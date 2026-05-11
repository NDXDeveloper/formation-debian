# Scripts du Module 19 — Architectures de référence

Ce dossier contient les **artefacts complets** des cinq scénarios  
d'architecture présentés dans le Module 19. Chaque sous-dossier correspond  
à un scénario cohérent, déployable de bout en bout.

Contrairement aux modules thématiques précédents (qui produisaient des  
snippets isolés), le Module 19 présente des **architectures intégrées** —  
l'organisation reflète cette logique pour qu'un lecteur puisse picorer un  
scénario et déployer une plateforme complète.  

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

| Préfixe | Section module 19 | Scénario |
|---------|-------------------|----------|
| `01.1-*` | 19.1.1 — Configuration poste Debian | Poste développeur cloud-native |
| `01.2-*` | 19.1.2 — Environnement Kubernetes local | Poste développeur cloud-native |
| `02.1-*` | 19.2.1 — Conception on-premise/cloud | Infrastructure hybride |
| `02.2-*` | 19.2.2 — Cluster K8s HA Debian | Infrastructure hybride |
| `02.3-*` | 19.2.3 — Services intégrés (DNS/DHCP/...) | Infrastructure hybride |
| `02.4-*` | 19.2.4 — Pipeline CI/CD complet | Infrastructure hybride |
| `02.5-*` | 19.2.5 — Procédures d'exploitation/runbooks | Infrastructure hybride |
| `03.1-*` | 19.3.1 — Plateforme interne (Backstage) | Internal Developer Platform |
| `03.2-*` | 19.3.2 — Self-service portal (Crossplane) | Internal Developer Platform |
| `03.3-*` | 19.3.3 — GitOps workflow complet | Internal Developer Platform |
| `03.4-*` | 19.3.4 — Multi-tenancy & isolation | Internal Developer Platform |
| `04.2-*` | 19.4.2 — Conteneurisation microservices | Migration Legacy → Cloud-Native |
| `04.3-*` | 19.4.3 — Migration zero-downtime | Migration Legacy → Cloud-Native |
| `05.1-*` | 19.5.1 — Multi-région cross-cloud | Disaster Recovery |
| `05.2-*` | 19.5.2 — Chaos engineering | Disaster Recovery |
| `05.4-*` | 19.5.4 — RTO/RPO et dimensionnement | Disaster Recovery |

## Arborescence

