# Scripts du Module 14 — CI/CD et GitOps

Cette arborescence regroupe les **pipelines CI/CD et manifestes GitOps  
complets** extraits du Module 14 et organisés par outil. Chaque fichier  
porte un en-tête normalisé identifiant sa section d'origine, et a été  
validé syntaxiquement dans un conteneur Debian 13.  

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

| Préfixe | Section du module | Outil |
|---------|-------------------|-------|
| `01.2-*` | 14.1.2 — Pipelines : conception et bonnes pratiques | Dockerfile, semantic-release |
| `01.3-*` | 14.1.3 — Stratégies de branching et workflows Git | semantic-release |
| `02.1-*` | 14.2.1 — GitLab Runner systemd | runner config, gitlab-ci.yml |
| `02.2-*` | 14.2.2 — GitHub Actions self-hosted | workflows GitHub Actions |
| `02.3-*` | 14.2.3 — Configuration et sécurisation des runners | gitlab-ci.yml, scripts |
| `03.2-*` | 14.3.2 — Tekton Pipelines | Task, Pipeline, PipelineRun |
| `03.3-*` | 14.3.3 — GitLab CI runners K8s | runner-values.yaml, gitlab-ci.yml |
| `04.2-*` | 14.4.2 — ArgoCD | Application, AppProject, ConfigMaps |
| `04.3-*` | 14.4.3 — Flux | GitRepository, Kustomization, HelmRelease |
| `04.4-*` | 14.4.4 — Déploiement multi-environnement | Application, ApplicationSet |
| `04.5-*` | 14.4.5 — Secrets en GitOps | SealedSecret, SOPS, ExternalSecret |

## Arborescence

```
scripts/
├── README.md                                     # Ce fichier
├── 01-cicd-fondamentaux/
│   ├── 01.2-multistage-dockerfile.Dockerfile    # Multi-stage optimisé cache
│   └── 01.3-semantic-release-config.yml         # Versioning automatique
├── 02-gitlab-ci/
│   ├── 02.1-runner-docker-config.toml           # /etc/gitlab-runner/config.toml
│   ├── 02.1-dind-build-image.gitlab-ci.yml      # Build DinD
│   ├── 02.3-build-buildkit-rootless.gitlab-ci.yml  # Build sans privilèges
│   ├── 02.3-vault-oidc-deploy.gitlab-ci.yml     # Secrets Vault via OIDC
│   ├── 03.3-deploy-staging-rbac.gitlab-ci.yml   # Deploy K8s avec SA dédié
│   ├── 03.3-test-integration-services.gitlab-ci.yml  # Tests + PG + Redis
│   ├── runners/
│   │   ├── 02.1-cleanup-timer.systemd           # Timer + service nettoyage
│   │   ├── 02.3-ci-cleanup.sh                   # Script nettoyage CI/CD
│   │   └── 03.3-runner-k8s-values.yaml          # Helm values runner K8s
│   └── templates/
│       └── 03.3-build-gpu-overrides.gitlab-ci.yml  # Overrides KUBERNETES_*
├── 03-github-actions/
│   ├── .github/
│   │   └── actionlint.yaml                      # Config labels self-hosted
│   └── workflows/
│       ├── 02.2-debian-self-hosted.workflow.yml
│       ├── 02.2-test-postgres-services.workflow.yml
│       ├── 02.2-build-push-ghcr.workflow.yml
│       └── 02.2-deploy-environment-protected.workflow.yml
├── 04-tekton/
│   ├── 03.2-rbac-ci-build.yaml                  # SA + Role + RoleBinding
│   ├── 03.2-tekton-pruner.yaml                  # Pruner événementiel
│   ├── tasks/
│   │   └── 03.2-build-and-push-task.yaml        # Task lint + build d'image
│   ├── pipelines/
│   │   └── 03.2-ci-pipeline.yaml                # Pipeline complet 6 Tasks
│   └── runs/
│       ├── 03.2-ci-pipeline-run.yaml            # PipelineRun
│       └── 03.2-gitlab-eventlistener.yaml       # EventListener + Triggers
├── 05-argocd/
│   ├── 04.2-rbac-cm.yaml                        # ConfigMap argocd-rbac-cm
│   ├── applications/
│   │   ├── 04.2-application-staging-kustomize.yaml
│   │   ├── 04.2-app-of-apps-root.yaml           # Pattern App of Apps
│   │   ├── 04.2-app-image-updater.yaml          # Annotations image-updater
│   │   ├── 04.4-app-dev.yaml                    # Une App par environnement
│   │   ├── 04.4-app-staging.yaml
│   │   ├── 04.4-app-production.yaml
│   │   ├── 04.4-applicationset-list-generator.yaml
│   │   └── 04.4-applicationset-git-directory.yaml
│   ├── projects/
│   │   └── 04.2-appproject-team-backend.yaml    # Multi-tenancy
│   └── notifications/
│       └── 04.2-notifications-cm.yaml           # ConfigMap Slack
├── 06-flux/
│   ├── 04.3-gitrepository.yaml                  # Source Git
│   ├── 04.3-kustomization-staging.yaml          # Déploiement staging
│   ├── 04.3-kustomization-dependson.yaml        # Déploiement ordonné
│   ├── 04.3-kustomization-sops.yaml             # Déchiffrement SOPS
│   ├── 04.3-helmrepository-helmrelease.yaml     # Helm natif
│   ├── 04.3-image-automation.yaml               # Image automation
│   └── 04.3-multitenancy-team-backend.yaml      # Multi-tenancy K8s natif
└── 07-secrets-gitops/
    ├── 04.5-sealed-secret-database.yaml         # SealedSecret (placeholder)
    ├── 04.5-sops-config.sops.yaml               # .sops.yaml règles
    ├── 04.5-sops-encrypted-secret.yaml          # Secret chiffré SOPS+age
    ├── 04.5-eso-vault-secretstore.yaml          # ESO SecretStore
    ├── 04.5-eso-vault-externalsecret.yaml       # ESO ExternalSecret
    ├── 04.5-eso-cluster-secretstore.yaml        # ESO ClusterSecretStore
    └── 04.5-pre-commit-hook.sh                  # Hook anti-commit-clair
```

