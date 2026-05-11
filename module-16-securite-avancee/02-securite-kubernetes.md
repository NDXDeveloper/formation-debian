🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 16.2 Sécurité Kubernetes

## Prérequis

- Maîtrise de l'administration système Debian durcie (section 16.1)
- Connaissance approfondie de l'architecture Kubernetes (module 11 : architecture, ressources fondamentales, réseau, stockage)
- Expérience opérationnelle d'un cluster Kubernetes en production (module 12 : HA, outils d'écosystème, autoscaling, cycle de vie)
- Familiarité avec les conteneurs et leur sécurité (module 10.5)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre le modèle de menaces spécifique à Kubernetes et identifier les surfaces d'attaque d'un cluster
- Concevoir et appliquer des politiques RBAC respectant le principe du moindre privilège
- Configurer les Pod Security Standards et les admission controllers pour imposer des contraintes de sécurité à l'admission des workloads
- Implémenter le principe de Policy as Code avec OPA Gatekeeper pour valider et imposer des règles personnalisées à l'admission des ressources
- Déployer Falco pour la détection d'anomalies et de menaces en temps réel au runtime
- Mettre en place des Network Policies avancées avec Cilium pour la micro-segmentation du trafic inter-pods (politiques L4/L7, DNS-aware, identity-based)

---

## Introduction

La section 16.1 a couvert le durcissement de Debian en tant que système d'exploitation. Mais dans un cluster Kubernetes, le système hôte n'est qu'une couche parmi d'autres. Kubernetes introduit ses propres abstractions — pods, services, namespaces, service accounts, admission controllers — qui forment un système de sécurité parallèle, avec ses propres vecteurs d'attaque et ses propres mécanismes de défense.

La sécurité d'un cluster Kubernetes ne se réduit pas à la somme de la sécurité de ses nœuds. Un nœud Debian parfaitement durci peut héberger un cluster vulnérable si les politiques Kubernetes sont permissives. Inversement, des politiques Kubernetes rigoureuses ne protègent pas contre un noyau hôte compromis. Les deux niveaux doivent être traités conjointement, et c'est précisément l'articulation de cette section avec la précédente.

## Le modèle de menaces Kubernetes

### Les 4C de la sécurité Cloud-Native

Le modèle des **4C** (*Cloud, Cluster, Container, Code*) est le cadre de référence pour structurer la sécurité dans un environnement Kubernetes. Chaque couche dépend de la sécurité de la couche qui la contient :

