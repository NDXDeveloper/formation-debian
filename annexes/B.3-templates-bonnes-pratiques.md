🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe B.3 — Templates et bonnes pratiques

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section fournit des **modèles de configuration prêts à adapter** pour les services les plus courants, accompagnés des **bonnes pratiques** de gestion, d'organisation et de maintenance des fichiers de configuration dans un environnement Debian. Là où B.2 expliquait la syntaxe, B.3 se concentre sur la méthodologie et les choix d'architecture qui garantissent un système maintenable, reproductible et sûr en production.

---

## Partie 1 — Bonnes pratiques de gestion de la configuration

### 1.1 Ne jamais modifier les fichiers fournis par les paquets

Le principe fondamental de la gestion de configuration sous Debian est de ne jamais modifier directement un fichier installé par un paquet. Les fichiers distribués dans `/lib/systemd/system/`, `/usr/share/` ou les fichiers de configuration par défaut dans `/etc/` sont susceptibles d'être remplacés lors d'une mise à jour. Toute modification directe impose à l'administrateur un choix lors de chaque mise à jour et crée un risque de perte de personnalisation.

La méthode correcte dépend du service concerné. Pour systemd, on utilise `systemctl edit <service>` qui crée un fichier d'override dans `/etc/systemd/system/<service>.d/override.conf`. Pour les services utilisant des répertoires drop-in (`/etc/apt/sources.list.d/`, `/etc/sysctl.d/`, `/etc/rsyslog.d/`), on ajoute un nouveau fichier plutôt que de modifier le fichier principal. Pour les services sans mécanisme drop-in, on copie le fichier par défaut sous un nouveau nom ou on utilise le fichier dédié aux overrides locaux (`jail.local` pour fail2ban, `conf.d/` pour Nginx).

### 1.2 Convention de nommage des fichiers drop-in

Les fichiers dans les répertoires `.d/` sont lus par ordre alphabétique. La convention recommandée est de les préfixer par un nombre à deux chiffres qui reflète la priorité de chargement.

```
/etc/sysctl.d/
├── 10-network-security.conf       # Paramètres réseau de base
├── 20-kernel-hardening.conf       # Durcissement du noyau
├── 50-application.conf            # Paramètres applicatifs
└── 99-override.conf               # Surcharges finales (priorité maximale)
```

Les plages recommandées sont : 00-09 pour les configurations système de base, 10-29 pour la sécurité et le réseau, 30-49 pour les services, 50-69 pour les applications et 70-99 pour les overrides locaux. Cette convention n'est pas imposée par le système, mais elle facilite la compréhension de l'ordre d'application quand plusieurs fichiers coexistent.

### 1.3 Versionner /etc avec etckeeper

L'installation et la configuration d'`etckeeper` devraient être l'un des premiers gestes après l'installation d'un serveur Debian.

```bash
# Installation
apt install etckeeper

# Configuration : /etc/etckeeper/etckeeper.conf
VCS="git"                               # Utiliser git comme VCS  
AVOID_DAILY_AUTOCOMMITS=1               # Pas de commits automatiques quotidiens  
AVOID_COMMIT_BEFORE_INSTALL=0           # Commit avant chaque apt install  
```

Après installation, etckeeper initialise automatiquement un dépôt Git dans `/etc` et crée un commit à chaque opération `apt`. L'administrateur conserve la possibilité de faire des commits manuels pour documenter ses modifications.

```bash
cd /etc  
git log --oneline                        # Historique des modifications  
git diff                                 # Modifications en cours  
git log -p -- ssh/sshd_config            # Historique d'un fichier spécifique  
git checkout -- nginx/sites-available/default  # Restaurer un fichier  
```

Pour les serveurs gérés par Ansible ou Terraform, le versionning de `/etc` via etckeeper complète le versionning du code d'automatisation : il capture aussi les modifications manuelles d'urgence qui n'ont pas encore été intégrées dans les playbooks.

### 1.4 Toujours valider avant d'appliquer

Chaque modification d'un fichier de configuration doit suivre un cycle en trois étapes : modifier, valider, appliquer. La validation utilise les commandes dédiées de chaque service (documentées en détail dans l'introduction de l'annexe B). L'application se fait ensuite par rechargement du service (`systemctl reload`) plutôt que par redémarrage (`systemctl restart`) lorsque le service le permet, afin d'éviter toute interruption.

