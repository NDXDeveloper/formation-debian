#!/usr/bin/env bash
#
# Nom         : 03.1-check-venv.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.3.1 — Python sur Debian (venv, PEP 668)
# Source      : module-05-scripting-automatisation/03.1-python-debian-venv.md
# Description : Vérification d'environnement Python (version, venv actif, paquets
#               installés, conformité).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
set -euo pipefail

echo "=== Vérification de l'environnement Python ==="

echo ""
echo "--- Interpréteur système ---"
echo "Python3 : $(python3 --version 2>&1)"
echo "Chemin  : $(which python3)"
echo "Prefix  : $(python3 -c 'import sys; print(sys.prefix)')"

echo ""
echo "--- Modules essentiels ---"
for module in venv pip json pathlib subprocess logging; do
    if python3 -c "import $module" 2>/dev/null; then
        printf "  %-15s [OK]\n" "$module"
    else
        printf "  %-15s [MANQUANT]\n" "$module"
    fi
done

echo ""
echo "--- PEP 668 ---"
if [[ -f "/usr/lib/python3.13/EXTERNALLY-MANAGED" ]]; then
    echo "  Environnement externally-managed : OUI (PEP 668 active)"
    echo "  → Utiliser un venv pour pip install"
else
    echo "  Environnement externally-managed : NON"
fi

echo ""
echo "--- python3-venv ---"
if dpkg -l python3-venv 2>/dev/null | grep -q "^ii"; then
    echo "  python3-venv : installé"
else
    echo "  python3-venv : NON INSTALLÉ"
    echo "  → sudo apt install python3-venv"
fi

# Vérifier un venv existant si le chemin est fourni
if [[ -n "${1:-}" && -d "$1" ]]; then
    echo ""
    echo "--- Venv : $1 ---"
    echo "  Python : $("$1/bin/python3" --version 2>&1)"
    echo "  Pip    : $("$1/bin/pip" --version 2>&1)"
    echo "  Paquets installés :"
    "$1/bin/pip" list --format=columns 2>/dev/null | head -15
fi

echo ""
echo "=== Vérification terminée ==="
