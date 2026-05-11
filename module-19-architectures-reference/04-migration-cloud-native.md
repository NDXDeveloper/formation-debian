🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 19.4 Architecture de migration cloud-native

## Parcours 3 — Transformer une application monolithique legacy en un système cloud-native sur Kubernetes

---

## Objectifs de la section

À l'issue de cette section, vous serez en mesure de :

- Évaluer une application legacy et déterminer la stratégie de migration la plus adaptée à son contexte.
- Planifier et exécuter une migration progressive, du monolithe on-premise vers une architecture conteneurisée et orchestrée sur Kubernetes.
- Identifier les risques, les prérequis et les critères de succès à chaque étape de la migration.
- Articuler les phases techniques (conteneurisation, refactoring, déploiement) avec les réalités organisationnelles (compétences, budget, continuité de service).
- Valider la migration par le monitoring, les tests de performance et la comparaison avec le système d'origine.

---

## Le contexte de la migration

### La réalité des applications legacy

La grande majorité des organisations ne partent pas d'une feuille blanche. Elles opèrent des applications construites il y a 5, 10 ou 20 ans, qui représentent un investissement considérable en développement, en données accumulées et en connaissance métier. Ces applications — souvent qualifiées de « legacy » — fonctionnent. Elles rendent le service pour lequel elles ont été conçues. Mais elles posent des problèmes croissants.

Un **monolithe LAMP typique** (Linux, Apache, MySQL, PHP) déployé sur un serveur Debian bare-metal illustre ces problèmes. Le déploiement est manuel ou semi-automatisé : un administrateur copie les fichiers via rsync, exécute les migrations de base de données à la main, redémarre Apache et vérifie que rien n'est cassé. Les mises à jour sont risquées car il n'y a pas de rollback automatique ; en cas de problème, l'administrateur doit restaurer les fichiers et la base de données manuellement, ce qui prend du temps et peut entraîner une perte de données.

La **scalabilité** est limitée : pour absorber plus de trafic, il faut dimensionner un serveur plus puissant (scaling vertical) ou dupliquer l'application entière derrière un load balancer (scaling horizontal coûteux et complexe). L'**observabilité** est rudimentaire : des logs dans des fichiers, peut-être un Nagios qui vérifie si le port 80 répond. La **résilience** est faible : si le serveur tombe, l'application est indisponible jusqu'à l'intervention d'un administrateur.

Et pourtant, cette application traite les commandes de l'entreprise, gère les dossiers clients ou fait tourner le système de facturation. On ne peut pas la supprimer et la réécrire de zéro — le risque métier est trop élevé et le coût prohibitif.

### Pourquoi migrer ?

La migration cloud-native n'est pas une fin en soi. Elle se justifie par des bénéfices concrets et mesurables.

**La vélocité de livraison.** Sur une application cloud-native, un développeur peut livrer un changement en production plusieurs fois par jour, avec un pipeline CI/CD automatisé, des tests de non-régression et un rollback en un clic. Sur un monolithe legacy, un cycle de release mensuel ou trimestriel est la norme.

**La résilience.** Une application cloud-native sur Kubernetes redémarre automatiquement en cas de crash, se distribue sur plusieurs nœuds pour tolérer la perte d'un serveur, et se scale horizontalement pour absorber les pics de charge. Un monolithe legacy est un single point of failure.

**L'efficience opérationnelle.** L'infrastructure cloud-native (conteneurs, orchestration, IaC, GitOps) est gérée par des processus automatisés et reproductibles. L'infrastructure legacy repose sur des connaissances tacites et des opérations manuelles.

**L'intégration dans la plateforme.** Une application migrée bénéficie de tout l'écosystème construit dans les sections précédentes : monitoring Prometheus/Grafana, déploiement GitOps, self-service Backstage, sécurité Kyverno, gestion des secrets Vault.

Mais ces bénéfices ont un coût. La migration consomme du temps d'ingénierie, introduit temporairement de la complexité (deux systèmes à opérer en parallèle) et comporte des risques (régressions, perte de performance, interruptions de service). La décision de migrer — et le choix de la stratégie — doivent être fondés sur une analyse rigoureuse du rapport bénéfice/risque.

