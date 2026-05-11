🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 14.2 CI/CD sur serveur Debian

## Introduction

La section précédente (14.1) a posé les principes théoriques du CI/CD : intégration continue, déploiement continu, conception de pipelines et stratégies de branching. Il est temps de passer à la mise en œuvre concrète. Et le point de départ le plus naturel dans le cadre de cette formation est celui que tout administrateur système Debian maîtrise déjà : **un serveur Debian classique, administré avec les outils et les pratiques des Parcours 1 et 2**.

Avant l'ère Kubernetes, et encore aujourd'hui dans de très nombreuses organisations, l'infrastructure CI/CD repose sur des **serveurs dédiés** qui hébergent les agents d'exécution (runners) des pipelines. Ces runners sont installés, configurés et maintenus comme n'importe quel autre service d'infrastructure — au même titre qu'un serveur web Nginx, une base de données PostgreSQL ou un serveur DNS BIND.

Cette approche, parfois qualifiée de « bare-metal CI » ou de « self-hosted CI », constitue le socle historique et reste une solution parfaitement viable, performante et souvent préférable dans de nombreux contextes.

---

## Pourquoi héberger ses runners sur Debian ?

### La maîtrise de l'environnement

Héberger ses propres runners offre un **contrôle total** sur l'environnement d'exécution. Contrairement aux runners cloud managés (GitLab.com shared runners, GitHub-hosted runners), un runner self-hosted sur Debian permet de :

- Choisir précisément la version de Debian, le noyau, les paquets système installés.
- Accéder à du matériel spécifique (GPU, FPGA, périphériques réseau, stockage haute performance).
- Garantir que les données du pipeline ne quittent jamais le réseau interne de l'organisation (exigence fréquente dans les secteurs réglementés).
- Dimensionner les ressources (CPU, RAM, disque) en fonction des besoins réels des pipelines.
- Maîtriser les coûts : pas de facturation à la minute d'exécution, pas de surprises sur la facture cloud.

### Debian Stable : la fiabilité au service du CI/CD

Debian Stable est un choix particulièrement pertinent pour héberger des runners CI/CD, pour les raisons qui en font un pilier de l'infrastructure serveur depuis des décennies :

**Stabilité et prévisibilité.** Les paquets de Debian Stable ne changent pas de version majeure pendant toute la durée de vie de la release. Un runner installé sur Debian Bookworm fonctionnera de manière identique pendant les cinq ans de support standard — pas de rupture liée à une mise à jour du système.

**Cycles de support longs.** Avec le support standard (~5 ans), LTS (~5 ans supplémentaires) et ELTS, un serveur Debian peut rester en production jusqu'à 10 ans avec des mises à jour de sécurité (voir section 1.1.3).

**Empreinte minimale.** Une installation serveur minimale de Debian consomme moins de 200 Mo de RAM et quelques gigaoctets de disque, laissant le maximum de ressources aux jobs CI.

**Écosystème APT.** L'installation et la mise à jour des runners et de leurs dépendances s'intègrent naturellement dans le workflow APT que l'administrateur maîtrise déjà.

### Le lien avec les compétences acquises

Administrer un runner CI/CD sur Debian mobilise directement les compétences des modules précédents :

| Compétence | Module source | Application CI/CD |
|-----------|---------------|-------------------|
| Gestion des services systemd | Module 3 (§ 3.4) | Le runner s'exécute comme un service systemd |
| Gestion des utilisateurs et permissions | Module 3 (§ 3.2) | Compte de service dédié, isolation des jobs |
| Pare-feu et sécurité réseau | Module 6 (§ 6.2) | Filtrage du trafic sortant/entrant du runner |
| SSH et accès distant | Module 6 (§ 6.3) | Déploiement vers des cibles distantes |
| Docker sur Debian | Module 10 (§ 10.2) | Exécution des jobs dans des conteneurs |
| Monitoring et logs | Module 3 (§ 3.5) | Surveillance de l'état et des performances du runner |
| Sauvegarde et maintenance | Module 8 (§ 8.4) | Sauvegarde de la configuration, procédures de recovery |
| Automatisation Ansible | Module 13 (§ 13.1) | Déploiement et configuration automatisée des runners |

Un administrateur système Debian qui maîtrise ces fondamentaux est en mesure de déployer, sécuriser et maintenir une infrastructure CI/CD complète sans outil supplémentaire.

---

## Architecture type d'une infrastructure CI/CD self-hosted

### Vue d'ensemble

L'architecture self-hosted suit un modèle **serveur/agent** dans lequel une plateforme centrale (GitLab, GitHub, Jenkins) orchestre les pipelines, tandis que des runners décentralisés exécutent les jobs :

