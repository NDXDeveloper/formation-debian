#!/usr/bin/env bash
# =============================================================================
# Module 14 — CI/CD et GitOps
# Section 14.2.3 — Configuration, maintenance et sécurisation des runners
# Fichier : /usr/local/bin/ci-cleanup.sh — nettoyage CI/CD quotidien
# Licence : CC BY 4.0
# =============================================================================
# Script lancé par un timer systemd quotidien (cf. 02.1-cleanup-timer.systemd).
# Nettoie les ressources accumulées par GitLab Runner et GitHub Actions :
#   - Images et conteneurs Docker datant de plus de 48h
#   - Cache de build BuildKit datant de plus de 72h
#   - Répertoires de build orphelins (GitLab Runner, > 3 jours)
#   - Répertoires _work GitHub Actions (> 7 jours)
#   - Logs de diagnostic GitHub Actions (> 30 jours)
# =============================================================================
set -euo pipefail

echo "[$(date -Iseconds)] Début du nettoyage CI/CD"

# Nettoyage Docker : images et conteneurs de plus de 48h
docker system prune -af --filter "until=48h" 2>/dev/null || true

# Nettoyage du cache de build Docker BuildKit
docker builder prune -af --filter "until=72h" 2>/dev/null || true

# Nettoyage des répertoires de build orphelins (GitLab Runner)
if [ -d /home/gitlab-runner/builds ]; then
    find /home/gitlab-runner/builds -maxdepth 2 -type d -mtime +3 -exec rm -rf {} + 2>/dev/null || true
fi

# Nettoyage des répertoires de travail (GitHub Actions runner)
if [ -d /home/github-runner/actions-runner/_work ]; then
    find /home/github-runner/actions-runner/_work -maxdepth 2 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
fi

# Nettoyage des logs de diagnostic GitHub Actions (plus de 30 jours)
if [ -d /home/github-runner/actions-runner/_diag ]; then
    find /home/github-runner/actions-runner/_diag -name "*.log" -mtime +30 -delete 2>/dev/null || true
fi

echo "[$(date -Iseconds)] Nettoyage terminé"
echo "Espace disque : $(df -h / | tail -1 | awk '{print $4}') disponible"
