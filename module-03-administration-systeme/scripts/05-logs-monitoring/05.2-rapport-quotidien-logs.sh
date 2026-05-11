#!/usr/bin/env bash
#
# Nom         : 05.2-rapport-quotidien-logs.sh
# Module      : 3 — Administration système
# Section     : 3.5.2 — Analyse de logs
# Source      : module-03-administration-systeme/05.2-analyse-logs.md
# Description : Génère un rapport de synthèse des logs de la veille (events critiques,
#               services fail, auth).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
HIER=$(date -d yesterday +%Y-%m-%d)

echo "=== Rapport de logs — $HIER ==="
echo ""

echo "--- Erreurs système ---"
journalctl --since "$HIER 00:00" --until "$HIER 23:59" -p err --no-pager | wc -l
echo " erreurs enregistrées"
echo ""

echo "--- Connexions SSH ---"
echo "Réussies: $(journalctl --since "$HIER" --until "$HIER 23:59" -u ssh -g "Accepted" --no-pager | wc -l)"
echo "Échouées: $(journalctl --since "$HIER" --until "$HIER 23:59" -u ssh -g "Failed password" --no-pager | wc -l)"
echo ""

echo "--- Top 5 IPs tentatives SSH échouées ---"
journalctl --since "$HIER" --until "$HIER 23:59" -u ssh -g "Failed password" -o cat --no-pager | \
    grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -rn | head -5
echo ""

echo "--- Espace disque ---"
df -h / /var /home 2>/dev/null | awk 'NR>1 {print $6, $5, "utilisé sur", $2}'
echo ""

echo "--- Services en échec ---"
systemctl --failed --no-pager --no-legend
