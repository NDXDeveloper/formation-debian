🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 10.2 Docker

## Prérequis

- Maîtrise des fondamentaux des conteneurs (section 10.1) : namespaces, cgroups v2, OverlayFS
- Compréhension des différences architecturales entre conteneurs et machines virtuelles
- Connaissance des standards OCI (image-spec, runtime-spec, distribution-spec)
- Administration système Debian : gestion des paquets APT, systemd, réseau, utilisateurs et groupes

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Installer et configurer Docker Engine sur Debian en suivant les bonnes pratiques
- Construire des images Docker efficaces et sécurisées, en maîtrisant le système de couches et les multi-stage builds
- Gérer le cycle de vie complet des conteneurs (création, exécution, inspection, arrêt, suppression)
- Orchestrer des applications multi-conteneurs avec Docker Compose
- Administrer les volumes et les réseaux Docker
- Déployer et utiliser un registre privé
- Optimiser les images Debian pour un usage en conteneur

## Introduction

Docker est le logiciel qui a démocratisé les conteneurs. Lorsqu'il est apparu en 2013, les technologies sous-jacentes existaient depuis des années (namespaces depuis 2002, cgroups depuis 2008, LXC depuis 2008), mais leur utilisation restait l'apanage de quelques équipes d'infrastructure disposant de compétences noyau avancées. Docker a rendu la conteneurisation accessible à tout développeur sachant taper une ligne de commande.

### L'apport de Docker

L'innovation de Docker n'est pas technique au sens strict — il n'a créé aucun mécanisme noyau nouveau. Son apport se situe sur quatre plans :

**Une expérience utilisateur radicalement simplifiée** — Là où la création d'un conteneur LXC nécessitait de manipuler manuellement des configurations de namespaces, cgroups et systèmes de fichiers, Docker a réduit l'opération à une commande unique : `docker run`. Cette simplicité a abaissé la barrière d'entrée et permis aux développeurs, et non plus seulement aux administrateurs système, de s'emparer de la technologie.

**Le Dockerfile et les images en couches** — Docker a introduit un format déclaratif (le Dockerfile) pour décrire la construction d'un environnement applicatif, étape par étape. Chaque instruction produit une couche de système de fichiers, mise en cache et réutilisable. Ce modèle permet de versionner l'infrastructure comme du code et de partager des environnements reproductibles.

**Le registre centralisé (Docker Hub)** — En proposant un dépôt public d'images prêtes à l'emploi, Docker a créé un écosystème de partage comparable à ce que NPM est au JavaScript ou PyPI au Python. Toute application, toute base de données, tout outil pouvait être téléchargé et lancé en quelques secondes, sans installation manuelle de dépendances.

**Le modèle de conteneur applicatif** — Contrairement aux conteneurs système LXC qui reproduisent une machine complète avec init, services et accès SSH, Docker a popularisé le modèle du conteneur applicatif : un conteneur = un processus = une responsabilité. Ce paradigme a posé les fondations des architectures microservices et du mouvement cloud-native.

### Docker aujourd'hui

Le paysage a considérablement évolué depuis 2013. Docker Inc. a traversé des mutations profondes — cession de son activité Enterprise à Mirantis en 2019, recentrage sur les outils développeur (Docker Desktop, Docker Hub). Parallèlement, l'écosystème s'est structuré autour des standards OCI, et des alternatives matures ont émergé : Podman, Buildah, containerd, CRI-O.

Docker reste néanmoins un outil incontournable pour plusieurs raisons :

- **Base installée massive** — Docker est le runtime de conteneurs le plus déployé au monde. La majorité des Dockerfiles, tutoriels, documentations et workflows CI/CD existants ciblent Docker.

- **Écosystème de développement** — Docker Compose, Docker Build (BuildKit), Docker Scout et Docker Desktop constituent une chaîne d'outils cohérente et mature pour le développement local.

- **Docker Hub** — Reste le registre d'images le plus vaste et le plus utilisé, hébergeant les images officielles de la quasi-totalité des projets open source majeurs.

- **Compatibilité OCI** — Docker produit et consomme des images conformes aux standards OCI. Toute image Docker est utilisable par Podman, Kubernetes (via containerd ou CRI-O) et tout outil conforme OCI.

Il est cependant important de comprendre que Docker n'est plus le seul choix possible, ni toujours le meilleur selon le contexte. En production sur Kubernetes, containerd ou CRI-O ont remplacé Docker comme runtime de référence depuis la dépréciation de Dockershim dans Kubernetes 1.24 (2022). Pour les environnements exigeant une sécurité renforcée, Podman en mode rootless offre un modèle architecturalement plus sûr. Ces alternatives seront traitées dans la section 10.3.

### Architecture de Docker Engine

