#!/usr/bin/env bash
#
# Nom         : 04.5-migration-to-networkd.sh
# Module      : 3 — Administration système
# Section     : 3.4.5 — systemd-networkd et systemd-resolved
# Source      : module-03-administration-systeme/04.5-systemd-network-resolved.md
# Description : Migration depuis ifupdown/NetworkManager vers systemd-networkd (à
#               exécuter avec accès console).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -e

echo "Arrêt de ifupdown..."
systemctl stop networking.service

echo "Démarrage de networkd et resolved..."
systemctl start systemd-networkd
systemctl start systemd-resolved

echo "Attente de la configuration réseau (10s)..."
sleep 10

echo "Test de connectivité..."
if ping -c 3 -W 5 192.168.1.1 > /dev/null 2>&1; then
    echo "SUCCÈS : connectivité OK"
    systemctl disable networking.service
    systemctl enable systemd-networkd systemd-resolved
    echo "Migration terminée avec succès"
else
    echo "ÉCHEC : rollback vers ifupdown"
    systemctl stop systemd-networkd
    systemctl start networking.service
    echo "Rollback effectué — ifupdown restauré"
    exit 1
fi
