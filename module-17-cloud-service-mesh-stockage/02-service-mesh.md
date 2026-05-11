🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 17.2 Service Mesh

## Prérequis

- Architecture et concepts Kubernetes (Module 11)
- Kubernetes en production : réseau, sécurité, déploiements (Module 12)
- Réseau Kubernetes : CNI, Ingress, Services, Network Policies (Module 11, section 11.4 et Module 16, section 16.2.5)
- Observabilité : métriques, logs, traces (Module 15)
- Notions de TLS, certificats et PKI (Module 6, section 6.4.3)
- Kubernetes managé (section 17.1.5, recommandé)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Définir ce qu'est un service mesh et identifier les problèmes qu'il résout
- Comprendre l'architecture data plane / control plane propre aux service meshes
- Évaluer la pertinence d'un service mesh pour une architecture donnée
- Distinguer les approches sidecar proxy et eBPF/ambient
- Comparer Istio et Linkerd sur des critères techniques, opérationnels et organisationnels
- Anticiper les implications en termes de complexité, de performance et de coûts

---

## Introduction

### Le problème : la communication entre microservices

Tout au long de cette formation, la complexité du réseau Kubernetes a été un fil conducteur. Au Module 11 (section 11.4), vous avez étudié le modèle réseau de Kubernetes, les CNI, les Services et les Ingress Controllers. Au Module 12 (section 12.2.3), vous avez mis en place des Network Policies pour la micro-segmentation. Au Module 15, vous avez déployé des stacks d'observabilité pour comprendre ce qui se passe dans votre cluster.

Ces fondations sont solides pour des architectures simples. Mais lorsqu'une application est décomposée en dizaines, voire centaines de microservices qui communiquent entre eux via des appels réseau (HTTP, gRPC, TCP), un ensemble de problématiques transverses émerge — des problématiques qui ne relèvent pas de la logique métier de chaque service mais de l'infrastructure de communication elle-même :

**Le chiffrement des communications internes.** Dans un cluster Kubernetes, le trafic entre Pods circule en clair par défaut. Les Network Policies contrôlent qui peut parler à qui, mais elles ne chiffrent pas le contenu des échanges. Dans un environnement multi-tenant ou soumis à des contraintes réglementaires (PCI DSS, RGPD, HDS), le chiffrement mutuel TLS (mTLS) entre chaque paire de services devient une exigence. Implémenter mTLS manuellement dans chaque service — génération de certificats, rotation, vérification des chaînes de confiance — est un travail considérable et une source d'erreurs.

**La gestion du trafic.** Comment router progressivement le trafic vers une nouvelle version d'un service (canary deployment) ? Comment répartir le trafic entre deux versions en production (traffic splitting) ? Comment retenter automatiquement les requêtes échouées avec un backoff exponentiel ? Comment couper l'accès à un service défaillant avant qu'il ne provoque une cascade de pannes (circuit breaking) ? Ces comportements peuvent être implémentés dans chaque service via des bibliothèques (comme Hystrix ou Resilience4j en Java), mais cela impose un couplage entre le code métier et l'infrastructure de communication, multiplie les implémentations et les langages à maintenir, et rend impossible une politique unifiée au niveau de la plateforme.

**L'observabilité fine des communications.** Les outils de monitoring vus au Module 15 capturent les métriques au niveau des Pods et des nœuds. Mais quelle est la latence entre le service A et le service B ? Quel pourcentage des requêtes entre C et D échoue avec un code 503 ? Par où transite une requête utilisateur dans un graphe de 30 microservices ? Le tracing distribué (Module 15, section 15.4) répond partiellement à cette dernière question, mais il nécessite une instrumentation dans le code de chaque service. Obtenir ces informations de manière transparente, sans modifier le code applicatif, est un objectif fondamental.

**Le contrôle d'accès service-à-service.** Les Network Policies opèrent au niveau L3/L4 (adresses IP, ports). Elles ne peuvent pas exprimer des règles comme « le service payment peut appeler le service ledger sur l'endpoint POST /transactions, mais pas sur DELETE /transactions ». Un contrôle d'accès au niveau L7 (HTTP, gRPC), conscient de l'identité cryptographique du service appelant, nécessite une couche supplémentaire.

