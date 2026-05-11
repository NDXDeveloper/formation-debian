#!/usr/bin/env bash
#
# Nom         : 04.4-journal-maintenance.sh
# Module      : 3 — Administration système
# Section     : 3.4.4 — journald
# Source      : module-03-administration-systeme/04.4-journald.md
# Description : Script de maintenance journald : vérifie l'intégrité et alerte en cas
#               de corruption.
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
# À exécuter via un timer systemd quotidien

# Vérifier l'intégrité
journalctl --verify 2>&1 | grep -i fail && echo "ALERTE: corruption du journal"

# Maintenir la taille sous contrôle
journalctl --vacuum-size=2G --vacuum-time=30d

# Reporter l'utilisation
echo "Espace journal : $(journalctl --disk-usage)"
