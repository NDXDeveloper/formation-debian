🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 11.3 Ressources fondamentales

## Introduction

Les deux sections précédentes ont posé les fondations : l'architecture du cluster (11.1) et son installation sur Debian (11.2). Le cluster est opérationnel — les nœuds sont en état `Ready`, le CNI est installé, CoreDNS résout les noms. Il est maintenant temps d'apprendre à **utiliser** Kubernetes, c'est-à-dire à déployer et gérer des applications en exploitant les abstractions que la plateforme met à disposition.

Dans Kubernetes, tout est représenté sous forme d'un **objet API** (cf. 11.1.4). Ces objets — appelés **ressources** — sont les briques élémentaires avec lesquelles l'opérateur construit ses architectures applicatives. Certaines ressources gèrent le cycle de vie des conteneurs, d'autres exposent les applications sur le réseau, d'autres encore injectent de la configuration ou des données sensibles. Chaque ressource a un rôle précis et bien délimité, et c'est leur **composition** qui produit des architectures puissantes.

Cette section couvre les ressources fondamentales de Kubernetes — celles que tout opérateur ou développeur utilise quotidiennement, quel que soit le contexte (développement, staging, production).

---

## Le modèle de composition

Kubernetes ne propose pas un objet unique qui fait tout. Il suit une philosophie de **composition** : des ressources simples et spécialisées sont combinées pour construire des architectures complexes. Ce modèle ressemble à la philosophie Unix — « faire une seule chose et la faire bien » — appliquée à l'orchestration de conteneurs.

Le schéma suivant illustre comment les ressources fondamentales s'articulent entre elles :

```
                    ┌───────────────────────────────┐
                    │         Deployment            │
                    │  (stratégie de mise à jour)   │
                    └──────────────┬────────────────┘
                                   │ gère
                                   ▼
                    ┌───────────────────────────────┐
                    │         ReplicaSet            │
                    │  (nombre de réplicas)         │
                    └──────────────┬────────────────┘
                                   │ gère
                                   ▼
              ┌────────────────────┼────────────────────┐
              │                    │                    │
        ┌─────▼──────┐       ┌─────▼──────┐       ┌─────▼──────┐
        │   Pod A    │       │   Pod B    │       │   Pod C    │
        │ ┌────────┐ │       │ ┌────────┐ │       │ ┌────────┐ │
        │ │Cont. 1 │ │       │ │Cont. 1 │ │       │ │Cont. 1 │ │
        │ └────────┘ │       │ └────────┘ │       │ └────────┘ │
        └─────┬──────┘       └─────┬──────┘       └──────┬─────┘
              │                    │                     │
              │         ┌──────────▼──────────┐          │
              └────────►│      Service        │◄─────────┘
                        │   (IP stable, LB)   │
                        └──────────┬──────────┘
                                   │
                         ┌─────────▼──────────┐
                         │    Ingress         │
                         │  (HTTP routing)    │
                         └────────────────────┘

        ┌──────────────┐          ┌──────────────┐
        │  ConfigMap   │          │   Secret     │
        │ (config)     │─────────►│ (données     │──────► montés dans les Pods
        │              │          │  sensibles)  │
        └──────────────┘          └──────────────┘

        ┌──────────────┐          ┌──────────────┐
        │  Namespace   │          │  Job /       │
        │ (isolation   │          │  CronJob     │
        │  logique)    │          │ (tâches)     │
        └──────────────┘          └──────────────┘
```

Chaque couche ajoute une responsabilité :

- Le **Pod** exécute un ou plusieurs conteneurs.
- Le **ReplicaSet** garantit qu'un nombre défini de Pods identiques sont en cours d'exécution.
- Le **Deployment** ajoute la gestion des mises à jour (rolling update, rollback) par-dessus le ReplicaSet.
- Le **Service** fournit une adresse IP stable et un mécanisme de load balancing pour accéder aux Pods.
- Le **ConfigMap** et le **Secret** externalisent la configuration et les données sensibles hors des images de conteneurs.
- Le **Namespace** fournit une isolation logique pour organiser les ressources.
- Le **Job** et le **CronJob** gèrent les tâches à exécution ponctuelle ou planifiée.

En pratique, l'opérateur ne crée presque jamais de Pods directement — il crée un Deployment, qui crée un ReplicaSet, qui crée les Pods. De même, il ne référence presque jamais un Pod par son IP — il crée un Service qui lui fournit une adresse stable. Ce modèle de couches successives est au cœur de l'utilisation quotidienne de Kubernetes.

---

## Structure commune des objets Kubernetes

Toutes les ressources Kubernetes partagent une structure commune, déjà évoquée dans le sous-chapitre 11.1.4, mais qu'il est essentiel de maîtriser avant d'aborder chaque ressource individuellement.

### Les quatre champs de base

