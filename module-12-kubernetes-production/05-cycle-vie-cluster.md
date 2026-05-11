🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 12.5 Cycle de vie du cluster

## Module 12 — Kubernetes Production · Parcours 2

---

## Introduction

Les sections précédentes ont couvert la construction d'un cluster Kubernetes de production : haute disponibilité (12.1), sécurité (12.2), outillage (12.3) et autoscaling (12.4). Mais un cluster de production n'est pas un objet statique que l'on installe une fois pour toutes. C'est un système vivant qui doit être sauvegardé, mis à jour, adapté aux évolutions de la charge et des applications, et préparé à absorber les migrations de workloads.

Le cycle de vie du cluster englobe l'ensemble des opérations qui accompagnent le cluster depuis sa mise en service jusqu'à son éventuel remplacement : sauvegarde et restauration de l'état, montées de version Kubernetes, stratégies de déploiement avancées pour les applications, et migration des charges de travail existantes vers l'architecture conteneurisée.

Ces opérations sont parmi les plus critiques de l'exploitation d'un cluster. Un upgrade raté peut rendre le cluster indisponible. Une sauvegarde non testée est une illusion de sécurité. Un déploiement mal orchestré provoque une interruption de service. Chacune de ces opérations nécessite une planification rigoureuse, des procédures documentées et des tests préalables.

---

## Les quatre piliers du cycle de vie

### Pilier 1 — Sauvegarde et restauration

La capacité à restaurer l'état du cluster après un incident est le filet de sécurité ultime. Sans sauvegarde fiable et testée, toute autre mesure de protection (HA, RBAC, monitoring) peut être anéantie par une erreur humaine, un bug logiciel ou une corruption de données.

Deux niveaux de sauvegarde coexistent dans un cluster Kubernetes :

**Sauvegarde etcd** : elle capture l'intégralité de l'état déclaratif du cluster — chaque ressource Kubernetes, chaque configuration, chaque Secret. C'est le snapshot le plus fondamental, celui qui permet de reconstruire un cluster à partir de zéro. Mais elle ne capture pas les données applicatives (contenus des bases de données, fichiers sur les volumes persistants).

**Sauvegarde applicative (Velero)** : elle capture les ressources Kubernetes d'un ou plusieurs namespaces avec leurs volumes persistants associés. C'est le niveau de sauvegarde pertinent pour la protection des applications et de leurs données, la migration entre clusters, et la réplication d'environnements.

La complémentarité de ces deux niveaux est essentielle : la sauvegarde etcd protège le cluster lui-même, la sauvegarde Velero protège les applications et leurs données.

### Pilier 2 — Upgrade du cluster

Kubernetes suit un cycle de release rapide : une version mineure tous les quatre mois environ, avec un support de chaque version pendant environ 14 mois. Rester à jour n'est pas optionnel — les versions non supportées ne reçoivent plus de correctifs de sécurité et deviennent progressivement incompatibles avec les outils de l'écosystème.

L'upgrade d'un cluster de production est une opération à risque qui touche simultanément le control plane (API Server, etcd, scheduler, controller manager), les nœuds worker (kubelet, container runtime) et les composants de l'écosystème (CNI, CSI, Ingress controllers, opérateurs). Chaque composant a ses propres contraintes de compatibilité et sa propre procédure de mise à jour.

Sur un cluster Debian géré par kubeadm, l'upgrade suit un processus séquentiel strict : control plane d'abord (nœud par nœud), puis workers (nœud par nœud), avec validation à chaque étape. Cette procédure est bien documentée mais demande de la rigueur et de la discipline.

### Pilier 3 — Stratégies de déploiement avancées

Le Deployment Kubernetes natif propose la stratégie `RollingUpdate`, qui remplace progressivement les anciens pods par les nouveaux. Cette stratégie convient à la majorité des mises à jour courantes, mais elle présente des limites pour les déploiements à haut risque : pas de validation fonctionnelle automatique avant bascule complète, pas de possibilité de router seulement une fraction du trafic vers la nouvelle version, rollback qui nécessite un redéploiement complet.

Les stratégies **Blue/Green** et **Canary** adressent ces limites en offrant un contrôle plus fin sur la bascule entre versions :

- **Blue/Green** : deux environnements complets (ancien et nouveau) coexistent, et la bascule se fait instantanément au niveau du routage réseau. Le rollback est immédiat — il suffit de rerouter vers l'ancienne version.
- **Canary** : la nouvelle version est déployée sur un petit pourcentage du trafic, puis progressivement étendue si les métriques sont satisfaisantes. Cette approche réduit le rayon d'impact d'un bug en production.

Ces stratégies sont implémentées soit au niveau de l'infrastructure Kubernetes (manipulation des Services et des Ingress), soit via des outils spécialisés (Argo Rollouts, Flagger) qui automatisent le processus de promotion progressive.

### Pilier 4 — Migration de workloads

La conteneurisation d'une application existante (VM vers conteneur) est rarement une opération triviale. Elle implique des choix architecturaux (monolithe conteneurisé vs refactoring en microservices), des adaptations techniques (gestion des fichiers, des logs, de la configuration), et une stratégie de migration qui minimise le risque et l'interruption de service.