## Index tabulé

### Section 14.1 — Fondamentaux CI/CD

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `01-cicd-fondamentaux/01.2-multistage-dockerfile.Dockerfile` | Multi-stage build optimisé pour le cache | hadolint |
| `01-cicd-fondamentaux/01.3-semantic-release-config.yml` | Versioning automatique via Conventional Commits | yamllint, yaml.safe_load |

### Section 14.2 — CI/CD sur serveur Debian

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `02-gitlab-ci/02.1-runner-docker-config.toml` | Configuration GitLab Runner Docker (2 runners) | python tomllib |
| `02-gitlab-ci/02.1-dind-build-image.gitlab-ci.yml` | Build d'image en mode DinD | yamllint, structure CI |
| `02-gitlab-ci/02.3-build-buildkit-rootless.gitlab-ci.yml` | Build sans privilèges (BuildKit rootless) | yamllint, structure CI |
| `02-gitlab-ci/02.3-vault-oidc-deploy.gitlab-ci.yml` | Récupération secrets Vault via OIDC | yamllint, structure CI |
| `02-gitlab-ci/runners/02.1-cleanup-timer.systemd` | Timer + service nettoyage Docker périodique | inspection visuelle |
| `02-gitlab-ci/runners/02.3-ci-cleanup.sh` | Script de nettoyage CI/CD quotidien | shellcheck |
| `03-github-actions/workflows/02.2-debian-self-hosted.workflow.yml` | Workflow self-hosted minimal | actionlint, yamllint |
| `03-github-actions/workflows/02.2-test-postgres-services.workflow.yml` | Tests avec services PG + Redis | actionlint, yamllint |
| `03-github-actions/workflows/02.2-build-push-ghcr.workflow.yml` | Build + push vers GitHub Container Registry | actionlint, yamllint |
| `03-github-actions/workflows/02.2-deploy-environment-protected.workflow.yml` | Deploy environnement protégé | actionlint, yamllint |
| `03-github-actions/.github/actionlint.yaml` | Config labels self-hosted custom | yamllint |

