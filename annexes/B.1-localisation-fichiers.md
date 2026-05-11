🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe B.1 — Localisation des fichiers importants par service

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section est un annuaire de référence : pour chaque service ou composant étudié dans la formation, elle indique l'emplacement des fichiers de configuration, de données, de logs et de travail sur un système Debian avec installation par défaut depuis les dépôts officiels.

Les chemins sont organisés par domaine technique, en suivant la progression des trois parcours de la formation.

---

## Conventions

Chaque entrée utilise les catégories suivantes.

- **Config** : fichiers de configuration modifiables par l'administrateur.
- **Données** : fichiers de données persistantes du service.
- **Logs** : fichiers ou canaux de journalisation.
- **Runtime** : fichiers de travail temporaires (PID, sockets, caches).
- **Docs** : documentation embarquée sur le système.

Lorsqu'un répertoire se termine par `.d/`, il s'agit d'un répertoire drop-in dont les fichiers sont lus automatiquement.

---

## Parcours 1 — Administration système Debian

### 1. Système de base

#### Démarrage et initialisation

```
Config    /etc/default/grub                    Options du chargeur de démarrage GRUB  
Config    /boot/grub/grub.cfg                  Configuration générée (ne pas éditer directement)  
Config    /etc/fstab                           Points de montage automatiques  
Config    /etc/crypttab                        Volumes chiffrés à déverrouiller au boot  
Config    /etc/initramfs-tools/                Configuration de l'initramfs  
Runtime   /boot/vmlinuz-*                      Noyaux installés  
Runtime   /boot/initrd.img-*                   Images initramfs correspondantes  
```

#### Identification du système

```
Config    /etc/hostname                        Nom d'hôte  
Config    /etc/hosts                           Résolution locale de noms  
Config    /etc/machine-id                      Identifiant unique de la machine  
Config    /etc/os-release                      Identification de la distribution  
Config    /etc/debian_version                  Version Debian  
```

#### Localisation et fuseau horaire

```
Config    /etc/locale.gen                      Locales à générer  
Config    /etc/default/locale                  Locale par défaut du système  
Config    /etc/timezone                        Fuseau horaire (texte)  
Données   /etc/localtime                       Fuseau horaire (lien vers /usr/share/zoneinfo/)  
Config    /etc/default/keyboard                Disposition du clavier  
Config    /etc/vconsole.conf                   Console virtuelle (clavier, police)  
```

#### Shells et environnement

```
Config    /etc/profile                         Script exécuté au login (tous les shells)  
Config    /etc/profile.d/                      Scripts drop-in au login  
Config    /etc/bash.bashrc                     Configuration Bash globale (shells interactifs)  
Config    /etc/environment                     Variables d'environnement système  
Config    /etc/shells                          Shells autorisés  
Config    ~/.bashrc                            Configuration Bash utilisateur  
Config    ~/.profile                           Script de login utilisateur  
Config    ~/.bash_aliases                      Alias utilisateur (si sourcé par .bashrc)  
Config    /etc/skel/                           Modèle pour les nouveaux répertoires personnels  
```

### 2. Utilisateurs, groupes et authentification

```
Config    /etc/passwd                          Comptes utilisateurs  
Config    /etc/shadow                          Mots de passe chiffrés et politiques  
Config    /etc/group                           Groupes  
Config    /etc/gshadow                         Mots de passe de groupes  
Config    /etc/login.defs                      Paramètres par défaut de création de compte  
Config    /etc/adduser.conf                    Configuration de la commande adduser  
Config    /etc/sudoers                         Règles sudo (éditer avec visudo)  
Config    /etc/sudoers.d/                      Drop-in sudo  
Config    /etc/pam.d/                          Modules d'authentification PAM  
Config    /etc/pam.d/common-auth               Chaîne d'authentification commune  
Config    /etc/pam.d/common-password           Politique de mot de passe  
Config    /etc/pam.d/common-session            Configuration de session  
Config    /etc/security/limits.conf            Limites de ressources par utilisateur  
Config    /etc/security/limits.d/              Drop-in de limites  
Config    /etc/nsswitch.conf                   Ordre de résolution des noms (NSS)  
Config    /etc/sssd/sssd.conf                  Configuration SSSD (intégration LDAP/AD)  
Config    /etc/ldap/ldap.conf                  Configuration client LDAP  
```

### 3. systemd

```
Config    /etc/systemd/system/                 Unités personnalisées et overrides  
Config    /etc/systemd/system/<svc>.d/         Répertoires d'override par service  
Config    /lib/systemd/system/                 Unités fournies par les paquets (ne pas modifier)  
Config    /etc/systemd/system.conf             Configuration globale de systemd (manager)  
Config    /etc/systemd/user.conf               Configuration globale des sessions utilisateur  
Config    /etc/systemd/journald.conf           Configuration de journald  
Config    /etc/systemd/journald.conf.d/        Drop-in journald  
Config    /etc/systemd/logind.conf             Configuration du gestionnaire de sessions  
Config    /etc/systemd/timesyncd.conf          Synchronisation NTP (systemd-timesyncd)  
Config    /etc/systemd/resolved.conf           Résolveur DNS (systemd-resolved)  
Config    /etc/systemd/networkd.conf           Configuration globale de networkd  
Config    /etc/systemd/network/                Fichiers de configuration réseau (.network, .netdev, .link)  
Données   /var/log/journal/                    Journaux persistants de journald  
Runtime   /run/systemd/                        État d'exécution de systemd  
```

