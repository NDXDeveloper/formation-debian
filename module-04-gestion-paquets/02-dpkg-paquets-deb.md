🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 4.2 Dpkg et paquets .deb

## Introduction

Si APT est le chef d'orchestre de la gestion des paquets Debian, dpkg en est le moteur d'exécution. Chaque opération d'installation, de suppression ou de mise à jour finit, en dernière instance, par un appel à dpkg. Comprendre dpkg et le format `.deb` est indispensable pour tout administrateur Debian : c'est à ce niveau que l'on intervient lorsqu'APT atteint ses limites — installation d'un paquet hors dépôt, diagnostic d'un conflit de fichiers, inspection du contenu d'un paquet avant déploiement, ou récupération d'un système dont la base de paquets est corrompue.

Cette section présente dpkg et le format `.deb` en profondeur : leur positionnement dans l'architecture de gestion des paquets, la structure interne d'un paquet, les mécanismes d'installation et la base de données dpkg.

---

## 1. Positionnement de dpkg dans l'écosystème

### 1.1 Architecture à deux niveaux

La gestion des paquets sous Debian repose sur une séparation nette des responsabilités entre deux couches :

**dpkg (niveau bas)** opère sur des paquets individuels. Il sait décompresser un fichier `.deb`, en extraire les fichiers, exécuter les scripts de maintenance, enregistrer l'état du paquet dans sa base de données et vérifier l'intégrité des fichiers installés. En revanche, dpkg ne sait pas télécharger de paquets, ne connaît pas les dépôts et ne résout pas les dépendances automatiquement. Si un paquet A dépend d'un paquet B qui n'est pas installé, dpkg signalera l'erreur mais ne tentera pas d'installer B de lui-même.

**APT (niveau haut)** ajoute l'intelligence réseau et la résolution de dépendances. Il consulte les dépôts, calcule l'arbre de dépendances, télécharge les paquets nécessaires, puis délègue l'installation effective à dpkg.

Cette architecture offre un avantage important : dpkg est un outil déterministe et prévisible. Lorsqu'on lui demande d'installer un paquet, il fait exactement cela — ni plus, ni moins. C'est cette prévisibilité qui en fait l'outil de choix pour le diagnostic, la réparation et les opérations manuelles de bas niveau.

### 1.2 Quand utiliser dpkg plutôt qu'APT

Bien que la recommandation générale soit d'utiliser APT pour les opérations courantes, dpkg reste indispensable dans plusieurs situations :

- Installer un fichier `.deb` récupéré manuellement (bien que `apt install ./fichier.deb` soit désormais possible, dpkg offre un contrôle plus fin).
- Diagnostiquer un problème d'installation en examinant les scripts de maintenance et les messages d'erreur détaillés.
- Lister les fichiers installés par un paquet ou identifier à quel paquet appartient un fichier donné.
- Vérifier l'intégrité des fichiers installés (sommes de contrôle).
- Forcer une opération qu'APT refuse (suppression d'un paquet malgré des dépendances inversées, extraction sans installation).
- Reconfigurer un paquet ou relancer ses scripts de post-installation.
- Réparer une base de données dpkg corrompue.
- Inspecter le contenu d'un paquet `.deb` sans l'installer.

---

## 2. Anatomie d'un paquet `.deb`

### 2.1 Format de l'archive

Un fichier `.deb` est une archive `ar` (format Unix standard) contenant exactement trois éléments, dans cet ordre :

1. **`debian-binary`** — Un fichier texte contenant le numéro de version du format `.deb`. Pour tous les paquets actuels, cette valeur est `2.0`.

2. **`control.tar.xz`** (ou `control.tar.gz`, `control.tar.zst`) — Une archive compressée contenant les métadonnées du paquet : fichier de contrôle, scripts de maintenance, sommes de contrôle des fichiers, etc.

3. **`data.tar.xz`** (ou `data.tar.gz`, `data.tar.zst`) — Une archive compressée contenant les fichiers qui seront effectivement installés sur le système, organisés selon leur chemin absolu (`./usr/bin/`, `./etc/`, etc.).

On peut vérifier cette structure avec la commande `ar` :

```bash
ar t nginx_1.26.0-2_amd64.deb
# Sortie :
# debian-binary
# control.tar.xz
# data.tar.xz
```

### 2.2 L'archive de contrôle (`control.tar.xz`)

L'archive de contrôle contient les fichiers suivants (tous ne sont pas obligatoires) :

**`control`** — Le fichier de métadonnées principal. C'est le seul fichier obligatoire. Il décrit le paquet : nom, version, architecture, dépendances, description, mainteneur, etc.

