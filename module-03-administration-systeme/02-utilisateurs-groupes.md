🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 3.2 Gestion des utilisateurs et groupes

## Introduction

Linux est un système d'exploitation **multi-utilisateur** depuis ses origines. Chaque processus s'exécute sous l'identité d'un utilisateur, chaque fichier appartient à un utilisateur et un groupe, et chaque accès au système — qu'il provienne d'un être humain, d'un service applicatif ou d'un script automatisé — est soumis à un contrôle d'identité. La gestion des utilisateurs et des groupes est donc au cœur de la sécurité et du fonctionnement de tout système Debian.

Un administrateur Debian gère des utilisateurs dans des contextes très variés : créer un compte pour un nouveau membre de l'équipe, provisionner un utilisateur système pour un service (Nginx, PostgreSQL, Prometheus), appliquer une politique de mots de passe conforme aux exigences de sécurité de l'entreprise, intégrer les comptes locaux avec un annuaire centralisé (LDAP, Active Directory), ou configurer des élévations de privilèges finement contrôlées avec `sudo`. Chacune de ces tâches mobilise des outils, des fichiers de configuration et des concepts qu'il faut maîtriser en profondeur.

## Architecture du modèle d'identification Linux

### UID et GID : les identités numériques

Le noyau Linux n'identifie jamais un utilisateur par son nom. Toutes les vérifications de permissions, d'appartenance et de propriété s'effectuent à travers des identifiants numériques :

- L'**UID** (User Identifier) identifie un utilisateur de manière unique.
- Le **GID** (Group Identifier) identifie un groupe de manière unique.

Les noms lisibles (`root`, `alice`, `www-data`) ne sont que des correspondances stockées dans des bases de données (fichiers locaux, annuaires LDAP). Quand un processus accède à un fichier, le noyau compare l'UID du processus avec l'UID du propriétaire du fichier — jamais les noms.

```bash
$ id alice
uid=1001(alice) gid=1001(alice) groupes=1001(alice),27(sudo),1002(dev),1003(docker)
```

Cette commande révèle les quatre composantes de l'identité d'un utilisateur sous Linux : son UID, son GID principal, et la liste de ses groupes secondaires (chacun identifié par un GID et un nom).

### Plages d'UID et conventions Debian

Debian définit des plages d'UID standardisées dans `/etc/login.defs` et la Debian Policy :

| Plage UID | Usage | Exemples |
|---|---|---|
| **0** | Superutilisateur | `root` |
| **1 – 99** | Utilisateurs système statiques, alloués par Debian | `daemon` (1), `bin` (2), `sys` (3), `mail` (8) |
| **100 – 999** | Utilisateurs système dynamiques, alloués par les paquets | `systemd-network` (101), `sshd` (106), `www-data` (33), `postgres` (114) |
| **1000 – 59999** | Utilisateurs humains | `alice` (1001), `bob` (1002) |
| **60000 – 64999** | Réservé (Debian) | Usages spécifiques |
| **65534** | Utilisateur `nobody` | Identité sans privilège |

Ces plages sont configurées dans `/etc/login.defs` :

```bash
# Sur Debian Trixie, seuls UID_MIN/UID_MAX sont actifs (non commentés) ;
# les valeurs SYS_UID_MIN/SYS_UID_MAX sont laissées commentées avec
# leurs défauts codés en dur (101 et 999). Pour les voir, retirer
# l'ancrage `^` du grep :
$ grep -E "(UID_MIN|UID_MAX|SYS_UID_MIN|SYS_UID_MAX)" /etc/login.defs
#SYS_UID_MIN		  101
#SYS_UID_MAX		  999
UID_MIN			 1000  
UID_MAX			60000  
```

Les mêmes conventions s'appliquent aux GID. Les outils `useradd` et `adduser` respectent automatiquement ces plages : `adduser` attribue un UID ≥ 1000, `adduser --system` attribue un UID dans la plage 100–999.

### Utilisateurs système vs utilisateurs humains

La distinction entre ces deux catégories est fondamentale sous Debian.

**Utilisateurs humains** (UID ≥ 1000) — Ce sont les comptes destinés à des personnes réelles. Ils possèdent un répertoire personnel dans `/home`, un shell interactif (`/bin/bash`), un mot de passe, et peuvent se connecter au système.

**Utilisateurs système** (UID < 1000) — Ce sont des comptes créés pour faire fonctionner des services. Ils possèdent généralement un shell désactivé (`/usr/sbin/nologin` ou `/bin/false`), pas de mot de passe, et un répertoire personnel qui est soit inexistant, soit un répertoire fonctionnel du service (`/var/lib/postgresql` pour `postgres`, `/var/www` pour `www-data`). Leur rôle est de fournir une identité avec des privilèges limités sous laquelle un démon s'exécute, appliquant ainsi le **principe du moindre privilège**.

