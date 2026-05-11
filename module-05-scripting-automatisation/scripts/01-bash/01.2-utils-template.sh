#!/usr/bin/env bash
#
# Nom         : 01.2-utils-template.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.2 — Fonctions et sous-shells
# Source      : module-05-scripting-automatisation/01.2-fonctions-sous-shells.md
# Description : Squelette type d'un script bash bien structuré : en-tête, options,
#               fonctions, log, traitement, cleanup.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# nom_du_script.sh — Description courte du script
#
# Usage : nom_du_script.sh [options] <arguments>
#
# Description détaillée du script, son objectif, ses prérequis
# et son comportement attendu.
#
set -euo pipefail

# ─── Constantes ──────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# ─── Variables globales ─────────────────────────────────────
VERBOSE=0
DRY_RUN=0

# ─── Fonctions utilitaires ──────────────────────────────────
log() {
    local niveau=$1
    shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$niveau" "$*" | tee -a "$LOG_FILE" >&2
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }

die() {
    log_error "$@"
    exit 1
}

# ─── Fonctions métier ───────────────────────────────────────
afficher_aide() {
    cat <<EOF
Usage: $SCRIPT_NAME [options] <argument>

Options:
  -v, --verbose    Mode verbeux
  -n, --dry-run    Simulation (aucune modification)
  -h, --help       Afficher cette aide

Exemple:
  $SCRIPT_NAME -v /chemin/vers/donnees
EOF
}

parser_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)  VERBOSE=1; shift ;;
            -n|--dry-run)  DRY_RUN=1; shift ;;
            -h|--help)     afficher_aide; exit 0 ;;
            --)            shift; break ;;
            -*)            die "Option inconnue : $1" ;;
            *)             break ;;
        esac
    done

    # Validation des arguments obligatoires
    [[ $# -ge 1 ]] || die "Argument manquant. Utilisez -h pour l'aide."
    CIBLE=$1
}

traitement_principal() {
    log_info "Début du traitement sur $CIBLE"

    if (( DRY_RUN )); then
        log_warn "Mode simulation — aucune modification ne sera effectuée"
    fi

    # ... logique métier ...

    log_info "Traitement terminé."
}

# ─── Nettoyage ───────────────────────────────────────────────
cleanup() {
    local code_retour=$?
    # Supprimer les fichiers temporaires, libérer les verrous, etc.
    log_info "Nettoyage (code de sortie : $code_retour)"
    exit "$code_retour"
}

# ─── Point d'entrée ─────────────────────────────────────────
main() {
    trap cleanup EXIT
    parser_arguments "$@"
    traitement_principal
}

main "$@"
