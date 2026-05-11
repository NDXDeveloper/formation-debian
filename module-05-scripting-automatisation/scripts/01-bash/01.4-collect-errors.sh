#!/usr/bin/env bash
#
# Nom         : 01.4-collect-errors.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Collecte les erreurs sans interrompre le script, puis affiche un
#               rapport final (alternative à set -e).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -uo pipefail
# Note : pas de set -e ici, les erreurs sont gérées manuellement

declare -a erreurs=()
declare -i nb_succes=0

traiter_serveur() {
    local serveur=$1

    if ! ssh -o ConnectTimeout=5 "$serveur" "uptime" &>/dev/null; then
        erreurs+=("$serveur : connexion impossible")
        return 1
    fi

    if ! ssh "$serveur" "systemctl is-active nginx" &>/dev/null; then
        erreurs+=("$serveur : nginx inactif")
        return 1
    fi

    (( nb_succes++ ))
    return 0
}

serveurs=("web01" "web02" "web03" "db01" "db02")

for serveur in "${serveurs[@]}"; do
    traiter_serveur "$serveur" || true
done

# Rapport final
echo "Résultat : $nb_succes/${#serveurs[@]} serveurs OK"

if (( ${#erreurs[@]} > 0 )); then
    echo ""
    echo "Erreurs détectées :"
    for erreur in "${erreurs[@]}"; do
        echo "  - $erreur"
    done
    exit 1
fi

exit 0
