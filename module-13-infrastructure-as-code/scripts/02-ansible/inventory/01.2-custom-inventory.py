#!/usr/bin/env python3
# =============================================================================
# Module 13 — Infrastructure as Code
# Section 13.1.2 — Inventaires, connexions et variables
# Fichier : inventory/custom_inventory.py (script d'inventaire personnalisé)
# Licence : CC BY 4.0
# =============================================================================
"""Script d'inventaire dynamique interrogeant une CMDB interne.

Usage : ./custom_inventory.py --list | --host <hostname>

Le script doit être exécutable (chmod +x) et placé dans inventory/.
Format de sortie attendu par Ansible : JSON avec _meta.hostvars.
"""

import argparse
import json
import sys

import requests

CMDB_API = "https://cmdb.example.com/api/v1"


def get_inventory():
    """Récupère l'inventaire complet depuis la CMDB."""
    response = requests.get(f"{CMDB_API}/servers", timeout=10)
    response.raise_for_status()
    servers = response.json()

    inventory = {"_meta": {"hostvars": {}}}

    for server in servers:
        # Déterminer le groupe en fonction du rôle
        role = server.get("role", "ungrouped")
        if role not in inventory:
            inventory[role] = {"hosts": [], "vars": {}}
        inventory[role]["hosts"].append(server["fqdn"])

        # Variables par hôte
        inventory["_meta"]["hostvars"][server["fqdn"]] = {
            "ansible_host": server["ip_address"],
            "ansible_port": server.get("ssh_port", 22),
            "datacenter": server.get("datacenter", "unknown"),
            "os_version": server.get("os_version", "debian-13"),
        }

    return inventory


def get_host(hostname):
    """Récupère les variables d'un hôte spécifique."""
    response = requests.get(f"{CMDB_API}/servers/{hostname}", timeout=10)
    if response.status_code == 404:
        return {}
    response.raise_for_status()
    server = response.json()
    return {
        "ansible_host": server["ip_address"],
        "ansible_port": server.get("ssh_port", 22),
        "datacenter": server.get("datacenter", "unknown"),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--host", type=str)
    args = parser.parse_args()

    if args.list:
        print(json.dumps(get_inventory(), indent=2))
    elif args.host:
        print(json.dumps(get_host(args.host), indent=2))
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
