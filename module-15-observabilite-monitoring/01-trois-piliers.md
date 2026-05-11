🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 15.1 Les trois piliers de l'observabilité

## Introduction

L'observabilité est un concept emprunté à la théorie du contrôle, où il désigne la capacité à inférer l'état interne d'un système à partir de ses sorties externes. Appliqué aux systèmes informatiques, il traduit notre aptitude à comprendre **ce qui se passe réellement** à l'intérieur d'une infrastructure — serveurs Debian, conteneurs, clusters Kubernetes — sans avoir à se connecter manuellement à chaque composant ni à reproduire un incident pour le diagnostiquer.

L'observabilité ne se résume pas au monitoring. Le monitoring répond à la question « est-ce que ça fonctionne ? » en vérifiant des seuils prédéfinis. L'observabilité va plus loin : elle permet de répondre à des questions **qu'on n'avait pas anticipées** au moment de la conception. Face à un comportement inattendu — une latence anormale, une dégradation progressive, un incident en cascade — un système observable fournit suffisamment de données pour qu'un opérateur puisse formuler des hypothèses, les tester et converger vers la cause racine, le tout sans modifier le code ni redéployer d'instrumentation.

---

## Du monitoring classique à l'observabilité

### Les limites du monitoring traditionnel

Pendant des années, l'approche dominante consistait à surveiller des métriques système de base — charge CPU, mémoire disponible, espace disque — et à déclencher des alertes lorsqu'un seuil était franchi. Cette approche, héritée de l'ère des serveurs monolithiques, repose sur une hypothèse implicite : l'administrateur sait **à l'avance** quels indicateurs surveiller et quels seuils sont significatifs.

Dans un environnement Debian classique avec quelques serveurs bien identifiés, cette approche fonctionne raisonnablement bien. On configure Nagios ou Zabbix (comme vu au module 3.5), on définit des checks, et on réagit aux alertes. Les pannes sont souvent localisées : un disque plein, un service tombé, une interface réseau défaillante.

Mais dès que l'infrastructure évolue vers des architectures distribuées — microservices, conteneurs orchestrés par Kubernetes, déploiements multi-nœuds — cette approche atteint ses limites pour plusieurs raisons :

**La cardinalité explose.** Là où l'on surveillait 10 serveurs Debian avec chacun une dizaine de métriques, on se retrouve avec des centaines de pods éphémères, chacun générant ses propres métriques, logs et événements. Les combinaisons possibles de dimensions (service, version, pod, nœud, namespace, endpoint) rendent impossible la création manuelle de dashboards et d'alertes pour chaque cas de figure.

**Les pannes deviennent systémiques.** Dans un système distribué, un incident se manifeste rarement par un composant unique en erreur. Une requête traverse plusieurs services, chacun pouvant contribuer partiellement à une dégradation. La latence d'un appel à la base de données PostgreSQL sur un nœud Debian peut se propager en cascade à travers toute la chaîne applicative, sans que le serveur de base de données lui-même ne déclenche la moindre alerte.

**L'éphémérité des composants.** Les conteneurs vivent quelques minutes ou quelques heures. Un pod Kubernetes redémarré par le scheduler a changé d'adresse IP, potentiellement de nœud. Les données de monitoring classique, indexées par hostname ou IP, perdent leur sens dans ce contexte.

### Le changement de paradigme

L'observabilité propose un renversement de perspective. Plutôt que de définir à l'avance ce qu'il faut surveiller (approche réactive), on instrumente le système pour qu'il **émette suffisamment de signaux** permettant d'investiguer n'importe quel comportement a posteriori (approche exploratoire).

Ce changement repose sur trois types de signaux complémentaires, communément appelés les **trois piliers de l'observabilité** :

| Pilier | Question à laquelle il répond | Exemple concret |
|--------|-------------------------------|-----------------|
| **Métriques** | *Que se passe-t-il en ce moment ? Quelle est la tendance ?* | Le taux de requêtes HTTP 5xx a augmenté de 2 % à 15 % en 10 minutes |
| **Logs** | *Pourquoi cela s'est-il produit ? Quel est le contexte précis ?* | `ERROR: connection refused to PostgreSQL on 10.0.3.12:5432 — max_connections reached` |
| **Traces** | *Comment la requête a-t-elle traversé le système ? Où est le goulot ?* | La requête `GET /api/orders` a passé 1,2 s dans le service `inventory` dont 900 ms en attente d'une connexion DB |

