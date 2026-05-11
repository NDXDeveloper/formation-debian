🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 17.1 Cloud providers

## Prérequis

- Maîtrise de l'administration système Debian (Parcours 1)
- Expérience opérationnelle avec les conteneurs et Kubernetes (Modules 10 à 12)
- Notions d'Infrastructure as Code avec Terraform et Ansible (Module 13)
- Connaissances réseau avancées (Module 6)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre le positionnement des principaux cloud providers et leurs modèles de service (IaaS, PaaS, CaaS)
- Installer, configurer et utiliser les CLI des trois hyperscalers majeurs (AWS, GCP, Azure) sur un poste ou serveur Debian
- Déployer et exploiter des instances Debian officielles dans le cloud
- Évaluer les offres Kubernetes managées (EKS, GKE, AKS) et choisir celle qui correspond à un contexte donné
- Intégrer un environnement cloud dans une chaîne d'outillage DevOps existante basée sur Debian

---

## Introduction

Jusqu'ici dans cette formation, l'ensemble des compétences acquises reposait principalement sur des infrastructures on-premise : des serveurs Debian physiques ou virtualisés, des clusters Kubernetes déployés avec kubeadm ou K3s, des pipelines CI/CD hébergés localement. Cette approche reste fondamentale — elle constitue le socle de compréhension sans lequel l'utilisation du cloud se réduit à du clic-bouton sans maîtrise réelle.

Mais dans la réalité opérationnelle d'un ingénieur DevOps ou SRE en 2026, le cloud public est devenu un composant incontournable de la plupart des architectures. Que ce soit pour absorber des pics de charge, pour déployer dans plusieurs régions géographiques, pour bénéficier de services managés ou simplement pour réduire la charge opérationnelle liée au matériel, les cloud providers s'intègrent naturellement dans une stratégie d'infrastructure moderne.

Cette section pose les bases de l'interaction entre un environnement Debian et les trois hyperscalers dominants du marché : Amazon Web Services (AWS), Google Cloud Platform (GCP) et Microsoft Azure.

---

## Le paysage du cloud public

### Les trois hyperscalers

Le marché du cloud public est largement dominé par trois acteurs dont les parts de marché combinées représentent environ deux tiers des dépenses mondiales en infrastructure cloud.

**Amazon Web Services (AWS)** est le pionnier et le leader historique du cloud public. Lancé en 2006, il dispose du catalogue de services le plus étendu (plus de 200 services) et de la plus grande empreinte géographique. Son écosystème est mature, sa documentation abondante et le marché de l'emploi autour d'AWS reste le plus large. En contrepartie, la complexité de son offre peut être déroutante et sa tarification parfois difficile à anticiper.

**Google Cloud Platform (GCP)** se distingue par son expertise en matière de données, de machine learning et surtout de Kubernetes — ce qui n'est pas surprenant puisque Google est le créateur du projet. GKE (Google Kubernetes Engine) est généralement considéré comme l'offre Kubernetes managée la plus mature et la plus intégrée. GCP propose également un réseau mondial de très haute qualité (le réseau backbone de Google) et une approche souvent plus épurée que ses concurrents.

**Microsoft Azure** occupe une position particulièrement forte dans les entreprises qui utilisent déjà l'écosystème Microsoft (Active Directory, Office 365, Windows Server). Son intégration avec les outils Microsoft est un avantage décisif dans ces contextes. Azure a considérablement étoffé son support Linux au fil des années et Debian y est pleinement supportée en tant qu'image de première classe.

### Au-delà des trois grands

Il serait réducteur de limiter le cloud public à ces trois acteurs. D'autres fournisseurs méritent d'être mentionnés pour des cas d'usage spécifiques. OVHcloud (basé en France, certifié SecNumCloud pour certaines offres) et Scaleway proposent des alternatives européennes avec des engagements forts en matière de souveraineté des données. DigitalOcean et Hetzner Cloud se distinguent par leur simplicité et leur rapport qualité-prix pour des charges de travail plus modestes. Oracle Cloud Infrastructure (OCI) a gagné en crédibilité ces dernières années, notamment grâce à une offre gratuite généreuse et des performances compétitives.

Néanmoins, cette formation se concentre sur les trois hyperscalers car ils représentent la très grande majorité des environnements rencontrés en production, et parce que les compétences acquises sur l'un sont largement transposables aux autres.

