#!/usr/bin/env bash
#
# Nom         : 02.4-lib-notify.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.4 — Rapports et notifications
# Source      : module-05-scripting-automatisation/02.4-rapports-notifications.md
# Description : Bibliothèque de notification unifiée : journal, email, Slack,
#               Mattermost (configurable par variables d'environnement).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# lib/notify.sh — Système de notification unifié
#
# Canaux supportés : journal, email, slack, mattermost
# Configuration via variables d'environnement :
#   NOTIFY_CHANNELS="journal,email,slack"
#   NOTIFY_EMAIL_TO="admin@example.com"
#   SLACK_WEBHOOK_URL="https://hooks.slack.com/..."
#   MATTERMOST_WEBHOOK_URL="https://mattermost.example.com/hooks/..."
#   SMTP_URL, SMTP_USER, SMTP_PASS (pour l'email direct)

[[ -n "${_NOTIFY_SH_LOADED:-}" ]] && return 0
readonly _NOTIFY_SH_LOADED=1

readonly NOTIFY_CHANNELS="${NOTIFY_CHANNELS:-journal}"
readonly NOTIFY_HOSTNAME=$(hostname -f)
readonly NOTIFY_SHORT_HOST=$(hostname -s)

_notify_journal() {
    local niveau=$1 message=$2
    local priorite
    case "$niveau" in
        info) priorite="info" ;; warning) priorite="warning" ;;
        error) priorite="err" ;; critical) priorite="crit" ;;
        *) priorite="notice" ;;
    esac
    logger --tag "${SCRIPT_NAME:-notify}" --priority "user.${priorite}" "$message"
}

_notify_email() {
    local niveau=$1 message=$2
    local destinataire="${NOTIFY_EMAIL_TO:-}"
    [[ -z "$destinataire" ]] && return 0

    local sujet="[${niveau^^}] ${NOTIFY_SHORT_HOST} — ${SCRIPT_NAME:-script}"
    echo "$message" | mail -s "$sujet" "$destinataire" 2>/dev/null || true
}

_notify_slack() {
    local niveau=$1 message=$2
    local webhook="${SLACK_WEBHOOK_URL:-}"
    [[ -z "$webhook" ]] && return 0

    local emoji
    case "$niveau" in
        info) emoji=":information_source:" ;; success) emoji=":white_check_mark:" ;;
        warning) emoji=":warning:" ;; error) emoji=":x:" ;;
        critical) emoji=":rotating_light:" ;; *) emoji=":speech_balloon:" ;;
    esac

    local payload
    payload=$(jq -n \
        --arg t "$emoji *[${niveau^^}] ${NOTIFY_SHORT_HOST}* : $message" \
        '{text: $t}')

    curl -sSf --max-time 10 -X POST "$webhook" \
        -H "Content-Type: application/json" -d "$payload" >/dev/null 2>&1 || true
}

_notify_mattermost() {
    local niveau=$1 message=$2
    local webhook="${MATTERMOST_WEBHOOK_URL:-}"
    [[ -z "$webhook" ]] && return 0

    local payload
    payload=$(jq -n \
        --arg user "Serveur ${NOTIFY_SHORT_HOST}" \
        --arg t "[${niveau^^}] ${NOTIFY_HOSTNAME} : $message" \
        '{username: $user, text: $t}')

    curl -sSf --max-time 10 -X POST "$webhook" \
        -H "Content-Type: application/json" -d "$payload" >/dev/null 2>&1 || true
}

notify() {
    local niveau=$1
    shift
    local message="$*"

    # Envoyer sur tous les canaux configurés
    IFS=',' read -ra canaux <<< "$NOTIFY_CHANNELS"
    for canal in "${canaux[@]}"; do
        canal=$(echo "$canal" | tr -d '[:space:]')
        case "$canal" in
            journal)    _notify_journal "$niveau" "$message" ;;
            email)      _notify_email "$niveau" "$message" ;;
            slack)      _notify_slack "$niveau" "$message" ;;
            mattermost) _notify_mattermost "$niveau" "$message" ;;
            *) echo "Canal de notification inconnu : $canal" >&2 ;;
        esac
    done
}

# Raccourcis
notify_info()     { notify info "$@"; }
notify_success()  { notify success "$@"; }
notify_warning()  { notify warning "$@"; }
notify_error()    { notify error "$@"; }
notify_critical() { notify critical "$@"; }
