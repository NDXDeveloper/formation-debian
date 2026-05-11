🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 1.2 Installation de base

## Présentation générale

L'installation d'un système Debian est la première étape concrète du parcours d'administrateur. C'est un moment fondateur : les choix effectués à ce stade — type de support d'installation, schéma de partitionnement, configuration réseau, sélection des paquets — auront des répercussions durables sur la maintenabilité, la sécurité et les performances du système tout au long de sa vie en production.

Debian propose un installateur mature et éprouvé, le **debian-installer** (souvent abrégé **d-i**), qui offre un niveau de contrôle remarquable sur chaque aspect du processus. Contrairement aux installateurs de certaines distributions qui privilégient la simplicité au prix de choix automatiques parfois opaques, le debian-installer expose clairement les décisions à prendre et laisse l'administrateur aux commandes. Cette transparence, qui peut intimider au premier abord, est en réalité un atout : elle permet de construire un système parfaitement adapté à son contexte d'utilisation, qu'il s'agisse d'un poste de travail, d'un serveur de production ou d'une machine virtuelle.

## Le debian-installer (d-i)

### Historique et architecture

Le debian-installer a été introduit avec Debian 3.1 (Sarge) en 2005, en remplacement de l'ancien installateur (*boot-floppies*). Il a été conçu dès l'origine avec une architecture **modulaire** : chaque étape de l'installation est gérée par un composant indépendant appelé **udeb** (*micro-deb*), un format de paquet allégé spécifique au contexte d'installation. Cette modularité permet au d-i de s'adapter à des scénarios très variés — de l'installation graphique sur un poste de travail à l'installation automatisée par le réseau sur des centaines de serveurs — sans duplication de code.

### Modes d'installation

Le debian-installer propose plusieurs modes d'interaction pour s'adapter aux différents contextes.

**Le mode texte** (interface *newt*) est le mode historique et le plus universel. Il fonctionne sur n'importe quel matériel, y compris les consoles série, les connexions SSH et les terminaux les plus basiques. C'est le mode recommandé pour les installations serveur et le mode de repli lorsque le mode graphique pose problème.

**Le mode graphique** (interface *GTK*) offre une interface visuelle avec support de la souris, des polices Unicode et des langues nécessitant des caractères complexes (arabe, chinois, japonais, coréen). Les étapes et les options sont strictement identiques au mode texte — seule la présentation change. Dans Debian 13 (Trixie), l'entrée « Graphical install » est **sélectionnée par défaut** dans le menu d'amorçage de l'installateur ; l'entrée « Install » lance le mode texte traditionnel.

**Le mode expert** est accessible dans les deux interfaces (texte et graphique) et expose la totalité des options de configuration, y compris celles qui sont normalement masquées ou configurées automatiquement. Ce mode est recommandé pour les administrateurs qui souhaitent un contrôle total sur chaque paramètre.

**Le mode automatisé (preseed)** permet de fournir un fichier de réponses pré-remplies au d-i, supprimant toute interaction humaine pendant l'installation. Ce mécanisme est indispensable pour les déploiements à grande échelle et sera abordé dans le module 7 (Debian Server).

### Accessibilité

Le debian-installer intègre un support d'accessibilité notable : un mode de synthèse vocale (via *speakup* et *espeakup*) permet aux utilisateurs malvoyants de réaliser l'installation de manière autonome. Un afficheur braille est également supporté. Cette attention à l'accessibilité dès l'installateur reflète l'engagement de Debian envers l'universalité.

## Les étapes de l'installation

Le processus d'installation suit une séquence logique que les sous-sections suivantes détailleront une par une. Voici une vue d'ensemble de ce parcours pour en comprendre l'enchaînement global.

**Préparation du support d'installation (1.2.1)** — Avant de démarrer, il faut obtenir et préparer le média d'installation : téléchargement de l'image ISO appropriée, vérification de son intégrité, et écriture sur le support choisi (clé USB, DVD, ou mise en place d'un serveur PXE).

**Choix du type d'installation (1.2.2)** — Debian offre plusieurs vecteurs d'installation, chacun adapté à un contexte : installation réseau minimale (netinst), image DVD complète, clé USB, ou démarrage par le réseau (PXE). Le choix du vecteur détermine la quantité de données téléchargées pendant l'installation et les prérequis en termes de connectivité réseau.

**Partitionnement du disque (1.2.3)** — L'une des étapes les plus structurantes. Le choix du schéma de partitionnement (GPT vs MBR), de la disposition des partitions et des systèmes de fichiers influence directement la sécurité (séparation des données), la flexibilité (redimensionnement futur avec LVM), et la résilience (RAID logiciel) du système.