Docker Engine est composé de plusieurs éléments qui s'articulent selon une architecture client-serveur :

```
┌─────────────────────────────────────────────────────────────┐
│                       HÔTE DEBIAN                           │
│                                                             │
│  ┌──────────┐     API REST      ┌─────────────────────────┐ │
│  │ docker   │ ──────────────→   │     dockerd             │ │
│  │  CLI     │  (socket Unix     │  (Docker daemon)        │ │
│  │          │   ou TCP)         │                         │ │
│  └──────────┘                   │  Gestion des images     │ │
│                                 │  Gestion du réseau      │ │
│  ┌──────────┐                   │  Gestion des volumes    │ │
│  │ Docker   │ ──────────────→   │  API REST               │ │
│  │ Compose  │                   │         │               │ │
│  └──────────┘                   └─────────┼───────────────┘ │
│                                           │                 │
│                                           ↓                 │
│                                 ┌─────────────────────────┐ │
│                                 │     containerd          │ │
│                                 │  (gestion du cycle de   │ │
│                                 │   vie des conteneurs)   │ │
│                                 │         │               │ │
│                                 └─────────┼───────────────┘ │
│                                           │                 │
│                                           ↓                 │
│                                 ┌─────────────────────────┐ │
│                                 │    containerd-shim      │ │
│                                 │  (un shim par conteneur)│ │
│                                 │         │               │ │
│                                 └─────────┼───────────────┘ │
│                                           │                 │
│                                           ↓                 │
│                                 ┌─────────────────────────┐ │
│                                 │      runc / crun        │ │
│                                 │   (runtime OCI)         │ │
│                                 │                         │ │
│                                 │  → clone() namespaces   │ │
│                                 │  → configure cgroups    │ │
│                                 │  → pivot_root           │ │
│                                 │  → exec processus       │ │
│                                 └─────────────────────────┘ │
│                                                             │
│  Noyau Linux (namespaces, cgroups v2, OverlayFS, seccomp)   │
└─────────────────────────────────────────────────────────────┘
```

**docker CLI** — Le client en ligne de commande. Il ne fait qu'envoyer des requêtes à l'API REST du daemon. Il peut être exécuté sur une machine différente de celle qui héberge le daemon.

**dockerd (Docker daemon)** — Le processus principal qui tourne en arrière-plan en tant que service systemd sur Debian. Il expose une API REST (par défaut sur le socket Unix `/var/run/docker.sock`), gère les images, les réseaux, les volumes et délègue l'exécution des conteneurs à containerd. Le daemon s'exécute en tant que `root`, ce qui a des implications de sécurité importantes.

