#!/usr/bin/env bash
#
# Nom         : 05.4-notify-webhook.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Fonction réutilisable pour l'envoi de webhooks (Slack, Teams,
#               Mattermost).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# /usr/local/lib/monitoring/notify-webhook.sh
# Fonction réutilisable pour l'envoi de webhooks

send_webhook() {
    local webhook_url="$1"
    local message="$2"
    local severity="${3:-info}"
    local payload

    # Déclaration et assignation séparées : si la commande échoue, le code de
    # retour est conservé (sinon `local` masque toujours `$?` à 0 — SC2155).
    payload=$(cat <<EOF
{
    "hostname": "$(hostname -f)",
    "timestamp": "$(date -Iseconds)",
    "severity": "$severity",
    "message": "$message"
}
EOF
)
    
    curl -s -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10 \
        > /dev/null 2>&1 || \
        logger -t webhook-alert -p warning "Échec d'envoi webhook vers $webhook_url"
}