### 4. Gestion des paquets (APT / dpkg)

```
Config    /etc/apt/sources.list                Dépôts principaux (format historique)  
Config    /etc/apt/sources.list.d/             Drop-in de dépôts (.list ou .sources)  
Config    /etc/apt/apt.conf                    Configuration globale d'APT (rarement utilisé)  
Config    /etc/apt/apt.conf.d/                 Drop-in de configuration APT  
Config    /etc/apt/preferences                 Règles de pinning  
Config    /etc/apt/preferences.d/              Drop-in de pinning  
Config    /etc/apt/keyrings/                   Clés GPG des dépôts (emplacement recommandé,  
                                                à référencer via Signed-By dans les fichiers
                                                .sources ou .list)
Config    /etc/apt/trusted.gpg.d/              Clés GPG (legacy : globalement fiables, à éviter
                                                pour les nouvelles intégrations)
Config    /etc/apt/auth.conf.d/                Identifiants pour dépôts authentifiés  
Config    /etc/dpkg/dpkg.cfg                   Configuration de dpkg  
Données   /var/lib/apt/lists/                  Index des paquets téléchargés  
Données   /var/cache/apt/archives/             Paquets .deb téléchargés  
Données   /var/lib/dpkg/info/                  Métadonnées des paquets installés  
Données   /var/lib/dpkg/status                 État de tous les paquets  
Logs      /var/log/apt/history.log             Historique des opérations APT  
Logs      /var/log/apt/term.log                Sortie terminale des opérations APT  
Logs      /var/log/dpkg.log                    Historique des opérations dpkg  
```

### 5. Réseau

#### Configuration des interfaces

```
Config    /etc/network/interfaces              Configuration réseau classique (ifupdown)  
Config    /etc/network/interfaces.d/           Drop-in de configuration réseau  
Config    /etc/NetworkManager/NetworkManager.conf  Configuration de NetworkManager  
Config    /etc/NetworkManager/conf.d/          Drop-in NetworkManager  
Config    /etc/NetworkManager/system-connections/ Profils de connexion  
Config    /etc/systemd/network/                Fichiers networkd (.network, .netdev, .link)  
Config    /etc/resolv.conf                     Résolveurs DNS (souvent lien symbolique)  
Runtime   /run/NetworkManager/                 État de NetworkManager  
Runtime   /run/systemd/resolve/                État de systemd-resolved  
```

#### DNS client

```
Config    /etc/resolv.conf                     Résolveurs DNS actifs  
Config    /etc/nsswitch.conf                   Ordre de résolution (ligne "hosts:")  
Config    /etc/host.conf                       Comportement du résolveur (obsolète)  
Config    /etc/gai.conf                        Préférences IPv4/IPv6 pour getaddrinfo  
```

#### Paramètres noyau réseau

```
Config    /etc/sysctl.conf                     Paramètres noyau (fichier historique)  
Config    /etc/sysctl.d/                       Drop-in sysctl  
Config    /proc/sys/net/                       Paramètres réseau actifs (lecture/écriture)  
```

### 6. Pare-feu et sécurité réseau

```
Config    /etc/nftables.conf                   Règles nftables persistantes  
Config    /etc/iptables/rules.v4               Règles iptables IPv4 (iptables-persistent)  
Config    /etc/iptables/rules.v6               Règles iptables IPv6  
Config    /etc/ufw/                            Configuration UFW  
Config    /etc/ufw/ufw.conf                    Activation et logging UFW  
Config    /etc/ufw/user.rules                  Règles utilisateur UFW  
Config    /etc/ufw/before.rules                Règles exécutées avant les règles utilisateur  
Config    /etc/default/ufw                     Politique par défaut UFW  
Config    /etc/fail2ban/fail2ban.conf          Configuration principale fail2ban  
Config    /etc/fail2ban/jail.conf              Jails par défaut (ne pas modifier)  
Config    /etc/fail2ban/jail.local             Overrides locaux des jails  
Config    /etc/fail2ban/jail.d/                Drop-in de jails  
Config    /etc/fail2ban/filter.d/              Filtres (expressions régulières)  
Config    /etc/fail2ban/action.d/              Actions (ban, notification)  
Données   /var/lib/fail2ban/fail2ban.sqlite3   Base de données des bans  
Logs      /var/log/fail2ban.log                Journal fail2ban  
```

### 7. SSH

```
Config    /etc/ssh/sshd_config                 Configuration du serveur SSH  
Config    /etc/ssh/sshd_config.d/              Drop-in sshd (Debian 12+)  
Config    /etc/ssh/ssh_config                  Configuration du client SSH (globale)  
Config    /etc/ssh/ssh_config.d/               Drop-in client SSH  
Config    ~/.ssh/config                        Configuration client SSH (utilisateur)  
Config    ~/.ssh/authorized_keys               Clés publiques autorisées  
Config    ~/.ssh/known_hosts                   Empreintes des serveurs connus  
Données   ~/.ssh/id_ed25519                    Clé privée utilisateur  
Données   ~/.ssh/id_ed25519.pub                Clé publique utilisateur  
Données   /etc/ssh/ssh_host_*                  Clés d'hôte du serveur  
Logs      journalctl -u ssh                    Logs du service SSH  
```