---

## Les stratégies de migration : les 6 R

Le framework des « 6 R », popularisé par AWS mais applicable à toute migration, identifie six stratégies de migration, classées par ordre croissant de transformation.

> **Note 2026 — du « 6 R » au « 7 R »** : à l'origine, Gartner avait proposé 5 stratégies. AWS a ajouté **Retire** pour porter le framework à 6 R, puis **Relocate** pour atteindre 7 R. La stratégie **Relocate** consiste à migrer une infrastructure virtualisée existante (typiquement un cluster VMware) vers le même hyperviseur en cloud (VMware Cloud on AWS, par exemple), sans modifier les machines virtuelles. Cette stratégie est peu pertinente pour la migration cible de cette formation (passage de bare-metal Debian vers conteneurs Kubernetes), c'est pourquoi nous nous concentrons sur les 6 R historiques. Si votre organisation gère un parc VMware significatif et envisage un cloud public, examinez aussi Relocate.

### Retain (conserver)

La décision de ne pas migrer. L'application reste sur son infrastructure actuelle, telle quelle. Cette stratégie est appropriée quand l'application est en fin de vie et sera décommissionnée dans un avenir proche, quand le coût de migration dépasse les bénéfices attendus, ou quand des contraintes techniques rendent la migration impossible (dépendance matérielle, logiciel propriétaire non conteneurisable).

Le « retain » n'est pas un échec — c'est une décision consciente et documentée. L'application conservée doit néanmoins être intégrée au monitoring global (exporters Prometheus, cf. section 19.2.3) et à la sauvegarde centralisée.

### Retire (décommissionner)

L'application est identifiée comme obsolète et retirée. Ses fonctionnalités sont soit abandonnées (plus personne ne les utilise), soit absorbées par un autre système. Le décommissionnement nécessite un inventaire précis des dépendants de l'application (qui l'appelle ? qui consulte ses données ?), un plan de migration des données à conserver, une période de coexistence avec redirection du trafic, et une communication aux utilisateurs.

### Rehost (lift and shift)

L'application est migrée telle quelle vers un conteneur ou une machine virtuelle dans le cloud/sur Kubernetes, sans modification du code. Le serveur Debian + Apache + PHP + MySQL devient un conteneur Docker avec la même stack, déployé comme un pod Kubernetes.

```
AVANT                          APRÈS (rehost)
┌──────────────────┐          ┌──────────────────────────┐
│ Serveur Debian   │          │ Pod Kubernetes           │
│                  │          │ ┌────────────────────┐   │
│ Apache + PHP     │   ──►    │ │ Conteneur Apache   │   │
│ MySQL local      │          │ │ + PHP + app code   │   │
│ Fichiers app     │          │ └────────────────────┘   │
│ Cron jobs        │          │ ┌────────────────────┐   │
│ Logs dans /var   │          │ │ Conteneur MySQL    │   │
└──────────────────┘          │ │ (ou service managé)│   │
                              │ └────────────────────┘   │
                              └──────────────────────────┘
```

Le rehost apporte un bénéfice immédiat : l'application bénéficie de la gestion Kubernetes (redémarrage automatique, scheduling, rolling updates) et s'intègre dans le pipeline CI/CD. Mais elle conserve ses limitations architecturales (monolithe, scaling limité).

Le rehost est la stratégie la moins risquée et la plus rapide à exécuter. C'est souvent la première étape d'une migration progressive : d'abord lift and shift, puis modernisation itérative.

### Replatform (lift, tinker and shift)

L'application est migrée avec des modifications mineures pour tirer parti de l'environnement cible. Par exemple : remplacer MySQL local par un service de base de données managé ou un pod PostgreSQL géré par Crossplane, externaliser les sessions dans Redis (au lieu du filesystem local), envoyer les logs vers stdout/stderr (au lieu de fichiers) pour l'intégration avec la stack de logs Kubernetes, et remplacer les cron jobs système par des CronJobs Kubernetes.

Le replatform offre un meilleur rapport bénéfice/effort que le rehost pur, sans nécessiter une réécriture. Les modifications sont ciblées et à faible risque.

### Refactor (re-architecturer)

L'application est partiellement ou totalement réécrite pour adopter une architecture cloud-native : décomposition en microservices, communication asynchrone via des files de messages, API RESTful ou gRPC, stockage distribué. C'est la stratégie la plus bénéfique à long terme, mais aussi la plus coûteuse et la plus risquée.

Le refactor n'est justifié que si l'application a une durée de vie longue devant elle, si les limitations architecturales du monolithe bloquent l'évolution métier, et si l'équipe a les compétences et le temps nécessaires.

La bonne pratique est le **refactoring progressif** (le « Strangler Fig Pattern ») : les nouvelles fonctionnalités sont développées en microservices, et les fonctionnalités existantes sont extraites du monolithe une par une, sur une période de plusieurs mois. Le monolithe et les microservices coexistent derrière un reverse proxy ou un API gateway, et le monolithe rétrécit progressivement.

### Repurchase (remplacer)

L'application est remplacée par un SaaS ou un logiciel standard. Par exemple, un CRM développé en interne est remplacé par Salesforce, ou un outil de gestion de projet interne est remplacé par Jira. Cette stratégie est hors du scope technique de cette formation (c'est une décision métier), mais elle doit être envisagée systématiquement lors de l'inventaire des applications candidates à la migration.

