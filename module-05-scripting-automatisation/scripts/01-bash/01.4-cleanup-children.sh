#!/usr/bin/env bash
#
# Nom         : 01.4-cleanup-children.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Trap qui nettoie un fichier temporaire ET kill les processus enfants
#               encore actifs.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

readonly TMPFILE=$(mktemp)
PROCESSUS_ENFANTS=()

cleanup() {
    local signal=${1:-EXIT}
    echo "Nettoyage déclenché par : $signal" >&2

    # Arrêter les processus enfants
    for pid in "${PROCESSUS_ENFANTS[@]}"; do
        kill -TERM "$pid" 2>/dev/null && wait "$pid" 2>/dev/null || true
    done

    # Supprimer les fichiers temporaires
    rm -f "$TMPFILE"

    # Si déclenché par un signal (pas EXIT), propager le signal
    if [[ "$signal" != "EXIT" ]]; then
        trap - "$signal"             # Restaurer le comportement par défaut
        kill -"$signal" $$           # Se renvoyer le signal pour le code de retour correct
    fi
}

trap 'cleanup INT' INT
trap 'cleanup TERM' TERM
trap 'cleanup HUP' HUP
trap 'cleanup EXIT' EXIT
