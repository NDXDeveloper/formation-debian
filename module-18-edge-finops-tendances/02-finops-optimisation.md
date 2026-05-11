🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 18.2 FinOps et optimisation des coûts

## Introduction

L'adoption de Kubernetes et du cloud a profondément transformé la manière dont les infrastructures sont consommées et facturées. Dans le modèle traditionnel on-premise, les coûts d'infrastructure sont essentiellement des investissements initiaux (CAPEX) : on achète des serveurs, on les amortit sur trois à cinq ans, et le coût marginal d'exécution d'un workload supplémentaire est quasi nul tant que la capacité n'est pas saturée. Dans le modèle cloud, les coûts deviennent des dépenses opérationnelles (OPEX) proportionnelles à l'usage : chaque heure de calcul, chaque gigaoctet stocké et chaque gigaoctet transféré est facturé.

Ce changement de modèle économique a créé une nouvelle catégorie de problèmes. Les organisations qui migraient vers le cloud en espérant réduire leurs coûts ont souvent constaté l'inverse : les factures cloud augmentent de manière incontrôlée, les ressources provisionnées dépassent largement les besoins réels, et personne dans l'organisation n'a une vision claire de qui consomme quoi et pourquoi.

FinOps — contraction de Finance et Operations — est la discipline qui répond à ces problèmes. Elle combine pratiques culturelles, outils techniques et processus organisationnels pour maximiser la valeur métier obtenue par euro dépensé en infrastructure, qu'il s'agisse de cloud public, de clusters Kubernetes on-premise ou d'une flotte de nœuds edge.

---

## Qu'est-ce que FinOps ?

### Définition et principes fondateurs

FinOps n'est pas un outil, ni une méthode de réduction de coûts. C'est un modèle opérationnel qui donne aux équipes d'ingénierie la capacité de prendre des décisions d'architecture et d'exploitation en connaissance de cause quant à leur impact financier. La FinOps Foundation (qui fait partie de la Linux Foundation) définit FinOps comme une pratique culturelle évolutive, structurée autour de six principes.

**Les équipes doivent collaborer.** L'optimisation des coûts n'est pas la responsabilité exclusive d'un service financier ou d'une équipe infrastructure. Les développeurs, les ops, les architectes et les décideurs métier partagent la responsabilité des dépenses. Chaque équipe qui provisionne des ressources doit comprendre le coût de ses décisions.

**Chacun est responsable de son usage cloud.** Les équipes d'ingénierie sont propriétaires de leur consommation. Les coûts sont attribués (chargeback) ou rendus visibles (showback) au niveau de chaque équipe, projet ou service. Cette visibilité crée une incitation naturelle à l'optimisation.

**Un groupe centralisé pilote FinOps.** Une équipe FinOps transverse (parfois appelée Cloud Center of Excellence) définit les bonnes pratiques, fournit les outils de reporting, négocie les contrats avec les fournisseurs et anime la démarche d'optimisation à l'échelle de l'organisation.

**Les rapports doivent être accessibles et en temps réel.** Les données de coûts doivent être disponibles rapidement, pas dans un rapport mensuel reçu trois semaines après la clôture. Les dashboards de coûts sont consultés quotidiennement par les équipes, comme les dashboards d'observabilité technique.

**Les décisions sont guidées par la valeur métier.** L'objectif n'est pas de minimiser les coûts à tout prix, mais de maximiser le rapport entre la valeur métier produite et le coût de l'infrastructure qui la porte. Dépenser plus pour un service qui génère plus de revenus est parfaitement rationnel. Dépenser pour des ressources inutilisées ne l'est pas.

**Le modèle de coût variable du cloud est un levier.** La facturation à l'usage n'est pas un problème, c'est une opportunité. Contrairement au modèle on-premise où la capacité est fixe, le cloud permet d'ajuster les ressources à la demande. FinOps exploite cette flexibilité pour aligner les coûts sur la charge réelle.

### Le cycle FinOps : Inform, Optimize, Operate

La pratique FinOps s'articule autour d'un cycle itératif en trois phases.

**Inform (Informer).** La première phase consiste à rendre les coûts visibles, compréhensibles et attribuables. Cela inclut la collecte des données de facturation auprès des fournisseurs cloud, l'attribution des coûts aux équipes, projets et environnements via un système de tags et de labels, la création de dashboards de visualisation des coûts et de leur évolution, l'identification des anomalies (pics de dépenses, dérives progressives), et le benchmarking par rapport aux périodes précédentes ou aux budgets prévisionnels.