### 8. VPN

#### WireGuard

```
Config    /etc/wireguard/wg0.conf              Interface WireGuard (config + clés peers)  
Config    /etc/wireguard/privatekey             Clé privée (à protéger en 600)  
Config    /etc/wireguard/publickey              Clé publique  
```

#### OpenVPN

```
Config    /etc/openvpn/                        Répertoire principal  
Config    /etc/openvpn/server/                 Configuration serveur  
Config    /etc/openvpn/client/                 Configuration client  
Config    /etc/openvpn/server.conf             Fichier serveur (ancien emplacement)  
Données   /etc/openvpn/easy-rsa/               PKI et certificats (si easy-rsa est utilisé)  
Logs      journalctl -u openvpn@server         Logs du serveur OpenVPN  
```

### 9. Serveurs web

#### Apache

```
Config    /etc/apache2/apache2.conf            Configuration principale  
Config    /etc/apache2/ports.conf              Ports d'écoute  
Config    /etc/apache2/envvars                 Variables d'environnement  
Config    /etc/apache2/sites-available/        Virtual hosts disponibles  
Config    /etc/apache2/sites-enabled/          Virtual hosts activés (liens symboliques)  
Config    /etc/apache2/mods-available/         Modules disponibles  
Config    /etc/apache2/mods-enabled/           Modules activés (liens symboliques)  
Config    /etc/apache2/conf-available/         Fragments de configuration disponibles  
Config    /etc/apache2/conf-enabled/           Fragments activés (liens symboliques)  
Données   /var/www/html/                       DocumentRoot par défaut  
Logs      /var/log/apache2/access.log          Journal d'accès  
Logs      /var/log/apache2/error.log           Journal d'erreurs  
Runtime   /var/run/apache2/apache2.pid         Fichier PID  
```

#### Nginx

```
Config    /etc/nginx/nginx.conf                Configuration principale  
Config    /etc/nginx/sites-available/          Virtual hosts disponibles  
Config    /etc/nginx/sites-enabled/            Virtual hosts activés (liens symboliques)  
Config    /etc/nginx/conf.d/                   Drop-in de configuration  
Config    /etc/nginx/snippets/                 Fragments réutilisables  
Config    /etc/nginx/mime.types                Types MIME  
Config    /etc/nginx/fastcgi_params            Paramètres FastCGI  
Config    /etc/nginx/proxy_params              Paramètres proxy  
Données   /var/www/html/                       DocumentRoot par défaut  
Logs      /var/log/nginx/access.log            Journal d'accès  
Logs      /var/log/nginx/error.log             Journal d'erreurs  
Runtime   /var/run/nginx.pid                   Fichier PID  
```

#### Caddy

```
Config    /etc/caddy/Caddyfile                 Configuration principale  
Config    /etc/caddy/conf.d/                   Imports additionnels (si configuré)  
Données   /var/lib/caddy/.local/               Certificats TLS automatiques  
Données   /var/lib/caddy/.config/              Configuration Caddy générée  
Logs      journalctl -u caddy                  Logs du service  
```

#### Let's Encrypt (certbot)

```
Config    /etc/letsencrypt/cli.ini             Options par défaut de certbot  
Config    /etc/letsencrypt/renewal/            Configuration de renouvellement par domaine  
Données   /etc/letsencrypt/live/<domaine>/     Certificats actifs (liens symboliques)  
Données   /etc/letsencrypt/archive/<domaine>/  Historique des certificats  
Données   /etc/letsencrypt/accounts/           Comptes ACME  
```

### 10. Bases de données

#### MariaDB

```
Config    /etc/mysql/mariadb.conf.d/           Drop-in de configuration MariaDB  
Config    /etc/mysql/my.cnf                    Point d'entrée (inclut les drop-in)  
Config    /etc/mysql/mariadb.cnf               Configuration spécifique MariaDB  
Config    /etc/mysql/debian.cnf                Identifiants du compte de maintenance  
Config    ~/.my.cnf                            Configuration client par utilisateur  
Données   /var/lib/mysql/                      Bases de données  
Logs      /var/log/mysql/error.log             Journal d'erreurs  
Logs      /var/log/mysql/mysql.log             Journal général (si activé)  
Logs      /var/log/mysql/mysql-slow.log        Requêtes lentes (si activé)  
Runtime   /run/mysqld/mysqld.sock              Socket Unix  
Runtime   /run/mysqld/mysqld.pid               Fichier PID  
```

#### PostgreSQL

```
Config    /etc/postgresql/<ver>/main/postgresql.conf     Configuration principale  
Config    /etc/postgresql/<ver>/main/pg_hba.conf         Authentification des clients  
Config    /etc/postgresql/<ver>/main/pg_ident.conf       Mapping d'identités  
Config    /etc/postgresql/<ver>/main/conf.d/             Drop-in de configuration  
Config    /etc/postgresql-common/createcluster.conf      Défauts pour les nouveaux clusters  
Données   /var/lib/postgresql/<ver>/main/                Données du cluster  
Logs      /var/log/postgresql/postgresql-<ver>-main.log  Journal principal  
Runtime   /run/postgresql/                               Sockets Unix  
```

