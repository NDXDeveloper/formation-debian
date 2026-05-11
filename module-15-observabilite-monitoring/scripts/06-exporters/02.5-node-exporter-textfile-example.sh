#!/usr/bin/env bash
# =============================================================================
# Module 15 — Observabilité et monitoring
# Section 15.2.5 — node_exporter : textfile_collector
# Fichier : exemple de génération de métriques custom via textfile collector
# Licence : CC BY 4.0
# =============================================================================
# Le textfile_collector lit tous les *.prom du répertoire spécifié et
# expose leurs métriques. Pattern simple pour ajouter des métriques custom
# sans écrire d'exporter dédié.
#
# Bonnes pratiques :
#   - Écrire dans un fichier temporaire puis renommer (atomique)
#   - Format strictement Prometheus (# HELP, # TYPE, métrique <valeur>)
#   - Lancé via cron ou timer systemd selon la fréquence souhaitée
#
# Exemple : nombre de paquets APT en attente de mise à jour
# =============================================================================
set -euo pipefail

TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"
METRIC_FILE="${TEXTFILE_DIR}/apt_updates.prom"
TMP_FILE="${METRIC_FILE}.tmp.$$"

# Compter les paquets en attente de mise à jour
upgrades=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo 0)

# Compter les mises à jour de sécurité spécifiquement
security=$(apt-get -s upgrade 2>/dev/null | grep "^Inst" | grep -c -i security || echo 0)

# Écrire au format Prometheus
cat > "${TMP_FILE}" <<EOF
# HELP apt_packages_pending Number of APT packages pending upgrade.
# TYPE apt_packages_pending gauge
apt_packages_pending ${upgrades}

# HELP apt_security_packages_pending Number of security APT packages pending.
# TYPE apt_security_packages_pending gauge
apt_security_packages_pending ${security}

# HELP apt_check_timestamp_seconds Last APT check timestamp (Unix epoch).
# TYPE apt_check_timestamp_seconds gauge
apt_check_timestamp_seconds $(date +%s)
EOF

# Renommage atomique (évite que node_exporter lise un fichier partiel)
mv "${TMP_FILE}" "${METRIC_FILE}"
