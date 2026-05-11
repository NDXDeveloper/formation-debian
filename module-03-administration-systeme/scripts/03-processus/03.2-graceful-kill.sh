#!/usr/bin/env bash
#
# Nom         : 03.2-graceful-kill.sh
# Module      : 3 — Administration système
# Section     : 3.3.2 — Signaux et kill
# Source      : module-03-administration-systeme/03.2-signaux-kill.md
# Description : Terminaison propre d'un processus : envoie SIGTERM puis SIGKILL après
#               timeout.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# Usage : graceful-kill.sh <PID> [timeout_seconds]

PID="${1:?Usage: $0 <PID> [timeout]}"
TIMEOUT="${2:-10}"

# Vérifier que le processus existe
if ! kill -0 "$PID" 2>/dev/null; then
    echo "Le processus $PID n'existe pas"
    exit 1
fi

echo "Envoi de SIGTERM au processus $PID..."
kill "$PID"

# Attendre la terminaison avec timeout
for ((i=0; i<TIMEOUT; i++)); do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Processus $PID terminé proprement (${i}s)"
        exit 0
    fi
    sleep 1
done

echo "Le processus $PID ne répond pas après ${TIMEOUT}s, envoi de SIGKILL..."
kill -9 "$PID"

sleep 1
if ! kill -0 "$PID" 2>/dev/null; then
    echo "Processus $PID tué avec SIGKILL"
    exit 0
else
    echo "ERREUR : le processus $PID est toujours actif (probablement en état D)"
    exit 1
fi
