🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 14.3 CI/CD sur Kubernetes

## Introduction

La section précédente (14.2) a traité du CI/CD sur des serveurs Debian dédiés : des runners installés comme des services systemd classiques, administrés avec les outils et les pratiques du Parcours 1. Cette approche, éprouvée et parfaitement viable, repose sur des serveurs **persistants** dont l'administrateur gère le cycle de vie complet — installation, configuration, mise à jour, nettoyage, monitoring.

Ce modèle présente cependant des limites à mesure que l'infrastructure CI/CD monte en charge et en complexité :

- **Dimensionnement statique.** Les runners dédiés sont dimensionnés pour le pic de charge. En dehors des heures de pointe, leurs ressources sont inutilisées. À l'inverse, lors d'un pic (release, fin de sprint, merge massif), la capacité fixe crée un goulet d'étranglement.
- **Maintenance des serveurs.** Chaque runner est un serveur à maintenir : mises à jour du système, nettoyage Docker, surveillance de l'espace disque, rotation des certificats. Multiplier les runners, c'est multiplier la charge opérationnelle.
- **Isolation imparfaite.** Sur un runner partagé, même avec le Docker executor, les jobs cohabitent sur le même noyau et partagent les ressources du serveur hôte. Le cache Docker local peut entraîner des contaminations entre projets.
- **Incohérence environnementale.** Les runners dédiés sont des « flocons de neige » — chacun finit par dériver légèrement de la configuration de référence malgré les efforts d'automatisation.

L'alternative naturelle dans un monde cloud-native est de **déplacer l'infrastructure CI/CD dans le cluster Kubernetes lui-même**. Les runners ne sont plus des serveurs persistants mais des **pods éphémères**, créés à la demande pour chaque pipeline ou job, puis détruits. Le cluster Kubernetes gère l'allocation des ressources, le scheduling, l'isolation et le nettoyage — exactement comme il le fait pour n'importe quelle workload applicative.

---

## Le paradigme des runners éphémères

### Principe fondamental

Dans le modèle Kubernetes, un pipeline CI/CD se traduit par une séquence de pods :

1. Un événement Git déclenche un pipeline.
2. Le contrôleur CI/CD (Jenkins, GitLab Runner, Tekton) crée un ou plusieurs pods dans le cluster Kubernetes.
3. Chaque pod exécute un job (build, test, scan, deploy).
4. Les résultats sont transmis à la plateforme CI.
5. Le pod est détruit.

Le pod n'existe que pour la durée du job — quelques secondes à quelques dizaines de minutes. Il n'y a pas de serveur runner à maintenir, pas de disque à nettoyer, pas de cache Docker qui s'accumule.

```
Événement Git (push, MR, tag)
        │
        ▼
┌─────────────────────────────────────────────────┐
│           Plateforme CI/CD                      │
│    (GitLab, GitHub, Jenkins, Tekton)            │
└────────────────────┬────────────────────────────┘
                     │ Crée des pods via l'API K8s
                     ▼
┌─────────────────────────────────────────────────┐
│              Cluster Kubernetes                 │
│                                                 │
│  ┌─────────┐   ┌─────────┐  ┌─────────┐         │
│  │ Pod CI  │   │ Pod CI  │  │ Pod CI  │         │
│  │ (build) │   │ (test)  │  │ (scan)  │         │
│  │         │   │         │  │         │  ...    │
│  │ debian: │   │ python: │  │ trivy:  │         │
│  │ slim    │   │ 3.13    │  │ latest  │         │
│  └────┬────┘   └────┬────┘  └────┬────┘         │
│       │             │            │              │
│       ▼             ▼            ▼              │
│    Terminé       Terminé      Terminé           │
│   (supprimé)    (supprimé)   (supprimé)         │
│                                                 │
│  Nœuds worker Debian 13                         │
└─────────────────────────────────────────────────┘
```

### Bénéfices du modèle éphémère