Sans visibilité, aucune optimisation n'est possible. La phase Inform est le fondement sur lequel tout le reste repose.

**Optimize (Optimiser).** La deuxième phase identifie et met en œuvre les leviers de réduction des coûts. Les optimisations se regroupent en plusieurs catégories : le right-sizing (ajuster la taille des ressources au besoin réel), l'élimination du gaspillage (supprimer les ressources inutilisées), les engagements tarifaires (reserved instances, savings plans), les choix architecturaux (choix de région, de type de stockage, de classe de service) et l'autoscaling (adapter dynamiquement les ressources à la charge).

**Operate (Opérer).** La troisième phase pérennise les optimisations dans les processus opérationnels. Les politiques de coûts sont intégrées dans les pipelines CI/CD (vérification automatique des ressources demandées), les alertes de budget sont configurées et surveillées, les revues de coûts sont institutionnalisées (réunions hebdomadaires ou mensuelles), les bonnes pratiques sont codifiées et partagées. Le cycle recommence ensuite : les données collectées lors de la phase Operate alimentent la phase Inform du cycle suivant.

---

## FinOps et Kubernetes : des défis spécifiques

### La couche d'abstraction Kubernetes

Kubernetes introduit une couche d'abstraction entre les workloads applicatifs et l'infrastructure sous-jacente. Un développeur qui déploie un pod ne voit pas directement la VM, le serveur physique ou l'instance cloud sur lesquels ce pod s'exécute. Cette abstraction, bénéfique pour la portabilité et la productivité, rend l'attribution des coûts plus complexe.

Dans un modèle IaaS classique (VMs cloud), chaque VM est identifiable, taggable et imputable à un propriétaire. Dans un cluster Kubernetes, des dizaines de pods de différentes équipes cohabitent sur les mêmes nœuds. Un nœud de 16 Go de RAM à 200 €/mois héberge simultanément des pods du service web, de l'API backend, du monitoring et de batch processing. Comment répartir ces 200 € entre les quatre équipes ? Le problème est analogue à la répartition des charges dans une copropriété : la facture est collective, mais chacun veut payer sa juste part.

### Requests, limits et consommation réelle

Le modèle de gestion des ressources de Kubernetes repose sur deux concepts : les requests (ressources réservées, garanties au pod) et les limits (plafond maximal). La différence entre les deux crée un espace de surallocation (overcommit) qui est à la fois une force (meilleure utilisation de l'infrastructure) et une source de complexité pour l'attribution des coûts.

Un pod qui demande 256 Mo de RAM (request) mais en consomme réellement 100 Mo gaspille 156 Mo de capacité réservée. Un pod qui demande 256 Mo mais qui a une limite à 512 Mo peut ponctuellement consommer plus que sa réservation, au détriment des autres pods. Le coût doit-il être calculé sur la request, sur la consommation réelle, ou sur une combinaison des deux ?

Cette question n'a pas de réponse unique. Elle dépend de la politique de l'organisation et du modèle de chargeback choisi. Les outils de FinOps Kubernetes (Kubecost, OpenCost) proposent différents modèles de répartition, abordés dans les sous-sections suivantes.

### Multi-cluster et environnements hybrides

La complexité s'accroît encore dans les architectures multi-cluster et hybrides, qui sont précisément celles abordées dans ce parcours. Une organisation qui opère des clusters Kubernetes sur AWS, GCP et on-premise, complétés par une flotte de clusters K3s edge, doit consolider des données de coûts provenant de sources radicalement différentes : factures cloud (avec des modèles de tarification distincts par fournisseur), coûts on-premise (amortissement matériel, électricité, refroidissement, main-d'œuvre), coûts edge (matériel, connectivité cellulaire, interventions sur site).

FinOps pour Kubernetes dans un contexte hybride exige une normalisation de ces données hétérogènes vers un référentiel commun qui permet les comparaisons et les arbitrages.

---

## Les dimensions du coût Kubernetes

### Coûts de calcul (compute)

Le calcul est généralement le poste de dépense le plus important. Il comprend les instances cloud (EC2, GCE, Azure VMs) pour les clusters managés, les serveurs physiques (amortissement) pour les clusters on-premise, et les edge devices (Raspberry Pi, mini-PC industriels) pour les clusters K3s edge. Le coût de calcul est directement lié au nombre et à la taille des nœuds du cluster, eux-mêmes déterminés par les ressources (CPU, RAM) demandées par les pods.

