#!/usr/bin/env bash
#
# Nom         : 02.1-provision-debian.sh
# Module      : 5 — Scripting et automatisation
# Section     : 5.2.1 — Scripts d'administration
# Source      : module-05-scripting-automatisation/02.1-scripts-administration.md
# Description : Provisionnement initial complet d'un serveur Debian fraîchement
#               installé (packages, sshd, ufw, sudoers, etc.).
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
#
# provision_debian.sh — Provisionnement initial d'un serveur Debian
#
# Ce script amène un serveur Debian fraîchement installé (netinst)
# dans un état standardisé pour la production.
#
# Usage : provision_debian.sh [-n] [-v]
#
# Prérequis : exécution en tant que root sur Debian 13 (Trixie)
#
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
VERBOSE=0
DRY_RUN=0

# ─── Logging ─────────────────────────────────────────────────
log_info()  { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_warn()  { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_error() { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_ok()    { printf '[%s] [OK]    %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

executer() {
    if (( DRY_RUN )); then
        log_info "[DRY-RUN] $*"
    else
        (( VERBOSE )) && log_info "exec: $*"
        "$@"
    fi
}

# ─── Vérifications ───────────────────────────────────────────
verifier_prerequis() {
    if (( EUID != 0 )); then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi

    if [[ ! -f /etc/debian_version ]]; then
        log_error "Ce script est conçu pour Debian"
        exit 1
    fi

    local version
    version=$(cat /etc/debian_version)
    log_info "Système détecté : Debian $version"
}

# ─── Configuration des dépôts ────────────────────────────────
# Note : Trixie installe par défaut /etc/apt/sources.list.d/debian.sources
# au format DEB822. Cette fonction utilise le format one-line classique dans
# /etc/apt/sources.list pour la simplicité de l'exemple. Si le fichier
# debian.sources existe déjà, la coexistence des deux fichiers fonctionne
# tant que les dépôts déclarés sont identiques.
configurer_depots() {
    log_info "Configuration des dépôts APT..."

    local sources_file="/etc/apt/sources.list"
    local deb822_file="/etc/apt/sources.list.d/debian.sources"

    # Si DEB822 est déjà configuré (installation Trixie native), ne rien faire
    if [[ -f "$deb822_file" ]] && grep -q "Suites: trixie" "$deb822_file" 2>/dev/null; then
        log_ok "Dépôts déjà configurés (format DEB822)"
        return 0
    fi

    if grep -q "trixie main contrib non-free-firmware" "$sources_file" 2>/dev/null; then
        log_ok "Dépôts déjà configurés (format one-line)"
        return 0
    fi

    # Sauvegarde avant modification
    [[ -f "$sources_file" ]] && cp "$sources_file" "${sources_file}.provision.bak"

    cat > "$sources_file" << 'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
EOF

    log_ok "Dépôts configurés"
}

# ─── Mise à jour du système ──────────────────────────────────
mise_a_jour_systeme() {
    log_info "Mise à jour du système..."
    executer apt-get update -qq
    executer apt-get upgrade -y -qq
    executer apt-get dist-upgrade -y -qq
    executer apt-get autoremove -y --purge -qq
    log_ok "Système à jour"
}

# ─── Installation des paquets de base ────────────────────────
installer_paquets_base() {
    log_info "Installation des paquets de base..."

    local -a paquets=(
        # Outils système essentiels
        vim curl wget htop iotop lsof strace
        # Réseau et diagnostic (iproute2 est déjà installé par défaut, net-tools reste utile pour `netstat`/`ifconfig`)
        net-tools dnsutils tcpdump mtr-tiny nmap
        # Gestion des paquets et archives
        # (apt-transport-https n'est plus nécessaire depuis Debian 11 :
        #  HTTPS est intégré nativement dans APT)
        ca-certificates gnupg
        # Monitoring et logs
        sysstat logrotate
        # Sécurité
        ufw fail2ban unattended-upgrades
        # Outils de scripting
        jq bc tree rsync
        # Système de fichiers
        parted gdisk
        # Synchronisation horaire (ntp a été remplacé par ntpsec dans Trixie ; chrony reste recommandé)
        chrony
    )

    # Filtrer les paquets déjà installés
    local -a a_installer=()
    for paquet in "${paquets[@]}"; do
        if ! dpkg -l "$paquet" 2>/dev/null | grep -q "^ii"; then
            a_installer+=("$paquet")
        fi
    done

    if (( ${#a_installer[@]} > 0 )); then
        log_info "  ${#a_installer[@]} paquet(s) à installer : ${a_installer[*]}"
        executer apt-get install -y -qq "${a_installer[@]}"
        log_ok "Paquets de base installés"
    else
        log_ok "Tous les paquets de base sont déjà installés"
    fi
}

# ─── Configuration du fuseau horaire et des locales ──────────
configurer_timezone_locales() {
    log_info "Configuration du fuseau horaire et des locales..."

    local timezone_cible="Europe/Paris"
    local timezone_actuel
    timezone_actuel=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone)

    if [[ "$timezone_actuel" != "$timezone_cible" ]]; then
        executer timedatectl set-timezone "$timezone_cible"
        log_ok "Fuseau horaire configuré : $timezone_cible"
    else
        log_ok "Fuseau horaire déjà correct : $timezone_cible"
    fi

    # S'assurer que la locale fr_FR.UTF-8 est générée
    if ! locale -a 2>/dev/null | grep -q "fr_FR.utf8"; then
        executer sed -i 's/^# *fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
        executer locale-gen
        log_ok "Locale fr_FR.UTF-8 générée"
    else
        log_ok "Locale fr_FR.UTF-8 déjà disponible"
    fi
}

# ─── Création de l'utilisateur d'administration ──────────────
creer_utilisateur_admin() {
    local username="${ADMIN_USER:-sysadmin}"
    log_info "Configuration de l'utilisateur d'administration : $username"

    if id "$username" &>/dev/null; then
        log_ok "Utilisateur $username déjà existant"
    else
        executer useradd -m -s /bin/bash -G sudo "$username"
        log_ok "Utilisateur $username créé"
    fi

    # Configurer sudo sans mot de passe (optionnel, pour l'automatisation)
    local sudoers_file="/etc/sudoers.d/$username"
    if [[ ! -f "$sudoers_file" ]]; then
        echo "$username ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
        chmod 440 "$sudoers_file"
        log_ok "Sudo sans mot de passe configuré pour $username"
    else
        log_ok "Configuration sudo déjà en place pour $username"
    fi

    # Déployer la clé SSH si fournie
    if [[ -n "${ADMIN_SSH_KEY:-}" ]]; then
        local ssh_dir="/home/$username/.ssh"
        mkdir -p "$ssh_dir"
        if ! grep -qF "$ADMIN_SSH_KEY" "$ssh_dir/authorized_keys" 2>/dev/null; then
            echo "$ADMIN_SSH_KEY" >> "$ssh_dir/authorized_keys"
            chmod 700 "$ssh_dir"
            chmod 600 "$ssh_dir/authorized_keys"
            chown -R "$username:$username" "$ssh_dir"
            log_ok "Clé SSH déployée pour $username"
        else
            log_ok "Clé SSH déjà présente pour $username"
        fi
    fi
}

# ─── Sécurisation SSH ────────────────────────────────────────
securiser_ssh() {
    log_info "Sécurisation du serveur SSH..."

    local sshd_config="/etc/ssh/sshd_config"
    local -i modifications=0

    appliquer_config_ssh() {
        local parametre=$1
        local valeur=$2

        if grep -qE "^${parametre}\s+${valeur}$" "$sshd_config" 2>/dev/null; then
            return 0
        fi

        # Décommenter et modifier, ou ajouter
        if grep -qE "^#?\s*${parametre}\b" "$sshd_config"; then
            sed -i "s/^#*\s*${parametre}\b.*/${parametre} ${valeur}/" "$sshd_config"
        else
            echo "${parametre} ${valeur}" >> "$sshd_config"
        fi
        (( modifications++ ))
    }

    appliquer_config_ssh "PermitRootLogin" "no"
    appliquer_config_ssh "PasswordAuthentication" "no"
    appliquer_config_ssh "PubkeyAuthentication" "yes"
    appliquer_config_ssh "X11Forwarding" "no"
    appliquer_config_ssh "MaxAuthTries" "3"
    appliquer_config_ssh "ClientAliveInterval" "300"
    appliquer_config_ssh "ClientAliveCountMax" "2"

    if (( modifications > 0 )); then
        # Vérifier la syntaxe avant de recharger
        if sshd -t 2>/dev/null; then
            executer systemctl reload sshd
            log_ok "SSH sécurisé ($modifications modification(s))"
        else
            log_error "Erreur de syntaxe dans sshd_config — rechargement annulé"
            exit 1
        fi
    else
        log_ok "SSH déjà sécurisé"
    fi
}

# ─── Configuration du pare-feu ───────────────────────────────
configurer_firewall() {
    log_info "Configuration du pare-feu UFW..."

    if ufw status | grep -q "Status: active"; then
        log_ok "UFW déjà actif"
    else
        executer ufw default deny incoming
        executer ufw default allow outgoing
        executer ufw allow ssh
        executer ufw --force enable
        log_ok "UFW activé avec règles de base"
    fi
}

# ─── Mises à jour automatiques ───────────────────────────────
configurer_mises_a_jour_auto() {
    log_info "Configuration des mises à jour automatiques de sécurité..."

    local ua_config="/etc/apt/apt.conf.d/50unattended-upgrades"

    if [[ -f "$ua_config" ]]; then
        # S'assurer que les mises à jour de sécurité sont activées
        if grep -q "Debian-Security" "$ua_config"; then
            log_ok "Mises à jour automatiques de sécurité déjà configurées"
            return 0
        fi
    fi

    # Activer les mises à jour périodiques
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

    log_ok "Mises à jour automatiques configurées"
}

# ─── Configuration sysctl ────────────────────────────────────
configurer_sysctl() {
    log_info "Application des paramètres sysctl de sécurité..."

    local sysctl_file="/etc/sysctl.d/99-hardening.conf"

    if [[ -f "$sysctl_file" ]]; then
        log_ok "Paramètres sysctl déjà en place"
        return 0
    fi

    cat > "$sysctl_file" << 'EOF'
# Protection réseau
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1

# Protection système
kernel.sysrq = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

    executer sysctl --system --quiet
    log_ok "Paramètres sysctl appliqués"
}

# ─── Rapport final ───────────────────────────────────────────
rapport_final() {
    echo ""
    echo "================================================================"
    echo "  PROVISIONNEMENT TERMINÉ"
    echo "  Serveur  : $(hostname -f)"
    echo "  Debian   : $(cat /etc/debian_version)"
    echo "  Noyau    : $(uname -r)"
    echo "  IP       : $(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo 'N/A')"
    echo "  Uptime   : $(uptime -p)"
    echo "  Date     : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "================================================================"
    echo ""
    echo "  Actions recommandées :"
    echo "    1. Vérifier la connectivité SSH avec le compte admin"
    echo "    2. Configurer les règles firewall spécifiques au rôle du serveur"
    echo "    3. Installer les services applicatifs"
    echo "    4. Configurer la supervision (monitoring)"
    echo ""
}

# ─── Main ────────────────────────────────────────────────────
main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)  DRY_RUN=1; shift ;;
            -v|--verbose)  VERBOSE=1; shift ;;
            -h|--help)
                echo "Usage: $SCRIPT_NAME [-n] [-v] [-h]"
                exit 0
                ;;
            *) shift ;;
        esac
    done

    log_info "=== Début du provisionnement ==="
    (( DRY_RUN )) && log_warn "Mode simulation activé"

    verifier_prerequis
    configurer_depots
    mise_a_jour_systeme
    installer_paquets_base
    configurer_timezone_locales
    creer_utilisateur_admin
    securiser_ssh
    configurer_firewall
    configurer_mises_a_jour_auto
    configurer_sysctl

    log_info "=== Provisionnement terminé avec succès ==="
    rapport_final
}

main "$@"
