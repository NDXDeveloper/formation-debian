🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 17.3 Stockage distribué

## Prérequis

- Administration système Debian : systèmes de fichiers, montage, LVM, RAID (Module 3, section 3.1 et Module 8, section 8.5)
- Stockage Kubernetes : Persistent Volumes, PVC, StorageClasses, CSI (Module 11, section 11.5)
- Réseau : configuration avancée, bonding, diagnostic (Module 6, section 6.1)
- Kubernetes en production : haute disponibilité, opérations (Module 12)
- Cloud providers et Kubernetes managé (section 17.1)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Identifier les limites du stockage local et du stockage cloud natif dans les architectures distribuées
- Comprendre les trois abstractions de stockage distribué (bloc, fichier, objet) et leurs cas d'usage
- Évaluer la pertinence d'une solution de stockage distribué pour une architecture donnée
- Distinguer les approches convergée et hyperconvergée du stockage
- Comparer les solutions majeures (Ceph, MinIO, Rook) sur des critères techniques et opérationnels
- Anticiper les implications en termes de performance, de résilience et de coûts

---

## Introduction

### Le problème du stockage dans les architectures distribuées

Tout au long de cette formation, le stockage a été abordé sous plusieurs angles. Au Module 3 (section 3.1), vous avez étudié les systèmes de fichiers locaux (ext4, XFS, Btrfs, ZFS) et les mécanismes de montage sur un serveur Debian individuel. Au Module 8 (section 8.5), vous avez mis en œuvre le RAID logiciel (mdadm) et LVM pour la redondance et la flexibilité sur un seul serveur. Au Module 11 (section 11.5), vous avez découvert les Persistent Volumes et les StorageClasses dans Kubernetes. Au Module 17 section 17.1, vous avez vu que chaque cloud provider propose ses propres services de stockage bloc (EBS, Persistent Disk, Azure Disk) et objet (S3, GCS, Azure Blob).

Ces fondations couvrent la majorité des besoins. Mais elles atteignent leurs limites lorsque l'architecture exige un stockage qui soit simultanément :

**Distribué sur plusieurs nœuds.** Le stockage local (un disque attaché à un serveur) disparaît si le serveur tombe. Le RAID protège contre la panne d'un disque mais pas contre la panne du serveur entier. Dans un cluster Kubernetes, un Pod reschedulé sur un autre nœud perd l'accès à ses données locales. Le stockage distribué répartit les données sur plusieurs nœuds, garantissant que la perte d'un nœud n'entraîne pas la perte de données.

**Accessible depuis n'importe quel nœud.** Les volumes bloc du cloud provider (EBS, Persistent Disk, Azure Disk) sont attachés à un seul nœud à la fois. Si un Pod est reschedulé sur un autre nœud, le volume doit être détaché puis réattaché — un processus qui prend de quelques secondes à plusieurs minutes selon le provider. Les volumes de stockage distribué sont accessibles depuis n'importe quel nœud du cluster, éliminant cette contrainte.

**Accessible en écriture par plusieurs consommateurs simultanément.** Les volumes bloc sont par nature mono-attachement : un seul Pod peut écrire sur un volume EBS à un instant donné (mode `ReadWriteOnce`). Pour les applications qui nécessitent un accès en écriture partagé entre plusieurs Pods (mode `ReadWriteMany`) — une application web qui partage des uploads entre réplicas, un système de traitement de données qui lit et écrit dans un espace partagé — le stockage bloc ne suffit pas. Les services NFS managés (EFS chez AWS, Filestore chez GCP, Azure Files) répondent partiellement à ce besoin mais avec des limitations de performance et de coût.

**Indépendant d'un cloud provider.** Si votre architecture est multi-cloud, hybride (on-premise + cloud) ou si vous souhaitez éviter le lock-in sur le stockage d'un provider, les services de stockage natifs ne suffisent pas. Un stockage distribué auto-hébergé fournit la même interface (bloc, fichier ou objet) quelle que soit l'infrastructure sous-jacente.

