🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 4.1 APT (Advanced Package Tool)

## Introduction

APT (Advanced Package Tool) est le système de gestion de paquets de haut niveau de Debian. Il constitue l'interface principale entre l'administrateur et les milliers de paquets disponibles dans les dépôts de la distribution. Comprendre APT en profondeur est une compétence fondamentale pour tout administrateur Debian, car la quasi-totalité des opérations de maintenance — installation de logiciels, mises à jour de sécurité, gestion des dépendances — passe par cet outil.

## Positionnement d'APT dans l'écosystème Debian

La gestion des paquets sous Debian repose sur une architecture à deux niveaux :

- **Niveau bas — dpkg** : c'est le moteur d'installation des paquets `.deb`. Il sait installer, supprimer et inspecter un paquet individuel, mais il ne gère pas les dépendances automatiquement et ne sait pas télécharger de paquets depuis un dépôt distant.
- **Niveau haut — APT** : il s'appuie sur dpkg et y ajoute la résolution automatique des dépendances, le téléchargement depuis des dépôts distants, la gestion des mises à jour et un système de cache local. APT est en quelque sorte le « chef d'orchestre » qui coordonne dpkg.

Cette séparation des responsabilités est un choix architectural délibéré. dpkg reste un outil déterministe et prévisible pour manipuler des paquets individuels, tandis qu'APT se charge de la complexité liée aux relations entre paquets et à la logistique des dépôts.

## Bref historique

APT a été développé à la fin des années 1990 pour résoudre un problème concret : la gestion manuelle des dépendances avec `dpkg` seul devenait ingérable à mesure que le nombre de paquets Debian augmentait. Avant APT, les administrateurs devaient télécharger chaque paquet et ses dépendances à la main, puis les installer dans le bon ordre — un processus fastidieux et source d'erreurs souvent désigné sous le nom informel de *dependency hell*.

APT a introduit plusieurs concepts qui sont devenus des standards dans le monde Linux :

- La notion de **dépôts** (repositories) centralisés accessibles via le réseau.
- La **résolution automatique des dépendances** : APT calcule l'ensemble des paquets nécessaires, détecte les conflits éventuels et propose une solution cohérente avant toute installation.
- L'**authentification cryptographique** des dépôts via des clés GPG, garantissant l'intégrité et l'origine des paquets téléchargés.
- Un **système de cache local** (`/var/cache/apt/archives/`) qui évite de retélécharger des paquets déjà récupérés.

## Les commandes APT : `apt` vs `apt-get` vs `aptitude`

Debian propose plusieurs interfaces en ligne de commande pour interagir avec le système APT. Il est important de comprendre leurs différences et leurs cas d'usage :

**`apt-get` et `apt-cache`** sont les commandes historiques. `apt-get` gère l'installation, la suppression et les mises à jour ; `apt-cache` permet d'interroger le cache des paquets (recherche, informations, dépendances). Ces commandes offrent une sortie stable et prévisible, ce qui les rend particulièrement adaptées à une utilisation dans des scripts d'automatisation.

**`apt`** est la commande unifiée introduite avec Debian 8 (Jessie). Elle regroupe les fonctionnalités les plus courantes de `apt-get` et `apt-cache` dans une interface unique, avec une sortie plus lisible (barre de progression, couleurs, affichage simplifié). Elle est conçue pour l'usage interactif en terminal. En revanche, son format de sortie peut évoluer d'une version à l'autre et ne doit pas être parsé dans des scripts.

**`aptitude`** est un gestionnaire de paquets alternatif qui dispose à la fois d'une interface en ligne de commande et d'une interface semi-graphique en mode texte (ncurses). Son algorithme de résolution de dépendances est plus sophistiqué que celui d'`apt-get` : lorsqu'un conflit survient, `aptitude` est capable de proposer plusieurs scénarios de résolution et de laisser l'administrateur choisir. Il n'est pas installé par défaut mais reste disponible dans les dépôts via `apt install aptitude`.

En pratique, la recommandation actuelle pour un administrateur Debian est la suivante : utiliser `apt` pour les opérations quotidiennes en mode interactif, `apt-get` dans les scripts et l'automatisation, et `aptitude` lorsque la résolution de conflits complexes le nécessite.

