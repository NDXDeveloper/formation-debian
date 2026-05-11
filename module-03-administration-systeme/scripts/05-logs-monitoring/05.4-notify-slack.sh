#!/usr/bin/env bash
#
# Nom         : 05.4-notify-slack.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Envoi de notification Slack via webhook avec formatage et niveau de
#               criticité.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# /usr/local/lib/monitoring/notify-slack.sh

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"

send_slack_alert() {
    local severity="$1"
    local message="$2"
    local hostname payload
    hostname=$(hostname -f)

    # Couleur selon la sévérité
    local color="good"
    [[ "$severity" == "WARNING" ]] && color="warning"
    [[ "$severity" == "CRITICAL" ]] && color="danger"
    [[ "$severity" == "RESOLVED" ]] && color="good"

    # Déclaration et assignation séparées (SC2155) — voir notify-webhook.sh.
    payload=$(cat <<EOF
{
    "attachments": [{
        "color": "$color",
        "title": "[$severity] $hostname",
        "text": "$message",
        "ts": $(date +%s)
    }]
}
EOF
)
    
    curl -s -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10
}

# Utilisation
# source /usr/local/lib/monitoring/notify-slack.sh
# send_slack_alert "CRITICAL" "Disque / à 95% sur srv01"
