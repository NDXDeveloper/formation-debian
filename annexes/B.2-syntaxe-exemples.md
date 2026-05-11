🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe B.2 — Syntaxe et exemples annotés

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section présente les **formats de configuration** rencontrés dans la formation, illustrés par des exemples fonctionnels commentés ligne par ligne. L'objectif est double : comprendre la logique syntaxique de chaque format et disposer de configurations de référence directement exploitables comme point de départ.

Les exemples sont classés par famille de syntaxe, puis par service. Les pièges courants propres à chaque format sont signalés par un encadré « Attention ».

---

## 1. Fichiers tabulaires et à champs fixes

Ces formats historiques d'Unix utilisent des colonnes séparées par des espaces, des tabulations ou un caractère délimiteur fixe. Ils sont compacts mais peu tolérants aux erreurs de formatage.

### /etc/fstab — Points de montage

Chaque ligne définit un système de fichiers à monter automatiquement. Les six champs sont séparés par des espaces ou des tabulations.

```bash
# <périphérique>              <point de montage>  <type>  <options>           <dump> <pass>

# Partition racine identifiée par son UUID (préféré à /dev/sdXN)
UUID=a1b2c3d4-e5f6-7890-abcd-ef1234567890  /           ext4    errors=remount-ro   0      1

# Partition /home séparée avec options de sécurité
UUID=b2c3d4e5-f6a7-8901-bcde-f12345678901  /home       ext4    defaults,nosuid,nodev  0  2

# Partition swap
UUID=c3d4e5f6-a7b8-9012-cdef-123456789012  none        swap    sw                  0      0

# Partage NFS monté au démarrage
192.168.1.10:/export/data  /mnt/nfs  nfs4  defaults,_netdev,nofail  0  0

# Tmpfs pour /tmp (en RAM, limité à 2 Go)
tmpfs  /tmp  tmpfs  defaults,noatime,nosuid,nodev,size=2G  0  0

# Volume chiffré LUKS (référencé via /etc/crypttab)
/dev/mapper/crypt_data  /srv/data  ext4  defaults,nofail  0  2
```

Le champ **dump** vaut 0 (pas de sauvegarde dump) ou 1. Le champ **pass** contrôle l'ordre de vérification fsck au démarrage : 1 pour la racine, 2 pour les autres partitions, 0 pour désactiver la vérification.

> **Attention** — L'option `nofail` est essentielle pour les montages non critiques (NFS, volumes chiffrés, disques externes). Sans elle, un périphérique absent au démarrage bloque le boot du système en mode maintenance.

### /etc/crypttab — Volumes chiffrés

```bash
# <nom>        <périphérique>                                    <fichier clé>  <options>
crypt_data     UUID=d4e5f6a7-b8c9-0123-defa-234567890123         none           luks,discard  
crypt_backup   /dev/sdb1                                         /root/.keyfile luks  
```

### /etc/passwd et /etc/shadow

```bash
# /etc/passwd — 7 champs séparés par ':'
# login:mot_de_passe:UID:GID:commentaire:home:shell
alice:x:1001:1001:Alice Martin:/home/alice:/bin/bash  
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin  
# 'x' dans le champ mot de passe renvoie vers /etc/shadow

# /etc/shadow — 9 champs séparés par ':'
# login:hash:dernière_modif:min:max:avertissement:inactivité:expiration:réservé
alice:$y$j9T$salt$hash:19820:0:90:7:30::
# $y$ = algorithme yescrypt (défaut Debian 12+)
# 19820 = jours depuis le 1er janvier 1970
# 0 = délai minimum entre deux changements (jours)
# 90 = durée de validité du mot de passe (jours)
# 7 = avertissement avant expiration (jours)
# 30 = jours d'inactivité autorisés après expiration
```

### /etc/hosts

```bash
# Résolution locale — consultée avant le DNS si nsswitch.conf le prévoit
127.0.0.1       localhost
127.0.1.1       srv-debian01.example.com  srv-debian01

# Adresses IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes  
ff02::2         ip6-allrouters  

# Entrées manuelles (utile en l'absence de DNS interne)
192.168.1.10    db01.internal db01
192.168.1.11    web01.internal web01
```

### crontab — Planification de tâches

```bash
# Format : minute heure jour_mois mois jour_semaine commande
# Plages : 0-59   0-23  1-31      1-12 0-7 (0 et 7 = dimanche)

# Variables d'environnement (facultatives, mais recommandées)
SHELL=/bin/bash  
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin  
MAILTO=admin@example.com  

# Sauvegarde quotidienne à 3h15
15 3 * * *  /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# Nettoyage des fichiers temporaires chaque dimanche à 4h
0 4 * * 0   find /tmp -type f -mtime +7 -delete

# Vérification toutes les 5 minutes
*/5 * * * * /usr/local/bin/healthcheck.sh

# Premier jour de chaque mois à minuit
0 0 1 * *   /usr/local/bin/monthly-report.sh

# Du lundi au vendredi à 8h et 18h
0 8,18 * * 1-5  /usr/local/bin/sync.sh
```

> **Attention** — Dans les fichiers de `/etc/cron.d/`, un sixième champ avant la commande spécifie l'utilisateur d'exécution. Ce champ n'existe pas dans les crontabs utilisateur éditées via `crontab -e`.

---

## 2. Format clé-valeur simple

De nombreux fichiers de configuration Debian utilisent un format où chaque ligne contient une directive suivie de sa valeur, séparées par un espace, un signe `=` ou un autre délimiteur. Les commentaires commencent par `#`.

### /etc/ssh/sshd_config — Serveur SSH