**containerd** — Daemon de gestion du cycle de vie des conteneurs, conforme aux standards OCI. Il gère le pull/push des images, le stockage des images et le suivi des conteneurs en cours d'exécution. Docker l'utilise comme composant interne, mais containerd peut aussi fonctionner indépendamment (c'est le cas dans Kubernetes).

**containerd-shim** — Un processus léger créé pour chaque conteneur. Il sert d'intermédiaire entre containerd et le processus du conteneur, permettant au conteneur de survivre à un redémarrage de containerd ou de dockerd sans interruption. Le shim maintient les descripteurs de fichiers (stdin, stdout, stderr) et le statut de sortie du conteneur.

**runc** — Le runtime OCI de bas niveau qui effectue les opérations noyau réelles : création des namespaces, configuration des cgroups, pivot_root, application de seccomp et lancement du processus du conteneur. runc se termine immédiatement après le lancement — il ne reste pas résident.

### Le modèle client-daemon et ses implications

L'architecture client-daemon de Docker a plusieurs conséquences qu'il est important de comprendre :

**Le daemon tourne en root** — `dockerd` nécessite des privilèges root pour créer des namespaces, configurer des cgroups et gérer le réseau. Tout utilisateur ayant accès au socket Docker (`/var/run/docker.sock`) dispose de facto d'un accès root sur l'hôte. L'appartenance au groupe `docker` est donc équivalente à l'octroi de privilèges root, ce qui doit être pris en compte dans la politique de sécurité. Le mode rootless de Docker existe mais reste moins mature que l'approche rootless de Podman.

**Point de défaillance unique** — Si le daemon `dockerd` s'arrête ou plante, la gestion de tous les conteneurs est affectée. Les containerd-shims atténuent ce problème en maintenant les conteneurs en vie indépendamment du daemon, mais certaines opérations (création, suppression, inspection) deviennent impossibles tant que le daemon est arrêté.

**Communication via socket** — Par défaut, le CLI communique avec le daemon via le socket Unix `/var/run/docker.sock`. Ce socket peut aussi être exposé en TCP pour l'administration à distance, mais cela nécessite impérativement une authentification TLS pour éviter de donner un accès root distant non authentifié.

Ce modèle client-daemon sera un point de comparaison important avec Podman (section 10.3), qui adopte une architecture sans daemon.

### Docker et Debian : une relation étroite

Docker entretient une relation privilégiée avec Debian :

**Images de base** — L'image officielle `debian` est l'une des plus utilisées comme image de base dans les Dockerfiles. Les variantes `slim` (allégées) sont particulièrement populaires en production pour leur faible empreinte et leur stabilité.

**Plateforme de build** — Les images officielles Docker Hub sont construites sur des systèmes Debian. Le projet « Docker Official Images » utilise Debian comme environnement de référence pour la construction et les tests.

**Support de première classe** — Docker Engine publie des paquets `.deb` officiels pour Debian Stable, avec un dépôt APT dédié et des mises à jour régulières.

**Compatibilité noyau** — Le noyau livré avec Debian Bookworm (Linux 6.1 LTS) et Debian Trixie (Linux 6.12 LTS, support upstream jusqu'en décembre 2026) intègre nativement tous les composants requis par Docker : cgroups v2, OverlayFS, user namespaces, veth, bridge, seccomp, AppArmor.

### Ce que nous allons couvrir

Cette section se décompose en sept sous-sections progressives qui couvrent l'ensemble de l'utilisation de Docker sur Debian :

- **10.2.1 — Installation et configuration sur Debian** : installation depuis le dépôt officiel Docker, configuration du daemon (`daemon.json`), intégration systemd, configuration des utilisateurs et vérification de l'installation.

- **10.2.2 — Images : construction, couches, multi-stage builds** : anatomie d'un Dockerfile, bonnes pratiques de construction, optimisation du cache de couches, builds multi-étapes pour des images de production minimales, et utilisation de BuildKit.

- **10.2.3 — Conteneurs : cycle de vie et gestion** : création, exécution, inspection, arrêt, redémarrage, suppression. Gestion des logs, des variables d'environnement, des ports et des politiques de redémarrage.

- **10.2.4 — Docker Compose et orchestration locale** : définition de stacks multi-conteneurs avec `compose.yaml`, gestion des dépendances entre services, profils, et cas d'usage pour le développement et le test.

- **10.2.5 — Volumes et réseaux** : volumes nommés, bind mounts, tmpfs. Réseaux bridge, host, overlay et macvlan. Isolation réseau entre conteneurs et communication inter-services.

- **10.2.6 — Registry privé et distribution d'images** : déploiement d'un registre privé sur Debian, authentification, TLS, stratégie de tagging et gestion du cycle de vie des images.

- **10.2.7 — Images Debian : slim, minimalistes et bonnes pratiques** : choix de l'image de base, comparaison `debian:trixie` vs `trixie-slim` vs alternatives (Alpine, distroless, scratch), optimisation de la taille et de la sécurité des images basées Debian.

### Positionnement de Docker dans le parcours

Docker est le premier outil de conteneurisation que nous abordons en pratique, après les fondamentaux théoriques de la section 10.1. C'est un choix pédagogique délibéré : Docker reste l'outil de référence pour l'apprentissage des conteneurs, sa documentation est la plus abondante et les concepts qu'il introduit (Dockerfile, images en couches, volumes, réseaux, Compose) se transposent directement aux alternatives.

Cependant, Docker n'est qu'un outil parmi d'autres dans un écosystème standardisé par l'OCI. Les sections suivantes présenteront Podman et ses outils compagnons (10.3) pour une approche sans daemon et rootless, puis LXC/Incus (10.4) pour les conteneurs système, et enfin les principes de sécurité transverses (10.5). L'objectif est de maîtriser Docker tout en comprenant quand et pourquoi envisager une alternative.

```
Section 10.1 (Fondamentaux)
    │
    ▼
┌─────────────────────────────────────────┐
│  Section 10.2 — Docker     ◄── vous êtes ici
│  (conteneurs applicatifs,               │
│   modèle client-daemon)                 │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Section 10.3 — Podman et alternatives  │
│  (sans daemon, rootless, Buildah,       │
│   Skopeo, Quadlet)                      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Section 10.4 — LXC/LXD (Incus)         │
│  (conteneurs système)                   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Section 10.5 — Sécurité des conteneurs │
│  (seccomp, AppArmor, scanning, bonnes   │
│   pratiques transverses)                │
└─────────────────────────────────────────┘
```

---

> **Navigation**  
>  
> Section précédente : [10.1.3 Standards OCI (Open Container Initiative)](/module-10-conteneurs/01.3-standards-oci.md)  
>  
> Section suivante : [10.2.1 Installation et configuration sur Debian](/module-10-conteneurs/02.1-installation-docker-debian.md)

⏭️ [Installation et configuration sur Debian](/module-10-conteneurs/02.1-installation-docker-debian.md)