**Capable de fournir du stockage objet compatible S3.** L'API S3 est devenue le standard de facto pour le stockage objet. De nombreuses applications, frameworks de données et outils de sauvegarde utilisent l'API S3 nativement. Disposer d'un stockage objet S3-compatible auto-hébergé permet de bénéficier de cet écosystème sans dépendre d'AWS.

### La réponse : le stockage distribué logiciel

Le stockage distribué logiciel (Software-Defined Storage, SDS) répond à ces besoins en transformant les disques locaux de plusieurs serveurs en un pool de stockage unifié, résilient et accessible depuis n'importe quel nœud du cluster. Les données sont réparties et répliquées automatiquement entre les nœuds selon des politiques de placement configurables.

L'idée fondatrice est d'appliquer au stockage la même logique que Kubernetes applique au compute : abstraire les ressources physiques (les disques de chaque serveur) derrière une interface unifiée (volumes, buckets) et laisser le logiciel gérer la distribution, la réplication et la récupération automatique.

Cette approche n'est pas nouvelle. Les systèmes de fichiers distribués existent depuis des décennies (NFS, GlusterFS, Lustre). Mais la génération actuelle de solutions de stockage distribué — incarnée par Ceph, MinIO et leurs opérateurs Kubernetes — apporte un niveau de maturité, de performance et d'intégration avec Kubernetes qui les rend viables pour la production à grande échelle.

---

## Les trois abstractions de stockage

Le stockage distribué expose les données via trois abstractions distinctes, chacune adaptée à des cas d'usage spécifiques. Comprendre ces abstractions est fondamental pour choisir la bonne solution et la bonne configuration.

### Stockage bloc (Block Storage)

Le stockage bloc présente un volume brut à un consommateur, comme un disque dur virtuel. Le consommateur (une VM, un Pod Kubernetes) formate ce volume avec le système de fichiers de son choix (ext4, XFS) et l'utilise comme un disque local. Chaque volume est attaché à un seul consommateur à la fois (mode `ReadWriteOnce`).

C'est l'abstraction la plus performante car elle offre les latences les plus faibles et les IOPS les plus élevées. Les bases de données (PostgreSQL, MySQL, MongoDB) et les systèmes de fichiers transactionnels utilisent le stockage bloc.

Dans le monde Kubernetes, le stockage bloc est exposé via des PersistentVolumes de type `Block` ou `Filesystem` (le driver CSI formate le bloc avant de le monter). Les services cloud natifs (EBS, Persistent Disk, Azure Disk) sont du stockage bloc. Les solutions de stockage distribué (Ceph RBD) fournissent du stockage bloc distribué — répliqué sur plusieurs nœuds mais accessible depuis un seul Pod à la fois.

### Stockage fichier (File Storage)

Le stockage fichier expose un système de fichiers partagé, accessible simultanément par plusieurs consommateurs via un protocole réseau (NFS, SMB/CIFS, CephFS). C'est l'équivalent d'un partage réseau classique.

L'avantage principal est l'accès concurrent : plusieurs Pods peuvent lire et écrire dans le même système de fichiers simultanément (mode `ReadWriteMany`). C'est indispensable pour les applications web qui partagent des fichiers entre réplicas, les systèmes de build qui utilisent un cache partagé et les workloads de data science qui accèdent à des datasets communs.

