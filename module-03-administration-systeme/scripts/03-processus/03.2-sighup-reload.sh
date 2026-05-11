#!/usr/bin/env bash
#
# Nom         : 03.2-sighup-reload.sh
# Module      : 3 — Administration système
# Section     : 3.3.2 — Signaux et kill
# Source      : module-03-administration-systeme/03.2-signaux-kill.md
# Description : Démon qui recharge sa configuration sur SIGHUP (sans redémarrage).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# Recharger la configuration sur SIGHUP
reload_config() {
    echo "Rechargement de la configuration..."
    source /etc/mon-daemon/config.conf
    echo "Configuration rechargée"
}
trap reload_config HUP

# Ignorer SIGINT (Ctrl+C ne doit pas interrompre ce script critique)
trap '' INT

# Terminaison propre sur SIGTERM
graceful_shutdown() {
    echo "Arrêt en cours, finalisation des tâches..."
    # Attendre la fin du traitement courant
    wait
    echo "Arrêt terminé"
    exit 0
}
trap graceful_shutdown TERM

# Boucle principale
while true; do
    process_next_job
    sleep 5
done