### Section 14.3 — CI/CD sur Kubernetes

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `02-gitlab-ci/runners/03.3-runner-k8s-values.yaml` | Helm values gitlab/gitlab-runner (executor K8s) | yamllint |
| `02-gitlab-ci/03.3-deploy-staging-rbac.gitlab-ci.yml` | Deploy K8s avec ServiceAccount dédié | yamllint, structure CI |
| `02-gitlab-ci/03.3-test-integration-services.gitlab-ci.yml` | Tests intégration K8s executor | yamllint, structure CI |
| `02-gitlab-ci/templates/03.3-build-gpu-overrides.gitlab-ci.yml` | Overrides KUBERNETES_* (GPU) | yamllint, structure CI |
| `04-tekton/03.2-rbac-ci-build.yaml` | RBAC moindre privilège pour Tasks de build | kubeconform |
| `04-tekton/03.2-tekton-pruner.yaml` | TektonPruner + ConfigMap rétention | kubeconform (CRD partiel) |
| `04-tekton/tasks/03.2-build-and-push-task.yaml` | Task lint + build d'image | kubeconform (CRD Tekton) |
| `04-tekton/pipelines/03.2-ci-pipeline.yaml` | Pipeline complet 6 Tasks (parallélisme + chaînage) | kubeconform (CRD Tekton) |
| `04-tekton/runs/03.2-ci-pipeline-run.yaml` | PipelineRun avec PVC éphémère | kubeconform (CRD Tekton) |
| `04-tekton/runs/03.2-gitlab-eventlistener.yaml` | EventListener + TriggerBinding + TriggerTemplate | kubeconform (CRD Tekton) |

### Section 14.4 — GitOps

| Fichier | Description | Validé par |
|---------|-------------|------------|
| `05-argocd/04.2-rbac-cm.yaml` | Politiques Casbin (admin/dev/ops) | kubeconform |
| `05-argocd/applications/04.2-application-staging-kustomize.yaml` | Application avec auto-sync + self-heal + retry | kubeconform |
| `05-argocd/applications/04.2-app-of-apps-root.yaml` | Pattern App of Apps | kubeconform |
| `05-argocd/applications/04.2-app-image-updater.yaml` | Annotations argocd-image-updater | kubeconform |
| `05-argocd/applications/04.4-app-dev.yaml` | Une Application par environnement (dev) | kubeconform |
| `05-argocd/applications/04.4-app-staging.yaml` | Une Application par environnement (staging) | kubeconform |
| `05-argocd/applications/04.4-app-production.yaml` | Application production (tag fixe, prune false) | kubeconform |
| `05-argocd/applications/04.4-applicationset-list-generator.yaml` | ApplicationSet liste + templatePatch booléen | kubeconform |
| `05-argocd/applications/04.4-applicationset-git-directory.yaml` | ApplicationSet auto-découverte par répertoire | kubeconform |
| `05-argocd/projects/04.2-appproject-team-backend.yaml` | AppProject multi-tenancy | kubeconform |
| `05-argocd/notifications/04.2-notifications-cm.yaml` | ConfigMap notifications Slack | kubeconform |
| `06-flux/04.3-gitrepository.yaml` | Source Git surveillée | kubeconform |
| `06-flux/04.3-kustomization-staging.yaml` | Déploiement avec health checks | kubeconform |
| `06-flux/04.3-kustomization-dependson.yaml` | Déploiement ordonné (infra → apps) | kubeconform |
| `06-flux/04.3-kustomization-sops.yaml` | Déchiffrement SOPS natif | kubeconform |
| `06-flux/04.3-helmrepository-helmrelease.yaml` | Helm natif (helm install/upgrade) | kubeconform |
| `06-flux/04.3-image-automation.yaml` | ImageRepo + Policy + UpdateAutomation | kubeconform |
| `06-flux/04.3-multitenancy-team-backend.yaml` | Multi-tenancy via RBAC K8s | kubeconform |
| `07-secrets-gitops/04.5-sealed-secret-database.yaml` | SealedSecret (placeholder pédagogique) | kubeconform |
| `07-secrets-gitops/04.5-sops-config.sops.yaml` | Règles `.sops.yaml` par chemin | yamllint |
| `07-secrets-gitops/04.5-sops-encrypted-secret.yaml` | Secret K8s chiffré SOPS+age (placeholder) | yamllint |
| `07-secrets-gitops/04.5-eso-vault-secretstore.yaml` | SecretStore Vault | structure manuelle |
| `07-secrets-gitops/04.5-eso-vault-externalsecret.yaml` | ExternalSecret + template Sprig | kubeconform |
| `07-secrets-gitops/04.5-eso-cluster-secretstore.yaml` | ClusterSecretStore Vault | structure manuelle |
| `07-secrets-gitops/04.5-pre-commit-hook.sh` | Hook anti-commit-secret-clair | shellcheck |