```bash
# Un utilisateur humain
$ getent passwd alice
alice:x:1001:1001:Alice Dupont,,,:/home/alice:/bin/bash

# Un utilisateur système
$ getent passwd www-data
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

## Les fichiers fondamentaux

Quatre fichiers locaux constituent la base du système d'identification sous Debian. Leur format, leur rôle et leurs interactions doivent être parfaitement compris par tout administrateur.

### `/etc/passwd` — Base des utilisateurs

Chaque ligne décrit un utilisateur, avec sept champs séparés par `:` :

```
nom:mot_de_passe:UID:GID:commentaire:répertoire_personnel:shell
```

```bash
$ cat /etc/passwd | head -5
root:x:0:0:root:/root:/bin/bash  
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin  
bin:x:2:2:bin:/bin:/usr/sbin/nologin  
sys:x:3:3:sys:/dev:/usr/sbin/nologin  
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin  

$ getent passwd alice
alice:x:1001:1001:Alice Dupont,Bureau 42,0561000000,:/home/alice:/bin/bash
```

| Champ | Description |
|---|---|
| `nom` | Nom de connexion (login), unique, sensible à la casse |
| `mot_de_passe` | `x` indique que le hash est dans `/etc/shadow` (standard moderne) |
| `UID` | Identifiant numérique unique |
| `GID` | GID du groupe principal |
| `commentaire` | Champ GECOS : nom complet, bureau, téléphone (sous-champs séparés par des virgules) |
| `répertoire_personnel` | Chemin du répertoire home |
| `shell` | Shell de connexion (ou `/usr/sbin/nologin` pour les comptes système) |

Ce fichier est lisible par tous les utilisateurs (`644`), car de nombreux programmes ont besoin de résoudre la correspondance UID↔nom. C'est pourquoi les mots de passe ne sont plus stockés ici.

### `/etc/shadow` — Mots de passe et politique d'expiration

Ce fichier contient les hash de mots de passe et les paramètres de la politique d'expiration. Il est lisible uniquement par `root` et le groupe `shadow` (`640`).

```
nom:hash:dernier_changement:min:max:warn:inactive:expire:réservé
```

```bash
$ sudo cat /etc/shadow | grep alice
alice:$y$j9T$abc...xyz$HASH_COMPLET:19827:0:90:14:30:20089:
```

| Champ | Description |
|---|---|
| `nom` | Nom de connexion (correspondance avec `/etc/passwd`) |
| `hash` | Hash du mot de passe (ou `!`/`*` si verrouillé, `!!` si jamais défini) |
| `dernier_changement` | Date du dernier changement (en jours depuis le 1er janvier 1970) |
| `min` | Nombre minimum de jours entre deux changements |
| `max` | Nombre maximum de jours de validité |
| `warn` | Nombre de jours d'avertissement avant expiration |
| `inactive` | Nombre de jours de grâce après expiration (compte désactivé ensuite) |
| `expire` | Date d'expiration absolue du compte (en jours depuis epoch) |

Le champ hash commence par un identifiant d'algorithme : `$y$` pour yescrypt (défaut depuis Debian 11), `$6$` pour SHA-512 (défaut de Debian 10 et antérieures), `$5$` pour SHA-256. L'algorithme est configuré dans `/etc/login.defs` (`ENCRYPT_METHOD`) et dans PAM.

### `/etc/group` — Base des groupes

Chaque ligne décrit un groupe avec quatre champs :

```
nom:mot_de_passe:GID:membres
```

```bash
$ cat /etc/group | grep -E "^(dev|sudo|docker)"
sudo:x:27:alice,bob  
dev:x:1002:alice,bob,charlie  
docker:x:1003:alice,deployer  
```

| Champ | Description |
|---|---|
| `nom` | Nom du groupe |
| `mot_de_passe` | `x` (inutilisé en pratique, héritage historique) |
| `GID` | Identifiant numérique unique du groupe |
| `membres` | Liste des utilisateurs membres, séparés par des virgules |

Un utilisateur qui a ce groupe comme GID principal (dans `/etc/passwd`) n'apparaît **pas** nécessairement dans la liste des membres dans `/etc/group`. Son appartenance est implicite via le champ GID de `/etc/passwd`. La commande `id` montre la vue complète.

### `/etc/gshadow` — Mots de passe des groupes

Fichier compagnon de `/etc/group`, lisible uniquement par root. En pratique, les mots de passe de groupe sont très rarement utilisés. Ce fichier contient aussi la liste des administrateurs de chaque groupe (utilisateurs autorisés à ajouter/retirer des membres).

```bash
$ sudo cat /etc/gshadow | grep dev
dev:!::alice,bob,charlie
# ! = pas de mot de passe de groupe
```

## Le mécanisme des groupes

### Groupe principal et groupes secondaires

Chaque utilisateur possède exactement **un groupe principal** (défini par le champ GID dans `/etc/passwd`) et peut appartenir à un nombre arbitraire de **groupes secondaires** (définis dans `/etc/group`).

Le groupe principal détermine le groupe propriétaire des fichiers créés par l'utilisateur (sauf si le bit setgid est positionné sur le répertoire parent, comme vu en section 3.1.3). Les groupes secondaires étendent les droits d'accès : quand le noyau vérifie les permissions de groupe, il considère **tous** les groupes de l'utilisateur (principal et secondaires).

Sous Debian, la convention **User Private Group (UPG)** est appliquée par défaut : chaque utilisateur humain reçoit un groupe principal portant le même nom que son login et dont il est le seul membre (UID = GID). Ce schéma simplifie la gestion des permissions et permet d'utiliser un umask `002` sans risque (les fichiers créés sont accessibles au groupe, mais le groupe ne contient que l'utilisateur lui-même par défaut).

```bash
$ id alice
uid=1001(alice) gid=1001(alice) groupes=1001(alice),27(sudo),1002(dev)
#                    ^                        ^           ^
#              groupe principal         groupes secondaires
```

### Groupes notables sous Debian

Debian crée plusieurs groupes système ayant des rôles spécifiques :

| Groupe | GID | Rôle |
|---|---|---|
| `root` | 0 | Groupe du superutilisateur |
| `sudo` | 27 | Membres autorisés à utiliser `sudo` (via configuration PAM/sudoers) |
| `adm` | 4 | Accès en lecture aux fichiers de logs (`/var/log/syslog`, etc.) |
| `www-data` | 33 | Groupe du serveur web (Apache, Nginx) |
| `shadow` | 42 | Accès en lecture à `/etc/shadow` |
| `disk` | 6 | Accès direct aux périphériques de type bloc |
| `plugdev` | 46 | Accès aux périphériques amovibles (USB, etc.) |
| `netdev` | 109 | Gestion des interfaces réseau via NetworkManager |
| `audio` | 29 | Accès aux périphériques audio |
| `video` | 44 | Accès aux périphériques vidéo |
| `systemd-journal` | — | Accès aux logs de journald |
| `docker` | — | Accès au socket Docker (équivalent root — à attribuer avec prudence) |

### Prise en compte des changements de groupes

Quand un administrateur ajoute un utilisateur à un groupe, le changement n'est **pas immédiatement effectif** pour les sessions déjà ouvertes. L'utilisateur doit fermer et rouvrir sa session (ou exécuter `newgrp` pour activer un groupe dans le shell courant) :

```bash
# Ajouter alice au groupe docker
$ sudo usermod -aG docker alice

