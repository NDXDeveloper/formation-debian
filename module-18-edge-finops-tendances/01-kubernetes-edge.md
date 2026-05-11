🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 18.1 Kubernetes à la périphérie

## Introduction

L'edge computing — ou informatique en périphérie — représente un changement de paradigme dans la manière dont les infrastructures sont conçues et opérées. Plutôt que de centraliser l'ensemble des traitements dans un datacenter ou un cloud distant, l'idée est de rapprocher le calcul, le stockage et la logique applicative au plus près des sources de données et des utilisateurs finaux.

Kubernetes, initialement pensé pour orchestrer des conteneurs dans de vastes clusters cloud, s'est progressivement imposé comme un standard d'orchestration y compris pour ces environnements contraints. Des distributions légères ont émergé pour répondre aux spécificités de l'edge : ressources matérielles limitées, connectivité réseau intermittente, dispersion géographique des nœuds et contraintes de sécurité physique.

Cette section explore les concepts, les architectures et les défis propres au déploiement de Kubernetes à la périphérie, en s'appuyant sur Debian comme système d'exploitation de référence pour les nœuds edge.

---

## Pourquoi l'edge computing ?

### Le problème de la latence et de la bande passante

Dans une architecture traditionnelle centralisée, toutes les données remontent vers un datacenter ou un cloud public pour y être traitées. Ce modèle fonctionne correctement lorsque la latence n'est pas critique et que la bande passante disponible est suffisante. Cependant, de nombreux cas d'usage modernes rendent cette approche inadaptée :

- **Latence incompressible** — Les applications temps réel (véhicules autonomes, robotique industrielle, réalité augmentée) nécessitent des temps de réponse de l'ordre de quelques millisecondes. Un aller-retour vers un datacenter distant introduit une latence réseau incompatible avec ces exigences.

- **Volume de données** — Les capteurs IoT, les caméras de surveillance ou les équipements industriels génèrent des volumes de données considérables. Transférer l'intégralité de ces flux vers le cloud est coûteux en bande passante, parfois techniquement impossible, et rarement pertinent puisque seule une fraction des données nécessite un traitement centralisé.

- **Disponibilité en mode dégradé** — Dans de nombreux contextes (sites industriels isolés, navires, plateformes offshore, zones rurales), la connectivité réseau vers le cloud n'est pas garantie en permanence. Les traitements critiques doivent pouvoir s'exécuter localement même en cas de coupure.

### Les domaines d'application

L'edge computing concerne aujourd'hui un spectre très large de secteurs et de cas d'usage :

- **Industrie 4.0** — Supervision de lignes de production, maintenance prédictive, contrôle qualité par vision par ordinateur, pilotage de robots. Les usines connectées déploient des dizaines voire des centaines de nœuds de calcul à proximité immédiate des équipements.

- **Retail et distribution** — Points de vente connectés, gestion des stocks en temps réel, digital signage, analyse du comportement client. Chaque magasin ou entrepôt devient un site edge à part entière.

- **Télécommunications** — Les opérateurs déploient du calcul au plus près des antennes (Multi-access Edge Computing, MEC) pour offrir des services à faible latence sur les réseaux 5G.

- **Santé** — Dispositifs médicaux connectés, imagerie médicale décentralisée, monitoring patient en temps réel dans les établissements de soins.

- **Transport et logistique** — Véhicules connectés, flottes de drones, gestion de trafic, systèmes embarqués dans les trains ou les navires.

- **Agriculture de précision** — Stations de monitoring environnemental, pilotage d'irrigation, analyse d'images satellite ou drone en local.

---

## Kubernetes comme standard d'orchestration à la périphérie

### D'un outil de datacenter à un standard universel

Kubernetes a été conçu à l'origine par Google pour gérer des milliers de conteneurs dans des clusters massifs. Son architecture — control plane centralisé, workers distribués, modèle déclaratif, boucle de réconciliation — supposait implicitement un réseau fiable à faible latence entre les composants, des nœuds disposant de ressources confortables, et une équipe d'exploitation dédiée.

L'adoption de Kubernetes comme standard de fait pour l'orchestration de conteneurs a naturellement conduit l'écosystème à chercher à l'adapter aux contraintes de l'edge. L'intérêt est évident : utiliser les mêmes abstractions (Pods, Deployments, Services, ConfigMaps), les mêmes outils (kubectl, Helm, ArgoCD) et les mêmes compétences d'un bout à l'autre de l'infrastructure, du cloud central jusqu'au nœud le plus distant.

### Ce que Kubernetes apporte à l'edge