---

## Évaluation et priorisation

### Inventaire des applications

La première étape d'un programme de migration est l'inventaire exhaustif des applications existantes. Pour chaque application, les informations suivantes sont collectées :

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FICHE D'INVENTAIRE APPLICATION                   │
├─────────────────────────────────────────────────────────────────────┤
│ Nom : Application de gestion des commandes                          │
│ ID technique : app-commandes-legacy                                 │
│ Équipe propriétaire : equipe-commerce                               │
│                                                                     │
│ ─── Architecture ───                                                │
│ Type : Monolithe                                                    │
│ Langage : PHP 7.4 / Symfony 4                                       │
│ Base de données : MySQL 5.7 (local)                                 │
│ Stockage : Fichiers uploadés dans /var/www/uploads (15 Go)          │
│ Sessions : Filesystem local                                         │
│ Cache : Aucun (requêtes DB directes)                                │
│ Tâches planifiées : 3 cron jobs (nettoyage, rapports, sync)         │
│                                                                     │
│ ─── Infrastructure actuelle ───                                     │
│ Serveur : Debian 11, 4 CPU, 8 Go RAM, 200 Go SSD                    │
│ Serveur web : Apache 2.4 + mod_php                                  │
│ Réseau : IP interne 10.1.5.20, VLAN production                      │
│ Backup : rsync quotidien vers serveur de backup                     │
│                                                                     │
│ ─── Dépendances ───                                                 │
│ Consomme : API legacy ERP (SOAP, sur mainframe)                     │
│ Expose : Interface web (port 443), API REST (port 8443)             │
│ Intégrations : LDAP pour l'authentification, SMTP pour les notifs   │
│ Volumes de données : ~500 000 lignes, ~2 Go                         │
│                                                                     │
│ ─── Métriques opérationnelles ───                                   │
│ Disponibilité (12 mois) : 99.2% (3 incidents majeurs)               │
│ Trafic : ~200 req/min en pointe, ~50 req/min moyen                  │
│ Temps de réponse : p50=120ms, p95=850ms, p99=2.5s                   │
│ Fréquence de release : ~1 release/mois                              │
│ Temps de déploiement : ~45 minutes (manuel)                         │
│ Dernier incident : perte de service 2h (crash MySQL, 2026-02-14)    │
│                                                                     │
│ ─── Évaluation ───                                                  │
│ Criticité métier : Haute                                            │
│ Durée de vie restante : > 5 ans                                     │
│ Complexité de migration : Moyenne                                   │
│ Stratégie recommandée : Replatform → Refactor progressif            │
│ Priorité de migration : P1                                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Matrice de priorisation

Les applications inventoriées sont classées selon deux axes : la **valeur de la migration** (bénéfice attendu) et la **complexité de la migration** (effort et risque).

