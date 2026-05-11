#!/usr/bin/env bash
#
# Nom         : 04.3-mon-app-wrapper.sh
# Module      : 3 — Administration système
# Section     : 3.4.3 — Services personnalisés
# Source      : module-03-administration-systeme/04.3-services-personnalises.md
# Description : Wrapper de démarrage Type=forking : lance l'app en arrière-plan et
#               attend qu'elle soit prête.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
/srv/app/bin/server &
APP_PID=$!

# Attendre que l'application soit prête (par exemple, que le port soit ouvert)
while ! ss -tlnp | grep -q ':8080'; do
    sleep 0.5
done

# Notifier systemd
systemd-notify --ready --pid=$APP_PID
wait $APP_PID
