#!/usr/bin/env bash
#
# Nom         : 01.4-on-error-context.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Capture le contexte complet (script, ligne, fonction, code) lors d'une
#               erreur via trap ERR + LINENO.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

on_error() {
    local code=$?
    local ligne=$1
    echo "ERREUR : commande en erreur (code $code) à la ligne $ligne" >&2
    echo "  Commande : ${BASH_COMMAND}" >&2
    echo "  Fichier : ${BASH_SOURCE[0]}" >&2
    echo "  Pile d'appels : ${FUNCNAME[*]}" >&2
}

trap 'on_error $LINENO' ERR

echo "Début"
ls /fichier/inexistant               # Déclenche le trap ERR
echo "Fin"                           # Non atteint (set -e arrête le script)
