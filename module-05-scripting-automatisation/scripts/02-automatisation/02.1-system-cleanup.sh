#!/usr/bin/env bash
#
# Nom         : 02.1-system-cleanup.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Nettoyage automatisé hebdomadaire : APT cache, journaux, /tmp,
#               fichiers core, anciens kernels.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# system_cleanup.sh — Nettoyage automatisé de l'espace disque
#
# Ce script est conçu pour être exécuté périodiquement (hebdomadaire).
# En mode dry-run (-n), il affiche les actions sans les exécuter.
#
# Codes de retour :
#   0  Nettoyage effectué
#   1  Erreur
#
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
DRY_RUN=0

log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

executer() {
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] $*"
    else
        "$@"
    fi
}

taille_avant_apres() {
    # Appeler en début et fin d'opération pour mesurer le gain
    df -BM --output=avail / | tail -1 | tr -d ' M'
}

# ─── Actions de nettoyage ────────────────────────────────────

nettoyer_cache_apt() {
    log_info "Nettoyage du cache APT..."
    local taille
    taille=$(du -sm /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    log_info "  Cache actuel : ${taille} Mo"

    executer apt-get clean -y
    executer apt-get autoclean -y

    # Supprimer les paquets orphelins
    local orphelins
    orphelins=$(apt-get autoremove --dry-run 2>/dev/null \
        | grep -c "^Remv" || true)
    if (( orphelins > 0 )); then
        log_info "  $orphelins paquet(s) orphelin(s) à supprimer"
        executer apt-get autoremove -y --purge
    fi
}

purger_configs_residuelles() {
    log_info "Purge des configurations résiduelles..."
    local -a paquets_rc
    mapfile -t paquets_rc < <(dpkg -l | awk '/^rc/{print $2}')

    if (( ${#paquets_rc[@]} > 0 )); then
        log_info "  ${#paquets_rc[@]} paquet(s) en état 'rc' à purger"
        executer dpkg --purge "${paquets_rc[@]}"
    else
        log_info "  Aucune configuration résiduelle"
    fi
}

nettoyer_fichiers_temporaires() {
    log_info "Nettoyage des fichiers temporaires..."

    # Fichiers dans /tmp de plus de 7 jours
    local nb_tmp
    nb_tmp=$(find /tmp -type f -mtime +7 -not -path "/tmp/systemd-*" 2>/dev/null | wc -l)
    if (( nb_tmp > 0 )); then
        log_info "  $nb_tmp fichier(s) dans /tmp de plus de 7 jours"
        executer find /tmp -type f -mtime +7 -not -path "/tmp/systemd-*" -delete
    fi

    # Fichiers dans /var/tmp de plus de 30 jours
    local nb_var_tmp
    nb_var_tmp=$(find /var/tmp -type f -mtime +30 2>/dev/null | wc -l)
    if (( nb_var_tmp > 0 )); then
        log_info "  $nb_var_tmp fichier(s) dans /var/tmp de plus de 30 jours"
        executer find /var/tmp -type f -mtime +30 -delete
    fi

    # Répertoires vides dans /tmp
    executer find /tmp -mindepth 1 -type d -empty -delete 2>/dev/null || true
}

nettoyer_journald() {
    log_info "Nettoyage des journaux systemd..."
    local taille_avant
    taille_avant=$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+[GMK]' || echo "N/A")
    log_info "  Taille actuelle : $taille_avant"

    executer journalctl --vacuum-time=30d --vacuum-size=500M
}

nettoyer_anciens_noyaux() {
    log_info "Nettoyage des anciens noyaux..."
    local noyau_actuel
    noyau_actuel=$(uname -r | sed 's/-[a-z].*$//')

    local -a anciens_noyaux
    mapfile -t anciens_noyaux < <(
        dpkg -l 'linux-image-*' 'linux-headers-*' 2>/dev/null \
            | awk '/^ii/{print $2}' \
            | grep -v "$noyau_actuel" \
            | grep -v "linux-image-amd64" \
            | grep -v "linux-headers-amd64" \
            || true
    )

    if (( ${#anciens_noyaux[@]} > 0 )); then
        log_info "  ${#anciens_noyaux[@]} paquet(s) de noyaux anciens à supprimer"
        for pkg in "${anciens_noyaux[@]}"; do
            log_info "    - $pkg"
        done
        executer apt-get purge -y "${anciens_noyaux[@]}"
    else
        log_info "  Aucun ancien noyau à supprimer"
    fi
}

nettoyer_logs_applicatifs() {
    log_info "Nettoyage des logs applicatifs compressés anciens..."

    # Supprimer les logs compressés de plus de 90 jours
    local nb_vieux_logs
    nb_vieux_logs=$(find /var/log -name "*.gz" -mtime +90 -type f 2>/dev/null | wc -l)
    if (( nb_vieux_logs > 0 )); then
        log_info "  $nb_vieux_logs archive(s) de logs de plus de 90 jours"
        executer find /var/log -name "*.gz" -mtime +90 -type f -delete
    fi

    # Supprimer les logs numérotés anciens (syslog.1, auth.log.2, etc.)
    local nb_rotated
    nb_rotated=$(find /var/log -regextype posix-extended -regex '.*\.[0-9]+$' -mtime +30 -type f 2>/dev/null | wc -l)
    if (( nb_rotated > 0 )); then
        log_info "  $nb_rotated log(s) tournés non compressés de plus de 30 jours"
        executer find /var/log -regextype posix-extended -regex '.*\.[0-9]+$' -mtime +30 -type f -delete
    fi
}

# ─── Main ────────────────────────────────────────────────────
main() {
    # Parser les arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run) DRY_RUN=1; shift ;;
            -h|--help)
                echo "Usage: $SCRIPT_NAME [-n|--dry-run] [-h|--help]"
                exit 0
                ;;
            *) log_warn "Option inconnue : $1"; shift ;;
        esac
    done

    (( EUID == 0 )) || { log_warn "Ce script doit être exécuté en tant que root"; exit 1; }

    log_info "=== Début du nettoyage système ==="
    (( DRY_RUN )) && log_warn "Mode simulation activé"

    local espace_avant
    espace_avant=$(taille_avant_apres)

    nettoyer_cache_apt
    purger_configs_residuelles
    nettoyer_fichiers_temporaires
    nettoyer_journald
    nettoyer_anciens_noyaux
    nettoyer_logs_applicatifs

    local espace_apres
    espace_apres=$(taille_avant_apres)
    local gain=$(( espace_apres - espace_avant ))

    log_info "=== Nettoyage terminé ==="
    log_info "Espace récupéré sur / : ${gain} Mo"
}

main "$@"
