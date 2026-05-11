🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 10.1 Fondamentaux des conteneurs

## Prérequis

- Maîtrise de l'administration système Debian (Parcours 1, modules 1 à 8)
- Connaissance de la virtualisation et de ses principes (Module 9)
- Familiarité avec la ligne de commande, la gestion des processus et systemd
- Notions de réseau (interfaces, bridges, routage)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre les mécanismes fondamentaux du noyau Linux qui rendent les conteneurs possibles
- Expliquer les différences architecturales entre conteneurs et machines virtuelles et choisir la technologie appropriée selon le contexte
- Identifier les standards OCI et leur rôle dans l'interopérabilité de l'écosystème conteneur

## Introduction

La conteneurisation représente l'une des évolutions les plus structurantes de l'informatique moderne. Avant de manipuler Docker, Podman ou Kubernetes, il est essentiel de comprendre **ce qu'est réellement un conteneur** et sur quels mécanismes du noyau Linux il repose. Contrairement à une idée reçue, les conteneurs ne sont pas une technologie unique inventée ex nihilo : ils résultent de la convergence de plusieurs fonctionnalités du noyau Linux développées et perfectionnées au fil des années.

### Un peu d'histoire

L'idée d'isoler des processus dans un environnement restreint ne date pas de Docker. Elle remonte aux premiers mécanismes d'isolation sous Unix :

- **1979 — `chroot`** : l'appel système `chroot`, introduit dans Unix V7, permet de changer le répertoire racine apparent d'un processus. C'est le premier ancêtre conceptuel du conteneur, même s'il ne fournit aucune isolation réelle au-delà du système de fichiers.

- **2000 — FreeBSD Jails** : les *jails* BSD étendent le concept de `chroot` en ajoutant une isolation réseau, des utilisateurs et des processus. Ils préfigurent ce que seront les conteneurs Linux, mais restent limités à l'écosystème FreeBSD.

- **2002 — Linux namespaces** : le noyau Linux introduit progressivement les *namespaces*, qui permettent d'isoler différents aspects du système (PID, réseau, points de montage, etc.). Ce mécanisme constitue le premier pilier des conteneurs Linux modernes.

- **2006-2008 — cgroups (Control Groups)** : développés initialement par des ingénieurs de Google sous le nom de *process containers*, les cgroups permettent de limiter, comptabiliser et isoler les ressources matérielles (CPU, mémoire, I/O) consommées par un groupe de processus. Ils forment le second pilier fondamental.

- **2008 — LXC (Linux Containers)** : premier projet à combiner namespaces et cgroups pour offrir une solution complète de conteneurs sous Linux. LXC propose des conteneurs « système » qui se comportent comme des machines virtuelles légères.

- **2013 — Docker** : Docker ne crée aucune technologie noyau nouvelle. Son apport majeur est de proposer une expérience utilisateur radicalement simplifiée autour des conteneurs « applicatifs », avec un système d'images en couches, un registre centralisé (Docker Hub) et un format de distribution standardisé. Docker démocratise les conteneurs auprès des développeurs et déclenche une adoption massive.

- **2015 — Open Container Initiative (OCI)** : face à la domination de Docker et au besoin d'interopérabilité, les acteurs de l'industrie créent l'OCI sous l'égide de la Linux Foundation pour standardiser les formats d'images et les runtimes de conteneurs. Ce standard garantit qu'un conteneur construit avec un outil peut être exécuté par un autre.

### Les trois piliers techniques

Un conteneur Linux repose sur trois mécanismes fondamentaux du noyau, que nous détaillerons dans la section 10.1.1 :

1. **Les namespaces** — Ils assurent l'**isolation**. Chaque conteneur dispose de sa propre vue du système : ses propres identifiants de processus (PID), sa propre pile réseau, ses propres points de montage, son propre nom d'hôte, etc. Un processus à l'intérieur d'un conteneur ne voit pas les processus des autres conteneurs ni ceux de l'hôte.

2. **Les cgroups (Control Groups) v2** — Ils assurent la **limitation des ressources**. Les cgroups permettent de définir des quotas de CPU, de mémoire, de bande passante disque et réseau pour chaque conteneur. Ils empêchent un conteneur de monopoliser les ressources de l'hôte et fournissent des mécanismes de comptabilité précis.