Chaque manifeste YAML d'une ressource Kubernetes contient quatre champs de premier niveau :

```yaml
apiVersion: apps/v1              # Groupe et version de l'API  
kind: Deployment                 # Type de ressource  
metadata:                        # Identité et métadonnées  
  name: web-frontend
  namespace: production
  labels:
    app: web
    tier: frontend
  annotations:
    description: "Frontend web de l'application"
spec:                            # État souhaité (déclaratif)
  replicas: 3
  # ...
```

**`apiVersion`** — Identifie le groupe d'API et la version de l'API sous laquelle la ressource est définie. Les ressources de base (Pod, Service, ConfigMap, Secret, Namespace) sont dans le groupe `v1` (core API). Les ressources plus récentes sont dans des groupes nommés : `apps/v1` (Deployment, ReplicaSet, StatefulSet, DaemonSet), `batch/v1` (Job, CronJob), `networking.k8s.io/v1` (Ingress, NetworkPolicy).

**`kind`** — Le type de ressource. Chaque kind correspond à un objet API distinct avec sa propre sémantique, son propre schéma de validation et ses propres contrôleurs.

**`metadata`** — L'identité de l'objet. Les champs les plus importants sont `name` (unique dans un namespace), `namespace` (portée de l'objet), `labels` (paires clé-valeur pour le filtrage et le regroupement) et `annotations` (métadonnées non structurées pour les outils et les humains). D'autres champs sont gérés par le système : `uid` (identifiant universel unique), `resourceVersion` (version pour la concurrence optimiste), `creationTimestamp`, `ownerReferences` (chaîne de propriété).

**`spec`** — L'état souhaité, défini par l'opérateur. La structure du `spec` varie selon le `kind` de la ressource. C'est le cœur du modèle déclaratif : l'opérateur exprime ce qu'il veut, et les contrôleurs Kubernetes se chargent de le réaliser.

Un cinquième champ, **`status`**, est présent sur les objets persistés mais n'est pas spécifié par l'opérateur — il est écrit et maintenu par les contrôleurs Kubernetes pour refléter l'état observé.

### Labels et sélecteurs : le mécanisme de liaison

Les labels sont le mécanisme fondamental par lequel les ressources Kubernetes se référencent mutuellement. Contrairement à un identifiant fixe (comme une clé étrangère dans une base de données relationnelle), les labels permettent un couplage **dynamique** et **multi-dimensionnel** :

```yaml
# Un Pod portant des labels
metadata:
  labels:
    app: web
    version: v2
    environment: production
    team: frontend
```

Un Service, un ReplicaSet ou une Network Policy peuvent sélectionner ce Pod via n'importe quelle combinaison de ses labels :

```yaml
# Sélecteur dans un Service
spec:
  selector:
    app: web                    # Sélectionne tous les Pods avec app=web
```

```yaml
# Sélecteur dans un ReplicaSet (expression set-based)
spec:
  selector:
    matchExpressions:
      - key: app
        operator: In
        values: [web, api]      # Sélectionne app=web OU app=api
      - key: environment
        operator: NotIn
        values: [staging]       # Exclut environment=staging
```

Cette flexibilité permet de créer des architectures où les relations entre ressources sont définies par des **attributs partagés** plutôt que par des références directes, ce qui facilite le scaling, les mises à jour progressives et la réorganisation des applications.

### Conventions de labels recommandées

Kubernetes propose un ensemble de labels préfixés recommandés pour assurer la cohérence entre les équipes et les outils :

| Label | Description | Exemple |
|-------|-------------|---------|
| `app.kubernetes.io/name` | Nom de l'application | `web-frontend` |
| `app.kubernetes.io/version` | Version de l'application | `v2.1.0` |
| `app.kubernetes.io/component` | Rôle dans l'architecture | `frontend`, `backend`, `database` |
| `app.kubernetes.io/part-of` | Application parente | `e-commerce` |
| `app.kubernetes.io/managed-by` | Outil de gestion | `helm`, `kustomize`, `argocd` |
| `app.kubernetes.io/instance` | Instance de l'application | `web-frontend-prod` |

Ces labels sont des conventions — Kubernetes ne les impose pas — mais ils sont reconnus par de nombreux outils (Helm, ArgoCD, Grafana, Prometheus) et facilitent le filtrage, le monitoring et le troubleshooting.

---

## Ressources namespacées vs ressources cluster-wide

Les ressources Kubernetes se répartissent en deux catégories de portée :

**Ressources namespacées** — Elles existent au sein d'un namespace et leur nom doit être unique dans ce namespace (mais peut être réutilisé dans un autre namespace). La majorité des ressources de travail sont namespacées : Pods, Deployments, Services, ConfigMaps, Secrets, Jobs, CronJobs, Ingress, PersistentVolumeClaims.

**Ressources cluster-wide** — Elles existent au niveau du cluster entier et leur nom doit être globalement unique. Ce sont typiquement les ressources d'infrastructure : Nodes, Namespaces, PersistentVolumes, StorageClasses, ClusterRoles, ClusterRoleBindings, IngressClasses, CustomResourceDefinitions.

Pour vérifier la portée d'un type de ressource :

```bash
# Lister toutes les ressources API avec leur portée
kubectl api-resources --namespaced=true   # Ressources namespacées  
kubectl api-resources --namespaced=false  # Ressources cluster-wide  
```

---

## Interactions avec les ressources

### Les opérations CRUD via kubectl

Toutes les ressources Kubernetes supportent les opérations CRUD (Create, Read, Update, Delete) via `kubectl` :

**Création** — `kubectl apply -f manifest.yaml` (déclaratif, idempotent) ou `kubectl create -f manifest.yaml` (impératif, échoue si existe déjà).

**Lecture** — `kubectl get <type>` (liste), `kubectl get <type> <nom> -o yaml` (détail complet), `kubectl describe <type> <nom>` (vue résumée lisible avec événements).

**Mise à jour** — `kubectl apply -f manifest.yaml` (déclaratif), `kubectl edit <type> <nom>` (éditeur interactif), `kubectl patch <type> <nom> -p '{...}'` (modification ciblée).

**Suppression** — `kubectl delete <type> <nom>` ou `kubectl delete -f manifest.yaml`.

### Formats de sortie

kubectl supporte plusieurs formats de sortie pour s'adapter aux besoins :

```bash
# Tableau par défaut
kubectl get pods

# YAML complet (utile pour comprendre la structure ou sauvegarder)
kubectl get pod my-pod -o yaml

# JSON (utile pour le traitement avec jq)
kubectl get pods -o json | jq '.items[].metadata.name'

# Colonnes personnalisées
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# JSONPath (extraction ciblée)
kubectl get pod my-pod -o jsonpath='{.status.podIP}'

# Wide (colonnes supplémentaires : IP, nœud)
kubectl get pods -o wide
```

---

## Ce que vous allez apprendre

Cette section 11.3 est découpée en cinq sous-chapitres qui couvrent les ressources fondamentales dans un ordre progressif :

**11.3.1 — Pods, ReplicaSets, Deployments** : les trois couches qui gèrent le cycle de vie des conteneurs. Du Pod unitaire au Deployment avec rolling updates et rollbacks, en passant par le ReplicaSet qui assure le nombre souhaité de réplicas. Ce sous-chapitre est le plus volumineux car ces trois ressources sont le cœur de toute application Kubernetes.

**11.3.2 — Services (ClusterIP, NodePort, LoadBalancer)** : l'abstraction réseau qui fournit une adresse IP stable et un load balancing vers un ensemble de Pods. Ce sous-chapitre couvre les trois types de Services, la découverte de services par DNS et variables d'environnement, et la gestion du trafic externe.

**11.3.3 — ConfigMaps et Secrets** : l'externalisation de la configuration et des données sensibles. Ce sous-chapitre montre comment injecter des paramètres dans les conteneurs (variables d'environnement, fichiers montés) sans les encoder dans les images, et comment gérer les Secrets avec les précautions appropriées.