Chacun de ces problèmes peut être résolu individuellement par des outils dédiés. Mais la combinaison de tous ces besoins dans une architecture microservices de taille significative justifie une approche unifiée. C'est exactement ce que propose un service mesh.

### La réponse : une couche d'infrastructure réseau dédiée

Un service mesh est une couche d'infrastructure dédiée à la gestion des communications service-à-service au sein d'une architecture distribuée. Il intercepte le trafic réseau entre les services, de manière transparente pour le code applicatif, et applique un ensemble de fonctionnalités transverses : chiffrement, routage, résilience, observabilité et contrôle d'accès.

L'idée fondatrice est de **déplacer les préoccupations réseau hors du code applicatif et dans l'infrastructure**. Le développeur écrit un service qui appelle d'autres services via des requêtes HTTP ou gRPC classiques. Le service mesh intercepte ces requêtes au niveau du réseau, les chiffre, les route, les observe et les contrôle, sans que le code du service n'ait connaissance de cette couche intermédiaire.

Ce principe n'est pas nouveau en soi — les load balancers et les reverse proxies remplissent ce rôle depuis des décennies au niveau périmétrique (trafic nord-sud, entre les clients et les serveurs). L'innovation du service mesh est d'appliquer cette logique au trafic **est-ouest** (entre les services eux-mêmes), à l'échelle de chaque communication interne du cluster.

---

## Architecture d'un service mesh

### Le modèle data plane / control plane

L'architecture d'un service mesh reprend une séparation familière dans le monde Kubernetes : la distinction entre **data plane** (plan de données) et **control plane** (plan de contrôle).

Le **data plane** est constitué des proxies réseau qui interceptent le trafic applicatif. Chaque instance de service est accompagnée d'un proxy qui capture tout le trafic entrant et sortant. Ce proxy applique les politiques de routage, de sécurité et d'observabilité. Le trafic entre deux services traverse donc quatre points : le code du service A → le proxy de A → le réseau → le proxy de B → le code du service B. Les proxies du data plane sont les composants qui traitent chaque requête en temps réel — leur performance est donc critique.

Le **control plane** est le cerveau du mesh. Il reçoit la configuration (politiques de routage, règles de sécurité, paramètres d'observabilité), la traduit en instructions compréhensibles par les proxies et la distribue à chaque proxy du data plane. Il gère également l'émission et la rotation des certificats TLS utilisés pour le mTLS. Le control plane ne traite pas le trafic applicatif directement — il configure les proxies qui, eux, le traitent.

Cette séparation a une implication architecturale importante : si le control plane tombe en panne, les proxies du data plane continuent de fonctionner avec leur dernière configuration connue. Le trafic applicatif n'est pas interrompu. En revanche, les changements de configuration ne peuvent plus être distribués et les certificats ne peuvent plus être renouvelés jusqu'au rétablissement du control plane. C'est un modèle de dégradation gracieuse qui protège la disponibilité des applications.

### Le pattern sidecar

Le modèle d'implémentation historique et le plus répandu est le **pattern sidecar**. Un conteneur proxy est injecté dans chaque Pod, aux côtés du conteneur applicatif. Les deux conteneurs partagent le même réseau (via le network namespace du Pod) et le proxy est configuré (via des règles iptables ou eBPF) pour intercepter tout le trafic entrant et sortant du Pod.

L'injection du sidecar se fait généralement de manière automatique via un webhook d'admission Kubernetes (Mutating Admission Webhook). Lorsqu'un Pod est créé dans un namespace labellisé pour le mesh, le webhook modifie la définition du Pod pour y ajouter le conteneur sidecar et la configuration d'interception du trafic. Le développeur n'a pas à modifier ses Deployments — l'injection est transparente.

Le proxy sidecar le plus utilisé dans l'écosystème est **Envoy**, un proxy L4/L7 haute performance développé par Lyft et versé à la CNCF (statut Graduated). Envoy est le data plane d'Istio. Linkerd, à l'inverse, utilise son propre proxy minimaliste **linkerd2-proxy**, écrit en Rust et conçu spécifiquement pour le cas d'usage service mesh — il s'agit d'un projet distinct d'Envoy, plus léger et plus restreint fonctionnellement.

Le pattern sidecar présente un avantage fondamental : l'isolation. Chaque Pod a son propre proxy, avec sa propre configuration et ses propres certificats. L'impact d'un bug dans le proxy est limité au Pod concerné. Le déploiement et la mise à jour des proxies se font par rolling update des Pods.

En contrepartie, il a un coût en ressources : chaque sidecar consomme de la mémoire (typiquement 30 à 100 Mo par instance Envoy, selon la complexité de la configuration) et du CPU. Dans un cluster avec des milliers de Pods, ce surcoût agrégé est significatif. La latence ajoutée par le double passage à travers les proxies (émetteur et récepteur) est généralement de l'ordre de quelques millisecondes, mais elle peut devenir un facteur dans les chaînes d'appels profondes.

### L'approche ambient (sidecar-less)

Pour répondre aux limitations du pattern sidecar, une approche alternative émerge : le **mode ambient** (ou sidecar-less). Plutôt que d'injecter un proxy dans chaque Pod, le trafic est intercepté au niveau du nœud par un agent partagé. Ce modèle réduit drastiquement la consommation de ressources (un seul agent par nœud plutôt qu'un proxy par Pod) et simplifie les opérations (plus besoin de redémarrer les Pods pour mettre à jour le proxy).

