🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe A.1 — Référence des commandes par catégorie

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette sous-annexe organise l'ensemble des commandes abordées dans la formation selon un classement **fonctionnel transversal**, indépendamment du module dans lequel elles apparaissent. L'objectif est de permettre à un administrateur ou un ingénieur de retrouver rapidement la commande appropriée en partant du besoin (« je dois diagnostiquer un problème réseau ») plutôt que du module de formation.

Chaque commande est accompagnée d'une description concise de son rôle et d'un ou deux exemples d'utilisation. Les modules de référence sont indiqués entre parenthèses pour faciliter le renvoi vers le cours détaillé.

---

## Conventions

- `#` : commande exécutée en tant que root ou via `sudo`
- `$` : commande exécutée en tant qu'utilisateur standard
- `<valeur>` : paramètre à remplacer
- `[option]` : paramètre facultatif

---

## 1. Gestion du système et du démarrage

Cette catégorie regroupe les commandes liées au cycle de vie du système, au contrôle des services et à l'analyse du démarrage.

**systemctl** — Contrôle central de systemd et de l'ensemble des services, timers et targets du système. (Modules 3, 7, 8)

```bash
# Gestion des services
# systemctl start|stop|restart|reload <service>
# systemctl enable|disable <service>
# systemctl status <service>
# systemctl is-active <service>
# systemctl is-enabled <service>

# Gestion des targets
# systemctl get-default
# systemctl set-default multi-user.target
# systemctl isolate rescue.target

# Listage
# systemctl list-units --type=service --state=running
# systemctl list-units --type=timer
# systemctl list-unit-files --state=enabled

# Rechargement global
# systemctl daemon-reload
```

**journalctl** — Consultation et filtrage des journaux du système gérés par systemd-journald. (Modules 3, 15)

```bash
# Journaux d'un service spécifique
$ journalctl -u nginx.service

# Suivi en temps réel
$ journalctl -f

# Filtrage par période
$ journalctl --since "2026-04-01 08:00" --until "2026-04-01 12:00"

# Filtrage par priorité (0=emerg à 7=debug)
$ journalctl -p err

# Journaux du démarrage courant
$ journalctl -b

# Espace disque utilisé par les journaux
$ journalctl --disk-usage

# Nettoyage des anciens journaux
# journalctl --vacuum-time=30d
# journalctl --vacuum-size=500M
```

**systemd-analyze** — Analyse des performances de démarrage du système. (Module 3)

```bash
$ systemd-analyze                        # Temps total de démarrage
$ systemd-analyze blame                  # Classement des services par temps
$ systemd-analyze critical-chain         # Chaîne critique de démarrage
$ systemd-analyze plot > boot.svg        # Graphique SVG du démarrage
```

**timedatectl** — Configuration du fuseau horaire et de la synchronisation NTP. (Module 1)

```bash
$ timedatectl status
# timedatectl set-timezone Europe/Paris
# timedatectl set-ntp true
```

**localectl** — Configuration de la langue et de la disposition du clavier. (Module 1)

```bash
$ localectl status
# localectl set-locale LANG=fr_FR.UTF-8
# localectl set-keymap fr
# localectl set-x11-keymap fr
```

**hostnamectl** — Gestion du nom d'hôte du système. (Module 1)

```bash
$ hostnamectl status
# hostnamectl set-hostname srv-debian01
```

---

## 2. Gestion des paquets et logiciels

Toutes les commandes liées à l'installation, la mise à jour, la suppression et l'inspection des logiciels sur un système Debian.

**apt** — Interface haut niveau pour la gestion des paquets Debian. C'est l'outil principal pour les opérations courantes. (Module 4)

```bash
# Mise à jour de l'index des paquets
# apt update

# Installation et suppression
# apt install <paquet> [<paquet2> ...]
# apt install <paquet>=<version>          # Version spécifique
# apt install --no-install-recommends <paquet>
# apt remove <paquet>
# apt purge <paquet>                      # Suppression avec fichiers de config
# apt autoremove                          # Nettoyage des dépendances orphelines

# Mise à jour du système
# apt upgrade
# apt full-upgrade                        # Gère aussi les changements de dépendances

# Recherche et information
$ apt search <terme>
$ apt show <paquet>
$ apt list --installed
$ apt list --upgradable
$ apt policy <paquet>                     # Affiche les versions et priorités
```

**apt-get / apt-cache** — Interface traditionnelle, toujours pertinente dans les scripts pour sa stabilité de sortie. (Module 4)

```bash
# apt-get update
# apt-get install -y <paquet>
# apt-get dist-upgrade
$ apt-cache search <terme>
$ apt-cache depends <paquet>
$ apt-cache rdepends <paquet>             # Dépendances inversées
$ apt-cache madison <paquet>              # Versions disponibles par dépôt
```

**dpkg** — Gestionnaire bas niveau des paquets .deb, opérant sans résolution automatique des dépendances. (Module 4)

```bash
# Installation locale
# dpkg -i <fichier.deb>
# dpkg -r <paquet>                        # Désinstallation
# dpkg -P <paquet>                        # Purge

# Interrogation
$ dpkg -l                                 # Liste des paquets installés
$ dpkg -l <motif>                         # Filtrage par motif
$ dpkg -L <paquet>                        # Fichiers installés par un paquet
$ dpkg -S <chemin>                        # Paquet propriétaire d'un fichier
$ dpkg --configure -a                     # Reprendre les configurations en attente

# Reconfiguration
# dpkg-reconfigure <paquet>
# dpkg-reconfigure locales
# dpkg-reconfigure tzdata
```

**flatpak** — Gestion des applications sandboxées au format Flatpak. (Module 4)

```bash
# flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# flatpak install flathub <application>
$ flatpak run <application>
# flatpak update
$ flatpak list
# flatpak uninstall <application>
```

**pip / pipx** — Gestion des paquets Python. Sur Debian 12+, l'environnement Python système est marqué `externally-managed` (PEP 668) : `pip install` à la racine échoue avec un message explicite. Deux solutions selon le contexte. (Module 5)

```bash
# Bibliothèques pour un projet : environnement virtuel
$ python3 -m venv <répertoire>
$ source <répertoire>/bin/activate
$ pip install <paquet>
$ pip freeze > requirements.txt
$ pip install -r requirements.txt
$ deactivate                              # Sortir du venv

# Applications Python autonomes (httpie, ansible, black, etc.) : pipx
# isole automatiquement chaque application dans son propre venv tout en
# exposant ses commandes dans le PATH utilisateur (~/.local/bin).
# apt install pipx
$ pipx ensurepath                         # Une seule fois (PATH)
$ pipx install <application>
$ pipx list
$ pipx upgrade <application>
$ pipx uninstall <application>
```

---

## 3. Gestion des utilisateurs, groupes et droits

Les commandes de cette catégorie couvrent la création et l'administration des comptes, la gestion des permissions et la configuration des accès privilégiés.

**adduser / deluser** — Création et suppression d'utilisateurs de manière interactive (wrappers Debian autour de useradd/userdel). (Module 3)

```bash
# adduser <utilisateur>
# adduser <utilisateur> <groupe>
# deluser <utilisateur>
# deluser --remove-home <utilisateur>
```

**useradd / userdel / usermod** — Commandes bas niveau pour la gestion des comptes utilisateurs. (Module 3)

```bash
# useradd -m -s /bin/bash <utilisateur>
# userdel -r <utilisateur>
# usermod -aG sudo <utilisateur>          # Ajout au groupe sudo
# usermod -L <utilisateur>                # Verrouillage du compte
# usermod -U <utilisateur>                # Déverrouillage
# usermod -s /usr/sbin/nologin <utilisateur>
```