### 11. Serveurs de fichiers

#### Samba

```
Config    /etc/samba/smb.conf                  Configuration principale  
Config    /etc/samba/lmhosts                   Résolution NetBIOS  
Données   /var/lib/samba/                      Bases de données Samba (TDB)  
Données   /var/lib/samba/private/passdb.tdb    Base des mots de passe Samba  
Logs      /var/log/samba/                      Journaux (un par client et par service)  
Runtime   /run/samba/                          Fichiers PID et sockets  
```

#### NFS

```
Config    /etc/exports                         Partages NFS  
Config    /etc/default/nfs-kernel-server       Options du serveur NFS  
Config    /etc/default/nfs-common              Options du client NFS  
Config    /etc/idmapd.conf                     Mapping des identités NFSv4  
```

### 12. DNS (BIND9)

```
Config    /etc/bind/named.conf                 Configuration principale (inclusions)  
Config    /etc/bind/named.conf.options         Options globales  
Config    /etc/bind/named.conf.local           Zones locales  
Config    /etc/bind/named.conf.default-zones   Zones par défaut (ne pas modifier)  
Config    /etc/bind/db.*                       Fichiers de zones  
Config    /etc/bind/rndc.key                   Clé d'authentification rndc  
Données   /var/cache/bind/                     Cache et zones dynamiques  
Logs      journalctl -u named                  Logs du service  
Runtime   /run/named/named.pid                 Fichier PID  
```

### 13. DHCP (ISC Kea)

```
Config    /etc/kea/kea-dhcp4.conf              Configuration DHCPv4  
Config    /etc/kea/kea-dhcp6.conf              Configuration DHCPv6  
Config    /etc/kea/kea-ctrl-agent.conf         Agent de contrôle REST  
Config    /etc/kea/kea-dhcp-ddns.conf          Mise à jour DNS dynamique  
Données   /var/lib/kea/                        Bases de baux  
Logs      journalctl -u kea-dhcp4-server       Logs DHCPv4  
```

### 14. Serveur mail

#### Postfix

```
Config    /etc/postfix/main.cf                 Configuration principale  
Config    /etc/postfix/master.cf                Définition des services  
Config    /etc/postfix/transport                Table de transport  
Config    /etc/postfix/virtual                  Alias virtuels  
Config    /etc/postfix/sasl/                    Configuration SASL  
Config    /etc/aliases                          Alias système (exécuter newaliases après modif)  
Données   /var/spool/postfix/                   Files d'attente  
Données   /var/lib/postfix/                     État interne  
Logs      /var/log/mail.log                     Journal principal  
Logs      /var/log/mail.err                     Erreurs  
```

#### Dovecot

```
Config    /etc/dovecot/dovecot.conf            Configuration principale  
Config    /etc/dovecot/conf.d/                 Drop-in de configuration  
Config    /etc/dovecot/conf.d/10-auth.conf     Authentification  
Config    /etc/dovecot/conf.d/10-mail.conf     Emplacement des boîtes mail  
Config    /etc/dovecot/conf.d/10-ssl.conf      TLS  
Config    /etc/dovecot/conf.d/20-imap.conf     Paramètres IMAP  
Config    /etc/dovecot/users                   Base d'utilisateurs (si fichier plat)  
Données   /var/mail/                           Boîtes mail (format mbox)  
Données   /var/vmail/                          Boîtes mail (Maildir, si configuré)  
Logs      /var/log/mail.log                    Journal partagé avec Postfix  
```

#### Anti-spam

```
Config    /etc/rspamd/local.d/                 Overrides locaux Rspamd  
Config    /etc/rspamd/override.d/              Overrides prioritaires Rspamd  
Config    /etc/spamassassin/local.cf           Configuration locale SpamAssassin  
```

#### DKIM / SPF / DMARC

```
Config    /etc/opendkim.conf                   Configuration OpenDKIM  
Config    /etc/opendkim/                       Clés et tables  
Config    /etc/opendkim/keys/                  Clés privées DKIM  
```

### 15. Sauvegarde

```
Config    /etc/borgbackup/                     Scripts et configurations borg (si organisé)  
Config    ~/.config/restic/                    Configuration utilisateur restic  
Config    /etc/cron.d/backup                   Planification de sauvegarde (cron)  
Config    /etc/systemd/system/backup.timer     Timer systemd de sauvegarde  
Config    /etc/systemd/system/backup.service   Service associé  
```

### 16. RAID et LVM

```
Config    /etc/mdadm/mdadm.conf                Configuration RAID logiciel  
Config    /etc/lvm/lvm.conf                    Configuration LVM  
Données   /dev/md*                             Périphériques RAID  
Données   /dev/mapper/vg_*-lv_*               Volumes logiques LVM  
Runtime   /proc/mdstat                         État RAID temps réel  
```

### 17. Haute disponibilité

```
Config    /etc/corosync/corosync.conf          Configuration du bus de communication  
Config    /etc/corosync/authkey                Clé d'authentification inter-nœuds  
Config    /var/lib/pacemaker/cib/cib.xml       Base de configuration du cluster (CIB)  
Config    /etc/haproxy/haproxy.cfg             Configuration HAProxy  
Config    /etc/keepalived/keepalived.conf       Configuration Keepalived (VRRP)  
Logs      /var/log/haproxy.log                 Journal HAProxy  
Runtime   /var/run/haproxy/admin.sock          Socket d'administration HAProxy  
```