Aucun de ces piliers ne suffit à lui seul. Les métriques donnent une vue d'ensemble mais manquent de contexte. Les logs fournissent du détail mais sont difficiles à agréger. Les traces montrent le parcours d'une requête mais ne couvrent pas l'état global du système. C'est leur **corrélation** qui produit l'observabilité.

---

## Pourquoi l'observabilité est critique en contexte Debian + Kubernetes

Dans le parcours de cette formation, l'infrastructure a progressivement gagné en complexité : d'un serveur Debian unique (modules 1 à 8) vers des clusters Kubernetes multi-nœuds (modules 11 et 12), en passant par la conteneurisation (module 10) et l'Infrastructure as Code (module 13). À chaque étape, le nombre de composants en interaction a augmenté, et avec lui la difficulté à diagnostiquer les incidents.

### Sur un serveur Debian classique

Même sur une machine Debian isolée, l'observabilité apporte de la valeur au-delà du monitoring traditionnel. Les logs de `journald`, les métriques système exposées par `node_exporter`, et les traces applicatives permettent de comprendre des comportements subtils : pourquoi un service systemd met 30 secondes à démarrer certains matins, pourquoi la latence d'Apache augmente chaque vendredi après-midi, pourquoi un processus consomme progressivement plus de mémoire au fil des jours.

### Dans un environnement conteneurisé

Avec Docker ou Podman sur Debian, la couche d'abstraction supplémentaire rend le diagnostic plus complexe. Les logs ne sont plus dans `/var/log` mais dans les flux stdout/stderr des conteneurs. Les métriques réseau impliquent des bridges virtuels et des namespaces réseau. L'éphémérité des conteneurs impose de centraliser les données avant qu'elles ne disparaissent avec le conteneur.

### Sur Kubernetes

C'est dans un cluster Kubernetes que l'observabilité devient véritablement indispensable. Un cluster de production typique sur nœuds Debian implique des dizaines de composants en interaction : l'API Server, etcd, le scheduler, les kubelets, les contrôleurs d'Ingress, les CNI plugins, les applications elles-mêmes, les sidecars éventuels d'un service mesh. Diagnostiquer un ralentissement perçu par l'utilisateur final nécessite de corréler des données provenant de toutes ces couches.

---

## Les trois piliers en détail

### Métriques

Les métriques sont des **mesures numériques horodatées** qui représentent l'état d'un système à un instant donné. Elles sont par nature agrégables : on peut calculer des moyennes, des percentiles, des taux de variation. Leur coût de stockage est relativement faible et prévisible, ce qui permet de conserver un historique long.

Dans l'écosystème Debian et Kubernetes, Prometheus s'est imposé comme le standard de facto pour la collecte et le stockage des métriques. Son modèle de données en séries temporelles multidimensionnelles (des labels associés à chaque métrique) offre la flexibilité nécessaire pour naviguer dans la cardinalité des environnements modernes.

Les métriques sont le pilier de prédilection pour le **monitoring en temps réel et l'alerting** : elles permettent de détecter rapidement qu'un problème existe, même si elles ne suffisent pas à en identifier la cause.

### Logs

Les logs sont des **enregistrements textuels horodatés** d'événements discrets. Chaque entrée de log capture un moment précis dans la vie d'un composant : un démarrage de service, une requête reçue, une erreur rencontrée, une connexion établie ou refusée. Sur Debian, `journald` centralise déjà les logs de l'ensemble des services systemd dans un format structuré et interrogeable.

La richesse des logs réside dans leur **granularité contextuelle**. Là où une métrique indique « le taux d'erreurs a augmenté », un log précise « la connexion à la base PostgreSQL a échoué parce que le nombre maximal de connexions est atteint, pour la requête de l'utilisateur X sur l'endpoint Y ».

Le défi des logs est leur volume. Un cluster Kubernetes de taille moyenne peut générer des gigaoctets de logs par jour. Sans centralisation, structuration et indexation appropriées, cette masse de données devient inexploitable. Des outils comme la stack ELK (Elasticsearch, Logstash, Kibana) ou l'alternative plus légère Loki + Grafana Alloy permettent de transformer ce flux brut en source d'investigation efficace.

### Traces distribuées

Les traces (ou traces distribuées) suivent le **parcours d'une requête** à travers les différents services d'un système distribué. Une trace est composée de spans — des segments représentant chacun une opération dans un service donné — reliés entre eux par des identifiants de corrélation (trace ID, span ID).

