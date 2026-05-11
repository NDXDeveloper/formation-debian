🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 15.2 Métriques et alerting

## Introduction

La section 15.1 a posé le cadre conceptuel de l'observabilité : les trois piliers, le cadre SLI/SLO/error budgets, et les principes d'une stratégie globale. Cette section entre dans la mise en œuvre concrète du premier pilier — les métriques — et de son corollaire opérationnel — l'alerting.

Les métriques sont le pilier le plus mature de l'écosystème d'observabilité. Elles bénéficient d'outils éprouvés, de standards stabilisés et d'une communauté vaste. Dans l'écosystème Debian et Kubernetes, Prometheus s'est imposé comme le standard de facto : intégré nativement dans Kubernetes, adopté par la quasi-totalité des projets CNCF, et soutenu par un écosystème d'exporteurs couvrant pratiquement tous les composants d'infrastructure imaginables.

Mais collecter des métriques n'est que la première étape. La valeur opérationnelle se matérialise quand ces métriques alimentent des dashboards pertinents (Grafana), déclenchent des alertes ciblées (AlertManager), et sous-tendent les SLO qui guident les décisions d'ingénierie. C'est l'ensemble de cette chaîne — de la collecte à la décision — que cette section couvre.

---

## De la théorie à la pratique

### Le chemin parcouru

Les sections précédentes ont introduit les métriques sous l'angle conceptuel : les types de métriques (counter, gauge, histogram, summary), le modèle de données en séries temporelles multidimensionnelles, le problème de la cardinalité, et le rôle des métriques dans la corrélation avec les logs et les traces (section 15.1.1). Le cadre SLI/SLO a montré comment transformer des métriques brutes en objectifs de fiabilité mesurables, et comment le burn rate permet un alerting orienté impact utilisateur (section 15.1.2). La stratégie d'observabilité globale a défini l'architecture de référence et les conventions à respecter (section 15.1.3).

### Ce qui reste à couvrir

Cette section passe de la théorie à l'implémentation. Il ne s'agit plus de savoir **pourquoi** collecter des métriques, mais **comment** le faire concrètement dans un environnement Debian et Kubernetes en production. Les questions pratiques sont nombreuses : comment installer et configurer Prometheus sur un nœud Debian ? Comment le déployer dans un cluster Kubernetes ? Comment écrire des requêtes PromQL efficaces ? Comment configurer AlertManager pour router les alertes vers les bons canaux ? Comment construire des dashboards Grafana qui aident réellement au diagnostic ? Comment instrumenter un nœud Debian avec node_exporter pour couvrir l'ensemble des métriques système ?

---

## L'écosystème Prometheus

### Pourquoi Prometheus

Avant de détailler l'architecture, il est utile de comprendre pourquoi Prometheus domine l'écosystème des métriques cloud-native, et pourquoi cette formation le retient comme outil de référence.

**Origine et adoption.** Prometheus a été créé chez SoundCloud en 2012, inspiré par Borgmon, le système de monitoring interne de Google. Rejoint par la Cloud Native Computing Foundation (CNCF) en 2016 comme deuxième projet hébergé (après Kubernetes lui-même), il a atteint le statut de projet « graduated » en 2018. Cette proximité avec l'écosystème Kubernetes n'est pas un hasard : les deux projets partagent une philosophie commune de découverte de services dynamique, de labels multidimensionnels et de gestion des composants éphémères.

**Modèle pull.** Contrairement aux systèmes push traditionnels (où chaque composant envoie ses métriques à un collecteur central), Prometheus **scrape** (interroge) les endpoints de métriques à intervalle régulier. Ce modèle a plusieurs avantages dans un contexte Debian et Kubernetes : Prometheus contrôle la fréquence de collecte, la découverte de nouvelles cibles est automatique (via la service discovery Kubernetes ou la configuration statique sur les nœuds Debian), et l'absence de réponse d'un endpoint est elle-même un signal (la cible est down).

**Format ouvert.** Le format d'exposition des métriques Prometheus (texte plat, lisible par un humain) est devenu un standard de facto, formalisé sous le nom OpenMetrics et adopté par des centaines de projets. Tout composant qui expose un endpoint `/metrics` au format Prometheus est immédiatement intégrable dans l'écosystème, sans agent ni configuration complexe. Sur Debian, cela signifie que l'ajout d'un nouvel exporteur se résume souvent à installer un binaire, le configurer comme service systemd, et ajouter une cible dans la configuration de Prometheus.

