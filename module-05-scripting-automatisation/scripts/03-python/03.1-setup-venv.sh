#!/usr/bin/env bash
#
# Nom         : 03.1-setup-venv.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.3.1 — Python sur Debian (venv, PEP 668)
# Source      : module-05-scripting-automatisation/03.1-python-debian-venv.md
# Description : Création et mise à jour idempotente du venv d'administration (PEP
#               668-compliant).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# setup_venv.sh — Création et mise à jour du venv d'administration
#
set -euo pipefail

readonly VENV_DIR="/opt/scripts/admin-venv"
readonly REQUIREMENTS="/opt/scripts/requirements.txt"

# Installer les prérequis système si nécessaire
install_system_deps() {
    local -a paquets_requis=("python3-venv" "python3-dev" "python3-pip")
    local -a a_installer=()

    for paquet in "${paquets_requis[@]}"; do
        dpkg -l "$paquet" 2>/dev/null | grep -q "^ii" || a_installer+=("$paquet")
    done

    if (( ${#a_installer[@]} > 0 )); then
        echo "Installation des prérequis système : ${a_installer[*]}"
        apt-get update -qq
        apt-get install -y -qq "${a_installer[@]}"
    fi
}

# Créer ou mettre à jour le venv
setup_venv() {
    if [[ ! -d "$VENV_DIR" ]]; then
        echo "Création du venv : $VENV_DIR"
        python3 -m venv --upgrade-deps "$VENV_DIR"
    else
        echo "Venv existant, mise à jour de pip..."
        "$VENV_DIR/bin/pip" install --upgrade pip
    fi

    if [[ -f "$REQUIREMENTS" ]]; then
        echo "Installation des dépendances depuis $REQUIREMENTS"
        "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS"
    fi

    echo "Venv prêt : $VENV_DIR"
    "$VENV_DIR/bin/python3" --version
    "$VENV_DIR/bin/pip" list
}

main() {
    (( EUID == 0 )) || { echo "Ce script doit être exécuté en tant que root" >&2; exit 1; }
    install_system_deps
    setup_venv
}

main "$@"