**11.3.4 — Namespaces et organisation des ressources** : l'isolation logique au sein du cluster. Ce sous-chapitre couvre la création de namespaces, les quotas de ressources, les LimitRanges, et les stratégies d'organisation multi-équipes ou multi-environnements.

**11.3.5 — Jobs et CronJobs** : la gestion des tâches à exécution unique ou planifiée. Ce sous-chapitre couvre les cas d'usage courants (migrations de base de données, traitements batch, rapports périodiques) et les politiques de retry, de parallélisme et de rétention d'historique.

---

## Prérequis pour cette section

Les compétences suivantes sont directement mobilisées :

- **Architecture Kubernetes** (Section 11.1) : compréhension du modèle déclaratif, des boucles de réconciliation et du rôle de chaque composant.
- **Cluster opérationnel** (Section 11.2) : un cluster Kubernetes fonctionnel sur Debian (kubeadm, K3s ou Kind) avec kubectl configuré.
- **Conteneurs** (Module 10) : compréhension des images, des Dockerfiles, des ports exposés, des variables d'environnement et des volumes.
- **YAML** : maîtrise de la syntaxe YAML (indentation, listes, dictionnaires) qui est le format standard des manifestes Kubernetes.

---

*Dans le sous-chapitre suivant (11.3.1), nous commencerons par les trois ressources les plus fondamentales — Pod, ReplicaSet et Deployment — qui constituent la colonne vertébrale de toute application Kubernetes.*

⏭️ [Pods, ReplicaSets, Deployments](/module-11-kubernetes-fondamentaux/03.1-pods-replicasets-deployments.md)