```
scripts/
├── README.md                                      # Ce fichier
├── 01-poste-developpeur/
│   ├── ansible/
│   │   ├── 01.1-poste-debian-playbook.yml         # Playbook principal
│   │   └── 01.1-role-kubernetes-tasks.yml         # Rôle outils K8s (kubectl, kind, k9s)
│   ├── dotfiles/
│   │   ├── 01.1-starship.toml                     # Prompt cloud-native
│   │   ├── 01.1-tmux.conf                         # Multiplexeur productivité
│   │   └── 01.1-aliases.sh                        # Alias k=kubectl, gs=git status…
│   ├── kind-configs/
│   │   ├── 01.2-kind-multi-node.yaml              # Cluster 1 cp + 2 workers
│   │   └── 01.2-kind-with-ingress.yaml            # Cluster avec ports 80/443
│   ├── skaffold/
│   │   └── 01.2-skaffold-dev.yaml                 # Workflow build→deploy→tail
│   └── tilt/
│       └── 01.2-Tiltfile                          # Workflow Tilt (Starlark)
├── 02-infrastructure-hybride/
│   ├── network/
│   │   ├── 02.1-wg-cloud.conf                     # WireGuard tunnel on-prem ↔ cloud
│   │   ├── 02.2-haproxy.cfg                       # LB API K8s (cp-1, cp-2, cp-3)
│   │   ├── 02.2-keepalived-cp-1.conf              # VRRP MASTER (priority 110)
│   │   ├── 02.2-keepalived-cp-2.conf              # VRRP BACKUP (priority 105)
│   │   ├── 02.2-keepalived-cp-3.conf              # VRRP BACKUP (priority 100)
│   │   ├── 02.3-bind-named.conf.options           # DNS autoritaire — options
│   │   ├── 02.3-bind-named.conf.local             # DNS autoritaire — zones
│   │   └── 02.3-kea-dhcp4.conf                    # DHCP avec DDNS vers BIND
│   ├── kubernetes/
│   │   ├── 02.2-kubeadm-init.yaml                 # ClusterConfig kubeadm v1beta4
│   │   └── 02.2-metallb-config.yaml               # IPAddressPool + L2Advertisement
│   ├── gitlab-ci/
│   │   └── 02.4-pipeline-app.gitlab-ci.yml        # Pipeline complet Go (lint/build/test)
│   └── runbooks/
│       ├── 02.5-RB-001-mise-a-jour-noeuds-debian.md
│       ├── 02.5-RB-002-sauvegarde-etcd.md
│       ├── 02.5-RB-101-noeud-notready.md
│       └── 02.5-script-drain-update-node.sh       # Script associé à RB-001
├── 03-platform-engineering/
│   ├── backstage/
│   │   └── 03.1-catalog-info-api-commandes.yaml   # Catalog entry API Component
│   ├── crossplane/
│   │   ├── 03.2-xrd-database.yaml                 # XRD XDatabase (engine + size)
│   │   └── 03.2-database-claim-example.yaml       # Claim consommé par dev
│   ├── argocd/
│   │   └── 03.3-applicationset-all-envs.yaml      # ApplicationSet git/directories
│   └── multi-tenancy/
│       ├── 03.4-networkpolicy-default-deny.yaml   # Isolation intra-tenant
│       ├── 03.4-resourcequota-tenant.yaml         # Quotas par namespace
│       └── 03.4-kyverno-disallow-root.yaml        # ClusterPolicy disallow root (failureAction 1.13+)
├── 04-migration-cloud-native/
│   ├── containerization/
│   │   └── 04.2-gestcom.Dockerfile                # Multi-stage PHP/Symfony Trixie
│   ├── k8s-manifests/
│   │   ├── 04.2-gestcom-deployment.yaml           # Deployment + 3 probes (startup essentielle)
│   │   └── 04.2-gestcom-hpa.yaml                  # HPA CPU+RAM avec behavior asymétrique
│   └── migration-scripts/
│       └── 04.3-decommission-legacy-gestcom.sh    # Backup final + arrêt services legacy
└── 05-disaster-recovery/
    ├── multi-region/
    │   ├── 05.1-velero-schedule-critical.yaml     # 2 schedules (critical /6h + full /jour)
    │   └── 05.1-files-sync-to-s3.sh               # rclone sync PVC → S3
    ├── chaos/
    │   ├── 05.2-exp-01-pod-kill.yaml              # PodChaos action: pod-kill
    │   └── 05.2-exp-02-network-latency-db.yaml    # NetworkChaos delay 200ms vers DB
    └── tests-restore/
        └── 05.4-test-restore-integrated-gestcom.sh # Test RTO bout en bout
```

## Scénarios d'architecture

### 🖥️ Scénario 1 — Poste développeur cloud-native

**Objectif** : provisionner en une commande un poste Debian 13 prêt pour
le développement cloud-native (Go/Python, Kubernetes, Docker, Git, IDE).

**Fichiers** : `01-poste-developpeur/`

**Ordre de déploiement** :
1. Bootstrap Debian 13 minimal (installation manuelle classique)
2. Cloner ce dépôt et exécuter le playbook Ansible :
   ```bash
   cd scripts/01-poste-developpeur/ansible/
   ansible-playbook -i inventory/localhost.yml 01.1-poste-debian-playbook.yml --ask-become-pass
   ```
3. Source les dotfiles dans `~/.bashrc` :
   ```bash
   ln -sf $PWD/../dotfiles/01.1-aliases.sh ~/.aliases
   ln -sf $PWD/../dotfiles/01.1-tmux.conf ~/.tmux.conf
   mkdir -p ~/.config && ln -sf $PWD/../dotfiles/01.1-starship.toml ~/.config/starship.toml
   echo '[ -f ~/.aliases ] && source ~/.aliases' >> ~/.bashrc
   ```
4. Créer un cluster Kind multi-node :
   ```bash
   kind create cluster --config 01.2-kind-multi-node.yaml
   # ou avec ingress mappé :
   kind create cluster --config 01.2-kind-with-ingress.yaml
   ```
5. Lancer la boucle dev avec Skaffold ou Tilt depuis ton projet applicatif.

**Pointeurs module** : 19.1.1, 19.1.2, 19.1.3

### 🏢 Scénario 2 — Infrastructure hybride GestCom

**Objectif** : infrastructure on-premise complète (3 control-planes K8s HA
+ services DNS/DHCP/mail) interconnectée avec un cloud public via
WireGuard, le tout opéré via runbooks documentés.

