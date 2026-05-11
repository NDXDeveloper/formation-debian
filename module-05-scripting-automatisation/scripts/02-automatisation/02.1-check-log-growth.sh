#!/usr/bin/env bash
#
# Nom         : 02.1-check-log-growth.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Détection de croissance anormale des logs (alerte si delta > seuil sur
#               24h).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# check_log_growth.sh — Détection de croissance anormale des logs
#
set -euo pipefail

readonly SEUIL_MO="${SEUIL_MO:-500}"
readonly LOG_DIRS=("/var/log" "/var/log/nginx" "/var/log/monapp")
readonly STATE_FILE="/var/lib/monscript/log_sizes.state"

log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

declare -A tailles_precedentes
declare -a alertes=()

charger_etat() {
    if [[ -f "$STATE_FILE" ]]; then
        while IFS='=' read -r cle valeur; do
            tailles_precedentes["$cle"]="$valeur"
        done < "$STATE_FILE"
    fi
}

sauvegarder_etat() {
    mkdir -p "$(dirname "$STATE_FILE")"
    : > "$STATE_FILE"
    for cle in "${!tailles_actuelles[@]}"; do
        echo "${cle}=${tailles_actuelles[$cle]}" >> "$STATE_FILE"
    done
}

declare -A tailles_actuelles

main() {
    charger_etat

    for repertoire in "${LOG_DIRS[@]}"; do
        [[ -d "$repertoire" ]] || continue

        while IFS= read -r -d '' fichier; do
            local taille_mo
            taille_mo=$(( $(stat -c%s "$fichier") / 1024 / 1024 ))
            tailles_actuelles["$fichier"]=$taille_mo

            # Comparer avec la taille précédente
            local taille_prec=${tailles_precedentes["$fichier"]:-0}
            local croissance=$(( taille_mo - taille_prec ))

            if (( croissance > SEUIL_MO )); then
                alertes+=("$fichier : +${croissance} Mo (${taille_prec} → ${taille_mo} Mo)")
            fi
        done < <(find "$repertoire" -maxdepth 1 -name "*.log" -type f -print0 2>/dev/null)
    done

    sauvegarder_etat

    if (( ${#alertes[@]} > 0 )); then
        log_warn "Croissance anormale détectée sur ${#alertes[@]} fichier(s) :"
        for alerte in "${alertes[@]}"; do
            log_warn "  $alerte"
        done
        exit 1
    fi

    log_info "Aucune croissance anormale détectée"
}

main "$@"