### Modèles de service et responsabilité partagée

Pour exploiter efficacement le cloud, il est essentiel de bien comprendre les différents modèles de service et le partage de responsabilité qu'ils impliquent.

**IaaS (Infrastructure as a Service)** fournit des ressources de calcul, de stockage et de réseau virtualisées. Le fournisseur gère le matériel physique, l'hyperviseur et le réseau sous-jacent. Le client est responsable de tout ce qui se trouve au-dessus : système d'exploitation, middleware, applications, données. C'est ici que Debian s'insère le plus naturellement — on déploie une instance EC2 (AWS), Compute Engine (GCP) ou Virtual Machine (Azure) avec une image Debian, et on l'administre exactement comme on administrerait un serveur physique ou virtuel on-premise. Toutes les compétences acquises dans les modules précédents s'appliquent directement.

**PaaS (Platform as a Service)** abstrait la couche système d'exploitation. Le fournisseur gère l'infrastructure et le runtime ; le client se concentre sur son code applicatif et ses données. Des services comme AWS Elastic Beanstalk, Google App Engine ou Azure App Service entrent dans cette catégorie. L'interaction avec Debian est indirecte ici : on utilise un poste Debian pour développer et déployer, mais on ne gère plus le système d'exploitation des serveurs de production.

**CaaS (Container as a Service)** est le modèle qui nous intéresse le plus dans le contexte de cette formation. Les offres Kubernetes managées (EKS, GKE, AKS) en sont l'illustration principale. Le fournisseur gère le control plane Kubernetes (API server, etcd, scheduler, controller manager) tandis que le client gère ses workloads conteneurisés et, selon les configurations, les nœuds workers. C'est un modèle intermédiaire qui offre un bon équilibre entre contrôle et réduction de la charge opérationnelle.

Le schéma ci-dessous résume le partage de responsabilité selon le modèle :

```
                    On-premise    IaaS         CaaS          PaaS
                   ──────────   ──────────   ──────────   ──────────
Applications       │  Client │  │  Client │  │  Client │  │  Client │  
Données            │         │  │         │  │         │  │         │  
                   ├─────────┤  ├─────────┤  ├─────────┤  ├─────────┤
Runtime / K8s      │  Client │  │  Client │  │ Partagé │  │ Provider│  
Middleware         │         │  │         │  │         │  │         │  
                   ├─────────┤  ├─────────┤  ├─────────┤  │         │
OS (Debian)        │  Client │  │  Client │  │ Partagé │  │         │
                   ├─────────┤  ├─────────┤  ├─────────┤  │         │
Virtualisation     │  Client │  │ Provider│  │ Provider│  │         │  
Serveurs/Réseau    │         │  │         │  │         │  │         │  
Stockage physique  │         │  │         │  │         │  │         │  
                   └─────────┘  └─────────┘  └─────────┘  └─────────┘
```

---

## La place de Debian dans le cloud

### Un OS de premier rang pour le cloud

Debian occupe une place particulière dans l'écosystème cloud. Contrairement à ce que l'on pourrait penser, elle n'est pas une distribution marginale dans ce contexte — bien au contraire.

Les trois hyperscalers proposent des images Debian officielles maintenues et optimisées pour leurs plateformes respectives. Le projet Debian lui-même publie des images cloud officielles via le **Debian Cloud Team** (équipe officielle au sein du projet Debian, dont les outils de build sont publiés sur le dépôt `debian-cloud-images` de Salsa, la forge GitLab de Debian), garantissant que ces images respectent les standards Debian en termes de qualité, de sécurité et de suivi des mises à jour.