**Isolation parfaite.** Chaque job s'exécute dans un pod vierge, avec son propre système de fichiers, ses propres processus et son propre réseau. Aucune contamination possible entre les jobs — pas de résidus de build, pas de secrets persistants, pas de cache partagé implicite.

**Élasticité native.** Le cluster Kubernetes alloue les ressources dynamiquement. En période de pointe, des dizaines de pods CI s'exécutent en parallèle ; en période creuse, les ressources sont libérées pour d'autres workloads. Si le cluster utilise un Cluster Autoscaler (section 12.4.3), des nœuds supplémentaires sont provisionnés automatiquement pour absorber la charge CI.

**Zéro maintenance de runners.** Plus de serveurs runner à mettre à jour, plus de disques à nettoyer, plus de Docker daemon à surveiller. La maintenance se réduit à celle du cluster Kubernetes lui-même — une responsabilité que l'équipe assume déjà pour les workloads de production.

**Reproductibilité totale.** L'environnement de chaque job est défini par une image Docker et un manifeste Kubernetes. Deux exécutions du même pipeline utilisent exactement le même environnement, à l'octet près.

**Cohérence avec la production.** Si les applications de l'organisation sont déployées sur Kubernetes, exécuter les pipelines CI/CD sur le même cluster (ou un cluster dédié) garantit une cohérence d'environnement : même version de Kubernetes, même CNI, mêmes network policies, mêmes StorageClasses.

### Limites et contraintes

**Temps de démarrage.** Créer un pod, tirer une image Docker et initialiser l'environnement prend plus de temps que de lancer un job sur un runner pré-provisionné. Ce surcoût, typiquement de 10 à 30 secondes, est acceptable pour la plupart des pipelines mais peut devenir significatif pour des jobs très courts ou très fréquents.

**Complexité d'administration.** Administrer un cluster Kubernetes est intrinsèquement plus complexe qu'administrer un serveur Debian avec un service systemd. Cette approche suppose que l'équipe maîtrise les compétences des Modules 11 et 12.

**Coût du cluster.** Un cluster Kubernetes dédié au CI/CD représente un investissement en infrastructure. L'alternative — utiliser le cluster de production pour les jobs CI — pose des questions d'isolation et de stabilité (un build intensif peut impacter les workloads de production).

**Stockage éphémère.** Le cache de dépendances et le cache Docker ne persistent pas entre les jobs. Des mécanismes de cache distribué (PVC partagé, cache S3, registry de cache Docker) doivent être mis en place pour éviter que chaque job ne télécharge ses dépendances depuis zéro.

**Build d'images Docker.** Construire une image Docker à l'intérieur d'un pod Kubernetes pose les mêmes défis de sécurité que sur un runner Debian (DinD, socket binding), avec la contrainte supplémentaire que le pod n'a pas accès au Docker daemon du nœud. Les solutions sans démon — **BuildKit en mode rootless ou via service distant**, **Buildah rootless** — deviennent quasi obligatoires. Kaniko, longtemps populaire dans ce rôle, a été archivé par Google en juin 2025 et n'est plus recommandé pour de nouveaux déploiements (cf. § 14.2.3).

---

## Architecture : cluster dédié ou cluster partagé ?

### Cluster CI/CD dédié

Un cluster Kubernetes distinct, exclusivement réservé aux workloads CI/CD. Les nœuds worker sont des serveurs Debian optimisés pour les builds (SSD rapides, CPU élevé, RAM abondante).

```
┌──────────────────────┐     ┌──────────────────────┐
│  Cluster CI/CD       │     │  Cluster Production  │
│                      │     │                      │
│  Jobs de build       │────▸│  Applications        │
│  Jobs de test        │     │  Services            │
│  Jobs de scan        │     │  Bases de données    │
│  Pods éphémères      │     │                      │
│                      │     │                      │
│  Nœuds Debian 13     │     │  Nœuds Debian 13     │
└──────────────────────┘     └──────────────────────┘
```

