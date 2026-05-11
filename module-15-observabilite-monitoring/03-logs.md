🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 15.3 Logs

## Introduction

La section 15.2 a couvert en profondeur le premier pilier de l'observabilité — les métriques — avec Prometheus, PromQL, AlertManager, Grafana et node_exporter. Cette section aborde le deuxième pilier : les **logs**.

Les métriques répondent à la question « que se passe-t-il ? » avec des valeurs numériques agrégées. Les logs répondent à la question « pourquoi cela se passe-t-il ? » avec le contexte textuel de chaque événement individuel. Quand une alerte Prometheus se déclenche pour signaler un taux d'erreurs anormal sur un service, ce sont les logs de ce service qui révèlent la cause : une connexion refusée à la base de données, un certificat expiré, une requête malformée, un timeout sur un appel externe. Sans logs centralisés et interrogeables, le diagnostic reste aveugle.

La section 15.1.1 a posé les fondamentaux des logs : logs structurés vs non structurés, niveaux de sévérité, le rôle de journald sur Debian, et les bonnes pratiques de logging. Cette section passe à la mise en œuvre concrète : comment **centraliser**, **stocker**, **indexer** et **exploiter** les logs à l'échelle d'une infrastructure Debian et Kubernetes.

---

## Le problème de la centralisation

### Pourquoi centraliser

Sur un serveur Debian isolé, les logs sont consultables localement via `journalctl` ou en lisant les fichiers sous `/var/log/`. Cette approche fonctionne tant que l'infrastructure se résume à quelques machines bien identifiées. Mais dès que l'environnement grandit — plusieurs serveurs Debian, un cluster Kubernetes avec des dizaines de pods éphémères — la consultation locale des logs devient impraticable pour plusieurs raisons.

**La dispersion.** Les logs d'une même requête utilisateur peuvent être répartis sur 5 serveurs et 12 conteneurs différents. Diagnostiquer un incident nécessite de se connecter successivement à chaque machine, de chercher les logs pertinents avec des outils différents (`journalctl` sur un nœud Debian, `kubectl logs` pour un pod Kubernetes, `docker logs` pour un conteneur isolé), et de corréler mentalement les horodatages.

**L'éphémérité.** Sur Kubernetes, les logs d'un pod disparaissent quand le pod est supprimé ou redémarré. Un pod en CrashLoopBackOff qui redémarre toutes les 30 secondes ne conserve que les logs de son dernier cycle de vie. Les logs des cycles précédents — qui contiennent potentiellement la cause du crash — sont perdus. Sur un serveur Debian, la rotation des logs (`logrotate`) peut supprimer les fichiers pertinents si la rétention est trop courte.

**Le volume.** `grep` sur un fichier de 50 Go est lent. Chercher un pattern dans les logs de 30 serveurs simultanément est fastidieux avec des outils en ligne de commande. La recherche full-text avec filtrage par service, par niveau de sévérité, par plage temporelle et par champ structuré nécessite un système d'indexation dédié.

**La corrélation.** La navigation entre les piliers d'observabilité (section 15.1.1) — passer d'une métrique Prometheus à un log, puis du log à une trace — exige que les logs soient accessibles depuis la même interface que les métriques et les traces. Un log isolé sur un serveur Debian n'est pas corrélable avec un exemplar Prometheus ou un trace ID OpenTelemetry.

**La conformité.** Les exigences réglementaires (RGPD, PCI-DSS, ISO 27001 — section 15.1.3) imposent la conservation des logs d'audit pendant des durées définies, dans un stockage dont l'intégrité est garantie. Les logs stockés localement sur chaque serveur ne satisfont pas ces exigences : ils peuvent être modifiés, supprimés, ou perdus en cas de panne matérielle.

### L'architecture de centralisation

Toute solution de centralisation des logs suit un schéma en trois étapes :

