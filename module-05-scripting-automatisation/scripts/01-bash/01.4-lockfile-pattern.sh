#!/usr/bin/env bash
#
# Nom         : 01.4-lockfile-pattern.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Empêche l'exécution concurrente du même script via un lockfile et
#               garantit son nettoyage automatique.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

readonly LOCKFILE="/var/run/monscript.lock"

acquérir_verrou() {
    if ! mkdir "$LOCKFILE" 2>/dev/null; then
        echo "ERREUR : une instance est déjà en cours (lockfile : $LOCKFILE)" >&2
        exit 1
    fi
    # Stocker le PID pour le diagnostic
    echo $$ > "$LOCKFILE/pid"
}

libérer_verrou() {
    rm -rf "$LOCKFILE"
}

trap libérer_verrou EXIT
acquérir_verrou

echo "Exécution exclusive en cours (PID $$)..."
# ... traitement ...