## Notes importantes

### Sealed Secrets — placeholders à régénérer

Le fichier `07-secrets-gitops/04.5-sealed-secret-database.yaml` contient  
des valeurs `encryptedData` **fictives**. Un SealedSecret réel est chiffré  
avec la **clé publique d'un cluster spécifique** — copier ce fichier tel  
quel ne fonctionnera PAS sur un autre cluster.  

Pour générer votre propre SealedSecret avec votre clé publique :

```bash
kubectl create secret generic database-credentials \
  --from-literal=username=myapp \
  --from-literal=password='votre-vrai-mot-de-passe' \
  --namespace staging \
  --dry-run=client -o yaml > /tmp/secret.yaml

kubeseal --format yaml < /tmp/secret.yaml > sealed-secret.yaml

rm /tmp/secret.yaml      # Le fichier en clair NE DOIT PAS être commité
```

### SOPS — placeholders à régénérer

De même, `07-secrets-gitops/04.5-sops-encrypted-secret.yaml` contient  
des blocs `ENC[...]` illustratifs. Pour générer un vrai fichier :  

```bash
age-keygen -o age.key  
sops --encrypt --in-place overlays/staging/database.secret.yaml  
```

### Tokens et credentials

Tous les tokens, mots de passe et credentials apparaissent sous forme de  
placeholders : `<RUNNER-AUTH-TOKEN-XXX>`, `glrt-xxxxx`, `glpat-xxxxx`,  
`changeme`. Substituer par les valeurs réelles via Secret K8s, Vault ou
ExternalSecret — **jamais en clair dans Git**.

## Prérequis d'utilisation

- **GitLab Runner sur Debian** : voir Module 14.2.1 pour l'installation
  via dépôt APT (`packages.gitlab.com`).
- **GitHub Actions self-hosted** : voir Module 14.2.2 pour l'installation
  manuelle de l'archive `actions-runner-linux-x64`.
- **Cluster Kubernetes Debian 13** : voir Modules 11-12 pour l'installation
  kubeadm / kubelet sur Debian Trixie.
- **Tekton** : `kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml`
  ou Helm chart `cdf/tekton-pipeline` (Module 14.3.2).
- **ArgoCD** : `kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
  ou Helm chart `argo/argo-cd` (Module 14.4.2).
- **Flux** : `curl -fsSL https://fluxcd.io/install.sh | sudo bash` puis
  `flux bootstrap gitlab|github` (Module 14.4.3).
- **Sealed Secrets** : `kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.36.6/controller.yaml`
- **External Secrets Operator** : `helm install external-secrets external-secrets/external-secrets`
- **SOPS + age** : `apt install age` + binaire SOPS depuis `getsops/sops/releases`

## Licence

CC BY 4.0 — Attribution 4.0 International
