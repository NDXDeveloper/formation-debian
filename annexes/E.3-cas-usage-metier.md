🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe E.3 — Cas d'usage métier et architectures sectorielles

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section illustre l'application des compétences de la formation dans des **contextes professionnels concrets**. Chaque cas d'usage décrit un profil d'organisation, ses contraintes métier, l'architecture technique qui y répond et les modules de la formation mobilisés. L'objectif est de montrer comment les briques techniques s'assemblent dans des projets réels et d'aider l'apprenant à identifier les compétences les plus pertinentes pour son propre contexte.

Les architectures présentées sont des modèles simplifiés, représentatifs des choix techniques courants dans chaque secteur. Elles ne constituent pas des prescriptions universelles : chaque organisation adapte son infrastructure en fonction de ses contraintes spécifiques (budget, réglementation, compétences disponibles, historique technique).

---

## Cas 1 — Startup web en croissance

### Contexte

Une startup de 15 à 50 personnes développe une application SaaS (Software as a Service) destinée aux professionnels. L'équipe technique est réduite (3 à 8 développeurs, 1 à 2 ops/DevOps). Le produit évolue rapidement avec plusieurs déploiements par jour. Le budget infrastructure est limité mais la croissance du trafic est forte et imprévisible.

### Contraintes métier

La vélocité de développement est la priorité absolue : tout frein au déploiement a un impact direct sur la capacité à itérer sur le produit. La résilience doit être suffisante pour garantir un SLA acceptable (99,5% à 99,9%) sans mobiliser une équipe dédiée à l'exploitation. Le coût doit rester proportionnel au revenu, avec une capacité à scaler sans investissement initial massif.

### Architecture type

L'infrastructure repose sur un cluster Kubernetes managé (GKE, EKS ou AKS) pour éviter la charge d'exploitation du control plane. L'application est conteneurisée et déployée via Helm avec des fichiers values par environnement (staging, production). Le CI/CD utilise GitHub Actions ou GitLab CI avec des runners managés, et le déploiement en production passe par ArgoCD pour un workflow GitOps.

L'observabilité s'appuie sur une stack managée ou légère : Prometheus + Grafana pour les métriques (souvent via le monitoring intégré du cloud provider), Loki pour les logs et des alertes PagerDuty ou Slack pour l'on-call. La base de données est un service managé (Cloud SQL, RDS) pour éviter la charge d'administration.

Un ou deux serveurs Debian dédiés hébergent les outils de développement (runners CI, registry Docker privé, environnements de test) et servent de bastions SSH pour l'accès au réseau privé.

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 1, 3, 5, 6 | Administration Debian des bastions, scripting, SSH, pare-feu |
| 2 | 10, 11, 13 | Dockerfiles optimisés, Kubernetes fondamentaux, Terraform pour le cloud |
| 3 | 14, 15, 17 | GitOps (ArgoCD), observabilité, cloud providers |

### Compétences différenciantes dans ce contexte

La capacité à mettre en place un pipeline CI/CD complet et un workflow GitOps en quelques jours, avec un niveau de fiabilité suffisant pour des déploiements quotidiens, est la compétence la plus valorisée. La maîtrise de Terraform pour provisionner et faire évoluer l'infrastructure cloud de manière reproductible permet à l'équipe réduite de gérer l'infrastructure comme du code, avec le même workflow que le développement applicatif.

---

## Cas 2 — PME industrielle avec infrastructure on-premise

### Contexte

Une entreprise industrielle de 200 à 500 personnes gère une infrastructure informatique classique : serveurs de fichiers, messagerie interne, applications métier (ERP, GMAO), postes de travail pour l'administration et les bureaux d'études. L'équipe informatique est composée de 3 à 5 administrateurs système. Le budget est contraint et les investissements sont planifiés sur des cycles annuels.

### Contraintes métier

La disponibilité des services internes est critique pour la production industrielle : un arrêt du serveur ERP peut bloquer la chaîne de fabrication. La sécurité des données est une préoccupation croissante (réglementation, cyber-risques). Les solutions doivent être pérennes et maintenables par une équipe généraliste, sans expertise pointue en cloud-native. La connectivité Internet peut être limitée ou intermittente sur certains sites industriels.

### Architecture type

L'infrastructure repose sur des serveurs physiques Debian hébergeant les services critiques : serveur de fichiers Samba pour les partages Windows, serveur mail Postfix/Dovecot avec anti-spam Rspamd, serveur DNS BIND9 et DHCP Kea pour le réseau interne, serveur web Nginx pour les applications métier web internes et bases de données PostgreSQL et MariaDB pour les applications métier.

