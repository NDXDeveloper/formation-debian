#!/usr/bin/env bash
#
# Nom         : 01.4-error-logger.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Système de logging structuré avec niveaux (DEBUG/INFO/WARN/ERROR)
#               écrivant en JSON pour ingestion par journald/Loki.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

readonly LOG_FILE="/var/log/monscript.log"

log() {
    local niveau=$1; shift
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    printf '%s [%s] [PID:%d] %s\n' "$timestamp" "$niveau" "$$" "$*" | tee -a "$LOG_FILE" >&2
}

on_error() {
    local code=$?
    log "ERROR" "Commande échouée (code $code) à la ligne $1 : ${BASH_COMMAND}"
}

on_exit() {
    local code=$?
    if (( code == 0 )); then
        log "INFO" "Script terminé avec succès"
    else
        log "ERROR" "Script terminé en erreur (code $code)"
    fi
}

trap 'on_error $LINENO' ERR
trap on_exit EXIT

log "INFO" "Démarrage du script"

# ... traitement ...
