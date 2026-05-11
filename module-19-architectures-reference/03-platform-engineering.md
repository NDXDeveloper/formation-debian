🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 19.3 Architecture Platform Engineering

## Parcours 3 — De l'infrastructure opérée manuellement à la plateforme en self-service

---

## Objectifs de la section

À l'issue de cette section, vous serez en mesure de :

- Comprendre les principes du Platform Engineering et ce qui le distingue du DevOps traditionnel.
- Concevoir l'architecture d'une Internal Developer Platform (IDP) sur l'infrastructure hybride Debian/Kubernetes construite en section 19.2.
- Identifier les composants d'une plateforme (portail développeur, abstractions, golden paths, garde-fous) et leur articulation.
- Évaluer la maturité Platform Engineering d'une organisation et planifier une adoption progressive.
- Articuler les rôles et responsabilités entre l'équipe plateforme et les équipes de développement.

---

## Pourquoi le Platform Engineering ?

### Le problème que le DevOps seul ne résout pas

Les sections 19.1 et 19.2 ont construit une infrastructure hybride complète : postes développeurs configurés, cluster Kubernetes HA, services intégrés, pipeline CI/CD de bout en bout, runbooks opérationnels. Cette infrastructure est techniquement aboutie — mais elle pose un problème fondamental dès que l'organisation grandit au-delà d'une poignée d'équipes.

Le problème se résume en une phrase : **la charge cognitive imposée aux développeurs est devenue insoutenable**.

Pour déployer une application sur l'infrastructure construite en section 19.2, un développeur doit écrire un Dockerfile optimisé (multi-stage, image slim, scanning), rédiger des manifestes Kubernetes (Deployment, Service, Ingress, ConfigMap, Secret, HPA, PDB, NetworkPolicy), configurer un pipeline `.gitlab-ci.yml` avec les bons stages et les bonnes images, structurer un dépôt GitOps avec des overlays Kustomize par environnement, demander à l'équipe SRE la création d'un namespace avec les bons quotas et les bons RBAC, configurer le monitoring (ServiceMonitor, alertes Prometheus, dashboard Grafana), gérer les certificats TLS et les DNS, et comprendre les politiques de sécurité (Pod Security Standards, Network Policies, scanning d'images).

Chacune de ces tâches est documentée dans les modules précédents de cette formation. Mais leur maîtrise simultanée exige une expertise en infrastructure que la plupart des développeurs applicatifs n'ont pas — et ne devraient pas avoir besoin d'avoir. Leur métier est de concevoir et d'implémenter la logique métier, pas de devenir des experts Kubernetes.

Le mouvement DevOps a rapproché les développeurs de l'exploitation — ce qui était nécessaire et bénéfique. Mais poussé trop loin, le « you build it, you run it » sans accompagnement transforme chaque développeur en administrateur système à temps partiel, avec les résultats prévisibles : configurations copiées-collées sans compréhension entre projets, divergence progressive des pratiques entre équipes, erreurs de sécurité par méconnaissance, temps croissant consacré à la « plomberie » plutôt qu'au développement, et frustration généralisée.

### La réponse du Platform Engineering

Le Platform Engineering propose une approche différente : au lieu de demander à chaque développeur de maîtriser l'ensemble de la stack, une **équipe plateforme dédiée** construit et maintient une couche d'abstraction — l'**Internal Developer Platform (IDP)** — qui expose les capacités de l'infrastructure sous une forme simplifiée, sécurisée et standardisée.

L'IDP n'est pas un outil unique. C'est un ensemble cohérent de services, d'abstractions, de templates et de garde-fous qui permettent aux développeurs de déployer, opérer et observer leurs applications en **self-service**, sans ticket vers l'équipe infrastructure, mais dans un cadre qui garantit la conformité aux standards de l'organisation.

```
AVANT (DevOps sans plateforme)          APRÈS (Platform Engineering)
                                        
Équipe A ──► Kubernetes ──► Infra       Équipe A ──►┐
Équipe B ──► Kubernetes ──► Infra       Équipe B ──►├──► IDP ──► Kubernetes ──► Infra
Équipe C ──► Kubernetes ──► Infra       Équipe C ──►│    (self-service,
Équipe D ──► Kubernetes ──► Infra       Équipe D ──►┘    golden paths,
                                                         garde-fous)
Chaque équipe réinvente la roue.        L'IDP standardise et simplifie.  
Les pratiques divergent.                Les pratiques convergent.  
Les SRE sont un goulot d'étranglement. Les SRE construisent la plateforme.  
```