```
        Valeur de la migration
        ▲
  Haute │  ┌──────────────┐    ┌──────────────┐
        │  │  QUICK WINS  │    │ PROJETS      │
        │  │  (P1)        │    │ STRATÉGIQUES │
        │  │              │    │ (P2)         │
        │  │  Valeur haute│    │ Valeur haute │
        │  │  Complexité  │    │ Complexité   │
        │  │  faible      │    │ élevée       │
        │  └──────────────┘    └──────────────┘
        │
        │  ┌──────────────┐    ┌──────────────┐
        │  │ AMÉLIORATIONS│    │  LAISSER     │
        │  │ OPPORTUNISTES│    │  EN PLACE    │
        │  │ (P3)         │    │  (Retain)    │
  Basse │  │              │    │              │
        │  │ Valeur faible│    │ Valeur faible│
        │  │ Complexité   │    │ Complexité   │
        │  │ faible       │    │ élevée       │
        │  └──────────────┘    └──────────────┘
        │
        └──────────────────────────────────────►
              Faible              Élevée
              Complexité de la migration
```

**Quick wins (P1)** — Applications à haute valeur et faible complexité. Ce sont les premières candidates : leur migration apporte des bénéfices rapides et visibles, ce qui renforce la confiance dans le programme de migration. Typiquement : applications web stateless ou quasi-stateless, services avec peu de dépendances, applications déjà partiellement conteneurisées.

**Projets stratégiques (P2)** — Applications à haute valeur mais complexité élevée. Leur migration nécessite un investissement significatif mais se justifie par l'ampleur des bénéfices. Ce sont des projets à planifier soigneusement, avec des phases intermédiaires (rehost d'abord, puis refactor). Typiquement : monolithes métier critiques, applications avec de nombreuses dépendances.

**Améliorations opportunistes (P3)** — Applications à faible valeur et faible complexité. Elles sont migrées quand l'occasion se présente (mise à jour majeure, changement d'équipe, refonte fonctionnelle planifiée) mais ne justifient pas un effort dédié.

**Retain** — Applications à faible valeur et complexité élevée. Le coût de migration dépasse les bénéfices. Elles restent en place et sont intégrées au monitoring global.

---

## Les phases de la migration

### Vue d'ensemble du processus

La migration d'une application suit un processus en quatre phases, chacune avec ses livrables, ses risques et ses critères de passage à la phase suivante.

```
Phase 1                Phase 2                Phase 3              Phase 4
ÉVALUER                CONTENEURISER          DÉPLOYER             OPTIMISER
                                                                    
┌────────────┐         ┌───────────┐          ┌───────────┐         ┌──────────┐
│ Inventaire │         │ Dockerfile│          │ Manifestes│         │ Refactor │
│ Dépendances│         │ CI/CD     │          │ K8s       │         │ Scale    │
│ Stratégie  │         │ Tests     │          │ GitOps    │         │ Observe  │
│ Risques    │         │ Migration │          │ Bascule   │         │ Iterate  │
│            │         │ données   │          │ trafic    │         │          │
└─────┬──────┘         └─────┬─────┘          └─────┬─────┘         └──────────┘
      │                      │                      │
      │ Go/No-Go             │ Go/No-Go             │ Go/No-Go
      │ Fiche inventaire     │ Image fonctionnelle  │ Trafic 100%
      │ Stratégie validée    │ Tests passent        │ sur K8s
      ▼                      ▼                      ▼
```

**Phase 1 — Évaluer** (1-2 semaines par application). Collecter les informations de la fiche d'inventaire. Identifier toutes les dépendances (entrantes et sortantes). Choisir la stratégie de migration (rehost, replatform, refactor). Identifier les risques et les mitigations. Définir les critères de succès mesurables. Estimer l'effort et le planning.

**Phase 2 — Conteneuriser** (2-4 semaines). Écrire le Dockerfile. Adapter l'application pour le runtime conteneurisé (logs, sessions, configuration). Mettre en place le pipeline CI/CD. Exécuter les tests de non-régression. Planifier la migration des données.

**Phase 3 — Déployer** (1-2 semaines). Écrire les manifestes Kubernetes. Intégrer dans le workflow GitOps (ArgoCD). Déployer en parallèle de l'application existante. Basculer le trafic progressivement. Valider par le monitoring et les tests.