```
┌───────────────────────────────────────────────────────────┐
│                   Plateforme CI/CD                        │
│             (GitLab, GitHub, Jenkins...)                  │
│                                                           │
│  ┌───────────┐   ┌───────────┐  ┌───────────┐             │
│  │ Pipeline  │   │ Pipeline  │  │ Pipeline  │             │
│  │ Projet A  │   │ Projet B  │  │ Projet C  │   ...       │
│  └─────┬─────┘   └─────┬─────┘  └─────┬─────┘             │
│        │               │              │                   │
└────────┼───────────────┼──────────────┼───────────────────┘
         │               │              │
         ▼               ▼              ▼
┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│  Runner 1      │ │  Runner 2      │ │  Runner 3      │
│  Debian 13     │ │  Debian 13     │ │  Debian 13     │
│  Rôle : build  │ │  Rôle : test   │ │  Rôle : deploy │
│                │ │                │ │                │
│  Docker        │ │  Docker        │ │  kubectl       │
│  BuildKit      │ │  PostgreSQL    │ │  Helm          │
│  Trivy         │ │  Redis         │ │  Ansible       │
└────────────────┘ └────────────────┘ └────────────────┘
              Serveurs Debian dédiés ou VM
```

### Modes d'exécution des runners

Les runners self-hosted peuvent exécuter les jobs de différentes manières, appelées **executors** :

**Shell executor** — Le job s'exécute directement dans un shell sur le serveur Debian. C'est le mode le plus simple, mais aussi le moins isolé : chaque job a accès au système de fichiers du runner, et les jobs se partagent le même environnement. Ce mode convient pour des environnements mono-projet ou de confiance.

**Docker executor** — Le job s'exécute dans un conteneur Docker éphémère, construit à partir de l'image spécifiée dans la définition du pipeline. Ce mode offre une **isolation forte** entre les jobs (chaque job dispose de son propre système de fichiers, de ses propres processus) et garantit la reproductibilité. C'est le mode recommandé dans la majorité des cas.

**Docker Autoscaler / Instance executor** — Variantes du Docker executor qui provisionnent automatiquement des machines virtuelles à la demande (autoscaling) via les fleeting plugins (AWS, GCP, Azure, Hetzner). Les VM sont créées pour exécuter le job et détruites ensuite. Ce mode est pertinent pour les pics de charge. Ces deux executors remplacent l'ancien `docker+machine` (Docker Machine), déprécié dans GitLab 17.5 et planifié pour suppression dans GitLab 20.0 (voir section 14.2.3 § 8.3).

**SSH executor** — Le runner se connecte à une machine distante via SSH pour y exécuter le job. Utile pour les déploiements sur des serveurs de production ou pour l'exécution sur du matériel spécialisé.

Le choix de l'executor a un impact direct sur la sécurité, la performance, le coût et la complexité de maintenance — un sujet détaillé dans la section 14.2.3.

### Dimensionnement

Le dimensionnement des runners dépend de la nature des jobs exécutés :

| Type de workload | CPU | RAM | Disque | Réseau |
|-----------------|-----|-----|--------|--------|
| Build d'images Docker | 4-8 cœurs | 8-16 Go | SSD 100+ Go | Rapide (pull/push registry) |
| Tests unitaires (langage interprété) | 2-4 cœurs | 4-8 Go | SSD 50 Go | Modéré |
| Tests d'intégration (conteneurs services) | 4-8 cœurs | 16-32 Go | SSD 100+ Go | Rapide |
| Compilation (C/C++, Go, Rust) | 8-16 cœurs | 16-32 Go | SSD 100+ Go | Modéré |
| Scan de sécurité (Trivy, SAST) | 2-4 cœurs | 8-16 Go | SSD 50 Go | Rapide (téléchargement DB CVE) |
| Déploiement (kubectl, Helm, Ansible) | 2 cœurs | 4 Go | SSD 20 Go | Accès cluster/cibles |

La règle empirique : **un runner doit pouvoir exécuter confortablement le job le plus gourmand qui lui sera attribué**, avec une marge de 20-30 % pour absorber les pics. Le surprovisionnement est préférable au sous-provisionnement — un job de build qui swap est un job qui prend 10 fois plus de temps.

---

## Runners cloud-managés vs self-hosted : critères de choix

Le choix entre runners managés et runners self-hosted n'est pas binaire : de nombreuses organisations combinent les deux, utilisant les runners managés pour les projets standards et les runners self-hosted pour les cas spécifiques.

