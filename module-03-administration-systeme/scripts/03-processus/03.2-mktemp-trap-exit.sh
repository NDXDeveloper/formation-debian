#!/usr/bin/env bash
#
# Nom         : 03.2-mktemp-trap-exit.sh
# Module      : 3 — Administration système
# Section     : 3.3.2 — Signaux et kill
# Source      : module-03-administration-systeme/03.2-signaux-kill.md
# Description : Pattern minimal mktemp -d + trap EXIT pour répertoire temporaire avec
#               nettoyage garanti.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Si n'importe quelle commande échoue, le script s'arrête
# et le trap EXIT nettoie le répertoire temporaire
cp /source/data.csv "$TMPDIR/"
process_data "$TMPDIR/data.csv"
mv "$TMPDIR/result.csv" /output/
