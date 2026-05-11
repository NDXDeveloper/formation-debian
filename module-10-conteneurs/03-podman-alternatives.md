🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 10.3 Podman et alternatives

## Prérequis

- Maîtrise de Docker : images, conteneurs, volumes, réseaux, Compose (section 10.2)
- Compréhension des fondamentaux des conteneurs : namespaces, cgroups v2, OverlayFS (section 10.1.1)
- Connaissance des standards OCI : image-spec, runtime-spec, distribution-spec (section 10.1.3)
- Administration Debian : systemd, gestion des utilisateurs, configuration réseau

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre les différences architecturales entre Docker et Podman et leurs implications en matière de sécurité
- Installer et utiliser Podman en mode rootless sur Debian
- Construire des images OCI avec Buildah, indépendamment de tout daemon
- Inspecter et copier des images entre registres avec Skopeo
- Intégrer les conteneurs Podman dans systemd via Quadlet
- Évaluer quand utiliser Docker, Podman ou les deux selon le contexte

## Introduction

Docker a démocratisé les conteneurs, mais son architecture centrée autour d'un daemon privilégié (root) soulève des questions de sécurité et de conception qui ont motivé le développement d'alternatives. Podman, accompagné de Buildah et Skopeo, constitue la principale alternative à Docker dans l'écosystème des conteneurs OCI. Développés par Red Hat et intégrés aux dépôts Debian, ces outils proposent une approche fondamentalement différente : **pas de daemon, rootless par conception, compatible OCI**.

### Le problème architectural de Docker

Comme décrit en section 10.2, Docker repose sur un daemon central (`dockerd`) qui s'exécute en tant que root et gère l'intégralité des opérations sur les conteneurs. Cette architecture a des conséquences profondes :

**Point de défaillance unique** — Si `dockerd` s'arrête ou plante, la gestion de tous les conteneurs est compromise. Certes, les conteneurs survivent grâce aux containerd-shims, mais les opérations de gestion (création, suppression, inspection, logs) deviennent impossibles tant que le daemon n'est pas relancé.

**Surface d'attaque élevée** — Le daemon root expose un socket Unix (`/var/run/docker.sock`) qui offre un accès root effectif à quiconque peut s'y connecter. Tout membre du groupe `docker` dispose de facto de privilèges équivalents à root sur l'hôte. Ce socket est aussi une cible de choix lorsqu'il est monté dans des conteneurs (pratique courante mais dangereuse pour les outils CI/CD, les agents de monitoring, etc.).

**Modèle de sécurité inversé** — Le mode rootless de Docker existe mais reste un ajout après-coup sur une architecture conçue pour root. Le daemon rootless nécessite une configuration spécifique et conserve certaines limitations héritées de cette conception initiale.

### La réponse de Podman

Podman (**Pod Manager**) est né en 2018 au sein du projet Containers, initié par Red Hat, avec un objectif clair : offrir une alternative à Docker qui soit **rootless par conception** et **sans daemon**.

L'approche de Podman repose sur trois principes architecturaux :

**Pas de daemon** — Podman est un outil client direct. Chaque commande `podman` est un processus indépendant qui interagit directement avec le runtime OCI (runc/crun) et le noyau, sans passer par un daemon intermédiaire. Lorsque `podman run` crée un conteneur, le processus `podman` configure les namespaces et cgroups, invoque le runtime OCI, puis se termine (ou reste attaché si le mode interactif est demandé). Le conteneur vit comme un processus fils de l'utilisateur, pas d'un daemon système.

**Rootless par défaut** — Podman est conçu dès l'origine pour fonctionner sans aucun privilège root. Chaque utilisateur peut créer et gérer ses propres conteneurs dans son espace utilisateur, grâce aux user namespaces (section 10.1.1). Le root à l'intérieur du conteneur est mappé sur l'UID de l'utilisateur hôte, éliminant le risque d'escalade de privilèges en cas d'évasion du conteneur.

