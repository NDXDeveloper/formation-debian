#!/usr/bin/env bash
#
# Nom         : 02.3-gitlab-ops.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.3 — Interaction avec des APIs REST
# Source      : module-05-scripting-automatisation/02.3-interaction-apis-rest.md
# Description : Opérations courantes via l'API GitLab : lister projets, créer un
#               issue, déclencher un pipeline.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# gitlab_ops.sh — Opérations courantes via l'API GitLab
#
set -euo pipefail

readonly GITLAB_URL="${GITLAB_URL:-https://gitlab.example.com}"
readonly GITLAB_TOKEN="${GITLAB_TOKEN:?Variable GITLAB_TOKEN requise}"

gitlab_api() {
    local methode=$1
    local endpoint=$2
    local donnees=${3:-}

    local args=(-sSf --max-time 30)
    args+=(-H "PRIVATE-TOKEN: $GITLAB_TOKEN")
    args+=(-H "Content-Type: application/json")

    [[ -n "$donnees" ]] && args+=(-X "$methode" -d "$donnees") || args+=(-X "$methode")

    curl "${args[@]}" "${GITLAB_URL}/api/v4${endpoint}"
}

# Lister les projets d'un groupe
lister_projets() {
    local groupe=$1
    gitlab_api GET "/groups/$(jq -rn --arg g "$groupe" '$g | @uri')/projects?per_page=100" \
        | jq -r '.[].path_with_namespace'
}

# Créer un tag (release) sur un projet
creer_tag() {
    local projet_id=$1
    local tag=$2
    local ref=${3:-main}

    local payload
    payload=$(jq -n --arg t "$tag" --arg r "$ref" --arg m "Release $tag" \
        '{tag_name: $t, ref: $r, message: $m}')

    gitlab_api POST "/projects/$projet_id/repository/tags" "$payload" \
        | jq '{tag: .name, commit: .commit.short_id, message: .message}'
}

# Déclencher un pipeline
declencher_pipeline() {
    local projet_id=$1
    local branche=${2:-main}

    local payload
    payload=$(jq -n --arg ref "$branche" '{ref: $ref}')

    local resultat
    resultat=$(gitlab_api POST "/projects/$projet_id/pipeline" "$payload")

    local pipeline_id
    pipeline_id=$(echo "$resultat" | jq -r '.id')
    local web_url
    web_url=$(echo "$resultat" | jq -r '.web_url')

    echo "Pipeline #$pipeline_id déclenché : $web_url" >&2
    echo "$pipeline_id"
}

# Attendre la fin d'un pipeline
attendre_pipeline() {
    local projet_id=$1
    local pipeline_id=$2
    local timeout=${3:-600}

    local debut=$SECONDS

    while (( SECONDS - debut < timeout )); do
        local statut
        statut=$(gitlab_api GET "/projects/$projet_id/pipelines/$pipeline_id" \
            | jq -r '.status')

        case "$statut" in
            success)
                echo "Pipeline #$pipeline_id : succès" >&2
                return 0
                ;;
            failed|canceled)
                echo "Pipeline #$pipeline_id : $statut" >&2
                return 1
                ;;
            running|pending|created)
                echo "Pipeline #$pipeline_id : $statut ($(( SECONDS - debut ))s / ${timeout}s)" >&2
                sleep 15
                ;;
        esac
    done

    echo "Timeout après ${timeout}s en attendant le pipeline #$pipeline_id" >&2
    return 1
}
