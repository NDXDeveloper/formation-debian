#!/usr/bin/env bash
#
# Nom         : 01.4-trap-cleanup-tmpfile.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Crée un fichier temporaire sécurisé via mktemp et garantit sa
#               suppression via trap, même en cas d'erreur.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

# Créer un fichier temporaire sécurisé
readonly TMPFILE=$(mktemp /tmp/monscript.XXXXXX)
readonly TMPDIR_WORK=$(mktemp -d /tmp/monscript.XXXXXX)

# Garantir le nettoyage à la sortie
trap 'rm -f "$TMPFILE"; rm -rf "$TMPDIR_WORK"' EXIT

# Utiliser les fichiers temporaires en toute sécurité
echo "données intermédiaires" > "$TMPFILE"
cp /etc/nginx/nginx.conf "$TMPDIR_WORK/"
# ... traitement ...

# Le nettoyage est automatique, même en cas d'erreur