La virtualisation KVM/libvirt permet de consolider les serveurs physiques et de faciliter les sauvegardes via les snapshots. La haute disponibilité repose sur un RAID logiciel mdadm pour les disques, LVM pour la flexibilité du stockage et une sauvegarde borgbackup quotidienne vers un NAS distant avec réplication hors site.

Le réseau est segmenté par VLANs (bureaux, production industrielle, serveurs, DMZ) avec un pare-feu nftables sur le serveur passerelle. L'accès distant pour la télémaintenance passe par un VPN WireGuard.

L'automatisation est progressive : les tâches les plus répétitives (mises à jour de sécurité, rotation des sauvegardes, rapports de santé) sont scriptées en Bash, et Ansible est introduit graduellement pour la gestion de configuration à mesure que l'équipe monte en compétence.

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 1-8 (intégralité) | Installation, administration, services, réseau, sécurité, sauvegarde, HA |
| 2 | 9, 13 (partiellement) | Virtualisation KVM, introduction à Ansible |

### Compétences différenciantes dans ce contexte

La maîtrise complète du parcours 1 est directement valorisée. La capacité à mettre en place une stratégie de sauvegarde fiable avec des tests de restauration réguliers (module 8) et un pare-feu correctement configuré (module 6) sont des compétences critiques. L'introduction progressive d'Ansible (module 13) pour automatiser la gestion de configuration est le levier de modernisation le plus réaliste dans ce contexte.

---

## Cas 3 — Secteur public et collectivités

### Contexte

Une collectivité territoriale, un établissement public ou une administration gère une infrastructure informatique au service de plusieurs centaines à plusieurs milliers d'agents. L'équipe informatique assure à la fois le support utilisateur, la gestion du réseau, l'hébergement des applications métier et la conformité réglementaire. Le parc est hétérogène (serveurs anciens et récents, applications legacy et modernes).

### Contraintes métier

La conformité réglementaire est une obligation forte : RGS (Référentiel Général de Sécurité), RGPD, recommandations de l'ANSSI. L'utilisation de logiciels libres est encouragée par la politique publique française (circulaires Ayrault, DINUM). La pérennité des solutions est essentielle : les cycles de renouvellement sont longs (5 à 10 ans). La souveraineté numérique oriente les choix vers des solutions hébergeables en interne ou chez des opérateurs français.

### Architecture type

L'infrastructure repose sur des serveurs Debian, choisis pour leur stabilité long terme (cycle LTS/ELTS), l'absence de licence commerciale et leur conformité aux standards ouverts. Les postes de travail des agents peuvent être sous Debian avec GNOME ou XFCE selon la puissance du matériel.

Les services déployés incluent un annuaire LDAP ou Active Directory avec intégration SSSD pour l'authentification centralisée, un serveur de messagerie Postfix/Dovecot avec webmail (Roundcube ou SOGo), un serveur web Nginx pour les applications métier (intranet, téléservices), des bases de données PostgreSQL pour les applications métier, un partage de fichiers Samba intégré à l'annuaire et un serveur DNS et DHCP pour le réseau interne.

La sécurité fait l'objet d'une attention particulière : durcissement selon les guides de l'ANSSI (proches des CIS Benchmarks), chiffrement LUKS des disques contenant des données sensibles, journalisation centralisée avec rsyslog vers un serveur de collecte, AppArmor activé sur tous les serveurs et audits de sécurité réguliers avec Lynis.

La sauvegarde suit une stratégie 3-2-1 stricte avec borgbackup chiffré et des tests de restauration trimestriels documentés.

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 1-8 (intégralité) | Tous les services fondamentaux |
| 1 | 2 (spécifiquement) | Déploiement desktop pour les postes agents |
| 2 | 9 | Virtualisation pour la consolidation des serveurs |
| 3 | 16 (partiellement) | Durcissement, AppArmor, audit CIS |

### Compétences différenciantes dans ce contexte

La connaissance approfondie de Debian (module 1, philosophie et cycles de vie) est valorisée pour argumenter les choix techniques auprès des décideurs. Les compétences en sécurité et durcissement (modules 6 et 16) sont directement liées aux obligations de conformité RGS et ANSSI. La capacité à déployer et maintenir un serveur mail complet (module 8) est un besoin concret dans les structures qui souhaitent internaliser leur messagerie pour des raisons de souveraineté.

