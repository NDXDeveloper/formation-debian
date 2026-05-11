#!/usr/bin/env bash
# =============================================================================
# Module 15 — Observabilité et monitoring
# Section 15.2.4 — Grafana : annotation de déploiement via API
# Fichier : add-deploy-annotation.sh — appelé depuis le pipeline CI/CD
# Licence : CC BY 4.0
# =============================================================================
# Pousse une annotation sur un dashboard Grafana au moment d'un déploiement.
# Pattern fondamental d'observabilité : corréler visuellement les changements
# de métriques avec leurs causes (déploiements, mises à jour de config).
#
# Variables d'environnement attendues :
#   GRAFANA_URL       : ex. https://grafana.example.com
#   GRAFANA_API_KEY   : token API service account avec rôle Editor
#   GRAFANA_DASHBOARD_UID : UID du dashboard cible
#   APP_NAME          : ex. orders-api
#   APP_VERSION       : ex. v2.3.0
#   GIT_COMMIT_SHORT  : ex. abc123
# =============================================================================
set -euo pipefail

: "${GRAFANA_URL:?manquant}"
: "${GRAFANA_API_KEY:?manquant}"
: "${GRAFANA_DASHBOARD_UID:?manquant}"
: "${APP_NAME:?manquant}"
: "${APP_VERSION:?manquant}"
: "${GIT_COMMIT_SHORT:?manquant}"

curl -fsSL -X POST "${GRAFANA_URL}/api/annotations" \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(cat <<EOF
{
  "dashboardUID": "${GRAFANA_DASHBOARD_UID}",
  "time": $(date +%s000),
  "tags": ["deployment", "${APP_NAME}"],
  "text": "Déploiement ${APP_NAME} ${APP_VERSION} (commit ${GIT_COMMIT_SHORT})"
}
EOF
)"