La migration est souvent progressive : les nouveaux services sont nativement conteneurisés, tandis que les services legacy sont migrés par ordre de priorité, en commençant par les plus simples et les moins critiques. Chaque migration suit un cycle de conteneurisation, de test, de déploiement en parallèle, de validation, puis de bascule définitive.

---

## Interdépendances avec les sections précédentes

Le cycle de vie du cluster s'appuie sur les fondations posées dans les sections précédentes de ce module :

| Opération du cycle de vie | Fondations requises |
|:--------------------------|:-------------------|
| Sauvegarde etcd | Architecture HA et TLS etcd (12.1.2) |
| Sauvegarde Velero | Stockage Kubernetes, PV/PVC (11.5) |
| Upgrade du cluster | Architecture HA, load balancing (12.1), drain et PDB (12.1.1, 12.2.4) |
| Blue/Green et Canary | Services, Ingress (11.3, 11.4), Helm ou Kustomize (12.3.2, 12.3.3) |
| Migration VM → conteneurs | Docker, images Debian (10.2), sécurité des conteneurs (10.5, 12.2.2) |

L'architecture HA (12.1) est particulièrement critique pour les opérations de cycle de vie : un cluster à un seul nœud control plane ne peut pas être upgradé sans interruption, et la perte d'etcd sans sauvegarde est irrécupérable.

---

## Maturité opérationnelle

Les opérations de cycle de vie sont le marqueur de la maturité opérationnelle d'une équipe. Le tableau suivant situe les pratiques par niveau de maturité :

| Niveau | Sauvegarde | Upgrade | Déploiement | Migration |
|:------:|:-----------|:--------|:------------|:----------|
| **1 — Ad hoc** | Sauvegardes manuelles occasionnelles, jamais testées | Upgrade reporté indéfiniment par crainte de l'impact | Rolling update natif uniquement | Pas de migration — nouvelles applications uniquement |
| **2 — Documenté** | Sauvegardes automatisées par timer systemd, testées une fois | Upgrade planifié semestriellement, procédure écrite | Blue/Green manuel avec basculement de Service | Migration au cas par cas, procédures individuelles |
| **3 — Automatisé** | Velero avec scheduling, tests de restauration automatiques mensuels | Upgrade trimestriel, automatisé par Ansible, testé en staging | Canary automatisé avec Argo Rollouts, promotion par métriques | Framework de migration standardisé, checklist réutilisable |
| **4 — Optimisé** | Restauration testée en CI, RTO/RPO mesurés et respectés | Upgrade continu (rolling upgrade dès la sortie de chaque patch), zero-downtime validé | Progressive delivery intégrée au pipeline GitOps, rollback automatique | Migration continue — les services legacy sont graduellement décommissionnés |

L'objectif n'est pas d'atteindre le niveau 4 immédiatement, mais de progresser méthodiquement. Le passage du niveau 1 au niveau 2 (documenter et automatiser les sauvegardes, planifier les upgrades) est le progrès le plus impactant.

---

## Prérequis pour cette section

Cette section s'appuie sur l'ensemble des connaissances acquises dans le Module 12 et les modules précédents :

- Cluster haute disponibilité (12.1) : architecture multi-nœuds, etcd, load balancing — indispensable pour les opérations de maintenance sans interruption.
- Sécurité du cluster (12.2) : RBAC pour les accès aux opérations de backup/restore, PDB pour les drains lors des upgrades.
- Outils d'écosystème (12.3) : Helm pour le déploiement des outils (Velero, Argo Rollouts), Kustomize pour la gestion multi-environnement.
- Autoscaling (12.4) : interactions entre les upgrades et le HPA/Cluster Autoscaler.
- Conteneurs et images (Module 10) : construction d'images, bonnes pratiques Dockerfile — fondation pour la migration.
- Stratégies de sauvegarde (Module 8.4) : concepts de RTO/RPO, stratégie 3-2-1, tests de restauration.

---

## Plan de la section

Cette section 12.5 se décompose en quatre sous-parties couvrant les quatre piliers du cycle de vie :

- **12.5.1 — Sauvegarde etcd et Velero** : snapshot etcd automatisé, installation et configuration de Velero, schedules de sauvegarde, restauration complète et partielle, tests de restauration automatisés.
- **12.5.2 — Upgrade de clusters Kubernetes sur Debian** : planification, procédure kubeadm step-by-step (control plane puis workers), upgrade des composants de l'écosystème, validation post-upgrade, gestion des versions n-1/n/n+1.
- **12.5.3 — Blue/Green et Canary deployments** : implémentation native Kubernetes (Services, Ingress), Argo Rollouts (AnalysisRuns, promotion automatique), Flagger, intégration avec les service meshes.
- **12.5.4 — Migration de workloads (VM → conteneurs)** : évaluation des applications candidates, stratégies de conteneurisation (lift-and-shift vs refactoring), patterns de cohabitation VM/conteneur, cutover et décommissionnement.

---

*Le cycle de vie du cluster est le domaine où la discipline opérationnelle fait la différence entre un cluster qui vieillit bien et un cluster qui accumule la dette technique. Les sous-sections qui suivent fournissent les procédures, les outils et les garde-fous pour chaque étape de ce cycle.*

⏭️ [Sauvegarde etcd et Velero](/module-12-kubernetes-production/05.1-sauvegarde-etcd-velero.md)
