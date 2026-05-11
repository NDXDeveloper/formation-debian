#!/usr/bin/env bash
#
# Nom         : 02.4-report-html.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.4 — Rapports et notifications
# Source      : module-05-scripting-automatisation/02.4-rapports-notifications.md
# Description : Variante du rapport système au format HTML, prête à être envoyée par
#               email avec mail/msmtp.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

generer_rapport_html() {
    local hostname
    hostname=$(hostname -f)
    local date_rapport
    date_rapport=$(date '+%Y-%m-%d %H:%M:%S %Z')

    # Fonction helper pour la couleur selon le pourcentage
    couleur_seuil() {
        local pourcent=$1
        if (( pourcent >= 90 )); then echo "#dc3545"   # Rouge
        elif (( pourcent >= 75 )); then echo "#ffc107"  # Orange
        else echo "#28a745"                              # Vert
        fi
    }

    cat << 'HTMLHEAD'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
    body { font-family: -apple-system, Arial, sans-serif; margin: 20px; color: #333; background: #f8f9fa; }
    .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
    h2 { color: #34495e; margin-top: 25px; }
    table { border-collapse: collapse; width: 100%; margin: 15px 0; }
    th { background: #2c3e50; color: white; padding: 10px 12px; text-align: left; }
    td { padding: 8px 12px; border-bottom: 1px solid #ecf0f1; }
    tr:hover { background: #f1f3f5; }
    .badge { padding: 3px 10px; border-radius: 12px; color: white; font-size: 0.85em; font-weight: bold; }
    .ok { background: #28a745; }
    .warn { background: #ffc107; color: #333; }
    .error { background: #dc3545; }
    .footer { margin-top: 30px; padding-top: 15px; border-top: 1px solid #ecf0f1; color: #7f8c8d; font-size: 0.85em; }
</style>
</head>
<body>
<div class="container">
HTMLHEAD

    printf '<h1>Rapport système — %s</h1>\n' "$hostname"
    printf '<p>Généré le %s</p>\n' "$date_rapport"

    # ── Section Disques ──
    echo '<h2>Utilisation des disques</h2>'
    echo '<table><tr><th>Partition</th><th>Taille</th><th>Utilisé</th><th>Disponible</th><th>Utilisation</th></tr>'

    while read -r target size used avail pcent; do
        local pourcent=${pcent%\%}
        local couleur
        couleur=$(couleur_seuil "$pourcent")
        printf '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td>' \
            "$target" "$size" "$used" "$avail"
        printf '<td><span class="badge" style="background:%s">%s</span></td></tr>\n' \
            "$couleur" "$pcent"
    done < <(df -h --output=target,size,used,avail,pcent -x tmpfs -x devtmpfs | tail -n +2)

    echo '</table>'

    # ── Section Services ──
    echo '<h2>Services critiques</h2>'
    echo '<table><tr><th>Service</th><th>État</th><th>PID</th></tr>'

    local -a services=("ssh" "cron" "nginx" "postgresql")
    for svc in "${services[@]}"; do
        local etat_class etat_label pid
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            etat_class="ok"
            etat_label="Actif"
            pid=$(systemctl show -p MainPID --value "$svc" 2>/dev/null || echo "-")
        else
            etat_class="error"
            etat_label="Inactif"
            pid="-"
        fi
        printf '<tr><td>%s</td><td><span class="badge %s">%s</span></td><td>%s</td></tr>\n' \
            "$svc" "$etat_class" "$etat_label" "$pid"
    done

    echo '</table>'

    # ── Section Mémoire ──
    echo '<h2>Mémoire</h2>'
    local mem_total mem_used mem_pourcent
    mem_total=$(free -m | awk '/^Mem:/{print $2}')
    mem_used=$(free -m | awk '/^Mem:/{print $3}')
    mem_pourcent=$(( mem_used * 100 / mem_total ))
    local mem_couleur
    mem_couleur=$(couleur_seuil "$mem_pourcent")

    printf '<p>Utilisation : <strong>%d Mo</strong> / %d Mo ' "$mem_used" "$mem_total"
    printf '(<span class="badge" style="background:%s">%d%%</span>)</p>\n' \
        "$mem_couleur" "$mem_pourcent"

    # ── Section Mises à jour ──
    echo '<h2>Mises à jour</h2>'
    local nb_updates nb_security
    nb_updates=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo 0)
    nb_security=$(apt-get -s upgrade 2>/dev/null | grep -c "security" || echo 0)

    if (( nb_updates > 0 )); then
        printf '<p><span class="badge warn">%d paquet(s)</span> à mettre à jour' "$nb_updates"
        if (( nb_security > 0 )); then
            printf ' dont <span class="badge error">%d de sécurité</span>' "$nb_security"
        fi
        echo '</p>'
    else
        echo '<p><span class="badge ok">Système à jour</span></p>'
    fi

    # ── Footer ──
    cat << HTMLFOOT
<div class="footer">
    <p>Rapport généré automatiquement par ${SCRIPT_NAME:-rapport_systeme.sh} sur ${hostname}.</p>
</div>
</div>
</body>
</html>
HTMLFOOT
}

generer_rapport_html