Le workflow recommandé pour un service comme Nginx est :

```bash
# 1. Modifier la configuration
vim /etc/nginx/sites-available/app.conf

# 2. Valider la syntaxe
nginx -t

# 3. Appliquer sans interruption
systemctl reload nginx

# 4. Vérifier le fonctionnement
curl -I https://app.example.com  
systemctl status nginx  
journalctl -u nginx --since "1 minute ago"  
```

Pour les modifications à risque, on prévoit un mécanisme de rollback avant de commencer.

```bash
# Sauvegarde ponctuelle avant une modification majeure
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d)

# Ou via etckeeper
cd /etc && git add -A && git commit -m "Avant migration Nginx vers HTTP/3"
```

### 1.5 Séparer la configuration par environnement

Dans un contexte multi-environnement (développement, staging, production), la configuration ne doit jamais être dupliquée intégralement. La bonne pratique est d'isoler les éléments qui varient entre environnements (adresses IP, noms de domaines, identifiants, tailles de ressources) dans des fichiers de variables, et de conserver la structure commune dans des templates partagés.

Cette séparation se traduit différemment selon les outils. Ansible utilise les répertoires `group_vars/` et `host_vars/` pour les variables, et les templates Jinja2 pour la configuration commune. Terraform utilise les fichiers `.tfvars` par environnement ou les workspaces. Kubernetes utilise Kustomize avec des overlays par environnement ou Helm avec des fichiers `values-<env>.yaml` distincts. Docker Compose utilise les fichiers override (`compose.override.yaml`) ou les fichiers `.env` par environnement.

### 1.6 Protéger les données sensibles

Les fichiers de configuration contiennent régulièrement des données sensibles : mots de passe de bases de données, clés API, certificats TLS, tokens d'authentification. Ces données ne doivent jamais être stockées en clair dans un système de contrôle de version.

Les outils adaptés selon le contexte sont `ansible-vault` pour les variables sensibles dans les playbooks Ansible, `sops` ou `sealed-secrets` pour les secrets dans un workflow GitOps, HashiCorp Vault pour la gestion centralisée des secrets en production, et les Kubernetes Secrets (chiffrés au repos via `EncryptionConfiguration`) pour les données sensibles dans un cluster.

Sur le système de fichiers, les fichiers contenant des secrets doivent avoir des permissions restrictives. Les clés privées SSH sont en `600`, les fichiers contenant des mots de passe de base de données en `640` avec un groupe dédié, et les clés TLS privées en `600` appartenant à root.

### 1.7 Documenter chaque modification

Chaque fichier de configuration modifié doit comporter un en-tête documentant sa provenance et son rôle. Cette pratique est particulièrement importante quand plusieurs administrateurs interviennent sur un même système.

```bash
# ============================================================
# Fichier : /etc/nginx/sites-available/app.example.com.conf
# Rôle    : Virtual host pour l'application web principale
# Auteur  : Alice Martin <alice@example.com>
# Date    : 2026-04-12
# Géré par : Ansible (role nginx, template nginx-vhost.conf.j2)
# ============================================================
```

Pour les fichiers gérés par Ansible, l'en-tête standard prévient toute modification manuelle.

```bash
# ============================================================
# Ce fichier est géré par Ansible — ne pas modifier manuellement
# Template : roles/nginx/templates/vhost.conf.j2
# Playbook : site.yaml
# Toute modification sera écrasée au prochain déploiement
# ============================================================
```

---

## Partie 2 — Templates de configuration

Les templates ci-dessous sont conçus comme des points de départ pour un déploiement en production. Chaque template suit les bonnes pratiques décrites en partie 1 et intègre les paramètres de sécurité recommandés. Les valeurs entre chevrons `<valeur>` ou doubles accolades `{{ variable }}` sont à remplacer par les valeurs réelles de l'environnement.

### 2.1 Template systemd — Service personnalisé

Ce template couvre le cas courant d'une application web déployée comme service systemd sur un serveur Debian.

