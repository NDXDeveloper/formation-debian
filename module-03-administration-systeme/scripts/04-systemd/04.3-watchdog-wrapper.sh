#!/usr/bin/env bash
#
# Nom         : 04.3-watchdog-wrapper.sh
# Module      : 3 — Administration système
# Section     : 3.4.3 — Services personnalisés
# Source      : module-03-administration-systeme/04.3-services-personnalises.md
# Description : Wrapper avec systemd-notify pour Type=notify (signale READY=1 puis
#               WATCHDOG=1 périodiquement).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
/srv/app/bin/server &
APP_PID=$!
systemd-notify --ready --pid=$APP_PID

while kill -0 $APP_PID 2>/dev/null; do
    if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        systemd-notify WATCHDOG=1
    fi
    sleep 15
done