**PromQL.** Le langage de requête de Prometheus est expressif, puissant et spécifiquement conçu pour les séries temporelles. Il permet des opérations qui seraient extrêmement complexes dans un langage SQL classique : calcul de taux de variation sur des compteurs avec gestion automatique des resets, agrégation multidimensionnelle avec filtrage par label, opérations arithmétiques entre séries temporelles de sources différentes, calcul de percentiles à partir d'histogrammes. La maîtrise de PromQL est une compétence fondamentale pour tout ingénieur travaillant avec l'écosystème cloud-native.

**Écosystème d'exporteurs.** La force de Prometheus réside aussi dans la richesse de son écosystème d'exporteurs — des programmes qui traduisent les métriques d'un composant tiers dans le format Prometheus. Pour un environnement Debian, les exporteurs les plus pertinents couvrent le système d'exploitation (node_exporter), les bases de données (postgres_exporter, mysqld_exporter), les serveurs web (nginx_exporter, apache_exporter), les services réseau (blackbox_exporter, snmp_exporter, bind_exporter), le stockage (smartctl_exporter), et bien d'autres. Sur Kubernetes, les composants du cluster exposent nativement leurs métriques au format Prometheus.

### Les composants de l'écosystème

L'écosystème Prometheus n'est pas un outil monolithique mais un ensemble de composants spécialisés qui s'assemblent selon les besoins :

**Prometheus Server.** Le cœur du système : il scrape les endpoints, stocke les séries temporelles dans sa base locale (TSDB), évalue les règles d'enregistrement (recording rules) et d'alerte, et expose une API de requête PromQL. C'est le composant que l'on installe en premier, que ce soit sur un nœud Debian dédié ou dans un cluster Kubernetes.

**AlertManager.** Le gestionnaire d'alertes, séparé du serveur Prometheus. Il reçoit les alertes déclenchées par les règles Prometheus, les déduplique, les groupe, les silence si nécessaire, et les route vers les canaux de notification appropriés (email, Slack, PagerDuty, OpsGenie, webhooks). Cette séparation permet à plusieurs instances Prometheus d'envoyer leurs alertes à un même AlertManager, et de gérer les politiques de notification indépendamment de la collecte.

**Exporteurs.** Les agents qui exposent les métriques de composants tiers. Certains sont officiels (node_exporter, blackbox_exporter), d'autres sont communautaires. Sur un nœud Debian, les exporteurs tournent comme des services systemd légers, chacun exposant un endpoint HTTP `/metrics` que Prometheus scrape.

**Pushgateway.** Un composant intermédiaire qui permet aux jobs éphémères (scripts batch, tâches cron, jobs Kubernetes) de pousser leurs métriques vers un endpoint central que Prometheus scrape ensuite. Cela contourne la limitation du modèle pull pour les processus qui vivent moins longtemps que l'intervalle de scrape. Son usage doit rester limité aux cas où le modèle pull est véritablement inadapté.

**Grafana.** Bien que ne faisant pas partie du projet Prometheus à proprement parler, Grafana est le compagnon incontournable pour la visualisation. Il interroge Prometheus via l'API PromQL et propose des dashboards interactifs, des panneaux de graphiques, des tableaux, des jauges et des cartes de chaleur. La communauté maintient des milliers de dashboards prêts à l'emploi sur grafana.com, couvrant la plupart des exporteurs et des cas d'usage.

**Thanos / Cortex / Mimir.** Des solutions de stockage long terme et de haute disponibilité qui étendent Prometheus au-delà de ses limites natives (un seul nœud, rétention locale limitée). Ils permettent de fédérer plusieurs instances Prometheus, de dédupliquer les données, de stocker les métriques dans un stockage objet (S3, MinIO sur Debian), et de requêter des mois ou des années d'historique. Ces composants deviennent pertinents quand l'infrastructure dépasse une dizaine de nœuds ou quand la rétention doit excéder quelques semaines.

---

## La chaîne métriques-alerting de bout en bout

Pour donner une vision d'ensemble avant d'entrer dans le détail de chaque composant, voici le flux complet des données depuis le composant surveillé jusqu'à la notification de l'opérateur :