```ini
# /etc/systemd/system/myapp.service

[Unit]
Description=<Nom de l'application>  
Documentation=https://docs.example.com/myapp  
After=network-online.target postgresql.service  
Wants=network-online.target  
Requires=postgresql.service  

# Limite de redémarrages (cf. Restart= dans [Service]).
# Depuis systemd 230, StartLimit* sont déclarés dans [Unit], pas dans [Service]
# (sinon « Unknown key in section [Service], ignoring »).
StartLimitIntervalSec=60  
StartLimitBurst=3                        # Max 3 redémarrages en 60 secondes  

[Service]
Type=notify                              # L'application signale quand elle est prête  
User=myapp                               # Utilisateur dédié non-root  
Group=myapp  
WorkingDirectory=/opt/myapp  

# Démarrage
ExecStartPre=/opt/myapp/bin/check-config # Vérification pré-démarrage  
ExecStart=/opt/myapp/bin/myapp --config /etc/myapp/config.yaml  
ExecReload=/bin/kill -HUP $MAINPID       # Rechargement par signal  

# Redémarrage automatique (StartLimit* sont dans [Unit] ci-dessus)
Restart=on-failure  
RestartSec=5s  

# Environnement
EnvironmentFile=-/etc/default/myapp      # Le '-' ignore l'absence du fichier  
Environment=LOG_LEVEL=info  

# Timeouts
TimeoutStartSec=30  
TimeoutStopSec=30  
WatchdogSec=60                           # Watchdog : redémarrage si pas de signal  

# Sécurité — Sandboxing
NoNewPrivileges=true  
ProtectSystem=strict                     # / en lecture seule sauf exceptions  
ProtectHome=true                         # /home inaccessible  
PrivateTmp=true                          # /tmp isolé  
PrivateDevices=true                      # Pas d'accès aux périphériques  
ProtectKernelModules=true  
ProtectKernelTunables=true  
ProtectControlGroups=true  
ReadWritePaths=/var/lib/myapp /var/log/myapp  
ReadOnlyPaths=/etc/myapp  

# Capabilities
CapabilityBoundingSet=CAP_NET_BIND_SERVICE  
AmbientCapabilities=CAP_NET_BIND_SERVICE # Nécessaire pour les ports < 1024  

# Limites de ressources
LimitNOFILE=65535  
MemoryMax=1G  
CPUQuota=200%                            # Maximum 2 cœurs CPU  

[Install]
WantedBy=multi-user.target
```

Le template correspondant pour un timer de sauvegarde suit le même niveau de rigueur.

```ini
# /etc/systemd/system/backup-daily.timer

[Unit]
Description=Sauvegarde quotidienne de <service>

[Timer]
OnCalendar=*-*-* 02:30:00  
AccuracySec=15min                        # Tolérance de déclenchement  
Persistent=true                          # Rattrape les exécutions manquées  
RandomizedDelaySec=600                   # Jitter pour éviter les pics de charge  

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/backup-daily.service

[Unit]
Description=Exécution de la sauvegarde quotidienne  
After=network-online.target  

[Service]
Type=oneshot  
User=backup  
Group=backup  
ExecStart=/usr/local/bin/backup.sh  
StandardOutput=journal  
StandardError=journal  
SyslogIdentifier=backup-daily  

# Sécurité
NoNewPrivileges=true  
ProtectSystem=full  
PrivateTmp=true  

# Timeout généreux pour les sauvegardes volumineuses
TimeoutStartSec=3600

# Notification en cas d'échec
ExecStopPost=/bin/sh -c 'if [ "$$EXIT_STATUS" -ne 0 ]; then \
    echo "Backup failed with exit code $$EXIT_STATUS" | \
    mail -s "[ALERT] Backup failure on %H" admin@example.com; fi'
```

### 2.2 Template Nginx — Reverse proxy sécurisé

Ce template produit un virtual host complet avec HTTPS, reverse proxy, headers de sécurité et logging structuré.