3. **Les systèmes de fichiers en couches (overlay FS)** — Ils assurent l'**efficacité du stockage**. Grâce aux systèmes de fichiers par superposition (OverlayFS étant le plus courant), les images de conteneurs sont constituées de couches empilées en lecture seule, partagées entre plusieurs conteneurs. Seules les modifications sont écrites dans une fine couche supérieure propre à chaque instance.

### Conteneurs et Debian

Debian occupe une position privilégiée dans l'écosystème des conteneurs pour plusieurs raisons :

- **Images de base de référence** — Les images officielles `debian:trixie`, `debian:trixie-slim` et `debian:trixie-backports` figurent parmi les images de base les plus utilisées dans le monde des conteneurs. Leur stabilité, leur faible surface d'attaque et la qualité de la gestion des paquets APT en font un choix naturel.

- **Support noyau complet** — Le noyau livré avec Debian Stable intègre nativement le support des namespaces, des cgroups v2, d'OverlayFS et de tous les composants nécessaires à l'exécution de conteneurs, sans configuration supplémentaire.

- **Packaging des outils** — Docker, Podman, Buildah, Skopeo, LXC et Incus sont tous disponibles dans les dépôts Debian ou via des dépôts officiels tiers, avec des paquets `.deb` maintenus et intégrés au système.

- **Philosophie de stabilité** — La politique de stabilité de Debian, avec des versions figées et des mises à jour de sécurité suivies, en fait un excellent choix comme système hôte pour faire tourner des conteneurs en production.

### Ce que nous allons couvrir

Cette section introductive pose les fondations théoriques indispensables avant de passer à la pratique avec Docker (section 10.2), Podman (section 10.3) et LXC/Incus (section 10.4). Elle se décompose en trois sous-sections :

- **10.1.1 — Concepts fondamentaux (namespaces, cgroups v2, overlay FS)** : plongée technique dans les mécanismes noyau qui rendent les conteneurs possibles, avec une approche progressive et des exemples concrets sur Debian.

- **10.1.2 — Conteneurs vs machines virtuelles : différences architecturales** : comparaison structurée entre les deux approches d'isolation, critères de choix, cas d'usage respectifs et complémentarité.

- **10.1.3 — Standards OCI (Open Container Initiative)** : présentation des spécifications OCI (image-spec, runtime-spec, distribution-spec), leur rôle dans l'écosystème et pourquoi ils importent pour l'interopérabilité.

### Pourquoi comprendre les fondamentaux ?

Il est tentant de passer directement à `docker run` et de traiter le conteneur comme une boîte noire. Cette approche fonctionne jusqu'au jour où un conteneur consomme toute la mémoire de l'hôte, où un problème de réseau nécessite de comprendre les network namespaces, ou lorsqu'un système de fichiers en couches pose des problèmes de performance en production.

Comprendre les fondamentaux permet de :

- **Diagnostiquer** les problèmes liés aux conteneurs en remontant aux mécanismes noyau sous-jacents
- **Sécuriser** les déploiements en comprenant précisément ce qui est isolé — et ce qui ne l'est pas
- **Optimiser** les performances en agissant sur les bons leviers (cgroups, storage drivers, configuration réseau)
- **Choisir** les bons outils en connaissance de cause (Docker vs Podman, OverlayFS vs Btrfs, runc vs crun)
- **Évoluer** sereinement vers Kubernetes, où ces mêmes mécanismes sont à l'œuvre à plus grande échelle

---

> **Navigation**  
>  
> Section suivante : [10.1.1 Concepts fondamentaux (namespaces, cgroups v2, overlay FS)](/module-10-conteneurs/01.1-namespaces-cgroups-overlayfs.md)  
>  
> Retour au sommaire : [Module 10 — Conteneurs](/module-10-conteneurs.md)

⏭️ [Concepts fondamentaux (namespaces, cgroups v2, overlay FS)](/module-10-conteneurs/01.1-namespaces-cgroups-overlayfs.md)