**passwd / chage** — Gestion des mots de passe et des politiques d'expiration. (Module 3)

```bash
# passwd <utilisateur>
# passwd -l <utilisateur>                 # Verrouillage par mot de passe
# passwd -e <utilisateur>                 # Forcer le changement au prochain login
# chage -l <utilisateur>                  # Afficher la politique
# chage -M 90 <utilisateur>              # Durée max du mot de passe : 90 jours
# chage -E 2026-12-31 <utilisateur>      # Date d'expiration du compte
```

**groupadd / groupdel / gpasswd** — Gestion des groupes. (Module 3)

```bash
# groupadd <groupe>
# groupdel <groupe>
# gpasswd -a <utilisateur> <groupe>       # Ajouter un membre
# gpasswd -d <utilisateur> <groupe>       # Retirer un membre
$ groups <utilisateur>                     # Afficher les groupes d'un utilisateur
$ id <utilisateur>                         # UID, GID et groupes
```

**chmod / chown / chgrp** — Modification des permissions et de la propriété des fichiers. (Module 3)

```bash
# chmod 750 <fichier>
# chmod u+x <script>
# chmod -R g+rw <répertoire>
# chown <utilisateur>:<groupe> <fichier>
# chown -R www-data:www-data /var/www/
# chgrp <groupe> <fichier>
```

**setfacl / getfacl** — Gestion des listes de contrôle d'accès (ACL) étendues. (Module 3)

```bash
$ getfacl <fichier>
# setfacl -m u:<utilisateur>:rwx <fichier>
# setfacl -m g:<groupe>:rx <répertoire>
# setfacl -R -m d:u:<utilisateur>:rw <répertoire>  # ACL par défaut récursive
# setfacl -b <fichier>                    # Supprimer toutes les ACL
```

**visudo** — Édition sécurisée de la configuration sudo (vérifie la syntaxe avant enregistrement). (Module 3)

```bash
# visudo                                   # Édite /etc/sudoers
# visudo -f /etc/sudoers.d/<fichier>       # Édite un fichier de drop-in
```

---

## 4. Système de fichiers et stockage

Commandes de gestion des partitions, systèmes de fichiers, montage, LVM, RAID et chiffrement.

**lsblk / blkid / fdisk / gdisk / parted** — Inspection et partitionnement des disques. (Modules 1, 8)

```bash
$ lsblk                                   # Arborescence des blocs
$ lsblk -f                                # Avec les systèmes de fichiers
$ blkid                                   # UUID et types des partitions
# fdisk /dev/sda                           # Partitionnement MBR
# gdisk /dev/sda                           # Partitionnement GPT
# parted /dev/sda print                    # Affichage de la table
```

**mkfs / mount / umount / fstab** — Création et montage de systèmes de fichiers. (Modules 1, 3)

```bash
# mkfs.ext4 /dev/sda1
# mkfs.xfs /dev/sda2
# mkfs.btrfs /dev/sda3

# mount /dev/sda1 /mnt/data
# mount -t nfs <serveur>:/export /mnt/nfs
# umount /mnt/data

# Vérification sans montage
# mount -a                                 # Monte tout selon /etc/fstab
$ findmnt                                  # Arborescence des points de montage
```

**df / du** — Utilisation de l'espace disque. (Module 3)

```bash
$ df -h                                    # Espace par partition (lisible)
$ df -i                                    # Utilisation des inodes
$ du -sh <répertoire>                      # Taille d'un répertoire
$ du -h --max-depth=1 /var                 # Taille par sous-répertoire
```

**ln** — Création de liens symboliques et physiques. (Module 3)

```bash
$ ln -s <cible> <lien>                     # Lien symbolique
$ ln <cible> <lien>                        # Lien physique
$ readlink -f <lien>                       # Résolution complète d'un lien
```

**mdadm** — Administration des grappes RAID logiciel. (Module 8)

```bash
# mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]1
# mdadm --detail /dev/md0
# mdadm --manage /dev/md0 --add /dev/sdc1
# mdadm --manage /dev/md0 --fail /dev/sda1
$ cat /proc/mdstat                         # État en temps réel
# mdadm --examine /dev/sda1               # Métadonnées RAID d'un disque
```

**pvcreate / vgcreate / lvcreate / lvextend** — Pile LVM (Logical Volume Manager). (Module 8)

```bash
# pvcreate /dev/sda1
# vgcreate vg_data /dev/sda1 /dev/sdb1
# lvcreate -L 50G -n lv_www vg_data
# lvcreate -l 100%FREE -n lv_home vg_data

# Extension d'un volume logique
# lvextend -L +10G /dev/vg_data/lv_www
# resize2fs /dev/vg_data/lv_www            # ext4
# xfs_growfs /mnt/www                      # XFS

# Inspection
$ pvs                                      # Résumé des volumes physiques
$ vgs                                      # Résumé des groupes de volumes
$ lvs                                      # Résumé des volumes logiques
$ pvdisplay / vgdisplay / lvdisplay        # Détails complets
```

**smartctl** — Interrogation des données SMART des disques pour la surveillance de santé. (Module 8)

```bash
# smartctl -a /dev/sda                     # Toutes les informations SMART
# smartctl -H /dev/sda                     # État de santé global
# smartctl -t short /dev/sda               # Lancement d'un test court
```

**cryptsetup** — Gestion du chiffrement de disques avec LUKS/dm-crypt. (Module 6)

```bash
# cryptsetup luksFormat /dev/sda2
# cryptsetup luksOpen /dev/sda2 crypt_data
# cryptsetup luksClose crypt_data
# cryptsetup luksDump /dev/sda2            # Informations sur l'en-tête LUKS
# cryptsetup luksAddKey /dev/sda2          # Ajouter une clé de déchiffrement
```

---

## 5. Gestion des processus et des ressources

Commandes de supervision, contrôle et ordonnancement des processus.

**ps** — Capture instantanée des processus en cours d'exécution. (Module 3)

```bash
$ ps aux                                   # Tous les processus (format BSD)
$ ps -ef                                   # Tous les processus (format System V)
$ ps -u <utilisateur>                      # Processus d'un utilisateur
$ ps aux --sort=-%mem | head -20           # Top 20 par mémoire
$ ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu
```

**top / htop** — Supervision interactive des processus en temps réel. (Module 3)

```bash
$ top                                      # Vue temps réel
$ top -u <utilisateur>                     # Filtrer par utilisateur
$ htop                                     # Version améliorée et interactive
```

**kill / killall / pkill** — Envoi de signaux aux processus. (Module 3)

```bash
$ kill <PID>                               # SIGTERM (arrêt propre)
$ kill -9 <PID>                            # SIGKILL (arrêt forcé)
$ kill -HUP <PID>                          # Rechargement de configuration
$ killall <nom>                            # Par nom de processus
$ pkill -f <motif>                         # Par motif dans la ligne de commande
```

**nice / renice / ionice** — Gestion des priorités d'exécution. (Module 3)

```bash
$ nice -n 10 <commande>                    # Lancement avec priorité réduite
# renice -n -5 -p <PID>                   # Modification de la priorité
# ionice -c2 -n0 <commande>               # Priorité d'E/S élevée
```

**bg / fg / jobs / nohup** — Contrôle des tâches en arrière-plan et en premier plan. (Module 3)

```bash
$ <commande> &                             # Lancement en arrière-plan
$ jobs                                     # Liste des jobs du shell
$ fg %1                                    # Ramener le job 1 au premier plan
$ bg %1                                    # Relancer le job 1 en arrière-plan
$ nohup <commande> &                       # Survie à la fermeture du terminal
```

---

