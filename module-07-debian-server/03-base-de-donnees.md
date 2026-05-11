🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 7.3 Base de données

## Introduction

Après le serveur web, le serveur de bases de données est le second pilier d'une infrastructure applicative. La quasi-totalité des applications web, des CMS, des ERP, des systèmes de monitoring et des outils collaboratifs s'appuient sur une base de données relationnelle pour stocker, organiser et restituer leurs données. Un serveur de bases de données mal configuré — ou mal dimensionné — devient rapidement le goulet d'étranglement de toute la chaîne : requêtes lentes, verrous en cascade, consommation mémoire excessive, pertes de données en cas d'incident.

Debian propose deux systèmes de gestion de bases de données relationnelles (SGBDR) dans ses dépôts officiels : **MariaDB** et **PostgreSQL**. Les deux sont matures, performants, libres et bénéficient du support de sécurité Debian. Leur choix n'est pas anodin — ils incarnent des philosophies, des modèles de données et des écosystèmes différents qui les rendent plus ou moins adaptés selon le contexte.

Ce chapitre couvre l'installation, la configuration, l'optimisation, la sauvegarde, la restauration et les premières notions de réplication pour chacun de ces deux SGBDR, avec un focus constant sur les spécificités de Debian.

---

## MariaDB et PostgreSQL : deux héritages, deux philosophies

### MariaDB

MariaDB est né en 2009 d'un fork de MySQL, initié par Michael « Monty » Widenius, le créateur original de MySQL, en réaction au rachat de MySQL par Oracle. L'objectif était de garantir un SGBDR communautaire, libre et rétrocompatible avec MySQL, à l'abri des décisions d'un éditeur commercial.

Debian a remplacé MySQL par MariaDB comme implémentation par défaut du méta-paquet `default-mysql-server` à partir de Debian 9 (Stretch). Cette décision reflète la confiance de la communauté Debian dans la gouvernance et la pérennité de MariaDB. Sur Trixie, `default-mysql-server` existe toujours mais c'est un simple méta-paquet qui dépend de `mariadb-server-compat` (lui-même dépendant de `mariadb-server`). En pratique, sur une installation moderne, on installe directement `mariadb-server` — c'est plus explicite et cela évite la couche `default-*` qui n'apporte rien sur un nouveau déploiement.

MariaDB conserve une compatibilité protocolaire et syntaxique étendue avec MySQL. Les applications conçues pour MySQL fonctionnent généralement sans modification avec MariaDB. Les outils client (`mysql`, `mysqldump`, `mysqladmin`) portent le même nom et acceptent les mêmes options. Cette compatibilité fait de MariaDB un choix naturel pour les environnements historiquement liés à l'écosystème MySQL : WordPress, Drupal, Joomla, Magento, NextCloud, et la majorité des applications PHP.

Au fil des versions, MariaDB a développé ses propres fonctionnalités distinctes de MySQL : moteurs de stockage additionnels (Aria, ColumnStore, Spider), améliorations du moteur d'optimisation de requêtes, support natif des séquences, colonnes système versionnées (temporal tables) et un pool de threads intégré.

### PostgreSQL

PostgreSQL est un projet indépendant dont les origines remontent à 1986, au projet Postgres de l'Université de Californie à Berkeley. Il n'a aucun lien technique avec MySQL ou MariaDB. Son développement est piloté par le PostgreSQL Global Development Group, un collectif international de contributeurs sans entité commerciale dominante.

PostgreSQL se positionne comme un SGBDR avancé, mettant l'accent sur la **conformité SQL**, l'**intégrité des données** et l'**extensibilité**. Son respect du standard SQL est parmi les plus stricts du monde open source. Il supporte nativement des types de données avancés (JSON/JSONB, tableaux, types géométriques, plages, UUID), des index sophistiqués (B-tree, GiST, GIN, BRIN, bloom), des fonctions fenêtres complètes, des CTE récursifs, et un système d'extension qui permet d'ajouter de nouveaux types, opérateurs, fonctions et langages procéduraux.

PostgreSQL est le choix privilégié pour les applications où la complexité des données et des requêtes est élevée : applications d'entreprise, systèmes géographiques (avec l'extension PostGIS), data warehousing, applications financières et toute situation où la rigueur relationnelle et la richesse du SQL sont des atouts.

---

## Critères de choix

Le choix entre MariaDB et PostgreSQL dépend rarement d'un seul critère. Il résulte d'un croisement entre les besoins applicatifs, les compétences de l'équipe et les contraintes de l'écosystème existant.

### Compatibilité applicative

C'est souvent le critère décisif. De nombreuses applications imposent ou recommandent un SGBDR spécifique.

**MariaDB/MySQL requis ou recommandé** — WordPress, Drupal, Joomla, Magento, PrestaShop, NextCloud, MediaWiki, phpBB, GLPI, Zabbix (avec support PostgreSQL optionnel). La majorité de l'écosystème PHP historique repose sur MySQL/MariaDB.

