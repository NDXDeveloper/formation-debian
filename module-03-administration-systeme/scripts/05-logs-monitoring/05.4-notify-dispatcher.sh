#!/usr/bin/env bash
#
# Nom         : 05.4-notify-dispatcher.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Dispatcher multi-canal : mail/Slack/Webhook selon configuration.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
source /usr/local/lib/monitoring/notify-slack.sh

notify() {
    local severity="$1"
    local subject="$2"
    local body="$3"
    local mailto="${4:-ops@example.com}"
    
    # Toujours journald
    echo "$subject: $body" | systemd-cat -t monitoring -p warning
    
    # Email pour tout
    echo -e "$body" | mail -s "$subject" "$mailto"
    
    # Slack/webhook uniquement pour WARNING et CRITICAL
    if [[ "$severity" == "WARNING" || "$severity" == "CRITICAL" ]]; then
        send_slack_alert "$severity" "$subject\n$body"
    fi
}

# Utilisation dans les scripts d'alerte :
# source /usr/local/lib/monitoring/notify.sh
# notify "CRITICAL" "[CRITICAL] Disque plein — srv01" "/ à 96%, 800 Mo restant"
