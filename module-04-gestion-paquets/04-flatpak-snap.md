🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 4.4 Flatpak et Snap

## Introduction

Les sections précédentes ont couvert le système de paquets natif de Debian — APT, dpkg, les dépôts et leur gestion. Ce système, mûri depuis plus de vingt-cinq ans, excelle dans la cohérence du système, la résolution de dépendances partagées et l'intégration fine avec le système d'exploitation. Il présente cependant une limitation structurelle : les paquets `.deb` sont compilés contre les bibliothèques d'une version spécifique de Debian, ce qui lie étroitement la version d'une application à celle de la distribution.

Flatpak et Snap représentent une approche fondamentalement différente de la distribution de logiciels. Plutôt que de partager les bibliothèques du système, chaque application embarque ses propres dépendances dans un environnement isolé (sandboxé). Cette architecture découple le cycle de vie de l'application de celui de la distribution, permettant à un développeur de publier une version unique de son application fonctionnant sur Debian, Ubuntu, Fedora et toute autre distribution Linux, indépendamment de la version des bibliothèques système.

Cette section présente ces deux technologies, leur positionnement par rapport au système natif Debian, leurs cas d'usage légitimes et les considérations pratiques pour un administrateur Debian.

---

## 1. Le problème que résolvent Flatpak et Snap

### 1.1 Les limites du modèle de paquets traditionnels

Le modèle de paquets natifs (`.deb`, `.rpm`) repose sur un principe de bibliothèques partagées : une seule copie de `libssl3` ou `libgtk-4` est installée sur le système et partagée par toutes les applications qui en dépendent. Ce modèle est efficace en termes d'espace disque et de mémoire, et il garantit que les correctifs de sécurité appliqués à une bibliothèque profitent instantanément à toutes les applications qui l'utilisent.

Cependant, ce couplage crée des contraintes :

**Cycle de publication lié à la distribution.** Un développeur d'application qui souhaite utiliser une fonctionnalité récente d'une bibliothèque doit attendre que la distribution intègre cette version. Sur Debian stable, cela peut signifier un décalage de plusieurs années.

**Difficulté de distribution multi-distribution.** Le développeur doit construire et maintenir des paquets séparés pour chaque version de chaque distribution (Debian 12, Debian 13, Ubuntu 24.04 LTS, Ubuntu 26.04 LTS, Fedora 42, Fedora 43, etc.), chacun avec ses propres versions de bibliothèques.

**Conflits de versions.** Deux applications ne peuvent pas dépendre de deux versions incompatibles de la même bibliothèque sur un système traditionnel.

### 1.2 L'approche par isolation

Flatpak et Snap résolvent ces problèmes en isolant chaque application dans son propre environnement :

- Chaque application embarque les bibliothèques dont elle a besoin (ou les obtient via un runtime partagé entre applications Flatpak/Snap).
- L'application est sandboxée : elle ne peut accéder qu'aux ressources du système pour lesquelles elle a reçu une autorisation explicite (fichiers, réseau, périphériques, etc.).
- Le format de distribution est universel : un seul paquet Flatpak ou Snap fonctionne sur toute distribution Linux supportant le framework.

### 1.3 Analogie avec d'autres écosystèmes

Cette approche n'est pas propre à Linux. Elle s'apparente au modèle des applications macOS (bundles `.app` autonomes), des applications Windows modernes (MSIX/AppX avec isolation) ou des conteneurs applicatifs (Docker). Dans chaque cas, l'objectif est de découpler l'application de l'environnement d'exécution sous-jacent.

---

## 2. Flatpak

### 2.1 Origine et gouvernance

Flatpak est un projet open source né en 2015, initialement sous le nom de « xdg-app », développé principalement par Red Hat et la communauté GNOME. Il est hébergé par la fondation freedesktop.org et bénéficie d'une gouvernance communautaire ouverte. Flatpak est le format de distribution recommandé par GNOME et par de nombreuses distributions Linux pour les applications desktop.

### 2.2 Architecture

L'architecture de Flatpak repose sur trois concepts fondamentaux :

**Les runtimes** sont des ensembles de bibliothèques partagées qui forment la base d'exécution des applications. Les principaux runtimes sont `org.freedesktop.Platform` (bibliothèques de base : glibc, mesa, etc.), `org.gnome.Platform` (bibliothèques GNOME) et `org.kde.Platform` (bibliothèques KDE). Les runtimes sont versionnés et plusieurs versions coexistent sur le système. Une application déclare le runtime et la version qu'elle utilise.

**Les applications** sont des paquets qui contiennent le code de l'application et ses dépendances spécifiques (celles qui ne sont pas couvertes par le runtime). Chaque application est identifiée par un identifiant inversé de type DNS (par exemple `org.mozilla.firefox`, `com.spotify.Client`).

**Les dépôts (remotes)** sont des serveurs distribuant des runtimes et des applications. Le dépôt principal est Flathub (`https://flathub.org`), qui héberge plusieurs milliers d'applications.

### 2.3 Sandboxing

