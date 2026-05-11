🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 11.1 Architecture et concepts

## Introduction

Kubernetes — souvent abrégé **K8s** (le « 8 » représentant les huit lettres entre le *K* et le *s*) — est un système d'orchestration de conteneurs open source conçu pour automatiser le déploiement, la mise à l'échelle et la gestion d'applications conteneurisées. Conçu par Google et inspiré directement de leur système interne **Borg**, le projet a été annoncé et publié sous licence open source en juin 2014, puis confié à la **Cloud Native Computing Foundation (CNCF)** en juillet 2015 lors de la sortie de la version 1.0. Aujourd'hui sous gouvernance CNCF, Kubernetes constitue la pierre angulaire de l'écosystème cloud-native.

Ce chapitre pose les fondations indispensables à toute exploitation de Kubernetes, qu'il s'agisse d'un cluster de développement local ou d'une infrastructure de production multi-nœuds. Avant de déployer le moindre conteneur, il est essentiel de comprendre **comment** Kubernetes est construit, **pourquoi** il est construit ainsi, et **quels principes** gouvernent son fonctionnement.

---

## Pourquoi Kubernetes ?

L'adoption massive des conteneurs (cf. Module 10) a résolu le problème de la portabilité des applications, mais a introduit de nouveaux défis dès lors que l'on passe à l'échelle :

- **Placement** : sur quel nœud déployer chaque conteneur en fonction des ressources disponibles ?
- **Disponibilité** : comment garantir qu'une application reste accessible si un nœud ou un conteneur tombe en panne ?
- **Mise à l'échelle** : comment augmenter ou réduire le nombre d'instances d'une application en fonction de la charge ?
- **Mise à jour** : comment déployer une nouvelle version sans interruption de service ?
- **Découverte de services** : comment permettre aux conteneurs de se trouver et de communiquer entre eux dans un environnement dynamique ?
- **Gestion de la configuration et des secrets** : comment injecter des paramètres et des données sensibles de manière sécurisée ?

Docker Compose ou un simple script shell suffisent pour orchestrer quelques conteneurs sur une seule machine. Mais dès que l'infrastructure s'étend à plusieurs serveurs, ces approches atteignent leurs limites. C'est précisément le rôle de Kubernetes : fournir une **plateforme d'orchestration distribuée** capable de gérer des centaines, voire des milliers de conteneurs répartis sur un parc de machines.

---

## Origines et filiation

Kubernetes n'est pas né dans un vide technologique. Son architecture s'inscrit dans une lignée directe :

**Borg et Omega (Google, 2003–2013)** — Pendant plus d'une décennie, Google a exploité en interne des systèmes d'orchestration de conteneurs à très grande échelle. Borg gérait l'ensemble des workloads de production de Google (Search, Gmail, Maps…). Les leçons tirées de Borg et de son successeur expérimental Omega ont directement influencé la conception de Kubernetes, notamment le modèle déclaratif, le concept de labels et la boucle de réconciliation.

**Kubernetes 1.0 (21 juillet 2015)** — Google publie la première version stable et confie simultanément le projet à la CNCF, alors nouvellement créée comme branche de la Linux Foundation. Ce geste fondateur garantit la neutralité du projet vis-à-vis des fournisseurs cloud et favorise l'émergence d'un écosystème ouvert.

**Aujourd'hui** — Kubernetes est devenu le standard *de facto* de l'orchestration de conteneurs. Il est proposé en tant que service managé par tous les grands cloud providers (EKS chez AWS, GKE chez Google Cloud, AKS chez Azure) et s'installe également on-premise, notamment sur des serveurs Debian, ce qui sera notre fil conducteur tout au long de ce module.

---

## Les grands principes architecturaux

Avant d'entrer dans le détail de chaque composant, il est important de saisir les principes fondamentaux qui structurent l'ensemble de l'architecture Kubernetes.

### Architecture client-serveur distribuée