```bash
# Réseau
Port 22                              # Port d'écoute (changer en production si souhaité)  
AddressFamily inet                   # inet = IPv4 seul, inet6 = IPv6, any = les deux  
ListenAddress 0.0.0.0                # Adresse d'écoute (0.0.0.0 = toutes les interfaces)  

# Authentification
PermitRootLogin no                   # Interdit la connexion root directe  
PubkeyAuthentication yes             # Active l'authentification par clé  
PasswordAuthentication no            # Désactive les mots de passe (clés uniquement)  
AuthenticationMethods publickey      # Méthode(s) requise(s)  
MaxAuthTries 3                       # Tentatives avant déconnexion  

# Sécurité
AllowUsers alice bob                 # Seuls ces utilisateurs peuvent se connecter  
AllowGroups sshusers                 # Alternative : filtrage par groupe  
X11Forwarding no                     # Désactivé sur les serveurs  
AllowTcpForwarding yes               # Tunneling autorisé  
PermitEmptyPasswords no              # Jamais de mot de passe vide  
ClientAliveInterval 300              # Keepalive toutes les 300 secondes  
ClientAliveCountMax 2                # Déconnexion après 2 keepalives sans réponse  

# Logging
LogLevel VERBOSE                     # Niveau de détail dans les logs  
SyslogFacility AUTH                  # Facility syslog utilisée  

# Bannière
Banner /etc/ssh/banner.txt           # Message affiché avant l'authentification

# Subsystems
Subsystem sftp /usr/lib/openssh/sftp-server

# Bloc conditionnel par groupe
Match Group sftponly
    ForceCommand internal-sftp       # Restreint au SFTP
    ChrootDirectory /home/%u         # Cloisonnement dans le home
    AllowTcpForwarding no
    X11Forwarding no
```

> **Attention** — L'ordre compte dans `sshd_config` : les blocs `Match` doivent être placés en fin de fichier. Toutes les directives qui suivent un `Match` s'appliquent au contexte de ce bloc jusqu'au prochain `Match` ou la fin du fichier.

### /etc/sysctl.d/99-custom.conf — Paramètres noyau

```bash
# Sécurité réseau
net.ipv4.conf.all.rp_filter = 1          # Filtrage par chemin inverse (anti-spoofing)  
net.ipv4.conf.default.rp_filter = 1  
net.ipv4.icmp_echo_ignore_broadcasts = 1 # Ignore les pings broadcast  
net.ipv4.conf.all.accept_redirects = 0   # Refuse les redirections ICMP  
net.ipv4.conf.all.send_redirects = 0  
net.ipv4.conf.all.accept_source_route = 0  

# Forwarding (activer pour un routeur ou un hôte Docker/K8s)
net.ipv4.ip_forward = 1  
net.ipv6.conf.all.forwarding = 1  

# Performances réseau
net.core.somaxconn = 65535               # Taille max de la file d'écoute  
net.ipv4.tcp_max_syn_backlog = 65535  
net.core.rmem_max = 16777216             # Buffer de réception max  
net.core.wmem_max = 16777216             # Buffer d'envoi max  

# Performances système
vm.swappiness = 10                       # Réduit l'utilisation du swap  
vm.overcommit_memory = 1                 # Utile pour Redis et certaines bases de données  
fs.file-max = 2097152                    # Nombre max de descripteurs de fichiers  
fs.inotify.max_user_watches = 524288     # Utile pour les outils de build et IDE  

# Kubernetes : prérequis
net.bridge.bridge-nf-call-iptables = 1   # Requis par la plupart des CNI  
net.bridge.bridge-nf-call-ip6tables = 1  
```

### /etc/default/grub — Chargeur de démarrage

```bash
GRUB_DEFAULT=0                           # Entrée par défaut (0 = première)  
GRUB_TIMEOUT=5                           # Délai avant démarrage automatique (secondes)  
GRUB_DISTRIBUTOR=`lsb_release -i -s 2>/dev/null || echo Debian`  
GRUB_CMDLINE_LINUX_DEFAULT="quiet"       # Paramètres noyau pour le boot normal  
GRUB_CMDLINE_LINUX=""                    # Paramètres noyau pour tous les modes  
# Exemples de paramètres courants :
# GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"
# GRUB_CMDLINE_LINUX="console=ttyS0,115200n8"  # Console série (serveurs headless)
GRUB_TERMINAL=console                    # Type de terminal
# GRUB_GFXMODE=1920x1080                 # Résolution du framebuffer
```

> **Attention** — Après toute modification de `/etc/default/grub`, il est impératif d'exécuter `update-grub` pour régénérer `/boot/grub/grub.cfg`. Le fichier `grub.cfg` ne doit jamais être édité directement.

---

## 3. Format à blocs et directives

Ces formats utilisent des blocs hiérarchiques délimités par des accolades `{}` ou des balises ouvrantes/fermantes. Chaque directive se termine par un point-virgule ou se situe sur sa propre ligne.

### Nginx — Serveur web et reverse proxy

```nginx
# /etc/nginx/nginx.conf — Configuration principale

# Contexte global : s'applique à l'ensemble du serveur
user www-data;                           # Utilisateur du processus worker  
worker_processes auto;                   # Nombre de workers (auto = un par cœur CPU)  
pid /run/nginx.pid;                      # Emplacement du fichier PID  
error_log /var/log/nginx/error.log warn; # Journal d'erreurs et niveau minimum  

# Chargement dynamique des modules
include /etc/nginx/modules-enabled/*.conf;

# Bloc events : paramètres de connexion
events {
    worker_connections 1024;             # Connexions simultanées par worker
    multi_accept on;                     # Accepter plusieurs connexions à la fois
    use epoll;                           # Méthode d'I/O (epoll = Linux optimisé)
}

# Bloc http : configuration HTTP globale
http {
    # Types MIME et paramètres de base
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Format de log personnalisé
    log_format main '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '$request_time';

    access_log /var/log/nginx/access.log main;

    # Performances
    sendfile on;                         # Transfert direct fichier → socket
    tcp_nopush on;                       # Optimise les paquets TCP
    tcp_nodelay on;                      # Désactive l'algorithme de Nagle
    keepalive_timeout 65;                # Durée des connexions persistantes
    types_hash_max_size 2048;
    server_tokens off;                   # Masque la version de Nginx

    # Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;                # Ne pas compresser les petites réponses
    gzip_types text/plain text/css application/json application/javascript
               text/xml application/xml text/javascript image/svg+xml;

    # Inclusion des configurations de sites
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

```nginx
# /etc/nginx/sites-available/app.example.com — Virtual host avec reverse proxy

