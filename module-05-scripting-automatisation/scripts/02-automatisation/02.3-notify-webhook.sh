#!/usr/bin/env bash
#
# Nom         : 02.3-notify-webhook.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.3 — Interaction avec des APIs REST
# Source      : module-05-scripting-automatisation/02.3-interaction-apis-rest.md
# Description : Envoi de notifications via webhook (Slack/Mattermost) avec niveau de
#               criticité.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# notify.sh — Envoi de notifications via webhook
#
# Usage : notify.sh <niveau> <message>
#   niveau : info, warning, error, critical
#
set -euo pipefail

readonly WEBHOOK_URL="${WEBHOOK_URL:?Variable WEBHOOK_URL requise}"

envoyer_notification() {
    local niveau=$1
    local message=$2
    local hostname
    hostname=$(hostname -f)
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

    # Couleur selon le niveau (format Slack/Mattermost)
    local couleur
    case "$niveau" in
        info)     couleur="#36a64f" ;;
        warning)  couleur="#ff9900" ;;
        error)    couleur="#ff0000" ;;
        critical) couleur="#990000" ;;
        *)        couleur="#cccccc" ;;
    esac

    # Construction du payload JSON
    local payload
    payload=$(jq -n \
        --arg texte "[$niveau] $hostname : $message" \
        --arg couleur "$couleur" \
        --arg titre "$(echo "$niveau" | tr '[:lower:]' '[:upper:]') — $hostname" \
        --arg msg "$message" \
        --arg ts "$timestamp" \
        '{
            attachments: [{
                color: $couleur,
                title: $titre,
                text: $msg,
                footer: $ts
            }]
        }')

    # Envoi avec retry sur erreur réseau
    local tentative=1
    local max_tentatives=3

    while (( tentative <= max_tentatives )); do
        if curl -sSf --max-time 10 \
            -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "$payload" >/dev/null 2>&1; then
            return 0
        fi

        echo "Envoi échoué (tentative $tentative/$max_tentatives)" >&2
        sleep 2
        (( tentative++ ))
    done

    echo "Impossible d'envoyer la notification après $max_tentatives tentatives" >&2
    return 1
}

main() {
    local niveau=${1:?Usage: $0 <niveau> <message>}
    shift
    local message="$*"

    envoyer_notification "$niveau" "$message"
}

main "$@"