C'est le pilier le plus récent et celui qui prend tout son sens dans les architectures microservices. Quand une requête HTTP de l'utilisateur traverse un API Gateway, un service d'authentification, un service métier, un cache Redis et une base de données, seule une trace distribuée permet de visualiser l'ensemble du parcours et d'identifier précisément où se situe le goulot d'étranglement.

OpenTelemetry s'est imposé comme le standard unifié pour l'instrumentation, la collecte et l'export des traces (ainsi que des métriques et des logs), tandis que Jaeger reste l'outil de visualisation et d'analyse de traces le plus répandu dans l'écosystème Kubernetes.

---

## La corrélation : le ciment de l'observabilité

La véritable puissance de l'observabilité ne réside pas dans chaque pilier pris isolément, mais dans la capacité à **naviguer entre eux** lors d'une investigation.

Un scénario typique illustre cette complémentarité. Une alerte Prometheus se déclenche : le taux d'erreurs HTTP 500 du service `orders` a dépassé le seuil de 5 % (signal métrique). L'opérateur consulte les dashboards Grafana et constate que la latence du p99 a également augmenté (confirmation métrique). Il pivote vers les logs du service `orders` dans Loki ou Kibana et identifie des messages d'erreur liés à des timeouts de connexion vers le service `inventory` (contexte log). Il sélectionne alors une trace correspondant à une requête en erreur dans Jaeger et visualise que le span du service `inventory` montre un délai de 8 secondes pour un appel à la base de données (localisation trace). En consultant les métriques de l'instance PostgreSQL concernée, il découvre que le nombre de connexions actives a atteint le maximum configuré (cause racine métrique).

Cette navigation fluide entre métriques, logs et traces — facilitée par des identifiants de corrélation partagés (trace ID, request ID, labels communs) — est ce qui distingue un système véritablement observable d'un système simplement monitoré.

---

## L'observabilité comme pratique culturelle

Au-delà des outils, l'observabilité est une **discipline d'ingénierie** qui implique des choix à chaque étape du cycle de développement et d'exploitation :

**Lors du développement** : instrumenter le code dès la conception, émettre des métriques métier pertinentes, structurer les logs, propager les contextes de trace entre services.

**Lors du déploiement** : s'assurer que les pipelines CI/CD (module 14) intègrent la vérification de l'instrumentation, que les manifestes Kubernetes incluent les annotations nécessaires pour la collecte automatique.

**Lors de l'exploitation** : définir des SLO (Service Level Objectives) qui traduisent les attentes des utilisateurs en termes mesurables, maintenir des dashboards orientés service plutôt que infrastructure, construire des runbooks qui s'appuient sur les données d'observabilité.

**Lors de la réponse aux incidents** : utiliser les données d'observabilité pour accélérer le diagnostic, documenter les investigations pour enrichir les futurs runbooks, ajuster l'instrumentation après chaque incident pour combler les angles morts découverts.

Cette dimension culturelle sera approfondie dans les sections suivantes, notamment à travers les concepts de SLO/SLI/SLA et la définition d'une stratégie d'observabilité globale.

---

## Ce que couvre cette section

Les sous-sections qui suivent détaillent chacun des aspects fondamentaux de l'observabilité :

- **15.1.1 — Métriques, logs, traces : concepts et complémentarité** : approfondissement technique de chaque pilier, formats de données, outils de collecte et de stockage, et stratégies de corrélation entre les trois.

- **15.1.2 — SLO, SLI, SLA et error budgets** : comment traduire les attentes utilisateur en objectifs mesurables, définir des indicateurs fiables, et utiliser les budgets d'erreur pour arbitrer entre vélocité de développement et fiabilité.

- **15.1.3 — Stratégie d'observabilité globale** : comment concevoir une architecture d'observabilité cohérente pour un environnement Debian + Kubernetes, du choix des outils à l'organisation des équipes, en passant par la gestion des coûts et la gouvernance des données.

---

*Prérequis recommandés : Module 3.5 (Logs et monitoring de base), Module 11 (Kubernetes — Fondamentaux), Module 12 (Kubernetes — Production). Une familiarité avec les concepts de services distribués et de conteneurisation est fortement recommandée.*

⏭️ [Métriques, logs, traces : concepts et complémentarité](/module-15-observabilite-monitoring/01.1-metriques-logs-traces.md)