Plusieurs facteurs expliquent la pertinence de Debian dans le cloud. Sa stabilité légendaire réduit les risques d'incidents liés à l'OS en production. Son cycle de release prévisible permet de planifier les migrations. Sa légèreté (une installation minimale Debian est sensiblement plus compacte qu'une installation CentOS/RHEL équivalente) se traduit par des temps de démarrage plus courts et une consommation de ressources moindre — un avantage direct en termes de coûts dans un modèle facturé à l'usage. Enfin, l'absence de licence commerciale simplifie la gestion financière, contrairement aux distributions à souscription comme RHEL.

### Images Debian cloud : anatomie

Les images Debian cloud ne sont pas de simples copies de l'installateur standard. Elles sont construites spécifiquement pour l'environnement cloud et comportent plusieurs adaptations notables.

Le paquet `cloud-init` est préinstallé. Ce composant, quasi-universel dans le cloud, gère l'initialisation d'une instance au premier démarrage : configuration réseau, injection de clés SSH, exécution de scripts utilisateur (user-data), configuration du hostname et des métadonnées. C'est la pièce maîtresse qui permet de passer d'une image générique à une instance configurée pour un usage spécifique sans intervention manuelle.

Les images cloud incluent les pilotes et agents spécifiques à chaque hyperviseur : les outils invités pour la communication avec le host, les pilotes réseau et stockage optimisés (ENA et NVMe pour AWS, gVNIC et VirtIO pour GCP, mlx5 et hv_netvsc pour Azure), et dans certains cas un agent de gestion (comme `waagent` pour Azure ou `google-guest-agent` pour GCP).

Le noyau est parfois adapté (ou un noyau supplémentaire est disponible) pour inclure des options de configuration optimisées pour les environnements virtualisés. La taille de l'image est minimisée — pas d'environnement graphique, pas de services inutiles, documentation réduite — afin de limiter le temps de déploiement et l'empreinte sur le stockage.

### Du on-premise au cloud : continuité des compétences

Un point fondamental à retenir est que vos compétences Debian acquises tout au long de cette formation sont directement applicables dans le cloud. Une instance Debian dans AWS, GCP ou Azure reste un système Debian. On y retrouve APT pour la gestion des paquets, systemd pour la gestion des services, journald pour les logs, nftables pour le pare-feu, et tous les outils que vous maîtrisez déjà.

La différence se situe principalement dans la couche d'abstraction qui entoure l'instance : le réseau est virtualisé (VPC, subnets, security groups), le stockage est découplé (volumes bloc attachables, stockage objet), la haute disponibilité repose sur des mécanismes propres au provider (zones de disponibilité, load balancers managés) et l'ensemble est pilotable via des API.

C'est précisément la raison pour laquelle nous abordons le cloud à ce stade de la formation : vous disposez maintenant du socle technique pour comprendre non seulement ce que fait le cloud provider, mais aussi ce qu'il fait *à votre place* et quelles implications cela a en termes de sécurité, de performance et de coûts.

---

## Les CLI cloud : philosophie et approche commune

### Pourquoi la ligne de commande ?

Chaque cloud provider propose une console web (interface graphique dans le navigateur) pour administrer ses services. Alors pourquoi insister sur les outils en ligne de commande ?

La réponse tient en un mot : **reproductibilité**. Un clic dans une console ne laisse pas de trace exploitable. Une commande CLI, en revanche, peut être documentée, versionnée dans Git, intégrée dans un script, exécutée dans un pipeline CI/CD ou encapsulée dans un module Terraform. L'approche Infrastructure as Code que vous avez découverte au Module 13 repose fondamentalement sur la capacité à interagir avec les API des providers de manière programmatique.

Les trois CLI partagent une philosophie commune. Elles s'installent sur un poste ou serveur Debian en tant que binaires ou paquets. Elles s'authentifient via des credentials configurés localement (clés d'API, tokens, fichiers de configuration). Elles exposent l'ensemble des services du provider via des sous-commandes structurées. Et elles produisent une sortie structurée (JSON, YAML, texte tabulé) facilement exploitable par les outils Unix classiques (`jq`, `grep`, `awk`) ou par des scripts Python.

### Authentification et sécurité

L'un des aspects les plus critiques de l'utilisation des CLI cloud est la gestion des credentials. Une clé d'accès AWS ou un compte de service GCP donne potentiellement accès à l'ensemble de l'infrastructure cloud d'une organisation. La sécurisation de ces credentials est donc une priorité absolue.

Quelques principes fondamentaux s'appliquent indépendamment du provider :

Premièrement, ne jamais committer de credentials dans un dépôt Git. C'est la source de compromission la plus courante et la plus évitable. Des outils comme `git-secrets` ou `gitleaks` permettent de détecter ces erreurs avant qu'elles n'atteignent un dépôt distant.

Deuxièmement, appliquer le principe du moindre privilège. Les credentials utilisés pour le développement local ne devraient pas avoir les mêmes permissions que ceux d'un pipeline de production. Chaque provider propose des mécanismes de gestion fine des permissions : IAM Policies/Roles chez AWS, Cloud IAM (rôles prédéfinis ou personnalisés) chez GCP, et Azure RBAC adossé à Microsoft Entra ID chez Azure.

Troisièmement, préférer les credentials temporaires aux credentials statiques. AWS propose STS (Security Token Service) et les rôles assumables, GCP propose les tokens d'accès via les comptes de service, Azure propose les identités managées. Ces mécanismes génèrent des tokens à durée de vie limitée, réduisant l'impact d'une compromission.

Quatrièmement, utiliser des profils nommés pour gérer plusieurs environnements (développement, staging, production) sans risquer d'exécuter une commande destructrice sur le mauvais compte.

### Interaction avec Terraform et Ansible

Les CLI cloud ne sont pas des outils isolés. Elles s'intègrent dans l'écosystème IaC que vous avez étudié au Module 13.

Terraform utilise les providers AWS, Google et Azure pour interagir avec les API cloud. Ces providers Terraform s'appuient sur les mêmes mécanismes d'authentification que les CLI : si votre CLI est configurée et fonctionnelle, Terraform peut généralement réutiliser les mêmes credentials sans configuration supplémentaire.

Ansible dispose de collections dédiées pour chaque cloud (`amazon.aws`, `google.cloud`, `azure.azcollection`) qui permettent de provisionner et configurer des ressources cloud directement depuis des playbooks. Ces collections s'appuient sur les SDK Python des providers (`boto3`, `google-cloud-*`, `azure-*`). Sur Debian 13 et les versions plus récentes, l'installation système via `pip` est bloquée par PEP 668 (Module 5, section 5.3.1) ; les SDK doivent être installés dans un environnement virtuel Python (`python3 -m venv ...`) ou via les paquets `python3-*` officiels Debian quand ils existent.

Cette convergence des outils autour des mêmes API et des mêmes credentials simplifie considérablement la mise en place de workflows IaC complets, comme nous l'avons vu dans la section 13.3 sur la complémentarité Ansible et Terraform.

---

## Kubernetes managé : le CaaS en pratique

### Pourquoi un Kubernetes managé ?

Au Module 12, vous avez appris à déployer et opérer un cluster Kubernetes haute disponibilité sur des nœuds Debian. Vous avez mesuré la complexité de cette tâche : gestion du cluster etcd, maintenance des certificats, mise à jour du control plane, surveillance de la santé des composants système. Cette charge opérationnelle est significative et requiert des compétences pointues.

Les offres Kubernetes managées répondent à cette problématique en prenant en charge tout ou partie du control plane. Le client se concentre alors sur ses workloads applicatifs tandis que le provider garantit la disponibilité et les mises à jour du control plane.

Les trois offres principales sont EKS (Elastic Kubernetes Service) chez AWS, GKE (Google Kubernetes Engine) chez GCP et AKS (Azure Kubernetes Service) chez Azure. Chacune a ses particularités, ses forces et ses compromis, que nous détaillerons dans la section 17.1.5.

### Ce qui change par rapport à un cluster auto-géré

Le passage d'un cluster Kubernetes auto-géré sur Debian à un cluster managé modifie plusieurs aspects de l'exploitation quotidienne.

Le control plane devient une boîte noire. Vous n'avez plus accès directement aux composants `etcd`, `kube-apiserver`, `kube-scheduler` et `kube-controller-manager`. Les logs du control plane sont exposés via les mécanismes de logging du provider (CloudWatch chez AWS, Cloud Logging chez GCP, Azure Monitor chez Azure). La configuration du control plane se fait via les API du provider et non plus en éditant des fichiers de configuration sur les nœuds masters.

Les nœuds workers restent des instances que vous pouvez (dans la plupart des cas) administrer. Les OS par défaut diffèrent : AWS EKS utilise Amazon Linux 2023 (avec Bottlerocket en alternative), Azure AKS utilise Ubuntu (avec **Azure Linux** en alternative — anciennement CBL-Mariner, renommé officiellement en 2024) et GCP GKE utilise Container-Optimized OS (cos) avec Ubuntu en alternative. Debian peut être utilisée comme OS de nœuds chez AWS et Azure via des images personnalisées (AMI ou image managée), mais GKE n'autorise pas d'OS custom — le choix est limité à cos ou Ubuntu.

Le réseau est intégré au réseau virtuel du provider (VPC). Les services de type `LoadBalancer` provisionnent automatiquement des load balancers cloud. Les volumes persistants s'appuient sur le stockage bloc du provider (EBS, Persistent Disk, Azure Disk).

La facturation change de modèle. Le control plane est facturé en tant que service chez AWS (EKS, ~0,10 $/h soit ~73 $/mois sur les versions en standard support, ~0,60 $/h après 14 mois si vous restez sur une version en extended support) et GCP (GKE Standard et Autopilot, ~0,10 $/h depuis juin 2020 ; un seul cluster zonal par compte de facturation reste exempté en free tier). Azure AKS distingue trois tiers : **Free** (gratuit, mais sans SLA financier — seulement un objectif de 99,5 % de disponibilité), **Standard** (~0,10 $/h, SLA financier 99,95 %, infrastructure de control plane plus robuste) et **Premium** (~0,60 $/h, SLA + Long-Term Support de 2 ans sur les versions K8s LTS). Pour un cluster de production avec SLA, AKS Standard revient au même coût qu'EKS et GKE Standard. Les nœuds workers sont facturés comme des instances classiques chez les trois providers. Le coût total dépend donc de la taille du cluster, du nombre de clusters et de l'optimisation des ressources — un sujet que nous approfondirons au Module 18 sur le FinOps.

### Ce qui ne change pas

Les compétences Kubernetes que vous avez acquises aux Modules 11 et 12 restent pleinement valables. L'API Kubernetes est la même, que le cluster soit auto-géré ou managé. `kubectl` fonctionne de manière identique. Les manifestes YAML, les Helm charts, les configurations Kustomize, les Network Policies, les RBAC — tout cela est strictement identique.

Les outils de l'écosystème que vous maîtrisez (ArgoCD, Prometheus, Grafana, Cert-Manager, Istio) se déploient et s'opèrent de la même manière sur un cluster managé. C'est la force du standard Kubernetes : l'abstraction fonctionne dans les deux sens, et votre expertise est portable d'un environnement à l'autre.

---

## Organisation de cette section

Les sous-sections suivantes vous guideront à travers la mise en place concrète de l'outillage cloud sur Debian et l'utilisation des services Kubernetes managés :

- **17.1.1 — AWS CLI et outils sur Debian** : installation, configuration et utilisation de la CLI AWS, du SDK Python boto3 et des outils associés (eksctl, aws-iam-authenticator)
- **17.1.2 — Google Cloud SDK sur Debian** : installation et configuration de `gcloud`, `gsutil`, `bq` et des composants Kubernetes associés
- **17.1.3 — Azure CLI sur Debian** : installation de `az` CLI, authentification et gestion des ressources Azure
- **17.1.4 — Images Debian officielles dans le cloud** : exploration des images Debian disponibles chez chaque provider, personnalisation avec Packer et cloud-init
- **17.1.5 — Managed Kubernetes (EKS, GKE, AKS)** : comparaison détaillée des trois offres, critères de choix et patterns d'architecture courants

Chaque sous-section adopte une approche pratique centrée sur Debian : les installations se font sur un système Debian, les exemples utilisent des instances ou images Debian, et les configurations sont adaptées aux spécificités de notre distribution.

---

## Points clés à retenir

- Le cloud public n'est pas un remplacement de l'administration système — c'est une extension qui repose sur les mêmes fondamentaux.
- Les trois hyperscalers (AWS, GCP, Azure) dominent le marché mais le choix dépend du contexte technique, économique et organisationnel.
- Le modèle de responsabilité partagée détermine ce que vous gérez et ce que le provider gère : plus on monte dans l'abstraction (IaaS → CaaS → PaaS), plus le provider prend en charge de composants.
- Debian est un OS de premier rang dans le cloud, avec des images officielles optimisées chez les trois grands providers.
- Les CLI cloud sont les outils fondamentaux de l'interaction programmatique avec le cloud, et s'intègrent naturellement avec Terraform et Ansible.
- Kubernetes managé réduit la charge opérationnelle du control plane mais ne change pas les compétences Kubernetes requises pour opérer les workloads.
- La sécurité des credentials cloud est un enjeu critique qui doit être adressé dès le départ avec des pratiques rigoureuses.

⏭️ [AWS CLI et outils sur Debian](/module-17-cloud-service-mesh-stockage/01.1-aws-cli-debian.md)
