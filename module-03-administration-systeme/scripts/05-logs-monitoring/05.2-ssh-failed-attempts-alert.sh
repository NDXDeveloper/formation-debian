#!/usr/bin/env bash
#
# Nom         : 05.2-ssh-failed-attempts-alert.sh
# Module      : 3 — Administration système
# Section     : 3.5.2 — Analyse de logs
# Source      : module-03-administration-systeme/05.2-analyse-logs.md
# Description : Alerte si plus de N tentatives SSH échouées dans les 10 dernières
#               minutes.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
THRESHOLD=50
COUNT=$(journalctl -u ssh.service --since "10 min ago" --no-pager | \
    grep -c "Failed password" 2>/dev/null || echo 0)

if [[ "$COUNT" -ge "$THRESHOLD" ]]; then
    TOP_IPS=$(journalctl -u ssh.service --since "10 min ago" --no-pager | \
        grep "Failed password" | \
        grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | \
        sort | uniq -c | sort -rn | head -5)

    echo "ALERTE: $COUNT tentatives SSH échouées en 10 minutes" | \
        systemd-cat -t ssh-alert -p warning
    echo "Top IPs:" | systemd-cat -t ssh-alert -p warning
    echo "$TOP_IPS" | systemd-cat -t ssh-alert -p warning
fi
