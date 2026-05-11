#!/usr/bin/env bash
#
# Nom         : 03.2-cleanup-trap-pattern.sh
# Module      : 3 — Administration système
# Section     : 3.3.2 — Signaux et kill
# Source      : module-03-administration-systeme/03.2-signaux-kill.md
# Description : Pattern complet trap: nettoyage de fichier temporaire ET libération de
#               lockfile garantis.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
TMPFILE=$(mktemp /tmp/traitement.XXXXXX)
LOCKFILE="/var/lock/mon-script.lock"

# Fonction de nettoyage
cleanup() {
    echo "Nettoyage en cours..."
    rm -f "$TMPFILE"
    rm -f "$LOCKFILE"
    echo "Nettoyage terminé"
}

# Intercepter les signaux de terminaison
trap cleanup EXIT
# EXIT est un pseudo-signal Bash : exécuté à TOUTE sortie du script
# (terminaison normale, SIGTERM, SIGINT, erreur, exit explicite)

# Créer le fichier de verrouillage
echo $$ > "$LOCKFILE"

# Le script fait son travail...
echo "Traitement en cours..."
sleep 60

# Le nettoyage s'exécute automatiquement à la sortie