| Critère | Runners cloud-managés | Runners self-hosted (Debian) |
|---------|----------------------|------------------------------|
| **Mise en place** | Immédiate (rien à installer) | Installation et configuration requises |
| **Maintenance** | Gérée par le fournisseur | À la charge de l'équipe |
| **Coût** | À la minute (peut devenir cher) | Coût fixe de l'infrastructure |
| **Performance** | Standardisée, non personnalisable | Dimensionnable librement |
| **Matériel spécifique** | Limité (GPU en option payante) | Accès direct (GPU, FPGA, réseau) |
| **Sécurité des données** | Données transitent chez le fournisseur | Données restent on-premise |
| **Accès réseau interne** | Nécessite un tunnel ou VPN | Accès natif au réseau interne |
| **Conformité réglementaire** | Dépend du fournisseur et du contrat | Contrôle total |
| **Isolation** | Bonne (VM éphémères) | Dépend de l'executor choisi |
| **Disponibilité** | SLA du fournisseur | Responsabilité interne |
| **Scaling** | Automatique | Manuel ou avec outillage dédié |

Les cas d'usage les plus fréquents pour les runners self-hosted sur Debian sont :

- Les organisations qui traitent des données sensibles ou réglementées (santé, finance, défense).
- Les projets qui nécessitent un accès au réseau interne (déploiement sur des serveurs on-premise, accès à des bases de données internes, registries privés).
- Les équipes dont les pipelines sont très consommateurs de ressources (builds lourds, tests d'intégration massifs) et où le coût à la minute des runners cloud devient prohibitif.
- Les projets qui nécessitent du matériel spécifique non disponible dans le cloud.

---

## Sécurité : surface d'attaque spécifique des runners CI/CD

Un runner CI/CD est un **vecteur d'attaque privilégié**. Par nature, il exécute du code arbitraire (le contenu des pipelines), a accès à des secrets (tokens de déploiement, credentials de registries) et dispose souvent de droits étendus sur l'infrastructure (accès au cluster Kubernetes, accès SSH aux serveurs de production). Un runner compromis peut avoir des conséquences catastrophiques.

Les menaces spécifiques aux runners CI/CD incluent :

**L'exécution de code malveillant.** Un attaquant qui obtient la capacité de déclencher un pipeline (via une merge request sur un projet ouvert, par exemple) peut exécuter du code arbitraire sur le runner. Avec un shell executor, cela signifie un accès au système de fichiers du serveur.

**L'exfiltration de secrets.** Les variables CI contenant des tokens et credentials sont accessibles pendant l'exécution du job. Un job malveillant peut les capturer et les transmettre à un serveur externe.

**L'empoisonnement de la supply chain.** Un attaquant qui contrôle le build peut injecter du code malveillant dans l'artefact produit (image Docker, paquet .deb), qui sera ensuite déployé en production.

**L'escalade de privilèges.** Un runner qui exécute Docker avec le socket Docker monté (`/var/run/docker.sock`) offre effectivement un accès root au système hôte à tout job qui s'exécute.

La section 14.2.3 détaillera les mesures de sécurisation spécifiques pour chaque type de runner et chaque executor.

---

## Approche de cette section

Les trois sous-sections suivantes abordent la mise en œuvre concrète :

**14.2.1 — GitLab Runner comme service systemd sur Debian.** Installation, enregistrement, configuration des executors, gestion du cycle de vie du runner via systemd, et intégration dans l'infrastructure Debian.

**14.2.2 — GitHub Actions self-hosted runner sur Debian.** Installation, enregistrement auprès de GitHub, configuration comme service systemd, gestion des labels et des groupes de runners.

**14.2.3 — Configuration, maintenance et sécurisation des runners.** Bonnes pratiques de sécurisation (isolation, gestion des secrets, restrictions réseau), stratégies de mise à jour, monitoring, et automatisation du déploiement de runners avec Ansible.

Bien que GitLab et GitHub soient les deux plateformes les plus utilisées, les principes sous-jacents — installation d'un agent, enregistrement auprès d'une plateforme, exécution de jobs dans un environnement contrôlé, gestion via systemd — sont transposables à d'autres systèmes (Gitea, Forgejo, Woodpecker CI, Drone).

---

## Plan de la section

- **14.2.1** — GitLab Runner comme service systemd sur Debian
- **14.2.2** — GitHub Actions self-hosted runner sur Debian
- **14.2.3** — Configuration, maintenance et sécurisation des runners

---

*La section suivante (14.2.1) abordera l'installation complète de GitLab Runner sur Debian : ajout du dépôt APT officiel, installation du paquet, enregistrement auprès d'une instance GitLab, configuration des executors (shell, Docker), et gestion du service via systemd.*

⏭️ [GitLab Runner comme service systemd sur Debian](/module-14-cicd-gitops/02.1-gitlab-runner-systemd.md)
