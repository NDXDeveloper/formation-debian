🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 3.1 Système de fichiers

## Introduction

Le système de fichiers est le socle fondamental de toute administration sous Debian. Il définit la manière dont les données sont organisées, stockées et accédées sur les supports de stockage. Comprendre son fonctionnement est indispensable pour tout administrateur système, car chaque opération — de l'installation d'un paquet à la configuration d'un service — repose sur cette couche d'abstraction entre le matériel et les applications.

Sous Linux, et donc sous Debian, la philosophie est radicale : **tout est fichier**. Les fichiers réguliers, les répertoires, les périphériques matériels, les sockets réseau, les processus en cours d'exécution… tous sont représentés sous forme d'entrées dans une arborescence unique. Cette abstraction, héritée d'Unix, offre une interface cohérente et puissante pour interagir avec l'ensemble du système.

## Pourquoi cette section est essentielle

L'administrateur système Debian interagit en permanence avec le système de fichiers, que ce soit pour :

- **Diagnostiquer un problème** : un service qui ne démarre pas à cause de permissions incorrectes, un disque plein qui bloque les écritures de logs, un point de montage mal configuré après un redémarrage.
- **Planifier une infrastructure** : choisir le bon système de fichiers selon l'usage (serveur de base de données, serveur de fichiers, poste de travail), dimensionner les partitions, anticiper la croissance des données.
- **Sécuriser un serveur** : appliquer des permissions granulaires, isoler les données sensibles sur des partitions dédiées, restreindre les options de montage (`noexec`, `nosuid`, `nodev`).
- **Maintenir la disponibilité** : surveiller l'utilisation des disques, gérer les quotas, effectuer des opérations de maintenance sans interruption de service.

## Concepts clés abordés

Cette section couvre l'ensemble des connaissances nécessaires à la maîtrise du système de fichiers sous Debian, organisées en cinq sous-sections progressives.

**Structure des répertoires Linux/Debian (FHS)** — Le Filesystem Hierarchy Standard définit l'organisation de l'arborescence sous Debian. Savoir où se trouvent les fichiers de configuration (`/etc`), les logs (`/var/log`), les binaires (`/usr/bin`), les données temporaires (`/tmp`) et les fichiers des utilisateurs (`/home`) permet de naviguer efficacement dans le système et de respecter les conventions attendues par les outils et les paquets Debian.

**Systèmes de fichiers (ext4, XFS, Btrfs, ZFS)** — Debian supporte de nombreux systèmes de fichiers, chacun avec ses caractéristiques propres. Le choix entre ext4 (fiable et éprouvé, défaut de Debian), XFS (performant pour les gros fichiers), Btrfs (snapshots natifs, compression) ou ZFS (intégrité des données, RAID intégré) dépend directement du cas d'usage. Cette sous-section fournit les critères de comparaison pour faire un choix éclairé.

**Permissions et propriétés (ACL avancées)** — Au-delà du modèle classique propriétaire/groupe/autres (`rwx`), Debian supporte les ACL POSIX qui permettent un contrôle d'accès fin, indispensable dans les environnements multi-utilisateurs ou pour les partages de fichiers. Les attributs étendus, les bits spéciaux (`setuid`, `setgid`, sticky bit) et le masque `umask` complètent ce dispositif.

**Montage, démontage et fstab** — La gestion des points de montage est au cœur de l'administration quotidienne. Le fichier `/etc/fstab` contrôle le montage automatique des systèmes de fichiers au démarrage, tandis que les commandes `mount` et `umount` permettent les opérations manuelles. Les unités `.mount` de systemd offrent une alternative moderne avec une gestion fine des dépendances.

**Liens symboliques et physiques** — Les liens sont un mécanisme fondamental sous Linux. Les liens physiques (hard links) partagent le même inode et les mêmes données sur le disque, tandis que les liens symboliques (symlinks) sont des raccourcis flexibles qui peuvent traverser les systèmes de fichiers. Debian en fait un usage intensif, notamment dans la gestion des alternatives (`update-alternatives`) et l'organisation des services systemd.

## Prérequis

Pour aborder cette section dans les meilleures conditions, les connaissances suivantes sont attendues :

- Maîtrise des commandes de base du shell (`cd`, `ls`, `cp`, `mv`, `rm`, `cat`, `less`).
- Compréhension élémentaire de la notion de partition et de disque.
- Accès à un système Debian installé (physique ou virtuel) avec un compte disposant de privilèges `sudo`.
- Notions de base couvertes dans les modules 1 et 2 de cette formation.

## Outils principaux utilisés

Les commandes et outils suivants seront utilisés tout au long de cette section :

| Commande / Outil | Rôle |
|---|---|
| `ls`, `stat`, `file` | Inspection des fichiers et de leurs métadonnées |
| `chmod`, `chown`, `chgrp` | Gestion des permissions et de la propriété |
| `getfacl`, `setfacl` | Manipulation des ACL POSIX |
| `mount`, `umount`, `findmnt` | Opérations de montage et consultation |
| `df`, `du`, `lsblk` | Utilisation de l'espace disque et topologie des blocs |
| `mkfs.*` | Création de systèmes de fichiers |
| `ln` | Création de liens symboliques et physiques |
| `blkid`, `tune2fs` | Identification et paramétrage des systèmes de fichiers |

## Position dans le parcours

Cette section ouvre le **Module 3 — Administration système de base**, qui constitue le cœur du Parcours 1. Les compétences acquises ici sont transversales : elles sont mobilisées dans tous les modules suivants, de la gestion des services (Module 7) à la conteneurisation (Module 10), en passant par le stockage Kubernetes (Module 11). Une compréhension solide du système de fichiers est un prérequis implicite pour l'ensemble de la formation.

---

> **Navigation**  
>  
> Section suivante : [3.1.1 Structure des répertoires Linux/Debian (FHS)](/module-03-administration-systeme/01.1-structure-repertoires-fhs.md)  
>  
> Retour au module : [Module 3 — Administration système de base](/module-03-administration-systeme.md)

⏭️ [Structure des répertoires Linux/Debian (FHS)](/module-03-administration-systeme/01.1-structure-repertoires-fhs.md)
