#!/usr/bin/env bash
#
# Nom         : 02.1-rotate-app-logs.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Rotation et archivage des logs applicatifs pour les apps qui
#               n'utilisent pas logrotate.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# rotate_app_logs.sh — Rotation et archivage des logs applicatifs
#
# Gère la rotation des logs pour les applications qui n'utilisent pas
# logrotate ou qui nécessitent une logique de rétention personnalisée.
#
# Codes de retour :
#   0  Rotation effectuée avec succès
#   1  Erreur de configuration
#   2  Erreur lors de la rotation
#
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# ─── Configuration ───────────────────────────────────────────
readonly LOG_DIR="${LOG_DIR:-/var/log/monapp}"
readonly ARCHIVE_DIR="${ARCHIVE_DIR:-/var/log/monapp/archives}"
readonly RETENTION_JOURS="${RETENTION_JOURS:-30}"
readonly TAILLE_MAX_MO="${TAILLE_MAX_MO:-100}"
readonly PATTERN="*.log"

# ─── Logging ─────────────────────────────────────────────────
log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_error() { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

# ─── Fonctions ───────────────────────────────────────────────
verifier_prerequis() {
    [[ -d "$LOG_DIR" ]] || { log_error "Répertoire de logs inexistant : $LOG_DIR"; exit 1; }
    mkdir -p "$ARCHIVE_DIR"
}

rotation_logs_actifs() {
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local -i nb_rotations=0

    while IFS= read -r -d '' fichier; do
        local nom
        nom=$(basename "$fichier")
        local taille_mo
        taille_mo=$(( $(stat -c%s "$fichier") / 1024 / 1024 ))

        # Tourner si le fichier dépasse la taille maximale
        if (( taille_mo >= TAILLE_MAX_MO )); then
            local archive="${ARCHIVE_DIR}/${nom%.log}_${timestamp}.log.gz"
            log_info "Rotation de $nom (${taille_mo} Mo) → $(basename "$archive")"
            gzip -c "$fichier" > "$archive"
            truncate -s 0 "$fichier"
            (( nb_rotations++ ))
        fi
    done < <(find "$LOG_DIR" -maxdepth 1 -name "$PATTERN" -type f -print0)

    log_info "$nb_rotations fichier(s) tourné(s)"
}

purger_archives_anciennes() {
    local -i nb_purges=0

    while IFS= read -r -d '' archive; do
        log_info "Purge de l'archive ancienne : $(basename "$archive")"
        rm -f "$archive"
        (( nb_purges++ ))
    done < <(find "$ARCHIVE_DIR" -name "*.log.gz" -type f -mtime "+$RETENTION_JOURS" -print0)

    if (( nb_purges > 0 )); then
        log_info "$nb_purges archive(s) purgée(s) (rétention : $RETENTION_JOURS jours)"
    else
        log_info "Aucune archive à purger"
    fi
}

rapport_espace() {
    local taille_logs
    taille_logs=$(du -sh "$LOG_DIR" 2>/dev/null | awk '{print $1}')
    local taille_archives
    taille_archives=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | awk '{print $1}')
    local nb_archives
    nb_archives=$(find "$ARCHIVE_DIR" -name "*.log.gz" -type f 2>/dev/null | wc -l)

    log_info "Espace utilisé — logs actifs : $taille_logs, archives : $taille_archives ($nb_archives fichiers)"
}

# ─── Main ────────────────────────────────────────────────────
main() {
    log_info "Début de la rotation des logs ($LOG_DIR)"
    verifier_prerequis
    rotation_logs_actifs
    purger_archives_anciennes
    rapport_espace
    log_info "Rotation terminée"
}

main "$@"