# Redirection HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;                      # IPv6
    server_name app.example.com;
    return 301 https://$host$request_uri;
}

# Serveur HTTPS principal
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;                            # Nginx 1.25.1+ : directive http2 dédiée
                                          # (l'ancien `listen ... http2` est déprécié)
    server_name app.example.com;

    # Certificats TLS (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/app.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app.example.com/privkey.pem;

    # Paramètres TLS sécurisés
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;

    # En-têtes de sécurité
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    # Fichiers statiques servis directement
    location /static/ {
        alias /var/www/app/static/;
        expires 30d;                     # Cache navigateur de 30 jours
        access_log off;
    }

    # Reverse proxy vers l'application backend
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        # Buffers
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # Page d'erreur personnalisée
    error_page 502 503 504 /maintenance.html;
    location = /maintenance.html {
        root /var/www/errors;
        internal;                        # Accessible uniquement via error_page
    }
}
```

> **Attention** — Chaque directive Nginx se termine par un point-virgule `;`. Son oubli provoque une erreur de syntaxe qui empêche le rechargement. Toujours valider avec `nginx -t` avant `systemctl reload nginx`.

### Apache — Virtual host

```apache
# /etc/apache2/sites-available/app.example.com.conf

<VirtualHost *:80>
    ServerName app.example.com
    ServerAlias www.app.example.com

    # Redirection vers HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName app.example.com
    ServerAdmin webmaster@example.com
    DocumentRoot /var/www/app/public

    # TLS
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/app.example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/app.example.com/privkey.pem

    # Répertoire principal
    <Directory /var/www/app/public>
        Options -Indexes +FollowSymLinks   # Pas de listing, liens symboliques OK
        AllowOverride All                   # Autorise les .htaccess
        Require all granted                 # Accès autorisé
    </Directory>

    # Reverse proxy vers un backend
    ProxyPreserveHost On
    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/

    # Logs par virtual host
    ErrorLog ${APACHE_LOG_DIR}/app-error.log
    CustomLog ${APACHE_LOG_DIR}/app-access.log combined

    # En-têtes de sécurité
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set Strict-Transport-Security "max-age=63072000"
</VirtualHost>
```

### nftables — Pare-feu

```bash
#!/usr/sbin/nft -f
# /etc/nftables.conf — Règles de pare-feu

# Vider les règles existantes
flush ruleset

# Table pour le trafic IPv4 et IPv6 simultanément
table inet filter {

    # Chaîne d'entrée : trafic à destination du serveur
    chain input {
        type filter hook input priority 0; policy drop;
        # Politique par défaut : tout bloquer, puis autoriser au cas par cas

        # Connexions établies et associées : toujours acceptées
        ct state established,related accept

        # Interface loopback : toujours acceptée
        iif lo accept

        # ICMP : ping autorisé
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # SSH (limité à un sous-réseau d'administration)
        tcp dport 22 ip saddr 192.168.1.0/24 accept

        # HTTP et HTTPS : ouverts à tous
        tcp dport { 80, 443 } accept

        # DNS (si ce serveur est un serveur DNS)
        tcp dport 53 accept
        udp dport 53 accept

        # Monitoring (Node Exporter, limité au réseau interne)
        tcp dport 9100 ip saddr 10.0.0.0/8 accept

        # Journaliser les paquets rejetés (limité pour éviter le flood de logs)
        limit rate 5/minute log prefix "nft-drop: " counter drop
    }

    # Chaîne de forwarding : trafic transitant par le serveur
    chain forward {
        type filter hook forward priority 0; policy drop;
        # Accepter si le serveur fait office de routeur ou d'hôte Docker
        # ct state established,related accept
        # iifname "docker0" accept
        # oifname "docker0" ct state established,related accept
    }

    # Chaîne de sortie : trafic depuis le serveur
    chain output {
        type filter hook output priority 0; policy accept;
        # Politique permissive en sortie (restrictive si nécessaire)
    }
}
```

> **Attention** — Le shebang `#!/usr/sbin/nft -f` permet d'exécuter le fichier directement, mais le chargement standard se fait via `systemctl restart nftables` ou `nft -f /etc/nftables.conf`. Vérifier la syntaxe avec `nft -c -f /etc/nftables.conf` avant application.

### HAProxy — Load balancer

```bash
# /etc/haproxy/haproxy.cfg

global
    log /dev/log local0                  # Logging via syslog
    log /dev/log local1 notice
    chroot /var/lib/haproxy              # Isolation du processus
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    # TLS global
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode http                            # Mode HTTP (alternative : tcp)
    option httplog                       # Logs HTTP détaillés
    option dontlognull                   # Ne pas loguer les health checks
    option forwardfor                    # Ajoute l'en-tête X-Forwarded-For
    timeout connect 5s
    timeout client  30s
    timeout server  30s
    retries 3
    errorfile 503 /etc/haproxy/errors/503.http

# Interface de statistiques
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST

# Frontend HTTPS
frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/app.pem
    http-request set-header X-Forwarded-Proto https

    # Routage par nom de domaine
    acl host_app hdr(host) -i app.example.com
    acl host_api hdr(host) -i api.example.com

    use_backend app_servers if host_app
    use_backend api_servers if host_api
    default_backend app_servers

# Backend applicatif avec répartition round-robin
backend app_servers
    balance roundrobin
    option httpchk GET /health           # Health check HTTP
    http-check expect status 200

    server app01 192.168.1.20:8080 check inter 5s fall 3 rise 2
    server app02 192.168.1.21:8080 check inter 5s fall 3 rise 2
    server app03 192.168.1.22:8080 check inter 5s fall 3 rise 2 backup
    # check       : active le health check
    # inter 5s    : intervalle entre les vérifications
    # fall 3      : 3 échecs pour déclarer le serveur DOWN
    # rise 2      : 2 succès pour déclarer le serveur UP
    # backup      : serveur de secours, utilisé uniquement si les autres sont DOWN

# Backend API avec sticky sessions
backend api_servers
    balance leastconn                    # Connexion au serveur le moins chargé
    cookie SERVERID insert indirect nocache
    server api01 192.168.1.30:3000 check cookie api01
    server api02 192.168.1.31:3000 check cookie api02
```