```nginx
# /etc/nginx/sites-available/<domaine>.conf

# Paramètres SSL partagés (à inclure depuis un snippet)
# /etc/nginx/snippets/ssl-params.conf
ssl_protocols TLSv1.2 TLSv1.3;  
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;  
ssl_prefer_server_ciphers off;  
ssl_session_timeout 1d;  
ssl_session_cache shared:SSL:10m;  
ssl_session_tickets off;  
ssl_stapling on;  
ssl_stapling_verify on;  
resolver 127.0.0.1 valid=300s;  
resolver_timeout 5s;  

# /etc/nginx/snippets/security-headers.conf
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;  
add_header X-Content-Type-Options "nosniff" always;  
add_header X-Frame-Options "SAMEORIGIN" always;  
add_header Referrer-Policy "strict-origin-when-cross-origin" always;  
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;  

# Redirection HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name <domaine> www.<domaine>;

    # Exception pour le challenge ACME de Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://<domaine>$request_uri;
    }
}

# Redirection www → apex
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;                            # Nginx 1.25.1+ : directive http2 dédiée
    server_name www.<domaine>;

    ssl_certificate /etc/letsencrypt/live/<domaine>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<domaine>/privkey.pem;
    include snippets/ssl-params.conf;

    return 301 https://<domaine>$request_uri;
}

# Serveur principal
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;                            # Nginx 1.25.1+ (l'ancien `listen ... http2` est déprécié)
    server_name <domaine>;

    # TLS
    ssl_certificate /etc/letsencrypt/live/<domaine>/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/<domaine>/privkey.pem;
    include snippets/ssl-params.conf;
    include snippets/security-headers.conf;

    # Logs
    access_log /var/log/nginx/<domaine>-access.log main;
    error_log /var/log/nginx/<domaine>-error.log warn;

    # Taille maximale des uploads
    client_max_body_size 50M;

    # Fichiers statiques
    location /static/ {
        alias /var/www/<domaine>/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Reverse proxy vers le backend
    location / {
        proxy_pass http://127.0.0.1:<port>;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";

        proxy_connect_timeout 10s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 8k;
    }

    # Bloquer l'accès aux fichiers cachés
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Pages d'erreur personnalisées
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
}
```

Le découpage en snippets (`ssl-params.conf`, `security-headers.conf`) évite la duplication entre virtual hosts et centralise les paramètres de sécurité en un seul endroit.

### 2.3 Template Dockerfile — Application Debian

Ce template suit les bonnes pratiques de construction d'images : multi-stage build, utilisateur non-root, couches optimisées et image minimale.

```dockerfile
# ============================================================
# Dockerfile — <Nom de l'application>
# Image de base : Debian Trixie slim (Debian 13, stable depuis le 9 août
# 2025, full support jusqu'au 9 août 2028 puis LTS jusqu'au 30 juin 2030).
# Bookworm (12) reste disponible en oldstable jusqu'au 10 juin 2026, puis
# LTS jusqu'au 30 juin 2028, puis ELTS au-delà (support communautaire payant
# Freexian) — utiliser cette base si besoin de continuité avec un parc
# existant : remplacer "trixie" par "bookworm" dans les deux stages.
# ============================================================

# ---- Stage 1 : Build ----
# Image officielle Go (basée sur Debian Trixie) — fournit go, git et ca-certificates
FROM golang:1.26-trixie AS builder
# Versions notables : Go 1.25 (août 2025), Go 1.26 (10 février 2026, dernière stable).
# Toujours préférer une version supportée par l'amont Go (les deux dernières
# mineures, soit 1.25 et 1.26 en mai 2026). Variante Bookworm disponible :
# golang:1.26-bookworm.

# Éviter les interactions pendant l'installation
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /build

# Copier d'abord les fichiers de dépendances (cache Docker optimisé)
COPY go.mod go.sum ./  
RUN go mod download  

# Copier le reste du code source
COPY . .

# Compilation statique (CGO désactivé pour produire un binaire portable, sans dépendance libc)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/myapp .

# ---- Stage 2 : Runtime ----
FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive

# Installer uniquement les dépendances d'exécution
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid 1000 --no-create-home --shell /usr/sbin/nologin appuser

# Créer les répertoires nécessaires
RUN mkdir -p /app /var/lib/myapp /var/log/myapp && \
    chown -R appuser:appuser /app /var/lib/myapp /var/log/myapp

# Copier le binaire depuis le stage de build
COPY --from=builder --chown=appuser:appuser /app/myapp /app/myapp

# Passer en utilisateur non-root
USER appuser:appuser  
WORKDIR /app  

# Port exposé (documentation)
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/app/myapp", "healthcheck"]

# Point d'entrée via tini (gestion correcte des signaux)
ENTRYPOINT ["tini", "--"]  
CMD ["/app/myapp", "--config", "/etc/myapp/config.yaml"]  
```