**Compatibilité CLI Docker** — Podman implémente volontairement la même interface en ligne de commande que Docker. La plupart des commandes `docker` fonctionnent en remplaçant simplement `docker` par `podman`. Cette compatibilité est délibérée et permet une migration progressive.

### Architecture comparée

```
         DOCKER                              PODMAN
                                             
  ┌──────────┐                        ┌──────────┐
  │ docker   │                        │ podman   │
  │  CLI     │                        │  CLI     │
  └────┬─────┘                        └────┬─────┘
       │ API REST                          │ fork/exec direct
       │ (socket Unix)                     │ (pas de daemon)
       ▼                                   ▼
  ┌──────────────┐                    ┌───────────────┐
  │   dockerd    │ ← daemon root      │  conmon       │ ← monitor par conteneur
  │              │                    │  (1 par       │   (pas de daemon central)
  └──────┬───────┘                    │   conteneur)  │
         │                            └──────┬────────┘
         ▼                                   │
  ┌──────────────┐                           ▼
  │  containerd  │ ← daemon                ┌──────────────┐
  └──────┬───────┘                         │  crun / runc │ ← runtime OCI
         │                                 └──────┬───────┘
         ▼                                        │
  ┌──────────────┐                                ▼
  │  containerd- │                         ┌───────────────┐
  │  shim        │                         │  Conteneur    │
  └──────┬───────┘                         │  (processus   │
         │                                 │   utilisateur)│
         ▼                                 └───────────────┘
  ┌──────────────┐                         
  │  runc        │ ← runtime OCI          Processus fils de
  └──────┬───────┘                         l'utilisateur qui a
         │                                 lancé podman, pas
         ▼                                 d'un daemon root
  ┌──────────────┐                         
  │  Conteneur   │                         
  │  (processus  │                         
  │   de root)   │                         
  └──────────────┘                         
```

La différence est structurelle : Docker interpose deux daemons (dockerd + containerd) entre l'utilisateur et le conteneur, tous deux tournant en root. Podman crée le conteneur directement comme processus fils de l'utilisateur, avec **conmon** (container monitor) comme processus superviseur léger.

**conmon** est un petit programme qui remplit le rôle du containerd-shim de Docker : il maintient les descripteurs de fichiers du conteneur (stdin, stdout, stderr), enregistre le code de sortie et permet au processus `podman` de se terminer sans tuer le conteneur. Mais contrairement à containerd, conmon n'est pas un daemon : il y a une instance de conmon par conteneur, et chacune est un processus simple et indépendant.

### L'écosystème Containers : Podman, Buildah, Skopeo

Podman ne travaille pas seul. Il fait partie d'un écosystème cohérent d'outils complémentaires, tous développés dans le cadre du projet Containers et partageant les mêmes bibliothèques internes :

**Podman** — Exécution et gestion des conteneurs et des pods. Remplace `docker run`, `docker ps`, `docker stop`, `docker compose`, etc.

**Buildah** — Construction d'images OCI. Remplace `docker build`. Buildah offre des capacités que Docker Build n'a pas : construction d'images sans Dockerfile (via des commandes shell), contrôle fin de chaque couche, intégration avec des scripts d'automatisation. Buildah est intégré dans Podman (`podman build` appelle Buildah en interne), mais peut aussi être utilisé de manière autonome.

**Skopeo** — Inspection, copie et signature d'images OCI entre registres, sans téléchargement local complet. Remplace les cas d'usage de `docker pull` + `docker tag` + `docker push` pour la manipulation d'images entre registres, et ajoute des fonctionnalités d'inspection distante absentes de Docker.