**Phase 4 — Optimiser** (continu). Refactorer les composants qui le justifient. Optimiser les performances et les ressources. Intégrer les fonctionnalités de la plateforme (autoscaling, observabilité avancée, self-service). Décommissionner l'ancienne infrastructure.

### Coexistence pendant la migration

Pendant la migration, l'ancienne application (on-premise, bare-metal) et la nouvelle (Kubernetes) coexistent. Le reverse proxy Nginx (cf. section 19.2.3) gère la bascule progressive du trafic :

```
Clients
  │
  ▼
┌───────────────────────────────────┐
│ Reverse Proxy (Nginx)             │
│                                   │
│ Phase 1: 100% → Legacy            │
│ Phase 2:  90% → Legacy            │
│           10% → Kubernetes        │
│ Phase 3:  50% → Legacy            │
│           50% → Kubernetes        │
│ Phase 4:   0% → Legacy            │
│          100% → Kubernetes        │
│                                   │
│ Comparaison : latence, erreurs,   │
│ fonctionnel — à chaque phase      │
└───────┬───────────────┬───────────┘
        │               │
        ▼               ▼
┌──────────────┐  ┌──────────────┐
│ Legacy       │  │ Kubernetes   │
│ (Debian BM)  │  │ (Pods)       │
│              │  │              │
│ Base MySQL   │  │ Base PG/MySQL│
│ (source)     │  │ (répliquée)  │
└──────────────┘  └──────────────┘
```

Cette coexistence implique une gestion rigoureuse de la cohérence des données entre les deux systèmes. Les stratégies de synchronisation de données (réplication, double écriture, migration par batch) sont un aspect critique de chaque migration.

---

## Positionnement dans la formation

Cette section est la synthèse finale du Parcours 3. Elle mobilise la quasi-totalité des compétences acquises dans les 18 modules précédents et dans les sections 19.1 à 19.3 :

| Phase de migration | Modules et sections mobilisés |
|---|---|
| Évaluation de l'application | Module 3 (administration système), Module 7 (services), Module 15 (observabilité) |
| Conteneurisation | Module 10 (conteneurs, Dockerfile, images), Module 5 (scripting) |
| Pipeline CI/CD | Module 14 (CI/CD, GitOps), section 19.2.4 (pipeline complet) |
| Déploiement Kubernetes | Modules 11-12 (K8s), section 19.2.2 (cluster HA) |
| Migration de données | Module 7 (bases de données), Module 8 (sauvegarde) |
| Monitoring et validation | Module 15 (observabilité), section 19.2.3 (monitoring intégré) |
| Intégration plateforme | Section 19.3 (Platform Engineering) |
| Réseau et sécurité | Module 6 (réseau), Module 16 (sécurité), section 19.2.1 (hybride) |
| Infrastructure as Code | Module 13 (Ansible, Terraform) |

---

## Plan de la section

Cette section se décompose en quatre sous-parties qui suivent les phases de la migration :

- **19.4.1 — Modernisation d'une application legacy** : évaluation détaillée d'un monolithe LAMP, analyse des dépendances, choix de la stratégie, préparation de l'application pour la conteneurisation (externalisation de la configuration, des sessions, des logs).

- **19.4.2 — Conteneurisation et refactoring en microservices** : écriture du Dockerfile, construction du pipeline CI/CD, adaptation de l'application, Strangler Fig Pattern pour le refactoring progressif, gestion des données d'état.

- **19.4.3 — Stratégies de migration zero-downtime** : déploiement en parallèle, bascule progressive du trafic, synchronisation des données, rollback, critères de bascule définitive.

- **19.4.4 — Monitoring, performance testing et optimisation** : validation de la migration par les métriques, tests de charge comparatifs, optimisation des ressources Kubernetes, intégration dans la plateforme, décommissionnement de l'ancien système.

---

*Prérequis : Parcours 2 complet, sections 19.2 et 19.3 (architecture hybride et Platform Engineering), Module 7 (services serveur), Module 10 (conteneurs), Module 14 (CI/CD).*

⏭️ [Modernisation d'une application legacy](/module-19-architectures-reference/04.1-modernisation-legacy.md)