Points clés de ce template : le multi-stage build réduit la taille de l'image finale en excluant les outils de compilation. Les fichiers de dépendances sont copiés avant le code source pour exploiter le cache Docker. L'utilisation de `tini` comme init process assure la propagation correcte des signaux et le nettoyage des processus zombies. Le `HEALTHCHECK` intégré permet à Docker et aux orchestrateurs de surveiller la santé du conteneur.

### 2.4 Template Kubernetes — Application complète

Ce template regroupe les ressources Kubernetes nécessaires au déploiement d'une application en production : Namespace, ConfigMap, Secret, Deployment, Service, Ingress et HPA.

```yaml
# namespace.yaml
apiVersion: v1  
kind: Namespace  
metadata:  
  name: <app-namespace>
  labels:
    app.kubernetes.io/part-of: <app-name>
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
---
# configmap.yaml
apiVersion: v1  
kind: ConfigMap  
metadata:  
  name: <app-name>-config
  namespace: <app-namespace>
  labels:
    app.kubernetes.io/name: <app-name>
data:
  config.yaml: |
    server:
      port: 8080
      read_timeout: 30s
      write_timeout: 30s
    log:
      level: info
      format: json
---
# deployment.yaml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: <app-name>
  namespace: <app-namespace>
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/version: "<version>"
    app.kubernetes.io/component: server
    app.kubernetes.io/managed-by: kubectl
spec:
  replicas: 2
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: <app-name>
  template:
    metadata:
      labels:
        app.kubernetes.io/name: <app-name>
        app.kubernetes.io/version: "<version>"
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: <app-name>
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: <app-name>
          image: <registry>/<app-name>:<version>
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: <app-name>-secrets
                  key: database-url
          envFrom:
            - configMapRef:
                name: <app-name>-env
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 3
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
          startupProbe:
            httpGet:
              path: /healthz
              port: http
            periodSeconds: 5
            failureThreshold: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: config
              mountPath: /etc/myapp
              readOnly: true
      volumes:
        - name: tmp
          emptyDir:
            sizeLimit: 100Mi
        - name: config
          configMap:
            name: <app-name>-config
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: <app-name>
---
# service.yaml
apiVersion: v1  
kind: Service  
metadata:  
  name: <app-name>
  namespace: <app-namespace>
  labels:
    app.kubernetes.io/name: <app-name>
spec:
  type: ClusterIP
  ports:
    - name: http
      port: 80
      targetPort: http
      protocol: TCP
  selector:
    app.kubernetes.io/name: <app-name>
---
# ingress.yaml
apiVersion: networking.k8s.io/v1  
kind: Ingress  
metadata:  
  name: <app-name>
  namespace: <app-namespace>
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - <domaine>
      secretName: <app-name>-tls
  rules:
    - host: <domaine>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <app-name>
                port:
                  name: http
---
# hpa.yaml
apiVersion: autoscaling/v2  
kind: HorizontalPodAutoscaler  
metadata:  
  name: <app-name>
  namespace: <app-namespace>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <app-name>
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 120
```

Ce template utilise les labels recommandés par Kubernetes (`app.kubernetes.io/*`), intègre les trois types de probes (liveness, readiness, startup), applique le Pod Security Standard `restricted`, active le scraping Prometheus via annotations, et configure l'autoscaling avec des policies de montée et descente en charge adaptées.

### 2.5 Template Ansible — Rôle de déploiement

L'arborescence standard d'un rôle Ansible suit une convention stricte qui garantit la lisibilité et la réutilisabilité.

```
roles/webserver/
├── defaults/
│   └── main.yaml          # Variables par défaut (priorité la plus basse)
├── vars/
│   └── main.yaml          # Variables internes du rôle
├── tasks/
│   ├── main.yaml          # Point d'entrée des tâches
│   ├── install.yaml        # Installation des paquets
│   ├── configure.yaml      # Déploiement de la configuration
│   ├── security.yaml       # Durcissement
│   └── service.yaml        # Gestion du service
├── handlers/
│   └── main.yaml          # Handlers (rechargement, redémarrage)
├── templates/
│   ├── nginx-vhost.conf.j2
│   └── security-headers.conf.j2
├── files/
│   └── 50x.html           # Fichiers statiques
├── meta/
│   └── main.yaml          # Métadonnées et dépendances
└── molecule/               # Tests du rôle
    └── default/
        ├── molecule.yml
        └── verify.yml
```

