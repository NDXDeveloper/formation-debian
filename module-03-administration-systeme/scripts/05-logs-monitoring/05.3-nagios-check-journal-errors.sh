#!/usr/bin/env bash
#
# Nom         : 05.3-nagios-check-journal-errors.sh
# Module      : 3 — Administration système
# Section     : 3.5.3 — Introduction au monitoring
# Source      : module-03-administration-systeme/05.3-introduction-monitoring.md
# Description : Plugin Nagios qui vérifie le nombre d'erreurs dans journald sur les 10
#               dernières minutes.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
WARNING_THRESHOLD="${1:-10}"
CRITICAL_THRESHOLD="${2:-50}"

COUNT=$(journalctl --since "10 min ago" -p err --no-pager -q 2>/dev/null | wc -l)

if [[ "$COUNT" -ge "$CRITICAL_THRESHOLD" ]]; then
    echo "CRITICAL - $COUNT erreurs dans les 10 dernières minutes|errors=$COUNT;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0"
    exit 2
elif [[ "$COUNT" -ge "$WARNING_THRESHOLD" ]]; then
    echo "WARNING - $COUNT erreurs dans les 10 dernières minutes|errors=$COUNT;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0"
    exit 1
else
    echo "OK - $COUNT erreurs dans les 10 dernières minutes|errors=$COUNT;$WARNING_THRESHOLD;$CRITICAL_THRESHOLD;0"
    exit 0
fi