### Coûts de stockage

Le stockage comprend les volumes persistants (EBS, Persistent Disk, disques locaux), les snapshots et sauvegardes, le stockage objet (S3, GCS) pour les artefacts, logs et sauvegardes, et les registres d'images conteneur. Le stockage est souvent sous-estimé car les volumes persistent après la suppression des workloads. Des volumes orphelins peuvent représenter un gaspillage significatif.

### Coûts réseau

Le trafic réseau est facturé différemment selon les fournisseurs, mais le principe général est le suivant : le trafic entrant (ingress) est gratuit ou peu coûteux, le trafic sortant (egress) est facturé, le trafic inter-zones et inter-régions est facturé, le trafic intra-zone est souvent gratuit. Dans une architecture multi-cluster avec des communications edge-to-cloud fréquentes (cf. section 18.1.3), le coût de l'egress peut devenir un poste significatif. Les liaisons cellulaires pour les sites edge ajoutent un coût de connectivité direct facturé au volume.

### Coûts des services managés

Les clusters Kubernetes managés (EKS, GKE, AKS) facturent le control plane en plus des nœuds. Les services complémentaires (load balancers, NAT gateways, DNS, monitoring managé) ajoutent des coûts récurrents qui ne sont pas toujours anticipés. Un load balancer cloud coûte typiquement entre 15 et 25 €/mois, même avec un trafic minimal. Un cluster EKS avec trois environnements (dev, staging, prod) et deux load balancers chacun accumule des coûts fixes non négligeables avant même d'exécuter le moindre workload.

### Coûts humains et opérationnels

FinOps se concentre traditionnellement sur les coûts d'infrastructure, mais les coûts humains (temps d'ingénierie, astreintes, formation) sont souvent bien supérieurs. Un cluster auto-géré sur Debian (kubeadm) est moins cher en infrastructure qu'un cluster managé, mais le temps d'ingénierie pour l'opérer (mises à jour, patches de sécurité, debugging, monitoring) doit être comptabilisé. Le choix entre cluster managé et auto-géré est un arbitrage FinOps à part entière.

---

## FinOps pour les infrastructures on-premise et edge

### Adapter FinOps au-delà du cloud public

La littérature FinOps se concentre majoritairement sur le cloud public, où les données de coûts sont directement disponibles via les APIs de facturation des fournisseurs. Pour les infrastructures on-premise et edge, qui constituent une part importante des déploiements Debian/K3s couverts par cette formation, la démarche FinOps doit être adaptée.

Les coûts on-premise ne sont pas facturés à l'usage. Ils sont composés de l'amortissement du matériel (serveurs, stockage, réseau), de l'électricité et du refroidissement, de l'immobilier (espace datacenter), de la connectivité (liens réseau), de la main-d'œuvre (administration, exploitation) et des licences logicielles. Ces coûts doivent être modélisés pour être attribués aux workloads de manière comparable aux coûts cloud.

Une approche courante consiste à calculer un coût horaire par cœur CPU et par Go de RAM pour l'infrastructure on-premise, en intégrant l'ensemble des coûts directs et indirects. Ce coût unitaire est ensuite utilisé pour valoriser la consommation de chaque pod, de la même manière qu'un coût d'instance cloud.

### Coûts spécifiques à l'edge

Les flottes edge introduisent des postes de coûts particuliers rarement présents dans les déploiements cloud ou datacenter : le matériel edge (coût unitaire et amortissement des appareils), les forfaits de connectivité cellulaire ou satellitaire, les interventions sur site (déplacement de techniciens, remplacement de matériel), la consommation électrique locale (parfois alimentée par batterie ou panneau solaire) et l'usure du stockage (cartes SD, eMMC à durée de vie limitée). L'optimisation FinOps à l'edge porte autant sur la réduction du trafic réseau (cf. section 18.1.3) que sur le dimensionnement optimal des appareils et l'allongement de leur durée de vie.

---

## Les outils de l'écosystème FinOps Kubernetes

### OpenCost

OpenCost est un projet open-source de la CNCF (statut Incubating depuis octobre 2024, après son acceptation initiale en juin 2022) qui fournit un modèle standardisé de mesure et d'attribution des coûts Kubernetes. Il collecte les données d'utilisation des ressources (CPU, RAM, stockage, réseau) par pod, namespace et label, les croise avec les données de tarification (prix des instances cloud ou coûts modélisés pour le on-premise) et produit une attribution granulaire des coûts.