```
┌─────────────────────────────────────────────────────────────┐
│                         CLOUD                               │
│  Infrastructure sous-jacente (datacenter, cloud provider)   │
│  Réseau physique, hyperviseur, IAM, chiffrement disque      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                      CLUSTER                        │    │
│  │  API Server, etcd, kubelet, admission controllers   │    │
│  │  RBAC, Network Policies, Pod Security Standards     │    │
│  │                                                     │    │
│  │  ┌──────────────────────────────────────────────┐   │    │
│  │  │                 CONTAINER                    │   │    │
│  │  │  Image de base, vulnérabilités, runtime      │   │    │
│  │  │  Capabilities, seccomp, AppArmor, rootless   │   │    │
│  │  │                                              │   │    │
│  │  │  ┌───────────────────────────────────────┐   │   │    │
│  │  │  │              CODE                     │   │   │    │
│  │  │  │  Dépendances, secrets dans le code    │   │   │    │
│  │  │  │  Injection, authentification, TLS     │   │   │    │
│  │  │  └───────────────────────────────────────┘   │   │    │
│  │  └──────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

La section 16.1 a traité la couche **Cloud** (durcissement de l'OS hôte). Le module 10.5 a traité la couche **Container** (sécurité des conteneurs). La couche **Code** relève du développement applicatif (hors scope de cette formation). Cette section 16.2 se concentre sur la couche **Cluster** — les mécanismes de sécurité propres à Kubernetes.

### Surfaces d'attaque d'un cluster Kubernetes

Un cluster Kubernetes expose de multiples surfaces d'attaque, réparties entre le control plane, les nœuds workers et le plan réseau :

#### API Server — la cible principale

L'API Server (`kube-apiserver`) est le point d'entrée unique de toutes les opérations du cluster. Toute requête — qu'elle provienne de `kubectl`, d'un contrôleur, d'un pod ou d'un webhook — transite par l'API Server. Sa compromission donne un contrôle total sur le cluster. Les vecteurs d'attaque incluent l'exposition de l'API Server sur un réseau non sécurisé, des tokens de service account mal protégés, des certificats TLS faibles ou expirés, et des autorisations RBAC trop permissives.

#### etcd — la mémoire du cluster

etcd stocke l'intégralité de l'état du cluster : configurations, secrets (par défaut en clair ou en base64), état des workloads, tokens de service accounts. Un accès en lecture à etcd expose tous les secrets du cluster. Un accès en écriture permet de modifier arbitrairement l'état du cluster, de créer des pods privilégiés ou de modifier les bindings RBAC. etcd doit être considéré comme l'actif le plus sensible du cluster.

#### kubelet — la porte vers le nœud

Le kubelet est l'agent qui s'exécute sur chaque nœud et gère le cycle de vie des pods. Son API (port 10250) permet d'exécuter des commandes dans les conteneurs, de lire les logs et d'obtenir des informations sur les pods. Un kubelet mal sécurisé (API anonyme activée, absence de vérification des certificats) offre un accès direct aux workloads du nœud.

#### Plan réseau — le trafic inter-pods

Par défaut, Kubernetes adopte un modèle réseau **plat et ouvert** : tout pod peut communiquer avec tout autre pod du cluster, sans restriction. Ce modèle simplifie le développement mais signifie qu'un pod compromis peut scanner, attaquer et communiquer avec tous les autres pods — y compris les bases de données, les caches Redis, les services internes et l'API Server.

#### Workloads — les pods eux-mêmes

Les pods constituent la couche la plus exposée aux attaques applicatives (vulnérabilités dans le code, dépendances compromises, images malveillantes). Un pod compromis peut tenter d'escalader ses privilèges vers le nœud hôte via des montages sensibles (socket Docker, procfs, sysfs), des capabilities excessives ou des conteneurs privilégiés.

### Flux de sécurité à l'admission

Kubernetes implémente un pipeline de sécurité que chaque requête traverse avant d'être persistée dans etcd. Comprendre ce pipeline est essentiel pour savoir où chaque mécanisme de sécurité intervient :

```
Requête (kubectl, contrôleur, pod)
       │
       ▼
┌──────────────────────┐
│   AUTHENTIFICATION   │  Qui fait cette requête ?
│                      │  Certificats X.509, tokens, OIDC
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│    AUTORISATION      │  Cette identité a-t-elle le droit ?
│      (RBAC)          │  Roles, ClusterRoles, Bindings
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ ADMISSION CONTROLLERS│  La requête est-elle conforme ?
│                      │  Mutating → Validating
│  ┌────────────────┐  │
│  │   Mutating     │  │  Modifie la requête (injection de
│  │   Webhooks     │  │  sidecars, valeurs par défaut)
│  └───────┬────────┘  │
│          ▼           │
│  ┌────────────────┐  │
│  │  Validating    │  │  Accepte ou refuse la requête
│  │  Webhooks      │  │  (Pod Security, OPA Gatekeeper)
│  └───────┬────────┘  │
└──────────┼───────────┘
           │
           ▼