```
┌──────────────┐     scrape      ┌───────────────┐
│  Composant   │  ◄──────────    │  Prometheus   │
│  (endpoint   │   /metrics      │   Server      │
│   /metrics)  │   toutes les    │               │
│              │   15-30s        │  ┌──────────┐ │
│ node_exporter│                 │  │  TSDB    │ │
│ kube-state-  │                 │  │ (stockage│ │
│   metrics    │                 │  │  local)  │ │
│ application  │                 │  └──────────┘ │
└──────────────┘                 │               │
                                 │  ┌──────────┐ │
                                 │  │ Recording│ │
                                 │  │  Rules   │ │
                                 │  └──────────┘ │
                                 │               │
                                 │  ┌──────────┐ │    alertes     ┌──────────────┐
                                 │  │ Alerting │ │  ────────────► │ AlertManager │
                                 │  │  Rules   │ │                │              │
                                 │  └──────────┘ │                │ groupement   │
                                 └───────┬───────┘                │ silencing    │
                                         │                        │ routing      │
                                    API PromQL                    └──────┬───────┘
                                         │                               │
                                         ▼                               ▼
                                 ┌──────────────┐                notifications
                                 │   Grafana    │              (email, Slack,
                                 │              │               PagerDuty...)
                                 │ dashboards   │
                                 │ exploration  │
                                 │ corrélation  │
                                 └──────────────┘
```

Ce flux se décompose en cinq étapes fonctionnelles que les sous-sections suivantes détaillent :

**1. Exposition** — Les composants exposent leurs métriques sur un endpoint HTTP. Sur un nœud Debian, node_exporter expose les métriques système. Sur Kubernetes, chaque pod applicatif instrumenté, kube-state-metrics et les composants du control plane exposent leurs endpoints respectifs.

**2. Collecte** — Prometheus scrape ces endpoints à intervalle régulier, stocke les échantillons dans sa base de séries temporelles, et applique les labels configurés (job, instance, et tout label supplémentaire défini dans la configuration de scrape ou par relabeling).

**3. Traitement** — Les recording rules pré-calculent des expressions PromQL complexes (SLI, taux agrégés, moyennes glissantes) et les stockent comme de nouvelles séries temporelles, réduisant la charge de calcul lors des requêtes et des évaluations d'alertes.

**4. Alerting** — Les alerting rules évaluent des conditions PromQL à intervalle régulier. Quand une condition est vraie pendant une durée configurable (`for`), Prometheus envoie l'alerte à AlertManager, qui la déduplique, la groupe, applique les éventuels silences, et la route vers les canaux de notification appropriés.

**5. Visualisation** — Grafana interroge Prometheus via l'API PromQL pour alimenter les dashboards. Les opérateurs consultent les dashboards pour le monitoring en temps réel, l'investigation d'incidents et le suivi des SLO.

---

## Spécificités du contexte Debian

### Prometheus sur nœud Debian autonome

Dans le parcours 1 de cette formation (modules 1 à 8), l'infrastructure repose sur des serveurs Debian individuels hébergeant des services classiques : serveur web, base de données, DNS, DHCP, serveur mail. Sur cette infrastructure, Prometheus est installé directement sur un nœud Debian (ou un nœud dédié au monitoring) comme un service systemd classique. La configuration est un fichier YAML statique qui liste les cibles à scraper (les exporteurs installés sur chaque serveur).

Cette approche est simple, robuste et adaptée aux environnements de petite à moyenne taille. Elle ne nécessite ni conteneurisation ni orchestrateur. Un serveur Debian modeste (2 CPU, 4 Go RAM, 50 Go SSD) peut héberger Prometheus, Grafana et AlertManager pour un parc d'une centaine de nœuds sans difficulté.

### Prometheus sur Kubernetes

Dans les parcours 2 et 3 (modules 9 à 19), l'infrastructure évolue vers la conteneurisation et Kubernetes. Prometheus est alors déployé dans le cluster lui-même, typiquement via le chart Helm `kube-prometheus-stack` (maintenu par la communauté `prometheus-community`, anciennement `helm-charts/prometheus-operator`). Ce chart installe et configure l'ensemble de l'écosystème en un seul déploiement : le **Prometheus Operator** (qui gère les CRD), une instance Prometheus, AlertManager, Grafana, node_exporter (en DaemonSet), kube-state-metrics, et les dashboards et alertes préconfigurés pour le monitoring Kubernetes.