```yaml
# roles/webserver/defaults/main.yaml
---
webserver_package: nginx  
webserver_user: www-data  
webserver_port_http: 80  
webserver_port_https: 443  
webserver_ssl_protocols: "TLSv1.2 TLSv1.3"  
webserver_client_max_body_size: "50M"  
webserver_worker_processes: auto  
webserver_worker_connections: 1024  
webserver_keepalive_timeout: 65  
webserver_gzip: true  
webserver_server_tokens: false  
webserver_sites: []  
```

```yaml
# roles/webserver/tasks/main.yaml
---
- name: Inclure les tâches d'installation
  ansible.builtin.include_tasks: install.yaml
  tags: [install]

- name: Inclure les tâches de configuration
  ansible.builtin.include_tasks: configure.yaml
  tags: [configure]

- name: Inclure les tâches de sécurité
  ansible.builtin.include_tasks: security.yaml
  tags: [security]

- name: Inclure la gestion du service
  ansible.builtin.include_tasks: service.yaml
  tags: [service]
```

```yaml
# roles/webserver/tasks/configure.yaml
---
- name: Déployer la configuration principale Nginx
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    backup: true
    validate: nginx -t -c %s
  notify: Recharger Nginx

- name: Déployer les virtual hosts
  ansible.builtin.template:
    src: nginx-vhost.conf.j2
    dest: "/etc/nginx/sites-available/{{ item.domain }}.conf"
    owner: root
    group: root
    mode: '0644'
    validate: nginx -t -c %s
  loop: "{{ webserver_sites }}"
  loop_control:
    label: "{{ item.domain }}"
  notify: Recharger Nginx

- name: Activer les virtual hosts
  ansible.builtin.file:
    src: "/etc/nginx/sites-available/{{ item.domain }}.conf"
    dest: "/etc/nginx/sites-enabled/{{ item.domain }}.conf"
    state: link
  loop: "{{ webserver_sites }}"
  loop_control:
    label: "{{ item.domain }}"
  notify: Recharger Nginx

- name: Supprimer le site par défaut
  ansible.builtin.file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: Recharger Nginx
```

```yaml
# roles/webserver/handlers/main.yaml
---
- name: Recharger Nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded

- name: Redémarrer Nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
```

```yaml
# roles/webserver/meta/main.yaml
---
galaxy_info:
  role_name: webserver
  author: Équipe Infrastructure
  description: Installation et configuration de Nginx sur Debian
  license: MIT
  min_ansible_version: "2.15"
  platforms:
    - name: Debian
      versions:
        - bookworm
        - trixie

dependencies:
  - role: common
  - role: firewall
```

### 2.6 Template Terraform — Module réutilisable

Un module Terraform bien structuré sépare les entrées (variables), les ressources et les sorties dans des fichiers distincts.

```
modules/debian-server/
├── main.tf              # Ressources principales
├── variables.tf         # Déclaration des variables
├── outputs.tf           # Valeurs de sortie
├── versions.tf          # Contraintes de version
├── data.tf              # Data sources
└── README.md            # Documentation du module
```

```hcl
# modules/debian-server/versions.tf
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

```hcl
# modules/debian-server/variables.tf
variable "name" {
  type        = string
  description = "Nom de l'instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "Type d'instance EC2"
}

variable "subnet_id" {
  type        = string
  description = "ID du subnet de déploiement"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Liste des security groups à associer"
}

variable "key_name" {
  type        = string
  description = "Nom de la keypair SSH"
}