```
   On-premise                                Cloud
   ┌─────────────────────┐                ┌────────────┐
   │  cp-1, cp-2, cp-3   │                │  Backup    │
   │  (kubeadm + HAProxy │                │  Velero S3 │
   │   + Keepalived VIP) │◄──WireGuard───►│            │
   │                     │                │            │
   │  + BIND, Kea, MetalLB                │            │
   └─────────────────────┘                └────────────┘
```

**Fichiers** : `02-infrastructure-hybride/`

**Ordre de déploiement** :
1. **Réseau** : appliquer `02.1-wg-cloud.conf` sur la passerelle, configurer
   BIND9 avec `02.3-bind-named.conf.options` et `02.3-bind-named.conf.local`,
   Kea avec `02.3-kea-dhcp4.conf`.
2. **HA load balancer** : sur chaque control-plane Debian, déployer
   `02.2-haproxy.cfg` (identique) et la `02.2-keepalived-cp-N.conf`
   correspondante.
3. **Cluster** : `kubeadm init --config=02.2-kubeadm-init.yaml --upload-certs`
   sur cp-1, puis `kubeadm join` sur cp-2, cp-3 et les workers.
4. **MetalLB** : `kubectl apply -f 02.2-metallb-config.yaml` après l'install
   du chart Helm.
5. **CI/CD** : commiter `02.4-pipeline-app.gitlab-ci.yml` à la racine du
   dépôt applicatif.
6. **Exploitation** : suivre les runbooks `02.5-RB-001`, `RB-002`, `RB-101`
   selon les besoins.

**Pointeurs module** : 19.2.1 → 19.2.5