```
┌───────────────────────────────────────────────────────────────┐
│                     SOURCES DE LOGS                           │
│                                                               │
│  Serveurs Debian         Cluster Kubernetes        Services   │
│  ┌──────────────┐       ┌──────────────────┐      externes    │
│  │ journald     │       │ stdout/stderr    │      ┌────────┐  │
│  │ /var/log/*   │       │ des conteneurs   │      │ syslog │  │
│  │ applications │       │ composants K8s   │      │ agents │  │
│  └──────┬───────┘       └────────┬─────────┘      └───┬────┘  │
│         │                        │                    │       │
└─────────┼────────────────────────┼────────────────────┼───────┘
          │                        │                    │
          ▼                        ▼                    ▼
┌───────────────────────────────────────────────────────────────┐
│                   COLLECTE ET TRANSPORT                       │
│                                                               │
│  Agents déployés sur chaque nœud (DaemonSet / service systemd)│
│                                                               │
│  ┌─────────────┐  ┌─────────────┐   ┌───────────────────────┐ │
│  │ Grafana     │  │  Fluent Bit │   │  OpenTelemetry        │ │
│  │ Alloy       │  │  (→ multi)  │   │  Collector (→ multi)  │ │
│  │ (→ Loki)    │  │             │   │                       │ │
│  └──────┬──────┘  └──────┬──────┘   └───────────┬───────────┘ │
│         │                │                      │             │
└─────────┼────────────────┼──────────────────────┼─────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌───────────────────────────────────────────────────────────────┐
│               STOCKAGE ET INDEXATION                          │
│                                                               │
│  ┌────────────────────┐    ┌──────────────────────────────┐   │
│  │    Grafana Loki    │    │        ELK Stack             │   │
│  │  (indexation labels│    │  Elasticsearch (full-text)   │   │
│  │   stockage objet)  │    │  Logstash (transformation)   │   │
│  └─────────┬──────────┘    └──────────────┬───────────────┘   │
│            │                              │                   │
└────────────┼──────────────────────────────┼───────────────────┘
             │                              │
             ▼                              ▼
┌───────────────────────────────────────────────────────────────┐
│                    EXPLOITATION                               │
│                                                               │
│            Grafana              Kibana                        │
│         (Explore, dashboards,   (Discover, dashboards,        │
│          corrélation            visualisation)                │
│          métriques/traces)                                    │
└───────────────────────────────────────────────────────────────┘
```

Chaque étape — collecte, stockage, exploitation — offre des choix architecturaux qui impactent le coût, les performances et les fonctionnalités. Les sous-sections qui suivent détaillent les deux approches dominantes.

---

## Les deux grandes approches

Le paysage du stockage et de l'indexation des logs en 2026 est dominé par deux approches philosophiquement différentes, chacune avec ses forces et ses compromis.

### Approche 1 : Indexation full-text (ELK Stack)

La stack ELK — **Elasticsearch**, **Logstash**, **Kibana** — est l'approche historique et la plus riche fonctionnellement. Elasticsearch indexe le contenu complet de chaque ligne de log, permettant des recherches full-text arbitraires avec une latence faible. Logstash (ou ses alternatives plus légères comme Filebeat et Fluent Bit) collecte, transforme et achemine les logs. Kibana fournit une interface d'exploration et de visualisation puissante.

Les forces de cette approche résident dans la puissance de recherche : on peut chercher n'importe quel mot, n'importe quelle expression dans le corps des logs sans avoir défini de champs à l'avance. Les capacités analytiques sont riches : agrégation, faceting, visualisation de tendances dans les logs. L'écosystème est mature avec une communauté large et un support commercial (Elastic).

Le coût est le principal inconvénient. L'indexation full-text est gourmande en CPU, en mémoire et en stockage. Elasticsearch nécessite des ressources significatives pour fonctionner correctement : un cluster de production minimal exige 3 nœuds avec 16 à 32 Go de RAM chacun. Le volume de stockage est typiquement 1,5 à 2 fois la taille des logs bruts (l'index inversé ajoute un surcoût). La complexité opérationnelle est également notable : la gestion d'un cluster Elasticsearch (sharding, réplication, dimensionnement des heaps JVM, gestion des index lifecycle policies) est un domaine d'expertise en soi.

### Approche 2 : Indexation par labels (Loki)

Grafana **Loki** est une approche plus récente, conçue explicitement pour être le « Prometheus des logs ». Là où Elasticsearch indexe le contenu complet des logs, Loki n'indexe que les **labels** (métadonnées : nom du service, namespace, nœud, niveau de sévérité) et stocke le contenu des logs sous forme compressée dans un stockage objet, sans indexation full-text.