### Ce que le Platform Engineering n'est pas

Il est important de lever quelques confusions courantes.

Le Platform Engineering **n'est pas un retour aux équipes Ops en silo**. L'objectif n'est pas de recréer une équipe qui fait des choses pour les développeurs, mais une équipe qui construit des outils utilisés par les développeurs. La différence est fondamentale : le self-service élimine les tickets et les files d'attente.

Le Platform Engineering **n'est pas une surcouche obligatoire**. Les développeurs qui veulent descendre dans les couches basses (écrire leurs propres manifestes K8s, configurer leur monitoring finement) doivent pouvoir le faire. La plateforme fournit des **golden paths** (chemins pavés recommandés), pas des cages dorées.

Le Platform Engineering **n'est pas un produit commercial**. Il n'existe pas de solution « clé en main » qui constitue à elle seule une IDP. La plateforme est un assemblage de composants open source et internes, intégrés et adaptés au contexte spécifique de l'organisation. Backstage, ArgoCD, Crossplane, Terraform — ce sont des briques, pas la plateforme.

---

## Principes fondateurs

### La plateforme comme produit

Le premier principe du Platform Engineering est de traiter la plateforme comme un **produit interne** dont les développeurs sont les utilisateurs. Cela implique un changement de posture profond pour les équipes infrastructure.

**Orientée utilisateur.** L'équipe plateforme ne construit pas ce qu'elle trouve techniquement intéressant, mais ce dont les développeurs ont besoin. Elle mène des entretiens avec ses utilisateurs, mesure la satisfaction (enquêtes, NPS interne), observe les points de friction et itère sur ses fonctionnalités.

**Incrémentale.** La plateforme ne naît pas complète. Elle commence par résoudre les problèmes les plus douloureux (par exemple : « il faut 3 jours et 5 tickets pour obtenir un namespace de dev ») et s'enrichit progressivement. Chaque itération apporte une valeur mesurable.

**Documentée et supportée.** La plateforme dispose d'une documentation utilisateur (pas de la documentation d'architecture), d'exemples, de tutoriels et d'un canal de support dédié. Les développeurs ne devraient pas avoir besoin de lire le code de la plateforme pour l'utiliser.

**Mesurée.** L'impact de la plateforme est quantifié : temps de création d'un nouvel environnement (avant/après), nombre de tickets infrastructure (tendance), temps entre le commit et le déploiement en production (lead time), taux d'adoption des golden paths.

### Les golden paths

Les golden paths sont des **workflows pré-construits et recommandés** pour les tâches courantes. Un golden path pour « créer un nouveau microservice » pourrait inclure un template de projet avec le Dockerfile, le `.gitlab-ci.yml`, les manifestes Kubernetes et le monitoring pré-configurés, un script ou une commande CLI qui génère le projet complet à partir de quelques paramètres (nom, langage, type de service), la création automatique du dépôt Git, du pipeline CI/CD, du namespace Kubernetes et des entrées DNS, ainsi que le déploiement automatique d'un environnement de dev fonctionnel en quelques minutes.

Le développeur qui suit le golden path obtient un service déployable en production en une fraction du temps qu'il lui faudrait pour tout configurer manuellement. Et le résultat est conforme aux standards de l'organisation par construction — pas par audit après coup.

Le golden path n'est pas obligatoire. Un développeur expérimenté peut s'en écarter pour des besoins spécifiques. Mais pour 80% des cas, le golden path est le chemin le plus rapide et le plus sûr.

### Les abstractions et les garde-fous

L'IDP expose des **abstractions** qui masquent la complexité sous-jacente tout en préservant la flexibilité. Par exemple, au lieu de demander au développeur de rédiger un Deployment Kubernetes avec 80 lignes de YAML, la plateforme expose un objet simplifié de type :

```yaml
# Ce que le développeur écrit
apiVersion: platform.entreprise.fr/v1  
kind: Application  
metadata:  
  name: mon-api
spec:
  image: mon-api
  replicas: 3
  port: 8080
  env: production
  database: postgresql
  scaling:
    minReplicas: 2
    maxReplicas: 10
    targetCPU: 70
```

