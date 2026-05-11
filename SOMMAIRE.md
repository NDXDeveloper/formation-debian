# 📘 Formation Debian : du Desktop au Cloud-Native

## Formation Complète Administrateur Système → DevOps/SRE — Débutant → Expert

### *Édition 2026 — 19 Modules · 3 Parcours progressifs*

---

## Structure en 3 parcours

| Parcours | Modules | Profil cible | Durée estimée |
|----------|---------|--------------|---------------|
| **Parcours 1** — Administrateur Système Debian | 1 à 8 | Adminsys, techniciens, étudiants | ~100h |
| **Parcours 2** — Ingénieur Infrastructure & Conteneurs | 9 à 13 | Adminsys confirmés, DevOps juniors | ~90h |
| **Parcours 3** — Expert Cloud-Native & Kubernetes | 14 à 19 | DevOps/SRE confirmés, architectes | ~90h |

Chaque parcours est conçu pour être suivi indépendamment (avec les prérequis du parcours précédent acquis) ou dans la continuité.

---

# PARCOURS 1 — Administrateur Système Debian

*Modules 1 à 8 · Du poste de travail au serveur en production*

---

## **[Module 1 : Fondamentaux de Debian](/module-01-fondamentaux-debian.md)** *(Niveau : Débutant)*

### 1.1 [Introduction à Debian](/module-01-fondamentaux-debian/01-introduction-debian.md)

- 1.1.1 [Histoire et philosophie de Debian (le contrat social, le DFSG)](/module-01-fondamentaux-debian/01.1-histoire-philosophie.md)
- 1.1.2 [Les versions et cycles de release (Stable, Testing, Unstable, Experimental)](/module-01-fondamentaux-debian/01.2-versions-cycles-release.md)
- 1.1.3 [Support et cycles de vie (LTS, ELTS)](/module-01-fondamentaux-debian/01.3-support-cycles-vie.md)
- 1.1.4 [Différences avec les autres distributions (Ubuntu, RHEL, Arch)](/module-01-fondamentaux-debian/01.4-differences-distributions.md)
- 1.1.5 [Architecture du système Debian](/module-01-fondamentaux-debian/01.5-architecture-systeme.md)

### 1.2 [Installation de base](/module-01-fondamentaux-debian/02-installation-base.md)