Le résultat est un système radicalement plus économique en ressources. Loki peut fonctionner sur un seul nœud Debian modeste pour des volumes significatifs, et son stockage repose sur un backend objet (MinIO sur Debian, S3 en cloud) dont le coût par Go est très faible. L'ingestion est rapide car il n'y a pas d'indexation lourde à chaque ligne de log.

Le compromis est la recherche. Sans indexation full-text, les recherches dans le contenu des logs sont des scans séquentiels filtrés par labels. Chercher un mot spécifique dans les logs d'un service sur les dernières 24 heures est rapide (le volume est limité par le filtre de labels). Chercher le même mot dans les logs de tous les services sur les 30 derniers jours est lent (scan d'un volume important). L'approche Loki fonctionne bien quand l'opérateur sait quel service l'intéresse (filtrage par labels d'abord, puis recherche dans le contenu). Elle fonctionne moins bien pour les recherches exploratoires larges sans filtre préalable.

L'intégration native avec Grafana est l'autre force majeure de Loki. Les logs Loki apparaissent directement dans Grafana Explore, aux côtés des métriques Prometheus et des traces Tempo. La corrélation entre piliers (section 15.2.4) — exemplars, derived fields, trace-to-logs — est transparente dans l'écosystème Grafana, alors qu'elle nécessite une intégration plus complexe avec Kibana.

### Critères de choix

Le choix entre ELK et Loki dépend de plusieurs facteurs :

**Volume de logs.** Pour des volumes modérés (moins de 100 Go/jour), les deux approches sont viables. Pour des volumes importants (plusieurs centaines de Go à To/jour), le coût d'Elasticsearch devient un facteur significatif et Loki prend l'avantage économique.