Le sandboxing de Flatpak repose sur plusieurs technologies du noyau Linux :

- **Namespaces** — Isolation des espaces de noms (PID, réseau, montage, utilisateur).
- **Seccomp** — Filtrage des appels système autorisés.
- **cgroups** — Limitation des ressources.
- **Portals** (xdg-desktop-portal) — API sécurisée permettant à l'application sandboxée de demander l'accès à des ressources du système (sélection de fichiers, accès à la caméra, notifications) avec le consentement de l'utilisateur.

Le niveau de sandboxing est configurable par application via les permissions. Certaines applications demandent des permissions étendues qui réduisent l'isolation (accès complet au système de fichiers, session D-Bus, réseau hôte).

### 2.4 Flathub

Flathub est le dépôt centralisé de référence pour Flatpak. Il héberge à la fois des applications libres et propriétaires. Depuis 2023, Flathub a introduit un processus de vérification des éditeurs : les applications publiées par un éditeur vérifié portent un badge de confiance.

La qualité et la sécurité des applications sur Flathub varient. Les applications vérifiées par leur éditeur d'origine (Mozilla pour Firefox, Valve pour Steam) offrent un niveau de confiance élevé. Les applications empaquetées par des tiers sont soumises à une revue communautaire mais le niveau de garantie est moindre.

---

## 3. Snap

### 3.1 Origine et gouvernance

Snap est un système de paquets développé et contrôlé par Canonical, l'entreprise derrière Ubuntu. Le format Snap et le client `snapd` sont open source, mais le Snap Store (le dépôt centralisé) est propriétaire et opéré exclusivement par Canonical. Il n'est pas possible d'héberger un Snap Store alternatif de manière officielle, bien que des projets communautaires tentent de fournir des alternatives.

Ce point de gouvernance est un sujet de débat dans la communauté Linux : contrairement à Flatpak/Flathub où l'infrastructure est ouverte et décentralisable, Snap repose sur une infrastructure centralisée contrôlée par une seule entreprise.

### 3.2 Architecture

L'architecture de Snap diffère de celle de Flatpak :

**Les Snaps** sont des paquets au format SquashFS (système de fichiers compressé en lecture seule) qui contiennent l'application et toutes ses dépendances. Chaque Snap est monté en tant que système de fichiers au démarrage, ce qui crée des points de montage visibles dans la sortie de `mount` et `df`.

**Le daemon snapd** est un service système qui gère l'installation, les mises à jour et le sandboxing des Snaps. Il fonctionne en permanence en arrière-plan.

**Les interfaces** sont le mécanisme de permissions de Snap. Chaque Snap déclare les interfaces qu'il requiert (accès réseau, accès aux fichiers, accès à la caméra, etc.) et l'administrateur peut les connecter ou les déconnecter.

**Les canaux** (channels) permettent de suivre différents niveaux de stabilité : `stable`, `candidate`, `beta`, `edge`.

### 3.3 Sandboxing

Le sandboxing de Snap utilise AppArmor (sur les systèmes qui le supportent, comme Ubuntu et Debian) et Seccomp. Le niveau d'isolation est similaire à celui de Flatpak, avec des différences dans l'implémentation :

- Sur les systèmes avec AppArmor activé et configuré, l'isolation est complète.
- Sur les systèmes sans AppArmor (ou avec un AppArmor en mode complain), certains Snaps fonctionnent en mode « classic » (sans sandbox), ce qui réduit la sécurité à celle d'un paquet natif.

### 3.4 Snap Store

Le Snap Store est le seul dépôt officiel pour les Snaps. Il est accessible à `https://snapcraft.io`. Canonical effectue une revue automatisée des Snaps soumis, mais des incidents de sécurité ont été rapportés (Snaps contenant des cryptomineurs, par exemple), ce qui souligne que la revue automatisée a des limites.

---

## 4. Position de Debian vis-à-vis de Flatpak et Snap

### 4.1 Flatpak dans Debian

Flatpak est disponible dans les dépôts officiels de Debian :

```bash
apt search flatpak
# flatpak - Application deployment framework for desktop apps
```

Debian fournit le framework Flatpak et ses dépendances. Flathub n'est pas configuré par défaut : l'ajout du remote Flathub est une action explicite de l'administrateur.

La communauté Debian considère Flatpak comme un complément acceptable au système de paquets natifs pour les applications desktop, en particulier pour les logiciels propriétaires ou les applications à cycle de publication rapide.

### 4.2 Snap dans Debian

La relation entre Debian et Snap est plus nuancée. Le daemon `snapd` est disponible dans les dépôts Debian mais n'est pas installé par défaut. Contrairement à Ubuntu, où Snap est profondément intégré au système (certaines applications par défaut, comme Firefox, sont distribuées en tant que Snaps), Debian maintient une approche neutre où les paquets natifs `.deb` restent la méthode privilégiée.

La dépendance au Snap Store propriétaire de Canonical et l'impossibilité de le décentraliser sont des préoccupations pour le projet Debian, qui valorise la liberté logicielle et l'indépendance vis-à-vis des fournisseurs.

