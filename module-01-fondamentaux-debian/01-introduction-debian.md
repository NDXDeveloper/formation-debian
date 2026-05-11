🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 1.1 Introduction à Debian

## Présentation générale

Debian GNU/Linux est l'une des distributions Linux les plus anciennes, les plus influentes et les plus respectées de l'écosystème open source. Créée en 1993 par Ian Murdock, elle constitue la base sur laquelle reposent des dizaines d'autres distributions — dont Ubuntu, la plus connue d'entre elles — et demeure un choix de référence aussi bien pour les postes de travail que pour les serveurs de production et les infrastructures cloud.

Ce qui distingue Debian de la plupart des autres distributions, c'est avant tout son modèle de gouvernance communautaire. Debian n'est adossée à aucune entreprise commerciale : elle est développée, maintenue et gouvernée entièrement par une communauté mondiale de volontaires réunis autour d'un ensemble de principes fondateurs — le **Contrat social Debian** et les **Debian Free Software Guidelines (DFSG)**. Ces textes fondateurs définissent l'engagement du projet envers ses utilisateurs et envers le logiciel libre, et orientent chaque décision technique et organisationnelle du projet.

## Pourquoi Debian ?

Debian occupe une place singulière dans le paysage des distributions Linux pour plusieurs raisons.

**Stabilité et fiabilité.** La branche *Stable* de Debian est réputée pour sa robustesse en production. Chaque version stable traverse un cycle de tests rigoureux avant sa publication, ce qui en fait un socle de confiance pour les environnements critiques : serveurs web, bases de données, infrastructures réseau, clusters Kubernetes.

**Universalité.** Debian supporte officiellement un nombre d'architectures matérielles sans équivalent parmi les grandes distributions. Pour Debian 13 « Trixie », sept architectures sont officiellement prises en charge : `amd64`, `arm64`, `armhf`, `armel` (dernière release pour cette architecture), `ppc64el`, `riscv64` (nouveauté de Trixie : premier support officiel du 64 bits RISC-V) et `s390x` (mainframe IBM). À noter que les portages historiques `mipsel` et `mips64el` ont été retirés dans Trixie, et que `i386` n'est plus une architecture d'installation native (multiarch sur amd64 uniquement, pour la compatibilité avec d'anciennes applications 32 bits). Cette portabilité fait de Debian un choix naturel pour des contextes variés, du Raspberry Pi au mainframe, en passant par les serveurs cloud et les équipements embarqués.

**Un écosystème de paquets massif.** L'archive Debian 13 contient près de **70 000 paquets binaires** (69 830 à la sortie de Trixie, dont plus de 14 100 nouveaux par rapport à Bookworm), couvrant un spectre fonctionnel immense : outils système, langages de programmation, frameworks, serveurs, applications desktop, bibliothèques scientifiques. Le système de gestion de paquets APT, né chez Debian, reste l'un des gestionnaires de paquets les plus puissants et les plus ergonomiques disponibles ; sa version 3.0 introduite dans Trixie apporte une nouvelle interface en colonnes plus lisible.

**Une base pour d'autres distributions.** Debian sert de fondation à un grand nombre de distributions dérivées. Ubuntu, Linux Mint, Kali Linux, Proxmox VE, Raspberry Pi OS ou encore Devuan sont toutes construites sur Debian. Comprendre Debian, c'est donc acquérir des compétences transposables à une large famille de systèmes.

**Liberté et transparence.** Le projet Debian est l'un des rares à offrir une séparation claire et contractuelle entre logiciels libres et non libres, tout en laissant à l'utilisateur le choix d'activer ou non les composants propriétaires. Cette transparence est un atout pour les organisations soucieuses de conformité logicielle.

## Positionnement dans la formation

Cette section d'introduction pose les bases nécessaires à l'ensemble du parcours. Avant de manipuler le système, il est essentiel de comprendre d'où vient Debian, quels principes guident son développement, comment s'organisent ses versions et ses cycles de publication, et en quoi elle se différencie des autres distributions majeures.

Les sous-sections qui suivent couvriront ces aspects de manière progressive :

- **1.1.1 — Histoire et philosophie de Debian** : les origines du projet, le Contrat social, les DFSG et le modèle de gouvernance communautaire.
- **1.1.2 — Les versions et cycles de release** : le fonctionnement des branches Stable, Testing, Unstable et Experimental, le système de noms de code, et le processus de gel (*freeze*) qui mène à une nouvelle version stable.
- **1.1.3 — Support et cycles de vie** : la durée de support de chaque version, le rôle de l'équipe Security, le projet LTS et le programme ELTS.
- **1.1.4 — Différences avec les autres distributions** : une comparaison structurée avec Ubuntu, RHEL/CentOS/AlmaLinux et Arch Linux, pour situer Debian dans son écosystème et comprendre les critères de choix.
- **1.1.5 — Architecture du système Debian** : une vue d'ensemble des composants internes du système (noyau, init, gestionnaire de paquets, arborescence) qui seront approfondis dans les modules suivants.

## Public visé

Cette section s'adresse aux débutants qui découvrent Debian ainsi qu'aux administrateurs venant d'autres distributions et souhaitant comprendre les spécificités du projet Debian. Aucun prérequis technique n'est nécessaire pour aborder cette introduction ; des bases générales en informatique et une curiosité pour le logiciel libre suffisent.

---

> **Navigation**  
>  
> Section suivante : [1.1.1 Histoire et philosophie de Debian](/module-01-fondamentaux-debian/01.1-histoire-philosophie.md)  
>  
> Retour au sommaire du module : [Module 1 — Fondamentaux de Debian](/module-01-fondamentaux-debian.md)

⏭️ [Histoire et philosophie de Debian (le contrat social, le DFSG)](/module-01-fondamentaux-debian/01.1-histoire-philosophie.md)