La contrepartie est la performance : un système de fichiers partagé via réseau ajoute de la latence par rapport au stockage bloc local. Les métadonnées (opérations d'ouverture, de listage, de verrouillage de fichiers) sont particulièrement sensibles à cette latence.

Dans Kubernetes, le stockage fichier est exposé via des PersistentVolumes en mode `ReadWriteMany`. Les solutions incluent NFS (simple mais limité en performance et en fiabilité), les services managés (EFS, Filestore, Azure Files) et les systèmes de fichiers distribués (CephFS, GlusterFS).

### Stockage objet (Object Storage)

Le stockage objet est une abstraction fondamentalement différente des deux précédentes. Les données sont stockées sous forme d'**objets** (un blob de données + des métadonnées + un identifiant unique) dans des **buckets** (conteneurs logiques). L'accès se fait via une API HTTP/REST (typiquement l'API S3), et non via un protocole de système de fichiers.

Le stockage objet n'a pas de notion de répertoires, de permissions POSIX ou de verrouillage de fichiers. Il est optimisé pour le stockage à grande échelle de données non structurées : sauvegardes, archives, images, vidéos, logs, modèles de machine learning, artefacts de build.

Ses avantages sont l'extensibilité quasi illimitée (les buckets n'ont pas de taille fixe), la simplicité de l'API (GET, PUT, DELETE sur des objets) et le coût de stockage généralement plus faible que le bloc ou le fichier. Sa limite est qu'il ne peut pas être monté comme un système de fichiers classique — les applications doivent utiliser l'API S3 pour lire et écrire. Des adaptateurs FUSE existent (comme `s3fs` ou `goofys`) mais leurs performances sont significativement inférieures à celles d'un vrai système de fichiers.

L'API S3 d'Amazon est devenue le standard de facto : les solutions de stockage objet auto-hébergées (MinIO, Ceph RGW) implémentent cette API, rendant les applications compatibles S3 portables entre AWS et une infrastructure on-premise.

### Résumé des abstractions

| Aspect | Bloc | Fichier | Objet |
|--------|------|---------|-------|
| Analogie | Disque dur | Partage réseau | Dépôt d'objets via API |
| Protocole | iSCSI, RBD | NFS, SMB, CephFS | HTTP/REST (S3) |
| Accès concurrent | Non (`ReadWriteOnce`) | Oui (`ReadWriteMany`) | Oui (via API) |
| Performance | Élevée (faible latence) | Moyenne (latence réseau) | Variable (throughput élevé, latence modérée) |
| Cas d'usage principal | Bases de données, volumes transactionnels | Fichiers partagés, uploads, caches | Sauvegardes, archives, data lake, artefacts |
| Montage POSIX | Oui | Oui | Non natif (FUSE possible) |
| Scalabilité | Limitée par le volume | Limitée par les métadonnées | Quasi illimitée |
| Exemple cloud | EBS, Persistent Disk, Azure Disk | EFS, Filestore, Azure Files | S3, GCS, Azure Blob |
| Exemple distribué | Ceph RBD | CephFS | Ceph RGW, MinIO |

---

## Architectures de stockage distribué

### Architecture convergée vs hyperconvergée

La manière dont le stockage distribué est déployé par rapport au compute influence directement les performances, la complexité et les coûts.

**L'architecture convergée** sépare les nœuds de stockage des nœuds de compute. Les serveurs de stockage forment un cluster dédié qui expose des volumes aux serveurs applicatifs via le réseau. Cette séparation offre une grande flexibilité : le stockage et le compute peuvent être dimensionnés indépendamment, des disques spécialisés (NVMe, SSD enterprise) peuvent être utilisés pour le stockage sans surcoût sur les nœuds de compute, et la maintenance des nœuds de stockage n'impacte pas les nœuds applicatifs.

C'est l'architecture traditionnelle des SAN (Storage Area Networks) et la manière la plus courante de déployer Ceph en dehors de Kubernetes. Dans un contexte Debian, cela signifie un ensemble de serveurs Debian dédiés au stockage Ceph, fournissant des volumes bloc (RBD) et un stockage objet (RGW) aux serveurs applicatifs et aux clusters Kubernetes via le réseau.

**L'architecture hyperconvergée (HCI)** déploie le stockage et le compute sur les mêmes nœuds. Chaque nœud du cluster contribue à la fois sa capacité de calcul et ses disques au pool de stockage distribué. Les données sont répliquées entre les nœuds, et chaque nœud peut accéder aux données localement (quand le placement le permet) ou via le réseau (quand les données sont sur un autre nœud).

C'est l'architecture privilégiée par Rook (l'opérateur Kubernetes pour Ceph) : les Pods Ceph (OSD, Monitor, Manager) s'exécutent sur les mêmes nœuds que les Pods applicatifs, utilisant les disques locaux des nœuds workers Kubernetes. L'avantage est la simplicité de déploiement (pas de cluster séparé à gérer) et la localité des données (un Pod peut accéder à des données stockées localement sur son nœud, réduisant la latence). L'inconvénient est le couplage entre le stockage et le compute : la maintenance d'un nœud impacte les deux, et le dimensionnement est contraint (ajouter du stockage implique d'ajouter des nœuds de compute).

### Le modèle de réplication

La résilience du stockage distribué repose sur la **réplication** des données entre les nœuds. Deux modèles principaux coexistent.

**La réplication N-way** copie chaque donnée sur N nœuds (typiquement 3). Si un nœud tombe en panne, les données restent disponibles sur les N-1 nœuds restants. Le coût est un facteur de multiplication du stockage brut : pour stocker 1 To utile avec une réplication 3x, il faut 3 To de stockage brut. C'est le modèle le plus simple et le plus courant, utilisé par défaut chez Ceph (taille de pool = 3) et par Longhorn.

**L'erasure coding** découpe les données en fragments et génère des fragments de parité, répartis sur les nœuds. Comme le RAID 5/6 (Module 8, section 8.5.1) mais distribué sur le réseau. L'erasure coding offre un meilleur ratio stockage utile / stockage brut (typiquement 1,5x à 2x contre 3x pour la réplication) mais avec un coût CPU supérieur pour l'encodage et le décodage, et des performances en écriture généralement inférieures. Ceph supporte l'erasure coding en tant qu'alternative à la réplication pour les pools qui privilégient l'efficacité du stockage (archivage, stockage objet) plutôt que la performance (bases de données). MinIO va plus loin : il **utilise exclusivement l'erasure coding** (Reed-Solomon) en mode distribué — pas de réplication N-way disponible — avec un ratio par défaut de N/2 données + N/2 parité, soit 50 % d'espace utile.

### Cohérence et consensus

Un système de stockage distribué doit maintenir la cohérence des données entre les réplicas. Les solutions modernes utilisent des mécanismes de consensus distribué pour s'assurer qu'une écriture est considérée comme réussie seulement lorsqu'un quorum de réplicas l'a confirmée.

Ceph utilise le protocole CRUSH (Controlled Replication Under Scalable Hashing) pour le placement des données et un mécanisme de quorum basé sur les Monitors (Paxos) pour les métadonnées du cluster. Les écritures de données sont considérées comme réussies lorsque le nombre de réplicas configuré a confirmé l'écriture.

MinIO en mode distribué utilise l'erasure coding avec un quorum de lecture et d'écriture. Une écriture nécessite un quorum de disques pour être confirmée, et une lecture peut reconstruire les données même si certains disques sont indisponibles.

Ces mécanismes de consensus ont un impact sur la performance : chaque écriture doit être confirmée par plusieurs nœuds via le réseau avant d'être acquittée au client. La latence d'écriture est donc fondamentalement limitée par la latence réseau entre les nœuds. C'est pourquoi un réseau à faible latence (10 Gbps ou plus) est un prérequis pour les performances du stockage distribué.

---

## Stockage distribué et Kubernetes

### Le rôle de CSI

L'intégration du stockage distribué dans Kubernetes passe par le **CSI** (Container Storage Interface), une API standard que vous avez étudiée au Module 11 (section 11.5.3). Le driver CSI fait le pont entre les API Kubernetes (PersistentVolume, PersistentVolumeClaim, StorageClass) et le système de stockage sous-jacent (Ceph, MinIO, NFS).

Chaque solution de stockage distribué fournit son propre driver CSI :

- **Ceph RBD** → `rbd.csi.ceph.com` (stockage bloc)
- **CephFS** → `cephfs.csi.ceph.com` (stockage fichier)
- **MinIO** → accès via l'API S3 (pas de CSI — le stockage objet n'utilise pas de montage de volume)
- **Rook** → orchestre Ceph et expose les drivers CSI RBD et CephFS automatiquement

