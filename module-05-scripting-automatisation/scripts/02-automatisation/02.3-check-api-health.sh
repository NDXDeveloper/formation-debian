#!/usr/bin/env bash
#
# Nom         : 02.3-check-api-health.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.3 — Interaction avec des APIs REST
# Source      : module-05-scripting-automatisation/02.3-interaction-apis-rest.md
# Description : Vérification de santé d'une liste d'endpoints HTTP/HTTPS avec retry,
#               timeout et code de retour structuré.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# check_api_health.sh — Vérification de santé de services via leurs endpoints API
#
set -euo pipefail

log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_error() { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

declare -A ENDPOINTS=(
    [api-principale]="https://api.example.com/health"
    [grafana]="https://grafana.example.com/api/health"
    [gitlab]="https://gitlab.example.com/-/readiness"
    [registry]="https://registry.example.com/v2/"
)

declare -a alertes=()

verifier_endpoint() {
    local nom=$1
    local url=$2

    local code_http temps_reponse
    local resultats
    resultats=$(curl -sS -o /dev/null \
        --max-time 10 \
        --connect-timeout 5 \
        -w '%{http_code} %{time_total}' \
        "$url" 2>/dev/null) || {
            alertes+=("$nom : connexion impossible ($url)")
            return 1
        }

    code_http=$(awk '{print $1}' <<< "$resultats")
    temps_reponse=$(awk '{print $2}' <<< "$resultats")

    if [[ "$code_http" != 2* ]]; then
        alertes+=("$nom : HTTP $code_http ($url)")
        return 1
    fi

    # Alerter si le temps de réponse dépasse 5 secondes
    if (( $(echo "$temps_reponse > 5.0" | bc -l) )); then
        alertes+=("$nom : temps de réponse dégradé (${temps_reponse}s)")
    fi

    log_info "$nom : OK (HTTP $code_http, ${temps_reponse}s)"
}

main() {
    log_info "Vérification des endpoints de santé"

    for nom in "${!ENDPOINTS[@]}"; do
        verifier_endpoint "$nom" "${ENDPOINTS[$nom]}" || true
    done

    if (( ${#alertes[@]} > 0 )); then
        log_error "${#alertes[@]} problème(s) détecté(s) :"
        for alerte in "${alertes[@]}"; do
            log_error "  - $alerte"
        done
        exit 1
    fi

    log_info "Tous les endpoints sont opérationnels"
}

main "$@"