```
┌───────────────────────────────────────────────────────────┐
│                 Projet Containers                         │
│                                                           │
│  ┌───────────┐   ┌───────────┐   ┌───────────┐            │
│  │  Podman   │   │ Buildah   │   │  Skopeo   │            │
│  │           │   │           │   │           │            │
│  │ Exécuter  │   │ Construire│   │ Inspecter │            │
│  │ Gérer     │   │ des images│   │ Copier    │            │
│  │ Conteneurs│   │ OCI       │   │ Signer    │            │
│  │ et Pods   │   │           │   │ des images│            │
│  └────┬──────┘   └────┬──────┘   └────┬──────┘            │
│       │               │               │                   │
│       └───────────────┼───────────────┘                   │
│                       │                                   │
│               ┌───────┴────────┐                          │
│               │  Bibliothèques │                          │
│               │  partagées     │                          │
│               │  (containers/  │                          │
│               │   image,       │                          │
│               │   storage,     │                          │
│               │   common)      │                          │
│               └───────┬────────┘                          │
│                       │                                   │
│               ┌───────┴────────┐                          │
│               │ Runtime OCI    │                          │
│               │ (crun / runc)  │                          │
│               └────────────────┘                          │
└───────────────────────────────────────────────────────────┘
```

Les trois outils partagent les mêmes bibliothèques de gestion d'images (`containers/image`), de stockage (`containers/storage`) et de configuration (`containers/common`). Une image construite par Buildah est immédiatement disponible dans le stockage local de Podman, et inversement. Ce partage élimine les doublons et assure une cohérence totale.

### Podman et Debian

Podman est disponible dans les dépôts officiels Debian depuis Debian Bullseye (11). Sur Debian Bookworm (12) et Trixie (13), l'installation est directe via APT :

```bash
sudo apt install podman buildah skopeo
```

Le noyau Debian Bookworm (Linux 6.1 LTS) et Trixie (Linux 6.12 LTS) supportent nativement toutes les fonctionnalités requises par Podman rootless : user namespaces, cgroups v2 en hiérarchie unifiée, OverlayFS natif dans les user namespaces (depuis le noyau 5.11), et le résolveur réseau `pasta` (successeur moderne de `slirp4netns`, devenu le défaut dans Podman 5.x).

Debian est particulièrement bien positionnée pour Podman car :

- **cgroups v2 unifié** est le défaut depuis Debian Bullseye, condition nécessaire au bon fonctionnement de Podman rootless avec la gestion des ressources.
- **Les paquets `uidmap`** (`newuidmap`, `newgidmap`) et les fichiers `/etc/subuid` / `/etc/subgid` sont correctement configurés par les paquets Debian, simplifiant la mise en place du mode rootless.
- **crun** (runtime OCI en C, plus rapide et plus léger que runc) est disponible dans les dépôts et utilisé par défaut par Podman sur Debian.
- **AppArmor** est le module de sécurité mandataire par défaut sur Debian, et Podman l'intègre nativement.

### La compatibilité Docker

Un aspect essentiel de Podman est sa compatibilité avec l'écosystème Docker :

**Ligne de commande** — `podman` accepte les mêmes sous-commandes et options que `docker`. Un alias `alias docker=podman` fonctionne pour la grande majorité des cas d'usage quotidiens.

**Images OCI** — Podman consomme et produit des images conformes aux standards OCI, identiques à celles de Docker. Une image construite avec `docker build` est utilisable par `podman run`, et inversement.

**Registres** — Podman utilise la même API de distribution OCI pour interagir avec les registres (Docker Hub, Harbor, GitLab, registres privés). L'authentification utilise le même fichier `~/.docker/config.json` (ou le fichier Podman `${XDG_RUNTIME_DIR}/containers/auth.json`).

**Compose** — Podman implémente une socket API compatible Docker, permettant d'utiliser `docker-compose` ou `docker compose` avec Podman comme backend. Podman fournit aussi `podman compose` qui délègue à un moteur Compose externe (docker-compose ou podman-compose).

**Dockerfiles** — Les Dockerfiles sont interprétés par Buildah (intégré dans `podman build`) sans modification. Le terme **Containerfile** est l'équivalent neutre de Dockerfile, reconnu par Podman et Buildah. Les deux noms sont interchangeables.