**Patterns de recherche.** Si les opérateurs ont besoin de recherches full-text fréquentes sur de larges plages temporelles sans filtre préalable (cas typique : analyse de sécurité, forensics, compliance), ELK est plus adapté. Si les recherches partent toujours d'un service ou d'un pod connu et se concentrent sur une fenêtre temporelle limitée (cas typique : diagnostic d'incident opérationnel), Loki est plus adapté.

**Écosystème existant.** Si l'infrastructure utilise déjà Grafana pour les métriques Prometheus (ce qui est le cas dans cette formation), Loki s'intègre naturellement. Si Kibana est déjà déployé et maîtrisé par l'équipe, ELK évite un changement d'outil.

**Ressources d'exploitation.** Elasticsearch nécessite une expertise spécifique pour le dimensionnement, le tuning JVM, la gestion des shards et la planification des index. Loki est opérationnellement plus simple, surtout en mode monolithique (single binary).

**Besoin de SIEM.** Pour les cas d'usage de sécurité (détection d'intrusion, corrélation d'événements de sécurité — module 16.4.4), Elasticsearch offre des fonctionnalités analytiques plus riches et s'intègre avec des outils SIEM dédiés. Loki est principalement un outil opérationnel, pas un SIEM.

En pratique, de nombreuses organisations utilisent les deux : Loki pour le monitoring opérationnel quotidien (diagnostic d'incidents, débogage) et ELK pour les cas d'usage de sécurité et de compliance qui nécessitent la puissance de recherche full-text.

---

## Les agents de collecte

### Le rôle de l'agent

L'agent de collecte est le composant déployé sur chaque nœud (serveur Debian ou worker Kubernetes) qui lit les logs à la source, les enrichit de métadonnées, et les transmet au backend de stockage. Le choix de l'agent est en partie indépendant du choix du backend : Fluent Bit peut envoyer vers Loki ou Elasticsearch, et l'OTel Collector peut alimenter les deux.

### Les principaux agents

**Promtail** *(EOL depuis le 2 mars 2026)*. L'agent historique de Loki, développé par Grafana Labs. Conçu spécifiquement pour alimenter Loki, il a longtemps été le choix par défaut : découverte automatique des logs de conteneurs Kubernetes, lecture de journald sur Debian, pipeline de transformation (parsing, filtrage, enrichissement de labels). **Promtail a atteint sa fin de vie le 2 mars 2026** : plus de nouvelles fonctionnalités, plus de correctifs de sécurité. Les déploiements existants doivent être migrés vers Grafana Alloy via la commande `alloy convert --source-format=promtail`.

**Grafana Alloy** *(remplaçant officiel)*. Le collecteur unifié de Grafana Labs, basé sur OpenTelemetry Collector, qui rassemble la collecte de métriques, de logs et de traces dans un seul binaire (mentionné en section 15.1.3). Successeur officiel de Promtail et de Grafana Agent, Alloy est désormais le choix recommandé pour toute nouvelle installation Loki. Il offre un langage de configuration plus flexible (River) et la même couverture fonctionnelle que Promtail, plus le support unifié des trois piliers.

**Fluent Bit.** Un collecteur léger et performant, écrit en C, qui supporte un grand nombre de sources d'entrée (fichiers, journald, syslog, TCP, HTTP) et de destinations de sortie (Elasticsearch, Loki, S3, Kafka, et des dizaines d'autres). Son empreinte mémoire minimale (quelques Mo) en fait un choix privilégié pour les nœuds à ressources contraintes et pour les environnements qui alimentent plusieurs backends simultanément.

**Filebeat.** L'agent léger d'Elastic, conçu pour alimenter Elasticsearch (directement ou via Logstash). Il inclut des modules préconfigurés pour les logs de services courants (Nginx, Apache, MySQL, PostgreSQL, système Debian), avec des parsers et des dashboards Kibana associés. Filebeat est le choix naturel quand ELK est le backend principal.

**Logstash.** Plus qu'un agent de collecte, Logstash est un pipeline de transformation complet. Il lit les logs depuis de multiples sources, les parse, les enrichit et les route vers une ou plusieurs destinations. Logstash est plus gourmand en ressources que Fluent Bit ou Filebeat (il tourne sur la JVM) mais offre une flexibilité de transformation supérieure. Dans les architectures modernes, Logstash est souvent positionné comme un concentrateur central plutôt que comme un agent sur chaque nœud : Filebeat ou Fluent Bit collectent sur les nœuds et envoient vers Logstash qui transforme et achemine.

**OpenTelemetry Collector.** Le collecteur du projet OpenTelemetry supporte la collecte de logs en complément des métriques et des traces. Son avantage est l'unification des trois piliers sous un seul agent. La spécification OTel Logs est stable et le SDK Java logs l'est également ; les autres SDK rattrapent (Go en Beta, Python et JavaScript/Node.js en Development en mai 2026 — cf. section 15.1.1 § 4.5). Côté Collector, les receivers `filelog`, `journald` et `otlp` pour les logs sont stables et largement utilisés en production. Pour les organisations qui investissent dans OpenTelemetry comme couche d'instrumentation standard, l'OTel Collector est désormais un choix pertinent pour la collecte de logs.

### Sources de logs sur Debian

Sur un serveur Debian, les sources de logs que l'agent doit collecter sont :

**journald.** Le journal systemd est la source principale pour tous les services gérés par systemd. Il contient les logs du noyau, des services système, et des applications qui écrivent sur stdout/stderr via leurs unités systemd. L'accès se fait soit via l'API native de journald (utilisée par Grafana Alloy, Fluent Bit, l'OTel Collector et historiquement par Promtail — EOL depuis mars 2026), soit via le fichier binaire du journal (`/var/log/journal/`).

**Fichiers de logs classiques.** Certains services écrivent directement dans des fichiers sous `/var/log/` plutôt que via journald : logs d'accès Nginx (`/var/log/nginx/access.log`), logs PostgreSQL (`/var/log/postgresql/`), logs applicatifs spécifiques. L'agent surveille ces fichiers (tail) et les envoie au backend.

**Logs de conteneurs (Kubernetes).** Sur les nœuds workers, le runtime de conteneurs (containerd) redirige stdout/stderr de chaque conteneur vers des fichiers sous `/var/log/pods/` et `/var/log/containers/`. L'agent, déployé en DaemonSet, lit ces fichiers et les enrichit avec les métadonnées Kubernetes (nom du pod, namespace, labels) via l'API Kubernetes.

**Syslog distant.** Les équipements réseau (switches, routeurs, pare-feux) et certains appliances envoient leurs logs via le protocole syslog. Un agent peut écouter sur un port UDP/TCP syslog et intégrer ces logs dans le pipeline de centralisation.

---

## Structuration et enrichissement

### Le pipeline de transformation

Entre la lecture brute des logs et leur stockage dans le backend, l'agent applique un pipeline de transformation qui inclut typiquement :

**Parsing.** Extraction de champs structurés à partir de logs non structurés. Un log d'accès Nginx au format combined est parsé pour extraire l'adresse IP, la méthode HTTP, l'URL, le code de statut, la taille de la réponse et le temps de traitement. Ce parsing transforme une ligne de texte opaque en un ensemble de champs interrogeables.

**Enrichissement.** Ajout de métadonnées contextuelles non présentes dans le log brut. Sur Kubernetes, l'enrichissement ajoute le nom du pod, le namespace, les labels Kubernetes, le nom du nœud. Sur un serveur Debian, l'enrichissement peut ajouter le nom du datacenter, le rôle du serveur, la version de l'application.

**Filtrage.** Suppression des logs non pertinents avant l'envoi au backend. Les health checks Kubernetes (`GET /healthz`), les logs de DEBUG en production, les logs de services non critiques peuvent être filtrés à la source pour réduire le volume et les coûts de stockage.

**Réécriture.** Anonymisation des données sensibles (adresses IP, tokens, identifiants utilisateur), normalisation des formats de timestamp, ajout ou suppression de labels.

**Routage.** Envoi de différents types de logs vers différentes destinations. Les logs d'audit peuvent être envoyés vers un stockage long terme, les logs applicatifs vers Loki, et les logs de sécurité vers un SIEM.

### L'importance du format structuré

La section 15.1.1 a établi que le format JSON structuré est le standard recommandé pour les logs applicatifs. Dans le contexte de la centralisation, ce format prend encore plus de valeur : un log structuré ne nécessite pas de parsing heuristique par l'agent, les champs sont directement utilisables comme labels (dans Loki) ou comme champs indexés (dans Elasticsearch), et la corrélation via le trace ID est triviale quand c'est un champ JSON explicite.

Pour les services système Debian qui ne produisent pas de JSON nativement, les agents de collecte fournissent des parsers préconfigurés. Grafana Alloy, Fluent Bit et l'OTel Collector incluent des stages de parsing pour les formats courants : combined log format (Apache/Nginx), syslog, logs PostgreSQL, logs kernel. Ces parsers transforment les logs non structurés en représentation structurée dans le pipeline, avant l'envoi au backend.

---

## Ce que couvre cette section

Les sous-sections suivantes détaillent chaque approche et ses composants spécifiques :

- **15.3.1 — ELK Stack sur Debian (Elasticsearch, Logstash, Kibana)** : architecture d'un cluster Elasticsearch sur nœuds Debian, installation et configuration de chaque composant, collecte avec Filebeat, recherche et visualisation dans Kibana, gestion des index et rétention.

- **15.3.2 — Alternatives légères (Loki + Grafana Alloy / Fluent Bit, Promtail EOL)** : architecture de Loki, installation sur Debian et Kubernetes, collecte avec Grafana Alloy ou Fluent Bit (Promtail étant EOL depuis le 2 mars 2026), le langage LogQL, intégration avec Grafana, et comparaison avec ELK.

- **15.3.3 — Agrégation de logs multi-cluster** : stratégies pour centraliser les logs de plusieurs clusters Kubernetes et de nœuds Debian distribués géographiquement, topologies de collecte, et gestion des volumes à grande échelle.

- **15.3.4 — Intégration avec journald Debian** : exploitation avancée de journald comme source de logs, configuration de la rétention et du stockage, collecte par les agents, et complémentarité avec les solutions de centralisation.

---

*Prérequis : Section 15.1.1 (Métriques, logs, traces — concepts et complémentarité), en particulier la partie sur les logs. Section 15.2.4 (Grafana) pour les mécanismes de corrélation. Connaissance de journald (module 3.4.4) et des services Debian (modules 7 et 8).*

⏭️ [ELK Stack sur Debian (Elasticsearch, Logstash, Kibana)](/module-15-observabilite-monitoring/03.1-elk-stack-debian.md)
