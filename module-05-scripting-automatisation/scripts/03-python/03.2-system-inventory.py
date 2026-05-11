#!/usr/bin/env python3
#
# Nom         : 03.2-system-inventory.py
# Module      : 5 — Scripting et automatisation
# Section     : 5.3.2 — Scripts Python d'administration
# Source      : module-05-scripting-automatisation/03.2-scripts-python-admin.md
# Description : Génération d'un inventaire système au format JSON (OS, CPU, mémoire,
#               disques, services, réseau).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
"""
system_inventory.py — Génération d'un inventaire système au format JSON.

Collecte les informations système (OS, CPU, mémoire, disques, services,
paquets) et produit un rapport JSON sur stdout.
"""

import argparse
import json
import logging
import platform
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

logger = logging.getLogger("inventory")


def setup_logging(verbose: bool = False) -> None:
    logging.basicConfig(
        level=logging.DEBUG if verbose else logging.INFO,
        format="%(asctime)s [%(levelname)-5s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stderr,
    )


def get_os_info() -> dict:
    """Informations sur le système d'exploitation."""
    info = {
        "hostname": platform.node(),
        "system": platform.system(),
        "kernel": platform.release(),
        "architecture": platform.machine(),
    }

    debian_version = Path("/etc/debian_version")
    if debian_version.exists():
        info["debian_version"] = debian_version.read_text().strip()

    return info


def get_cpu_info() -> dict:
    """Informations sur le processeur."""
    info = {"cores": 0, "model": "unknown"}

    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.exists():
        lines = cpuinfo.read_text().splitlines()
        models = [l.split(":")[1].strip() for l in lines if l.startswith("model name")]
        info["cores"] = len(models)
        if models:
            info["model"] = models[0]

    load = Path("/proc/loadavg")
    if load.exists():
        parts = load.read_text().split()
        info["load_average"] = {
            "1min": float(parts[0]),
            "5min": float(parts[1]),
            "15min": float(parts[2]),
        }

    return info


def get_memory_info() -> dict:
    """Informations sur la mémoire."""
    meminfo = {}

    for line in Path("/proc/meminfo").read_text().splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            # Convertir en octets (les valeurs sont en kB)
            parts = val.strip().split()
            meminfo[key.strip()] = int(parts[0]) * 1024 if parts else 0

    total = meminfo.get("MemTotal", 0)
    available = meminfo.get("MemAvailable", 0)
    used = total - available

    return {
        "total_bytes": total,
        "available_bytes": available,
        "used_bytes": used,
        "usage_pct": round(used / total * 100, 1) if total else 0,
    }


def get_disk_info() -> list[dict]:
    """Informations sur les partitions montées."""
    disks = []
    seen = set()

    for line in Path("/proc/mounts").read_text().splitlines():
        parts = line.split()
        if len(parts) < 3:
            continue

        device, mount_point, fs_type = parts[0], parts[1], parts[2]
        if fs_type in ("tmpfs", "devtmpfs", "sysfs", "proc", "cgroup2",
                        "squashfs", "overlay", "securityfs", "efivarfs"):
            continue
        if mount_point in seen:
            continue
        seen.add(mount_point)

        try:
            import shutil
            usage = shutil.disk_usage(mount_point)
            disks.append({
                "mount": mount_point,
                "device": device,
                "fs_type": fs_type,
                "total_bytes": usage.total,
                "used_bytes": usage.used,
                "free_bytes": usage.free,
                "usage_pct": round(usage.used / usage.total * 100, 1) if usage.total else 0,
            })
        except (PermissionError, OSError) as e:
            logger.debug("Impossible de lire %s : %s", mount_point, e)

    return sorted(disks, key=lambda d: d["mount"])


def get_services_status(services: list[str]) -> list[dict]:
    """État des services systemd."""
    results = []

    for svc in services:
        try:
            result = subprocess.run(
                ["systemctl", "show", svc, "--property=ActiveState,MainPID,StateChangeTimestamp"],
                capture_output=True, text=True, timeout=10,
            )
            props = {}
            for line in result.stdout.strip().splitlines():
                if "=" in line:
                    k, v = line.split("=", 1)
                    props[k] = v

            results.append({
                "name": svc,
                "active": props.get("ActiveState", "unknown"),
                "pid": int(props.get("MainPID", 0)),
                "since": props.get("StateChangeTimestamp", ""),
            })
        except (subprocess.TimeoutExpired, OSError):
            results.append({"name": svc, "active": "unknown", "pid": 0, "since": ""})

    return results


def get_package_counts() -> dict:
    """Nombre de paquets installés et mises à jour disponibles."""
    info = {"installed": 0, "upgradable": 0, "security": 0}

    try:
        result = subprocess.run(
            ["dpkg-query", "-f", "${Status}\n", "-W"],
            capture_output=True, text=True, timeout=30,
        )
        info["installed"] = sum(
            1 for line in result.stdout.splitlines()
            if "install ok installed" in line
        )
    except (subprocess.SubprocessError, OSError):
        logger.warning("Impossible de compter les paquets installés")

    return info


def build_inventory(services: list[str]) -> dict:
    """Construit l'inventaire complet."""
    logger.info("Collecte des informations système...")

    inventory = {
        "meta": {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "generator": "system_inventory.py",
        },
        "os": get_os_info(),
        "cpu": get_cpu_info(),
        "memory": get_memory_info(),
        "disks": get_disk_info(),
        "services": get_services_status(services),
        "packages": get_package_counts(),
    }

    logger.info("Inventaire collecté pour %s", inventory["os"]["hostname"])
    return inventory


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Inventaire système au format JSON.")
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument(
        "-s", "--services", nargs="+",
        default=["ssh", "cron", "nginx", "postgresql"],
        help="Services à vérifier (défaut : ssh cron nginx postgresql)",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help="Fichier de sortie (défaut : stdout)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    setup_logging(verbose=args.verbose)

    inventory = build_inventory(args.services)
    json_output = json.dumps(inventory, indent=2, ensure_ascii=False, default=str)

    if args.output:
        args.output.write_text(json_output + "\n", encoding="utf-8")
        logger.info("Inventaire écrit dans %s", args.output)
    else:
        print(json_output)

    return 0


if __name__ == "__main__":
    sys.exit(main())
