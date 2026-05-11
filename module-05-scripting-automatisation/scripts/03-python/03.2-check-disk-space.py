#!/usr/bin/env python3
#
# Nom         : 03.2-check-disk-space.py
# Module      : 5 — Scripting et automatisation
# Section     : 5.3.2 — Scripts Python d'administration
# Source      : module-05-scripting-automatisation/03.2-scripts-python-admin.md
# Description : Vérification de l'espace disque avec alertes Prometheus exporter —
#               équivalent Python du script bash 02.1.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
"""
check_disk_space.py — Vérification de l'espace disque avec alertes.

Vérifie l'utilisation des partitions et alerte si un seuil est dépassé.
Conçu pour être exécuté via un timer systemd ou cron.

Codes de retour :
    0 : toutes les partitions sous le seuil
    1 : au moins une partition dépasse le seuil warning
    2 : au moins une partition dépasse le seuil critique
"""

import argparse
import logging
import shutil
import sys
from pathlib import Path

# ── Constantes ──────────────────────────────────────────────
DEFAULT_WARNING = 80
DEFAULT_CRITICAL = 90
EXCLUDED_FS = {"tmpfs", "devtmpfs", "squashfs", "overlay"}

# ── Logging ─────────────────────────────────────────────────
logger = logging.getLogger(__name__)


def setup_logging(verbose: bool = False) -> None:
    """Configure la journalisation."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)-5s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        stream=sys.stderr,
    )


# ── Logique métier ──────────────────────────────────────────
def check_partition(path: str, warning: int, critical: int) -> int:
    """Vérifie l'utilisation d'une partition.
    
    Retourne 0 (ok), 1 (warning) ou 2 (critical).
    """
    try:
        usage = shutil.disk_usage(path)
    except PermissionError:
        logger.warning("Permission refusée pour %s", path)
        return 0

    percent = int(usage.used / usage.total * 100)

    if percent >= critical:
        logger.error(
            "CRITIQUE : %s à %d%% (%s libre)",
            path, percent, format_size(usage.free),
        )
        return 2
    elif percent >= warning:
        logger.warning(
            "WARNING : %s à %d%% (%s libre)",
            path, percent, format_size(usage.free),
        )
        return 1
    else:
        logger.info("%s : %d%% (%s libre)", path, percent, format_size(usage.free))
        return 0


def format_size(size_bytes: int) -> str:
    """Formate une taille en octets vers un format lisible."""
    for unite in ("o", "Ko", "Mo", "Go", "To"):
        if abs(size_bytes) < 1024:
            return f"{size_bytes:.1f} {unite}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} Po"


def get_mount_points() -> list[str]:
    """Récupère les points de montage en excluant les FS virtuels."""
    points = []
    with open("/proc/mounts") as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 3 and parts[2] not in EXCLUDED_FS:
                mount_point = parts[1]
                if Path(mount_point).exists():
                    points.append(mount_point)
    # Dédupliquer (certains montages bind)
    return sorted(set(points))


# ── Arguments CLI ───────────────────────────────────────────
def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse les arguments de la ligne de commande."""
    parser = argparse.ArgumentParser(
        description="Vérification de l'espace disque avec alertes.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-w", "--warning",
        type=int, default=DEFAULT_WARNING,
        help=f"Seuil warning en %% (défaut : {DEFAULT_WARNING})",
    )
    parser.add_argument(
        "-c", "--critical",
        type=int, default=DEFAULT_CRITICAL,
        help=f"Seuil critique en %% (défaut : {DEFAULT_CRITICAL})",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Mode verbeux (affiche les partitions OK)",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=None,
        help="Points de montage à vérifier (défaut : tous)",
    )
    return parser.parse_args(argv)


# ── Point d'entrée ──────────────────────────────────────────
def main(argv: list[str] | None = None) -> int:
    """Point d'entrée principal. Retourne le code de sortie."""
    args = parse_args(argv)
    setup_logging(verbose=args.verbose)

    mount_points = args.paths if args.paths else get_mount_points()
    logger.debug("Partitions à vérifier : %s", mount_points)

    worst = 0
    for mp in mount_points:
        result = check_partition(mp, args.warning, args.critical)
        worst = max(worst, result)

    return worst


if __name__ == "__main__":
    sys.exit(main())