# Dans la session existante d'alice, le groupe n'est pas encore actif
$ groups
alice sudo dev
# docker n'apparaît pas

# Solution 1 : se reconnecter (SSH, login, etc.)
# Solution 2 : newgrp dans le shell courant
$ newgrp docker
$ groups
docker alice sudo dev
```

## La commande `getent` : interrogation unifiée

La commande `getent` (get entries) interroge les bases de données du NSS (Name Service Switch), ce qui inclut les fichiers locaux **et** les sources externes (LDAP, SSSD) si elles sont configurées. C'est la méthode recommandée pour interroger les utilisateurs et groupes, plutôt que de lire directement `/etc/passwd` ou `/etc/group` :

```bash
# Interroger un utilisateur (toutes sources confondues)
$ getent passwd alice
alice:x:1001:1001:Alice Dupont,,,:/home/alice:/bin/bash

# Interroger un groupe
$ getent group dev
dev:x:1002:alice,bob,charlie

# Lister tous les utilisateurs (locaux + annuaire)
$ getent passwd

# Vérifier si un utilisateur existe (code de retour)
$ getent passwd alice > /dev/null && echo "Existe" || echo "N'existe pas"
Existe
```

## Pourquoi cette section est essentielle

La gestion des utilisateurs et groupes est sollicitée dans pratiquement tous les modules de la formation :

**Module 6 (Réseau et sécurité)** — L'authentification SSH par clés repose sur les permissions du répertoire `~/.ssh` et l'appartenance aux groupes. La configuration de fail2ban interagit avec les logs d'authentification.

**Module 7 (Services)** — Chaque service (Apache, Nginx, MariaDB, PostgreSQL) s'exécute sous un utilisateur système dédié. Comprendre pourquoi et comment configurer ces utilisateurs est indispensable.

**Module 10 (Conteneurs)** — Le fonctionnement des conteneurs rootless (Podman) repose sur le remappage d'UID/GID via les fichiers `/etc/subuid` et `/etc/subgid`.

**Module 13 (Infrastructure as Code)** — Ansible gère la création d'utilisateurs et l'attribution de groupes à travers ses modules `user` et `group`, qui manipulent exactement les fichiers et commandes abordés ici.

**Module 16 (Sécurité avancée)** — Les politiques PAM, les audits de conformité CIS et le durcissement du système reposent tous sur une gestion rigoureuse des identités.

## Concepts clés abordés

Cette section est organisée en cinq sous-sections progressives.

**Création, modification et suppression d'utilisateurs** — Les commandes `useradd`/`adduser`, `usermod` et `userdel`/`deluser`, avec leurs options, leurs différences (commandes bas niveau vs wrappers Debian), et les implications de chaque opération sur les fichiers système. Le squelette `/etc/skel` et la personnalisation de l'environnement des nouveaux utilisateurs.

**Groupes et appartenance** — La gestion complète des groupes : création, ajout et retrait de membres, groupes primaires et secondaires, et les stratégies d'organisation des groupes dans un environnement professionnel.

**Gestion des mots de passe et politiques (PAM)** — La configuration des politiques de mots de passe (complexité, expiration, historique) via PAM et `/etc/login.defs`. L'architecture modulaire de PAM et ses principaux modules sous Debian.

**Sudo et privilèges avancés** — La configuration fine de `sudo` via `/etc/sudoers` et `/etc/sudoers.d/`, la syntaxe des règles, les alias, le contrôle granulaire des commandes autorisées, et les bonnes pratiques pour un serveur en production.

**NSS et intégration annuaire (LDAP, SSSD)** — Le mécanisme de Name Service Switch qui permet d'unifier les sources d'identité, l'intégration avec un annuaire LDAP ou Active Directory via SSSD, et les considérations de cache et de résilience.

## Outils principaux utilisés

| Commande / Fichier | Rôle |
|---|---|
| `adduser`, `useradd` | Création d'utilisateurs |
| `usermod` | Modification d'utilisateurs |
| `deluser`, `userdel` | Suppression d'utilisateurs |
| `addgroup`, `groupadd` | Création de groupes |
| `groupmod`, `groupdel` | Modification et suppression de groupes |
| `passwd`, `chage` | Gestion des mots de passe et de leur expiration |
| `id`, `groups`, `whoami` | Consultation de l'identité |
| `getent` | Interrogation unifiée des bases (passwd, group, shadow) |
| `sudo`, `visudo` | Élévation de privilèges et configuration |
| `su`, `newgrp` | Changement d'identité et de groupe |
| `/etc/passwd`, `/etc/shadow` | Bases locales des utilisateurs |
| `/etc/group`, `/etc/gshadow` | Bases locales des groupes |
| `/etc/login.defs` | Paramètres par défaut (plages UID/GID, algorithme de hash, umask) |
| `/etc/skel/` | Squelette des répertoires personnels |
| `/etc/nsswitch.conf` | Configuration du Name Service Switch |
| PAM (`/etc/pam.d/`) | Framework d'authentification modulaire |

## Prérequis

Pour aborder cette section, les connaissances suivantes sont attendues :

- Compréhension du modèle de permissions Linux (section 3.1.3) : propriétaire, groupe, permissions rwx, bits spéciaux.
- Maîtrise du montage et de la notion de système de fichiers (section 3.1.4) : les répertoires personnels peuvent être sur des partitions dédiées.
- Aisance avec l'éditeur de texte en ligne de commande (`nano`, `vi`) pour modifier les fichiers de configuration.
- Accès root ou sudo sur un système Debian.

---

> **Navigation**  
>  
> Section suivante : [3.2.1 Création, modification et suppression d'utilisateurs](/module-03-administration-systeme/02.1-creation-modification-utilisateurs.md)  
>  
> Retour au module : [Module 3 — Administration système de base](/module-03-administration-systeme.md)

⏭️ [Création, modification et suppression d'utilisateurs](/module-03-administration-systeme/02.1-creation-modification-utilisateurs.md)