En arrière-plan, un opérateur Kubernetes (ou Crossplane, ou un contrôleur custom) transforme cet objet simple en l'ensemble des ressources Kubernetes nécessaires : Deployment, Service, Ingress, HPA, PDB, NetworkPolicy, ServiceMonitor, ConfigMap — le tout conforme aux standards de l'organisation, avec les bonnes pratiques de sécurité appliquées automatiquement.

Les **garde-fous** (guardrails) complètent les abstractions. Ce sont les politiques appliquées automatiquement par la plateforme : tout conteneur doit avoir des limites de ressources, toute communication doit être chiffrée (mTLS), les images doivent être signées et scannées, les secrets ne doivent pas être stockés dans Git. Ces garde-fous ne sont pas des contraintes punitives — ce sont des protections intégrées dans la plateforme qui rendent impossible (ou au moins difficile) de produire un déploiement non conforme.

---

## Architecture de référence de l'IDP

### Vue d'ensemble

L'architecture de l'Internal Developer Platform s'empile sur l'infrastructure hybride construite dans les sections précédentes. Elle ajoute quatre couches au-dessus de Kubernetes :

```
┌─────────────────────────────────────────────────────────────────┐
│                    COUCHE 4 : PORTAIL DÉVELOPPEUR               │
│    Backstage (catalogue de services, templates, documentation)  │
│    Interface web unifiée · CLI plateforme · API self-service    │
├─────────────────────────────────────────────────────────────────┤
│                    COUCHE 3 : ORCHESTRATION APPLICATIVE         │
│    Golden paths · Templates de projets · Scaffolding            │
│    Pipelines CI/CD préconfigurés · Environnements éphémères     │
├─────────────────────────────────────────────────────────────────┤
│                    COUCHE 2 : ABSTRACTIONS ET GARDE-FOUS        │
│    CRDs plateforme · Crossplane · OPA/Kyverno                   │
│    Resource Quotas · Network Policies · Pod Security Standards  │
├─────────────────────────────────────────────────────────────────┤
│                    COUCHE 1 : INFRASTRUCTURE PARTAGÉE           │
│    Kubernetes HA · GitOps (ArgoCD) · Observabilité (Prometheus) │
│    Registry (Harbor) · Secrets (Vault) · Service Mesh           │
│    (= infrastructure 19.2)                                      │
├─────────────────────────────────────────────────────────────────┤
│                    COUCHE 0 : FONDATION                         │
│    Debian bare-metal · Réseau · DNS · DHCP · Mail               │
│    Connectivité hybride · IAM                                   │
│    (= infrastructure 19.2.1 à 19.2.3)                           │
└─────────────────────────────────────────────────────────────────┘
```

**Couche 1 — Infrastructure partagée.** C'est l'infrastructure construite en section 19.2 : le cluster Kubernetes HA, le pipeline CI/CD, le monitoring, le registry, la gestion des secrets. Cette couche est opérée par l'équipe plateforme et n'est pas directement exposée aux développeurs (sauf par nécessité).

**Couche 2 — Abstractions et garde-fous.** Cette couche transforme les primitives Kubernetes brutes en objets de plus haut niveau compréhensibles par les développeurs. Les CRDs (Custom Resource Definitions) définissent le vocabulaire de la plateforme. Les admission controllers (Kyverno, OPA Gatekeeper) appliquent les politiques. Crossplane provisionne les ressources d'infrastructure (bases de données, buckets S3, files de messages) de manière déclarative.

**Couche 3 — Orchestration applicative.** Cette couche fournit les golden paths : les templates de projets, les pipelines CI/CD standardisés, la création d'environnements éphémères pour les pull requests, et l'orchestration du cycle de vie des applications (création, déploiement, scaling, décommissionnement).

**Couche 4 — Portail développeur.** Backstage (ou équivalent) fournit une interface web unifiée qui agrège le catalogue de tous les services de l'organisation, les templates de golden paths, la documentation, les dashboards de santé et les liens vers les outils (GitLab, Grafana, ArgoCD, Vault). C'est la porte d'entrée unique de la plateforme.

### Interactions entre les couches

Le flux typique d'utilisation de la plateforme illustre comment les couches s'articulent :

