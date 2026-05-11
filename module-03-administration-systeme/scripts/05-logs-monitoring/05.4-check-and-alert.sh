#!/usr/bin/env bash
#
# Nom         : 05.4-check-and-alert.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Vérification + notification en un seul script (pour usage autonome
#               sans Nagios).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
source /usr/local/lib/monitoring/notify.sh

# Exécuter le check Nagios
output=$(/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p / 2>&1)
exit_code=$?

case $exit_code in
    0) ;; # OK — rien à faire
    1) notify "WARNING" "$output" "Espace disque warning sur $(hostname)" ;;
    2) notify "CRITICAL" "$output" "Espace disque critique sur $(hostname)" ;;
    *) notify "WARNING" "$output" "Vérification disque en erreur sur $(hostname)" ;;
esac