Le driver CSI gère le cycle de vie complet du volume : création, attachement à un nœud, montage dans un Pod, redimensionnement, snapshot et suppression. Il traduit les concepts Kubernetes (StorageClass, reclaimPolicy, accessModes) en opérations sur le système de stockage distribué.

### Le rôle des opérateurs Kubernetes

Le déploiement et l'exploitation d'un système de stockage distribué dans Kubernetes sont des tâches complexes : il faut gérer les démons de stockage (OSD, Monitors chez Ceph), surveiller la santé du cluster, orchestrer la reconstruction des données après une panne, planifier les montées de version et gérer le placement des données.

Les **opérateurs Kubernetes** (Module 12, section 12.3.4) automatisent ces tâches via des Custom Resources et une boucle de réconciliation. L'opérateur le plus important dans cet écosystème est **Rook**, un opérateur CNCF (projet diplômé) qui gère le cycle de vie complet de Ceph dans Kubernetes. Rook transforme un déploiement Ceph complexe — qui nécessitait historiquement une expertise spécialisée en stockage — en un ensemble de Custom Resources Kubernetes déclaratives.

L'opérateur MinIO remplit un rôle similaire pour MinIO, gérant le déploiement, le scaling et la configuration des clusters MinIO dans Kubernetes.

---