```
Développeur
    │
    │  1. "Je veux créer un nouveau service API"
    ▼
┌──────────────────────────────────────────┐
│ Backstage (Couche 4)                     │
│ → Catalogue de templates                 │
│ → Sélectionne "API Service (Go)"         │
│ → Renseigne : nom, équipe, base de       │
│   données, environnements cibles         │
└───────────────┬──────────────────────────┘
                │
                │  2. Scaffolding du projet
                ▼
┌──────────────────────────────────────────┐
│ Golden Path (Couche 3)                   │
│ → Crée le dépôt Git avec le code         │
│   squelette, Dockerfile, CI/CD, K8s      │
│ → Crée l'entrée dans le GitOps repo      │
│ → Configure le pipeline GitLab CI        │
│ → Enregistre le service dans Backstage   │
└───────────────┬──────────────────────────┘
                │
                │  3. Provisionnement des ressources
                ▼
┌──────────────────────────────────────────┐
│ Abstractions (Couche 2)                  │
│ → Crossplane provisionne la DB           │
│ → Kyverno applique les politiques        │
│ → ResourceQuota limite les ressources    │
│ → NetworkPolicy isole le namespace       │
└───────────────┬──────────────────────────┘
                │
                │  4. Déploiement effectif
                ▼
┌──────────────────────────────────────────┐
│ Infrastructure (Couche 1)                │
│ → ArgoCD synchronise le namespace        │
│ → Kubernetes déploie les pods            │
│ → Prometheus scrape les métriques        │
│ → Harbor sert les images                 │
└──────────────────────────────────────────┘
                │
                │  5. Résultat
                ▼
Le développeur a un service déployé en dev,  
avec CI/CD, monitoring, database, DNS et  
certificat TLS — en 15 minutes au lieu de 3 jours.  
```

---

## Modèle de maturité

L'adoption du Platform Engineering est un parcours progressif. Vouloir construire une IDP complète dès le premier jour est une erreur courante qui conduit à des plateformes sur-ingéniérées que personne n'utilise. La progression recommandée suit quatre niveaux de maturité.

### Niveau 1 — Templates et documentation

Le point de départ minimal. L'équipe plateforme crée des templates de projets réutilisables (Dockerfile de référence, `.gitlab-ci.yml` standardisé, manifestes Kubernetes de base) et une documentation opérationnelle (« comment déployer un service »). Les développeurs copient les templates et les adaptent. La standardisation est encouragée mais pas imposée.

Ce niveau apporte déjà une valeur significative : il réduit le temps de démarrage d'un projet et établit des conventions partagées. Il est atteignable en quelques semaines avec les outils déjà en place (GitLab, Kubernetes).

### Niveau 2 — Self-service automatisé

Les templates deviennent des workflows automatisés. Le développeur ne copie plus un template — il remplit un formulaire ou exécute une commande CLI, et la plateforme génère automatiquement le projet, le pipeline, le namespace et les ressources associées. Les garde-fous (admission controllers, politiques de sécurité) sont déployés et appliqués de manière automatique.

Ce niveau nécessite un investissement plus important : mise en place de Backstage ou d'un outil de scaffolding, déploiement de Kyverno ou OPA Gatekeeper, création de CRDs ou d'opérateurs custom. Il est atteignable en quelques mois.

### Niveau 3 — Abstractions et composition

La plateforme expose des abstractions de haut niveau (CRDs, Crossplane compositions) qui masquent la complexité Kubernetes. Les développeurs décrivent ce qu'ils veulent (« un service API avec une base PostgreSQL et un cache Redis ») et la plateforme gère le comment. Les environnements éphémères par pull request sont automatisés. Le catalogue de services dans Backstage est alimenté automatiquement.

Ce niveau est celui d'une IDP mature. Il nécessite un investissement significatif de l'équipe plateforme et une adoption progressive par les équipes de développement. Délai typique : 6 mois à 1 an.

### Niveau 4 — Plateforme autonome et mesurée

La plateforme s'auto-adapte : scaling automatique des ressources, optimisation des coûts (FinOps intégré), détection proactive des problèmes, recommandations automatisées. Les métriques DORA sont collectées et affichées par équipe. La plateforme mesure son propre impact (temps gagné, incidents évités, satisfaction développeur).

Ce niveau est l'aboutissement du Platform Engineering. Il est rarement atteint dans sa totalité, mais chaque élément peut être ajouté indépendamment.

---

