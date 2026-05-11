#!/usr/bin/env bash
#
# Nom         : 01.4-deploy-rollback.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.1.4 — Gestion des erreurs et trap
# Source      : module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md
# Description : Pattern de déploiement multiphase avec rollback automatique en cas
#               d'erreur (sauvegarde + bascule + reload).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

readonly BACKUP_DIR="/var/backups/deploy"
DEPLOY_PHASE="init"

cleanup_on_failure() {
    local code_retour=$?
    if (( code_retour != 0 )); then
        echo "ERREUR en phase '$DEPLOY_PHASE' (code $code_retour)" >&2
        echo "Rollback en cours..." >&2

        case "$DEPLOY_PHASE" in
            config)
                echo "Restauration de la configuration..." >&2
                cp "$BACKUP_DIR/nginx.conf.bak" /etc/nginx/nginx.conf 2>/dev/null || true
                ;;
            service)
                echo "Redémarrage de l'ancienne version..." >&2
                systemctl restart nginx 2>/dev/null || true
                ;;
        esac

        echo "Rollback terminé." >&2
    fi
}

trap cleanup_on_failure EXIT

# Phase 1 : sauvegarde
DEPLOY_PHASE="backup"
mkdir -p "$BACKUP_DIR"
cp /etc/nginx/nginx.conf "$BACKUP_DIR/nginx.conf.bak"

# Phase 2 : nouvelle configuration
DEPLOY_PHASE="config"
cp nouvelle_config.conf /etc/nginx/nginx.conf
nginx -t                             # Valider la syntaxe — si échec, rollback automatique

# Phase 3 : redémarrage du service
DEPLOY_PHASE="service"
systemctl reload nginx

DEPLOY_PHASE="terminé"
echo "Déploiement réussi."