## 6. Réseau

L'ensemble des commandes de configuration, diagnostic et analyse réseau.

**ip** — Outil unifié pour la gestion des interfaces, adresses et routes (remplace ifconfig et route). (Module 6)

```bash
$ ip addr show                             # Adresses de toutes les interfaces
$ ip addr show <interface>                 # Adresses d'une interface
# ip addr add <ip>/<masque> dev <interface>
# ip addr del <ip>/<masque> dev <interface>
# ip link set <interface> up|down

$ ip route show                            # Table de routage
# ip route add <réseau>/<masque> via <passerelle>
# ip route add default via <passerelle>

$ ip neigh show                            # Table ARP / voisinage
$ ip -s link show <interface>              # Statistiques d'interface

# VLAN
# ip link add link <interface> name <interface>.<vlan> type vlan id <vlan>
```

**ss** — Affichage des sockets réseau (remplace netstat). (Module 6)

```bash
$ ss -tlnp                                 # Ports TCP en écoute avec processus
$ ss -ulnp                                 # Ports UDP en écoute
$ ss -s                                    # Résumé statistique
$ ss -t state established                  # Connexions établies
$ ss -t dst <ip>                           # Connexions vers une IP spécifique
```

**ping / traceroute / mtr** — Tests de connectivité et analyse du chemin réseau. (Module 6)

```bash
$ ping -c 4 <hôte>                         # 4 paquets ICMP
$ ping6 <hôte>                             # Ping IPv6
$ traceroute <hôte>                        # Trace du chemin réseau
$ mtr <hôte>                               # Traceroute interactif continu
```

**tcpdump** — Capture de trafic réseau en ligne de commande. (Module 6)

```bash
# tcpdump -i <interface>                   # Capture sur une interface
# tcpdump -i <interface> port 443          # Filtrage par port
# tcpdump -i <interface> host <ip>         # Filtrage par hôte
# tcpdump -i <interface> -w capture.pcap   # Écriture dans un fichier
# tcpdump -r capture.pcap                  # Lecture d'une capture
# tcpdump -n -c 100                        # 100 paquets sans résolution DNS
```

**dig / nslookup / host** — Interrogation DNS. (Modules 6, 8)

```bash
$ dig <domaine>                            # Requête DNS complète
$ dig <domaine> MX                         # Enregistrements MX
$ dig @<serveur> <domaine>                 # Interrogation d'un serveur spécifique
$ dig +short <domaine>                     # Réponse concise
$ dig -x <ip>                              # Reverse DNS
$ nslookup <domaine>
$ host <domaine>
```

**curl / wget** — Transferts HTTP et téléchargement. (Modules 5, 7)

```bash
$ curl -v https://example.com              # Requête avec détails de connexion
$ curl -s https://api.example.com/data | jq .
$ curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' <url>
$ curl -o <fichier> <url>                  # Téléchargement
$ curl -k https://localhost:8443           # Ignorer la vérification TLS

$ wget <url>                               # Téléchargement simple
$ wget -r -np <url>                        # Téléchargement récursif
```

---

## 7. Pare-feu et sécurité réseau

Commandes de filtrage du trafic, protection contre les intrusions et contrôle d'accès réseau.

**nftables (nft)** — Framework de filtrage réseau natif, successeur d'iptables. (Module 6)

```bash
# nft list ruleset                         # Afficher toutes les règles
# nft list tables                          # Lister les tables
# nft add table inet filter
# nft add chain inet filter input '{ type filter hook input priority 0; policy drop; }'
# nft add rule inet filter input tcp dport 22 accept
# nft add rule inet filter input ct state established,related accept
# nft flush ruleset                        # Supprimer toutes les règles
# nft -f /etc/nftables.conf               # Charger depuis un fichier
```

**ufw** — Interface simplifiée pour la gestion du pare-feu. (Module 6)

```bash
# ufw enable
# ufw disable
# ufw status verbose
# ufw allow 22/tcp
# ufw allow from <ip> to any port 3306
# ufw deny 8080
# ufw delete allow 8080
# ufw reset
```

**fail2ban** — Protection automatique contre les attaques par force brute. (Module 6)

```bash
# fail2ban-client status                   # État général
# fail2ban-client status sshd             # État de la jail SSH
# fail2ban-client set sshd banip <ip>     # Bannir une IP manuellement
# fail2ban-client set sshd unbanip <ip>   # Débannir
# fail2ban-client reload                   # Recharger la configuration
```

---

## 8. SSH et accès distant

Commandes de connexion sécurisée, transfert de fichiers et tunneling.

**ssh** — Client de connexion sécurisée à distance. (Module 6)

```bash
$ ssh <utilisateur>@<hôte>
$ ssh -p <port> <utilisateur>@<hôte>
$ ssh -i <clé_privée> <utilisateur>@<hôte>
$ ssh -J <bastion> <utilisateur>@<cible>   # Connexion via jump host

# Tunneling
$ ssh -L <port_local>:<cible>:<port_cible> <utilisateur>@<hôte>   # Local forward
$ ssh -R <port_distant>:<cible>:<port_cible> <utilisateur>@<hôte> # Remote forward
$ ssh -D <port> <utilisateur>@<hôte>       # Proxy SOCKS dynamique
```

**ssh-keygen / ssh-copy-id / ssh-agent** — Gestion des clés et de l'authentification. (Module 6)

```bash
$ ssh-keygen -t ed25519 -C "<commentaire>"
$ ssh-copy-id <utilisateur>@<hôte>
$ eval "$(ssh-agent -s)"
$ ssh-add <clé_privée>
$ ssh-add -l                               # Lister les clés chargées
```

**scp / rsync** — Transfert de fichiers sécurisé. (Modules 6, 8)

```bash
$ scp <fichier> <utilisateur>@<hôte>:<destination>
$ scp -r <répertoire> <utilisateur>@<hôte>:<destination>

$ rsync -avz <source> <utilisateur>@<hôte>:<destination>
$ rsync -avz --delete <source> <destination>
$ rsync -avz --exclude='*.log' <source> <destination>
$ rsync -avzn <source> <destination>       # Dry-run (simulation)
```

---

## 9. VPN

**WireGuard** — VPN moderne, léger et performant. (Module 6)

```bash
$ wg genkey | tee privatekey | wg pubkey > publickey
$ wg show                                  # État des interfaces WireGuard
# wg-quick up wg0
# wg-quick down wg0
# wg set wg0 peer <clé_publique> allowed-ips <réseau> endpoint <ip>:<port>
```

---

## 10. Serveurs web

**Apache (apache2ctl / a2ensite / a2enmod)** — Serveur web Apache HTTP Server. (Module 7)

```bash
# apache2ctl -t                            # Test de syntaxe
# apache2ctl -S                            # Résumé des virtual hosts
# apache2ctl graceful                      # Rechargement gracieux
# a2ensite <site>                          # Activer un virtual host
# a2dissite <site>                         # Désactiver
# a2enmod <module>                         # Activer un module
# a2dismod <module>                        # Désactiver
```

**Nginx** — Serveur web et reverse proxy. (Module 7)

```bash
# nginx -t                                 # Test de syntaxe
# nginx -T                                 # Test et affichage de la config complète
# nginx -s reload                          # Rechargement
# nginx -s stop                            # Arrêt immédiat
# nginx -s quit                            # Arrêt propre
```

**Caddy** — Serveur web avec HTTPS automatique. (Module 7)

```bash
# caddy run                                # Lancement au premier plan
# caddy start                              # Lancement en arrière-plan
# caddy stop
# caddy reload                             # Rechargement de la configuration
# caddy adapt --config Caddyfile           # Conversion Caddyfile vers JSON
# caddy validate --config Caddyfile
```