### 4.3 Recommandation Debian

La position implicite du projet Debian est claire : les paquets `.deb` natifs sont la méthode d'installation par défaut et recommandée. Flatpak et Snap sont des outils complémentaires pour des cas d'usage spécifiques, principalement les postes de travail. Sur les serveurs, leur utilisation est rare et généralement non recommandée (les conteneurs Docker/Podman étant préférés pour l'isolation d'applications serveur).

---

## 5. Cas d'usage légitimes

### 5.1 Quand Flatpak ou Snap sont pertinents

**Applications propriétaires desktop.** Des logiciels comme Spotify, Discord, Slack, Zoom ou Steam sont souvent distribués en Flatpak ou Snap par leurs éditeurs. C'est le canal de distribution supporté et à jour.

**Applications à cycle rapide.** Des logiciels comme les navigateurs web, les IDE (VS Code, IntelliJ), les outils de communication ou les clients de jeux évoluent rapidement. Les versions Flatpak/Snap suivent le rythme de l'éditeur sans attendre le cycle de Debian.

**Applications graphiques nécessitant des bibliothèques récentes.** Certaines applications GUI dépendent de versions récentes de GTK, Qt ou d'autres bibliothèques de rendu que Debian stable ne fournit pas.

**Isolation d'applications non fiables.** Le sandboxing de Flatpak/Snap offre une couche de protection supplémentaire pour les applications dont le code source n'est pas auditable.

**Coexistence de versions.** Flatpak et Snap permettent d'installer plusieurs versions d'une même application simultanément, ce qui est impossible avec les paquets natifs.

### 5.2 Quand rester sur les paquets natifs

**Serveurs.** Flatpak et Snap ne sont pas conçus pour les services serveur. Les paquets natifs ou les conteneurs (Docker, Podman) sont les outils appropriés.

**Applications en ligne de commande.** Les outils CLI sont généralement disponibles dans les dépôts Debian et ne bénéficient pas du sandboxing desktop de Flatpak/Snap.

**Intégration système profonde.** Les applications qui doivent interagir étroitement avec le système (pilotes, services système, outils d'administration) ne fonctionnent pas bien dans un environnement sandboxé.

**Environnements à espace disque limité.** Les Flatpaks et Snaps consomment significativement plus d'espace disque que les paquets natifs en raison de la duplication des bibliothèques et des runtimes.

**Systèmes d'entreprise avec politique de sécurité stricte.** La dépendance à des dépôts externes (Flathub, Snap Store) peut être incompatible avec les politiques de sécurité qui exigent un contrôle total sur les sources de logiciels.

---

## 6. Comparaison synthétique

| Critère | Paquets natifs (`.deb`) | Flatpak | Snap |
|---------|------------------------|---------|------|
| Intégration système | Excellente | Bonne (desktop) | Variable |
| Isolation/sandboxing | Aucune | Bonne (portals) | Bonne (AppArmor) |
| Espace disque | Minimal (bibliothèques partagées) | Modéré (runtimes partagés) | Élevé (tout embarqué) |
| Mises à jour | Contrôlées par l'administrateur | Automatiques ou manuelles | Automatiques (par défaut) |
| Dépôt principal | Archives Debian (ouvertes) | Flathub (ouvert) | Snap Store (propriétaire) |
| Décentralisation | Miroirs, dépôts locaux | Remotes personnalisés possibles | Non décentralisable |
| Cible principale | Tout (desktop, serveur, embarqué) | Desktop | Desktop et serveur (limité) |
| Disponibilité hors ligne | Oui (cache APT, miroir local) | Possible (bundles) | Limitée |
| Contrôle de l'administrateur | Total | Élevé | Moindre (mises à jour auto) |
| Usage sur serveur | Recommandé | Non recommandé | Possible mais peu courant |

---

## Ce que couvrent les sous-sections suivantes

Les sous-sections qui suivent détaillent l'aspect pratique :

- **4.4.1 — Installation et configuration** : installation de Flatpak et Snap sur Debian, ajout des dépôts (Flathub, Snap Store), configuration du sandboxing et intégration avec l'environnement de bureau.
- **4.4.2 — Gestion des applications sandboxées** : installation, mise à jour, suppression, gestion des permissions, inspection et résolution de problèmes.
- **4.4.3 — Comparaison Flatpak vs Snap vs `.deb` natif** : analyse détaillée des performances, de la sécurité, de l'espace disque, du temps de démarrage et critères de choix selon le contexte.

## Prérequis

Pour aborder cette section :

- Maîtrise du système de paquets natif Debian (sections 4.1 à 4.3).
- Familiarité avec les concepts de sandboxing et de namespaces Linux (introduits ici, approfondis dans le Module 10).
- Connaissance de base de l'environnement de bureau Debian (Module 2) pour les aspects d'intégration desktop.

⏭️ [Installation et configuration](/module-04-gestion-paquets/04.1-installation-configuration.md)