---

## 4. Format INI et assimilés

Le format INI utilise des sections entre crochets `[section]` et des paires `clé = valeur`. Plusieurs variantes existent selon les services.

### MariaDB — Configuration de la base de données

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf

[mysqld]
# Réseau
bind-address            = 127.0.0.1      # Écoute locale uniquement  
port                    = 3306  

# Chemins
datadir                 = /var/lib/mysql  
tmpdir                  = /tmp  
socket                  = /run/mysqld/mysqld.sock  
pid-file                = /run/mysqld/mysqld.pid  

# Moteur de stockage par défaut
default-storage-engine  = InnoDB

# InnoDB — Performances
innodb_buffer_pool_size = 1G             # 50-70% de la RAM disponible sur un serveur dédié  
innodb_log_file_size    = 256M  
innodb_flush_log_at_trx_commit = 1       # 1 = sécurité max, 2 = meilleures performances  
innodb_file_per_table   = 1              # Un fichier par table  

# Jeu de caractères
character-set-server    = utf8mb4  
collation-server        = utf8mb4_unicode_ci  

# Logs
log_error               = /var/log/mysql/error.log  
slow_query_log          = 1  
slow_query_log_file     = /var/log/mysql/mysql-slow.log  
long_query_time         = 2              # Seuil en secondes  
log_queries_not_using_indexes = 1  

# Limites
max_connections         = 200  
max_allowed_packet      = 64M  
tmp_table_size          = 64M  
max_heap_table_size     = 64M  

[client]
default-character-set   = utf8mb4  
socket                  = /run/mysqld/mysqld.sock  
```

### Grafana — Observabilité

```ini
# /etc/grafana/grafana.ini (extraits)

[server]
protocol = http  
http_addr = 0.0.0.0  
http_port = 3000  
domain = grafana.example.com  
root_url = https://grafana.example.com/  
serve_from_sub_path = false  

[database]
type = sqlite3  
path = grafana.db  

[security]
admin_user = admin  
admin_password = changeme              # À changer immédiatement après installation  
secret_key = sw2YcwTIb9zpOQF1          # Clé de chiffrement des secrets  
cookie_secure = true                   # Cookies HTTPS uniquement  
cookie_samesite = lax  

[users]
allow_sign_up = false                  # Désactiver l'auto-inscription  
auto_assign_org = true  
auto_assign_org_role = Viewer          # Rôle par défaut des nouveaux utilisateurs  

[auth.ldap]
enabled = true  
config_file = /etc/grafana/ldap.toml  

[log]
mode = file  
level = info  
```

### fail2ban — Protection contre les intrusions

```ini
# /etc/fail2ban/jail.local — Overrides locaux

[DEFAULT]
# Paramètres par défaut pour toutes les jails
bantime  = 1h                          # Durée du ban  
findtime = 10m                         # Fenêtre d'observation  
maxretry = 5                           # Tentatives avant ban  
ignoreip = 127.0.0.1/8 192.168.1.0/24 # IPs jamais bannies  
banaction = nftables-multiport         # Action de ban (nftables)  
action = %(action_mwl)s                # Ban + mail avec logs  

[sshd]
enabled  = true  
port     = ssh  
logpath  = %(sshd_log)s  
maxretry = 3                           # Plus strict pour SSH  
bantime  = 24h  

[nginx-http-auth]
enabled  = true  
port     = http,https  
logpath  = /var/log/nginx/error.log  
maxretry = 5  

[postfix]
enabled  = true  
port     = smtp,465,submission  
logpath  = /var/log/mail.log  
maxretry = 5  
```

### GitLab Runner

```toml
# /etc/gitlab-runner/config.toml

concurrent = 4                           # Jobs simultanés  
check_interval = 3                       # Intervalle de polling (secondes)  
log_level = "info"  

[[runners]]
  name = "debian-runner-01"
  url = "https://gitlab.example.com/"
  token = "REGISTRATION_TOKEN"           # Remplacé par le vrai token
  executor = "docker"                    # Type d'exécuteur

  [runners.docker]
    image = "debian:trixie-slim"         # Image par défaut (Debian 13, stable depuis août 2025)
    privileged = false                   # Pas de mode privilégié
    disable_entrypoint_overwrite = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0

  [runners.cache]
    Type = "s3"
    Shared = true
    [runners.cache.s3]
      ServerAddress = "minio.internal:9000"
      BucketName = "runner-cache"
      Insecure = false