variable "volume_size" {
  type        = number
  default     = 20
  description = "Taille du volume root en Go"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags supplémentaires"
}
```

```hcl
# modules/debian-server/data.tf
data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]   # Trixie ; "debian-12-amd64-*" pour Bookworm
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"]          # ID officiel du compte Debian sur AWS
}
```

```hcl
# modules/debian-server/main.tf
resource "aws_instance" "this" {
  ami                    = data.aws_ami.debian.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"         # IMDSv2 obligatoire (sécurité)
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  lifecycle {
    create_before_destroy = true
  }
}
```

```hcl
# modules/debian-server/outputs.tf
output "instance_id" {
  value       = aws_instance.this.id
  description = "ID de l'instance EC2"
}

output "private_ip" {
  value       = aws_instance.this.private_ip
  description = "Adresse IP privée"
}

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "Adresse IP publique (si applicable)"
}
```

L'appel du module depuis la configuration principale se fait de manière concise.

```hcl
# environments/production/main.tf
module "web_server" {
  source   = "../../modules/debian-server"
  for_each = toset(["web-01", "web-02"])

  name               = "${local.prefix}-${each.key}"
  instance_type      = "t3.medium"
  subnet_id          = module.vpc.private_subnets[index(tolist(toset(["web-01", "web-02"])), each.key)]
  security_group_ids = [module.sg.web_sg_id]
  key_name           = aws_key_pair.deploy.key_name
  volume_size        = 40

  tags = {
    Role        = "webserver"
    Environment = "production"
  }
}
```

### 2.7 Template Helm — values.yaml de production

Ce template illustre l'organisation d'un fichier de valeurs pour un chart Helm en production, avec les sections les plus fréquentes.

```yaml
# values-production.yaml — Overrides de production pour le chart <app>

# Réplicas et stratégie de déploiement
replicaCount: 3

image:
  repository: registry.example.com/<app>
  tag: "1.5.0"
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: registry-credentials

# Ressources
resources:
  requests:
    cpu: 200m
    memory: 256Mi
  limits:
    cpu: "1"
    memory: 1Gi

# Autoscaling
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 15
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

# Service
service:
  type: ClusterIP
  port: 80

# Ingress
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com

# Configuration applicative
config:
  logLevel: info
  logFormat: json

# Probes
livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 15
  periodSeconds: 20

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10

# Sécurité
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]

# Affinité et distribution
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule

# Monitoring
serviceMonitor:
  enabled: true
  interval: 15s
  path: /metrics

# Pod Disruption Budget
podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

---

## Partie 3 — Organisation et arborescence de projet

### 3.1 Arborescence d'un projet IaC complet

L'organisation recommandée pour un projet combinant Terraform et Ansible dans un workflow multi-environnement suit une structure claire.

```
infrastructure/
├── README.md                          # Documentation du projet
├── Makefile                           # Commandes d'automatisation
│
├── terraform/
│   ├── modules/                       # Modules réutilisables
│   │   ├── network/
│   │   ├── compute/
│   │   └── database/
│   ├── environments/
│   │   ├── production/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── terraform.tfvars       # Valeurs de production
│   │   │   └── backend.tf
│   │   └── staging/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       └── backend.tf
│   └── shared/                        # Configuration partagée
│       └── providers.tf
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── production/
│   │   │   ├── hosts.yaml
│   │   │   ├── group_vars/
│   │   │   │   ├── all.yaml
│   │   │   │   ├── webservers.yaml
│   │   │   │   └── dbservers.yaml
│   │   │   └── host_vars/
│   │   └── staging/
│   │       └── ...
│   ├── playbooks/
│   │   ├── site.yaml                  # Playbook principal
│   │   ├── deploy.yaml                # Déploiement applicatif
│   │   └── security.yaml              # Hardening
│   ├── roles/
│   │   ├── common/
│   │   ├── webserver/
│   │   ├── database/
│   │   └── monitoring/
│   └── collections/
│       └── requirements.yaml
│
├── kubernetes/
│   ├── base/                          # Configuration commune (Kustomize)
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── overlays/                      # Overrides par environnement
│       ├── production/
│       │   ├── kustomization.yaml
│       │   ├── replica-patch.yaml
│       │   └── resource-patch.yaml
│       └── staging/
│           ├── kustomization.yaml
│           └── replica-patch.yaml
│
├── docker/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── compose.yaml
│
├── scripts/                           # Scripts utilitaires
│   ├── backup.sh
│   ├── restore.sh
│   └── healthcheck.sh
│
├── docs/                              # Documentation complémentaire
│   ├── architecture.md
│   ├── runbooks/
│   └── adr/                           # Architecture Decision Records
│
└── .github/                           # ou .gitlab-ci.yml
    └── workflows/
        ├── terraform.yaml
        ├── ansible-lint.yaml
        └── docker-build.yaml
```

