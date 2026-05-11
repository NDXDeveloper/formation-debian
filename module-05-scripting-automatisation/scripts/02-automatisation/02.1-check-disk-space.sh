#!/usr/bin/env bash
#
# Nom         : 02.1-check-disk-space.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Surveillance de l'espace disque avec alertes par mail si seuil
#               dépassé.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# check_disk_space.sh — Surveillance de l'espace disque avec alertes
#
set -euo pipefail

readonly SEUIL_WARNING=${SEUIL_WARNING:-80}
readonly SEUIL_CRITICAL=${SEUIL_CRITICAL:-90}
readonly ALERT_FILE="/var/lib/monscript/disk_alert_sent"

log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_error() { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

# Vérifier si une alerte a déjà été envoyée récemment (anti-spam)
alerte_deja_envoyee() {
    local partition=$1
    local fichier_flag="${ALERT_FILE}_$(echo "$partition" | tr '/' '_')"

    if [[ -f "$fichier_flag" ]]; then
        local age_minutes
        age_minutes=$(( ( $(date +%s) - $(stat -c%Y "$fichier_flag") ) / 60 ))
        # Ne pas renvoyer d'alerte avant 4 heures
        (( age_minutes < 240 ))
    else
        return 1
    fi
}

marquer_alerte_envoyee() {
    local partition=$1
    local fichier_flag="${ALERT_FILE}_$(echo "$partition" | tr '/' '_')"
    mkdir -p "$(dirname "$fichier_flag")"
    touch "$fichier_flag"
}

envoyer_alerte() {
    local niveau=$1
    local message=$2

    # Logger dans journald
    logger --tag "disk-monitor" --priority "user.${niveau}" "$message"

    # Notification par webhook (Slack/Mattermost) — si configuré
    if [[ -n "${WEBHOOK_URL:-}" ]]; then
        local couleur
        [[ "$niveau" == "warning" ]] && couleur="warning" || couleur="danger"
        curl -sf --max-time 10 -X POST "$WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"[$niveau] $(hostname): $message\"}" \
            >/dev/null 2>&1 || true
    fi
}

main() {
    local -i code_retour=0

    while IFS= read -r ligne; do
        local partition
        partition=$(awk '{print $1}' <<< "$ligne")
        local pourcentage
        pourcentage=$(awk '{print $5}' <<< "$ligne" | tr -d '%')

        if (( pourcentage >= SEUIL_CRITICAL )); then
            log_error "CRITIQUE : $partition à ${pourcentage}%"
            if ! alerte_deja_envoyee "$partition"; then
                envoyer_alerte "crit" "Espace disque critique : $partition à ${pourcentage}%"
                marquer_alerte_envoyee "$partition"
            fi
            code_retour=2

        elif (( pourcentage >= SEUIL_WARNING )); then
            log_warn "WARNING : $partition à ${pourcentage}%"
            if ! alerte_deja_envoyee "$partition"; then
                envoyer_alerte "warning" "Espace disque élevé : $partition à ${pourcentage}%"
                marquer_alerte_envoyee "$partition"
            fi
            (( code_retour < 2 )) && code_retour=1
        fi
    done < <(df --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | tail -n +2)

    if (( code_retour == 0 )); then
        log_info "Toutes les partitions sont sous le seuil de ${SEUIL_WARNING}%"
    fi

    exit "$code_retour"
}

main "$@"