## Le paysage des solutions

### Les acteurs principaux

L'écosystème du stockage distribué pour Kubernetes s'articule autour de trois solutions majeures, chacune positionnée sur un segment distinct :

**Ceph** est le système de stockage distribué le plus complet et le plus polyvalent. Développé depuis 2004, il fournit les trois abstractions de stockage (bloc via RBD, fichier via CephFS, objet via RGW) dans un système unifié. C'est un projet open source mature, largement déployé dans les infrastructures de production, notamment par les opérateurs cloud (OVHcloud, DigitalOcean) et les plateformes de cloud privé (OpenStack). Sa polyvalence en fait le choix par défaut pour les architectures qui nécessitent plusieurs types de stockage distribué. Sa contrepartie est la complexité opérationnelle — Ceph est un système sophistiqué avec de nombreux paramètres de configuration et une courbe d'apprentissage significative.

**MinIO** est une solution de stockage objet S3-compatible, optimisée pour la performance et la simplicité. Contrairement à Ceph qui tente de tout faire, MinIO se concentre exclusivement sur le stockage objet et vise à être le « meilleur stockage objet possible ». Il excelle dans les cas d'usage de data lake, de stockage d'artefacts, de sauvegarde et d'archivage. Son installation est plus simple que celle de Ceph, et ses performances en stockage objet sont généralement supérieures à celles du Ceph RGW. MinIO est distribué sous licence AGPL v3 (avec une option commerciale baptisée AIStor). **Évolution importante 2025-2026** : la *Community Edition* de MinIO est passée en *maintenance mode* fin 2025 puis a été archivée en 2026, l'éditeur redirigeant les utilisateurs vers son offre commerciale AIStor. Cette évolution doit être prise en compte lors de l'évaluation pour un nouveau projet (voir détail en section 17.3.2).

**Rook** n'est pas un système de stockage en soi mais un opérateur Kubernetes qui orchestre Ceph (et historiquement d'autres backends). Rook simplifie radicalement le déploiement et l'exploitation de Ceph dans Kubernetes en transformant les opérations de stockage complexes en ressources Kubernetes déclaratives. Il est devenu le moyen standard de déployer Ceph dans Kubernetes et constitue un projet diplômé de la CNCF.

