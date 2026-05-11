#!/usr/bin/env bash
#
# Nom         : 02.1-create-users-csv.sh
# Module      : 3 — Administration système
# Section     : 3.2.1 — Création et modification d'utilisateurs
# Source      : module-03-administration-systeme/02.1-creation-modification-utilisateurs.md
# Description : Crée des utilisateurs à partir d'un fichier CSV (format:
#               login,nom_complet,groupes_secondaires).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# Format CSV : login,nom_complet,groupes_secondaires

set -euo pipefail

INPUT_FILE="${1:?Usage: $0 fichier.csv}"
LOG_FILE="/var/log/creation-utilisateurs.log"

while IFS=',' read -r login nom groupes; do
    # Ignorer les lignes vides et les commentaires
    [[ -z "$login" || "$login" == \#* ]] && continue

    # Vérifier si l'utilisateur existe déjà
    if id "$login" &>/dev/null; then
        echo "[SKIP] $login existe déjà" | tee -a "$LOG_FILE"
        continue
    fi

    # Créer l'utilisateur
    adduser --disabled-password --gecos "$nom" "$login"

    # Ajouter aux groupes secondaires
    if [[ -n "$groupes" ]]; then
        usermod -aG "$groupes" "$login"
    fi

    # Forcer le changement de mot de passe au premier login
    chage -d 0 "$login"

    echo "[OK] $login créé (groupes: $groupes)" | tee -a "$LOG_FILE"

done < "$INPUT_FILE"