Istio a introduit son **Ambient Mesh** comme alternative au mode sidecar. Il utilise un composant par nœud appelé **ztunnel** (zero-trust tunnel) pour le chiffrement L4 (mTLS) et des **waypoint proxies** optionnels (des instances Envoy dédiées, déployées par namespace) pour les fonctionnalités L7 (routage HTTP, politiques d'autorisation L7, observabilité des requêtes).

Cette architecture à deux niveaux permet de ne payer le coût du proxy L7 que pour les services qui en ont besoin, tout en bénéficiant du mTLS pour l'ensemble du mesh avec un overhead minimal.

Linkerd explore également des approches légères, bien que sa philosophie ait toujours été de minimiser l'empreinte du sidecar plutôt que de l'éliminer. Le proxy Linkerd, écrit en Rust, est déjà significativement plus léger qu'Envoy.

L'approche ambient est plus récente que le pattern sidecar et dispose d'un historique de production plus court. Istio Ambient Mesh étant GA depuis Istio 1.24 (novembre 2024), elle a maintenant accumulé plus d'un an et demi de retours d'expérience en production. Elle représente la direction vers laquelle l'écosystème évolue pour les déploiements à grande échelle, mais le mode sidecar reste majoritaire dans les déploiements existants.

### L'approche eBPF

Au-delà du pattern sidecar et de l'ambient mesh, une troisième voie émerge avec **eBPF** (extended Berkeley Packet Filter). Cilium, que vous avez rencontré au Module 16 (section 16.2.5) comme CNI et moteur de Network Policies, propose des fonctionnalités de service mesh directement dans le kernel Linux via eBPF, sans proxy applicatif.

L'avantage théorique est une latence encore plus faible (pas de passage par un proxy en espace utilisateur) et une empreinte ressource quasi nulle. La limite est que les fonctionnalités L7 avancées (routing basé sur les headers HTTP, transformation de requêtes) sont plus complexes à implémenter en eBPF et ne couvrent pas encore tout le spectre fonctionnel d'un proxy comme Envoy.

Cilium Service Mesh représente une convergence entre le CNI et le service mesh — deux couches historiquement séparées qui partagent en réalité le même domaine : la gestion du réseau dans le cluster. Cette convergence est une tendance de fond de l'écosystème Kubernetes.

---

## Les fonctionnalités clés d'un service mesh

Un service mesh fournit quatre catégories de fonctionnalités, qui seront détaillées dans la section 17.2.1 :

### Sécurité : mTLS et identité cryptographique

Le chiffrement mutuel TLS (mTLS) est souvent la fonctionnalité qui motive initialement l'adoption d'un service mesh. Le mesh génère automatiquement un certificat TLS pour chaque workload, basé sur l'identité du ServiceAccount Kubernetes. Chaque communication entre deux services est chiffrée et authentifiée mutuellement : le service A vérifie l'identité de B, et B vérifie l'identité de A. Cette identité cryptographique permet ensuite de définir des politiques d'autorisation fines (« seul le service A peut appeler le service B »).

### Gestion du trafic

Le mesh offre un contrôle fin sur le routage du trafic : répartition pondérée entre versions (canary), routage basé sur les headers (A/B testing), retries automatiques avec budget de retry, timeouts, circuit breaking et injection de fautes pour les tests de résilience. Ces fonctionnalités sont déclarées via des ressources Kubernetes (Custom Resources) et appliquées par les proxies du data plane.

### Observabilité

Le mesh collecte automatiquement des métriques (latence, taux d'erreur, volume de requêtes — les « golden signals »), des logs d'accès et des traces distribuées pour chaque communication service-à-service. Ces données sont émises par les proxies et n'exigent aucune instrumentation dans le code applicatif. Elles complètent les métriques d'infrastructure (Module 15) avec une vision au niveau de la communication applicative.

### Politiques

Le mesh permet de définir des politiques de contrôle d'accès au niveau L7 (autorisation basée sur les paths HTTP, les méthodes, les headers), de rate limiting (limitation du nombre de requêtes par seconde vers un service) et de conformité (journalisation de toutes les communications pour les audits).

---

## Quand adopter un service mesh ?

### Le service mesh n'est pas toujours nécessaire

Un service mesh ajoute une couche d'infrastructure significative : composants supplémentaires à opérer, complexité de débogage accrue (le réseau a désormais une couche intermédiaire), consommation de ressources additionnelle et courbe d'apprentissage pour les équipes. Cette complexité doit être justifiée par des besoins réels.

Un service mesh est **probablement inutile** si votre architecture comprend moins d'une dizaine de services, si les communications internes sont simples et bien comprises, si vous n'avez pas d'exigence réglementaire de chiffrement interne et si votre observabilité actuelle (Module 15) répond à vos besoins.

Un service mesh est **probablement utile** si votre architecture comprend des dizaines de services communiquant de manière complexe, si vous avez besoin de mTLS pour la conformité ou la sécurité zero-trust, si vous voulez des déploiements canary ou du traffic splitting sans modifier le code applicatif, si vous avez besoin d'une observabilité des communications L7 sans instrumentation applicative, ou si vous opérez un cluster multi-tenant où l'isolation réseau L3/L4 ne suffit pas.

### La progression recommandée

L'adoption d'un service mesh ne doit pas être un big bang. Une progression incrémentale est recommandée :

1. **Commencer par l'observabilité.** Déployer le mesh en mode permissif (pas de mTLS enforced, pas de politiques d'autorisation) et exploiter les métriques et traces qu'il génère. Cela permet de comprendre les flux de communication réels dans le cluster et de valider que le mesh n'introduit pas de régressions.

2. **Activer le mTLS.** Une fois les flux compris, activer le mTLS progressivement — d'abord en mode permissif (accepte les connexions avec ou sans TLS), puis en mode strict (refuse les connexions non-TLS).

3. **Introduire les politiques d'autorisation.** Définir des AuthorizationPolicies service par service, en commençant par les services les plus sensibles.

4. **Exploiter le traffic management.** Utiliser les canary deployments et le traffic splitting pour les déploiements à risque, une fois que l'équipe est confortable avec le mesh.

---

## Le paysage des service meshes

### Les acteurs principaux

L'écosystème des service meshes a connu une période de prolifération (2017-2021) suivie d'une consolidation. En 2026, trois projets concentrent l'essentiel des déploiements (Istio et Linkerd dominent en parts d'adoption, Cilium Service Mesh est l'entrant le plus dynamique grâce à sa convergence avec le CNI) :

**Istio** est le service mesh le plus déployé et le plus riche fonctionnellement. Initialement développé par Google, IBM et Lyft, il est devenu un projet incubating de la CNCF (Cloud Native Computing Foundation) le 30 septembre 2022 et a atteint le statut de projet diplômé (*graduated*) le 12 juillet 2023. Istio utilise Envoy comme data plane et offre le spectre fonctionnel le plus large : mTLS, traffic management avancé, observabilité, politiques d'autorisation, extension via WebAssembly (Wasm). Sa réputation de complexité opérationnelle est partiellement justifiée par l'étendue de ses fonctionnalités, mais les versions récentes ont considérablement simplifié l'installation et la configuration.

**Linkerd** est le second service mesh le plus répandu, positionné comme une alternative plus simple et plus légère à Istio. Développé par Buoyant, il est également un projet diplômé de la CNCF. Linkerd utilise son propre proxy (linkerd2-proxy), développé en Rust, qui est significativement plus léger et plus performant qu'Envoy. La philosophie de Linkerd est de couvrir 80 % des cas d'usage avec 20 % de la complexité. Il fournit mTLS, observabilité et traffic splitting, mais ne propose pas certaines fonctionnalités avancées d'Istio (routage basé sur les headers, extension Wasm, rate limiting natif).

> **Note sur la licence Linkerd** : depuis Linkerd 2.15 (février 2024), Buoyant ne distribue plus de binaires « stables » prébuilt sous Apache 2.0. Le code source du projet reste sous licence Apache 2.0 (et reste constructible librement), mais les releases stables prébuilt distribuées par Buoyant relèvent de la *Buoyant Enterprise License* (BEL) — un abonnement commercial est requis au-delà d'un certain seuil d'usage en production. Les releases « edge » (build de développement) restent disponibles librement. Cette décision a suscité des débats dans la communauté et doit être prise en compte : si votre organisation exige des artefacts officiels open source, vous devrez soit reconstruire depuis le code source, soit utiliser les edge releases, soit souscrire à BEL. Vérifiez l'état actuel de la licence avant de vous engager.

**Cilium Service Mesh** est un entrant plus récent qui exploite eBPF pour fournir des fonctionnalités de service mesh au niveau du kernel, sans sidecar. Cilium étant déjà largement adopté comme CNI (il est le CNI par défaut de GKE Dataplane V2, comme vu dans la section 17.1.5), l'ajout de capacités service mesh représente une évolution naturelle plutôt qu'un composant supplémentaire. Cilium Service Mesh est particulièrement pertinent pour les organisations qui utilisent déjà Cilium comme CNI et qui veulent des fonctionnalités de mesh (mTLS, observabilité L7) sans ajouter un projet séparé.

### Projets arrêtés ou en déclin

Plusieurs projets de service mesh ont été abandonnés ou marginalisés au fil du temps, ce qui témoigne de la consolidation de l'écosystème. Consul Connect (HashiCorp) proposait un mesh intégré à l'outil de service discovery Consul, mais HashiCorp est passé sous licence BSL en 2023, ce qui a réduit son adoption dans les projets open source. AWS App Mesh, l'offre managée d'AWS, est entré en cycle de fin de support : depuis le 24 septembre 2024, les nouveaux clients ne peuvent plus s'y intégrer ; les clients existants conservent l'usage du service jusqu'au **30 septembre 2026, date à laquelle la console et les ressources App Mesh deviendront inaccessibles** (cette date marque la fin de vie complète, et non un simple changement de support). AWS recommande désormais Istio en self-managed sur EKS, VPC Lattice ou — pour ECS — Amazon ECS Service Connect comme remplacements. Open Service Mesh (OSM), initialement soutenu par Microsoft, a été archivé par la CNCF le 30 juin 2023 (annonce du 4 mai 2023, Microsoft ayant choisi de réorienter ses contributions vers Istio ; l'addon OSM dans AKS reste supporté jusqu'au 30 septembre 2027). Maesh/Traefik Mesh (Traefik Labs) a été discontinué.

Cette consolidation est un signal positif pour l'écosystème : les investissements se concentrent sur un nombre réduit de projets matures plutôt que de se disperser. Pour les organisations qui adoptent un service mesh aujourd'hui, le choix se résume essentiellement à Istio, Linkerd ou Cilium Service Mesh — avec Istio comme choix par défaut pour la majorité des cas.

---

## Service mesh et Kubernetes managé

### Offres intégrées des providers

Comme vu dans la section 17.1.5, les cloud providers proposent des intégrations de service mesh avec leurs offres Kubernetes managées :

**GKE** offre la meilleure intégration native. Cloud Service Mesh (anciennement Anthos Service Mesh) est un Istio managé, disponible comme addon GKE. Google gère l'installation, la mise à jour et la configuration du control plane Istio. L'intégration avec Cloud Monitoring, Cloud Logging et Cloud Trace est automatique. Pour les fonctionnalités L4 (mTLS uniquement), GKE Dataplane V2 (Cilium) fournit un chiffrement transparent sans mesh additionnel.

**AKS** propose l'addon Istio-based service mesh, intégré comme composant managé. Microsoft gère le lifecycle du control plane Istio. L'extension Open Service Mesh a été dépréciée au profit de cette intégration Istio.

**EKS** ne propose pas de service mesh intégré natif. AWS a déprécié App Mesh et recommande l'installation manuelle d'Istio ou l'utilisation de VPC Lattice (un service de connectivité applicative L7 propre à AWS, qui n'est pas un service mesh Kubernetes au sens strict mais couvre certains cas d'usage similaires). Cette approche est cohérente avec la philosophie EKS de laisser le client assembler ses propres composants.

### Impact sur le choix

L'existence d'un service mesh managé chez un provider réduit significativement la charge opérationnelle. Gérer le control plane Istio soi-même implique de suivre les releases, de planifier les mises à jour (Istio publie des releases mineures tous les quelques mois avec une politique de support limitée), de dimensionner les composants et de déboguer les problèmes de configuration. Un mesh managé délègue cette charge au provider.

Cependant, un mesh managé lie votre configuration mesh au provider cloud — un facteur de lock-in supplémentaire à évaluer (section 17.1.5 sur la portabilité).

---

## Organisation de cette section

Les sous-sections suivantes approfondissent chaque dimension du service mesh :

- **17.2.1 — Concepts et cas d'usage** : détail des fonctionnalités clés (mTLS, traffic management, observabilité), patterns de déploiement, exemples de configurations concrètes
- **17.2.2 — Istio : architecture et configuration** : architecture détaillée (istiod, Envoy, Gateway API), installation sur Debian/K8s, configuration des politiques de routage et de sécurité, intégration avec la stack d'observabilité du Module 15
- **17.2.3 — Linkerd : architecture et configuration** : philosophie et architecture (linkerd2-proxy, control plane minimal), installation et configuration, mTLS automatique, métriques dorées et intégration avec Grafana
- **17.2.4 — Comparaison et critères de choix** : analyse comparative détaillée (fonctionnalités, performance, complexité opérationnelle, communauté, support commercial), matrice de décision, stratégies de migration

Chaque sous-section est orientée Debian et Kubernetes, avec des configurations et commandes directement applicables sur les clusters que vous avez construits dans les modules précédents ou sur les clusters managés de la section 17.1.

---

## Points clés à retenir

- Un service mesh est une couche d'infrastructure réseau qui gère les communications entre microservices de manière transparente pour le code applicatif. Il fournit mTLS, gestion du trafic, observabilité et contrôle d'accès L7.
- L'architecture repose sur la séparation data plane (proxies qui traitent le trafic) / control plane (composants qui configurent les proxies). Si le control plane tombe, le data plane continue de fonctionner avec sa dernière configuration.
- Le pattern sidecar (un proxy par Pod) est le modèle historique. L'approche ambient (agent par nœud) et l'approche eBPF (traitement dans le kernel) émergent comme alternatives plus légères.
- Un service mesh ajoute une complexité opérationnelle significative. Il ne se justifie que pour des architectures microservices de taille importante ou sous contraintes de sécurité (mTLS) et d'observabilité fine.
- L'écosystème s'est consolidé autour de trois projets : Istio (le plus complet), Linkerd (le plus simple) et Cilium Service Mesh (convergence CNI/mesh via eBPF).
- Les cloud providers proposent des intégrations de service mesh (Cloud Service Mesh chez GKE, addon Istio chez AKS) qui réduisent la charge opérationnelle mais ajoutent du couplage avec le provider.
- L'adoption doit être progressive : observabilité d'abord, puis mTLS, puis politiques d'autorisation, puis traffic management. Un déploiement big bang est la recette de l'échec.

⏭️ [Concepts et cas d'usage (mTLS, traffic management, observabilité)](/module-17-cloud-service-mesh-stockage/02.1-concepts-cas-usage.md)