**PostgreSQL requis ou recommandé** — GitLab, Mastodon, Discourse, SonarQube, Keycloak, AWX/Ansible Tower, Redmine (supporte aussi MySQL), Grafana (supporte aussi MySQL), Odoo. Les applications Python (Django) et Ruby (Rails) fonctionnent avec les deux mais PostgreSQL est souvent préféré dans ces écosystèmes.

**Les deux supportés** — De nombreux frameworks modernes (Django, Rails, Laravel, Spring) supportent les deux SGBDR via des couches d'abstraction. Dans ce cas, le choix est libre et se fait selon les autres critères.

### Modèle de données et complexité des requêtes

**MariaDB** excelle dans les scénarios de lecture intensive avec des schémas relationnels simples à modérés. Son moteur de stockage InnoDB est optimisé pour les applications OLTP (Online Transaction Processing) à haut débit avec des requêtes courtes et fréquentes.

**PostgreSQL** brille quand le modèle de données est complexe, quand les requêtes analytiques sont fréquentes (agrégations, jointures complexes, fonctions fenêtres), quand les données sont hétérogènes (JSONB pour le semi-structuré, PostGIS pour le géospatial) et quand l'intégrité référentielle stricte est importante.

### Performance

Les comparaisons de performance brute entre MariaDB et PostgreSQL sont rarement pertinentes hors contexte. Les deux SGBDR sont capables de traiter des milliers de requêtes par seconde sur du matériel modeste. Les différences de performance significatives apparaissent dans des cas d'usage spécifiques :

- MariaDB est généralement plus rapide pour les requêtes de lecture simples sur des tables avec des index B-tree classiques, grâce à un overhead de parsing et de planification de requêtes plus faible.
- PostgreSQL est souvent plus performant sur les requêtes complexes (sous-requêtes corrélées, CTE, jointures multiples) grâce à son optimiseur de requêtes plus sophistiqué.
- Les deux offrent des performances d'écriture comparables avec leurs configurations par défaut.

Dans la pratique, la performance dépend davantage de la qualité du schéma (indexation, normalisation), de l'optimisation des requêtes et du dimensionnement du serveur (mémoire, I/O disque) que du choix du SGBDR.

### Administration et exploitation

**MariaDB** est généralement perçu comme plus simple à administrer pour les opérations courantes. La configuration par défaut est fonctionnelle pour la plupart des cas d'usage, les outils client sont familiers à tout administrateur ayant travaillé avec MySQL et l'écosystème d'outils graphiques (phpMyAdmin, Adminer, HeidiSQL) est très fourni.

**PostgreSQL** a une courbe d'apprentissage plus marquée. Les concepts de rôles (vs utilisateurs/privilèges MySQL), de schémas (namespace au sein d'une base), d'authentification par `pg_hba.conf` et de MVCC (Multi-Version Concurrency Control) avec VACUUM demandent un investissement initial. En contrepartie, PostgreSQL offre un contrôle plus fin sur le comportement du système, un catalogue système exploitable via SQL standard et une gestion des transactions plus rigoureuse.

### Licence et gouvernance

Les deux projets sont sous licences libres. MariaDB utilise la licence GPL v2. PostgreSQL utilise la licence PostgreSQL, une licence permissive similaire à BSD/MIT. La licence PostgreSQL est plus permissive pour les intégrations commerciales, ce qui explique la présence de PostgreSQL dans de nombreux produits propriétaires (Amazon RDS, Google Cloud SQL, Azure Database).

---

## Tableau comparatif