## Rôles et responsabilités

### L'équipe plateforme

L'équipe plateforme (parfois appelée Platform Team ou Infrastructure Product Team) est responsable de la construction et de la maintenance de l'IDP. Son profil type combine des compétences SRE (Kubernetes, infrastructure, observabilité), des compétences de développement (pour construire les outils, les opérateurs, les intégrations) et une sensibilité produit (pour comprendre les besoins des utilisateurs et prioriser les fonctionnalités).

L'équipe plateforme **possède** la couche 1 (infrastructure) et la couche 2 (abstractions et garde-fous), **construit et maintient** la couche 3 (golden paths et orchestration) et la couche 4 (portail), et **supporte** les équipes de développement dans leur utilisation de la plateforme.

L'équipe plateforme **ne fait pas** les déploiements applicatifs (c'est le self-service), **ne développe pas** la logique métier des applications, et **ne gère pas** les incidents applicatifs (elle gère les incidents d'infrastructure et de plateforme).

### Les équipes de développement

Les développeurs sont les utilisateurs de la plateforme. Ils sont responsables du code applicatif et de son cycle de vie, du choix d'utiliser les golden paths (recommandé) ou de configurer manuellement (possible), du monitoring applicatif (métriques métier, alertes applicatives) et de la réponse aux incidents de leurs services.

### Le contrat entre les deux

La relation entre l'équipe plateforme et les équipes de développement est formalisée par un contrat implicite ou explicite.

L'équipe plateforme garantit la disponibilité de l'infrastructure et des services de plateforme (SLO définis), fournit les golden paths et les outils de self-service, applique les garde-fous de sécurité et de conformité de manière transparente, et offre un canal de support pour les questions et les problèmes.

Les équipes de développement suivent les conventions de la plateforme (nomenclature, structure des projets, politiques de déploiement), utilisent les golden paths sauf besoin justifié de s'en écarter, et sont responsables de la santé de leurs applications une fois déployées.

---

## Positionnement dans la formation

Cette section mobilise la quasi-totalité des compétences acquises dans les trois parcours de la formation. Le tableau ci-dessous illustre comment chaque composant de la plateforme s'appuie sur les modules précédents :

| Composant IDP | Modules mobilisés | Section de référence |
|---|---|---|
| Infrastructure Kubernetes | Modules 11, 12 | 19.2.2 |
| Pipeline CI/CD et GitOps | Module 14 | 19.2.4 |
| Observabilité | Module 15 | 19.2.3, 19.2.4 |
| Sécurité et politiques | Module 16 | 19.2.2, 19.2.4 |
| Service Mesh | Module 17 | — |
| Backstage et portail | Module 18.3.1 (Platform Engineering & Backstage) | 19.3.1 |
| Multi-tenancy et isolation | Module 12 | 19.3.4 |
| IaC (Terraform, Ansible) | Module 13 | 19.2.1 |
| Conteneurs et images | Module 10 | 19.2.4 |

---

## Plan de la section

Cette section se décompose en quatre sous-parties qui détaillent chaque aspect de l'architecture Platform Engineering :

- **19.3.1 — Plateforme interne de développement** : déploiement de Backstage, catalogue de services, templates de golden paths, intégration avec GitLab et Kubernetes, CLI plateforme.

- **19.3.2 — Self-service portal et developer experience** : provisionnement automatisé de projets et d'environnements, environnements éphémères par pull request, abstractions applicatives, documentation intégrée et developer experience.

- **19.3.3 — GitOps workflow complet** : architecture GitOps multi-équipes, gestion des configurations par environnement, promotion automatisée, gestion des secrets dans le workflow GitOps, observabilité du déploiement.

- **19.3.4 — Multi-tenancy, isolation et policy enforcement** : isolation des namespaces et des ressources, ResourceQuotas et LimitRanges par équipe, Network Policies automatiques, politiques de sécurité via Kyverno/OPA, modèle de coût et chargeback par équipe.

---

*Prérequis : Parcours 2 complet (Modules 9 à 13), sections 19.2.1 à 19.2.5 (architecture hybride), Module 14 (CI/CD et GitOps), Module 16 (sécurité), Module 18.3.1 (Platform Engineering & Backstage — concepts).*

⏭️ [Plateforme interne de développement](/module-19-architectures-reference/03.1-plateforme-interne.md)