Exemple de fichier `control` :

```text
Package: nginx  
Version: 1.26.0-2  
Architecture: amd64  
Maintainer: Debian Nginx Maintainers <pkg-nginx-maintainers@alioth-lists.debian.net>  
Installed-Size: 892  
Depends: libc6 (>= 2.34), libpcre2-8-0 (>= 10.22), libssl3 (>= 3.0.0), zlib1g (>= 1:1.2.0)  
Recommends: logrotate  
Section: httpd  
Priority: optional  
Homepage: https://nginx.org  
Description: small, powerful, scalable web/proxy server  
 Nginx ("engine X") is a high-performance web and reverse proxy server
 created by Igor Sysoev. It can be used both as a standalone web server
 and as a proxy to reduce the load on back-end HTTP or mail servers.
```

Les champs principaux sont :

- `Package` — Nom du paquet (minuscules, chiffres, tirets, points).
- `Version` — Version au format Debian : `[epoch:]version_amont-revision_debian`.
- `Architecture` — Plateforme cible (`amd64`, `arm64`, `all` pour les paquets indépendants de l'architecture).
- `Depends`, `Pre-Depends`, `Recommends`, `Suggests`, `Conflicts`, `Breaks`, `Replaces`, `Provides` — Relations avec les autres paquets (détaillées en 4.1.1).
- `Installed-Size` — Estimation de l'espace disque requis (en kilooctets).
- `Section` — Catégorie thématique (`admin`, `net`, `httpd`, `libs`, `devel`, etc.).
- `Priority` — Niveau d'importance (`required`, `important`, `standard`, `optional`).
- `Description` — Description courte (première ligne) et longue (lignes suivantes, indentées d'un espace).

**`conffiles`** — Liste des fichiers de configuration gérés par dpkg. Chaque fichier listé ici bénéficiera d'un traitement spécial lors des mises à jour : si l'administrateur l'a modifié, dpkg demandera s'il faut conserver la version locale ou la remplacer par la nouvelle version du paquet.

```text
/etc/nginx/nginx.conf
/etc/nginx/mime.types
/etc/logrotate.d/nginx
```

**`md5sums`** (ou `sha256sums`) — Sommes de contrôle de tous les fichiers du paquet. Utilisé pour vérifier l'intégrité des fichiers installés.

**`preinst`** — Script exécuté avant l'installation ou la mise à jour du paquet.

**`postinst`** — Script exécuté après l'installation ou la mise à jour. C'est ici que se trouvent généralement les actions de configuration : création d'utilisateurs système, activation de services systemd, génération de fichiers de configuration initiaux.

**`prerm`** — Script exécuté avant la suppression du paquet. Typiquement, il arrête les services associés.

**`postrm`** — Script exécuté après la suppression. Il nettoie les fichiers générés dynamiquement, supprime les utilisateurs système créés par le paquet, etc.

**`triggers`** — Déclaration des triggers dpkg (mécanisme permettant à un paquet de réagir à des événements déclenchés par d'autres paquets).

**`shlibs`** ou **`symbols`** — Informations sur les bibliothèques partagées fournies par le paquet, utilisées par dpkg-shlibdeps pour calculer automatiquement les dépendances.

### 2.3 L'archive de données (`data.tar.xz`)

L'archive de données contient l'arborescence des fichiers tels qu'ils seront déposés sur le système de fichiers. Les chemins sont relatifs à la racine :

```bash
# Lister le contenu de l'archive de données
dpkg-deb --contents nginx_1.26.0-2_amd64.deb
# Sortie (extrait) :
# drwxr-xr-x root/root         0 2024-01-15 10:00 ./
# drwxr-xr-x root/root         0 2024-01-15 10:00 ./usr/
# drwxr-xr-x root/root         0 2024-01-15 10:00 ./usr/sbin/
# -rwxr-xr-x root/root    982456 2024-01-15 10:00 ./usr/sbin/nginx
# drwxr-xr-x root/root         0 2024-01-15 10:00 ./etc/
# drwxr-xr-x root/root         0 2024-01-15 10:00 ./etc/nginx/
# -rw-r--r-- root/root      1077 2024-01-15 10:00 ./etc/nginx/nginx.conf
# ...
```

Les permissions, le propriétaire et le groupe de chaque fichier sont préservés lors de l'extraction.

### 2.4 Le schéma de versionnement Debian

La version d'un paquet Debian suit un format précis qui permet à dpkg de comparer les versions et de déterminer laquelle est la plus récente :

```
[epoch:]version_amont[-revision_debian]
```

**epoch** (optionnel) — Un entier positif qui prend la priorité absolue sur le reste de la version. Il est utilisé lorsqu'un changement de schéma de numérotation en amont rend la comparaison classique incorrecte. Par exemple, si un logiciel passe d'une version `20240101` (format date) à `2.0` (format sémantique), `2.0` serait considéré comme inférieur à `20240101` sans epoch. L'ajout de `1:2.0` résout ce problème. L'epoch est séparé du reste par un deux-points (`:`).

**version_amont** — La version du logiciel telle que publiée par son développeur d'origine. Elle peut contenir des chiffres, des lettres, des points, des tildes et des signes plus. Le tilde (`~`) a un comportement spécial : il est trié avant le vide, ce qui fait que `1.0~rc1` est antérieur à `1.0`. Ce mécanisme est utilisé pour les versions bêta et release candidates.

**revision_debian** (optionnel) — Un numéro ajouté par le mainteneur Debian, séparé par un tiret (`-`). Il est incrémenté à chaque modification du paquet Debian (corrections de packaging, patches de sécurité Debian-spécifiques) sans changement de la version amont. Les paquets natifs Debian (développés directement par/pour Debian) n'ont pas de révision Debian.

Exemples de versions triées de la plus ancienne à la plus récente :

```
1.0~alpha1-1
1.0~beta1-1
1.0~rc1-1
1.0-1
1.0-2
1.0-2+deb13u1
1.0.1-1
1:0.5-1          (epoch 1, donc supérieur à tout ce qui précède)
```

Le suffixe `+deb13u1` est une convention Debian indiquant une mise à jour de sécurité spécifique à Debian 13 (Trixie). Le `u1` signifie « update 1 ».

Pour comparer deux versions :

```bash
dpkg --compare-versions "1.0-2" "lt" "1.0.1-1" && echo "vrai" || echo "faux"
# Affiche : vrai (1.0-2 est inférieur à 1.0.1-1)

dpkg --compare-versions "1:0.5" "gt" "2.0" && echo "vrai" || echo "faux"
# Affiche : vrai (epoch 1 est supérieur à l'epoch implicite 0)
```

Les opérateurs de comparaison disponibles sont : `lt` (inférieur strict), `le` (inférieur ou égal), `eq` (égal), `ge` (supérieur ou égal), `gt` (supérieur strict).

---

## 3. La base de données dpkg

### 3.1 Emplacement et structure

La base de données dpkg est stockée dans `/var/lib/dpkg/` et constitue la source de vérité sur l'état de tous les paquets connus du système. Ses composants principaux sont :

**`/var/lib/dpkg/status`** — Le fichier central. Il contient une entrée pour chaque paquet connu du système (installé, supprimé, partiellement installé, etc.), avec ses métadonnées complètes et son état actuel. Ce fichier est au format texte, avec des blocs séparés par des lignes vides, identiques en syntaxe au fichier `control` des paquets.

Extrait typique :

```text
Package: nginx  
Status: install ok installed  
Priority: optional  
Section: httpd  
Installed-Size: 892  
Maintainer: Debian Nginx Maintainers <...>  
Architecture: amd64  
Version: 1.26.3-3  
Depends: libc6 (>= 2.38), libpcre2-8-0 (>= 10.22), libssl3 (>= 3.2.0), zlib1g (>= 1:1.2.0), ...  
Conffiles:  
 /etc/nginx/nginx.conf a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4
 /etc/nginx/mime.types d4c3b2a1f6e5d4c3b2a1f6e5d4c3b2a1
Description: small, powerful, scalable web/proxy server
 ...
```

Le champ `Status` est composé de trois mots décrivant respectivement l'action souhaitée, l'état d'erreur et l'état courant du paquet.

**`/var/lib/dpkg/info/`** — Répertoire contenant, pour chaque paquet installé, les scripts de maintenance et les métadonnées extraits de l'archive de contrôle :

```
/var/lib/dpkg/info/
├── nginx.conffiles
├── nginx.list
├── nginx.md5sums
├── nginx.postinst
├── nginx.postrm
├── nginx.preinst
└── nginx.prerm
```

Le fichier `.list` est particulièrement important : il contient la liste exhaustive de tous les fichiers installés par le paquet. C'est ce fichier que consulte `dpkg -L` pour lister les fichiers d'un paquet et `dpkg -S` pour trouver à quel paquet appartient un fichier.

**`/var/lib/dpkg/available`** — Liste historique des paquets disponibles. Ce fichier est moins utilisé aujourd'hui car APT maintient son propre cache d'index.

**`/var/lib/dpkg/lock`** et **`/var/lib/dpkg/lock-frontend`** — Fichiers de verrouillage empêchant les accès concurrents.

### 3.2 États des paquets

Le champ `Status` dans la base dpkg encode trois informations :

**L'action souhaitée** (*desired action*) :

- `install` — Le paquet est censé être installé.
- `deinstall` — Le paquet est censé être supprimé (mais configs conservées).
- `purge` — Le paquet est censé être purgé (fichiers et configs supprimés).
- `hold` — Le paquet est verrouillé, aucune action ne doit être effectuée.
- `unknown` — Aucune action n'a été requise.

**Le drapeau d'erreur** (*error flag*) :

- `ok` — Aucune erreur.
- `reinstreq` — Le paquet est cassé et doit être réinstallé.

**L'état courant** (*current state*) :

- `not-installed` — Le paquet n'est pas installé et aucun fichier n'est présent.
- `config-files` — Seuls les fichiers de configuration subsistent (paquet supprimé avec `remove`).
- `half-installed` — L'installation a commencé mais n'a pas été achevée.
- `unpacked` — Le paquet a été décompressé mais pas configuré.
- `half-configured` — La configuration a commencé mais n'a pas abouti.
- `triggers-awaited` — Le paquet attend le traitement de triggers.
- `triggers-pending` — Le paquet a des triggers en attente de traitement.
- `installed` — Le paquet est correctement installé et configuré.

Les combinaisons courantes sont :

| Status complet | Signification |
|---------------|---------------|
| `install ok installed` | Paquet installé et fonctionnel |
| `deinstall ok config-files` | Paquet supprimé, fichiers de config conservés (état `rc`) |
| `purge ok not-installed` | Paquet entièrement purgé |
| `install reinstreq half-installed` | Installation échouée, réinstallation requise |
| `hold ok installed` | Paquet installé et verrouillé contre les mises à jour |

### 3.3 Sauvegarde automatique

dpkg crée automatiquement des sauvegardes de son fichier `status` ainsi que des bases annexes :

```bash
ls -la /var/backups/dpkg.*
# /var/backups/dpkg.status.0         # Sauvegarde la plus récente (non compressée)
# /var/backups/dpkg.status.1.gz      # Sauvegarde précédente (compressée)
# /var/backups/dpkg.status.2.gz      # Plus anciennes, compressées
# /var/backups/dpkg.arch.0           # Sauvegarde de la liste des architectures
# /var/backups/dpkg.diversions.0     # Sauvegarde des diversions
# /var/backups/dpkg.statoverride.0   # Sauvegarde des statoverrides
# /var/backups/alternatives.tar.0    # Sauvegarde du système d'alternatives
```

Ces sauvegardes sont gérées par le timer systemd `dpkg-db-backup.timer` (qui exécute `/usr/libexec/dpkg/dpkg-db-backup`) ou, à défaut de systemd, par le script `/etc/cron.daily/dpkg`. Elles sont précieuses en cas de corruption de la base de données. Sur un système fraîchement installé, ces fichiers n'apparaissent qu'après le premier déclenchement quotidien du timer.

---

## 4. Outils de l'écosystème dpkg

dpkg n'est pas un outil unique mais une suite de programmes complémentaires :

**`dpkg`** — Le programme principal. Installe, supprime, configure les paquets et interroge la base de données.

**`dpkg-deb`** — Manipule les fichiers `.deb` sans les installer : extraction, inspection du contenu, construction de paquets.

**`dpkg-query`** — Interroge la base de données dpkg de manière avancée avec des formats de sortie personnalisables. Particulièrement utile dans les scripts.

**`dpkg-reconfigure`** — Relance la phase de configuration interactive (debconf) d'un paquet déjà installé. Utilise le système debconf pour présenter les questions de configuration.

**`dpkg-divert`** — Permet de détourner un fichier de son emplacement normal pour empêcher un paquet de l'écraser. Mécanisme avancé utilisé pour remplacer un fichier fourni par un paquet sans créer de conflit.

**`dpkg-statoverride`** — Permet de surcharger les permissions et le propriétaire d'un fichier installé par un paquet, de manière persistante à travers les mises à jour.

**`dpkg-trigger`** — Active manuellement un trigger dpkg.

**`dpkg-split`** et **`dpkg-merge`** — Découpent et reconstituent des paquets `.deb` volumineux (usage historique pour la distribution sur disquettes, rarement utilisé aujourd'hui).

**`update-alternatives`** — Gère le système d'alternatives Debian, qui permet à plusieurs paquets de fournir le même type de programme (par exemple `vi`, `editor`, `x-www-browser`) avec un mécanisme de sélection configurable.

---

## 5. Le système debconf

### 5.1 Présentation

debconf est le système de configuration interactif de Debian. Lorsqu'un paquet a besoin de poser des questions à l'administrateur lors de l'installation (choix d'une option, saisie d'un mot de passe, sélection d'un mode de fonctionnement), il utilise debconf plutôt que d'interagir directement avec le terminal.

debconf offre plusieurs frontends (interfaces de présentation) :

- `dialog` — Interface semi-graphique en mode texte (par défaut).
- `readline` — Interface textuelle simple (questions/réponses en ligne).
- `noninteractive` — Aucune question posée ; les valeurs par défaut sont appliquées automatiquement.
- `gnome` et `kde` — Interfaces graphiques (si un environnement de bureau est disponible).

### 5.2 Pré-configuration avec `debconf-set-selections`

debconf permet de pré-configurer les réponses aux questions avant l'installation d'un paquet. Ce mécanisme est fondamental pour l'automatisation :

```bash
# Voir les questions d'un paquet installé
debconf-show postfix

# Pré-configurer les réponses
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections  
echo "postfix postfix/mailname string mail.example.com" | debconf-set-selections  

# Installer ensuite sans interaction
DEBIAN_FRONTEND=noninteractive apt install -y postfix
```

Ce mécanisme est largement utilisé dans les Dockerfiles, les scripts preseed, les playbooks Ansible et tout outil de provisionnement automatisé.

---

## 6. Le système d'alternatives

### 6.1 Principe

Le système d'alternatives (`update-alternatives`) résout un problème courant : plusieurs paquets peuvent fournir des programmes remplissant la même fonction. Par exemple, `vim`, `nano` et `ed` sont tous des éditeurs de texte. Le système d'alternatives permet de désigner lequel est l'éditeur par défaut du système via un lien symbolique géré automatiquement.

Les alternatives sont organisées en groupes. Chaque groupe correspond à un nom générique (par exemple `editor`, `pager`, `x-www-browser`) et contient une liste de candidats classés par priorité.

```bash
# Afficher l'alternative active pour "editor"
update-alternatives --display editor

# Configurer interactivement l'éditeur par défaut
update-alternatives --config editor

# Lister toutes les alternatives gérées
update-alternatives --get-selections
```

### 6.2 Mode automatique vs mode manuel

En mode **automatique** (par défaut), le système choisit le candidat ayant la plus haute priorité. Si un nouveau paquet installe un candidat de priorité supérieure, il devient automatiquement le choix par défaut.

En mode **manuel**, le choix de l'administrateur est respecté quels que soient les paquets installés ou supprimés. Le mode manuel est activé lorsque l'administrateur utilise `update-alternatives --set` ou fait un choix explicite via `--config`.

---

## Ce que couvrent les sous-sections suivantes

Les sous-sections qui suivent approfondissent les aspects pratiques de l'utilisation de dpkg et des paquets `.deb` :

- **4.2.1 — Installation manuelle de paquets** : utilisation de `dpkg -i`, extraction sans installation, gestion des conflits, options de forçage et récupération d'installations échouées.
- **4.2.2 — Création de paquets `.deb` personnalisés** : construction de paquets à partir de zéro, outils de packaging (`dpkg-deb`, `debhelper`, `dh`), structure du répertoire `debian/` et bonnes pratiques.
- **4.2.3 — Résolution des dépendances** : dépendances avec dpkg vs APT, diagnostic des conflits, gestion des paquets virtuels et des alternatives.
- **4.2.4 — Outils complémentaires** : `gdebi` comme alternative à `dpkg -i` avec résolution de dépendances, `dpkg-reconfigure` pour la reconfiguration, `dpkg-query` pour les requêtes avancées et `dpkg-divert` pour le détournement de fichiers.

## Prérequis

Pour aborder cette section, les connaissances suivantes sont attendues :

- Maîtrise de la section 4.1 (APT), en particulier la compréhension des types de dépendances entre paquets et de la chaîne de confiance GPG.
- Familiarité avec les archives et la compression sous Linux (`tar`, `gzip`, `xz`).
- Compréhension du fonctionnement des permissions et des liens symboliques (Module 3.1).
- Capacité à lire et interpréter des scripts shell de base (utile pour comprendre les scripts de maintenance des paquets).

⏭️ [Installation manuelle de paquets](/module-04-gestion-paquets/02.1-installation-manuelle.md)