**certbot** — Gestion des certificats Let's Encrypt via le protocole ACME. (Module 7)

```bash
# certbot --nginx -d <domaine>             # Obtention + config Nginx
# certbot --apache -d <domaine>            # Obtention + config Apache
# certbot certonly --standalone -d <domaine>
# certbot renew                            # Renouvellement de tous les certificats
# certbot renew --dry-run                  # Simulation de renouvellement
# certbot certificates                     # Liste des certificats gérés
```

---

## 11. Bases de données

**MariaDB / MySQL** — Système de gestion de base de données relationnelle. (Module 7)

```bash
$ mariadb -u <utilisateur> -p              # Connexion interactive
$ mariadb -u <utilisateur> -p <base> < dump.sql  # Import
$ mysqldump -u <utilisateur> -p <base> > dump.sql
$ mysqldump -u <utilisateur> -p --all-databases > all.sql
# mariadb-secure-installation              # Sécurisation post-installation
```

**PostgreSQL** — Système de base de données relationnelle avancé. (Module 7)

```bash
$ sudo -u postgres psql                    # Connexion en tant que superuser
$ psql -h <hôte> -U <utilisateur> -d <base>
$ pg_dump <base> > dump.sql
$ pg_dump -Fc <base> > dump.custom         # Format custom (compressé)
$ pg_restore -d <base> dump.custom
$ pg_lsclusters                            # Instances PostgreSQL installées
# pg_ctlcluster <version> main reload
```

---

## 12. DNS et DHCP

**BIND9 (named)** — Serveur DNS faisant autorité et résolveur. (Module 8)

```bash
# named-checkconf                          # Validation de la configuration
# named-checkzone <domaine> <fichier_zone> # Validation d'un fichier de zone
# rndc reload                              # Rechargement des zones
# rndc flush                               # Purge du cache
# rndc status                              # État du serveur
```

**ISC Kea** — Serveur DHCP nouvelle génération. (Module 8)

```bash
# keactrl start|stop|status
# kea-dhcp4 -t /etc/kea/kea-dhcp4.conf    # Test de configuration DHCPv4
# kea-dhcp6 -t /etc/kea/kea-dhcp6.conf    # Test de configuration DHCPv6
```

---

## 13. Serveur mail

**Postfix** — Agent de transfert de courrier (MTA). (Module 8)

```bash
# postconf                                 # Afficher la configuration active
# postconf -n                              # Paramètres modifiés uniquement
# postconf -e "parametre=valeur"           # Modifier un paramètre
# postqueue -p                             # Afficher la file d'attente
# postqueue -f                             # Forcer la remise
# postsuper -d ALL                         # Vider la file d'attente
```

**Dovecot** — Serveur IMAP/POP3. (Module 8)

```bash
# doveadm mailbox list -u <utilisateur>
# doveadm quota get -u <utilisateur>
# doveadm search -u <utilisateur> mailbox INBOX
# doveconf -n                              # Configuration active
```

---

## 14. Sauvegarde et restauration

**rsync** — Synchronisation incrémentale de fichiers (voir aussi section 8). (Module 8)

```bash
$ rsync -avz --delete /var/www/ /backup/www/
$ rsync -avz -e "ssh -p 2222" /data/ <user>@<hôte>:/backup/
```

**borgbackup (borg)** — Sauvegarde dédupliquée et chiffrée. (Module 8)

```bash
$ borg init --encryption=repokey <dépôt>
$ borg create <dépôt>::{hostname}-{now:%Y-%m-%d} /etc /home /var
$ borg list <dépôt>                        # Lister les archives
$ borg extract <dépôt>::<archive>          # Restauration
$ borg prune --keep-daily=7 --keep-weekly=4 --keep-monthly=6 <dépôt>
$ borg info <dépôt>                        # Statistiques du dépôt
$ borg check <dépôt>                       # Vérification d'intégrité
```

**restic** — Sauvegarde rapide, chiffrée et compatible multi-backends. (Module 8)

```bash
$ restic -r <dépôt> init
$ restic -r <dépôt> backup /etc /home /var
$ restic -r <dépôt> snapshots
$ restic -r <dépôt> restore <snapshot> --target /restore
$ restic -r <dépôt> forget --keep-last 10 --prune
$ restic -r <dépôt> check
```

---

## 15. Haute disponibilité et load balancing

**Pacemaker / Corosync (pcs / crm)** — Clustering et gestion de ressources haute disponibilité. (Module 8)

```bash
# pcs cluster setup <nom> <nœud1> <nœud2>
# pcs cluster start --all
# pcs status                               # État du cluster
# pcs resource create <nom> <type> <params>
# pcs resource move <nom> <nœud>
# pcs constraint colocation add <res1> with <res2>
```

**HAProxy** — Répartiteur de charge et proxy TCP/HTTP. (Module 8)

```bash
# haproxy -c -f /etc/haproxy/haproxy.cfg   # Validation de la config
# haproxy -db -f /etc/haproxy/haproxy.cfg   # Lancement en mode debug
$ echo "show stat" | socat stdio /var/run/haproxy/admin.sock
$ echo "show servers state" | socat stdio /var/run/haproxy/admin.sock
```

---

## 16. Virtualisation

**virsh** — Interface CLI de libvirt pour la gestion des machines virtuelles KVM. (Module 9)

```bash
$ virsh list --all                         # Toutes les VM
$ virsh start|shutdown|reboot|destroy <vm>
$ virsh suspend|resume <vm>
$ virsh console <vm>
$ virsh dominfo <vm>
$ virsh snapshot-create-as <vm> <nom>
$ virsh snapshot-list <vm>
$ virsh snapshot-revert <vm> <nom>
# virsh migrate --live <vm> qemu+ssh://<hôte>/system
$ virsh net-list --all                     # Réseaux virtuels
$ virsh pool-list --all                    # Pools de stockage
```

**virt-install** — Création de machines virtuelles en ligne de commande. (Module 9)

```bash
# virt-install \
    --name <vm> \
    --ram 2048 --vcpus 2 \
    --disk path=/var/lib/libvirt/images/<vm>.qcow2,size=20 \
    --cdrom /path/to/debian.iso \
    --os-variant debian12 \
    --network bridge=br0
```

**qemu-img** — Gestion des images disque virtuelles. (Module 9)

```bash
$ qemu-img create -f qcow2 <fichier>.qcow2 20G
$ qemu-img info <fichier>.qcow2
$ qemu-img resize <fichier>.qcow2 +10G
$ qemu-img convert -f raw -O qcow2 <source> <destination>
```

**Vagrant** — Gestion d'environnements de développement reproductibles. (Module 9)

```bash
$ vagrant init <box>
$ vagrant up
$ vagrant ssh
$ vagrant halt
$ vagrant destroy
$ vagrant status
$ vagrant box list
$ vagrant snapshot save <nom>
$ vagrant snapshot restore <nom>
```

---

## 17. Conteneurs — Docker

**docker** — Plateforme de conteneurisation applicative. (Module 10)