### 3.2 Fichier .gitignore pour l'infrastructure

```gitignore
# Terraform
**/.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log  
override.tf  
override.tf.json  
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Ansible
*.retry
ansible/inventory/*/host_vars/*/vault.yaml

# Secrets
*.pem
*.key
.env
.env.*
!.env.example
**/secrets/
*.vault.yaml

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
```

### 3.3 Makefile d'automatisation

Un Makefile simplifie l'exécution des commandes courantes et uniformise les workflows entre les membres de l'équipe.

```makefile
# Makefile — Commandes d'infrastructure

.PHONY: help plan apply destroy lint test

ENVIRONMENT ?= staging  
TF_DIR = terraform/environments/$(ENVIRONMENT)  
ANSIBLE_DIR = ansible  
INVENTORY = $(ANSIBLE_DIR)/inventory/$(ENVIRONMENT)/hosts.yaml  

help: ## Afficher l'aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Terraform ---

tf-init: ## Initialiser Terraform
	cd $(TF_DIR) && terraform init

tf-plan: ## Planifier les changements Terraform
	cd $(TF_DIR) && terraform plan -out=plan.tfplan

tf-apply: ## Appliquer le plan Terraform
	cd $(TF_DIR) && terraform apply plan.tfplan

tf-destroy: ## Détruire l'infrastructure
	cd $(TF_DIR) && terraform destroy

# --- Ansible ---

ansible-check: ## Vérifier le playbook (dry-run)
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yaml \
		-i $(INVENTORY) --check --diff

ansible-deploy: ## Déployer la configuration
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yaml \
		-i $(INVENTORY) --diff

ansible-security: ## Appliquer le hardening
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/security.yaml \
		-i $(INVENTORY) --diff

# --- Qualité ---

lint: ## Linter tous les fichiers
	cd $(TF_DIR) && terraform fmt -check -recursive
	cd $(TF_DIR) && terraform validate
	cd $(ANSIBLE_DIR) && ansible-lint playbooks/ roles/
	hadolint docker/Dockerfile

test: ## Exécuter les tests
	cd $(ANSIBLE_DIR)/roles/webserver && molecule test
	cd $(TF_DIR) && terraform plan -detailed-exitcode
```

---

## Partie 4 — Checklist de mise en production

Avant de mettre un service en production sur un système Debian, les points suivants doivent être vérifiés systématiquement.

En matière de **configuration**, chaque fichier modifié a été validé par la commande de vérification du service, un backup ou un commit etckeeper a été réalisé avant la modification, les permissions des fichiers sensibles sont restrictives et le service a été rechargé (et non redémarré) quand c'est possible.

Pour la **sécurité**, le service tourne avec un utilisateur dédié non-root, les ports exposés sont limités au strict nécessaire, le pare-feu autorise uniquement le trafic attendu, les certificats TLS sont en place et le renouvellement automatique est vérifié, et les secrets ne sont pas stockés en clair dans les fichiers de configuration versionnés.

Concernant l'**observabilité**, les logs du service sont collectés (journald ou fichier avec logrotate), les métriques sont exposées et scrapées par Prometheus, des alertes sont configurées pour les cas d'erreur critiques et un healthcheck est en place (systemd watchdog, Docker HEALTHCHECK ou probe Kubernetes).

Pour la **résilience**, le service redémarre automatiquement en cas de crash (`Restart=on-failure` pour systemd, `restart: unless-stopped` pour Docker), les volumes de données sont sauvegardés régulièrement, un test de restauration a été effectué au moins une fois et la procédure de rollback est documentée et testée.

Enfin, en termes de **documentation**, un runbook décrit les opérations courantes et les procédures d'urgence, les fichiers de configuration sont commentés et leur provenance est identifiable, et les changements sont tracés dans l'historique Git (etckeeper ou dépôt IaC).

⏭️ [Troubleshooting par composant](/annexes/C-troubleshooting.md)