Les incompatibilités existent mais sont rares et concernent principalement les cas suivants : les commandes spécifiques à Docker Swarm (non supporté par Podman), certaines options réseau avancées propres à Docker, et les outils qui communiquent directement avec le socket Docker (nécessitent l'activation du service socket Podman).

### Le concept de Pod dans Podman

Le nom Podman vient de **Pod Manager**. Au-delà des conteneurs individuels, Podman supporte nativement le concept de **pod**, directement inspiré des pods Kubernetes : un groupe de conteneurs partageant le même network namespace (et optionnellement d'autres namespaces).

```bash
# Créer un pod avec deux conteneurs partageant le réseau
podman pod create --name mon-pod -p 8080:80  
podman run -d --pod mon-pod --name web nginx:latest  
podman run -d --pod mon-pod --name sidecar mon-sidecar:v1.0  

# Les deux conteneurs partagent localhost et peuvent communiquer
# via 127.0.0.1 sans configuration réseau
```

Cette fonctionnalité facilite la transition vers Kubernetes : un pod Podman se comporte comme un pod Kubernetes en termes de modèle réseau. Podman peut même générer des manifestes Kubernetes à partir de conteneurs ou pods existants (`podman generate kube`) et, inversement, lancer des pods à partir de manifestes Kubernetes (`podman play kube`).

### Ce que nous allons couvrir

Cette section se décompose en quatre sous-sections :

- **10.3.1 — Podman rootless sur Debian** : installation, configuration du mode rootless, gestion des user namespaces et des subuid/subgid, réseau rootless (pasta/slirp4netns), stockage, utilisation quotidienne et migration depuis Docker.

- **10.3.2 — Buildah et Skopeo** : construction d'images OCI avec Buildah (mode Dockerfile et mode interactif), inspection et copie d'images entre registres avec Skopeo, intégration dans les pipelines CI/CD.

- **10.3.3 — Compatibilité Docker et migration** : compatibilité CLI, images et registres, migration des workflows Docker Compose, socket API compatible, alias et coexistence Docker/Podman sur le même système.

- **10.3.4 — Quadlet : intégration systemd des conteneurs** : gestion des conteneurs Podman comme des services systemd natifs via les fichiers Quadlet (`.container`, `.pod`, `.volume`, `.network`), démarrage automatique, supervision et journalisation intégrée.

### Positionnement : Docker ou Podman ?

La question « Docker ou Podman ? » n'appelle pas de réponse universelle. Les deux outils produisent et consomment des images OCI identiques, et le choix dépend du contexte :

**Podman est préférable** lorsque la sécurité rootless est prioritaire, pour les environnements multi-utilisateurs où chacun doit gérer ses conteneurs de manière isolée, pour l'intégration native avec systemd sur les serveurs Debian, et dans les environnements Red Hat/Fedora/CentOS où Podman est le standard.

**Docker reste pertinent** pour l'écosystème de développement (Docker Desktop, Docker Compose avancé, Docker Scout), lorsque la documentation et les exemples ciblent spécifiquement Docker, pour les équipes déjà formées sur Docker, et pour les cas d'usage nécessitant Docker Swarm.

**Les deux coexistent** dans de nombreux environnements : Docker sur les postes de développement (Docker Desktop), Podman sur les serveurs de production (rootless, systemd). Les images étant standardisées OCI, cette coexistence est transparente.

---

> **Navigation**  
>  
> Section précédente : [10.2.7 Images Debian : slim, minimalistes et bonnes pratiques](/module-10-conteneurs/02.7-images-debian-slim.md)  
>  
> Section suivante : [10.3.1 Podman rootless sur Debian](/module-10-conteneurs/03.1-podman-rootless.md)

⏭️ [Podman rootless sur Debian](/module-10-conteneurs/03.1-podman-rootless.md)
