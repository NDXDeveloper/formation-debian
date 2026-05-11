#!/usr/bin/env bash
#
# Nom         : 02.4-report-system.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.4 — Rapports et notifications
# Source      : module-05-scripting-automatisation/02.4-rapports-notifications.md
# Description : Génération d'un rapport système quotidien au format texte (uptime,
#               disque, mémoire, services).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

generer_rapport_systeme() {
    local hostname
    hostname=$(hostname -f)
    local date_rapport
    date_rapport=$(date '+%Y-%m-%d %H:%M:%S %Z')
    local uptime_info
    uptime_info=$(uptime -p)
    local noyau
    noyau=$(uname -r)
    local debian_version
    debian_version=$(cat /etc/debian_version)

    cat << EOF
╔══════════════════════════════════════════════════════════════╗
║              RAPPORT QUOTIDIEN — ÉTAT SYSTÈME               ║
╠══════════════════════════════════════════════════════════════╣
║  Serveur : ${hostname}
║  Date    : ${date_rapport}
║  Uptime  : ${uptime_info}
║  Système : Debian ${debian_version} — Noyau ${noyau}
╚══════════════════════════════════════════════════════════════╝

─── UTILISATION DES DISQUES ───────────────────────────────────
$(df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | column -t)

─── MÉMOIRE ───────────────────────────────────────────────────
$(free -h)

─── CHARGE SYSTÈME ────────────────────────────────────────────
$(cat /proc/loadavg | awk '{printf "Load average : %s (1min) %s (5min) %s (15min)\n", $1, $2, $3}')
Processus actifs : $(ps aux --no-heading | wc -l)

─── SERVICES CRITIQUES ────────────────────────────────────────
$(for svc in ssh cron nginx postgresql; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        printf "  %-20s [  OK  ]\n" "$svc"
    elif systemctl list-unit-files "$svc.service" &>/dev/null; then
        printf "  %-20s [ERREUR]\n" "$svc"
    fi
done)

─── CONNEXIONS RÉSEAU ─────────────────────────────────────────
Ports en écoute : $(ss -tlnp | tail -n +2 | wc -l)
Connexions établies : $(ss -tnp state established | tail -n +2 | wc -l)

─── DERNIÈRES CONNEXIONS ──────────────────────────────────────
$(last -n 5 --time-format iso | head -5)

─── MISES À JOUR DISPONIBLES ──────────────────────────────────
$(apt-get -s upgrade 2>/dev/null | grep "^Inst" | wc -l) paquet(s) à mettre à jour
$(apt-get -s upgrade 2>/dev/null | grep -c "security" || echo 0) mise(s) à jour de sécurité

══════════════════════════════════════════════════════════════
  Rapport généré automatiquement — $(date '+%Y-%m-%d %H:%M:%S')
══════════════════════════════════════════════════════════════
EOF
}

# Utilisation : stdout exploitable par redirection, pipe ou email
generer_rapport_systeme