OpenCost se déploie comme un pod dans le cluster et expose une API REST et des métriques Prometheus. Il s'intègre nativement avec Grafana pour la visualisation. Sa nature open-source et son hébergement CNCF en font un choix pertinent pour les organisations qui privilégient les standards ouverts.

### Kubecost

Kubecost est la solution commerciale la plus établie pour le FinOps Kubernetes. Construite sur le même noyau qu'OpenCost (Kubecost a contribué le code fondateur au projet OpenCost), elle ajoute des fonctionnalités avancées : interface web dédiée, recommandations automatiques de right-sizing, alertes de budget, rapports multi-cluster et intégration avec les APIs de facturation des cloud providers.

Kubecost propose une version communautaire gratuite (mono-cluster) et une version entreprise (multi-cluster, SSO, API avancées). La version communautaire est suffisante pour un cluster unique et constitue un excellent point de départ.

### Outils natifs des cloud providers

Chaque cloud provider propose ses propres outils de gestion des coûts : AWS Cost Explorer et AWS Budgets, Google Cloud Billing et Cost Management, Azure Cost Management. Ces outils fournissent une visibilité détaillée sur la facturation cloud mais ne descendent pas au niveau de granularité Kubernetes (par pod, par namespace). Ils sont complémentaires des outils comme Kubecost ou OpenCost et nécessaires pour capturer les coûts des services managés non directement liés aux workloads Kubernetes.

### Prometheus et Grafana

Le duo Prometheus/Grafana, déjà en place pour l'observabilité technique (cf. Module 15), peut être étendu au monitoring des coûts. Les métriques d'utilisation des ressources (`container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`) sont croisées avec des données de tarification pour produire des estimations de coûts en temps réel. OpenCost expose ses résultats sous forme de métriques Prometheus, ce qui permet une intégration naturelle dans les dashboards Grafana existants.

---

## Positionnement dans le parcours

Cette section s'appuie sur les compétences acquises dans les modules précédents et les enrichit de la dimension financière :

- **Module 12 (Kubernetes Production)** — Les concepts de Resource Quotas, LimitRanges et autoscaling (HPA, VPA, Cluster Autoscaler) sont les mécanismes techniques sur lesquels reposent les optimisations FinOps. La section 18.2.1 les reprend sous l'angle du coût.

- **Module 15 (Observabilité)** — Prometheus et Grafana fournissent les données de consommation qui alimentent les calculs de coûts. Les dashboards FinOps sont une extension des dashboards d'observabilité.

- **Module 17 (Cloud)** — La connaissance des modèles de tarification des cloud providers (instances, stockage, réseau) est un prérequis pour les optimisations de la section 18.2.3.

- **Section 18.1 (Kubernetes à la périphérie)** — Les contraintes de bande passante et de connectivité edge ont un impact direct sur les coûts réseau. Les stratégies de compression et de réduction du volume à la source (section 18.1.3) sont des optimisations FinOps appliquées à l'edge.

---

## Plan de la section

Les sous-sections suivantes détaillent les aspects techniques et organisationnels de l'optimisation des coûts Kubernetes :

- **18.2.1 Resource quotas, limits et right-sizing** — Configuration fine des requests et limits, mécanismes de quotas par namespace, recommandations de right-sizing via VPA et outils de profiling, impact du surprovisionnement et du sous-provisionnement sur les coûts et la performance.

- **18.2.2 Cost monitoring et alerting (Kubecost, OpenCost)** — Déploiement et configuration des outils de suivi des coûts, modèles d'attribution (chargeback, showback), dashboards Grafana pour le FinOps, alertes de budget et détection d'anomalies.

- **18.2.3 Comparaison des coûts entre providers** — Modèles de tarification AWS, GCP et Azure pour Kubernetes, coût total de possession (TCO) on-premise vs cloud vs hybride, méthodologie de comparaison et pièges courants.

- **18.2.4 Reserved instances, spot instances et stratégies d'optimisation** — Mécanismes d'engagement tarifaire, utilisation des instances spot/preemptible pour les workloads tolérants, stratégies de mix on-demand/reserved/spot, autoscaling économique.

⏭️ [Resource quotas, limits et right-sizing](/module-18-edge-finops-tendances/02.1-quotas-limits-rightsizing.md)