### 18. Logs et monitoring classique

```
Config    /etc/rsyslog.conf                    Configuration rsyslog principale  
Config    /etc/rsyslog.d/                      Drop-in rsyslog  
Config    /etc/logrotate.conf                  Rotation des logs  
Config    /etc/logrotate.d/                    Drop-in logrotate par service  
Données   /var/log/syslog                      Journal système principal (rsyslog)  
Données   /var/log/auth.log                    Authentification  
Données   /var/log/kern.log                    Messages du noyau  
Données   /var/log/daemon.log                  Messages des démons  
Données   /var/log/dmesg                       Messages de démarrage du noyau  
```

---

## Parcours 2 — Infrastructure et conteneurs

### 19. Virtualisation (KVM / libvirt)

```
Config    /etc/libvirt/libvirtd.conf           Configuration du démon libvirt  
Config    /etc/libvirt/qemu.conf               Configuration globale QEMU  
Config    /etc/libvirt/qemu/                   Définitions XML des VM  
Config    /etc/libvirt/qemu/networks/          Définitions des réseaux virtuels  
Config    /etc/libvirt/storage/                Définitions des pools de stockage  
Données   /var/lib/libvirt/images/             Images disque des VM (pool par défaut)  
Données   /var/lib/libvirt/qemu/snapshot/      Snapshots des VM  
Logs      /var/log/libvirt/qemu/               Logs par VM  
Runtime   /var/run/libvirt/                    Sockets et fichiers PID  
```

### 20. Vagrant

```
Config    ~/.vagrant.d/                        Configuration globale Vagrant  
Config    Vagrantfile                          Définition de l'environnement (par projet)  
Données   ~/.vagrant.d/boxes/                  Images de base (boxes)  
Données   .vagrant/                            État des machines (par projet)  
```

### 21. Docker

```
Config    /etc/docker/daemon.json              Configuration du démon Docker  
Config    ~/.docker/config.json                Identifiants de registries et préférences  
Config    Dockerfile                           Instructions de build (par projet)  
Config    compose.yaml                         Stack multi-conteneurs (par projet)  
Config    .dockerignore                        Exclusions du contexte de build  
Données   /var/lib/docker/                     Racine de stockage Docker  
Données   /var/lib/docker/volumes/             Volumes nommés  
Données   /var/lib/docker/image/               Couches d'images  
Données   /var/lib/docker/containers/          Données des conteneurs  
Données   /var/lib/docker/network/             Configuration réseau  
Logs      /var/lib/docker/containers/<id>/<id>-json.log    Logs par conteneur  
Runtime   /var/run/docker.sock                 Socket du démon Docker  
Runtime   /var/run/docker/containerd/          Runtime containerd  
```

### 22. Podman

```
Config    /etc/containers/registries.conf      Registries configurés  
Config    /etc/containers/policy.json          Politique de signature des images  
Config    /etc/containers/storage.conf         Configuration du stockage  
Config    /etc/containers/containers.conf      Comportement par défaut des conteneurs  
Config    ~/.config/containers/                Overrides utilisateur  
Données   ~/.local/share/containers/storage/   Stockage rootless (par utilisateur)  
Runtime   /run/user/<uid>/podman/              Socket rootless  

# Quadlet — intégration systemd déclarative (recommandée à la place de
# `podman generate systemd`, déprécié)
Config    /etc/containers/systemd/             Quadlet système (*.container, *.kube,
                                                *.network, *.volume, *.pod, *.image)
Config    ~/.config/containers/systemd/        Quadlet utilisateur (mode rootless)
                                                # Conversion en unités systemd au boot par
                                                # /usr/lib/systemd/system-generators/podman-system-generator
                                                # Après modification : systemctl daemon-reload
```

### 23. Incus (LXC/LXD)

```
Config    /etc/incus/                          Configuration du service  
Données   /var/lib/incus/                      Images, conteneurs, VM  
Données   /var/lib/incus/storage-pools/        Pools de stockage  
Logs      /var/log/incus/                      Journaux du démon  
Logs      /var/log/incus/<instance>/           Logs par conteneur  
Runtime   /var/lib/incus/unix.socket           Socket principal  
```

### 24. Kubernetes — Nœuds

#### kubeadm / kubelet

```
Config    /etc/kubernetes/admin.conf           Kubeconfig administrateur  
Config    /etc/kubernetes/kubelet.conf         Kubeconfig du kubelet  
Config    /etc/kubernetes/scheduler.conf       Kubeconfig du scheduler  
Config    /etc/kubernetes/controller-manager.conf  Kubeconfig du controller-manager  
Config    /var/lib/kubelet/config.yaml         Configuration du kubelet  
Config    /etc/default/kubelet                 Arguments supplémentaires kubelet  
Config    /etc/kubernetes/manifests/           Pods statiques du control plane  
Config    /etc/kubernetes/manifests/kube-apiserver.yaml  
Config    /etc/kubernetes/manifests/kube-controller-manager.yaml  
Config    /etc/kubernetes/manifests/kube-scheduler.yaml  
Config    /etc/kubernetes/manifests/etcd.yaml  
Config    /etc/kubernetes/pki/                 Certificats et clés du cluster  
Config    /etc/kubernetes/pki/ca.crt           Autorité de certification  
Config    /etc/kubernetes/pki/ca.key           Clé de l'autorité de certification  
Config    /etc/kubernetes/pki/etcd/            Certificats etcd  
Données   /var/lib/kubelet/                    État et pods du kubelet  
Données   /var/lib/kubelet/pods/               Volumes et données des pods  
Runtime   /var/run/kubernetes/                 Fichiers d'exécution  
Logs      journalctl -u kubelet                Logs du kubelet  
```