```bash
# Images
$ docker build -t <image>:<tag> .
$ docker build -t <image>:<tag> -f <Dockerfile> .
$ docker image ls
$ docker image prune                       # Nettoyer les images inutilisées
$ docker pull <image>:<tag>
$ docker push <image>:<tag>
$ docker tag <source> <destination>
$ docker image inspect <image>

# Conteneurs
$ docker run -d --name <nom> -p <hôte>:<ct> <image>
$ docker run -it --rm <image> /bin/bash
$ docker run -v <volume>:<chemin> <image>
$ docker run --env-file .env <image>
$ docker ps                                # Conteneurs actifs
$ docker ps -a                             # Tous les conteneurs
$ docker stop|start|restart <conteneur>
$ docker rm <conteneur>
$ docker rm -f <conteneur>                 # Suppression forcée

# Inspection et débogage
$ docker logs <conteneur>
$ docker logs -f --tail 100 <conteneur>
$ docker exec -it <conteneur> /bin/bash
$ docker inspect <conteneur>
$ docker stats                             # Ressources en temps réel
$ docker top <conteneur>                   # Processus dans un conteneur

# Volumes et réseaux
$ docker volume ls
$ docker volume create <nom>
$ docker volume inspect <nom>
$ docker network ls
$ docker network create <nom>
$ docker network inspect <nom>

# Système
$ docker system df                         # Utilisation de l'espace
$ docker system prune -a                   # Nettoyage complet
```

**docker compose** — Orchestration multi-conteneurs locale. (Module 10)

```bash
$ docker compose up -d
$ docker compose down
$ docker compose down -v                   # Supprime aussi les volumes
$ docker compose ps
$ docker compose logs -f <service>
$ docker compose exec <service> /bin/bash
$ docker compose build
$ docker compose pull
$ docker compose config                    # Valider et afficher la config
```

---

## 18. Conteneurs — Podman et alternatives

**podman** — Moteur de conteneurs sans démon, compatible Docker. (Module 10)

```bash
$ podman run -d --name <nom> -p <hôte>:<ct> <image>
$ podman ps -a
$ podman build -t <image> .
$ podman pod create --name <pod>
$ podman pod ps

# Intégration systemd : préférer désormais les fichiers Quadlet (déclaratifs)
# au lieu de `podman generate systemd` (déprécié, plus de nouvelles fonctionnalités).
# Les Quadlet vivent dans /etc/containers/systemd/ (système) ou
# ~/.config/containers/systemd/ (utilisateur, mode rootless) et sont convertis
# en unités systemd au boot par /usr/lib/systemd/system-generators/podman-system-generator.
$ ls /etc/containers/systemd/             # *.container, *.network, *.volume, *.kube
$ systemctl daemon-reload                  # Régénère les unités après modification d'un Quadlet
```

**buildah** — Construction d'images OCI sans Dockerfile. (Module 10)

```bash
$ buildah from debian:trixie-slim
$ buildah run <conteneur> -- apt-get update
$ buildah copy <conteneur> <source> <dest>
$ buildah commit <conteneur> <image>
$ buildah push <image> docker://<registry>/<image>
```

**skopeo** — Inspection et copie d'images entre registries. (Module 10)

```bash
$ skopeo inspect docker://<registry>/<image>:<tag>
$ skopeo copy docker://<source> docker://<destination>
$ skopeo list-tags docker://<registry>/<image>
```

**Incus (LXC/LXD)** — Conteneurs système. (Module 10)

```bash
$ incus launch images:debian/12 <nom>
$ incus list
$ incus exec <nom> -- /bin/bash
$ incus stop|start|restart <nom>
$ incus snapshot create <nom> <snap>
$ incus snapshot restore <nom> <snap>
$ incus file push <fichier> <nom>/<chemin>
```

**trivy / grype** — Scanning de vulnérabilités des images conteneur, des dépôts Git, des manifestes IaC et des clusters Kubernetes. Trivy (Aqua Security) couvre un périmètre plus large que grype (Anchore), incluant les misconfigurations IaC et les secrets en clair. (Modules 10, 14, 16)

```bash
# Trivy — image conteneur
$ trivy image <image>:<tag>
$ trivy image --severity HIGH,CRITICAL <image>
$ trivy image --ignore-unfixed <image>     # Uniquement les CVE corrigées
$ trivy image --format sarif -o report.sarif <image>
$ trivy image --format cyclonedx -o sbom.json <image>   # Génération de SBOM

# Trivy — système de fichiers et dépôt Git
$ trivy fs .                               # Code source / projet local
$ trivy repo https://github.com/<org>/<repo>
$ trivy rootfs /                           # Scan du système hôte

# Trivy — Infrastructure as Code (Terraform, K8s manifests, Dockerfile)
$ trivy config .                           # Détecte les misconfigurations
$ trivy config --severity HIGH terraform/

# Trivy — Kubernetes
$ trivy k8s --report summary cluster       # Tour d'horizon du cluster
$ trivy k8s --report all -n production
$ trivy k8s --include-namespaces <ns>

# Trivy — secrets en clair (clés API, tokens, mots de passe)
$ trivy fs --scanners secret .

# Grype (alternative) — image conteneur
$ grype <image>:<tag>
$ grype <image> --only-fixed               # Vulnérabilités avec correctif
$ grype sbom:./sbom.spdx.json              # Scan d'un SBOM existant
$ grype dir:.                              # Scan de répertoire
```

---

## 19. Kubernetes — kubectl

**kubectl** est l'outil central pour interagir avec un cluster Kubernetes. Les commandes sont ici regroupées par famille d'opérations. (Modules 11, 12)

```bash
# Inspection des ressources
$ kubectl get <type>                       # pods, svc, deploy, nodes, ns, pv, pvc...
$ kubectl get <type> -o wide               # Colonnes supplémentaires
$ kubectl get <type> -o yaml               # Sortie YAML complète
$ kubectl get all -n <namespace>
$ kubectl describe <type> <nom>
$ kubectl get events --sort-by=.metadata.creationTimestamp

# Création et modification
$ kubectl apply -f <fichier.yaml>
$ kubectl apply -k <répertoire>            # Via Kustomize
$ kubectl create namespace <nom>
$ kubectl edit <type> <nom>
$ kubectl patch <type> <nom> -p '<json>'
$ kubectl scale deployment <nom> --replicas=<n>
$ kubectl set image deployment/<nom> <conteneur>=<image>:<tag>

# Suppression
$ kubectl delete -f <fichier.yaml>
$ kubectl delete <type> <nom>
$ kubectl delete <type> --all -n <namespace>

# Débogage
$ kubectl logs <pod>
$ kubectl logs -f <pod> -c <conteneur>
$ kubectl logs --previous <pod>            # Logs du conteneur précédent (crash)
$ kubectl exec -it <pod> -- /bin/sh
$ kubectl debug <pod> --image=busybox --target=<conteneur>   # Conteneur éphémère dans un pod
$ kubectl debug -it node/<nœud> --image=ubuntu               # Pod privilégié avec rootfs du nœud
                                            # monté dans /host (debug d'un nœud sans SSH,
                                            # utile en CKA/CKS et clusters managés)
$ kubectl port-forward <pod> <local>:<distant>
$ kubectl port-forward svc/<service> <local>:<distant>

# Gestion des nœuds
$ kubectl drain <nœud> --ignore-daemonsets --delete-emptydir-data
$ kubectl cordon <nœud>
$ kubectl uncordon <nœud>
$ kubectl taint nodes <nœud> <clé>=<valeur>:<effet>

# Contexte et configuration
$ kubectl config get-contexts
$ kubectl config use-context <contexte>
$ kubectl config set-context --current --namespace=<ns>

# Ressources et métriques
$ kubectl top nodes
$ kubectl top pods -n <namespace>
$ kubectl api-resources                    # Types de ressources disponibles

# RBAC
$ kubectl auth can-i <verbe> <ressource>
$ kubectl auth can-i --list
```

**Outils de productivité kubectl** — Compléments essentiels au quotidien. (Modules 11, 12)