### Solutions complémentaires

Au-delà de ces trois acteurs, d'autres solutions méritent d'être mentionnées pour des cas d'usage spécifiques :

**Longhorn** (Rancher/SUSE, projet CNCF incubating) est une solution de stockage bloc distribué conçue spécifiquement pour Kubernetes. Plus simple que Ceph, elle cible les clusters de taille modeste et les environnements edge (Module 18, section 18.1). Son architecture est plus légère mais ses fonctionnalités et ses performances sont inférieures à celles de Ceph pour les grands déploiements.

**OpenEBS** (projet CNCF sandbox) propose plusieurs moteurs de stockage pour Kubernetes, dont Mayastor (stockage bloc haute performance basé sur NVMe-oF). Il est pertinent pour les workloads exigeant des latences très faibles.

**SeaweedFS** est une alternative open source (Apache 2.0) à Ceph et MinIO pour le stockage objet et fichier, avec un accent sur la simplicité et la performance, particulièrement sur les petits objets. Sa traction a sensiblement augmenté en 2025-2026 dans le contexte de la transition de MinIO vers un modèle commercial.

**Garage** (projet Deuxfleurs sous AGPL v3) est une solution de stockage objet S3-compatible conçue spécifiquement pour les déploiements multi-sites géographiquement distribués et les environnements à empreinte modeste (homelab, edge, infrastructure associative). Elle privilégie la simplicité opérationnelle sur l'exhaustivité fonctionnelle.

Ces solutions alternatives ne sont pas couvertes en détail dans cette formation mais constituent des options à évaluer pour des cas d'usage spécifiques. La section 17.3.4 les intègre dans la matrice de décision.

---

## Quand adopter le stockage distribué ?

### Le stockage distribué n'est pas toujours nécessaire

Le stockage distribué ajoute une couche d'infrastructure significative : des composants à opérer, des disques à dimensionner, une réplication à surveiller, des performances réseau à garantir. Cette complexité doit être justifiée par un besoin réel.

Le stockage distribué est **probablement inutile** si vos workloads Kubernetes utilisent des volumes bloc (EBS, Persistent Disk) avec un accès `ReadWriteOnce` qui suffit, si vous êtes sur un seul cloud provider et que ses services de stockage managés couvrent vos besoins, si votre cluster est de taille modeste (moins de 10 nœuds) et que le stockage local est suffisant, ou si vos données critiques sont stockées dans des bases de données managées (RDS, Cloud SQL, Azure SQL) plutôt que dans des volumes Kubernetes.

Le stockage distribué est **probablement nécessaire** si vous avez besoin de stockage `ReadWriteMany` (fichiers partagés entre Pods) au-delà de ce que les services NFS managés offrent en performance, si votre architecture est multi-cloud ou hybride (on-premise + cloud) et que vous voulez un stockage unifié, si vous avez besoin d'un stockage objet S3-compatible auto-hébergé (souveraineté des données, conformité, coûts), si vos volumes de données dépassent ce que les services managés offrent à un coût raisonnable, ou si vous construisez une plateforme de cloud privé (OpenStack, infrastructure interne).

### La question du coût

Le coût est un facteur décisif. Le stockage distribué auto-hébergé n'est pas « gratuit » — il consomme des disques (3x le stockage utile avec la réplication par défaut), de la mémoire (les démons de stockage sont gourmands, surtout Ceph OSD), du CPU (pour la réplication, l'erasure coding, les checksums), de la bande passante réseau (réplication entre nœuds, reconstruction après panne) et du temps d'exploitation (surveillance, montées de version, résolution d'incidents).

