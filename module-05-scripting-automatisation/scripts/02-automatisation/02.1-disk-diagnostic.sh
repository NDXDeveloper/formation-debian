#!/usr/bin/env bash
#
# Nom         : 02.1-disk-diagnostic.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Diagnostic complet de l'utilisation disque : top dossiers, top
#               fichiers, inodes, snapshots.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# disk_diagnostic.sh — Diagnostic de l'utilisation de l'espace disque
#
# Produit un rapport sur stdout, exploitable en redirection ou par mail.
#
set -euo pipefail

readonly SEUIL_POURCENTAGE="${SEUIL_POURCENTAGE:-80}"

log_info()  { printf '[%s] [INFO] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

rapport_partitions() {
    echo "=== Utilisation des partitions ==="
    echo ""
    df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | head -1
    df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | tail -n +2 | sort -k5 -rn
    echo ""
}

partitions_critiques() {
    local -i nb_critiques=0

    while read -r target _ _ _ pcent; do
        local pourcent=${pcent%\%}
        if (( pourcent >= SEUIL_POURCENTAGE )); then
            echo "ALERTE : $target à ${pourcent}% d'utilisation"
            (( nb_critiques++ ))
        fi
    done < <(df --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | tail -n +2)

    return $(( nb_critiques > 0 ? 1 : 0 ))
}

top_repertoires() {
    local point_montage=${1:-/}
    echo "=== Top 15 des répertoires les plus volumineux ($point_montage) ==="
    echo ""
    du -xh --max-depth=2 "$point_montage" 2>/dev/null | sort -rh | head -15
    echo ""
}

fichiers_volumineux() {
    local point_montage=${1:-/}
    local seuil_mo=${2:-100}
    echo "=== Fichiers de plus de ${seuil_mo} Mo ($point_montage) ==="
    echo ""
    find "$point_montage" -xdev -type f -size "+${seuil_mo}M" -printf '%s %p\n' 2>/dev/null \
        | sort -rn \
        | head -20 \
        | awk '{printf "%8.1f Mo  %s\n", $1/1024/1024, $2}'
    echo ""
}

fichiers_anciens_tmp() {
    echo "=== Fichiers temporaires de plus de 7 jours ==="
    echo ""
    local -i total=0
    local taille_totale

    for dir in /tmp /var/tmp; do
        [[ -d "$dir" ]] || continue
        local nb
        nb=$(find "$dir" -type f -mtime +7 2>/dev/null | wc -l)
        total+=$nb
    done

    taille_totale=$(find /tmp /var/tmp -type f -mtime +7 -printf '%s\n' 2>/dev/null \
        | awk '{s+=$1} END{printf "%.1f Mo", s/1024/1024}')

    echo "$total fichier(s) temporaires anciens occupant $taille_totale"
    echo ""
}

paquets_residuels() {
    echo "=== Paquets résiduels et caches APT ==="
    echo ""
    local nb_rc
    nb_rc=$(dpkg -l | grep -c "^rc" || true)
    echo "Paquets en état 'rc' (config résiduelle) : $nb_rc"

    local cache_apt
    cache_apt=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}')
    echo "Cache APT : $cache_apt"

    local noyaux_anciens
    noyaux_anciens=$(dpkg -l 'linux-image-*' 2>/dev/null \
        | awk '/^ii/{print $2}' \
        | grep -v "$(uname -r | sed 's/-[a-z].*$//')" \
        | wc -l || true)
    echo "Anciens noyaux installés : $noyaux_anciens"
    echo ""
}

journald_espace() {
    echo "=== Espace occupé par journald ==="
    echo ""
    journalctl --disk-usage 2>/dev/null || echo "journalctl non disponible"
    echo ""
}

main() {
    log_info "Diagnostic de l'espace disque"

    echo "================================================================"
    echo "  RAPPORT DIAGNOSTIC ESPACE DISQUE"
    echo "  Serveur : $(hostname -f)"
    echo "  Date    : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "================================================================"
    echo ""

    rapport_partitions
    top_repertoires /
    fichiers_volumineux / 100
    fichiers_anciens_tmp
    paquets_residuels
    journald_espace

    echo "================================================================"

    if ! partitions_critiques > /dev/null 2>&1; then
        log_info "Des partitions dépassent le seuil de ${SEUIL_POURCENTAGE}%"
        exit 1
    fi

    log_info "Diagnostic terminé — aucune partition critique"
}

main "$@"