L'utilisation de Kubernetes à la périphérie offre plusieurs avantages structurants par rapport à des approches ad hoc :

- **Modèle déclaratif et réconciliation** — L'état souhaité des applications est décrit dans des manifestes versionnés. Kubernetes s'assure en permanence que l'état réel converge vers cet état souhaité, même après un redémarrage, une panne réseau temporaire ou le remplacement d'un nœud. Ce modèle est particulièrement adapté à l'edge où les interventions manuelles sur site sont coûteuses.

- **Portabilité des workloads** — Une application conteneurisée et décrite via des manifestes Kubernetes peut être déployée indifféremment sur un cluster cloud, un serveur on-premise ou un nœud edge. Cette portabilité simplifie le développement, le test et le déploiement sur des infrastructures hétérogènes.

- **Gestion du cycle de vie** — Kubernetes gère nativement les mises à jour progressives (rolling updates), les rollbacks, le scaling et le health checking des applications. À l'échelle de centaines de sites edge, automatiser ces opérations est indispensable.

- **Écosystème unifié** — L'ensemble des outils de l'écosystème cloud-native (observabilité, sécurité, GitOps, service mesh) s'applique également aux déploiements edge, ce qui évite de maintenir des chaînes d'outils distinctes.

### Les défis spécifiques de l'edge

Déployer Kubernetes à la périphérie ne se résume pas à installer un cluster sur du matériel plus modeste. Les contraintes sont structurellement différentes de celles d'un datacenter :

- **Ressources limitées** — Les nœuds edge vont du Raspberry Pi (1 à 8 Go de RAM, processeur ARM) au serveur compact monté en rack (16 à 64 Go de RAM, processeur x86_64). Le control plane Kubernetes standard (API Server, etcd, scheduler, controller manager) consomme à lui seul plusieurs gigaoctets de mémoire, ce qui est incompatible avec les plus petits équipements.

- **Connectivité intermittente** — La liaison entre un site edge et le cluster central ou le cloud peut être instable, à faible débit, ou totalement coupée pendant des durées significatives. Le nœud doit continuer à faire tourner ses workloads de manière autonome et se resynchroniser proprement une fois la connexion rétablie.

- **Dispersion géographique** — Une flotte edge peut compter des dizaines, des centaines, voire des milliers de sites. Chaque site peut ne disposer que d'un ou deux nœuds. L'administration individuelle de chaque cluster est impensable : il faut des mécanismes de gestion centralisée à grande échelle.

- **Sécurité physique** — Contrairement aux datacenters, les équipements edge sont souvent déployés dans des lieux accessibles physiquement (usines, magasins, armoires de rue). Le risque de compromission physique impose des mesures de sécurité supplémentaires : chiffrement des volumes, attestation du boot, rotation automatique des secrets.

- **Hétérogénéité matérielle** — Les architectures processeur (ARM, x86_64, RISC-V), les capacités GPU/TPU, les types de stockage et les interfaces réseau varient considérablement d'un site à l'autre. La chaîne de build et de déploiement doit gérer cette diversité.

---

## Topologies d'architectures edge avec Kubernetes

Il n'existe pas une seule manière de déployer Kubernetes à la périphérie. Le choix de la topologie dépend du nombre de sites, des ressources disponibles par site, de la qualité de la connectivité et du niveau d'autonomie requis.

### Cluster unique étendu

Dans cette approche, un seul cluster Kubernetes est déployé avec le control plane dans un datacenter ou un cloud, et les workers distribués sur les sites edge. Les nœuds edge sont enregistrés comme workers classiques du cluster central.

Cette topologie est la plus simple à opérer lorsque la connectivité est fiable. Elle permet une gestion centralisée directe via kubectl et les outils habituels. En revanche, elle est vulnérable aux coupures réseau : si un worker edge perd la connexion au control plane, les pods existants continuent de tourner (grâce au kubelet local), mais aucune nouvelle opération (scheduling, scaling, mise à jour) n'est possible.

### Clusters edge autonomes

Chaque site edge dispose de son propre cluster Kubernetes léger (typiquement K3s), incluant un control plane local. Un outil de gestion centralisée (Rancher, Fleet, ArgoCD multi-cluster) assure la cohérence des déploiements entre les sites.

Cette topologie offre une autonomie complète de chaque site en cas de coupure réseau. Elle est adaptée aux environnements où la connectivité est intermittente ou peu fiable. Le coût est une complexité accrue : chaque site est un cluster à part entière, avec son propre etcd, sa propre configuration réseau, et ses propres certificats à gérer.

### Hiérarchie hub-and-spoke