**Dépendances entre fichiers** :
- `02.2-keepalived-cp-N.conf` dépend de `02.2-haproxy.cfg` (le script
  `check_haproxy` vérifie qu'il tourne).
- `02.2-kubeadm-init.yaml` dépend de la VIP 10.2.0.100 portée par
  Keepalived (`controlPlaneEndpoint`).
- `02.5-RB-001` utilise `02.5-script-drain-update-node.sh`.

### 🛠️ Scénario 3 — Internal Developer Platform

**Objectif** : exposer aux développeurs une expérience self-service
(catalogue Backstage + provisioning Crossplane) avec déploiements
GitOps automatisés (ArgoCD ApplicationSet) et garde-fous multi-tenant
(NetworkPolicy + Kyverno + ResourceQuota).

**Fichiers** : `03-platform-engineering/`

**Ordre de déploiement** :
1. Déployer Backstage et publier `03.1-catalog-info-api-commandes.yaml`
   à la racine du dépôt de chaque composant.
2. Installer Crossplane + provider Helm/Kubernetes, appliquer
   `03.2-xrd-database.yaml` puis la Composition associée. Les développeurs
   consomment via `03.2-database-claim-example.yaml`.
3. Configurer ArgoCD avec `03.3-applicationset-all-envs.yaml` qui découvre
   automatiquement chaque service × chaque environnement.
4. Activer les garde-fous : `03.4-networkpolicy-default-deny.yaml` (par
   namespace tenant), `03.4-resourcequota-tenant.yaml`, et la ClusterPolicy
   Kyverno `03.4-kyverno-disallow-root.yaml`.

**Pointeurs module** : 19.3.1 → 19.3.4

**Dépendances** :
- `03.2-database-claim-example.yaml` nécessite que le XRD `03.2-xrd-database.yaml`
  soit appliqué et qu'au moins une Composition correspondante existe.
- `03.3-applicationset-all-envs.yaml` suppose la convention
  `apps/<service>/overlays/<env>/` dans le dépôt GitOps.

### 🚀 Scénario 4 — Migration Legacy → Cloud-Native

**Objectif** : migrer une application monolithique GestCom (Symfony,
Apache, PHP, MySQL) vers Kubernetes en zero-downtime, puis décommissionner  
le serveur legacy.  

**Fichiers** : `04-migration-cloud-native/`

**Ordre de déploiement** :
1. **Conteneurisation** : `docker build -f 04.2-gestcom.Dockerfile -t gestcom:dev .`
2. **Manifestes K8s** : `kubectl apply -f 04.2-gestcom-deployment.yaml -f 04.2-gestcom-hpa.yaml`
3. **Migration progressive par paliers** : voir 19.4.3 (Strangler Fig
   pattern, switchover progressif via Nginx upstream weight).
4. **Décommissionnement** : `./04.3-decommission-legacy-gestcom.sh`
   après ≥ 2 semaines de stabilité K8s.

**Pointeurs module** : 19.4.1 → 19.4.4

**Dépendances** :
- Le Deployment dépend des ConfigMap/Secret `gestcom-config`/`gestcom-secrets`
  et du PVC `gestcom-uploads` (à créer séparément).
- Le HPA nécessite metrics-server installé dans le cluster.

### 🛡️ Scénario 5 — Disaster Recovery Multi-Region

**Objectif** : protéger l'infrastructure GestCom contre une perte
totale du datacenter principal (RTO 4h / RPO 1h documentés en 19.5.4).

**Fichiers** : `05-disaster-recovery/`

**Ordre de déploiement** :
1. **Backup multi-région** : installer Velero, appliquer
   `05.1-velero-schedule-critical.yaml`. Synchroniser les fichiers PVC vers
   S3 via `05.1-files-sync-to-s3.sh` (à exécuter via cron quotidien ou
   timer systemd).
2. **Chaos engineering** : exécuter régulièrement les expériences
   `05.2-exp-01-pod-kill.yaml` et `05.2-exp-02-network-latency-db.yaml`
   en staging pour valider la résilience.
3. **Tests de restauration** : exécuter trimestriellement
   `05.4-test-restore-integrated-gestcom.sh` pour mesurer le RTO réel.

**Pointeurs module** : 19.5.1 → 19.5.4

**Dépendances** :
- `05.1-velero-schedule-critical.yaml` suppose `velero install` exécuté
  avec le plugin AWS et un BackupStorageLocation `default` configuré.
- `05.4-test-restore-integrated-gestcom.sh` suppose AWS CLI configuré, GPG
  passphrase dans `/etc/dr/backup-passphrase`, et l'overlay Kustomize
  `k8s-deployments/apps/gestcom/overlays/dr-test/` existant.


## Notes importantes

### Placeholders à substituer

Plusieurs fichiers contiennent des **placeholders explicites** à remplacer  
avant déploiement :  

- `<CLE_PRIVEE_ON_PREMISE>`, `<CLE_PUBLIQUE_CLOUD>` dans `02.1-wg-cloud.conf`
- `GENERER_AVEC_tsig-keygen_dhcp-update-key` dans `02.3-bind-named.conf.local`
  (générer avec `tsig-keygen -a hmac-sha256 dhcp-update-key`)
- `auth_pass VrrPK8sX` dans les configs Keepalived (8 caractères max,
  identique sur les 3 nœuds)
- URLs `internal.example.com`, `apps.internal.example.com`, etc. — adapter
  au domaine de l'organisation

### Conventions héritées des modules précédents

- Cohérence avec corrections déjà appliquées :
  - `debian:trixie-slim` partout (vs bookworm)
  - PHP 8.4 (cycle support actif jusqu'au 31/12/2026)
  - Kubernetes 1.34 (kubeadm v1beta4 : `extraArgs` est une liste)
  - Kyverno 1.13+ : `failureAction` au niveau de la règle
- Chart Bitnami `mysql`/`postgresql` éviter (passé payant 28/08/2025) —
  les fichiers concernés utilisent `mysql:8.4` direct ou pointent vers
  CloudNativePG.

### Runbooks .md

Les fichiers `.md` du dossier `02-infrastructure-hybride/runbooks/` ne  
sont pas du contenu pédagogique mais des **scripts de procédure  
documentée** : checklists exécutables avec des blocs bash à copier.  
Conservés en `.md` pour compatibilité avec les portails opérationnels  
(Backstage TechDocs, MkDocs).

## Prérequis d'utilisation

- **Cluster Kubernetes** : 1.34+ pour kubeadm v1beta4 et VPA `InPlaceOrRecreate`
- **Helm** : v4 pour les charts récents (Crossplane 2.x, Kyverno 1.13+)
- **Velero** : v1.18+ avec plugin AWS
- **Backstage** : @backstage/create-app 0.8+ (Backstage v1.32+)
- **Ansible** : 2.19+ pour `apt_repository` avec `signed-by`
- **Outils dev** : kind v0.31+, Skaffold v2.14+, Tilt v0.33+

## Licence

CC BY 4.0 — Attribution 4.0 International