#### etcd

```
Config    /etc/kubernetes/manifests/etcd.yaml  Manifeste du pod statique etcd  
Config    /etc/kubernetes/pki/etcd/            Certificats etcd  
Données   /var/lib/etcd/                       Données du cluster etcd  
```

#### Container runtime (containerd)

```
Config    /etc/containerd/config.toml          Configuration de containerd  
Config    /etc/crictl.yaml                     Configuration de crictl  
Données   /var/lib/containerd/                 Images et conteneurs  
Runtime   /run/containerd/containerd.sock      Socket principal  
Logs      journalctl -u containerd             Logs du runtime  
```

#### Réseau (CNI)

```
Config    /etc/cni/net.d/                      Plugins CNI configurés (un .conf ou .conflist
                                                par CNI installé — premier fichier dans
                                                l'ordre lexicographique = CNI actif)
Données   /opt/cni/bin/                        Binaires des plugins CNI  
Config    /etc/calico/                         Configuration Calico (si installé)  
Config    /etc/cilium/                         Configuration Cilium (si installé)  
Config    /run/flannel/subnet.env              État de Flannel (CNI par défaut de K3s)  
```

#### Kubectl (client)

```
Config    ~/.kube/config                       Kubeconfig par défaut  
Config    $KUBECONFIG                          Variable d'environnement alternative  
```

#### Helm (client)

```
Config    ~/.config/helm/repositories.yaml     Dépôts de charts configurés (helm repo add)  
Config    ~/.config/helm/registry/config.json  Identifiants OCI registries  
Données   ~/.cache/helm/repository/            Cache des index de dépôts  
Données   ~/.cache/helm/plugins/               Plugins Helm installés  
Données   $XDG_DATA_HOME/helm/plugins/         Plugins Helm (alternative)  
Données   ./Chart.yaml                         Manifeste de chart (par projet)  
Données   ./values.yaml                        Valeurs par défaut du chart  
Données   ./templates/                         Templates Go du chart  
Données   ./charts/                            Sous-charts (dépendances vendored)  
                                                # Helm 4 (nov. 2025) : Server-Side Apply
                                                # par défaut pour les nouvelles installs.
                                                # Helm 3 EOL : 11 novembre 2026.
```

### 25. K3s

```
Config    /etc/rancher/k3s/config.yaml         Configuration du serveur K3s  
Config    /etc/rancher/k3s/registries.yaml     Registries privés  
Config    /var/lib/rancher/k3s/server/manifests/   Auto-deploy de manifestes  
Données   /var/lib/rancher/k3s/                Données du cluster  
Données   /var/lib/rancher/k3s/server/db/      Base de données intégrée (SQLite ou etcd)  
Données   /var/lib/rancher/k3s/agent/          Données de l'agent  
Logs      journalctl -u k3s                    Logs du service  
Runtime   /run/k3s/                            Fichiers d'exécution  
```

### 26. Ansible

```
Config    /etc/ansible/ansible.cfg             Configuration globale  
Config    /etc/ansible/hosts                   Inventaire par défaut  
Config    ~/.ansible.cfg                       Configuration utilisateur  
Config    ./ansible.cfg                        Configuration par projet (priorité maximale)  
Config    ./inventory/                         Inventaire par projet  
Config    ./group_vars/                        Variables par groupe  
Config    ./host_vars/                         Variables par hôte  
Config    ./roles/                             Rôles du projet  
Config    ./collections/                       Collections locales  
Données   ~/.ansible/                          Cache, plugins, collections utilisateur  
Données   ~/.ansible/collections/              Collections installées  
Données   ~/.ansible/roles/                    Rôles installés via Galaxy  
Logs      ./ansible.log                        Journal d'exécution (si log_path configuré)  
```

### 27. Terraform / OpenTofu

```
Config    *.tf                                 Fichiers de configuration HCL (par projet)  
Config    *.tfvars                             Fichiers de variables  
Config    *.auto.tfvars                        Variables chargées automatiquement  
Config    .terraformrc / terraform.rc          Configuration CLI globale (Terraform)  
Config    .tofurc / tofu.rc                    Configuration CLI globale (OpenTofu)  
Config    ~/.terraform.d/                      Plugins et configuration utilisateur (Terraform)  
Config    ~/.opentofu/                         Plugins et configuration utilisateur (OpenTofu)  
Config    backend.tf                           Configuration du backend d'état  
Données   .terraform/                          Providers et modules téléchargés (par projet)  
Données   terraform.tfstate                    État local (si backend local)  
                                                # OpenTofu utilise le même fichier
                                                # terraform.tfstate (compatible)
Données   terraform.tfstate.backup             Backup de l'état précédent  
Données   .terraform.lock.hcl                  Verrouillage des versions de providers  
                                                # OpenTofu : .terraform.lock.hcl identique
                                                # (compatible bilatéralement avec Terraform 1.5.x)
```