- 1.2.1 [Préparation du support d'installation](/module-01-fondamentaux-debian/02.1-preparation-support.md)
- 1.2.2 [Types d'installation (Netinst, DVD, USB, PXE)](/module-01-fondamentaux-debian/02.2-types-installation.md)
- 1.2.3 [Partitionnement du disque (GPT vs MBR, schémas recommandés)](/module-01-fondamentaux-debian/02.3-partitionnement.md)
- 1.2.4 [Configuration réseau de base](/module-01-fondamentaux-debian/02.4-configuration-reseau.md)
- 1.2.5 [Sélection des paquets de base (tasksel)](/module-01-fondamentaux-debian/02.5-selection-paquets.md)

### 1.3 [Post-installation](/module-01-fondamentaux-debian/03-post-installation.md)

- 1.3.1 [Premier démarrage et configuration initiale](/module-01-fondamentaux-debian/03.1-premier-demarrage.md)
- 1.3.2 [Configuration des locales, fuseaux horaires et clavier](/module-01-fondamentaux-debian/03.2-locales-fuseaux-clavier.md)
- 1.3.3 [Mise à jour du système](/module-01-fondamentaux-debian/03.3-mise-a-jour.md)
- 1.3.4 [Création du premier utilisateur et configuration de sudo](/module-01-fondamentaux-debian/03.4-utilisateur-sudo.md)

---

## **[Module 2 : Debian Desktop](/module-02-debian-desktop.md)** *(Niveau : Débutant-Intermédiaire)*

### 2.1 [Environnements de bureau](/module-02-debian-desktop/01-environnements-bureau.md)

- 2.1.1 [GNOME (environnement par défaut)](/module-02-debian-desktop/01.1-gnome.md)
- 2.1.2 [KDE Plasma](/module-02-debian-desktop/01.2-kde-plasma.md)
- 2.1.3 [XFCE et LXDE](/module-02-debian-desktop/01.3-xfce-lxde.md)
- 2.1.4 [Installation et configuration des DE](/module-02-debian-desktop/01.4-installation-configuration-de.md)
- 2.1.5 [Wayland vs Xorg](/module-02-debian-desktop/01.5-wayland-vs-xorg.md)

### 2.2 [Gestion des applications desktop](/module-02-debian-desktop/02-gestion-applications.md)

- 2.2.1 [Logithèque et centres d'applications](/module-02-debian-desktop/02.1-logitheque.md)
- 2.2.2 [Installation de logiciels courants](/module-02-debian-desktop/02.2-logiciels-courants.md)
- 2.2.3 [Gestion des formats de fichiers](/module-02-debian-desktop/02.3-formats-fichiers.md)
- 2.2.4 [Configuration du multimédia (codecs, PipeWire)](/module-02-debian-desktop/02.4-multimedia-codecs.md)

### 2.3 [Matériel et pilotes](/module-02-debian-desktop/03-materiel-pilotes.md)

- 2.3.1 [Firmware non-libre et pilotes propriétaires (NVIDIA, WiFi)](/module-02-debian-desktop/03.1-firmware-pilotes-proprietaires.md)
- 2.3.2 [Gestion de l'alimentation et suspend/hibernate](/module-02-debian-desktop/03.2-alimentation-suspend.md)
- 2.3.3 [Configuration multi-écrans](/module-02-debian-desktop/03.3-multi-ecrans.md)
- 2.3.4 [Bluetooth et périphériques](/module-02-debian-desktop/03.4-bluetooth-peripheriques.md)

### 2.4 [Personnalisation et optimisation](/module-02-debian-desktop/04-personnalisation-optimisation.md)

- 2.4.1 [Thèmes et apparence](/module-02-debian-desktop/04.1-themes-apparence.md)
- 2.4.2 [Raccourcis clavier](/module-02-debian-desktop/04.2-raccourcis-clavier.md)
- 2.4.3 [Optimisation des performances desktop](/module-02-debian-desktop/04.3-optimisation-performances.md)
- 2.4.4 [Accessibilité](/module-02-debian-desktop/04.4-accessibilite.md)

### 2.5 [Bureautique et productivité](/module-02-debian-desktop/05-bureautique-productivite.md)

- 2.5.1 [Suite LibreOffice](/module-02-debian-desktop/05.1-libreoffice.md)
- 2.5.2 [Navigateurs web et extensions](/module-02-debian-desktop/05.2-navigateurs-extensions.md)
- 2.5.3 [Clients de messagerie](/module-02-debian-desktop/05.3-clients-messagerie.md)
- 2.5.4 [Outils de développement (IDE, éditeurs, VS Code)](/module-02-debian-desktop/05.4-outils-developpement.md)

---

## **[Module 3 : Administration système de base](/module-03-administration-systeme.md)** *(Niveau : Intermédiaire)*

📁 [Scripts du module — systemd units, scripts d'admin Bash](/module-03-administration-systeme/scripts/README.md)

### 3.1 [Système de fichiers](/module-03-administration-systeme/01-systeme-fichiers.md)

- 3.1.1 [Structure des répertoires Linux/Debian (FHS)](/module-03-administration-systeme/01.1-structure-repertoires-fhs.md)
- 3.1.2 [Systèmes de fichiers (ext4, XFS, Btrfs, ZFS : concepts et comparaison)](/module-03-administration-systeme/01.2-systemes-fichiers-comparaison.md)
- 3.1.3 [Permissions et propriétés (ACL avancées)](/module-03-administration-systeme/01.3-permissions-acl.md)
- 3.1.4 [Montage, démontage et fstab](/module-03-administration-systeme/01.4-montage-fstab.md)
- 3.1.5 [Liens symboliques et physiques](/module-03-administration-systeme/01.5-liens-symboliques-physiques.md)

### 3.2 [Gestion des utilisateurs et groupes](/module-03-administration-systeme/02-utilisateurs-groupes.md)

- 3.2.1 [Création, modification et suppression d'utilisateurs](/module-03-administration-systeme/02.1-creation-modification-utilisateurs.md)
- 3.2.2 [Groupes et appartenance](/module-03-administration-systeme/02.2-groupes-appartenance.md)
- 3.2.3 [Gestion des mots de passe et politiques (PAM)](/module-03-administration-systeme/02.3-mots-de-passe-pam.md)
- 3.2.4 [Sudo et privilèges avancés](/module-03-administration-systeme/02.4-sudo-privileges.md)
- 3.2.5 [NSS et intégration annuaire (LDAP, SSSD)](/module-03-administration-systeme/02.5-nss-ldap-sssd.md)

### 3.3 [Gestion des processus](/module-03-administration-systeme/03-gestion-processus.md)

- 3.3.1 [Commandes ps, top, htop](/module-03-administration-systeme/03.1-ps-top-htop.md)
- 3.3.2 [Signaux et kill](/module-03-administration-systeme/03.2-signaux-kill.md)
- 3.3.3 [Jobs et processus en arrière-plan](/module-03-administration-systeme/03.3-jobs-arriere-plan.md)
- 3.3.4 [Priorités et ordonnancement (nice, ionice, cgroups v2)](/module-03-administration-systeme/03.4-priorites-ordonnancement.md)

### 3.4 [systemd en profondeur](/module-03-administration-systeme/04-systemd.md)

- 3.4.1 [Architecture de systemd et concepts fondamentaux](/module-03-administration-systeme/04.1-architecture-systemd.md)
- 3.4.2 [Unités, targets et dépendances](/module-03-administration-systeme/04.2-unites-targets-dependances.md)
- 3.4.3 [Création et gestion de services personnalisés](/module-03-administration-systeme/04.3-services-personnalises.md)
- 3.4.4 [journald : configuration et exploitation des logs](/module-03-administration-systeme/04.4-journald.md)
- 3.4.5 [systemd-networkd, systemd-resolved, systemd-timesyncd](/module-03-administration-systeme/04.5-systemd-network-resolved.md)
- 3.4.6 [Timers systemd (alternative à cron)](/module-03-administration-systeme/04.6-timers-systemd.md)

### 3.5 [Logs et monitoring de base](/module-03-administration-systeme/05-logs-monitoring.md)

- 3.5.1 [Système de logs (rsyslog vs journald)](/module-03-administration-systeme/05.1-rsyslog-vs-journald.md)
- 3.5.2 [Analyse des logs (grep, awk, sed)](/module-03-administration-systeme/05.2-analyse-logs.md)
- 3.5.3 [Introduction aux outils de monitoring (Nagios, Zabbix)](/module-03-administration-systeme/05.3-introduction-monitoring.md)
- 3.5.4 [Alertes et notifications](/module-03-administration-systeme/05.4-alertes-notifications.md)

---

## **[Module 4 : Gestion des paquets](/module-04-gestion-paquets.md)** *(Niveau : Intermédiaire)*

### 4.1 [APT (Advanced Package Tool)](/module-04-gestion-paquets/01-apt.md)

- 4.1.1 [Configuration d'APT et fonctionnement interne](/module-04-gestion-paquets/01.1-configuration-fonctionnement.md)
- 4.1.2 [Sources.list et dépôts (main, contrib, non-free, non-free-firmware)](/module-04-gestion-paquets/01.2-sources-list-depots.md)
- 4.1.3 [Commandes apt et apt-get](/module-04-gestion-paquets/01.3-commandes-apt.md)
- 4.1.4 [Gestion des clés GPG et authentification des dépôts](/module-04-gestion-paquets/01.4-cles-gpg-authentification.md)

### 4.2 [Dpkg et paquets .deb](/module-04-gestion-paquets/02-dpkg-paquets-deb.md)

- 4.2.1 [Installation manuelle de paquets](/module-04-gestion-paquets/02.1-installation-manuelle.md)
- 4.2.2 [Création de paquets .deb personnalisés](/module-04-gestion-paquets/02.2-creation-paquets-deb.md)
- 4.2.3 [Résolution des dépendances](/module-04-gestion-paquets/02.3-resolution-dependances.md)
- 4.2.4 [Outils complémentaires (gdebi, dpkg-reconfigure)](/module-04-gestion-paquets/02.4-outils-complementaires.md)

### 4.3 [Dépôts tiers et backports](/module-04-gestion-paquets/03-depots-tiers-backports.md)

- 4.3.1 [Ajout de dépôts externes](/module-04-gestion-paquets/03.1-ajout-depots-externes.md)
- 4.3.2 [Debian Backports](/module-04-gestion-paquets/03.2-debian-backports.md)
- 4.3.3 [Sécurité et vérification des sources](/module-04-gestion-paquets/03.3-securite-verification.md)
- 4.3.4 [Pinning des paquets (APT preferences)](/module-04-gestion-paquets/03.4-pinning-apt-preferences.md)

### 4.4 [Flatpak et Snap](/module-04-gestion-paquets/04-flatpak-snap.md)

- 4.4.1 [Installation et configuration](/module-04-gestion-paquets/04.1-installation-configuration.md)
- 4.4.2 [Gestion des applications sandboxées](/module-04-gestion-paquets/04.2-applications-sandboxees.md)
- 4.4.3 [Comparaison Flatpak vs Snap vs .deb natif](/module-04-gestion-paquets/04.3-comparaison-flatpak-snap-deb.md)

---

## **[Module 5 : Scripting et automatisation](/module-05-scripting-automatisation.md)** *(Niveau : Intermédiaire)*

📁 [Scripts du module — Bash et Python pour l'administration](/module-05-scripting-automatisation/scripts/README.md)

### 5.1 [Bash avancé](/module-05-scripting-automatisation/01-bash-avance.md)

- 5.1.1 [Variables, tableaux et structures de contrôle](/module-05-scripting-automatisation/01.1-variables-tableaux-structures.md)
- 5.1.2 [Fonctions, sous-shells et substitution de processus](/module-05-scripting-automatisation/01.2-fonctions-sous-shells.md)
- 5.1.3 [Expressions régulières et traitement de texte (sed, awk, jq)](/module-05-scripting-automatisation/01.3-regex-sed-awk-jq.md)
- 5.1.4 [Gestion des erreurs, codes de retour et signaux (trap)](/module-05-scripting-automatisation/01.4-gestion-erreurs-trap.md)
- 5.1.5 [Bonnes pratiques (shellcheck, set -euo pipefail, logging)](/module-05-scripting-automatisation/01.5-bonnes-pratiques.md)

### 5.2 [Automatisation système](/module-05-scripting-automatisation/02-automatisation-systeme.md)

- 5.2.1 [Scripts d'administration courants (rotation de logs, nettoyage, provisioning)](/module-05-scripting-automatisation/02.1-scripts-administration.md)
- 5.2.2 [Planification avec cron et timers systemd](/module-05-scripting-automatisation/02.2-planification-cron-timers.md)
- 5.2.3 [Interaction avec les APIs REST (curl, jq)](/module-05-scripting-automatisation/02.3-interaction-apis-rest.md)
- 5.2.4 [Génération de rapports et notifications](/module-05-scripting-automatisation/02.4-rapports-notifications.md)

### 5.3 [Introduction à Python pour l'administration](/module-05-scripting-automatisation/03-python-administration.md)

- 5.3.1 [Python sur Debian : installation et gestion des environnements virtuels](/module-05-scripting-automatisation/03.1-python-debian-venv.md)
- 5.3.2 [Scripts d'administration système en Python](/module-05-scripting-automatisation/03.2-scripts-python-admin.md)
- 5.3.3 [Bibliothèques utiles (os, subprocess, paramiko, requests)](/module-05-scripting-automatisation/03.3-bibliotheques-utiles.md)
- 5.3.4 [Quand utiliser Bash vs Python](/module-05-scripting-automatisation/03.4-bash-vs-python.md)

---

## **[Module 6 : Réseau et sécurité](/module-06-reseau-securite.md)** *(Niveau : Intermédiaire)*

### 6.1 [Configuration réseau avancée](/module-06-reseau-securite/01-configuration-reseau.md)

- 6.1.1 [Interfaces réseau et bonding/teaming](/module-06-reseau-securite/01.1-interfaces-bonding.md)
- 6.1.2 [Configuration statique et DHCP](/module-06-reseau-securite/01.2-configuration-statique-dhcp.md)
- 6.1.3 [IPv6 et dual-stack](/module-06-reseau-securite/01.3-ipv6-dual-stack.md)
- 6.1.4 [VLAN et réseaux virtuels](/module-06-reseau-securite/01.4-vlan-reseaux-virtuels.md)
- 6.1.5 [NetworkManager vs systemd-networkd vs /etc/network/interfaces](/module-06-reseau-securite/01.5-networkmanager-vs-systemd-networkd.md)
- 6.1.6 [Diagnostic réseau (ip, ss, tcpdump, traceroute, mtr)](/module-06-reseau-securite/01.6-diagnostic-reseau.md)

### 6.2 [Pare-feu et sécurité](/module-06-reseau-securite/02-parefeu-securite.md)

- 6.2.1 [nftables (et héritage iptables)](/module-06-reseau-securite/02.1-nftables-iptables.md)
- 6.2.2 [ufw (Uncomplicated Firewall)](/module-06-reseau-securite/02.2-ufw.md)
- 6.2.3 [Configuration de base et règles avancées](/module-06-reseau-securite/02.3-regles-avancees.md)
- 6.2.4 [fail2ban et protection contre les intrusions](/module-06-reseau-securite/02.4-fail2ban.md)

### 6.3 [SSH et accès distant](/module-06-reseau-securite/03-ssh-acces-distant.md)

- 6.3.1 [Installation et configuration d'OpenSSH](/module-06-reseau-securite/03.1-installation-openssh.md)
- 6.3.2 [Authentification par clés (ed25519, gestion de ssh-agent)](/module-06-reseau-securite/03.2-authentification-cles.md)
- 6.3.3 [Tunneling et port forwarding](/module-06-reseau-securite/03.3-tunneling-port-forwarding.md)
- 6.3.4 [Sécurisation d'SSH (fail2ban, port knocking, bastions)](/module-06-reseau-securite/03.4-securisation-ssh.md)

### 6.4 [VPN et chiffrement](/module-06-reseau-securite/04-vpn-chiffrement.md)

- 6.4.1 [WireGuard et OpenVPN](/module-06-reseau-securite/04.1-wireguard-openvpn.md)
- 6.4.2 [Configuration client/serveur](/module-06-reseau-securite/04.2-configuration-client-serveur.md)
- 6.4.3 [Certificats et PKI](/module-06-reseau-securite/04.3-certificats-pki.md)
- 6.4.4 [Chiffrement des données (LUKS, dm-crypt)](/module-06-reseau-securite/04.4-chiffrement-luks-dm-crypt.md)

---

## **[Module 7 : Debian Server — Services de base](/module-07-debian-server.md)** *(Niveau : Intermédiaire-Avancé)*

### 7.1 [Installation serveur](/module-07-debian-server/01-installation-serveur.md)

- 7.1.1 [Installation minimale et preseed (installation automatisée)](/module-07-debian-server/01.1-installation-minimale-preseed.md)
- 7.1.2 [Configuration réseau serveur](/module-07-debian-server/01.2-configuration-reseau-serveur.md)
- 7.1.3 [Sécurisation initiale (hardening de base)](/module-07-debian-server/01.3-securisation-initiale.md)
- 7.1.4 [Outils d'administration à distance (Cockpit, Webmin)](/module-07-debian-server/01.4-administration-distante.md)

### 7.2 [Serveur web](/module-07-debian-server/02-serveur-web.md)

- 7.2.1 [Apache : installation et configuration](/module-07-debian-server/02.1-apache.md)
- 7.2.2 [Nginx : installation et configuration](/module-07-debian-server/02.2-nginx.md)
- 7.2.3 [Caddy : HTTPS automatique et configuration simplifiée](/module-07-debian-server/02.3-caddy.md)
- 7.2.4 [Virtual hosts et reverse proxy](/module-07-debian-server/02.4-virtual-hosts-reverse-proxy.md)
- 7.2.5 [SSL/TLS et certificats (Let's Encrypt, ACME)](/module-07-debian-server/02.5-ssl-tls-letsencrypt.md)
- 7.2.6 [Performance tuning et comparaison](/module-07-debian-server/02.6-performance-tuning.md)

### 7.3 [Base de données](/module-07-debian-server/03-base-de-donnees.md)

- 7.3.1 [MariaDB (fork Debian-native de MySQL)](/module-07-debian-server/03.1-mariadb.md)
- 7.3.2 [PostgreSQL](/module-07-debian-server/03.2-postgresql.md)
- 7.3.3 [Configuration et optimisation](/module-07-debian-server/03.3-configuration-optimisation.md)
- 7.3.4 [Sauvegarde et restauration](/module-07-debian-server/03.4-sauvegarde-restauration.md)
- 7.3.5 [Réplication et clustering](/module-07-debian-server/03.5-replication-clustering.md)

### 7.4 [Serveur de fichiers](/module-07-debian-server/04-serveur-fichiers.md)

- 7.4.1 [Samba (partage Windows)](/module-07-debian-server/04.1-samba.md)
- 7.4.2 [NFS (partage Linux)](/module-07-debian-server/04.2-nfs.md)
- 7.4.3 [SFTP sécurisé](/module-07-debian-server/04.3-sftp.md)
- 7.4.4 [Configuration et sécurisation](/module-07-debian-server/04.4-configuration-securisation.md)

---

## **[Module 8 : Services réseau avancés, sauvegarde et HA](/module-08-services-avances-sauvegarde-ha.md)** *(Niveau : Avancé)*

### 8.1 [Serveur DNS](/module-08-services-avances-sauvegarde-ha/01-serveur-dns.md)

- 8.1.1 [BIND9 configuration avancée](/module-08-services-avances-sauvegarde-ha/01.1-bind9-configuration.md)
- 8.1.2 [Zones et enregistrements](/module-08-services-avances-sauvegarde-ha/01.2-zones-enregistrements.md)
- 8.1.3 [DNS dynamique et DNSSEC](/module-08-services-avances-sauvegarde-ha/01.3-dns-dynamique-dnssec.md)
- 8.1.4 [Sécurité DNS et alternatives (Unbound)](/module-08-services-avances-sauvegarde-ha/01.4-securite-dns-unbound.md)

### 8.2 [Serveur DHCP](/module-08-services-avances-sauvegarde-ha/02-serveur-dhcp.md)

- 8.2.1 [ISC Kea (successeur d'ISC DHCP Server)](/module-08-services-avances-sauvegarde-ha/02.1-isc-kea.md)
- 8.2.2 [Configuration des plages et haute disponibilité](/module-08-services-avances-sauvegarde-ha/02.2-plages-haute-disponibilite.md)
- 8.2.3 [Réservations statiques](/module-08-services-avances-sauvegarde-ha/02.3-reservations-statiques.md)
- 8.2.4 [Intégration DNS-DHCP](/module-08-services-avances-sauvegarde-ha/02.4-integration-dns-dhcp.md)

### 8.3 [Serveur mail](/module-08-services-avances-sauvegarde-ha/03-serveur-mail.md)

- 8.3.1 [Postfix configuration complète](/module-08-services-avances-sauvegarde-ha/03.1-postfix.md)
- 8.3.2 [Dovecot (IMAP/POP3)](/module-08-services-avances-sauvegarde-ha/03.2-dovecot.md)
- 8.3.3 [Filtrage anti-spam (Rspamd, SpamAssassin)](/module-08-services-avances-sauvegarde-ha/03.3-filtrage-anti-spam.md)
- 8.3.4 [Webmail et clients](/module-08-services-avances-sauvegarde-ha/03.4-webmail-clients.md)
- 8.3.5 [DKIM, SPF, DMARC](/module-08-services-avances-sauvegarde-ha/03.5-dkim-spf-dmarc.md)

### 8.4 [Stratégies de sauvegarde](/module-08-services-avances-sauvegarde-ha/04-strategies-sauvegarde.md)

- 8.4.1 [Types de sauvegardes (complète, incrémentale, différentielle)](/module-08-services-avances-sauvegarde-ha/04.1-types-sauvegardes.md)
- 8.4.2 [Outils Debian (rsync, tar, borgbackup, restic)](/module-08-services-avances-sauvegarde-ha/04.2-outils-sauvegarde.md)
- 8.4.3 [Automatisation avec cron et timers systemd](/module-08-services-avances-sauvegarde-ha/04.3-automatisation-cron-timers.md)
- 8.4.4 [Sauvegarde distante et chiffrement](/module-08-services-avances-sauvegarde-ha/04.4-sauvegarde-distante-chiffrement.md)
- 8.4.5 [Calcul RTO/RPO et stratégie 3-2-1](/module-08-services-avances-sauvegarde-ha/04.5-rto-rpo-strategie-321.md)
- 8.4.6 [Tests de restauration et validation](/module-08-services-avances-sauvegarde-ha/04.6-tests-restauration.md)

### 8.5 [RAID, LVM et haute disponibilité](/module-08-services-avances-sauvegarde-ha/05-raid-lvm-ha.md)

- 8.5.1 [Configuration RAID logiciel (mdadm)](/module-08-services-avances-sauvegarde-ha/05.1-raid-mdadm.md)
- 8.5.2 [LVM (Logical Volume Manager)](/module-08-services-avances-sauvegarde-ha/05.2-lvm.md)
- 8.5.3 [Surveillance des disques (SMART)](/module-08-services-avances-sauvegarde-ha/05.3-surveillance-smart.md)
- 8.5.4 [Clustering avec Pacemaker/Corosync](/module-08-services-avances-sauvegarde-ha/05.4-pacemaker-corosync.md)
- 8.5.5 [Load balancing (HAProxy, Keepalived)](/module-08-services-avances-sauvegarde-ha/05.5-haproxy-keepalived.md)
- 8.5.6 [Monitoring et failover automatique](/module-08-services-avances-sauvegarde-ha/05.6-monitoring-failover.md)

---

# PARCOURS 2 — Ingénieur Infrastructure & Conteneurs

*Modules 9 à 13 · De la virtualisation à l'Infrastructure as Code*

*Prérequis : Parcours 1 ou expérience équivalente en administration Debian*

---

## **[Module 9 : Virtualisation](/module-09-virtualisation.md)** *(Niveau : Avancé)*

### 9.1 [Virtualisation système avec KVM](/module-09-virtualisation/01-kvm.md)

- 9.1.1 [Concepts de virtualisation (type 1, type 2, paravirtualisation)](/module-09-virtualisation/01.1-concepts-virtualisation.md)
- 9.1.2 [KVM et QEMU sur Debian](/module-09-virtualisation/01.2-kvm-qemu-debian.md)
- 9.1.3 [libvirt et virt-manager](/module-09-virtualisation/01.3-libvirt-virt-manager.md)
- 9.1.4 [Gestion des machines virtuelles (création, snapshots, migration)](/module-09-virtualisation/01.4-gestion-vm.md)
- 9.1.5 [Réseaux virtuels et bridges avancés](/module-09-virtualisation/01.5-reseaux-virtuels-bridges.md)
- 9.1.6 [Optimisation des performances (virtio, hugepages)](/module-09-virtualisation/01.6-optimisation-performances.md)

### 9.2 [VirtualBox](/module-09-virtualisation/02-virtualbox.md)

- 9.2.1 [Installation sur Debian et cas d'usage](/module-09-virtualisation/02.1-installation-cas-usage.md)
- 9.2.2 [Configuration et intégration desktop](/module-09-virtualisation/02.2-configuration-integration.md)
- 9.2.3 [VirtualBox vs KVM : critères de choix](/module-09-virtualisation/02.3-virtualbox-vs-kvm.md)

### 9.3 [Vagrant et Packer](/module-09-virtualisation/03-vagrant-packer.md)

- 9.3.1 [Vagrant : environnements de développement reproductibles](/module-09-virtualisation/03.1-vagrant.md)
- 9.3.2 [Packer : création d'images Debian personnalisées](/module-09-virtualisation/03.2-packer-images-debian.md)
- 9.3.3 [Intégration avec les différents hyperviseurs](/module-09-virtualisation/03.3-integration-hyperviseurs.md)

---

## **[Module 10 : Conteneurs](/module-10-conteneurs.md)** *(Niveau : Avancé)*

### 10.1 [Fondamentaux des conteneurs](/module-10-conteneurs/01-fondamentaux.md)

- 10.1.1 [Concepts fondamentaux (namespaces, cgroups v2, overlay FS)](/module-10-conteneurs/01.1-namespaces-cgroups-overlayfs.md)
- 10.1.2 [Conteneurs vs machines virtuelles : différences architecturales](/module-10-conteneurs/01.2-conteneurs-vs-vm.md)
- 10.1.3 [Standards OCI (Open Container Initiative)](/module-10-conteneurs/01.3-standards-oci.md)

### 10.2 [Docker](/module-10-conteneurs/02-docker.md)

- 10.2.1 [Installation et configuration sur Debian](/module-10-conteneurs/02.1-installation-docker-debian.md)
- 10.2.2 [Images : construction, couches, multi-stage builds](/module-10-conteneurs/02.2-images-construction.md)
- 10.2.3 [Conteneurs : cycle de vie et gestion](/module-10-conteneurs/02.3-cycle-vie-gestion.md)
- 10.2.4 [Docker Compose et orchestration locale](/module-10-conteneurs/02.4-docker-compose.md)
- 10.2.5 [Volumes et réseaux](/module-10-conteneurs/02.5-volumes-reseaux.md)
- 10.2.6 [Registry privé et distribution d'images](/module-10-conteneurs/02.6-registry-prive.md)
- 10.2.7 [Images Debian : slim, minimalistes et bonnes pratiques](/module-10-conteneurs/02.7-images-debian-slim.md)

### 10.3 [Podman et alternatives](/module-10-conteneurs/03-podman-alternatives.md)

- 10.3.1 [Podman rootless sur Debian](/module-10-conteneurs/03.1-podman-rootless.md)
- 10.3.2 [Buildah et Skopeo](/module-10-conteneurs/03.2-buildah-skopeo.md)
- 10.3.3 [Compatibilité Docker et migration](/module-10-conteneurs/03.3-compatibilite-docker.md)
- 10.3.4 [Quadlet : intégration systemd des conteneurs](/module-10-conteneurs/03.4-quadlet-systemd.md)

### 10.4 [LXC/LXD (Incus)](/module-10-conteneurs/04-lxc-lxd-incus.md)

- 10.4.1 [Conteneurs système vs conteneurs applicatifs](/module-10-conteneurs/04.1-systeme-vs-applicatif.md)
- 10.4.2 [Configuration et gestion avancée](/module-10-conteneurs/04.2-configuration-gestion.md)
- 10.4.3 [Snapshots et migration](/module-10-conteneurs/04.3-snapshots-migration.md)
- 10.4.4 [Intégration réseau](/module-10-conteneurs/04.4-integration-reseau.md)

### 10.5 [Sécurité des conteneurs](/module-10-conteneurs/05-securite-conteneurs.md)

- 10.5.1 [Principes de sécurité (least privilege, immutabilité)](/module-10-conteneurs/05.1-principes-securite.md)
- 10.5.2 [Conteneurs rootless et capabilities](/module-10-conteneurs/05.2-rootless-capabilities.md)
- 10.5.3 [Seccomp et AppArmor pour conteneurs](/module-10-conteneurs/05.3-seccomp-apparmor.md)
- 10.5.4 [Scanning d'images (Trivy, Grype)](/module-10-conteneurs/05.4-scanning-images.md)

---

## **[Module 11 : Kubernetes — Fondamentaux](/module-11-kubernetes-fondamentaux.md)** *(Niveau : Avancé)*

### 11.1 [Architecture et concepts](/module-11-kubernetes-fondamentaux/01-architecture-concepts.md)

- 11.1.1 [Architecture d'un cluster Kubernetes](/module-11-kubernetes-fondamentaux/01.1-architecture-cluster.md)
- 11.1.2 [Control plane (API Server, etcd, scheduler, controller manager)](/module-11-kubernetes-fondamentaux/01.2-control-plane.md)
- 11.1.3 [Worker nodes (kubelet, kube-proxy, container runtime)](/module-11-kubernetes-fondamentaux/01.3-worker-nodes.md)
- 11.1.4 [Le modèle déclaratif et la boucle de réconciliation](/module-11-kubernetes-fondamentaux/01.4-modele-declaratif.md)

### 11.2 [Installation sur Debian](/module-11-kubernetes-fondamentaux/02-installation-debian.md)

- 11.2.1 [Prérequis système et préparation des nœuds Debian](/module-11-kubernetes-fondamentaux/02.1-prerequis-preparation-noeuds.md)
- 11.2.2 [Installation avec kubeadm](/module-11-kubernetes-fondamentaux/02.2-installation-kubeadm.md)
- 11.2.3 [K3s (lightweight Kubernetes)](/module-11-kubernetes-fondamentaux/02.3-k3s.md)
- 11.2.4 [MicroK8s et Kind (développement local)](/module-11-kubernetes-fondamentaux/02.4-microk8s-kind.md)
- 11.2.5 [Comparaison des distributions](/module-11-kubernetes-fondamentaux/02.5-comparaison-distributions.md)

### 11.3 [Ressources fondamentales](/module-11-kubernetes-fondamentaux/03-ressources-fondamentales.md)

- 11.3.1 [Pods, ReplicaSets, Deployments](/module-11-kubernetes-fondamentaux/03.1-pods-replicasets-deployments.md)
- 11.3.2 [Services (ClusterIP, NodePort, LoadBalancer)](/module-11-kubernetes-fondamentaux/03.2-services.md)
- 11.3.3 [ConfigMaps et Secrets](/module-11-kubernetes-fondamentaux/03.3-configmaps-secrets.md)
- 11.3.4 [Namespaces et organisation des ressources](/module-11-kubernetes-fondamentaux/03.4-namespaces-organisation.md)
- 11.3.5 [Jobs et CronJobs](/module-11-kubernetes-fondamentaux/03.5-jobs-cronjobs.md)

### 11.4 [Réseau Kubernetes](/module-11-kubernetes-fondamentaux/04-reseau-kubernetes.md)

- 11.4.1 [Modèle réseau Kubernetes](/module-11-kubernetes-fondamentaux/04.1-modele-reseau.md)
- 11.4.2 [CNI : Flannel, Calico, Cilium](/module-11-kubernetes-fondamentaux/04.2-cni-flannel-calico-cilium.md)
- 11.4.3 [Ingress Controllers (NGINX Ingress, Traefik)](/module-11-kubernetes-fondamentaux/04.3-ingress-controllers.md)
- 11.4.4 [DNS interne (CoreDNS)](/module-11-kubernetes-fondamentaux/04.4-coredns.md)

### 11.5 [Stockage Kubernetes](/module-11-kubernetes-fondamentaux/05-stockage-kubernetes.md)

- 11.5.1 [Persistent Volumes et Persistent Volume Claims](/module-11-kubernetes-fondamentaux/05.1-pv-pvc.md)
- 11.5.2 [StorageClasses et provisionnement dynamique](/module-11-kubernetes-fondamentaux/05.2-storageclasses.md)
- 11.5.3 [CSI drivers sur Debian](/module-11-kubernetes-fondamentaux/05.3-csi-drivers-debian.md)

---

## **[Module 12 : Kubernetes — Production](/module-12-kubernetes-production.md)** *(Niveau : Expert)*

### 12.1 [Cluster haute disponibilité](/module-12-kubernetes-production/01-cluster-ha.md)

- 12.1.1 [Architecture multi-nœuds HA sur Debian](/module-12-kubernetes-production/01.1-architecture-ha-debian.md)
- 12.1.2 [Configuration etcd en cluster](/module-12-kubernetes-production/01.2-etcd-cluster.md)
- 12.1.3 [Load balancing du control plane](/module-12-kubernetes-production/01.3-lb-control-plane.md)
- 12.1.4 [Tuning du noyau Debian pour workloads K8s (sysctl, ulimits)](/module-12-kubernetes-production/01.4-tuning-noyau-debian-k8s.md)

### 12.2 [Sécurité du cluster](/module-12-kubernetes-production/02-securite-cluster.md)

- 12.2.1 [RBAC et ServiceAccounts](/module-12-kubernetes-production/02.1-rbac-serviceaccounts.md)
- 12.2.2 [Pod Security Standards (admission control)](/module-12-kubernetes-production/02.2-pod-security-standards.md)
- 12.2.3 [Network Policies et micro-segmentation](/module-12-kubernetes-production/02.3-network-policies.md)
- 12.2.4 [Resource Quotas et LimitRanges](/module-12-kubernetes-production/02.4-resource-quotas-limitranges.md)

### 12.3 [Outils d'écosystème](/module-12-kubernetes-production/03-outils-ecosysteme.md)

- 12.3.1 [Kubectl avancé et plugins (krew, kubectl-debug)](/module-12-kubernetes-production/03.1-kubectl-avance-plugins.md)
- 12.3.2 [Helm : charts, repositories et bonnes pratiques](/module-12-kubernetes-production/03.2-helm.md)
- 12.3.3 [Kustomize : overlays et gestion multi-environnement](/module-12-kubernetes-production/03.3-kustomize.md)
- 12.3.4 [Operators et Custom Resource Definitions (CRD)](/module-12-kubernetes-production/03.4-operators-crd.md)

### 12.4 [Autoscaling et gestion des ressources](/module-12-kubernetes-production/04-autoscaling-ressources.md)

- 12.4.1 [Horizontal Pod Autoscaler (HPA)](/module-12-kubernetes-production/04.1-hpa.md)
- 12.4.2 [Vertical Pod Autoscaler (VPA)](/module-12-kubernetes-production/04.2-vpa.md)
- 12.4.3 [Cluster Autoscaler](/module-12-kubernetes-production/04.3-cluster-autoscaler.md)
- 12.4.4 [Right-sizing et optimisation des ressources](/module-12-kubernetes-production/04.4-right-sizing.md)

### 12.5 [Cycle de vie du cluster](/module-12-kubernetes-production/05-cycle-vie-cluster.md)

- 12.5.1 [Sauvegarde etcd et Velero](/module-12-kubernetes-production/05.1-sauvegarde-etcd-velero.md)
- 12.5.2 [Upgrade de clusters Kubernetes sur Debian](/module-12-kubernetes-production/05.2-upgrade-clusters-debian.md)
- 12.5.3 [Blue/Green et Canary deployments](/module-12-kubernetes-production/05.3-blue-green-canary.md)
- 12.5.4 [Migration de workloads (VM → conteneurs)](/module-12-kubernetes-production/05.4-migration-vm-conteneurs.md)

---

## **[Module 13 : Infrastructure as Code](/module-13-infrastructure-as-code.md)** *(Niveau : Avancé-Expert)*

📁 [Scripts du module — Playbooks Ansible, modules Terraform](/module-13-infrastructure-as-code/scripts/README.md)

### 13.1 [Ansible](/module-13-infrastructure-as-code/01-ansible.md)

- 13.1.1 [Architecture et installation sur Debian](/module-13-infrastructure-as-code/01.1-architecture-installation-debian.md)
- 13.1.2 [Inventaires, connexions et variables](/module-13-infrastructure-as-code/01.2-inventaires-connexions-variables.md)
- 13.1.3 [Playbooks : structure, templates Jinja2, handlers](/module-13-infrastructure-as-code/01.3-playbooks-jinja2-handlers.md)
- 13.1.4 [Rôles, collections et Ansible Galaxy](/module-13-infrastructure-as-code/01.4-roles-collections-galaxy.md)
- 13.1.5 [Ansible pour provisionner des nœuds Debian (paquets .deb, config système)](/module-13-infrastructure-as-code/01.5-ansible-provisioning-debian.md)
- 13.1.6 [Ansible pour Kubernetes](/module-13-infrastructure-as-code/01.6-ansible-kubernetes.md)
- 13.1.7 [AWX/Ansible Automation Platform](/module-13-infrastructure-as-code/01.7-awx-automation-platform.md)

### 13.2 [Terraform](/module-13-infrastructure-as-code/02-terraform.md)

- 13.2.1 [Concepts (providers, ressources, data sources)](/module-13-infrastructure-as-code/02.1-concepts-providers-ressources.md)
- 13.2.2 [Installation sur Debian et premiers déploiements](/module-13-infrastructure-as-code/02.2-installation-debian.md)
- 13.2.3 [État (state) et backends (S3, Consul, PostgreSQL)](/module-13-infrastructure-as-code/02.3-state-backends.md)
- 13.2.4 [Modules, workspaces et bonnes pratiques](/module-13-infrastructure-as-code/02.4-modules-workspaces.md)
- 13.2.5 [Terraform pour multi-cloud et on-premise](/module-13-infrastructure-as-code/02.5-multi-cloud-on-premise.md)

### 13.3 [Complémentarité Ansible + Terraform](/module-13-infrastructure-as-code/03-complementarite-ansible-terraform.md)

- 13.3.1 [Terraform pour le provisionning, Ansible pour la configuration](/module-13-infrastructure-as-code/03.1-provisioning-vs-configuration.md)
- 13.3.2 [Patterns d'intégration et workflows combinés](/module-13-infrastructure-as-code/03.2-patterns-workflows.md)
- 13.3.3 [Gestion de l'état et idempotence](/module-13-infrastructure-as-code/03.3-etat-idempotence.md)

---

# PARCOURS 3 — Expert Cloud-Native & Kubernetes

*Modules 14 à 19 · Vers l'expertise DevOps/SRE*

*Prérequis : Parcours 2 ou expérience opérationnelle Kubernetes*

---

## **[Module 14 : CI/CD et GitOps](/module-14-cicd-gitops.md)** *(Niveau : Expert)*

📁 [Scripts du module — Pipelines GitLab/GitHub, manifestes ArgoCD/Flux](/module-14-cicd-gitops/scripts/README.md)

### 14.1 [Principes de CI/CD](/module-14-cicd-gitops/01-principes-cicd.md)

- 14.1.1 [Concepts fondamentaux (intégration continue, déploiement continu)](/module-14-cicd-gitops/01.1-concepts-fondamentaux.md)
- 14.1.2 [Pipelines : conception et bonnes pratiques](/module-14-cicd-gitops/01.2-pipelines-conception.md)
- 14.1.3 [Stratégies de branching et workflows Git](/module-14-cicd-gitops/01.3-strategies-branching.md)

### 14.2 [CI/CD sur serveur Debian](/module-14-cicd-gitops/02-cicd-serveur-debian.md)

- 14.2.1 [GitLab Runner comme service systemd sur Debian](/module-14-cicd-gitops/02.1-gitlab-runner-systemd.md)
- 14.2.2 [GitHub Actions self-hosted runner sur Debian](/module-14-cicd-gitops/02.2-github-actions-self-hosted.md)
- 14.2.3 [Configuration, maintenance et sécurisation des runners](/module-14-cicd-gitops/02.3-configuration-securisation-runners.md)

### 14.3 [CI/CD sur Kubernetes](/module-14-cicd-gitops/03-cicd-kubernetes.md)

- 14.3.1 [Jenkins sur Kubernetes](/module-14-cicd-gitops/03.1-jenkins-kubernetes.md)
- 14.3.2 [Tekton Pipelines](/module-14-cicd-gitops/03.2-tekton-pipelines.md)
- 14.3.3 [GitLab CI avec runners Kubernetes](/module-14-cicd-gitops/03.3-gitlab-ci-runners-k8s.md)
- 14.3.4 [Comparaison des approches (serveur Debian vs K8s)](/module-14-cicd-gitops/03.4-comparaison-approches.md)

### 14.4 [GitOps](/module-14-cicd-gitops/04-gitops.md)

- 14.4.1 [Principes GitOps et avantages](/module-14-cicd-gitops/04.1-principes-gitops.md)
- 14.4.2 [ArgoCD : architecture et configuration](/module-14-cicd-gitops/04.2-argocd.md)
- 14.4.3 [Flux : architecture et configuration](/module-14-cicd-gitops/04.3-flux.md)
- 14.4.4 [Déploiement automatisé multi-environnement](/module-14-cicd-gitops/04.4-deploiement-multi-environnement.md)
- 14.4.5 [Gestion des secrets dans un workflow GitOps (Sealed Secrets, SOPS)](/module-14-cicd-gitops/04.5-secrets-gitops.md)

---

## **[Module 15 : Observabilité et monitoring](/module-15-observabilite-monitoring.md)** *(Niveau : Expert)*

📁 [Scripts du module — Prometheus, Loki, Tempo, OTel Collector, dashboards Grafana](/module-15-observabilite-monitoring/scripts/README.md)

### 15.1 [Les trois piliers de l'observabilité](/module-15-observabilite-monitoring/01-trois-piliers.md)

- 15.1.1 [Métriques, logs, traces : concepts et complémentarité](/module-15-observabilite-monitoring/01.1-metriques-logs-traces.md)
- 15.1.2 [SLO, SLI, SLA et error budgets](/module-15-observabilite-monitoring/01.2-slo-sli-sla.md)
- 15.1.3 [Stratégie d'observabilité globale](/module-15-observabilite-monitoring/01.3-strategie-observabilite.md)

### 15.2 [Métriques et alerting](/module-15-observabilite-monitoring/02-metriques-alerting.md)

- 15.2.1 [Prometheus : architecture et installation sur Debian/K8s](/module-15-observabilite-monitoring/02.1-prometheus-architecture.md)
- 15.2.2 [PromQL et métriques custom](/module-15-observabilite-monitoring/02.2-promql-metriques-custom.md)
- 15.2.3 [AlertManager : règles et routing](/module-15-observabilite-monitoring/02.3-alertmanager.md)
- 15.2.4 [Grafana : dashboards et visualisation](/module-15-observabilite-monitoring/02.4-grafana-dashboards.md)
- 15.2.5 [Node Exporter et métriques système Debian](/module-15-observabilite-monitoring/02.5-node-exporter-debian.md)

### 15.3 [Logs](/module-15-observabilite-monitoring/03-logs.md)

- 15.3.1 [ELK Stack sur Debian (Elasticsearch, Logstash, Kibana)](/module-15-observabilite-monitoring/03.1-elk-stack-debian.md)
- 15.3.2 [Alternatives légères (Loki + Promtail, Fluent Bit)](/module-15-observabilite-monitoring/03.2-loki-promtail-fluentbit.md)
- 15.3.3 [Agrégation de logs multi-cluster](/module-15-observabilite-monitoring/03.3-agregation-logs-multi-cluster.md)
- 15.3.4 [Intégration avec journald Debian](/module-15-observabilite-monitoring/03.4-integration-journald.md)

### 15.4 [Tracing distribué](/module-15-observabilite-monitoring/04-tracing-distribue.md)

- 15.4.1 [Concepts du distributed tracing](/module-15-observabilite-monitoring/04.1-concepts-tracing.md)
- 15.4.2 [Jaeger : architecture et utilisation](/module-15-observabilite-monitoring/04.2-jaeger.md)
- 15.4.3 [OpenTelemetry : standard unifié (métriques, logs, traces)](/module-15-observabilite-monitoring/04.3-opentelemetry.md)

---

## **[Module 16 : Sécurité avancée et cloud-native](/module-16-securite-avancee.md)** *(Niveau : Expert)*

### 16.1 [Hardening système Debian](/module-16-securite-avancee/01-hardening-debian.md)

- 16.1.1 [Sécurisation du noyau (sysctl, lockdown mode, kernel self-protection)](/module-16-securite-avancee/01.1-securisation-noyau.md)
- 16.1.2 [AppArmor sur Debian (profils, modes, personnalisation)](/module-16-securite-avancee/01.2-apparmor-debian.md)
- 16.1.3 [Audit et conformité (CIS benchmarks Debian)](/module-16-securite-avancee/01.3-audit-cis-benchmarks.md)
- 16.1.4 [Sécurisation du boot (Secure Boot, dm-verity)](/module-16-securite-avancee/01.4-securisation-boot.md)
- 16.1.5 [Durcissement réseau et services (ports, services inutiles)](/module-16-securite-avancee/01.5-durcissement-reseau-services.md)

### 16.2 [Sécurité Kubernetes](/module-16-securite-avancee/02-securite-kubernetes.md)

- 16.2.1 [RBAC avancé et least privilege](/module-16-securite-avancee/02.1-rbac-avance.md)
- 16.2.2 [Pod Security Standards et Admission Controllers](/module-16-securite-avancee/02.2-pod-security-admission.md)
- 16.2.3 [OPA Gatekeeper et Policy as Code](/module-16-securite-avancee/02.3-opa-gatekeeper.md)
- 16.2.4 [Falco (runtime security)](/module-16-securite-avancee/02.4-falco.md)
- 16.2.5 [Network Policies avancées (Cilium)](/module-16-securite-avancee/02.5-network-policies-cilium.md)

### 16.3 [Secrets et chiffrement](/module-16-securite-avancee/03-secrets-chiffrement.md)

- 16.3.1 [HashiCorp Vault (installation sur Debian, intégration K8s)](/module-16-securite-avancee/03.1-hashicorp-vault.md)
- 16.3.2 [Kubernetes Secrets et External Secrets Operator](/module-16-securite-avancee/03.2-k8s-secrets-external-secrets.md)
- 16.3.3 [cert-manager et gestion des certificats](/module-16-securite-avancee/03.3-cert-manager.md)
- 16.3.4 [Chiffrement at-rest et in-transit](/module-16-securite-avancee/03.4-chiffrement-at-rest-in-transit.md)

### 16.4 [DevSecOps](/module-16-securite-avancee/04-devsecops.md)

- 16.4.1 [Intégration sécurité dans les pipelines CI/CD (SAST/DAST)](/module-16-securite-avancee/04.1-securite-cicd-sast-dast.md)
- 16.4.2 [Supply chain security (signatures d'images, SBOM, Cosign)](/module-16-securite-avancee/04.2-supply-chain-security.md)
- 16.4.3 [Compliance automation](/module-16-securite-avancee/04.3-compliance-automation.md)
- 16.4.4 [Détection d'intrusion et réponse aux incidents (SIEM, IDS/IPS)](/module-16-securite-avancee/04.4-detection-intrusion-reponse.md)

---

## **[Module 17 : Cloud, Service Mesh et stockage distribué](/module-17-cloud-service-mesh-stockage.md)** *(Niveau : Expert)*

### 17.1 [Cloud providers](/module-17-cloud-service-mesh-stockage/01-cloud-providers.md)

- 17.1.1 [AWS CLI et outils sur Debian](/module-17-cloud-service-mesh-stockage/01.1-aws-cli-debian.md)
- 17.1.2 [Google Cloud SDK sur Debian](/module-17-cloud-service-mesh-stockage/01.2-gcloud-sdk-debian.md)
- 17.1.3 [Azure CLI sur Debian](/module-17-cloud-service-mesh-stockage/01.3-azure-cli-debian.md)
- 17.1.4 [Images Debian officielles dans le cloud (AMI, GCE images)](/module-17-cloud-service-mesh-stockage/01.4-images-debian-cloud.md)
- 17.1.5 [Managed Kubernetes (EKS, GKE, AKS) : concepts et comparaison](/module-17-cloud-service-mesh-stockage/01.5-managed-kubernetes.md)

### 17.2 [Service Mesh](/module-17-cloud-service-mesh-stockage/02-service-mesh.md)

- 17.2.1 [Concepts et cas d'usage (mTLS, traffic management, observabilité)](/module-17-cloud-service-mesh-stockage/02.1-concepts-cas-usage.md)
- 17.2.2 [Istio : architecture et configuration](/module-17-cloud-service-mesh-stockage/02.2-istio.md)
- 17.2.3 [Linkerd : architecture et configuration](/module-17-cloud-service-mesh-stockage/02.3-linkerd.md)
- 17.2.4 [Comparaison et critères de choix](/module-17-cloud-service-mesh-stockage/02.4-comparaison-service-mesh.md)

### 17.3 [Stockage distribué](/module-17-cloud-service-mesh-stockage/03-stockage-distribue.md)

- 17.3.1 [Ceph sur Debian](/module-17-cloud-service-mesh-stockage/03.1-ceph-debian.md)
- 17.3.2 [MinIO (S3 compatible)](/module-17-cloud-service-mesh-stockage/03.2-minio.md)
- 17.3.3 [Rook pour Kubernetes](/module-17-cloud-service-mesh-stockage/03.3-rook-kubernetes.md)
- 17.3.4 [Comparaison et cas d'usage](/module-17-cloud-service-mesh-stockage/03.4-comparaison-stockage.md)

---

## **[Module 18 : Edge Computing, FinOps et tendances](/module-18-edge-finops-tendances.md)** *(Niveau : Avancé-Expert)*

### 18.1 [Kubernetes à la périphérie](/module-18-edge-finops-tendances/01-kubernetes-edge.md)

- 18.1.1 [K3s pour edge devices sur Debian](/module-18-edge-finops-tendances/01.1-k3s-edge-debian.md)
- 18.1.2 [Architecture edge-to-cloud](/module-18-edge-finops-tendances/01.2-architecture-edge-to-cloud.md)
- 18.1.3 [Contraintes réseau et synchronisation](/module-18-edge-finops-tendances/01.3-contraintes-reseau-synchronisation.md)
- 18.1.4 [Sécurité IoT et mises à jour OTA](/module-18-edge-finops-tendances/01.4-securite-iot-ota.md)

### 18.2 [FinOps et optimisation des coûts](/module-18-edge-finops-tendances/02-finops-optimisation.md)

- 18.2.1 [Resource quotas, limits et right-sizing](/module-18-edge-finops-tendances/02.1-quotas-limits-rightsizing.md)
- 18.2.2 [Cost monitoring et alerting (Kubecost, OpenCost)](/module-18-edge-finops-tendances/02.2-cost-monitoring-kubecost.md)
- 18.2.3 [Comparaison des coûts entre providers](/module-18-edge-finops-tendances/02.3-comparaison-couts-providers.md)
- 18.2.4 [Reserved instances, spot instances et stratégies d'optimisation](/module-18-edge-finops-tendances/02.4-reserved-spot-optimisation.md)

### 18.3 [Tendances et évolutions](/module-18-edge-finops-tendances/03-tendances-evolutions.md)

- 18.3.1 [Platform Engineering et portails développeurs (Backstage)](/module-18-edge-finops-tendances/03.1-platform-engineering-backstage.md)
- 18.3.2 [WebAssembly (Wasm) et conteneurs](/module-18-edge-finops-tendances/03.2-webassembly-conteneurs.md)
- 18.3.3 [eBPF et observabilité nouvelle génération](/module-18-edge-finops-tendances/03.3-ebpf-observabilite.md)
- 18.3.4 [IA/ML Ops sur Kubernetes (concepts)](/module-18-edge-finops-tendances/03.4-mlops-kubernetes.md)

---

## **[Module 19 : Architectures de référence et cas d'usage](/module-19-architectures-reference.md)** *(Niveau : Tous niveaux)*

📁 [Scripts du module — 5 architectures intégrées de bout en bout (poste dev, infra hybride, IDP, migration legacy, DR)](/module-19-architectures-reference/scripts/README.md)

### 19.1 [Architecture poste développeur cloud-native](/module-19-architectures-reference/01-poste-developpeur.md) *(Parcours 1-2)*

- 19.1.1 [Configuration complète poste développeur Debian](/module-19-architectures-reference/01.1-configuration-poste-debian.md)
- 19.1.2 [Environnement de développement K8s local (Kind, Skaffold, Tilt)](/module-19-architectures-reference/01.2-environnement-k8s-local.md)
- 19.1.3 [Outillage et personnalisation avancée](/module-19-architectures-reference/01.3-outillage-personnalisation.md)

### 19.2 [Architecture infrastructure hybride](/module-19-architectures-reference/02-infrastructure-hybride.md) *(Parcours 2-3)*

- 19.2.1 [Conception d'une infrastructure on-premise + cloud](/module-19-architectures-reference/02.1-conception-on-premise-cloud.md)
- 19.2.2 [Cluster Kubernetes multi-nœuds HA sur Debian](/module-19-architectures-reference/02.2-cluster-k8s-ha-debian.md)
- 19.2.3 [Services intégrés (web, mail, DNS, DHCP)](/module-19-architectures-reference/02.3-services-integres.md)
- 19.2.4 [Pipeline CI/CD de bout en bout](/module-19-architectures-reference/02.4-pipeline-cicd-complet.md)
- 19.2.5 [Procédures d'exploitation et runbooks](/module-19-architectures-reference/02.5-procedures-exploitation-runbooks.md)

### 19.3 [Architecture Platform Engineering](/module-19-architectures-reference/03-platform-engineering.md) *(Parcours 3)*

- 19.3.1 [Plateforme interne de développement](/module-19-architectures-reference/03.1-plateforme-interne.md)
- 19.3.2 [Self-service portal et developer experience](/module-19-architectures-reference/03.2-self-service-portal.md)
- 19.3.3 [GitOps workflow complet](/module-19-architectures-reference/03.3-gitops-workflow-complet.md)
- 19.3.4 [Multi-tenancy, isolation et policy enforcement](/module-19-architectures-reference/03.4-multi-tenancy-isolation.md)

### 19.4 [Architecture de migration cloud-native](/module-19-architectures-reference/04-migration-cloud-native.md) *(Parcours 3)*

- 19.4.1 [Modernisation d'une application legacy](/module-19-architectures-reference/04.1-modernisation-legacy.md)
- 19.4.2 [Conteneurisation et refactoring en microservices](/module-19-architectures-reference/04.2-conteneurisation-microservices.md)
- 19.4.3 [Stratégies de migration zero-downtime](/module-19-architectures-reference/04.3-migration-zero-downtime.md)
- 19.4.4 [Monitoring, performance testing et optimisation](/module-19-architectures-reference/04.4-monitoring-performance-optimisation.md)

### 19.5 [Disaster Recovery et résilience](/module-19-architectures-reference/05-disaster-recovery.md) *(Parcours 2-3)*

- 19.5.1 [Architectures multi-région et cross-cloud](/module-19-architectures-reference/05.1-multi-region-cross-cloud.md)
- 19.5.2 [Chaos Engineering (principes et outils)](/module-19-architectures-reference/05.2-chaos-engineering.md)
- 19.5.3 [Runbooks automatisés et réponse aux incidents](/module-19-architectures-reference/05.3-runbooks-automatises.md)
- 19.5.4 [RTO/RPO : dimensionnement et validation](/module-19-architectures-reference/05.4-rto-rpo-dimensionnement.md)

---

## **[Annexes](/annexes/README.md)**

### A. [Commandes essentielles par module](/annexes/A-commandes-essentielles.md)

- [Référence des commandes par catégorie](/annexes/A.1-reference-commandes.md)
- [Options courantes et exemples](/annexes/A.2-options-exemples.md)
- [Cheat sheets par technologie (Debian, Docker, K8s, Terraform, Ansible)](/annexes/A.3-cheat-sheets.md)

### B. [Fichiers de configuration Debian](/annexes/B-fichiers-configuration.md)

- [Localisation des fichiers importants par service](/annexes/B.1-localisation-fichiers.md)
- [Syntaxe et exemples annotés](/annexes/B.2-syntaxe-exemples.md)
- [Templates et bonnes pratiques](/annexes/B.3-templates-bonnes-pratiques.md)

### C. [Troubleshooting par composant](/annexes/C-troubleshooting.md)

- [Guide diagnostic système Debian](/annexes/C.1-diagnostic-systeme.md)
- [Problèmes courants Kubernetes](/annexes/C.2-problemes-kubernetes.md)
- [Résolution réseau et stockage](/annexes/C.3-resolution-reseau-stockage.md)
- [Procédures recovery](/annexes/C.4-procedures-recovery.md)

### D. [Ressources et documentation](/annexes/D-ressources-documentation.md)

- [Documentation officielle (Debian, Kubernetes, cloud providers)](/annexes/D.1-documentation-officielle.md)
- [Communautés et forums](/annexes/D.2-communautes-forums.md)
- [Veille technologique](/annexes/D.3-veille-technologique.md)

### E. [Certifications et évaluation](/annexes/E-certifications-evaluation.md)

- [Critères d'évaluation par module et par parcours](/annexes/E.1-criteres-evaluation.md)
- [Préparation certifications (CKA, CKS, Terraform Associate)](/annexes/E.2-preparation-certifications.md)
- [Cas d'usage métier et architectures sectorielles](/annexes/E.3-cas-usage-metier.md)

---

**Prérequis : Bases Linux et réseau (TCP/IP, DNS, HTTP)**  
**Certifications préparées : CKA, CKS, Terraform Associate**  