L'opérateur Prometheus (Prometheus Operator) introduit des Custom Resource Definitions (CRD — module 12.3.4) qui permettent de gérer la configuration de Prometheus de manière déclarative et native Kubernetes : les `ServiceMonitor` et `PodMonitor` définissent les cibles de scrape, les `PrometheusRule` définissent les recording et alerting rules, et le `Prometheus` CRD configure l'instance Prometheus elle-même. Cette approche « Kubernetes-native » est plus complexe à mettre en place initialement mais s'intègre naturellement dans un workflow GitOps (module 14.4).

### Le pont entre les deux mondes

Dans un environnement hybride — des serveurs Debian autonomes coexistant avec un cluster Kubernetes — Prometheus sur Kubernetes peut scraper à la fois les endpoints internes au cluster et les exporteurs des nœuds Debian externes, à condition que le réseau le permette. Alternativement, une instance Prometheus dédiée aux nœuds Debian autonomes peut fédérer ses données vers le Prometheus du cluster via le mécanisme de fédération ou via le remote write vers un stockage centralisé (Thanos, Mimir).

---

## Compétences visées

À l'issue de cette section, les concepts et savoir-faire suivants seront couverts :

**Architecture Prometheus** (15.2.1) — Comprendre l'architecture interne de Prometheus (TSDB, scrape engine, rule engine, API), les modes de déploiement sur Debian (binaire + systemd) et sur Kubernetes (Prometheus Operator + Helm), la service discovery, et les stratégies de haute disponibilité et de stockage long terme.

**PromQL et métriques custom** (15.2.2) — Maîtriser le langage de requête de Prometheus : sélection de séries, fonctions d'agrégation et de taux, opérations entre vecteurs, calcul de percentiles à partir d'histogrammes, écriture de recording rules et de requêtes pour les SLI. Savoir instrumenter une application pour exposer des métriques custom au format Prometheus.

**AlertManager** (15.2.3) — Configurer le routing des alertes (arbre de routes, matchers, receivers), le groupement, le silencing, l'inhibition, et les intégrations avec les canaux de notification (email, Slack, PagerDuty, webhooks). Implémenter les alertes multi-fenêtre basées sur le burn rate définies en section 15.1.2.

**Grafana** (15.2.4) — Construire des dashboards opérationnels et de reporting, utiliser les panneaux adaptés à chaque type de donnée (graphiques de séries temporelles, jauges, tableaux, heatmaps), configurer les data sources, les variables de template, les annotations, et les liens de corrélation vers Loki et Tempo. Exploiter les dashboards communautaires et les adapter au contexte.

**Node Exporter et métriques système Debian** (15.2.5) — Installer et configurer node_exporter sur un nœud Debian, comprendre les collecteurs activés par défaut et ceux à activer selon les besoins, interpréter les métriques système essentielles (CPU, mémoire, disque, réseau, filesystem), et construire des dashboards et des alertes pour le monitoring infrastructure des nœuds Debian.

---

## Ce que couvre cette section

Les sous-sections suivantes détaillent chaque composant de la chaîne métriques-alerting :

- **15.2.1 — Prometheus : architecture et installation sur Debian/K8s** : architecture interne, installation binaire sur Debian avec configuration systemd, déploiement sur Kubernetes avec l'opérateur Prometheus, configuration du scrape et de la service discovery, haute disponibilité et stockage long terme.

- **15.2.2 — PromQL et métriques custom** : syntaxe et sémantique du langage de requête, fonctions essentielles, écriture de recording rules pour les SLI, instrumentation d'applications pour l'exposition de métriques custom.

- **15.2.3 — AlertManager : règles et routing** : architecture d'AlertManager, configuration du routing et des receivers, groupement et déduplication, silencing et inhibition, implémentation des alertes burn rate multi-fenêtre.

- **15.2.4 — Grafana : dashboards et visualisation** : installation et configuration, construction de dashboards, variables de template, annotations, corrélation avec les autres piliers, dashboards communautaires.

- **15.2.5 — Node Exporter et métriques système Debian** : installation et configuration sur Debian, collecteurs et métriques exposées, interprétation des métriques système, dashboards et alertes pour le monitoring des nœuds.

---

*Prérequis : Section 15.1 complète (Les trois piliers de l'observabilité). Connaissance de l'administration système Debian (modules 3 et 7), de systemd (module 3.4), et des bases de Kubernetes (module 11). Pour le déploiement Kubernetes de Prometheus, une familiarité avec Helm (module 12.3.2) et les CRD (module 12.3.4) est utile.*

⏭️ [Prometheus : architecture et installation sur Debian/K8s](/module-15-observabilite-monitoring/02.1-prometheus-architecture.md)
