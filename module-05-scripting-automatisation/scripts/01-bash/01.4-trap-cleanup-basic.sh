#!/usr/bin/env bash
#
# Nom         : 01.4-trap-cleanup-basic.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Démontre le pattern minimal trap+cleanup pour libérer des ressources
#               (fichier temporaire) en cas d'erreur ou d'interruption.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

cleanup() {
    echo "Nettoyage en cours..." >&2
    # Cette fonction s'exécute TOUJOURS à la sortie du script
}

trap cleanup EXIT

echo "Début du traitement"
# ... même si une erreur survient ici ...
echo "Fin du traitement"
# cleanup sera appelé automatiquement