```

---

## 5. Format YAML

YAML est le format dominant de l'écosystème cloud-native. Son principe fondamental est l'indentation par espaces (jamais par tabulations) pour définir la hiérarchie.

### Unité systemd sous forme de timer

Bien que systemd n'utilise pas YAML, il est courant de décrire les timers en complément des services. Voici d'abord le format natif systemd.

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Sauvegarde quotidienne

[Timer]
OnCalendar=*-*-* 03:00:00               # Tous les jours à 3h  
Persistent=true                          # Rattrape les exécutions manquées  
RandomizedDelaySec=900                   # Décalage aléatoire de 0 à 15 min  

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Script de sauvegarde  
After=network-online.target  

[Service]
Type=oneshot                             # Exécution unique puis terminaison  
User=backup  
Group=backup  
ExecStart=/usr/local/bin/backup.sh  
StandardOutput=journal  
StandardError=journal  

# Sécurité (sandboxing)
ProtectSystem=full                       # /usr et /boot en lecture seule  
ProtectHome=read-only  
PrivateTmp=true                          # /tmp isolé  
NoNewPrivileges=true  
```

### Docker Compose

```yaml
# compose.yaml — Stack applicative complète

services:
  # Application web
  app:
    build:
      context: .                         # Contexte de build = répertoire courant
      dockerfile: Dockerfile             # Dockerfile à utiliser
      args:
        APP_VERSION: "1.5.0"             # Arguments de build
    image: app:1.5.0
    container_name: app
    restart: unless-stopped              # Redémarrage auto sauf arrêt manuel
    ports:
      - "127.0.0.1:8080:8080"           # Bind localhost uniquement
    environment:
      - DATABASE_URL=postgresql://app:secret@db:5432/appdb
      - REDIS_URL=redis://cache:6379/0
    env_file:
      - .env                             # Variables supplémentaires
    volumes:
      - app-data:/app/data               # Volume nommé pour la persistance
      - ./config:/app/config:ro          # Bind mount en lecture seule
    depends_on:
      db:
        condition: service_healthy       # Attend que db soit sain
      cache:
        condition: service_started
    networks:
      - frontend
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: "1.0"

  # Base de données
  db:
    image: postgres:17-trixie              # Image officielle (PG 18 stable depuis sept. 2025,
                                            # PG 17 = version par défaut sous Debian Trixie)
    container_name: db
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret           # En production : utiliser un secret
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Cache Redis. Contexte de licence à connaître :
  # - Redis 7.x : licence BSD historique
  # - Redis 7.4+ (mars 2024) : SSPL/RSALv2 (non OSI-approved) → fork Valkey
  # - Redis 8.0 (mai 2025) : tri-licence AGPLv3 + SSPL + RSALv2 (AGPLv3 est OSI-approved)
  # Valkey reste l'alternative BSD-3 (sans clause copyleft) sous Linux Foundation,
  # drop-in replacement de Redis 7.2 ; choix recommandé si la dépendance à AGPLv3
  # pose problème (logiciels propriétaires SaaS notamment).
  cache:
    image: redis:8.4-trixie                # Alternative : valkey/valkey:9.0-alpine
    container_name: cache
    restart: unless-stopped
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - cache-data:/data
    networks:
      - backend

  # Reverse proxy
  nginx:
    image: nginx:1.28-trixie               # Branche stable Nginx (1.28.x).
                                            # Mainline = 1.29.x (nouvelles fonctionnalités).
                                            # Trixie de base ships nginx 1.26 ; l'image
                                            # Docker upstream propose des versions plus
                                            # récentes que la stable Debian.
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    depends_on:
      - app
    networks:
      - frontend

volumes:
  app-data:                              # Volume nommé géré par Docker
  db-data:
  cache-data:

networks:
  frontend:                              # Réseau exposé
  backend:                               # Réseau interne isolé
    internal: true                       # Pas d'accès externe
```

> **Attention** — YAML est sensible à l'indentation. Utiliser exactement 2 espaces par niveau. Les tabulations provoquent des erreurs de syntaxe silencieuses ou des interprétations inattendues. Les valeurs qui ressemblent à des booléens (`yes`, `no`, `on`, `off`, `true`, `false`) sont interprétées automatiquement : pour les garder en tant que chaînes, les entourer de guillemets.

### Manifeste Kubernetes — Deployment

```yaml
# deployment.yaml — Déploiement d'une application web

apiVersion: apps/v1                      # Version de l'API Kubernetes  
kind: Deployment                         # Type de ressource  
metadata:  
  name: web-app                          # Nom de la ressource
  namespace: production                  # Namespace cible
  labels:                                # Labels pour la sélection et l'organisation
    app: web-app
    version: v1.5.0
    team: backend
  annotations:
    kubernetes.io/change-cause: "Deploy v1.5.0 — fix auth bug"
spec:
  replicas: 3                            # Nombre de pods souhaité
  revisionHistoryLimit: 5                # Historique conservé pour rollback
  strategy:
    type: RollingUpdate                  # Mise à jour progressive
    rollingUpdate:
      maxSurge: 1                        # Max 1 pod supplémentaire pendant la MAJ
      maxUnavailable: 0                  # Aucune interruption pendant la MAJ
  selector:
    matchLabels:                         # Doit correspondre aux labels des pods
      app: web-app
  template:                              # Template du pod
    metadata:
      labels:
        app: web-app
        version: v1.5.0
    spec:
      serviceAccountName: web-app        # Compte de service dédié
      securityContext:                   # Sécurité au niveau du pod
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: web-app
          image: registry.example.com/web-app:1.5.0
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
              protocol: TCP
              name: http
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:            # Valeur depuis un Secret K8s
                  name: web-app-secrets
                  key: database-url
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:         # Valeur depuis un ConfigMap
                  name: web-app-config
                  key: log-level
          resources:                     # Ressources garanties et limites
            requests:
              cpu: 100m                  # 100 millicores = 0.1 CPU
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:                 # Redémarrage si le conteneur est mort
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 3
          readinessProbe:                # Retrait du service si pas prêt
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:               # Sécurité au niveau du conteneur
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: app-config
              mountPath: /etc/app/config.yaml
              subPath: config.yaml       # Monte un seul fichier du ConfigMap
              readOnly: true
      volumes:
        - name: tmp
          emptyDir: {}                   # Volume éphémère pour /tmp
        - name: app-config
          configMap:
            name: web-app-config
      affinity:                          # Répartition sur les nœuds
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: web-app
                topologyKey: kubernetes.io/hostname
```

