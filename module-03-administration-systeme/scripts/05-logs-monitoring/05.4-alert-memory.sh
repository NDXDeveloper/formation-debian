#!/usr/bin/env bash
#
# Nom         : 05.4-alert-memory.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Alerte mémoire avec hystérésis (évite les notifications répétées sur
#               seuil flottant).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

WARNING_PCT=80
CRITICAL_PCT=90
CLEAR_PCT=70       # Seuil de résolution (en dessous = retour à la normale)
STATE_FILE="/var/lib/monitoring/memory-state"
MAILTO="ops@example.com"
HOSTNAME=$(hostname -f)

mkdir -p /var/lib/monitoring

# Lire l'état précédent
previous_state="OK"
[[ -f "$STATE_FILE" ]] && previous_state=$(cat "$STATE_FILE")

# Calculer l'utilisation mémoire
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem_used_pct=$(( (mem_total - mem_available) * 100 / mem_total ))

# Déterminer le nouvel état avec hystérésis
if [[ "$mem_used_pct" -ge "$CRITICAL_PCT" ]]; then
    current_state="CRITICAL"
elif [[ "$mem_used_pct" -ge "$WARNING_PCT" ]]; then
    current_state="WARNING"
elif [[ "$mem_used_pct" -le "$CLEAR_PCT" ]]; then
    current_state="OK"
else
    # Entre CLEAR et WARNING : conserver l'état précédent (hystérésis)
    current_state="$previous_state"
fi

# Notifier uniquement en cas de changement d'état
if [[ "$current_state" != "$previous_state" ]]; then
    if [[ "$current_state" == "OK" ]]; then
        subject="[RESOLVED] Mémoire revenue à la normale — $HOSTNAME"
        body="Mémoire utilisée : ${mem_used_pct}% (seuil de résolution : ${CLEAR_PCT}%)"
    else
        subject="[$current_state] Mémoire à ${mem_used_pct}% — $HOSTNAME"
        body="Mémoire utilisée : ${mem_used_pct}%\nSeuils : WARNING=${WARNING_PCT}% / CRITICAL=${CRITICAL_PCT}%\n\n$(free -h)"
    fi
    
    echo -e "$body" | mail -s "$subject" "$MAILTO"
    echo "$subject" | systemd-cat -t memory-alert -p warning
fi

# Sauvegarder l'état
echo "$current_state" > "$STATE_FILE"