**Avantages** : isolation totale entre CI et production, pas de risque qu'un build intensif dégrade les services en production, possibilité de dimensionner indépendamment.

**Inconvénients** : coût d'infrastructure doublé, deux clusters à administrer.

### Cluster partagé avec isolation par namespace

Le CI/CD s'exécute dans un ou plusieurs namespaces dédiés du cluster de production, avec des mécanismes d'isolation :

- **Resource Quotas** (section 12.2.4) limitant les ressources consommables par le namespace CI.
- **Network Policies** (section 12.2.3) isolant le réseau du namespace CI.
- **Node affinity / taints et tolerations** réservant certains nœuds aux workloads CI.
- **Priority Classes** donnant la priorité aux workloads de production sur les jobs CI.

```yaml
# ResourceQuota pour le namespace CI
apiVersion: v1  
kind: ResourceQuota  
metadata:  
  name: ci-quota
  namespace: ci-runners
spec:
  hard:
    requests.cpu: "16"
    requests.memory: "32Gi"
    limits.cpu: "32"
    limits.memory: "64Gi"
    pods: "30"
```

**Avantages** : un seul cluster à administrer, utilisation optimale des ressources (les nœuds CI sont sous-utilisés en dehors des heures de pointe et peuvent absorber des workloads applicatives).

**Inconvénients** : risque de contention de ressources, complexité des politiques d'isolation, le blast radius d'un incident cluster affecte à la fois la production et le CI.

### Recommandation

Pour les organisations de petite à moyenne taille, le **cluster partagé avec isolation par namespace** offre le meilleur rapport coût/complexité. Pour les organisations de grande taille ou avec des exigences de conformité strictes, un **cluster CI/CD dédié** est préférable.

---

## Les approches couvertes dans cette section

Trois approches de CI/CD sur Kubernetes sont abordées dans les sous-sections suivantes, chacune représentant une philosophie et un niveau de maturité différents :

### Jenkins sur Kubernetes (section 14.3.1)

Jenkins est le système de CI/CD le plus ancien et le plus répandu. Son plugin **Kubernetes** lui permet de provisionner dynamiquement des pods agents dans le cluster. Le contrôleur Jenkins lui-même peut s'exécuter comme un Deployment Kubernetes, avec ses agents éphémères créés et détruits à la demande.

Cette approche est pertinente pour les organisations qui ont une base installée Jenkins conséquente et souhaitent migrer vers Kubernetes sans abandonner leur outillage existant. Elle hérite cependant de la complexité de Jenkins (système de plugins, interface Java, gestion de l'état).

### Tekton Pipelines (section 14.3.2)

Tekton est un framework CI/CD **cloud-native** conçu nativement pour Kubernetes. Les pipelines sont définis comme des **Custom Resources** Kubernetes (Tasks, Pipelines, PipelineRuns). Il n'y a pas de serveur CI central : le contrôleur Tekton surveille les Custom Resources et crée les pods nécessaires. Chaque step d'un pipeline s'exécute dans un conteneur au sein d'un pod.

Tekton représente l'approche la plus « Kubernetes-native » : les pipelines sont des objets Kubernetes à part entière, manipulables avec `kubectl`, versionnables dans Git, et soumis aux mêmes mécanismes de sécurité (RBAC, Network Policies, Pod Security Standards) que les workloads applicatives.

### GitLab CI avec runners Kubernetes (section 14.3.3)

GitLab Runner peut utiliser l'**executor Kubernetes** au lieu de l'executor Docker. Au lieu de lancer un conteneur Docker local pour chaque job, le runner crée un pod Kubernetes. Chaque job GitLab CI devient un pod éphémère dans le cluster.

Cette approche offre la continuité avec l'écosystème GitLab CI (même syntaxe `.gitlab-ci.yml`, mêmes variables, mêmes mécanismes de cache et d'artefacts) tout en bénéficiant de l'élasticité et de l'isolation de Kubernetes.