### Prometheus — Configuration du monitoring

```yaml
# /etc/prometheus/prometheus.yml

global:
  scrape_interval: 15s                   # Fréquence de collecte par défaut
  evaluation_interval: 15s               # Fréquence d'évaluation des règles
  scrape_timeout: 10s                    # Timeout par scrape
  external_labels:                       # Labels ajoutés à toutes les métriques
    cluster: production
    region: eu-west

# Fichiers de règles d'alerte
rule_files:
  - /etc/prometheus/rules/*.yml

# Configuration de l'envoi vers AlertManager
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Cibles de collecte
scrape_configs:
  # Prometheus se scrape lui-même
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  # Node Exporter sur les serveurs Debian
  - job_name: node
    file_sd_configs:                     # Découverte par fichier
      - files:
          - /etc/prometheus/targets/nodes.yml
        refresh_interval: 5m
    relabel_configs:                     # Renommage de labels
      - source_labels: [__address__]
        regex: '(.+):(\d+)'
        target_label: instance
        replacement: '${1}'

  # Pods Kubernetes avec annotations
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: '${1}'
```

### Ansible — Playbook

```yaml
# playbook.yaml — Déploiement d'un serveur web Debian

---
- name: Configurer les serveurs web Debian
  hosts: webservers
  become: true                           # Élévation de privilèges (sudo)
  gather_facts: true                     # Collecter les informations système

  vars:
    http_port: 443
    app_version: "1.5.0"
    ssl_cert_path: /etc/letsencrypt/live/{{ ansible_fqdn }}
    packages:
      - nginx
      - certbot
      - python3-certbot-nginx

  vars_files:
    - vars/secrets.yaml                  # Fichier chiffré avec ansible-vault

  pre_tasks:
    - name: Mettre à jour le cache APT
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600           # Ne rafraîchir qu'une fois par heure

  tasks:
    - name: Installer les paquets nécessaires
      ansible.builtin.apt:
        name: "{{ packages }}"
        state: present

    - name: Déployer la configuration Nginx
      ansible.builtin.template:
        src: templates/nginx-vhost.conf.j2
        dest: /etc/nginx/sites-available/{{ ansible_fqdn }}.conf
        owner: root
        group: root
        mode: '0644'
        validate: nginx -t -c %s         # Validation avant installation
      notify: Recharger Nginx

    - name: Activer le virtual host
      ansible.builtin.file:
        src: /etc/nginx/sites-available/{{ ansible_fqdn }}.conf
        dest: /etc/nginx/sites-enabled/{{ ansible_fqdn }}.conf
        state: link
      notify: Recharger Nginx

    - name: Paramètres de sécurité noyau
      ansible.posix.sysctl:
        name: "{{ item.key }}"
        value: "{{ item.value }}"
        sysctl_file: /etc/sysctl.d/99-hardening.conf
        reload: true
      loop:
        - { key: net.ipv4.conf.all.rp_filter, value: "1" }
        - { key: net.ipv4.conf.all.accept_redirects, value: "0" }
        - { key: net.ipv4.conf.all.send_redirects, value: "0" }

    - name: Configurer le pare-feu UFW
      community.general.ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "22"
        - "80"
        - "443"

    - name: Activer UFW
      community.general.ufw:
        state: enabled
        policy: deny                     # Politique par défaut : bloquer

  handlers:
    - name: Recharger Nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
```

### Ansible — Inventaire YAML

```yaml
# inventory/production.yaml

all:
  vars:                                  # Variables globales
    ansible_user: deploy
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
    ansible_python_interpreter: /usr/bin/python3
    ntp_server: ntp.internal.example.com

  children:
    webservers:
      hosts:
        web01.example.com:
          http_port: 443
          nginx_worker_processes: 4
        web02.example.com:
          http_port: 443
          nginx_worker_processes: 2
      vars:
        server_role: web

    dbservers:
      hosts:
        db01.example.com:
          postgresql_max_connections: 200
        db02.example.com:
          postgresql_max_connections: 100
          postgresql_role: replica        # Variable spécifique à l'hôte
      vars:
        server_role: database
        backup_schedule: "0 3 * * *"
```

---

## 6. Format HCL (HashiCorp Configuration Language)

HCL est le format utilisé par Terraform et son fork open source **OpenTofu** (MPL 2.0, maintenu par la Linux Foundation depuis le passage de Terraform sous BSL en août 2023). Les exemples ci-dessous fonctionnent à l'identique sur les deux outils. Sa syntaxe se situe entre JSON et un langage de programmation, avec des blocs typés, des expressions et des fonctions.

### Terraform / OpenTofu — Infrastructure