**Configuration réseau de base (1.2.4)** — Le d-i configure la connectivité réseau nécessaire au fonctionnement du système : nom d'hôte, domaine, configuration de l'interface réseau principale (DHCP ou adresse statique). Pour les installations netinst et PXE, cette étape est requise dès le début du processus afin de télécharger les paquets depuis les dépôts distants.

**Sélection des paquets de base (1.2.5)** — En fin d'installation, le d-i propose de sélectionner des ensembles de logiciels via **tasksel** : environnement de bureau (GNOME, KDE, XFCE…), serveur web, serveur SSH, outils standard du système. Cette sélection détermine le profil initial du système, qui pourra être modifié à tout moment après l'installation via APT.

## Prérequis matériels

Les prérequis matériels de Debian sont modestes par rapport aux standards actuels, ce qui est l'un de ses atouts.

Pour une **installation minimale** (serveur en ligne de commande, sans interface graphique), Debian nécessite un processeur compatible avec l'une des architectures supportées par Trixie (`amd64`, `arm64`, `armhf`, `armel`, `ppc64el`, `riscv64`, `s390x` — toutes 64 bits sauf `armel` et `armhf`), un minimum de **512 Mo de RAM** (256 Mo sont théoriquement suffisants mais rendent l'installation inconfortable), et un espace disque d'environ **2 Go** pour le système de base. Rappel : Debian 13 ne propose plus de noyau d'installation 32 bits pour PC (`i386`).

Pour une **installation desktop** avec environnement graphique complet (GNOME), les recommandations pratiques sont d'au moins **2 Go de RAM** (4 Go recommandés pour un usage confortable), un espace disque de **10 Go** minimum (20 Go recommandés pour disposer d'une marge), et un processeur raisonnablement récent (les machines de moins de 10-15 ans conviennent généralement).

Pour un **serveur de production**, les prérequis dépendent fortement de la charge de travail prévue. Le dimensionnement du stockage, de la mémoire et du processeur est un exercice d'architecture spécifique à chaque cas d'usage, abordé dans les modules suivants.

## Bonnes pratiques avant de commencer

Quelques principes à garder à l'esprit avant de lancer une installation.

**Vérifier la compatibilité matérielle.** Consulter la liste de compatibilité matérielle Debian (HCL, *Hardware Compatibility List*) et vérifier que les composants critiques (carte réseau, contrôleur de stockage) sont supportés par le noyau inclus dans le d-i. Depuis Debian 12, l'inclusion des firmwares non libres dans les images officielles a considérablement réduit les problèmes de compatibilité, mais certains matériels très récents peuvent encore nécessiter un noyau plus récent, disponible via les backports après installation.

**Planifier le partitionnement.** Le partitionnement est difficile à modifier après l'installation (sauf si LVM est utilisé). Prendre le temps de réfléchir au schéma de partitions avant de démarrer l'installateur évite des réinstallations ultérieures.

**Disposer d'une connexion réseau.** Même pour une installation depuis un DVD complet, une connexion réseau est recommandée pour récupérer les dernières mises à jour de sécurité dès l'installation.

**Sauvegarder les données existantes.** Si le disque d'installation contient déjà des données (dual-boot, réinstallation), effectuer une sauvegarde complète avant toute opération de partitionnement.

**Documenter ses choix.** Pour un déploiement en production, noter les choix effectués à chaque étape de l'installation facilite la reproductibilité et la documentation du système.

## Sous-sections

Les sous-sections qui suivent détaillent chaque étape du processus d'installation :

- **1.2.1 — Préparation du support d'installation** : obtention des images ISO, vérification d'intégrité, création du média bootable.
- **1.2.2 — Types d'installation (Netinst, DVD, USB, PXE)** : caractéristiques et critères de choix de chaque méthode.
- **1.2.3 — Partitionnement du disque (GPT vs MBR, schémas recommandés)** : stratégies de partitionnement adaptées aux différents contextes.
- **1.2.4 — Configuration réseau de base** : paramètres réseau définis pendant l'installation.
- **1.2.5 — Sélection des paquets de base (tasksel)** : choix du profil logiciel initial du système.

---

> **Navigation**  
>  
> Section précédente : [1.1.5 Architecture du système Debian](/module-01-fondamentaux-debian/01.5-architecture-systeme.md)  
>  
> Section suivante : [1.2.1 Préparation du support d'installation](/module-01-fondamentaux-debian/02.1-preparation-support.md)  
>  
> Retour au sommaire du module : [Module 1 — Fondamentaux de Debian](/module-01-fondamentaux-debian.md)

⏭️ [Préparation du support d'installation](/module-01-fondamentaux-debian/02.1-preparation-support.md)
