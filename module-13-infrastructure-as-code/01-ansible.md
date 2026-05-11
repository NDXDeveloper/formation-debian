🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 13.1 Ansible

## Introduction

Ansible est un outil d'automatisation open source qui permet de gérer la configuration, le déploiement d'applications et l'orchestration d'infrastructures entières de manière déclarative, reproductible et idempotente. Créé en 2012 par Michael DeHaan et aujourd'hui maintenu par Red Hat (IBM), Ansible s'est imposé comme l'un des piliers de l'Infrastructure as Code (IaC) grâce à sa simplicité d'approche et sa courbe d'apprentissage accessible.

Dans le contexte d'une infrastructure Debian — qu'il s'agisse de serveurs bare-metal, de machines virtuelles KVM ou de nœuds Kubernetes — Ansible offre une solution cohérente pour automatiser l'ensemble du cycle de vie des systèmes : du provisionnement initial à la maintenance quotidienne, en passant par la configuration des services et le déploiement applicatif.

---

## Pourquoi Ansible dans une formation Debian ?

Debian est réputée pour sa stabilité et sa rigueur dans la gestion des paquets. Ansible s'intègre naturellement dans cet écosystème pour plusieurs raisons.

**Architecture agentless.** Contrairement à Puppet ou Chef, Ansible ne nécessite l'installation d'aucun agent sur les machines cibles. Il s'appuie exclusivement sur SSH (déjà configuré dans le Module 6) et Python (présent par défaut sur tout système Debian). Cette approche réduit considérablement la surface d'attaque et la complexité opérationnelle : il n'y a aucun daemon supplémentaire à surveiller, aucun certificat d'agent à renouveler, aucun port additionnel à ouvrir dans le pare-feu.

**Langage déclaratif en YAML.** Les playbooks Ansible sont écrits en YAML, un format lisible par l'humain qui ne requiert aucune compétence en programmation avancée. Un administrateur système Debian habitué à éditer des fichiers de configuration s'y retrouvera immédiatement. Cette lisibilité facilite également la revue de code, la documentation vivante et le travail en équipe.

**Idempotence native.** Chaque module Ansible est conçu pour être idempotent : exécuter un playbook une ou cent fois produit le même résultat final. Si un paquet est déjà installé, Ansible ne tente pas de le réinstaller. Si un fichier de configuration est déjà à jour, il n'est pas modifié. Cette propriété est essentielle en production, car elle permet de ré-appliquer une configuration en toute sécurité sans craindre d'effets de bord.

**Écosystème riche pour Debian.** Ansible dispose de modules natifs qui s'intègrent directement avec les outils Debian : `apt` pour la gestion des paquets `.deb`, `systemd` pour le contrôle des services, `ufw` pour le pare-feu, `debconf` pour la préconfiguration des paquets, et bien d'autres. Les collections communautaires disponibles sur Ansible Galaxy couvrent des cas d'usage allant de la configuration de PostgreSQL au déploiement de clusters Kubernetes.

---

## Positionnement d'Ansible dans le paysage IaC

L'Infrastructure as Code regroupe un ensemble de pratiques et d'outils visant à gérer l'infrastructure par le code plutôt que par des interventions manuelles. Dans cet écosystème, chaque outil occupe un rôle distinct.

Ansible se positionne principalement comme un outil de **gestion de configuration** (Configuration Management) et d'**orchestration**. Il excelle dans les tâches suivantes : installer et configurer des paquets, déployer des fichiers de configuration à partir de templates, orchestrer des séquences de déploiement multi-serveurs, exécuter des actions ponctuelles (ad hoc) sur un parc de machines, et automatiser des workflows complexes impliquant plusieurs systèmes.

En revanche, le **provisionnement d'infrastructure** — c'est-à-dire la création des ressources elles-mêmes (machines virtuelles, réseaux, volumes de stockage) — est un domaine où Terraform (traité en section 13.2) se révèle plus adapté. La section 13.3 de ce module explore précisément la complémentarité entre ces deux outils et les patterns d'intégration recommandés.

Le tableau suivant résume le positionnement relatif des principaux outils IaC :

| Critère | Ansible | Terraform | Puppet / Chef |
|---|---|---|---|
| Approche | Déclarative avec ordre d'exécution explicite | Purement déclarative | Déclarative |
| Architecture | Agentless (SSH + Python) | Client uniquement (appels API) | Agent sur chaque nœud |
| Langage | YAML (playbooks) | HCL | DSL propriétaire (Ruby) |
| Force principale | Configuration et orchestration | Provisionnement d'infra | Configuration à grande échelle |
| Gestion d'état | Sans état (stateless) | Fichier d'état (state file) | Base de données centralisée |
| Idempotence | Par module | Par graphe de dépendances | Par manifeste |
| Courbe d'apprentissage | Faible à modérée | Modérée | Élevée |

---

## Concepts fondamentaux

Avant de plonger dans l'installation et la configuration (section 13.1.1), il est utile de se familiariser avec les concepts clés qui structurent l'ensemble de l'écosystème Ansible.

**Nœud de contrôle (Control Node).** C'est la machine depuis laquelle Ansible est exécuté. Dans notre contexte, il s'agit d'un poste ou serveur Debian sur lequel Ansible est installé. C'est le seul endroit où Ansible doit être présent. Le nœud de contrôle peut être un poste de travail d'administrateur, un serveur dédié à l'automatisation, ou un runner CI/CD.

**Nœuds gérés (Managed Nodes).** Ce sont les machines cibles sur lesquelles Ansible applique les configurations. Elles nécessitent uniquement un accès SSH et un interpréteur Python. Dans le cadre de cette formation, les nœuds gérés sont des serveurs Debian configurés selon les principes du Parcours 1.

