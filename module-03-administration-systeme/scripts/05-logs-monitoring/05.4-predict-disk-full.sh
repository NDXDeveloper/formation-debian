#!/usr/bin/env bash
#
# Nom         : 05.4-predict-disk-full.sh
# Module      : 3 — Administration système
# Section     : 3.5.4 — Alertes et notifications
# Source      : module-03-administration-systeme/05.4-alertes-notifications.md
# Description : Prédiction simplifiée du remplissage disque par extrapolation linéaire
#               (sysstat/sar).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# Requiert que sar soit configuré (paquet sysstat)
# Prédiction simplifiée : extrapolation linéaire sur les dernières 24h
# Requiert que sar soit configuré (paquet sysstat)

# Utilisation disque il y a 24h
yesterday_day=$(date -d "yesterday" +%d)
usage_24h_ago=$(sar -d -f "/var/log/sysstat/sa${yesterday_day}" 2>/dev/null | \
    awk '/sda/ {print $NF}' | tail -1)

# Utilisation disque actuelle
usage_now=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# Taux de croissance par heure
if [[ -n "$usage_24h_ago" ]]; then
    growth_per_hour=$(( (usage_now - usage_24h_ago) / 24 ))
    
    if [[ "$growth_per_hour" -gt 0 ]]; then
        hours_until_full=$(( (100 - usage_now) / growth_per_hour ))
        
        if [[ "$hours_until_full" -lt 24 ]]; then
            echo "ALERTE: Disque / plein dans ~${hours_until_full}h au rythme actuel" | \
                mail -s "[WARNING] Prédiction disque plein — $(hostname)" ops@example.com
        fi
    fi
fi
