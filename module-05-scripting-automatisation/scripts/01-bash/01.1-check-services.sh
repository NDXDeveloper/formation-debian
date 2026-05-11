#!/usr/bin/env bash
#
# Nom         : 01.1-check-services.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.1 — Variables, tableaux et structures de contrôle
# Source      : module-05-scripting-automatisation/01.1-variables-tableaux-structures.md
# Description : Vérifie l'état d'une liste de services et génère un rapport texte.
#               Démontre l'usage combiné de tableaux associatifs, expansion de
#               paramètres, [[ ]], while read et case.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# check_services.sh — Vérifie l'état de services et génère un rapport
#
set -euo pipefail

# Configuration par défaut avec valeurs de repli
readonly LOG_DIR="${LOG_DIR:-/var/log}"
readonly RAPPORT="${RAPPORT:-/tmp/rapport_services_$(date +%Y%m%d_%H%M%S).txt}"

# Tableau associatif : service → port attendu
declare -A services=(
    [nginx]=80
    [postgresql]=5432
    [redis-server]=6379
    [ssh]=22
)

# Tableau associatif pour stocker les résultats
declare -A resultats

# Compteurs
declare -i ok=0 ko=0

for service in "${!services[@]}"; do
    port="${services[$service]}"

    # Vérifier l'état systemd
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        etat="actif"
    else
        etat="inactif"
    fi

    # Vérifier l'écoute sur le port attendu
    if ss -tlnp 2>/dev/null | grep -q ":${port}\b"; then
        ecoute="oui"
    else
        ecoute="non"
    fi

    # Évaluer le résultat global
    case "${etat}:${ecoute}" in
        actif:oui)
            resultats[$service]="OK"
            (( ok++ ))
            ;;
        actif:non)
            resultats[$service]="WARN (actif mais port $port non ouvert)"
            (( ko++ ))
            ;;
        *)
            resultats[$service]="ERREUR (service $etat, port $port écoute: $ecoute)"
            (( ko++ ))
            ;;
    esac
done

# Génération du rapport
{
    echo "=== Rapport de vérification des services ==="
    echo "Date : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hôte : $(hostname -f)"
    echo ""

    for service in $(printf '%s\n' "${!resultats[@]}" | sort); do
        printf "%-20s %s\n" "$service" "${resultats[$service]}"
    done

    echo ""
    echo "Résumé : $ok OK, $ko en anomalie sur ${#services[@]} services vérifiés."
} | tee "$RAPPORT"

# Code de retour selon le résultat
(( ko == 0 ))