---

## Parcours 3 — Cloud-native et expert

### 28. CI/CD

#### GitLab Runner

```
Config    /etc/gitlab-runner/config.toml       Configuration des runners  
Données   /var/lib/gitlab-runner/              Données de travail  
Logs      journalctl -u gitlab-runner          Logs du service  
```

#### GitHub Actions (self-hosted)

```
Config    <runner-dir>/.runner                 Configuration du runner  
Config    <runner-dir>/.env                    Variables d'environnement  
Données   <runner-dir>/_work/                  Répertoire de travail des jobs  
```

### 29. GitOps

#### ArgoCD

```
Config    argocd-cm (ConfigMap)                Configuration principale  
Config    argocd-rbac-cm (ConfigMap)           Politique RBAC  
Config    argocd-secret (Secret)               Secrets (admin password, TLS)  
Config    argocd-cmd-params-cm (ConfigMap)     Paramètres en ligne de commande  
Config    ~/.config/argocd/config              Configuration CLI locale  
```

#### Flux

```
Config    clusters/<env>/flux-system/          Manifestes d'installation Flux  
Config    clusters/<env>/flux-system/gotk-components.yaml  
Config    clusters/<env>/flux-system/gotk-sync.yaml  
Config    clusters/<env>/kustomization.yaml    Point d'entrée Kustomize  
```

### 30. Observabilité

#### Prometheus

```
Config    /etc/prometheus/prometheus.yml       Configuration principale  
Config    /etc/prometheus/rules/               Fichiers de règles d'alerte  
Config    /etc/prometheus/targets/             Fichiers de découverte (file_sd)  
Config    /etc/default/prometheus              Arguments du service  
Données   /var/lib/prometheus/                 Base de données TSDB  
Logs      journalctl -u prometheus             Logs du service  
```

#### AlertManager

```
Config    /etc/prometheus/alertmanager.yml     Configuration principale  
Config    /etc/prometheus/templates/           Templates de notification  
Données   /var/lib/alertmanager/               Silences et état  
Logs      journalctl -u alertmanager           Logs du service  
```

#### Grafana

```
Config    /etc/grafana/grafana.ini             Configuration principale  
Config    /etc/grafana/provisioning/datasources/   Sources de données auto-provisionnées  
Config    /etc/grafana/provisioning/dashboards/    Dashboards auto-provisionnés  
Config    /etc/grafana/provisioning/alerting/      Règles d'alerte  
Config    /etc/grafana/ldap.toml               Configuration LDAP  
Données   /var/lib/grafana/grafana.db          Base SQLite (utilisateurs, dashboards)  
Données   /var/lib/grafana/plugins/            Plugins installés  
Logs      /var/log/grafana/grafana.log         Journal principal  
```

#### Loki

```
Config    /etc/loki/loki-config.yaml           Configuration principale  
Données   /var/lib/loki/                       Données indexées et chunks  
Logs      journalctl -u loki                   Logs du service  
```

#### Grafana Alloy / Fluent Bit / Promtail (EOL)

```
Config    /etc/alloy/config.alloy              Configuration Grafana Alloy (Alloy syntax,
                                                ex-« River » — renommé lors de la création
                                                d'Alloy, le langage reste identique)
Config    /etc/default/alloy                   Arguments du service Alloy  
Données   /var/lib/alloy/                      Cache et positions Alloy  
Logs      journalctl -u alloy                  Logs du service Alloy  

Config    /etc/fluent-bit/fluent-bit.conf      Configuration Fluent Bit  
Config    /etc/fluent-bit/parsers.conf         Parsers Fluent Bit  

Config    /etc/promtail/promtail-config.yaml   Configuration Promtail (EOL depuis le 2 mars 2026)
                                                — migrer vers Grafana Alloy
                                                (`alloy convert --source-format=promtail`)
```

#### Node Exporter

```
Config    /etc/default/prometheus-node-exporter Arguments du service  
Config    /var/lib/prometheus/node-exporter/    Répertoire textfile collector  
Logs      journalctl -u prometheus-node-exporter  
```

### 31. ELK Stack

```
Config    /etc/elasticsearch/elasticsearch.yml  Configuration Elasticsearch  
Config    /etc/elasticsearch/jvm.options        Options JVM  
Config    /etc/elasticsearch/jvm.options.d/     Drop-in JVM  
Données   /var/lib/elasticsearch/               Index et données  
Logs      /var/log/elasticsearch/               Journaux  

Config    /etc/logstash/logstash.yml            Configuration Logstash  
Config    /etc/logstash/conf.d/                 Pipelines (input/filter/output)  
Config    /etc/logstash/jvm.options             Options JVM  
Logs      /var/log/logstash/                    Journaux  

Config    /etc/kibana/kibana.yml                Configuration Kibana  
Logs      /var/log/kibana/                      Journaux  
```

### 32. Sécurité avancée

#### AppArmor