## Fonctionnement général d'APT

Le cycle de travail typique d'APT suit une logique en plusieurs étapes :

1. **Mise à jour de l'index** — APT contacte les dépôts configurés dans `/etc/apt/sources.list` (et les fichiers de `/etc/apt/sources.list.d/`) pour télécharger les listes de paquets disponibles. Ces métadonnées sont stockées localement dans `/var/lib/apt/lists/`.

2. **Résolution des dépendances** — Lorsqu'une installation ou une mise à jour est demandée, APT analyse l'arbre de dépendances du ou des paquets concernés. Il détermine quels paquets supplémentaires doivent être installés, lesquels doivent être mis à jour et si des conflits existent.

3. **Téléchargement** — Les paquets `.deb` nécessaires sont téléchargés depuis les dépôts et stockés dans le cache local `/var/cache/apt/archives/`.

4. **Installation** — APT délègue l'installation effective à dpkg, qui décompresse les paquets, exécute les scripts de pré/post-installation et enregistre les fichiers dans la base de données dpkg (`/var/lib/dpkg/`).

5. **Nettoyage** — Les paquets téléchargés restent dans le cache local. L'administrateur peut les purger manuellement avec `apt clean` ou `apt autoclean` pour libérer de l'espace disque.

## Fichiers et répertoires clés

Plusieurs emplacements du système de fichiers sont essentiels au fonctionnement d'APT :

- `/etc/apt/sources.list` — Fichier principal de configuration des dépôts.
- `/etc/apt/sources.list.d/` — Répertoire contenant des fichiers de dépôts additionnels (un fichier par source tierce, convention `.list` ou `.sources`).
- `/etc/apt/apt.conf.d/` — Répertoire contenant les fichiers de configuration d'APT (proxy, options de téléchargement, comportement par défaut).
- `/etc/apt/preferences.d/` — Répertoire de configuration du pinning (priorité des paquets et des dépôts).
- `/etc/apt/trusted.gpg.d/` — Emplacement historique des clés GPG des dépôts officiels (gérées par les paquets `debian-archive-keyring` et associés). Ne plus y déposer de clés manuellement.
- `/etc/apt/keyrings/` — Emplacement **recommandé depuis Debian 12** pour les clés GPG des dépôts tiers (Docker, Google, etc.), à référencer explicitement par `Signed-By:` dans le fichier de dépôt.
- `/var/lib/apt/lists/` — Cache local des index de paquets téléchargés depuis les dépôts.
- `/var/cache/apt/archives/` — Cache local des paquets `.deb` téléchargés.
- `/var/lib/dpkg/` — Base de données dpkg (état des paquets installés, fichiers appartenant à chaque paquet).

## Ce que couvre cette section

Les sous-sections suivantes détaillent chaque aspect du fonctionnement d'APT :

- **4.1.1 — Configuration d'APT et fonctionnement interne** : plongée dans les fichiers de configuration, les options avancées et les mécanismes internes de résolution et de téléchargement.
- **4.1.2 — Sources.list et dépôts** : syntaxe du fichier `sources.list`, composants (`main`, `contrib`, `non-free`, `non-free-firmware`), nouveau format DEB822 (`.sources`) et gestion des miroirs.
- **4.1.3 — Commandes apt et apt-get** : référence complète des commandes d'installation, mise à jour, recherche, suppression et maintenance.
- **4.1.4 — Gestion des clés GPG et authentification des dépôts** : mécanismes de signature, vérification de l'intégrité des paquets et gestion des clés de confiance.

## Prérequis

Pour aborder cette section dans de bonnes conditions, les connaissances suivantes sont attendues :

- Maîtrise de la navigation dans le système de fichiers Linux (Module 3.1).
- Compréhension du modèle de permissions et de la commande `sudo` (Module 3.2).
- Notions de base en réseau : protocoles HTTP/HTTPS, résolution DNS (Module 6.1 ou connaissances équivalentes).
- Familiarité avec l'édition de fichiers de configuration en ligne de commande (`nano`, `vim` ou tout autre éditeur).

⏭️ [Configuration d'APT et fonctionnement interne](/module-04-gestion-paquets/01.1-configuration-fonctionnement.md)