```bash
# k9s — TUI de navigation/diagnostic dans le cluster
$ k9s                                      # Interface plein écran (q pour quitter)
$ k9s -n <namespace>                       # Démarrer dans un namespace
# Touches utiles : :pods, :svc, :deploy pour basculer entre vues,
# l (logs), d (describe), Ctrl+D (delete), s (shell)

# stern — Suivi multi-pods des logs (mieux que kubectl logs --prefix)
$ stern <regex-pod>                        # Logs de tous les pods correspondants
$ stern -l app=nginx                       # Sélecteur de labels
$ stern -n <ns> --since 10m <pattern>      # Filtrage temporel

# kubectx / kubens — Bascule rapide entre contextes / namespaces
$ kubectx                                  # Lister les contextes
$ kubectx <contexte>                       # Basculer
$ kubens                                   # Lister les namespaces
$ kubens <namespace>                       # Basculer

# krew — Gestionnaire de plugins kubectl
$ kubectl krew install <plugin>            # Installer un plugin
$ kubectl krew list                        # Plugins installés
$ kubectl krew search                      # Catalogue
# Plugins courants : tree, neat, who-can, resource-capacity, ctx, ns
```

---

## 20. Kubernetes — Installation et administration de cluster

**kubeadm** — Outil d'amorçage et de gestion du cycle de vie des clusters. (Module 11)

```bash
# kubeadm init --pod-network-cidr=10.244.0.0/16
# kubeadm join <ip>:<port> --token <token> --discovery-token-ca-cert-hash <hash>
# kubeadm token create --print-join-command
# kubeadm upgrade plan
# kubeadm upgrade apply <version>
# kubeadm reset                            # Nettoyage complet d'un nœud
# kubeadm certs check-expiration           # Vérifier l'expiration des certificats
# kubeadm certs renew all                  # Renouveler tous les certificats
```

**crictl** — Client CLI pour le runtime CRI (containerd, CRI-O), installé sur les nœuds Kubernetes. À utiliser en troubleshooting quand kubectl ne suffit pas (debug du runtime, conteneurs hors pods). Les commandes ressemblent à `docker` mais ciblent les conteneurs CRI directement. (Modules 11, 12)

```bash
# crictl ps                                # Conteneurs en cours
# crictl ps -a                             # Tous les conteneurs (y compris arrêtés)
# crictl pods                              # Pods gérés par le runtime
# crictl images                            # Images locales
# crictl logs <container-id>               # Logs d'un conteneur
# crictl logs -f <container-id>            # Suivi temps réel
# crictl exec -it <container-id> /bin/sh   # Shell dans un conteneur
# crictl inspect <container-id>            # Détails JSON
# crictl pull <image>                      # Pull d'image (utile pour tester l'accès registry)
# crictl rmi --prune                       # Nettoyer les images inutilisées
# crictl rm $(crictl ps -a -q --state exited)  # Nettoyer les conteneurs arrêtés
# crictl info                              # État du runtime CRI
# crictl version                           # Version de crictl et du runtime
```

**etcdctl / etcdutl** — Administration du magasin de données etcd. `etcdctl` est le client réseau (lecture, écriture, monitoring), `etcdutl` opère directement sur les fichiers et est désormais l'outil officiel pour la restauration de snapshots. (Module 12)

```bash
# Opérations en ligne (etcdctl, via le réseau)
$ etcdctl member list
$ etcdctl endpoint health
$ etcdctl endpoint status --write-out=table
$ etcdctl snapshot save /backup/etcd-snapshot.db

# Restauration hors ligne (etcdutl, opère sur les fichiers)
# etcdctl snapshot restore est déprécié depuis etcd 3.5 et supprimé depuis
# etcd 3.6 (mai 2025). Idem pour `etcdctl snapshot status` → `etcdutl snapshot status`.
$ etcdutl snapshot restore /backup/etcd-snapshot.db --data-dir=/var/lib/etcd-restore
```

---

## 21. Kubernetes — Écosystème

**Helm** — Gestionnaire de paquets pour Kubernetes. **Helm 4** est sorti le 12 novembre 2025 (10 ans du projet) et apporte le **Server-Side Apply** comme changement majeur (les ressources sont créées/patchées par l'API server K8s, pas par un three-way merge côté client) — **SSA est activé uniquement pour les nouvelles installations** ; les releases existantes conservent le three-way merge après l'upgrade. La CLI reste compatible avec Helm 3, qui passe en EOL à l'automne 2026 (corrections de sécurité jusqu'au 11 novembre 2026). (Module 12)

```bash
$ helm repo add <nom> <url>
$ helm repo update
$ helm search repo <terme>
$ helm install <release> <chart> [-f values.yaml] [-n <namespace>]
$ helm upgrade <release> <chart> [-f values.yaml]
$ helm rollback <release> <revision>
$ helm list -n <namespace>
$ helm uninstall <release>
$ helm template <chart> [-f values.yaml]   # Rendu local sans installation
$ helm show values <chart>                 # Afficher les valeurs par défaut
$ helm version                             # Vérifier le numéro de version installé
```

**Velero** — Sauvegarde et restauration de clusters Kubernetes. Supporte les snapshots de volumes via les CSI drivers et les sauvegardes au niveau fichier via **Kopia** (recommandé depuis Velero 1.12+) ou **Restic** (legacy). (Module 19)

```bash
# Sauvegardes
$ velero backup create <nom> --include-namespaces <ns>
$ velero backup create <nom> --selector app=<label>
$ velero backup create <nom> --default-volumes-to-fs-backup    # Active Kopia/Restic
$ velero backup describe <nom>
$ velero backup logs <nom>
$ velero backup get
$ velero backup delete <nom>

# Restaurations
$ velero restore create --from-backup <nom>
$ velero restore create --from-backup <nom> --include-namespaces <ns>
$ velero restore create --from-backup <nom> --existing-resource-policy update
$ velero restore describe <nom>

# Sauvegardes planifiées
$ velero schedule create <nom> --schedule="0 2 * * *"
$ velero schedule create <nom> --schedule="@daily" --ttl 168h0m0s
$ velero schedule get
$ velero schedule pause|unpause <nom>

# Configuration
$ velero backup-location get
$ velero snapshot-location get
$ velero get plugins
```

---

## 22. Infrastructure as Code

**Ansible** — Automatisation de la configuration et du déploiement. (Module 13)

```bash
$ ansible-inventory --list -i <inventaire>
$ ansible <groupe> -m ping -i <inventaire>
$ ansible <groupe> -m shell -a "<commande>"
$ ansible-playbook <playbook.yaml> -i <inventaire>
$ ansible-playbook <playbook.yaml> --check --diff
$ ansible-playbook <playbook.yaml> --limit <hôte>
$ ansible-playbook <playbook.yaml> --tags <tag>
$ ansible-galaxy install <rôle>
$ ansible-galaxy collection install <collection>
$ ansible-vault encrypt <fichier>
$ ansible-vault decrypt <fichier>
$ ansible-vault edit <fichier>
$ ansible-vault create <fichier>
```

**Terraform / OpenTofu** — Provisionnement d'infrastructure déclaratif. Depuis le passage de Terraform sous licence BSL (août 2023), **OpenTofu** est l'alternative open source (MPL 2.0) maintenue par la Linux Foundation, drop-in replacement de Terraform 1.5.x. Toute commande ci-dessous fonctionne avec `tofu` à la place de `terraform`. (Module 13)

```bash
$ terraform init                           # ou : tofu init
$ terraform plan
$ terraform plan -out=plan.tfplan
$ terraform apply [plan.tfplan]
$ terraform destroy
$ terraform state list
$ terraform state show <ressource>
$ terraform import <ressource> <id>
$ terraform output
$ terraform fmt
$ terraform validate
$ terraform workspace list
$ terraform workspace new <nom>
$ terraform workspace select <nom>

# Spécificité OpenTofu : chiffrement de l'état côté client (AES-GCM, KMS cloud)
# Configuration via le bloc `encryption {}` dans le bloc terraform{}.
```