Kubernetes repose sur une séparation claire entre un **plan de contrôle** (*control plane*) et des **nœuds de travail** (*worker nodes*). Le plan de contrôle prend les décisions globales concernant le cluster (ordonnancement, détection de pannes, mise à l'échelle), tandis que les nœuds de travail exécutent effectivement les conteneurs applicatifs. Cette séparation permet de dimensionner indépendamment la capacité de gestion et la capacité d'exécution.

### Le modèle déclaratif

Contrairement à une approche impérative où l'on indique étape par étape *comment* atteindre un état (« démarre 3 conteneurs, puis configure le réseau, puis… »), Kubernetes adopte un modèle **déclaratif** : l'opérateur décrit l'**état souhaité** du système (« je veux 3 réplicas de mon application, exposés sur le port 443 avec un certificat TLS »), et Kubernetes se charge en permanence de faire converger l'état réel vers cet état souhaité. Ce principe est au cœur de toute interaction avec la plateforme.

### La boucle de réconciliation

Le mécanisme qui concrétise le modèle déclaratif est la **boucle de réconciliation** (*reconciliation loop* ou *control loop*). En continu, des contrôleurs spécialisés observent l'état actuel du cluster, le comparent à l'état souhaité (stocké dans l'API Server), et exécutent les actions nécessaires pour corriger tout écart. Si un conteneur s'arrête, le contrôleur en redémarre un automatiquement. Si un nœud tombe, les workloads sont replannifiés ailleurs. Ce modèle rend Kubernetes intrinsèquement **auto-réparateur** (*self-healing*).

### Tout est objet API

Dans Kubernetes, chaque entité — un Pod, un Service, un Deployment, un Volume — est représentée sous forme d'un **objet API** persisté dans une base de données distribuée (etcd). Ces objets sont créés, lus, modifiés et supprimés via une API REST unifiée. Cette approche « *everything-as-an-object* » rend le système extensible : il est possible de définir ses propres types de ressources (Custom Resource Definitions) et de créer les contrôleurs associés (Operators).

### Couplage lâche et extensibilité

L'architecture de Kubernetes est modulaire par conception. Le réseau est délégué à des plugins CNI, le stockage à des drivers CSI, le runtime de conteneurs à une interface CRI. Chaque couche peut être remplacée ou étendue indépendamment. Cette approche par interfaces standardisées permet à un même cluster Kubernetes de s'adapter à des environnements très différents — d'un Raspberry Pi à un data center hyperscale — sans modifier le cœur du système.

---

## Vue d'ensemble de l'architecture

À un haut niveau, un cluster Kubernetes se compose de deux catégories de machines :

```
┌──────────────────────────────────────────────────────────────────┐
│                        CLUSTER KUBERNETES                        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                     CONTROL PLANE                           │ │
│  │                                                             │ │
│  │   API Server ←→ etcd        Scheduler                       │ │
│  │       ↕                        ↕                            │ │
│  │   Controller Manager    Cloud Controller Manager            │ │
│  │                                                             │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                          ↕ API                                   │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐  │
│  │   WORKER NODE 1  │ │   WORKER NODE 2  │ │   WORKER NODE N  │  │
│  │                  │ │                  │ │                  │  │
│  │  kubelet         │ │  kubelet         │ │  kubelet         │  │
│  │  kube-proxy      │ │  kube-proxy      │ │  kube-proxy      │  │
│  │  Container       │ │  Container       │ │  Container       │  │
│  │  Runtime         │ │  Runtime         │ │  Runtime         │  │
│  │                  │ │                  │ │                  │  │
│  │  ┌────┐  ┌────┐  │ │  ┌────┐  ┌────┐  │ │  ┌────┐          │  │
│  │  │Pod │  │Pod │  │ │  │Pod │  │Pod │  │ │  │Pod │          │  │
│  │  └────┘  └────┘  │ │  └────┘  └────┘  │ │  └────┘          │  │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

**Le plan de contrôle** héberge les composants qui prennent les décisions : l'API Server (point d'entrée unique), etcd (base de données de l'état du cluster), le Scheduler (placement des Pods sur les nœuds), le Controller Manager (boucles de réconciliation) et, dans un contexte cloud, le Cloud Controller Manager.

**Les nœuds de travail** exécutent les charges applicatives sous forme de Pods. Chaque nœud fait tourner un agent kubelet (qui communique avec l'API Server), un kube-proxy (qui gère les règles réseau pour les Services) et un runtime de conteneurs (containerd ou CRI-O sur Debian).

Les sous-chapitres suivants détaillent chacun de ces composants et leur interaction.

---

## Kubernetes et Debian : un couple naturel

Dans le contexte de cette formation, Debian occupe une place particulière vis-à-vis de Kubernetes :

- **Stabilité** — La politique de release de Debian Stable, centrée sur la fiabilité et la prévisibilité, en fait un socle idéal pour les nœuds d'un cluster de production. Les mises à jour de sécurité sont rapides et les régressions rares.
- **Légèreté** — Une installation minimale de Debian (sans environnement graphique) consomme très peu de ressources, laissant un maximum de CPU et de mémoire aux workloads Kubernetes.
- **Images de conteneurs** — Les images `debian:trixie-slim` sont parmi les plus utilisées comme base pour la construction d'images Docker/OCI, offrant un bon compromis entre taille et richesse de l'écosystème de paquets.
- **Communauté et documentation** — Les procédures d'installation de kubeadm, K3s ou MicroK8s sont parfaitement documentées pour Debian, et la communauté est très active sur ce sujet.
- **Intégration systemd** — Kubernetes s'appuie sur systemd pour la gestion de ses services (kubelet, containerd). La maîtrise de systemd acquise dans le Module 3 est donc directement applicable.

---

## Ce que vous allez apprendre

Cette section 11.1 est découpée en quatre sous-chapitres qui construisent progressivement votre compréhension de l'architecture Kubernetes :

**11.1.1 — Architecture d'un cluster Kubernetes** : vision globale de l'architecture, rôle de chaque composant et flux de communication entre eux. Ce sous-chapitre vous donnera la carte mentale nécessaire pour comprendre tout ce qui suit.

**11.1.2 — Control plane** : plongée dans les composants du plan de contrôle (API Server, etcd, Scheduler, Controller Manager). Vous comprendrez comment chaque pièce fonctionne, pourquoi elle existe et comment elle interagit avec les autres.

**11.1.3 — Worker nodes** : focus sur les composants qui tournent sur chaque nœud de travail (kubelet, kube-proxy, container runtime). Vous verrez comment un nœud Debian rejoint un cluster et exécute des Pods.

**11.1.4 — Le modèle déclaratif et la boucle de réconciliation** : approfondissement du paradigme déclaratif qui distingue Kubernetes des systèmes d'orchestration impératifs. Vous comprendrez les boucles de contrôle, la convergence d'état et le concept de *desired state* vs *current state*.

---

## Prérequis pour cette section

Avant d'aborder l'architecture Kubernetes, assurez-vous de maîtriser les concepts suivants, couverts dans les modules précédents :

- **Conteneurs** (Module 10) : namespaces, cgroups v2, images OCI, Docker et/ou Podman, cycle de vie d'un conteneur.
- **Réseau** (Module 6) : TCP/IP, DNS, routage, pare-feu, concepts de NAT et de proxy.
- **systemd** (Module 3) : gestion des services, unités, journald.
- **Administration Debian** (Modules 3-4) : gestion des paquets, utilisateurs, processus, système de fichiers.

---

*Dans le sous-chapitre suivant (11.1.1), nous entrerons dans le détail de l'architecture d'un cluster Kubernetes en examinant chaque composant et les flux de communication qui les relient.*

⏭️ [Architecture d'un cluster Kubernetes](/module-11-kubernetes-fondamentaux/01.1-architecture-cluster.md)
