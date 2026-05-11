🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 15.4 Tracing distribué

## Introduction

Les sections 15.2 et 15.3 ont couvert les deux premiers piliers de l'observabilité : les métriques (Prometheus, PromQL, AlertManager, Grafana, node_exporter) et les logs (ELK, Loki, Grafana Alloy, Fluent Bit, journald). Cette section aborde le troisième et dernier pilier : le **tracing distribué**.

Les métriques indiquent *qu'un problème existe* (le taux d'erreurs augmente, la latence se dégrade). Les logs expliquent *pourquoi* (un message d'erreur, un timeout, une exception). Les traces montrent *où exactement* dans la chaîne d'appels le problème se situe — quel service, quelle opération, quelle dépendance est responsable du ralentissement ou de l'erreur observée.

Dans une architecture monolithique sur un serveur Debian unique, le tracing distribué est rarement nécessaire : une stack trace dans les logs suffit à localiser le problème. Mais dès que l'architecture se distribue — microservices sur Kubernetes, services répartis sur plusieurs nœuds, appels à des bases de données et des services externes — les stack traces locales ne montrent plus qu'un fragment du parcours de la requête. Le tracing distribué reconstitue le **tableau complet**, du point d'entrée de la requête utilisateur jusqu'à la réponse finale, en traversant tous les services intermédiaires.

---

## Le troisième pilier en contexte

### Positionnement dans l'architecture d'observabilité

La section 15.1.1 a introduit les traces distribuées conceptuellement : le modèle trace/span, la propagation du contexte, l'échantillonnage. La section 15.1.3 a positionné le tracing dans la stratégie d'observabilité globale, au niveau 3 de la maturité progressive. Cette section entre dans l'implémentation concrète.

Le tracing distribué est le pilier le plus récent et celui dont le déploiement est le plus progressif. Contrairement aux métriques (où node_exporter et Prometheus fournissent immédiatement une couverture infrastructure) et aux logs (où journald et un agent de collecte centralisent immédiatement les données existantes), le tracing nécessite une **instrumentation active** des applications. Chaque service doit intégrer un SDK ou un agent qui crée les spans, propage le contexte entre les appels, et exporte les données vers un backend de traces. Cette exigence d'instrumentation est la raison pour laquelle le tracing est typiquement déployé après les métriques et les logs.

### Quand le tracing devient indispensable

Le tracing distribué prend toute sa valeur dans des scénarios spécifiques que les deux premiers piliers ne couvrent pas efficacement :

**Diagnostic de latence dans les architectures microservices.** Une requête qui traverse 8 services avant de retourner une réponse peut présenter une latence de 2 secondes. Les métriques Prometheus montrent que la latence globale est élevée, mais ne révèlent pas lequel des 8 services contribue à cette latence. Les logs de chaque service montrent leur traitement local mais pas le temps d'attente entre les appels. Seule la trace — avec ses spans horodatés pour chaque service et chaque opération — permet de visualiser immédiatement que 1,5 seconde sur les 2 sont passées dans un appel à la base de données du service inventory.

**Compréhension des dépendances.** Dans un cluster Kubernetes avec des dizaines de services, la cartographie des dépendances réelles (quel service appelle quel autre service, à quelle fréquence, avec quel taux d'erreurs) est difficile à maintenir manuellement. Les traces, agrégées sur une période, fournissent automatiquement une **carte de services** (service map) qui reflète les communications réelles, pas celles documentées (qui sont souvent obsolètes).

**Corrélation cross-service.** Un utilisateur signale un comportement anormal. Le request ID ou trace ID de sa requête permet de retrouver l'ensemble des opérations effectuées dans tous les services, de reconstruire la séquence d'événements, et d'identifier la cause racine — même si le symptôme (une erreur dans le service A) et la cause (un timeout dans le service D) sont séparés par plusieurs couches.

**Analyse d'impact des changements.** Après un déploiement d'une nouvelle version d'un service, les traces permettent de comparer la latence par span entre l'ancienne et la nouvelle version, identifiant les régressions de performance à un niveau de granularité impossible avec les métriques seules.

---

## L'écosystème du tracing en 2026

### Convergence vers OpenTelemetry

L'écosystème du tracing distribué a connu une convergence significative ces dernières années. Historiquement fragmenté entre des solutions concurrentes (OpenTracing, OpenCensus, Jaeger client libraries, Zipkin), il s'est unifié autour de **OpenTelemetry** (OTel) — le projet qui standardise l'instrumentation, la collecte et l'export des trois piliers de l'observabilité.

En 2026, OpenTelemetry est le standard de facto pour l'instrumentation du tracing. Les SDK OTel **traces et métriques** sont disponibles et stables pour tous les langages majeurs (Go, Java, Python, Node.js, .NET, Rust, C++, Ruby, PHP) ; le SDK **logs** suit avec un calendrier propre (Java stable, Go en Beta, Python/JS en Development en mai 2026 — cf. section 15.1.1 § 4.5). Le protocole OTLP (OpenTelemetry Protocol) est supporté nativement par tous les backends de traces. Les auto-instrumentation agents OTel capturent automatiquement les spans pour les frameworks et bibliothèques les plus courants sans modification du code applicatif.

Cette convergence simplifie considérablement les choix architecturaux : on instrumente avec OTel, on collecte avec l'OTel Collector, et on choisit le backend de stockage et de visualisation indépendamment.

### Backends de traces

Le choix du backend de stockage et de visualisation des traces est découplé de l'instrumentation grâce à OTel. Les principales options pour un environnement Debian et Kubernetes sont :

**Grafana Tempo.** Le backend de traces de l'écosystème Grafana. Conçu avec la même philosophie que Loki (stockage objet, pas d'indexation coûteuse), Tempo offre un coût de stockage très faible et une intégration native avec Grafana pour la visualisation et la corrélation avec Prometheus et Loki. Les traces sont stockées dans MinIO/S3 et recherchées par trace ID ou via les métriques dérivées. C'est le backend recommandé pour les environnements qui utilisent déjà la stack Grafana (Prometheus + Loki + Grafana).

**Jaeger.** Le backend de traces historique de l'écosystème CNCF. Développé par Uber et donné à la CNCF, Jaeger offre une interface utilisateur dédiée pour la recherche et la visualisation de traces, avec des fonctionnalités d'analyse avancées (comparaison de traces, détection d'anomalies). Jaeger peut utiliser Elasticsearch, Cassandra ou un stockage en mémoire comme backend. Il est disponible en mode all-in-one (un seul binaire pour le développement) ou en mode distribué (composants séparés pour la production). Jaeger est le choix historique et reste pertinent pour les équipes qui préfèrent une interface dédiée au tracing.

**Zipkin.** Le plus ancien des backends de tracing open source, créé par Twitter. Zipkin reste utilisé mais son écosystème est moins dynamique que Jaeger et Tempo. Il est compatible avec OTel via l'exporteur Zipkin de l'OTel Collector.

**Solutions commerciales.** Datadog, New Relic, Honeycomb, Lightstep et d'autres proposent des backends de tracing managés. Ils sortent du périmètre de cette formation centrée sur les solutions auto-hébergées sur Debian, mais l'instrumentation OTel est compatible avec tous ces backends.

### Le rôle de l'OpenTelemetry Collector

L'OpenTelemetry Collector est le composant central du pipeline de tracing. Déployé en DaemonSet sur chaque nœud Kubernetes ou en service systemd sur chaque nœud Debian, il joue le rôle d'intermédiaire entre les SDK applicatifs et le backend de traces :

```
Applications                    OTel Collector              Backend
(SDK OTel)                      (par nœud)

┌─────────────┐                ┌──────────────────┐        ┌──────────┐
│ Service A   │──── OTLP ─────►│                  │        │          │
│ (Go)        │                │  Receivers       │        │  Tempo   │
└─────────────┘                │  (otlp, jaeger,  │        │  ou      │
┌─────────────┐                │   zipkin)        │──────► │  Jaeger  │
│ Service B   │──── OTLP ─────►│                  │  OTLP  │          │
│ (Python)    │                │  Processors      │        └──────────┘
└─────────────┘                │  (batch, filter, │
┌─────────────┐                │   tail_sampling, │        ┌──────────┐
│ Service C   │──── OTLP ─────►│   k8sattributes) │───────►│Prometheus│
│ (Java)      │                │                  │ remote │(métriques│
└─────────────┘                │  Exporters       │ write  │ dérivées)│
                               │  (otlp, prom,    │        └──────────┘
                               │   loki)          │
                               └──────────────────┘
```

Le Collector n'est pas un simple proxy. Il exécute des **processors** qui enrichissent, filtrent et échantillonnent les traces avant de les transmettre au backend, ainsi que des **connectors** qui transforment un type de signal en un autre :

**`batch`** *(processor)* : accumule les spans en lots pour réduire le nombre de requêtes réseau vers le backend.

**`k8sattributes`** *(processor)* : enrichit chaque span avec les métadonnées Kubernetes du pod émetteur (namespace, pod name, deployment, node). Essentiel sur Kubernetes car il ajoute le contexte d'orchestration que le SDK applicatif ne connaît pas.

**`tail_sampling`** *(processor)* : applique un échantillonnage de queue (section 15.1.1) qui conserve 100 % des traces en erreur ou à latence élevée tout en échantillonnant les traces nominales. Nécessite un buffer de quelques secondes pour reconstituer la trace avant de décider de la conserver ou non.

**`filter`** *(processor)* : supprime les spans ou les traces correspondant à des critères définis (health checks, requêtes internes, spans de monitoring).

**`spanmetrics`** *(connector)* : génère des métriques RED (Rate, Errors, Duration) à partir des spans, exportables vers Prometheus. Cela fournit des métriques de service sans instrumentation Prometheus supplémentaire — les métriques sont dérivées automatiquement du tracing. Depuis la v0.84 du Collector, c'est un **connector** (et non plus un processor) : il sort de la pipeline traces et entre dans la pipeline metrics.

---

## Le tracing dans le parcours de la formation

### Lien avec les modules précédents

Le tracing distribué s'appuie sur les compétences construites tout au long de la formation :

**Module 10 (Conteneurs)** : le tracing dans les conteneurs Docker et Podman implique la configuration des variables d'environnement OTel et l'exposition des ports OTLP.

**Module 11 (Kubernetes — Fondamentaux)** : le déploiement de l'OTel Collector en DaemonSet, les annotations de pods pour l'auto-instrumentation, et les Services pour l'exposition des endpoints de collecte.

**Module 12 (Kubernetes — Production)** : le RBAC pour l'accès de l'OTel Collector à l'API Kubernetes (processor `k8sattributes`), les resource quotas pour le Collector, et les déploiements canary observés via les traces.

**Module 14 (CI/CD et GitOps)** : l'intégration du tracing dans les pipelines CI/CD pour vérifier l'instrumentation, et l'injection d'annotations de déploiement corrélées avec les traces.

**Module 17 (Service Mesh)** : Istio et Linkerd génèrent automatiquement des spans pour le trafic réseau entre services, complémentant l'instrumentation applicative. Le service mesh fournit le tracing « infrastructure » tandis que l'instrumentation OTel fournit le tracing « applicatif ».

### Architecture cible

L'architecture de tracing recommandée pour cette formation s'intègre dans la stack d'observabilité globale définie en section 15.1.3 :

```
┌─────────────────────────────────────────────────────────────────┐
│                         Grafana                                 │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐             │
│  │ Prometheus │    │   Loki     │    │   Tempo    │             │
│  │ (métriques)│◄──►│  (logs)    │◄──►│  (traces)  │             │
│  └─────▲──────┘    └─────▲──────┘    └─────▲──────┘             │
│        │                 │                 │                    │
│   exemplars         derived fields    trace-to-logs             │
│   spanmetrics        trace_id         trace-to-metrics          │
└────────┼─────────────────┼─────────────────┼────────────────────┘
         │                 │                 │
┌────────┼─────────────────┼─────────────────┼────────────────────┐
│        │    OTel Collector (DaemonSet / systemd)                │
│        │                 │                 │                    │
│   ┌────┴────┐       ┌────┴────┐       ┌────┴────┐               │
│   │ Prom    │       │ Alloy / │       │  OTLP   │               │
│   │ scrape  │       │FluentBit│       │receiver │               │
│   └─────────┘       └─────────┘       └────▲────┘               │
│                                            │                    │
│         Applications instrumentées (SDK OTel)                   │
└─────────────────────────────────────────────────────────────────┘
```

Les trois backends (Prometheus, Loki, Tempo) sont reliés dans Grafana par les mécanismes de corrélation couverts en section 15.2.4 : exemplars (métriques → traces), derived fields (logs → traces), trace-to-logs et trace-to-metrics (traces → logs et métriques). Le connector `spanmetrics` de l'OTel Collector génère des métriques RED depuis les traces, alimentant Prometheus sans instrumentation supplémentaire.

---

## Ce que couvre cette section

Les sous-sections suivantes détaillent chaque aspect du tracing distribué :

- **15.4.1 — Concepts du distributed tracing** : approfondissement du modèle de données (traces, spans, contexte), les standards de propagation (W3C Trace Context, B3), les stratégies d'échantillonnage en détail, et les patterns d'instrumentation (manuelle, automatique, hybride).

- **15.4.2 — Jaeger : architecture et utilisation** : architecture de Jaeger (agent, collector, query, storage), installation sur Debian et Kubernetes, l'interface utilisateur de Jaeger pour la recherche et l'analyse de traces, et les cas d'usage de Jaeger comme backend autonome ou complémentaire à Tempo.

- **15.4.3 — OpenTelemetry : standard unifié (métriques, logs, traces)** : architecture du SDK et du Collector, instrumentation d'applications en Go et Python, auto-instrumentation sur Kubernetes, configuration du Collector (receivers, processors, exporters), et intégration avec Tempo et Grafana pour la corrélation complète entre les trois piliers.

---

*Prérequis : Section 15.1.1 (Métriques, logs, traces — concepts et complémentarité) pour les fondamentaux du tracing. Sections 15.2 et 15.3 complètes pour les deux premiers piliers. Section 15.2.4 (Grafana) pour les mécanismes de corrélation. Connaissance de Kubernetes (modules 11-12) pour le déploiement de l'OTel Collector. Familiarité avec au moins un langage de programmation (Go, Python — module 5.3) pour l'instrumentation.*

⏭️ [Concepts du distributed tracing](/module-15-observabilite-monitoring/04.1-concepts-tracing.md)
