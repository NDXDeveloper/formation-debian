#!/usr/bin/env bash
# =============================================================================
# Module 19 — Architectures de référence
# Section 19.5.1 — Multi-région cross-cloud (rclone files sync)
# Fichier : scripts/dr/files-sync-to-s3.sh
# Licence : CC BY 4.0
# =============================================================================
# Synchronisation des fichiers PVC (uploads applicatifs GestCom) vers le
# bucket S3 de DR. Complète Velero, qui gère les manifestes K8s mais les
# gros volumes de fichiers sont mieux servis par rclone (transfers
# parallèles, reprise sur erreur).
#
# Configuration rclone : ~/.config/rclone/rclone.conf (remote `s3-dr`)
# Lancement typique : via cron quotidien ou systemd timer
# =============================================================================
set -euo pipefail

rclone sync \
    /srv/nfs/k8s-pv/gestcom-uploads/ \
    s3-dr:entreprise-dr-backups/files-sync/gestcom-uploads/ \
    --transfers 8 \
    --checkers 16 \
    --progress \
    --log-file /var/log/dr/files-sync.log \
    --log-level INFO
