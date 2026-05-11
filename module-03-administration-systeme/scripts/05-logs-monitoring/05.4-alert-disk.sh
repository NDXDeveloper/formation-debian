#!/usr/bin/env bash
#
# Nom         : 05.4-alert-disk.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Alerte mail si une partition dépasse un seuil d'utilisation (avec
#               hystérésis simple).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# /usr/local/bin/alert-disk.sh
# Alerte sur l'espace disque

set -euo pipefail

# --- Configuration ---
WARNING_PCT=80
CRITICAL_PCT=90
MAILTO="ops@example.com"
HOSTNAME=$(hostname -f)

# --- Collecte ---
alert_triggered=false
message=""

# Les colonnes `size` et `used` ne sont pas utilisées : on les renomme
# `_size`/`_used` pour signaler l'intention (sinon SC2034 « unused »).
while read -r filesystem _size _used avail pct mountpoint; do
    # Retirer le % pour la comparaison numérique
    usage=${pct%\%}
    
    if [[ "$usage" -ge "$CRITICAL_PCT" ]]; then
        message+="CRITICAL: $mountpoint à ${pct} ($avail restant sur $filesystem)\n"
        alert_triggered=true
        severity="CRITICAL"
    elif [[ "$usage" -ge "$WARNING_PCT" ]]; then
        message+="WARNING: $mountpoint à ${pct} ($avail restant sur $filesystem)\n"
        alert_triggered=true
        severity="${severity:-WARNING}"
    fi
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs | tail -n +2)

# --- Notification ---
if [[ "$alert_triggered" == "true" ]]; then
    subject="[$severity] Espace disque — $HOSTNAME"
    body="Alerte espace disque sur $HOSTNAME à $(date)\n\n$message\n--- Détail complet ---\n$(df -h)"
    
    echo -e "$body" | mail -s "$subject" "$MAILTO"
    
    # Aussi dans journald pour la traçabilité
    echo -e "$message" | systemd-cat -t disk-alert -p warning
fi