```hcl
# main.tf — Infrastructure AWS

terraform {
  required_version = ">= 1.7.0"         # Version minimum de Terraform

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"                # Compatible 5.x
    }
  }

  backend "s3" {                         # Stockage distant de l'état
    bucket       = "terraform-state-prod"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true                  # Verrouillage natif S3 (depuis
                                          # Terraform 1.10 / OpenTofu 1.8 :
                                          # plus besoin de DynamoDB).
                                          # Pour les anciennes versions ou
                                          # une migration progressive,
                                          # `dynamodb_table = "terraform-locks"`
                                          # reste accepté mais déprécié
                                          # depuis Terraform 1.11.
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}

# Variables
variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "Région AWS de déploiement"
}

variable "project_name" {
  type        = string
  description = "Nom du projet"
}

variable "instance_count" {
  type        = number
  default     = 2
  description = "Nombre d'instances web"
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Le nombre d'instances doit être entre 1 et 10."
  }
}

# Data source : AMI Debian la plus récente
data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]       # Trixie (stable depuis août 2025).
                                          # Utiliser "debian-12-amd64-*" pour rester
                                          # sur Bookworm (oldstable).
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["136693071363"]              # ID du compte Debian officiel sur AWS
}

# Locals : valeurs calculées
locals {
  name_prefix = "${var.project_name}-${terraform.workspace}"
  common_tags = {
    Component = "web"
  }
}

# Ressource : instances EC2
resource "aws_instance" "web" {
  count = var.instance_count             # Boucle count

  ami           = data.aws_ami.debian.id
  instance_type = "t3.small"
  subnet_id     = aws_subnet.web[count.index % length(aws_subnet.web)].id

  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deploy.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/scripts/init.sh", {
    hostname = "${local.name_prefix}-web-${count.index + 1}"
    env      = terraform.workspace
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-${count.index + 1}"
    Role = "webserver"
  })

  lifecycle {
    create_before_destroy = true         # Crée la nouvelle avant de supprimer l'ancienne
    ignore_changes        = [ami]        # Ne pas recréer si l'AMI change
  }
}

# Outputs
output "web_ips" {
  value       = aws_instance.web[*].public_ip
  description = "Adresses IP publiques des serveurs web"
}

output "lb_dns" {
  value       = aws_lb.web.dns_name
  description = "DNS du load balancer"
}
```

> **Attention** — HCL est sensible à la différence entre `=` (affectation d'un argument) et les blocs sans `=` (définition d'un sous-bloc). Par exemple, `tags = { ... }` est une affectation de map, tandis que `root_block_device { ... }` est un sous-bloc. Confondre les deux provoque des erreurs de syntaxe.

---

## 7. Format JSON

JSON est utilisé principalement pour la configuration du démon Docker et certaines APIs.

### Docker daemon

```json
{
  "data-root": "/var/lib/docker",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    }
  ],
  "dns": ["192.168.1.1", "8.8.8.8"],
  "live-restore": true,
  "userland-proxy": false,
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "insecure-registries": [],
  "registry-mirrors": ["https://mirror.gcr.io"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "metrics-addr": "127.0.0.1:9323",
  "experimental": false
}
```

Le fichier `/etc/docker/daemon.json` est lu au démarrage du démon Docker. Toute modification nécessite un `systemctl restart docker`. Les options de ce fichier ne doivent pas entrer en conflit avec les arguments de la ligne de commande définis dans l'unité systemd.

> **Attention** — JSON n'autorise pas les commentaires. C'est sa limitation principale pour les fichiers de configuration. JSON n'autorise pas non plus les virgules traînantes après le dernier élément d'un objet ou d'un tableau.

---

## 8. Format TOML