Un cluster central (le hub) orchestre et pilote les clusters edge distants (les spokes) via un mécanisme de fédération ou de GitOps. Le hub concentre la définition de l'état souhaité, la gestion des politiques de sécurité et l'agrégation de l'observabilité. Les spokes exécutent les workloads de manière autonome et se synchronisent avec le hub lorsque la connectivité le permet.

Cette architecture est la plus courante dans les déploiements edge à grande échelle. Elle combine les avantages de la gestion centralisée et de l'autonomie locale.

---

## L'écosystème des distributions Kubernetes edge

Plusieurs distributions Kubernetes ont été spécifiquement conçues ou adaptées pour les environnements edge :

- **K3s** (Rancher/SUSE) — Distribution ultra-légère certifiée CNCF, packagée en un seul binaire d'environ 70 Mo. Elle remplace etcd par une base SQLite (ou un backend externe), intègre un load balancer, un ingress controller (Traefik) et un CNI (Flannel) par défaut. K3s est la distribution edge la plus largement adoptée et fonctionne parfaitement sur Debian, aussi bien sur ARM que sur x86_64.

- **MicroK8s** (Canonical) — Distribution légère orientée simplicité d'installation via snap. Bien que fonctionnelle pour l'edge, sa dépendance au système snap la rend moins naturelle sur Debian que sur Ubuntu.

- **KubeEdge** (CNCF Graduated depuis septembre 2024) — Projet spécifiquement conçu pour l'edge, avec un composant EdgeCore sur les nœuds distants et un CloudCore dans le cluster central. KubeEdge gère nativement la communication asynchrone entre le cloud et l'edge, y compris en mode déconnecté.

- **K0s** (Mirantis) — Distribution « zéro friction » sans dépendances système, packagée en un seul binaire. Compatible ARM et x86_64, avec une empreinte mémoire réduite.

Dans le cadre de cette formation centrée sur Debian, K3s sera la distribution privilégiée pour les déploiements edge, en raison de sa maturité, de sa compatibilité native avec Debian, de sa certification CNCF, et de la richesse de son écosystème (Rancher, Fleet).

---

## Positionnement dans le parcours

Cette section s'appuie sur les compétences acquises dans les modules précédents et les mobilise dans le contexte spécifique de l'edge :

- **Module 10 (Conteneurs)** — La maîtrise de Docker, Podman et des images Debian slim est indispensable pour construire des images conteneur adaptées aux contraintes de l'edge (taille réduite, multi-architecture).

- **Module 11 (Kubernetes Fondamentaux)** — La compréhension de l'architecture Kubernetes, des ressources fondamentales et du modèle déclaratif est un prérequis direct.

- **Module 12 (Kubernetes Production)** — Les concepts de haute disponibilité, de sécurité du cluster et d'autoscaling s'appliquent avec des adaptations aux clusters edge.

- **Module 13 (Infrastructure as Code)** — Ansible et Terraform sont utilisés pour provisionner et configurer les nœuds edge Debian de manière reproductible à grande échelle.

- **Module 14 (CI/CD et GitOps)** — Le modèle GitOps (ArgoCD, Flux) est le mécanisme privilégié pour déployer et synchroniser les applications sur des centaines de clusters edge.

- **Module 15 (Observabilité)** — La collecte de métriques, logs et traces depuis des nœuds edge distribués vers une stack d'observabilité centralisée pose des défis spécifiques abordés dans cette section.

---

## Plan de la section

Les sous-sections suivantes détaillent les aspects clés du déploiement de Kubernetes à la périphérie sur Debian :

- **18.1.1 K3s pour edge devices sur Debian** — Installation, configuration et optimisation de K3s sur des nœuds Debian hétérogènes (ARM, x86_64), avec gestion des agents, du stockage local et du réseau.

- **18.1.2 Architecture edge-to-cloud** — Conception d'architectures hybrides reliant les clusters edge au cloud central, gestion multi-cluster avec Rancher et Fleet, fédération et réplication des workloads.

- **18.1.3 Contraintes réseau et synchronisation** — Stratégies pour gérer la connectivité intermittente, la synchronisation d'état, le caching local, les mécanismes de store-and-forward et la gestion de la bande passante.

- **18.1.4 Sécurité IoT et mises à jour OTA** — Sécurisation des nœuds edge Debian (chiffrement LUKS, Secure Boot, attestation), gestion des mises à jour over-the-air, rotation des certificats et stratégies de rollback.

⏭️ [K3s pour edge devices sur Debian](/module-18-edge-finops-tendances/01.1-k3s-edge-debian.md)