---

## 23. CI/CD et GitOps

**ArgoCD** — Déploiement continu GitOps pour Kubernetes. (Module 14)

```bash
# Authentification
$ argocd login <serveur>
$ argocd account get-user-info
$ argocd logout <serveur>

# Cycle de vie d'une application
$ argocd app create <nom> --repo <url> --path <chemin> --dest-server <cluster>
$ argocd app list
$ argocd app get <nom>
$ argocd app sync <nom>
$ argocd app sync <nom> --prune              # Supprime aussi les ressources hors Git
$ argocd app diff <nom>                      # Écart entre Git et le cluster
$ argocd app history <nom>
$ argocd app rollback <nom> <revision>
$ argocd app delete <nom>
$ argocd app set <nom> --revision <ref>      # Cibler une branche ou un tag

# Dépôts et projets
$ argocd repo add <url>
$ argocd repo list
$ argocd proj create <nom>
$ argocd proj list

# Diagnostic
$ argocd app wait <nom> --health             # Attendre que l'app soit Healthy
$ argocd app manifests <nom>                 # Manifestes générés (rendu)
```

**Flux** — Opérateur GitOps pour Kubernetes. (Module 14)

```bash
$ flux bootstrap github --owner=<org> --repository=<repo> --path=<chemin>
$ flux get kustomizations
$ flux get helmreleases
$ flux reconcile kustomization <nom>
$ flux reconcile source git <nom>
$ flux suspend|resume kustomization <nom>
$ flux logs
```

**Tekton (tkn)** — Framework de pipelines CI/CD natif Kubernetes. (Module 14)

```bash
# Pipelines
$ tkn pipeline list
$ tkn pipeline start <nom>
$ tkn pipeline start <nom> -p key=value -w name=ws,claimName=pvc

# Exécutions
$ tkn pipelinerun list
$ tkn pipelinerun logs <nom> -f              # Suivi en temps réel
$ tkn pipelinerun cancel <nom>               # Annuler une exécution en cours
$ tkn pipelinerun describe <nom>
$ tkn pipelinerun delete --all --keep 5      # Nettoyer en gardant les 5 dernières

# Tasks
$ tkn task list
$ tkn task start <nom>
$ tkn taskrun list
$ tkn taskrun logs <nom>

# Tekton Hub (catalogue)
$ tkn hub search <terme>
$ tkn hub install task <nom>
```

---

## 24. Observabilité

**Prometheus (promtool)** — Validation des configurations Prometheus. (Module 15)

```bash
$ promtool check config /etc/prometheus/prometheus.yml
$ promtool check rules /etc/prometheus/rules/*.yml
$ promtool tsdb analyze /var/lib/prometheus/
```

**Grafana / Loki** — L'administration se fait principalement via l'interface web et les APIs REST. L'outil `logcli` permet d'interroger Loki en ligne de commande. (Module 15)

```bash
$ logcli query '{job="varlogs"}'
$ logcli query '{namespace="production"} |= "error"' --limit=50
```

**Grafana Alloy** — Collecteur unifié (logs vers Loki, métriques vers Prometheus, traces vers Tempo) basé sur l'Alloy syntax (anciennement « River »). Successeur de Promtail (EOL le 2 mars 2026). (Module 15)

```bash
# alloy run /etc/alloy/config.alloy        # Lancement (en général via systemd)
# alloy fmt /etc/alloy/config.alloy        # Formater la config (Alloy syntax)
# alloy convert --source-format=promtail \
#     --output=/etc/alloy/config.alloy \
#     /etc/promtail/config.yaml             # Migration depuis Promtail
$ curl http://localhost:12345/-/healthy    # Endpoint de santé
```

---

## 25. Sécurité avancée

**AppArmor** — Contrôle d'accès obligatoire basé sur les profils. (Module 16)

```bash
# aa-status                                # État de tous les profils
# aa-enforce /etc/apparmor.d/<profil>
# aa-complain /etc/apparmor.d/<profil>
# aa-disable /etc/apparmor.d/<profil>
# apparmor_parser -r /etc/apparmor.d/<profil>  # Recharger un profil
```

**Vault / OpenBao** — Gestion centralisée des secrets. **OpenBao** (CLI `bao`) est le fork open source MPL 2.0 de Vault, sous gouvernance de la Linux Foundation depuis le passage de Vault sous BSL (août 2023). Drop-in replacement de Vault 1.14.x, mêmes commandes en remplaçant `vault` par `bao`. (Module 16)

```bash
$ vault operator init                      # ou : bao operator init
$ vault operator unseal
$ vault status
$ vault kv put secret/<chemin> <clé>=<valeur>
$ vault kv get secret/<chemin>
$ vault kv list secret/
$ vault token create -policy=<politique>
$ vault auth enable kubernetes             # Activer une méthode d'authentification
$ vault policy write <nom> <fichier.hcl>   # Créer une politique
$ vault audit enable file file_path=/var/log/vault-audit.log
```

**cosign** — Signature et vérification d'images conteneur (projet Sigstore, OpenSSF). Cosign 3.x (sortie octobre 2025) adopte par défaut le **Sigstore Bundle Format** (`--bundle` obligatoire) et stocke les signatures comme **OCI Image 1.1 referring artifacts**. (Module 16)

```bash
# Mode classique avec clés
$ cosign generate-key-pair
$ cosign sign --key cosign.key <image>@<digest>
$ cosign verify --key cosign.pub <image>

# Mode keyless (recommandé) — authentification OIDC + Fulcio + Rekor
# Pas de clé locale à gérer, l'identité est attestée par le journal Rekor.
$ cosign sign <image>@<digest>             # Lance le flow OIDC
$ cosign verify \
    --certificate-identity <email-ou-spiffe> \
    --certificate-oidc-issuer <issuer-url> \
    <image>

# Attestations (SBOM, SLSA provenance)
$ cosign attest --predicate sbom.spdx.json --type spdx <image>
$ cosign attest --predicate provenance.json --type slsaprovenance <image>
$ cosign verify-attestation --type spdx <image>

# Cosign 3.x — nouveau format Bundle
$ cosign sign --bundle bundle.json <image>@<digest>
$ cosign verify-blob --bundle bundle.json <fichier>
```

---

## 26. Cloud et Service Mesh

**Istio (istioctl)** — Service mesh. (Module 17)

```bash
$ istioctl install --set profile=demo
$ istioctl analyze
$ istioctl proxy-status
$ istioctl proxy-config routes <pod>
$ istioctl dashboard kiali                 # Interface de visualisation
```

**Linkerd** — Service mesh léger. (Module 17)

```bash
$ linkerd install | kubectl apply -f -
$ linkerd check
$ linkerd viz dashboard
$ linkerd viz stat deployments -n <namespace>
$ linkerd viz top deploy/<nom>
```

**CLI Cloud** — Interactions avec les providers cloud. (Module 17)

```bash
# AWS
$ aws configure
$ aws ec2 describe-instances
$ aws s3 ls
$ aws eks update-kubeconfig --name <cluster>

# Google Cloud
$ gcloud init
$ gcloud compute instances list
$ gcloud container clusters get-credentials <cluster>

# Azure
$ az login
$ az vm list
$ az aks get-credentials --resource-group <rg> --name <cluster>
```

---

## 27. eBPF et observabilité réseau (Cilium / Hubble)

**cilium** — CLI pour gérer le CNI Cilium et diagnostiquer le datapath eBPF. (Module 18)