| Critère | MariaDB | PostgreSQL |
|---------|---------|------------|
| **Origine** | Fork de MySQL (2009) | Projet indépendant (1986/1996) |
| **Paquet Debian** | `mariadb-server` | `postgresql` |
| **Port par défaut** | 3306 | 5432 |
| **Protocole** | MySQL wire protocol | PostgreSQL wire protocol |
| **Moteur de stockage par défaut** | InnoDB | Heap (unique, intégré) |
| **Moteurs alternatifs** | Aria, MyRocks, ColumnStore, Spider | — (extensible via Foreign Data Wrappers) |
| **Conformité SQL** | Bonne (avec extensions MySQL) | Excellente (la plus stricte en open source) |
| **JSON** | JSON (stocké en texte) | JSONB (binaire, indexable, requêtable) |
| **Géospatial** | Basique (types Geometry) | Avancé (PostGIS, référence mondiale) |
| **Full-text search** | InnoDB FTS | ts_vector / ts_query (très puissant) |
| **Réplication** | Binlog (async, semi-sync), Galera (sync) | Streaming (async, sync), logique |
| **Partitionnement** | RANGE, LIST, HASH, KEY | RANGE, LIST, HASH (déclaratif) |
| **Procédures stockées** | SQL/PSM, PL/SQL partiel | PL/pgSQL, PL/Python, PL/Perl, PL/V8 |
| **Concurrence** | InnoDB : MVCC pour les lectures cohérentes + verrouillage par ligne pour les écritures | MVCC complet (snapshots par transaction, pas de lecture qui bloque l'écriture) |
| **VACUUM** | Non nécessaire | Nécessaire (autovacuum par défaut) |
| **Configuration** | `my.cnf` / `mariadb.cnf` | `postgresql.conf` + `pg_hba.conf` |
| **Outil client CLI** | `mariadb` (alias `mysql`) | `psql` |
| **Outils graphiques courants** | phpMyAdmin, Adminer, DBeaver | pgAdmin, Adminer, DBeaver |

---

## Considérations d'architecture sur Debian

### Base de données sur le même serveur vs serveur dédié

Pour les petites infrastructures et les environnements de développement, la base de données est souvent installée sur le même serveur Debian que le serveur web. Cette approche simplifie l'administration et élimine la latence réseau entre l'application et la base. La communication peut se faire via un socket Unix (plus rapide que TCP) et les données ne transitent pas sur le réseau.

Pour les environnements de production à fort trafic ou soumis à des exigences de disponibilité, un serveur dédié à la base de données est préférable. La séparation permet un dimensionnement indépendant (un serveur web a besoin de CPU et de réseau, un serveur de base de données a besoin de mémoire et d'I/O disque rapides), une maintenance sans impact croisé (redémarrer la base ne touche pas le serveur web), et une sécurité renforcée (la base n'est pas accessible depuis le réseau public).

### Dimensionnement des ressources

Le facteur le plus déterminant pour la performance d'un SGBDR est la **mémoire vive**. MariaDB comme PostgreSQL utilisent des caches en mémoire pour éviter les accès disque : le buffer pool InnoDB pour MariaDB, le shared_buffers et le cache du système de fichiers pour PostgreSQL. L'objectif idéal est que le jeu de données actif (working set) tienne entièrement en mémoire.

Le second facteur est la performance des **I/O disque**. Un SSD (ou mieux, un NVMe) fait une différence considérable par rapport à un disque mécanique, en particulier pour les écritures aléatoires (commits de transactions, écriture de logs WAL/binlog) et les lectures aléatoires (recherches par index).

Le CPU est rarement le facteur limitant sauf pour les requêtes analytiques complexes ou le chiffrement/déchiffrement des connexions TLS.

### Sécurité réseau

Quelle que soit la configuration choisie (colocalisé ou dédié), le port de la base de données ne doit jamais être exposé sur Internet. Si la base est sur le même serveur que l'application, configurer le SGBDR pour n'écouter que sur `localhost` (ou utiliser un socket Unix). Si la base est sur un serveur dédié, restreindre l'accès au réseau interne via nftables et via les mécanismes d'authentification du SGBDR.

```bash
# Vérifier que la base n'écoute pas sur une interface publique
$ sudo ss -tlnp | grep -E '3306|5432'
# Attendu : 127.0.0.1:3306 ou 127.0.0.1:5432
# Problème : 0.0.0.0:3306 ou 0.0.0.0:5432
```

---

## Prérequis

Les sous-sections de ce chapitre s'appuient sur les acquis suivants :

- Un serveur Debian installé et sécurisé conformément aux sections 7.1.1 à 7.1.3.
- Un pare-feu nftables actif. Si la base de données doit être accessible depuis un autre serveur, le port correspondant (3306 pour MariaDB, 5432 pour PostgreSQL) doit être ouvert uniquement pour les adresses IP des serveurs applicatifs autorisés.
- Une maîtrise de la gestion des services systemd et de l'édition des fichiers de configuration (Module 3).
- Des notions de SQL de base (CREATE, SELECT, INSERT, UPDATE, DELETE). Ce chapitre ne couvre pas l'apprentissage du SQL mais les aspects d'installation, de configuration et d'administration du serveur de base de données.

---

## Organisation des sous-sections

Chaque SGBDR est traité dans sa propre sous-section, puis les sujets transversaux sont abordés :

**7.3.1 MariaDB** — Installation du paquet Debian, sécurisation initiale (`mariadb-secure-installation`), structure de configuration, gestion des utilisateurs et des droits, moteurs de stockage, opérations courantes.

**7.3.2 PostgreSQL** — Installation, architecture multi-cluster propre à Debian (`pg_ctlcluster`, `pg_lsclusters`), configuration (`postgresql.conf`, `pg_hba.conf`), gestion des rôles et des bases, opérations courantes avec `psql`.

**7.3.3 Configuration et optimisation** — Paramètres de performance clés pour chaque SGBDR (buffer pool, shared_buffers, cache, logs de requêtes lentes), dimensionnement selon les ressources disponibles, profilage des requêtes.

**7.3.4 Sauvegarde et restauration** — Stratégies de sauvegarde logique (`mysqldump`/`mariadb-dump`, `pg_dump`) et physique (`mariabackup`, `pg_basebackup`), automatisation, tests de restauration.

**7.3.5 Réplication et clustering** — Réplication MariaDB (binlog, Galera), réplication PostgreSQL (streaming, logique), principes de haute disponibilité, cas d'usage et limitations.

⏭️ [MariaDB (fork Debian-native de MySQL)](/module-07-debian-server/03.1-mariadb.md)
