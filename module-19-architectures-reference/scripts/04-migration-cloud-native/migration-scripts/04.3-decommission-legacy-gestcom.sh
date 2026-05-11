#!/usr/bin/env bash
# =============================================================================
# Module 19 — Architectures de référence
# Section 19.4.3 — Migration zero-downtime (décommissionnement)
# Fichier : decommission-legacy-gestcom.sh — backup final + arrêt services
# Licence : CC BY 4.0
# =============================================================================
# Décommissionnement du serveur legacy GestCom après migration complète
# vers Kubernetes (palier 4 stable depuis ≥ 2 semaines).
#
# Ce script :
#   1. Effectue un backup complet final (DB + fichiers + config)
#   2. Copie les backups vers le serveur d'archivage long terme
#   3. Arrête et désactive les services Apache + MySQL
#   4. Affiche les TODO manuels (DNS, firewall, période de grâce)
#
# PRÉREQUIS (checklist du module §7.1) :
#   - 100% du trafic sur K8s depuis ≥ 2 semaines
#   - Aucun rollback déclenché
#   - Toutes les données sont sur K8s
#   - Approbations équipe + plateforme + management
# =============================================================================
set -euo pipefail

LEGACY_HOST="${LEGACY_HOST:-admin@srv-gestcom}"
ARCHIVE_HOST="${ARCHIVE_HOST:-admin@backup.infra.internal.example.com}"
ARCHIVE_PATH="${ARCHIVE_PATH:-/srv/archives/gestcom-legacy}"

echo "[1/4] Backup final sur ${LEGACY_HOST}..."
ssh "${LEGACY_HOST}" << 'EOF'
set -euo pipefail

# Backup base de données
mysqldump --single-transaction --all-databases > /tmp/gestcom-final-backup.sql
# Backup fichiers applicatifs
tar czf /tmp/gestcom-files-final.tar.gz /var/www/gestcom/
# Backup configuration
tar czf /tmp/gestcom-config-final.tar.gz /etc/apache2/ /etc/mysql/ /etc/php/

ls -lh /tmp/gestcom-*-final.*
EOF

echo "[2/4] Copie des backups vers ${ARCHIVE_HOST}:${ARCHIVE_PATH}/ ..."
scp "${LEGACY_HOST}":/tmp/gestcom-*-final.* "${ARCHIVE_HOST}":"${ARCHIVE_PATH}/"

echo "[3/4] Arrêt des services (Apache + MySQL) sur ${LEGACY_HOST}..."
ssh "${LEGACY_HOST}" << 'EOF'
set -euo pipefail
sudo systemctl stop apache2
sudo systemctl stop mysql
sudo systemctl disable apache2
sudo systemctl disable mysql
echo "Services arrêtés et désactivés."
EOF

echo "[4/4] OK — services legacy arrêtés."
echo
echo "TODO manuels :"
echo "  - Mettre à jour DNS (BIND zone interne) : supprimer/orienter srv-gestcom"
echo "  - Supprimer les règles firewall vers le serveur legacy"
echo "  - Période de grâce 1 semaine avant extinction physique"
echo "  - Mettre à jour catalog-info.yaml Backstage et runbooks associés"
echo "  - Rédiger le postmortem de migration"
