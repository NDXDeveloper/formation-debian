🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 2.1 Environnements de bureau

## Introduction

L'une des forces majeures de Debian réside dans sa capacité à offrir un large choix d'environnements de bureau (Desktop Environments, ou DE). Contrairement à de nombreux systèmes d'exploitation qui imposent une interface graphique unique, Debian permet à l'utilisateur de sélectionner, installer et même combiner plusieurs environnements selon ses besoins, ses préférences esthétiques et les capacités matérielles de sa machine.

Un environnement de bureau ne se limite pas à une simple couche graphique posée sur le système. Il constitue un ensemble cohérent de composants logiciels qui définissent l'expérience utilisateur au quotidien : gestionnaire de fenêtres, barre des tâches, gestionnaire de fichiers, gestionnaire de sessions, système de notifications, outils de configuration et souvent une suite d'applications intégrées.

---

## Qu'est-ce qu'un environnement de bureau ?

Un environnement de bureau est une pile logicielle qui fournit une interface graphique complète au-dessus du système d'exploitation. Il se compose de plusieurs couches interdépendantes :

- **Le serveur d'affichage** (Xorg ou Wayland) : il gère la communication entre le matériel graphique et les applications. C'est la fondation sur laquelle repose tout l'affichage graphique.
- **Le gestionnaire de fenêtres** (window manager) : il contrôle le placement, le dimensionnement, la décoration et le comportement des fenêtres à l'écran. Certains gestionnaires de fenêtres fonctionnent de manière autonome (i3, Sway, Openbox), tandis que d'autres sont intégrés à un environnement de bureau complet.
- **Le shell graphique** : il englobe la barre des tâches, le lanceur d'applications, la zone de notifications (system tray), le sélecteur d'espaces de travail et les éléments visuels persistants de l'interface.
- **Le gestionnaire de sessions** : il gère l'authentification de l'utilisateur (écran de connexion), le démarrage de l'environnement, la restauration de la session précédente et la fermeture propre de la session.
- **Les applications intégrées** : gestionnaire de fichiers, terminal, éditeur de texte, visionneuse d'images, utilitaire de capture d'écran, outil de configuration système, etc.
- **Les services d'arrière-plan** : gestion du presse-papiers, indexation des fichiers, gestion de l'alimentation, contrôle du volume audio, gestion des réseaux, notifications, etc.

### Distinction entre environnement de bureau et gestionnaire de fenêtres

Il est important de ne pas confondre ces deux notions. Un gestionnaire de fenêtres est un composant unique, responsable uniquement du comportement des fenêtres. Un environnement de bureau est un ensemble complet qui inclut un gestionnaire de fenêtres mais aussi tous les éléments mentionnés ci-dessus.

Un utilisateur avancé peut tout à fait n'installer qu'un gestionnaire de fenêtres seul (comme i3, Sway ou Openbox) et construire son propre environnement de travail en assemblant des outils individuels. Cette approche offre un contrôle total et une consommation de ressources minimale, mais elle demande un investissement significatif en temps et en configuration.

À l'inverse, un environnement de bureau complet offre une expérience intégrée et cohérente dès l'installation, au prix d'une consommation de ressources plus élevée.

---

## Les environnements de bureau disponibles sous Debian

Debian propose officiellement plusieurs environnements de bureau, tous disponibles dans les dépôts officiels. Voici les principaux, classés par catégorie :

### Environnements complets (full-featured)

| Environnement | Version Trixie | Toolkit | Serveur d'affichage | RAM minimale recommandée | Philosophie |
|---------------|----------------|---------|---------------------|--------------------------|-------------|
| **GNOME** | 48 | GTK4 / libadwaita | Wayland (défaut), Xorg | ~2 Go | Simplicité, modernité, flux de travail centré sur les activités |
| **KDE Plasma** | 6.3 | Qt 6 / QML | Wayland (défaut), Xorg | ~1,5 Go | Personnalisation poussée, richesse fonctionnelle |

### Environnements légers