┌──────────────────────┐
│   PERSISTANCE        │  Écriture dans etcd
│    (etcd)            │  La ressource existe dans le cluster
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   EXÉCUTION          │  Scheduling, création du pod
│  (kubelet, runtime)  │  Les contrôles runtime s'appliquent
│                      │  (AppArmor, seccomp, Falco)
└──────────────────────┘
```

Les mécanismes couverts dans cette section s'insèrent à quatre points complémentaires :

- **RBAC** (16.2.1) opère à l'étape d'**autorisation**
- **Pod Security Standards et OPA Gatekeeper** (16.2.2 et 16.2.3) opèrent à l'étape d'**admission**
- **Falco** (16.2.4) opère à l'étape d'**exécution** (runtime security)
- **Network Policies** (16.2.5) opèrent au niveau du **plan réseau**, indépendamment du pipeline d'admission

## Principes directeurs de la sécurité Kubernetes

### Moindre privilège par défaut

Le principe du moindre privilège, déjà appliqué au niveau système dans la section 16.1, se décline à chaque couche de Kubernetes :

- **Service accounts** : chaque pod s'exécute sous un service account. Le service account par défaut (`default`) reçoit un token monté automatiquement dans le pod. Ce token, s'il est associé à des permissions RBAC, permet au pod d'interroger l'API Server. La bonne pratique est de désactiver le montage automatique du token et de créer des service accounts dédiés avec des permissions minimales.
- **Capabilities** : un conteneur doit démarrer avec l'ensemble de capabilities le plus restreint possible. La liste par défaut de Docker/containerd est déjà réduite, mais des capabilities comme `NET_RAW` (nécessaire pour `ping` mais exploitable pour le spoofing ARP) restent présentes et doivent être retirées explicitement.
- **Accès au système de fichiers** : les conteneurs doivent s'exécuter avec un système de fichiers racine en lecture seule (`readOnlyRootFilesystem: true`), les volumes d'écriture étant montés uniquement là où c'est nécessaire.
- **Réseau** : la politique réseau par défaut doit être le refus (*deny all*), les flux autorisés étant déclarés explicitement via des Network Policies.

### Défense en profondeur dans le cluster

Comme au niveau système, la sécurité Kubernetes repose sur la superposition de couches indépendantes. L'échec d'une couche ne doit pas compromettre l'ensemble :

```
Couche 1 — RBAC
  Un développeur ne peut créer que des pods dans son namespace
      │
      ▼
Couche 2 — Pod Security Standards
  Les pods ne peuvent pas être privilégiés ni monter le hostPath
      │
      ▼
Couche 3 — OPA Gatekeeper / Policy as Code
  Les images doivent provenir d'un registry approuvé
  Les labels obligatoires sont vérifiés
      │
      ▼
Couche 4 — Network Policies
  Le pod ne peut communiquer qu'avec les services déclarés
      │
      ▼
Couche 5 — Runtime Security (Falco)
  Toute exécution de shell dans un conteneur déclenche une alerte
      │
      ▼
Couche 6 — Sécurité du nœud hôte (section 16.1)
  AppArmor confine le runtime conteneur
  sysctl durci, lockdown mode actif