### Comparaison des approches (section 14.3.4)

La dernière sous-section proposera une comparaison structurée entre les trois approches Kubernetes et le modèle serveur Debian de la section 14.2, avec des critères de choix adaptés aux différents contextes organisationnels.

---

## Concepts Kubernetes transversaux

Quelle que soit l'approche choisie, les concepts Kubernetes suivants sont mobilisés de manière transversale :

### ServiceAccounts et RBAC

Les pods CI/CD ont besoin de permissions Kubernetes pour interagir avec le cluster (déployer des applications, créer des namespaces, manipuler des secrets). Ces permissions sont attribuées via des **ServiceAccounts** dédiés et des rôles RBAC (section 12.2.1) suivant le principe du moindre privilège :

- Un ServiceAccount pour les jobs de build n'a besoin que de lire les secrets du namespace CI et de pousser vers le registry.
- Un ServiceAccount pour les jobs de déploiement a besoin d'appliquer des manifestes dans le namespace cible — mais pas dans tous les namespaces.
- Aucun pod CI ne devrait avoir les permissions `cluster-admin`.

### Persistent Volumes pour le cache

L'éphémérité des pods est un avantage pour l'isolation mais un inconvénient pour les performances. Sans cache persistant, chaque job télécharge ses dépendances (paquets pip, modules npm, images Docker de base) depuis le réseau. Un PersistentVolumeClaim (PVC) partagé en `ReadWriteMany` (ou un cache distribué S3) permet de persister le cache entre les jobs tout en maintenant l'isolation de l'espace de travail.

### Pod Security Standards

Les pods CI/CD doivent être soumis aux mêmes standards de sécurité que les pods applicatifs (section 12.2.2). En particulier :

- Le profil `restricted` interdit les conteneurs privilégiés, les montages hostPath et l'exécution en root — ce qui est compatible avec les outils de build sans démon (BuildKit rootless, Buildah rootless).
- Le profil `baseline` autorise certains conteneurs non-root mais interdit les conteneurs privilégiés.
- Le profil `privileged` est nécessaire pour DinD mais doit être limité à un namespace dédié et strictement contrôlé.

### Network Policies

Les pods CI/CD doivent pouvoir accéder au registry, à la plateforme Git et aux cibles de déploiement, mais pas aux services applicatifs de production ni aux bases de données. Des Network Policies (section 12.2.3) dans le namespace CI définissent précisément les flux réseau autorisés.

---

## Prérequis pour cette section

Cette section suppose la maîtrise des compétences suivantes, acquises dans les modules précédents :

| Module | Compétences requises |
|--------|---------------------|
| **Module 10** — Conteneurs | Docker, construction d'images, registries |
| **Module 11** — Kubernetes fondamentaux | Pods, Deployments, Services, ConfigMaps, Secrets, Namespaces, PV/PVC |
| **Module 12** — Kubernetes production | RBAC, Pod Security Standards, Network Policies, Helm, Kustomize |
| **Module 13** — IaC | Helm charts, manifestes déclaratifs, gestion de l'état |
| **Section 14.1** — Principes CI/CD | Pipelines, stratégies de branching, bonnes pratiques |
| **Section 14.2** — CI/CD sur serveur Debian | GitLab Runner, GitHub Actions (pour la comparaison) |

---

## Plan de la section

- **14.3.1** — Jenkins sur Kubernetes
- **14.3.2** — Tekton Pipelines
- **14.3.3** — GitLab CI avec runners Kubernetes
- **14.3.4** — Comparaison des approches (serveur Debian vs Kubernetes)

---

*La section suivante (14.3.1) abordera le déploiement de Jenkins sur Kubernetes : installation via Helm, configuration du plugin Kubernetes pour le provisionnement dynamique d'agents pods, définition de pod templates, et intégration dans un pipeline Jenkinsfile.*

⏭️ [Jenkins sur Kubernetes](/module-14-cicd-gitops/03.1-jenkins-kubernetes.md)