Dans de nombreux cas, les services de stockage managés du cloud provider sont plus économiques que le stockage distribué auto-hébergé lorsqu'on intègre le coût total (infrastructure + opérations + expertise). Le stockage distribué auto-hébergé devient économiquement pertinent à partir d'un certain volume (typiquement plusieurs dizaines de téraoctets), lorsque les coûts de sortie de données (egress) du cloud sont prohibitifs, ou lorsque des contraintes de souveraineté imposent un hébergement local.

---

## Organisation de cette section

Les sous-sections suivantes approfondissent chaque solution majeure et leur comparaison :

- **17.3.1 — Ceph sur Debian** : architecture de Ceph (RADOS, OSD, Monitor, Manager, MDS), déploiement sur des serveurs Debian, configuration des pools, administration et monitoring. L'accent est mis sur la compréhension architecturale et le déploiement bare-metal sur Debian.

- **17.3.2 — MinIO (S3 compatible)** : architecture de MinIO, déploiement sur Debian et dans Kubernetes, configuration des buckets et des politiques, intégration avec les outils de sauvegarde et les workflows de données. L'accent est mis sur le stockage objet S3-compatible.

- **17.3.3 — Rook pour Kubernetes** : déploiement de Ceph dans Kubernetes via l'opérateur Rook, Custom Resources (CephCluster, CephBlockPool, CephObjectStore), StorageClasses et intégration CSI. L'accent est mis sur l'orchestration de Ceph dans Kubernetes.

- **17.3.4 — Comparaison et cas d'usage** : comparaison détaillée des solutions (Ceph, MinIO/AIStor, SeaweedFS, Garage, Longhorn, services managés cloud) sur des critères techniques, opérationnels et économiques. Matrices de décision et scénarios d'architecture, intégrant la situation 2026 du paysage stockage objet open source.

Chaque sous-section est ancrée dans le contexte Debian : les installations se font sur des systèmes Debian, les configurations utilisent les packages et les chemins Debian, et les recommandations prennent en compte les spécificités de la distribution.

---

## Points clés à retenir

- Le stockage distribué répond à des besoins que le stockage local et le stockage cloud natif ne couvrent pas : résilience multi-nœuds, accès `ReadWriteMany`, indépendance du provider et stockage objet S3-compatible auto-hébergé.
- Les trois abstractions de stockage (bloc, fichier, objet) répondent à des cas d'usage distincts. Le bloc offre les meilleures performances pour les bases de données, le fichier permet l'accès concurrent entre Pods, et l'objet est optimisé pour les données non structurées à grande échelle.
- L'architecture hyperconvergée (stockage et compute sur les mêmes nœuds, modèle Rook) simplifie le déploiement mais couple les deux domaines. L'architecture convergée (nœuds de stockage dédiés) offre plus de flexibilité mais plus de complexité.
- La réplication 3x est le modèle par défaut (simple, performant, coûteux en espace). L'erasure coding offre un meilleur ratio d'efficacité de stockage mais avec un coût CPU supérieur.
- Ceph est la solution la plus polyvalente (bloc + fichier + objet) et Rook est le moyen standard de la déployer dans Kubernetes. Pour le stockage objet S3-compatible, MinIO Community Edition reste très utilisé sur les déploiements existants mais a été archivée en 2026 ; les nouveaux projets open source se tournent désormais vers Ceph RGW, SeaweedFS, Garage, ou vers AIStor (offre commerciale MinIO Inc.) pour la continuité fonctionnelle.
- Le stockage distribué n'est pas toujours nécessaire. Les services managés du cloud provider couvrent la majorité des besoins avec une charge opérationnelle moindre. Le stockage distribué auto-hébergé se justifie par le volume de données, la souveraineté, le multi-cloud ou l'optimisation des coûts à grande échelle.
- Le coût total du stockage distribué inclut les disques (3x pour la réplication), les ressources compute des démons de stockage, la bande passante réseau et le temps d'exploitation. Ce coût doit être comparé aux services managés équivalents.

⏭️ [Ceph sur Debian](/module-17-cloud-service-mesh-stockage/03.1-ceph-debian.md)
