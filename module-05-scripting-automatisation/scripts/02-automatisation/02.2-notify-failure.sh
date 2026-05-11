#!/usr/bin/env bash
#
# Nom         : 02.2-notify-failure.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.2 — Planification (cron, systemd timers)
# Source      : module-05-scripting-automatisation/02.2-planification-cron-timers.md
# Description : Script déclenché par OnFailure= d'un service systemd : envoie une
#               notification de défaillance.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# /opt/scripts/notify_failure.sh
set -euo pipefail

service="$1"
hostname=$(hostname -f)
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Récupérer les dernières lignes de log
logs=$(journalctl -u "$service" -n 20 --no-pager 2>/dev/null || echo "Logs indisponibles")

message="[ÉCHEC] Service $service sur $hostname à $timestamp

Dernières lignes de log :
$logs"

# Envoyer par email
echo "$message" | mail -s "[ALERTE] Échec de $service sur $hostname" admin@example.com

# Envoyer par webhook (Slack/Mattermost)
if [[ -n "${WEBHOOK_URL:-}" ]]; then
    curl -sf --max-time 10 -X POST "$WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$message\"}" >/dev/null 2>&1 || true
fi
