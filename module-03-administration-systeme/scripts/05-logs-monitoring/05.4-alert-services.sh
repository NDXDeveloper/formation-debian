#!/usr/bin/env bash
#
# Nom         : 05.4-alert-services.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Vérifie que les services critiques sont actifs et alerte par
#               mail/Slack.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

SERVICES="nginx postgresql ssh cron"
MAILTO="ops@example.com"
HOSTNAME=$(hostname -f)

failed_services=""

for svc in $SERVICES; do
    if ! systemctl is-active --quiet "$svc"; then
        state=$(systemctl is-active "$svc" 2>/dev/null || echo "unknown")
        failed_services+="  - $svc.service : $state\n"
    fi
done

if [[ -n "$failed_services" ]]; then
    subject="[CRITICAL] Services en échec — $HOSTNAME"
    body="Les services suivants ne sont pas actifs sur $HOSTNAME :\n\n$failed_services\n"
    body+="--- Détail ---\n"
    
    for svc in $SERVICES; do
        if ! systemctl is-active --quiet "$svc"; then
            body+="$(systemctl status "$svc" --no-pager 2>&1 | head -15)\n\n"
        fi
    done
    
    echo -e "$body" | mail -s "$subject" "$MAILTO"
    echo -e "$failed_services" | systemd-cat -t service-alert -p crit
fi