```bash
$ cilium status                            # État global de l'agent et du datapath
$ cilium status --verbose                  # Détails par sous-système (kvstore, kube-proxy, etc.)
$ cilium config view                       # Configuration runtime de l'agent
$ cilium connectivity test                 # Test de bout en bout (~50 cas, env. 5 min)
$ cilium connectivity test --test pod-to-service
$ cilium endpoint list                     # Endpoints gérés sur le nœud courant
$ cilium identity list                     # Identités de sécurité Cilium
$ cilium bpf nat list                      # Entrées NAT eBPF
$ cilium bpf ct list global                # Table conntrack eBPF
$ cilium policy get                        # Politiques réseau actives
$ cilium hubble enable                     # Activer Hubble dans le cluster
$ cilium upgrade                           # Mise à jour gérée par la CLI
```

**hubble** — Observabilité réseau temps réel pour Cilium (flux, services, drops). (Module 18)

```bash
$ hubble status                            # État du serveur Hubble
$ hubble observe                           # Flux temps réel
$ hubble observe --follow                  # Suivi continu (Ctrl+C pour arrêter)
$ hubble observe --namespace <ns>          # Filtrer par namespace
$ hubble observe --pod <pod>               # Filtrer par pod
$ hubble observe --verdict DROPPED         # Uniquement les paquets droppés
$ hubble observe --protocol http           # Filtrer par protocole L7
$ hubble observe --type policy-verdict     # Décisions des Network Policies
$ hubble list nodes                        # Nœuds Hubble
```

**bpftool** — Outil bas niveau pour inspecter les programmes et maps eBPF chargés. (Module 18)

```bash
# bpftool prog list                        # Programmes eBPF chargés
# bpftool prog show id <id>                # Détails d'un programme
# bpftool map list                         # Maps eBPF actives
# bpftool map dump id <id>                 # Contenu d'une map
# bpftool net list                         # Programmes attachés aux interfaces (XDP, TC)
# bpftool feature                          # Capacités eBPF du noyau courant
```

**bpftrace** — Langage de tracing dynamique pour eBPF (analogue de DTrace). (Module 18)

```bash
# bpftrace -l 'tracepoint:syscalls:*'      # Lister les tracepoints disponibles
# bpftrace -e 'tracepoint:syscalls:sys_enter_open { printf("%s %s\n", comm, str(args->filename)); }'
# bpftrace -e 'tracepoint:tcp:tcp_connect { @[comm] = count(); }'
# bpftrace /usr/share/bpftrace/tools/tcpconnect.bt   # Outil prêt à l'emploi
```

---

## 28. Traitement de texte et manipulation de données

Outils fondamentaux utilisés dans de nombreux contextes tout au long de la formation.

**grep / sed / awk / jq** — Recherche, transformation et structuration de données. (Module 5)

```bash
# grep
$ grep -r "<motif>" <répertoire>           # Recherche récursive
$ grep -i "<motif>" <fichier>              # Insensible à la casse
$ grep -v "<motif>" <fichier>              # Inversion (lignes sans le motif)
$ grep -c "<motif>" <fichier>              # Comptage
$ grep -E "<regex>" <fichier>              # Expressions régulières étendues
$ grep -l "<motif>" <répertoire>/*         # Noms de fichiers uniquement

# sed
$ sed 's/ancien/nouveau/g' <fichier>       # Substitution globale
$ sed -i 's/ancien/nouveau/g' <fichier>    # Modification en place
$ sed -n '10,20p' <fichier>               # Lignes 10 à 20
$ sed '/^#/d' <fichier>                    # Supprimer les commentaires

# awk
$ awk '{print $1, $3}' <fichier>           # Colonnes 1 et 3
$ awk -F: '{print $1}' /etc/passwd         # Délimiteur personnalisé
$ awk '$3 > 1000' <fichier>               # Filtrage conditionnel
$ awk '{sum+=$1} END {print sum}' <fichier> # Somme d'une colonne

# jq
$ jq '.' <fichier.json>                    # Formatage
$ jq '.key' <fichier.json>                 # Extraction d'une clé
$ jq '.items[] | .name' <fichier.json>     # Itération dans un tableau
$ jq -r '.value' <fichier.json>            # Sortie brute (sans guillemets)
$ echo '{"a":1}' | jq '.a'                # Pipe depuis stdin
```

**sort / uniq / wc / cut / tr** — Outils complémentaires de manipulation de lignes. (Module 5)

```bash
$ sort <fichier>
$ sort -n <fichier>                        # Tri numérique
$ sort -rn <fichier>                       # Tri numérique décroissant
$ sort -t: -k3 -n /etc/passwd              # Tri par champ
$ uniq                                     # Dédoublonnage (sur entrée triée)
$ sort <fichier> | uniq -c | sort -rn      # Comptage des occurrences
$ wc -l <fichier>                          # Nombre de lignes
$ cut -d: -f1 /etc/passwd                  # Extraction de champ
$ tr '[:upper:]' '[:lower:]'               # Conversion de casse
```

---

## 29. Planification de tâches

**cron / crontab** — Planification classique de tâches récurrentes. (Module 5)

```bash
$ crontab -e                               # Éditer la crontab de l'utilisateur
$ crontab -l                               # Afficher la crontab
# crontab -u <utilisateur> -e              # Éditer la crontab d'un autre utilisateur
# cat /etc/crontab                         # Crontab système

# Format : minute heure jour_mois mois jour_semaine commande
# 0 3 * * * /usr/local/bin/backup.sh       # Tous les jours à 3h
# */15 * * * * /usr/local/bin/check.sh     # Toutes les 15 minutes
```

**Timers systemd** — Alternative moderne à cron, intégrée à systemd. (Modules 3, 5)

```bash
$ systemctl list-timers --all
$ systemctl status <timer>.timer
# systemctl enable --now <timer>.timer
# systemctl disable <timer>.timer
```

---

## Matrice de correspondance rapide

Pour retrouver les commandes par besoin courant :

| Besoin | Commandes principales |
|--------|----------------------|
| Installer un paquet | `apt install`, `dpkg -i`, `flatpak install` |
| Chercher un paquet | `apt search`, `apt-cache search`, `dpkg -l` |
| Voir les logs | `journalctl`, `docker logs`, `kubectl logs` |
| Diagnostiquer le réseau | `ip`, `ss`, `ping`, `traceroute`, `mtr`, `tcpdump`, `dig` |
| Gérer le pare-feu | `nft`, `ufw`, `fail2ban-client` |
| Superviser les processus | `ps`, `top`, `htop`, `docker stats`, `kubectl top` |
| Gérer les disques | `lsblk`, `fdisk`, `gdisk`, `mkfs`, `mount`, `df`, `du` |
| Sauvegarder | `rsync`, `borg`, `restic`, `velero`, `etcdctl snapshot` |
| Gérer des VM | `virsh`, `virt-install`, `qemu-img`, `vagrant` |
| Gérer des conteneurs | `docker`, `podman`, `buildah`, `incus` |
| Piloter Kubernetes | `kubectl`, `kubeadm`, `helm`, `kustomize` |
| Déployer l'infra as code | `ansible-playbook`, `terraform apply` |
| CI/CD et GitOps | `argocd`, `flux`, `tkn`, `gitlab-runner` |
| Sécuriser | `aa-status`, `vault`, `trivy`, `cosign`, `lynis` |
| Observer le réseau eBPF | `cilium status`, `hubble observe`, `bpftool`, `bpftrace` |
| Productivité kubectl | `k9s`, `stern`, `kubectx`, `kubens`, `kubectl krew` |

⏭️ [Options courantes et exemples](/annexes/A.2-options-exemples.md)