TOML (Tom's Obvious, Minimal Language) est utilisé par containerd et certains outils modernes. Il ressemble au format INI mais avec un typage plus strict.

### containerd — Runtime de conteneurs

```toml
# /etc/containerd/config.toml

version = 2                              # Version du format de configuration

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.10"

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true         # Utiliser systemd pour les cgroups

    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
```

> **Note (containerd 2.x / Kubernetes 1.34+)** — Avec containerd 2.0 (sorti en novembre 2024) le format de configuration **version = 3** est désormais recommandé. La version 2 reste lue par containerd 2.x (conversion automatique en mémoire, sans modification du fichier sur disque). En version 3, les chemins de plugin changent : `plugins."io.containerd.grpc.v1.cri"` devient `plugins."io.containerd.cri.v1.runtime"` (et `plugins."io.containerd.cri.v1.images"` pour `sandbox_image`). Côté image pause, Kubernetes 1.30+ utilise `registry.k8s.io/pause:3.10` par défaut (kubeadm, kubelet, Linux et Windows) et reste sur cette version dans les releases 1.34/1.35 de 2025-2026 — la version `3.9` reste fonctionnelle mais n'est plus alignée avec les versions récentes. À noter qu'en Kubernetes 1.34, le flag `--pod-infra-container-image` du kubelet a été supprimé : le retirer des `extraArgs` kubelet/kubeadm avant la mise à jour pour éviter un échec de démarrage.

> **Attention** — Les sections TOML imbriquées produisent des clés très longues comme `plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options`. L'indentation visuelle n'est pas significative en TOML — c'est la hiérarchie des en-têtes entre crochets qui détermine la structure. Les guillemets autour des noms contenant des points sont obligatoires.

---

## 9. Formats spécifiques

Certains services utilisent des formats propres qui ne rentrent dans aucune des catégories précédentes.

### PostgreSQL — pg_hba.conf (authentification)

```bash
# /etc/postgresql/<version>/main/pg_hba.conf
# Debian Bookworm 12  → version 15 par défaut
# Debian Trixie  13   → version 17 par défaut (sortie août 2025)
# Dépôt PGDG (apt.postgresql.org) → versions 17 et 18 disponibles sur Bookworm/Trixie
#
# TYPE    DATABASE    USER        ADDRESS            METHOD

# Connexions locales via socket Unix
local     all         postgres                       peer  
local     all         all                            peer  

# Connexions IPv4 locales
host      all         all         127.0.0.1/32       scram-sha-256

# Connexions IPv6 locales
host      all         all         ::1/128            scram-sha-256

# Réseau interne : authentification par mot de passe
host      appdb       appuser     192.168.1.0/24     scram-sha-256

# Réplication
host      replication replica     192.168.1.20/32    scram-sha-256
```

Les méthodes d'authentification courantes sont `peer` (correspondance utilisateur Unix), `scram-sha-256` (mot de passe chiffré, recommandé), `md5` (ancien, moins sûr), `reject` (refus explicite) et `trust` (aucune authentification, uniquement en développement local).

> **Attention** — Les règles sont évaluées de haut en bas : la première correspondance s'applique. Une règle trop permissive placée avant une règle restrictive rend cette dernière inopérante. Après modification, recharger avec `systemctl reload postgresql`.

### Caddyfile — Serveur web Caddy

```
# /etc/caddy/Caddyfile

# Options globales
{
    email admin@example.com              # Email pour les certificats ACME
    admin off                            # Désactiver l'API d'admin
}

# Site principal avec HTTPS automatique
app.example.com {
    # Reverse proxy vers l'application
    reverse_proxy localhost:8080 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
        health_uri /health
        health_interval 30s
    }

    # Fichiers statiques
    handle_path /static/* {
        root * /var/www/app/static
        file_server {
            precompressed gzip
        }
    }

    # Logs
    log {
        output file /var/log/caddy/app-access.log {
            roll_size 100MiB
            roll_keep 5
        }
        format json
    }

    # En-têtes de sécurité
    header {
        Strict-Transport-Security "max-age=63072000"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        -Server                          # Supprimer l'en-tête Server
    }

    # Compression
    encode gzip zstd
}

# Redirection www vers le domaine principal
www.app.example.com {
    redir https://app.example.com{uri} permanent
}
```

### WireGuard — Interface VPN

```ini
# /etc/wireguard/wg0.conf

[Interface]
# Configuration locale
PrivateKey = yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=  
Address = 10.0.0.1/24                    # Adresse IP dans le tunnel  
ListenPort = 51820                       # Port UDP d'écoute  
DNS = 192.168.1.1                        # DNS à utiliser via le tunnel  

# Commandes exécutées au démarrage/arrêt de l'interface
PostUp = nft add rule inet filter input udp dport 51820 accept  
PostDown = nft delete rule inet filter input udp dport 51820 accept  

[Peer]
# Client 1
PublicKey = xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=  
AllowedIPs = 10.0.0.2/32                # Adresse autorisée pour ce peer  
PresharedKey = ...                       # Clé pré-partagée (optionnel, sécurité +)  

[Peer]
# Client 2
PublicKey = TrMvSoP4jYQlY6RIzBgbssQqY3vxI2piVFBs207AliQ=  
AllowedIPs = 10.0.0.3/32  
Endpoint = 203.0.113.50:51820            # Adresse publique du peer (si connue)  
PersistentKeepalive = 25                 # Keepalive pour les NAT (secondes)  
```

### BIND9 — Fichier de zone DNS

```
; /etc/bind/db.example.com — Zone directe

$TTL    86400                            ; TTL par défaut : 24 heures
$ORIGIN example.com.                     ; Domaine de la zone (point final obligatoire)

; Enregistrement SOA (Start of Authority)
@   IN  SOA ns1.example.com. admin.example.com. (
        2026041201  ; Numéro de série (convention : YYYYMMDDNN)
        3600        ; Refresh : 1 heure
        900         ; Retry : 15 minutes
        1209600     ; Expire : 2 semaines
        86400       ; Minimum TTL (TTL négatif) : 24 heures
    )

; Serveurs de noms
    IN  NS      ns1.example.com.
    IN  NS      ns2.example.com.

; Enregistrements MX (mail)
    IN  MX  10  mail.example.com.        ; Priorité 10 (plus bas = prioritaire)
    IN  MX  20  mail-backup.example.com.

; Enregistrements A (IPv4)
@       IN  A       203.0.113.10         ; Domaine racine
ns1     IN  A       203.0.113.1  
ns2     IN  A       203.0.113.2  
mail    IN  A       203.0.113.5  
www     IN  A       203.0.113.10  
app     IN  A       203.0.113.20  

; Enregistrements AAAA (IPv6)
@       IN  AAAA    2001:db8::10
www     IN  AAAA    2001:db8::10

; CNAME (alias)
ftp     IN  CNAME   www.example.com.  
docs    IN  CNAME   app.example.com.  

; Enregistrements TXT
@       IN  TXT     "v=spf1 mx a:mail.example.com -all"
_dmarc  IN  TXT     "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"

; SRV (services)
_https._tcp  IN  SRV  0 1 443 www.example.com.
```

> **Attention** — En DNS, le **point final** après les noms de domaine complets (FQDN) est fondamental. `www.example.com.` (avec point) est un nom absolu. `www.example.com` (sans point) serait interprété comme `www.example.com.example.com.` car BIND ajoute automatiquement l'`$ORIGIN`. Cette erreur est l'une des causes les plus fréquentes de problèmes de résolution.

---

## Synthèse des pièges par format

| Format | Piège fréquent | Symptôme |
|--------|---------------|----------|
| fstab | Oubli de `nofail` sur un montage non critique | Système bloqué au boot |
| YAML | Tabulation au lieu d'espaces | Erreur de parsing silencieuse |
| YAML | `yes`/`no` interprétés comme booléens | Valeurs inattendues |
| JSON | Virgule après le dernier élément | Erreur de syntaxe |
| JSON | Commentaire dans le fichier | Erreur de syntaxe |
| Nginx | Oubli du `;` en fin de directive | Échec du rechargement |
| Apache | `AllowOverride` mal configuré | `.htaccess` ignorés |
| HCL | Confusion `=` (argument) vs bloc | Erreur de syntaxe Terraform |
| TOML | Points dans les clés sans guillemets | Hiérarchie incorrecte |
| sshd_config | `Match` mal positionné | Règles appliquées globalement |
| pg_hba.conf | Ordre des règles | Authentification inattendue |
| DNS (zone) | Oubli du point final sur un FQDN | Nom de domaine dupliqué |
| nftables | `policy drop` sans règle established | Connexions existantes coupées |
| systemd | Oubli de `daemon-reload` après modification | Ancienne version chargée |
| cron (système) | Oubli du champ utilisateur dans `/etc/cron.d/` | Exécution en tant que root |

⏭️ [Templates et bonnes pratiques](/annexes/B.3-templates-bonnes-pratiques.md)