```
Config    /etc/apparmor.d/                     Profils AppArmor  
Config    /etc/apparmor.d/local/               Overrides locaux  
Config    /etc/apparmor.d/abstractions/        Fragments réutilisables  
Config    /etc/apparmor.d/tunables/            Variables globales des profils  
Config    /etc/apparmor/parser.conf            Configuration du parser  
Données   /sys/kernel/security/apparmor/       État du module noyau  
Logs      journalctl -k | grep apparmor        Messages du noyau AppArmor  
Logs      /var/log/audit/audit.log             Journal d'audit (si auditd installé)  
```

#### Audit système

```
Config    /etc/audit/auditd.conf               Configuration du démon d'audit  
Config    /etc/audit/rules.d/                  Règles d'audit  
Données   /var/log/audit/                      Journaux d'audit  
```

#### Vault

```
Config    /etc/vault.d/vault.hcl               Configuration du serveur Vault  
Config    ~/.vault-token                       Token d'authentification courant  
Données   /opt/vault/data/                     Données (backend intégré Raft)  
Logs      journalctl -u vault                  Logs du service  
```

### 33. Cloud CLI

```
Config    ~/.aws/config                        Configuration AWS (région, profil)  
Config    ~/.aws/credentials                   Identifiants AWS  
Config    ~/.config/gcloud/                    Configuration Google Cloud  
Config    ~/.config/gcloud/application_default_credentials.json  
Config    ~/.azure/                            Configuration Azure CLI  
Config    ~/.azure/config                      Paramètres par défaut Azure  
```

### 34. Service Mesh

#### Istio

```
Config    IstioOperator (CRD)                  Configuration déclarative passée à
                                                istioctl install / Helm. À noter :
                                                l'in-cluster Operator (le déploiement
                                                istio-operator) est déprécié depuis
                                                Istio 1.23 et supprimé depuis 1.24 —
                                                migrer vers Helm pour les installs
                                                gérées par opérateur.
Config    istio-system/istio (ConfigMap)        Mesh config  
Config    PeerAuthentication (CRD)              Politique mTLS  
Config    VirtualService (CRD)                  Routage du trafic — Istio recommande  
                                                désormais le Kubernetes Gateway API
                                                (HTTPRoute) pour les nouvelles
                                                installations ; VirtualService reste
                                                supporté, notamment pour fault injection
                                                et traffic mirroring.
Config    DestinationRule (CRD)                 Règles de destination  
Config    Gateway (CRD)                         Points d'entrée Istio (cohabite avec  
                                                la ressource Gateway de la Gateway API)
Config    AuthorizationPolicy (CRD)             Contrôle d'accès
```

#### Linkerd

```
Config    linkerd-config (ConfigMap)            Configuration du mesh  
Config    ServiceProfile (CRD)                  Profils de service  
Config    Server (CRD)                          Politique de trafic  
Config    ServerAuthorization (CRD)             Autorisation  
```

### 35. Stockage distribué

#### Ceph

```
Config    /etc/ceph/ceph.conf                  Configuration principale  
Config    /etc/ceph/ceph.client.admin.keyring   Clé d'authentification admin  
Données   /var/lib/ceph/                       Données OSD, MON, MDS  
Logs      /var/log/ceph/                       Journaux  
```

#### MinIO

```
Config    /etc/default/minio                   Variables d'environnement MinIO  
Config    ~/.mc/config.json                    Configuration du client mc  
Données   /var/lib/minio/                      Données objets (si local)  
Logs      journalctl -u minio                  Logs du service  
```

---

## Récapitulatif des répertoires stratégiques

Quelques répertoires méritent d'être connus par cœur tant ils sont consultés fréquemment.

| Répertoire | Contenu |
|-----------|---------|
| `/etc/` | Configuration de tous les services système |
| `/var/log/` | Journaux de tous les services (hors journald) |
| `/var/lib/` | Données persistantes des services |
| `/var/spool/` | Files d'attente (mail, impression, cron) |
| `/run/` | Fichiers d'exécution (PID, sockets), tmpfs |
| `/tmp/` | Fichiers temporaires, nettoyé au redémarrage |
| `/usr/lib/systemd/system/` | Unités systemd fournies par les paquets |
| `/etc/systemd/system/` | Unités systemd personnalisées |
| `/etc/kubernetes/` | Configuration du cluster Kubernetes |
| `/var/lib/docker/` | Racine de stockage Docker |
| `~/.kube/` | Kubeconfig de l'utilisateur |
| `~/.ssh/` | Clés SSH et configuration client |

---

## Réflexe de localisation

Face à un service inconnu ou un fichier de configuration à retrouver, les commandes suivantes permettent de localiser rapidement les fichiers concernés.

`dpkg -L <paquet>` liste tous les fichiers installés par un paquet, y compris ses fichiers de configuration. `dpkg -L nginx | grep /etc/` filtre les fichiers de configuration.

`systemctl cat <service>` affiche le fichier d'unité du service et ses overrides. L'en-tête de chaque section indique le chemin du fichier source.

`find /etc -name "*<service>*"` recherche tous les fichiers de configuration liés à un service dans `/etc`.

`strace -e openat <commande> 2>&1 | grep /etc` trace les fichiers de configuration ouverts par un programme au démarrage (approche de dernier recours pour les cas complexes).

La documentation de chaque paquet est disponible dans `/usr/share/doc/<paquet>/`, incluant souvent des exemples de configuration dans un sous-répertoire `examples/`.

⏭️ [Syntaxe et exemples annotés](/annexes/B.2-syntaxe-exemples.md)