```

Si un attaquant contourne le RBAC (par exemple via un token volé), les Pod Security Standards l'empêchent de créer un pod privilégié. S'il parvient à déployer un pod, les Network Policies limitent ses communications. S'il exécute des commandes suspectes dans le conteneur, Falco déclenche une alerte. Aucune couche n'est infaillible seule ; c'est leur combinaison qui rend l'exploitation réellement difficile.

### Immutabilité et déclaratif

Kubernetes est un système déclaratif : l'état désiré est décrit en YAML et le cluster converge vers cet état. Cette philosophie s'étend naturellement à la sécurité :

- Les **politiques de sécurité sont déclarées en tant que ressources** Kubernetes (NetworkPolicies, ClusterRoles, Constraints OPA), versionnées dans Git et déployées via GitOps (cf. module 14.4).
- Les **conteneurs sont immutables** : aucune modification en place, pas d'installation de paquets dans un conteneur en cours d'exécution, pas de patching à chaud. Toute modification passe par une reconstruction d'image et un redéploiement.
- Les **secrets sont gérés de manière déclarative** via des opérateurs (External Secrets, Sealed Secrets) plutôt que par des interventions manuelles.

Cette approche déclarative rend l'état de sécurité du cluster auditable, reproductible et réversible — trois propriétés fondamentales pour la conformité.

## La sécurité comme responsabilité partagée

La sécurité Kubernetes n'est pas la responsabilité d'une seule équipe. Elle se distribue entre plusieurs acteurs selon le modèle de responsabilité partagée :

**L'équipe plateforme / SRE** est responsable de la sécurité du cluster lui-même : durcissement des nœuds (section 16.1), configuration du control plane, mise à jour de Kubernetes, déploiement des admission controllers, configuration des Network Policies par défaut, mise en place de la stack d'observabilité sécurité (Falco, audit logs).

**Les équipes de développement** sont responsables de la sécurité de leurs workloads : choix d'images de base sécurisées, gestion des secrets applicatifs, déclaration des security contexts appropriés dans leurs manifestes, définition des Network Policies spécifiques à leurs services.

**L'équipe sécurité** définit les politiques globales (quels registries sont autorisés, quels profils de sécurité sont exigés, quels labels sont obligatoires), audite la conformité et gère la réponse aux incidents.

Les mécanismes décrits dans les sous-sections suivantes outillent ces trois niveaux de responsabilité : le RBAC sépare les permissions, les Pod Security Standards et OPA Gatekeeper imposent les politiques de l'équipe sécurité de manière automatique, les Network Policies permettent aux équipes de développement de déclarer leurs flux, et Falco donne à l'équipe SRE une visibilité sur les comportements anormaux en runtime.

## Plan de la section

Cette section est organisée en cinq sous-parties, chacune couvrant un mécanisme de sécurité à un point spécifique du pipeline :

**16.2.1 — RBAC avancé et least privilege** : conception de politiques RBAC granulaires, service accounts dédiés, audit des permissions excessives, patterns anti-fragiles pour le multi-tenancy.

**16.2.2 — Pod Security Standards et Admission Controllers** : les trois niveaux de restriction (Privileged, Baseline, Restricted), configuration du contrôleur d'admission natif, migration depuis les PodSecurityPolicies obsolètes, personnalisation par namespace.

**16.2.3 — OPA Gatekeeper et Policy as Code** : architecture d'Open Policy Agent, écriture de contraintes en Rego, bibliothèque de politiques Gatekeeper, intégration dans les pipelines CI/CD pour la validation pré-déploiement.

**16.2.4 — Falco (runtime security)** : architecture de détection basée sur les appels système et eBPF, règles par défaut et personnalisation, intégration avec les stacks d'alerting, réponse automatisée aux incidents.

**16.2.5 — Network Policies avancées (Cilium)** : limites des Network Policies natives, capacités avancées de Cilium (politiques L7, DNS-aware, identity-based), micro-segmentation en pratique, observabilité réseau avec Hubble.

---

## Résumé

> La sécurité Kubernetes opère à la couche **Cluster** du modèle 4C, en complément du durcissement système (couche Cloud/OS, section 16.1) et de la sécurité des conteneurs (couche Container, module 10.5). Le modèle de menaces Kubernetes identifie cinq surfaces d'attaque principales : l'API Server (point d'entrée unique), etcd (stockage de tous les secrets et états), le kubelet (accès aux workloads de chaque nœud), le plan réseau plat par défaut (communication sans restriction entre tous les pods) et les workloads eux-mêmes (escalade de privilèges vers l'hôte). La sécurité s'implémente à chaque étape du pipeline d'admission — authentification, autorisation (RBAC), admission (Pod Security Standards, OPA Gatekeeper), exécution (Falco) et réseau (Network Policies) — selon les principes de moindre privilège, de défense en profondeur et d'immutabilité déclarative. Les cinq sous-sections suivantes détaillent la mise en œuvre de chaque mécanisme, de la conception des politiques RBAC à la micro-segmentation réseau avec Cilium.

⏭️ [RBAC avancé et least privilege](/module-16-securite-avancee/02.1-rbac-avance.md)
