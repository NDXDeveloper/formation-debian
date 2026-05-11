🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 10.4 LXC/LXD (Incus)

## Prérequis

- Compréhension des fondamentaux des conteneurs : namespaces, cgroups v2, OverlayFS (section 10.1)
- Connaissance de Docker et/ou Podman pour la comparaison (sections 10.2, 10.3)
- Administration système Debian : systemd, gestion des utilisateurs, réseau, LVM (Parcours 1)
- Notions de virtualisation (Module 9)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Distinguer les conteneurs système (LXC/Incus) des conteneurs applicatifs (Docker/Podman) et choisir l'approche adaptée à chaque cas d'usage
- Installer et configurer Incus sur Debian
- Créer, gérer et administrer des conteneurs système et des machines virtuelles avec Incus
- Utiliser les snapshots, la migration et les profils pour une gestion avancée
- Configurer le réseau et le stockage des instances Incus

## Introduction

Les sections précédentes ont exploré les conteneurs **applicatifs** : Docker et Podman empaquettent une application et ses dépendances dans un conteneur léger exécutant un seul processus principal. Ce modèle, idéal pour les microservices et les architectures cloud-native, ne couvre pas tous les cas d'usage. Certaines situations nécessitent un environnement système complet — avec un init system, plusieurs services, un accès SSH, une gestion de paquets opérationnelle — tout en bénéficiant de la légèreté et de la densité des conteneurs plutôt que de la lourdeur des machines virtuelles.

C'est exactement le créneau des **conteneurs système**, dont LXC est le pionnier historique et Incus (successeur de LXD) la solution moderne.

### LXC : le pionnier des conteneurs Linux

**LXC (Linux Containers)**, créé en 2008, est le premier projet à avoir combiné les namespaces et les cgroups du noyau Linux pour offrir une solution complète de conteneurisation. LXC est antérieur à Docker de cinq ans et a posé les fondations sur lesquelles Docker s'est construit — Docker utilisait d'ailleurs LXC comme backend d'exécution dans ses premières versions avant de développer libcontainer (devenu runc).

LXC propose des conteneurs qui se comportent comme des **machines Linux complètes** : ils exécutent un système d'initialisation (systemd, SysV init), gèrent plusieurs services simultanément, disposent de leur propre pile réseau complète et sont administrables par SSH. Du point de vue de l'utilisateur, un conteneur LXC est quasi indiscernable d'une machine virtuelle, mais il partage le noyau de l'hôte et démarre en quelques secondes.

LXC fournit les briques de bas niveau — les outils en ligne de commande (`lxc-create`, `lxc-start`, `lxc-attach`) et les bibliothèques C (`liblxc`) — pour manipuler directement les mécanismes noyau. Ces outils restent disponibles sur Debian mais sont rarement utilisés directement en production, au profit de couches de gestion supérieures.

### LXD : la couche de gestion

**LXD**, développé par Canonical à partir de 2015, est une surcouche à LXC qui ajoute une API REST, un daemon de gestion, un client CLI (`lxc`), et des fonctionnalités d'infrastructure avancées : clustering, migration live, snapshots, gestion fine du stockage et du réseau, profils de configuration, et support des machines virtuelles QEMU en plus des conteneurs LXC.

LXD a transformé LXC d'un ensemble d'outils bas niveau en une plateforme de gestion d'infrastructure complète, positionnée comme une alternative légère à OpenStack pour les environnements privés.

### Incus : le fork communautaire

En juillet 2023, Canonical a unilatéralement retiré LXD du projet Linux Containers pour en reprendre le développement en interne ; quelques mois plus tard (décembre 2023), le projet a été re-licencié de Apache 2.0 vers **AGPLv3** et placé sous un **CLA Canonical** obligatoire pour toute nouvelle contribution. En réponse à la sortie de LXD du giron communautaire, **Aleksa Sarai** (mainteneur de runc et packager de longue date de LXD pour openSUSE) a créé **Incus**, un fork de LXD rapidement adopté par la gouvernance du projet Linux Containers (linuxcontainers.org), le même projet qui maintient LXC. L'équipe historique de LXD — **Stéphane Graber** (ancien lead engineer LXD chez Canonical), **Christian Brauner**, **Serge Hallyn** et **Tycho Andersen** — a rejoint Incus en tant que mainteneurs.