| Environnement | Toolkit | Serveur d'affichage | RAM minimale recommandée | Philosophie |
|---------------|---------|---------------------|--------------------------|-------------|
| **XFCE** | GTK3 | Xorg | ~512 Mo | Légèreté, stabilité, interface classique |
| **LXQt** | Qt | Xorg (Wayland expérimental) | ~256 Mo | Ultra-léger, modulaire |
| **LXDE** | GTK2 | Xorg | ~256 Mo | Minimalisme, machines anciennes |
| **MATE** | GTK3 | Xorg | ~512 Mo | Continuation de GNOME 2, interface traditionnelle |
| **Cinnamon** | GTK3 | Xorg (Wayland expérimental) | ~1 Go | Modernité avec métaphore de bureau classique |
| **Budgie** | GTK3 | Xorg | ~768 Mo | Élégance, simplicité moderne |

### Gestionnaires de fenêtres en mosaïque (tiling)

Pour les utilisateurs qui préfèrent un contrôle clavier total et une gestion automatique du placement des fenêtres, Debian propose également dans ses dépôts des gestionnaires de fenêtres en mosaïque tels que **i3** (Xorg) et **Sway** (Wayland, compatible i3). **Hyprland**, un compositeur Wayland très populaire pour son esthétique et ses animations, a été retiré de Trixie en juin 2025 (la version packagée n'aurait pas pu être maintenue sur la durée de vie de la stable) ; il est désormais disponible via les **backports** de Debian 13 — l'installation se fait avec `apt install -t trixie-backports hyprland`, mais des problèmes de dépendances peuvent se présenter (Hyprland évoluant rapidement, certaines bibliothèques requises peuvent être plus récentes que celles de la stable). Bien qu'il ne s'agisse pas d'environnements de bureau à proprement parler, ces compositeurs méritent d'être mentionnés car ils représentent une approche radicalement différente de l'interaction avec le système.

---

## Critères de choix d'un environnement de bureau

Le choix d'un environnement de bureau dépend de plusieurs facteurs qui doivent être évalués selon le contexte d'utilisation :

### Ressources matérielles disponibles

C'est souvent le premier critère déterminant. Sur une machine récente dotée de 8 Go de RAM ou plus, tous les environnements fonctionneront confortablement. Sur une machine plus ancienne ou un ordinateur mono-carte (Raspberry Pi, par exemple), un environnement léger comme XFCE ou LXQt sera nettement plus adapté. GNOME et KDE Plasma ont considérablement amélioré leurs performances au fil des versions, mais ils restent plus gourmands que les alternatives légères.

### Usage prévu

Un poste de travail destiné à de la bureautique classique n'a pas les mêmes exigences qu'un poste de développement ou qu'une station de montage vidéo. GNOME propose un flux de travail épuré qui convient bien à la productivité. KDE Plasma offre une flexibilité qui plaît aux utilisateurs souhaitant adapter finement leur espace de travail. XFCE est souvent recommandé pour les postes de travail d'entreprise en raison de sa stabilité et de sa faible consommation.

### Familiarité et transition depuis un autre système

Les utilisateurs venant de Windows se sentiront généralement plus à l'aise avec KDE Plasma, Cinnamon ou XFCE, dont la métaphore de bureau (barre des tâches en bas, menu démarrer, bureau avec icônes) est familière. Les utilisateurs venant de macOS retrouveront certains paradigmes dans GNOME, qui privilégie une approche épurée avec une barre supérieure et un système d'activités. Il ne s'agit toutefois que de points de départ : chaque environnement est hautement configurable.

### Accessibilité

GNOME est l'environnement de bureau qui offre le support d'accessibilité le plus complet sous Linux, avec une intégration native du lecteur d'écran Orca, un mode de contraste élevé, un zoom d'écran, et des options de clavier virtuel. Si l'accessibilité est un besoin prioritaire, GNOME est le choix le plus abouti.

### Support Wayland

La transition de Xorg vers Wayland est en cours dans l'écosystème Linux. GNOME et KDE Plasma utilisent désormais Wayland par défaut dans Debian, ce qui apporte de meilleures performances, une sécurité renforcée (isolation des applications) et une meilleure gestion des écrans HiDPI et multi-écrans. Les environnements plus légers restent majoritairement sur Xorg, bien que des ports Wayland soient en développement. Ce sujet est approfondi dans la section 2.1.5.

---

## Installation d'un environnement de bureau sous Debian

### Lors de l'installation du système

L'installateur Debian propose la sélection d'un environnement de bureau lors de l'étape **tasksel**. Par défaut, GNOME est présélectionné. L'utilisateur peut choisir un autre environnement ou même en sélectionner plusieurs simultanément (bien que cela ne soit pas recommandé pour les débutants, car cela peut entraîner des conflits visuels et des doublons d'applications).

### Après l'installation

Il est tout à fait possible d'installer un nouvel environnement de bureau après l'installation initiale du système. Debian utilise des méta-paquets (appelés **tasks**) qui regroupent l'ensemble des composants nécessaires à un environnement complet :

```bash
# Lister les environnements disponibles via tasksel
tasksel --list-tasks | grep desktop

# Installer un environnement complet via tasksel
sudo tasksel install kde-desktop

# Ou via apt directement avec les méta-paquets
sudo apt install task-gnome-desktop  
sudo apt install task-kde-desktop  
sudo apt install task-xfce-desktop  
sudo apt install task-lxde-desktop  
sudo apt install task-lxqt-desktop  
sudo apt install task-mate-desktop  
sudo apt install task-cinnamon-desktop  
```

Chaque méta-paquet `task-*-desktop` installe l'environnement de bureau complet ainsi que les applications associées. Pour une installation plus minimale, on peut installer uniquement le cœur de l'environnement :

```bash
# Installation minimale (environnement seul, sans applications complémentaires)
sudo apt install gnome-core  
sudo apt install kde-plasma-desktop  
sudo apt install xfce4  
sudo apt install lxqt  
```

### Cohabitation de plusieurs environnements

Debian permet d'installer plusieurs environnements de bureau en parallèle. Le gestionnaire de connexion (GDM, SDDM, LightDM) propose alors un sélecteur permettant de choisir l'environnement souhaité à chaque ouverture de session.

Cette approche présente quelques inconvénients à connaître : les menus d'applications peuvent devenir encombrés (les applications GNOME apparaissent dans KDE et inversement), les fichiers de configuration peuvent entrer en conflit, et l'espace disque consommé augmente significativement. En règle générale, il est préférable de choisir un environnement principal et de n'installer que quelques applications individuelles d'un autre environnement si nécessaire.

---

## Le gestionnaire de connexion (Display Manager)

Le gestionnaire de connexion est le premier élément graphique que l'utilisateur voit au démarrage. Il gère l'authentification et le lancement de la session graphique. Chaque environnement de bureau a ses préférences :

| Gestionnaire de connexion | Environnement associé | Caractéristiques |
|---------------------------|----------------------|-------------------|
| **GDM3** (GNOME Display Manager) | GNOME | Support Wayland natif, intégration GNOME |
| **SDDM** (Simple Desktop Display Manager) | KDE Plasma | Thèmes QML, support Wayland |
| **LightDM** | XFCE, LXDE, LXQt, Budgie | Léger, très configurable, multi-greeters |

Lorsque plusieurs gestionnaires de connexion sont installés, Debian demande à l'utilisateur de choisir celui qu'il souhaite utiliser par défaut. Ce choix peut être modifié ultérieurement avec :

```bash
sudo dpkg-reconfigure gdm3
# ou
sudo dpkg-reconfigure sddm
# ou
sudo dpkg-reconfigure lightdm
```

---

## Résumé

Le choix d'un environnement de bureau sous Debian est une décision qui influence considérablement l'expérience quotidienne d'utilisation du système. Debian se distingue par la richesse de son offre : des environnements complets et modernes comme GNOME et KDE Plasma aux solutions ultra-légères comme LXQt, en passant par les gestionnaires de fenêtres minimalistes pour les utilisateurs avancés.

Les sections suivantes détaillent les environnements les plus populaires et les plus pertinents dans le contexte de cette formation : GNOME (environnement par défaut de Debian), KDE Plasma, XFCE et LXDE. La section 2.1.4 couvre l'installation et la configuration détaillée des environnements, tandis que la section 2.1.5 approfondit la distinction entre Wayland et Xorg, un sujet central pour comprendre l'avenir de l'affichage graphique sous Linux.

⏭️ [GNOME (environnement par défaut)](/module-02-debian-desktop/01.1-gnome.md)
