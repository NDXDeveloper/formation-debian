#!/usr/bin/env bash
#
# Nom         : 02.4-daily-report.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.4 — Rapports et notifications
# Source      : module-05-scripting-automatisation/02.4-rapports-notifications.md
# Description : Rapport quotidien avec notification conditionnelle (envoie un email
#               seulement si anomalie détectée).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# daily_report.sh — Rapport quotidien avec notification conditionnelle
#
set -euo pipefail

readonly SCRIPT_NAME="daily-report"
readonly RAPPORT_DIR="/var/rapports"
readonly RAPPORT_FILE="${RAPPORT_DIR}/systeme_$(date '+%Y%m%d').html"

source "$(dirname "${BASH_SOURCE[0]}")/lib/notify.sh"

main() {
    mkdir -p "$RAPPORT_DIR"

    # 1. Générer le rapport HTML
    local rapport_html
    rapport_html=$(generer_rapport_html)
    echo "$rapport_html" > "$RAPPORT_FILE"

    # 2. Analyser les résultats pour déterminer le niveau d'alerte
    local -i alertes=0 warnings=0

    # Vérifier l'espace disque
    while read -r _ _ _ _ pcent; do
        local p=${pcent%\%}
        if (( p >= 90 )); then (( alertes++ ))
        elif (( p >= 80 )); then (( warnings++ ))
        fi
    done < <(df --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | tail -n +2)

    # Vérifier les services
    for svc in ssh cron nginx postgresql; do
        systemctl is-active --quiet "$svc" 2>/dev/null || (( alertes++ )) || true
    done

    # 3. Envoyer le rapport par email (toujours)
    if command -v s-nail &>/dev/null; then
        echo "$rapport_html" | s-nail \
            -s "Rapport système — $(hostname -s) — $(date '+%Y-%m-%d')" \
            -S content-type="text/html; charset=utf-8" \
            "${NOTIFY_EMAIL_TO:-admin@example.com}" 2>/dev/null || true
    fi

    # 4. Notifications conditionnelles (Slack/Mattermost)
    if (( alertes > 0 )); then
        notify_critical "$alertes problème(s) critique(s) détecté(s) — voir rapport email"
    elif (( warnings > 0 )); then
        notify_warning "$warnings avertissement(s) — voir rapport email"
    else
        notify_info "Rapport quotidien : tous les indicateurs sont normaux"
    fi

    # 5. Nettoyer les anciens rapports (rétention 30 jours)
    find "$RAPPORT_DIR" -name "systeme_*.html" -mtime +30 -delete 2>/dev/null || true
}

main "$@"