---

## Cas 4 — Hébergeur et infogérant

### Contexte

Un hébergeur ou un prestataire d'infogérance gère l'infrastructure de dizaines à centaines de clients. L'équipe technique est composée d'administrateurs système, d'ingénieurs réseau et d'ingénieurs DevOps. Le métier consiste à garantir la disponibilité, la performance et la sécurité des infrastructures hébergées, tout en maîtrisant les coûts d'exploitation.

### Contraintes métier

La densité est un enjeu économique : maximiser le nombre de clients par serveur physique tout en garantissant l'isolation et les performances. La standardisation des opérations est indispensable pour gérer un grand nombre d'environnements avec une équipe de taille raisonnable. Le SLA contractuel (99,9% à 99,99%) impose une haute disponibilité réelle, pas seulement théorique. La sécurité est critique car une compromission affecte potentiellement tous les clients d'un même serveur.

### Architecture type

L'infrastructure physique repose sur des serveurs Debian optimisés pour la virtualisation KVM/libvirt ou la conteneurisation. La couche d'orchestration utilise Kubernetes pour les clients cloud-native et des VM KVM pour les clients traditionnels.

La gestion de configuration est entièrement automatisée avec Ansible : chaque opération (provisionnement d'un client, mise à jour de sécurité, changement de configuration) est codifiée dans un playbook. Terraform provisionne l'infrastructure réseau et les ressources cloud pour les clients multi-cloud.

L'observabilité est centralisée : Prometheus avec federation pour les métriques de centaines de services, Loki pour l'agrégation des logs multi-clients, Grafana avec des dashboards par client et des alertes opérationnelles acheminées vers un système d'astreinte (PagerDuty ou équivalent). Les SLO sont définis par contrat client et suivis automatiquement.

La sécurité repose sur l'isolation réseau stricte (VLANs, Network Policies Kubernetes, pare-feu par client), le durcissement systématique des nœuds Debian (CIS Benchmarks, AppArmor), le scanning d'images conteneurs (Trivy) et la gestion centralisée des secrets (Vault).

Le load balancing HAProxy en frontal distribue le trafic entre les backends. La haute disponibilité s'appuie sur des clusters Pacemaker/Corosync pour les services critiques traditionnels et sur la réplication native de Kubernetes pour les workloads conteneurisés.

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 1, 3, 5, 6, 7, 8 | Administration Debian, scripting, réseau, services, HA |
| 2 | 9, 10, 11, 12, 13 | Virtualisation, conteneurs, Kubernetes production, IaC |
| 3 | 14, 15, 16, 17, 19 | CI/CD, observabilité, sécurité, cloud, architectures |

### Compétences différenciantes dans ce contexte

L'hébergement est le contexte qui mobilise le spectre le plus large de la formation. La capacité à automatiser intégralement le cycle de vie d'un client (provisionnement, configuration, monitoring, facturation) avec Ansible et Terraform (module 13) est fondamentale. La maîtrise de l'observabilité à grande échelle (module 15, federation Prometheus, agrégation de logs multi-tenant) et de la sécurité multi-tenant (module 16, isolation, Policy as Code) sont les compétences les plus avancées mobilisées.

---

## Cas 5 — Plateforme e-commerce

### Contexte

Une entreprise de commerce en ligne (pure player ou omnicanal) exploite une plateforme web qui génère un chiffre d'affaires directement lié à sa disponibilité et à ses performances. L'équipe technique comprend des développeurs, des ingénieurs SRE et des data engineers. Le trafic est fortement variable avec des pics prévisibles (soldes, Black Friday, Noël) et imprévisibles (campagnes virales, ruptures de stock médiatisées).

### Contraintes métier

Chaque seconde de temps de chargement supplémentaire a un impact mesurable sur le taux de conversion. L'indisponibilité se traduit directement en perte de chiffre d'affaires (chiffrable à la minute). Les pics de trafic de 5 à 20 fois le trafic normal doivent être absorbés sans dégradation visible. La conformité PCI-DSS est requise pour le traitement des paiements.

### Architecture type

L'application est décomposée en microservices déployés sur Kubernetes (cluster managé ou auto-géré sur Debian selon la taille). Chaque service dispose de son pipeline CI/CD avec ArgoCD pour le déploiement GitOps. Le Horizontal Pod Autoscaler (HPA) et le Cluster Autoscaler gèrent l'élasticité automatique pour absorber les pics de trafic.

Le frontend statique est servi par un CDN, et le trafic dynamique passe par un Ingress Controller (Nginx ou Traefik) avec TLS terminé en frontal. Un service mesh Istio ou Linkerd assure le mTLS entre les microservices, le traffic management (canary deployments, circuit breaking) et l'observabilité fine du trafic inter-services.

Les bases de données utilisent des services managés (PostgreSQL, Redis, Elasticsearch) ou des StatefulSets Kubernetes avec stockage distribué (Ceph via Rook) pour les données nécessitant un contrôle total. Le cache distribué (Redis, Memcached) réduit la charge sur les bases de données.

L'observabilité est complète : métriques applicatives et infrastructure avec Prometheus, tracing distribué (instrumentation OpenTelemetry, backend Jaeger ou Tempo) pour identifier les goulots d'étranglement, logs structurés avec Loki, dashboards business temps réel dans Grafana (taux de conversion, panier moyen, erreurs de paiement). Les SLO sont définis sur les parcours critiques (recherche, panier, paiement) avec des error budgets suivis en continu.

La sécurité suit les exigences PCI-DSS : segmentation réseau stricte (Network Policies Kubernetes), chiffrement en transit (mTLS via service mesh) et au repos, gestion des secrets avec Vault, scanning d'images dans le pipeline CI/CD et audit logging complet.

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 3, 5, 6, 7 | Administration système, scripting, réseau, services web |
| 2 | 10, 11, 12, 13 | Conteneurs, Kubernetes production (HPA, RBAC), IaC |
| 3 | 14, 15, 16, 17, 18, 19 | GitOps, observabilité complète, sécurité, service mesh, FinOps, architecture |

### Compétences différenciantes dans ce contexte

La maîtrise de l'autoscaling Kubernetes (module 12) et sa combinaison avec les stratégies FinOps (module 18) pour optimiser le coût tout en garantissant les performances sous pic sont des compétences critiques. Le tracing distribué et les SLO (module 15) permettent de localiser les goulots d'étranglement dans une architecture microservices complexe. Le service mesh (module 17) apporte le mTLS et le traffic management nécessaires à la sécurité et à la fiabilité des déploiements progressifs.

---

## Cas 6 — Laboratoire de recherche ou établissement d'enseignement

### Contexte

Un laboratoire de recherche universitaire ou un département informatique d'école d'ingénieurs gère une infrastructure destinée à la fois à l'enseignement (salles TP, environnements de développement pour les étudiants) et à la recherche (calcul scientifique, traitement de données, hébergement de services collaboratifs). L'équipe informatique est souvent réduite (1 à 3 personnes) et les chercheurs ou enseignants contribuent à l'administration de certains services.

### Contraintes métier

La flexibilité est prioritaire : les besoins évoluent au rythme des projets de recherche et des programmes d'enseignement. Le budget est limité et les investissements passent par des cycles de financement pluriannuels. Les utilisateurs sont techniquement compétents mais ont des besoins très variés (du poste bureautique au cluster de calcul GPU). L'ouverture vers les solutions libres est naturelle dans le milieu académique.

### Architecture type

L'infrastructure combine des postes de travail Debian pour les salles TP et les bureaux des chercheurs, avec un serveur de déploiement PXE pour l'installation automatisée (preseed). La virtualisation KVM/libvirt héberge des environnements de développement et de test reproductibles, complétée par Vagrant pour les TP nécessitant des environnements jetables.

Un cluster K3s léger sur quelques serveurs Debian sert de plateforme de démonstration pour les cours cloud-native et héberge les services internes (GitLab, Nextcloud, wiki). Les étudiants avancés disposent d'environnements Kubernetes dédiés via des namespaces isolés avec des ResourceQuotas.

Les services collaboratifs incluent un serveur de fichiers NFS pour les répertoires partagés, un serveur Git (Gitea ou GitLab) pour les projets étudiants et de recherche, et un serveur web Nginx pour les pages de projets et les publications.

La sauvegarde utilise borgbackup vers un serveur dédié, avec une attention particulière à la sauvegarde des données de recherche (résultats expérimentaux, jeux de données, code source).

### Modules mobilisés

| Parcours | Modules clés | Compétences utilisées |
|----------|-------------|----------------------|
| 1 | 1, 2, 3, 5, 6, 7 | Installation (PXE/preseed), desktop, administration, scripting, réseau, services |
| 2 | 9, 10, 11 | Virtualisation (KVM, Vagrant), conteneurs, K3s |
| 3 | 19 (partiellement) | Architecture poste développeur, environnement K8s local |

### Compétences différenciantes dans ce contexte

La maîtrise de l'installation automatisée (preseed, module 1 et 7) permet de gérer un parc de postes TP de manière efficace. La combinaison virtualisation + conteneurs (modules 9 et 10) offre la flexibilité nécessaire aux projets de recherche variés. La capacité à mettre en place un K3s fonctionnel (module 11) avec des namespaces isolés par groupe d'étudiants et des quotas de ressources démontre un usage pédagogique concret de Kubernetes.

---

## Synthèse transversale

### Modules les plus sollicités par contexte

| Module | Startup | PME industrie | Secteur public | Hébergeur | E-commerce | Recherche |
|--------|:-------:|:------------:|:--------------:|:---------:|:----------:|:---------:|
| 1 — Fondamentaux | ● | ● | ● | ● | ● | ● |
| 3 — Admin système | ● | ● | ● | ● | ● | ● |
| 5 — Scripting | ● | ● | ● | ● | ● | ● |
| 6 — Réseau/sécurité | ● | ● | ● | ● | ● | ● |
| 7 — Server | | ● | ● | ● | | ● |
| 8 — Services avancés/HA | | ● | ● | ● | | |
| 9 — Virtualisation | | ● | ● | ● | | ● |
| 10 — Conteneurs | ● | | | ● | ● | ● |
| 11 — K8s fondamentaux | ● | | | ● | ● | ● |
| 12 — K8s production | ● | | | ● | ● | |
| 13 — IaC | ● | ○ | | ● | ● | |
| 14 — CI/CD GitOps | ● | | | ● | ● | |
| 15 — Observabilité | ● | | | ● | ● | |
| 16 — Sécurité avancée | | | ● | ● | ● | |
| 17 — Cloud/Service Mesh | ● | | | ● | ● | |
| 18 — Edge/FinOps | | | | | ● | |
| 19 — Architectures | ● | | | ● | ● | ○ |

● = compétence centrale pour le contexte, ○ = compétence utile mais secondaire.

### Les quatre compétences universelles

Quel que soit le contexte, quatre compétences reviennent systématiquement comme fondamentales.

**L'administration système Debian** (modules 1, 3) est le socle commun à tous les cas d'usage. Même dans un environnement tout-Kubernetes managé, les nœuds restent des machines Linux qu'il faut savoir diagnostiquer et administrer.

**Le scripting et l'automatisation** (module 5) sont des multiplicateurs de productivité dans tous les contextes. La capacité à automatiser une tâche répétitive, à traiter des logs ou à interagir avec une API libère du temps pour les activités à plus forte valeur ajoutée.

**La sécurité réseau** (module 6) est une obligation dans tous les environnements. La configuration d'un pare-feu, le durcissement SSH et la mise en place de fail2ban sont des compétences de base exigées partout.

**La sauvegarde et la restauration** (module 8) sont le filet de sécurité ultime. La capacité à concevoir une stratégie de sauvegarde adaptée, à l'automatiser et surtout à tester régulièrement la restauration est la compétence qui fait la différence le jour où un incident majeur survient.

---

## Utilisation de cette section

**Pour orienter son parcours** — Un apprenant qui sait dans quel contexte professionnel il évolue (ou souhaite évoluer) peut utiliser les cas d'usage pour identifier les modules les plus pertinents et les compétences à prioriser.

**Pour un entretien d'embauche** — Les architectures décrites ici correspondent aux questions d'entretien typiques (« Comment concevriez-vous l'infrastructure de... ? »). Pouvoir décrire une architecture cohérente, justifier les choix techniques et identifier les compromis démontre une compréhension qui dépasse la maîtrise des outils individuels.

**Pour un projet professionnel** — Les cas d'usage servent de source d'inspiration et de point de départ pour concevoir l'architecture d'un projet réel. Les modules correspondants fournissent les détails techniques pour passer de l'architecture au déploiement.

**Pour un formateur** — Les cas d'usage permettent de contextualiser les modules techniques et de répondre à la question « à quoi ça sert dans la vie réelle ? » qui motive l'apprentissage. Ils peuvent servir de fil conducteur pour un parcours adapté au profil des apprenants.

⏭️ [Sommaire](/SOMMAIRE.md)