**Inventaire (Inventory).** L'inventaire est le fichier (statique ou dynamique) qui définit les machines gérées, leur regroupement logique et les variables associées. Il constitue la cartographie de l'infrastructure sur laquelle Ansible opère.

**Module.** Un module est une unité de travail autonome qu'Ansible exécute sur les nœuds gérés. Chaque module réalise une tâche spécifique : installer un paquet (`apt`), copier un fichier (`copy`), gérer un service (`systemd`), créer un utilisateur (`user`). Ansible dispose de plusieurs milliers de modules couvrant une très grande variété de cas d'usage.

**Tâche (Task).** Une tâche est l'appel d'un module avec des paramètres spécifiques. Elle représente une action unitaire dans un playbook, par exemple « installer le paquet nginx » ou « activer le service sshd ».

**Playbook.** Un playbook est un fichier YAML qui décrit une séquence ordonnée de tâches à appliquer sur un ensemble de nœuds. C'est l'unité fondamentale de travail dans Ansible. Un playbook peut contenir un ou plusieurs *plays*, chacun ciblant un groupe de machines différent.

**Rôle.** Un rôle est une structure standardisée permettant d'organiser et de réutiliser des playbooks, variables, templates, fichiers et handlers de manière modulaire. Les rôles favorisent la réutilisabilité et le partage via Ansible Galaxy.

**Collection.** Introduites dans Ansible 2.9, les collections regroupent des modules, rôles, plugins et documentation dans des packages distribuables. Elles constituent le mécanisme principal de distribution et de versionnement du contenu Ansible.

---

## Ce que couvre cette section

La section 13.1 est structurée en sept sous-sections progressives qui vous amèneront de l'installation d'Ansible sur Debian jusqu'à son utilisation dans des contextes avancés, y compris l'orchestration Kubernetes.

La sous-section **13.1.1 — Architecture et installation sur Debian** détaille l'architecture interne d'Ansible, les différentes méthodes d'installation disponibles sur Debian (paquets APT, pip, pipx) et la configuration initiale du nœud de contrôle.

La sous-section **13.1.2 — Inventaires, connexions et variables** traite de la définition des inventaires statiques et dynamiques, de la configuration des connexions SSH, et du système de variables et de leur hiérarchie de précédence.

La sous-section **13.1.3 — Playbooks : structure, templates Jinja2, handlers** couvre l'écriture de playbooks structurés, l'utilisation du moteur de templates Jinja2 pour générer des fichiers de configuration dynamiques, et le mécanisme des handlers pour gérer les redémarrages de services.

La sous-section **13.1.4 — Rôles, collections et Ansible Galaxy** explore la structuration du code Ansible en rôles réutilisables, l'utilisation des collections et l'intégration avec Ansible Galaxy pour partager et consommer du contenu communautaire.

La sous-section **13.1.5 — Ansible pour provisionner des nœuds Debian** se concentre sur les cas d'usage spécifiques à Debian : gestion des paquets `.deb`, configuration système, intégration avec les outils natifs Debian et patterns de provisionnement courants.

La sous-section **13.1.6 — Ansible pour Kubernetes** couvre l'utilisation d'Ansible pour déployer et gérer des clusters Kubernetes, en s'appuyant sur les compétences acquises dans les modules 11 et 12.

La sous-section **13.1.7 — AWX / Ansible Automation Platform** présente les solutions d'entreprise permettant de centraliser, planifier et auditer l'exécution des playbooks Ansible à travers une interface web et une API REST.

---

## Prérequis

Pour aborder cette section dans les meilleures conditions, les connaissances et compétences suivantes sont attendues :

- Administration système Debian (Modules 3 à 5) : gestion des utilisateurs, des services systemd, des permissions et du système de fichiers.
- Configuration et sécurisation SSH (Module 6, section 6.3) : authentification par clés, configuration du client et du serveur SSH, tunneling.
- Réseau Debian (Module 6, section 6.1) : adressage IP, résolution DNS, diagnostic réseau de base.
- Scripting Bash et notions de Python (Module 5) : lecture et compréhension de scripts, manipulation de variables et structures de contrôle.
- Gestion des paquets APT (Module 4) : installation, mise à jour et configuration des dépôts.
- Familiarité avec YAML : bien qu'aucune expérience préalable ne soit strictement nécessaire, une aisance avec les formats de données structurées est un atout.

---

## Conventions utilisées dans cette section

Tout au long de la section 13.1, les conventions suivantes s'appliquent :

Les commandes exécutées sur le **nœud de contrôle** (la machine Debian depuis laquelle Ansible est piloté) sont préfixées par le prompt `controller$`. Les commandes exécutées sur un **nœud géré** (serveur cible) sont préfixées par `node$`. Les commandes nécessitant les privilèges root sont préfixées par `#`.

Les fichiers de configuration et playbooks présentés utilisent des chemins conformes aux conventions Debian et au FHS (Filesystem Hierarchy Standard) tel qu'abordé dans le Module 3.

L'environnement de référence repose sur **Debian 13 "Trixie"** (stable depuis août 2025) avec **Ansible Core 2.19+** (paquet `ansible 12.x` dans Trixie, qui inclut `ansible-core 2.19.4`) et **Python 3.13** (version livrée par défaut sur Trixie). Les éventuelles spécificités liées à des versions antérieures de Debian (Bookworm) sont signalées lorsqu'elles existent.

⏭️ [Architecture et installation sur Debian](/module-13-infrastructure-as-code/01.1-architecture-installation-debian.md)