Incus est fonctionnellement identique à LXD au moment du fork (l'API, le CLI et les concepts sont les mêmes) mais conserve la licence Apache 2.0 d'origine, avec une gouvernance communautaire et un développement actif indépendant de Canonical. Depuis le fork, Incus a divergé de LXD avec ses propres améliorations et corrections, et l'incompatibilité de licence (Apache 2.0 vs AGPLv3) empêche désormais le partage de code entre les deux projets.

**Sur Debian, Incus est le choix recommandé.** Le paquet `incus` (version 6.0.4 LTS dans Trixie) est disponible dans les dépôts Debian à partir de Trixie (13) et via les backports pour Bookworm (12), avec un cycle LTS de cinq ans aligné sur celui de Debian.

Debian propose également un paquet `lxd` (version 5.0.2), correspondant à la dernière version de LXD publiée sous licence Apache 2.0 avant la re-licence Canonical vers AGPLv3 + CLA. Ce paquet reste disponible pour les utilisateurs ayant des installations existantes mais ne reçoit plus de mises à jour fonctionnelles upstream — Canonical distribue désormais les versions récentes de LXD (≥ 5.20) exclusivement via snap, qui n'est pas supporté nativement par Debian. **Pour toute nouvelle installation, Incus est la voie officielle.** LXC reste disponible comme composant bas niveau (paquet `lxc`).

### Chronologie

```
2008    LXC — Premier projet de conteneurs Linux
        Combine namespaces + cgroups pour des conteneurs système
        
2013    Docker — Conteneurs applicatifs, initialement basé sur LXC
        Popularise un modèle différent : 1 conteneur = 1 processus
        
2015    LXD — Surcouche de gestion sur LXC par Canonical
        API REST, daemon, CLI, clustering, migration live, VMs
        
2015    OCI — Standardisation des conteneurs applicatifs
        runc, image-spec, runtime-spec
        
2023-07  Canonical retire LXD du projet Linux Containers
         Reprise du développement en interne, sortie du giron communautaire

2023-08  Incus — Fork communautaire de LXD par Aleksa Sarai
         Adoption rapide par Linux Containers, équipe LXD historique rejoint
         le projet (Stéphane Graber, Christian Brauner, Serge Hallyn…)

2023-12  Re-licence LXD vers AGPLv3 + CLA Canonical
         Incompatibilité de licence avec Incus (Apache 2.0)

2024     Incus 6.0 LTS publiée — base de la version Debian Trixie
         Développement actif, divergence progressive de LXD
```

### Architecture d'Incus

Incus adopte une architecture client-serveur avec un daemon central :

```
┌──────────────────────────────────────────────────────────────┐
│                        HÔTE DEBIAN                           │
│                                                              │
│  ┌──────────┐      API REST       ┌──────────────────────┐   │
│  │  incus   │ ──────────────────→ │      incusd          │   │
│  │  (CLI)   │   (socket Unix      │   (daemon)           │   │
│  │          │    ou HTTPS)        │                      │   │
│  └──────────┘                     │  Gestion :           │   │
│                                   │  - Instances         │   │
│  ┌──────────┐                     │  - Stockage          │   │
│  │  API     │ ──────────────────→ │  - Réseau            │   │
│  │  REST    │                     │  - Images            │   │
│  │ (HTTP)   │                     │  - Profils           │   │
│  └──────────┘                     │  - Clustering        │   │
│                                   └──────────┬───────────┘   │
│                                              │               │
│                        ┌─────────────────────┼──────────┐    │
│                        │                     │          │    │
│                        ▼                     ▼          ▼    │
│               ┌──────────────┐    ┌────────────┐  ┌───────┐  │
│               │  Conteneur   │    │ Conteneur  │  │  VM   │  │
│               │  système     │    │ système    │  │ QEMU  │  │
│               │  (LXC)       │    │ (LXC)      │  │       │  │
│               │              │    │            │  │       │  │
│               │ ┌──────────┐ │    │ ┌────────┐ │  │ Noyau │  │
│               │ │ systemd  │ │    │ │systemd │ │  │ dédié │  │
│               │ │ sshd     │ │    │ │nginx   │ │  │       │  │
│               │ │ cron     │ │    │ │postfix │ │  │       │  │
│               │ │ rsyslog  │ │    │ │dovecot │ │  │       │  │
│               │ └──────────┘ │    │ └────────┘ │  │       │  │
│               └──────────────┘    └────────────┘  └───────┘  │
│                                                              │
│  Noyau Linux partagé (conteneurs) │ QEMU/KVM (VMs)           │
└──────────────────────────────────────────────────────────────┘
```

Un aspect distinctif d'Incus est qu'il gère à la fois les **conteneurs système** (via LXC) et les **machines virtuelles** (via QEMU/KVM) avec la même API, le même CLI et les mêmes workflows. Cette unification permet de choisir le niveau d'isolation adapté à chaque charge de travail sans changer d'outillage.

Le terme générique pour désigner un conteneur ou une VM dans Incus est une **instance**. Les commandes `incus launch`, `incus start`, `incus stop` fonctionnent de manière identique sur les deux types d'instances.

### Les images Incus

Incus utilise son propre format d'images, distinct du format OCI/Docker. Les images Incus contiennent un **système d'exploitation complet** (rootfs + métadonnées) et sont publiées sur des serveurs d'images publics maintenus par la communauté Linux Containers :

- **images:** (`https://images.linuxcontainers.org`) — Serveur communautaire offrant des images pour des dizaines de distributions (Debian, Ubuntu, Fedora, CentOS, Alpine, Arch, etc.), mises à jour quotidiennement.

Ces images ne sont pas des images Docker/OCI. Elles contiennent un système complet avec systemd, les utilitaires de base, le gestionnaire de paquets et tout ce qui est nécessaire pour démarrer une « machine » fonctionnelle.

```bash
# Lister les images Debian disponibles
incus image list images: debian

# Les images sont identifiées par distribution/version/architecture
# debian/12          → Debian Bookworm
# debian/13          → Debian Trixie
# debian/trixie      → Alias par nom de code (équivalent à debian/13)
# debian/13/cloud    → Variante avec cloud-init préinstallé
```

### Incus et Debian : un positionnement naturel

Debian et Incus partagent des valeurs communes — logiciel libre, gouvernance communautaire, stabilité — ce qui explique l'intégration d'Incus dans les dépôts Debian :

- **Packaging officiel** — Incus est packagé dans Debian Trixie (13) et disponible en backports pour Bookworm (12), avec des paquets `.deb` maintenus par l'équipe Debian.

- **Pas de snap** — Contrairement à LXD qui nécessitait snapd (non supporté par Debian), Incus s'installe via APT comme tout paquet Debian standard.

- **Intégration système** — Incus s'intègre nativement avec le noyau Debian (cgroups v2, namespaces, AppArmor), les outils réseau (bridges, nftables) et le stockage (ZFS, Btrfs, LVM, directory).

- **Images Debian** — Les images Debian pour Incus sont construites quotidiennement et validées par la communauté Linux Containers, garantissant des images à jour et fonctionnelles.

### Ce que nous allons couvrir

Cette section se décompose en quatre sous-sections :

- **10.4.1 — Conteneurs système vs conteneurs applicatifs** : comparaison détaillée des deux modèles, critères de choix, cas d'usage respectifs et complémentarité entre Docker/Podman et LXC/Incus.

- **10.4.2 — Configuration et gestion avancée** : installation d'Incus sur Debian, initialisation (`incus admin init`), création et gestion d'instances (conteneurs et VMs), profils de configuration, limites de ressources et gestion du stockage.

- **10.4.3 — Snapshots et migration** : snapshots manuels et planifiés, restauration, migration d'instances entre hôtes, export/import, et stratégies de sauvegarde.

- **10.4.4 — Intégration réseau** : bridges, réseaux managés, configuration réseau avancée (VLAN, macvlan, SR-IOV), intégration avec l'infrastructure réseau Debian existante.

### Positionnement dans le Module 10

```
Conteneurs applicatifs                    Conteneurs système
(1 processus, immuable,                   (OS complet, mutable,
 microservices, CI/CD)                     remplacement de VMs)

┌─────────────────────────┐              ┌─────────────────────────┐
│  10.2 Docker            │              │  10.4 LXC/LXD (Incus)   │
│  10.3 Podman            │              │                         │
│                         │              │  Conteneurs système     │
│  Format : OCI           │              │  Format : images Incus  │
│  Modèle : 1 proc/ctn    │              │  Modèle : OS complet    │
│  Init : aucun (PID 1)   │              │  Init : systemd         │
│  Gestion : immuable     │              │  Gestion : mutable      │
│  Orchestration : K8s    │              │  Orchestration : Incus  │
│                         │              │  clustering             │
└────────────┬────────────┘              └────────────┬────────────┘
             │                                        │
             │         ┌──────────────────┐           │
             └────────→│  10.5 Sécurité   │←──────────┘
                       │  des conteneurs  │
                       │  (transversal)   │
                       └──────────────────┘
```

Docker/Podman et LXC/Incus répondent à des besoins différents et sont complémentaires. Une infrastructure peut utiliser Incus pour héberger des « machines légères » (serveurs de développement, environnements de test, services legacy) et Docker/Podman pour les applications cloud-native conteneurisées. Les deux technologies partagent les mêmes mécanismes noyau (namespaces, cgroups v2) et coexistent sans conflit sur un même hôte Debian.

---

> **Navigation**  
>  
> Section précédente : [10.3.4 Quadlet : intégration systemd des conteneurs](/module-10-conteneurs/03.4-quadlet-systemd.md)  
>  
> Section suivante : [10.4.1 Conteneurs système vs conteneurs applicatifs](/module-10-conteneurs/04.1-systeme-vs-applicatif.md)

⏭️ [Conteneurs système vs conteneurs applicatifs](/module-10-conteneurs/04.1-systeme-vs-applicatif.md)
