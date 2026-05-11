🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 18.3 Tendances et évolutions

## Introduction

L'écosystème cloud-native évolue à un rythme soutenu. Les technologies qui constituaient l'avant-garde il y a trois ans — Kubernetes, les service meshes, le GitOps — sont aujourd'hui des standards de production adoptés à grande échelle. De nouvelles tendances émergent qui redéfinissent la manière dont les plateformes sont conçues, opérées et consommées par les équipes de développement.

Ces évolutions ne sont pas des curiosités technologiques isolées. Elles répondent à des problèmes concrets que les organisations rencontrent à mesure qu'elles maturent dans leur adoption du cloud-native : la complexité cognitive imposée aux développeurs par l'empilement de couches techniques, le besoin d'observabilité plus profonde sans l'overhead des approches traditionnelles, les limites du modèle de conteneur Linux pour certains workloads, et la convergence des workflows d'infrastructure avec ceux du machine learning et de l'intelligence artificielle.

Cette section présente quatre tendances majeures qui façonnent l'avenir des infrastructures cloud-native en 2026 et au-delà, avec un ancrage systématique dans l'écosystème Debian et Kubernetes couvert par cette formation.

---

## Le contexte : maturité et complexité croissante

### La dette de complexité du cloud-native

L'adoption progressive des technologies couvertes dans les modules précédents — conteneurs (Module 10), Kubernetes (Modules 11-12), Infrastructure as Code (Module 13), CI/CD et GitOps (Module 14), observabilité (Module 15), sécurité (Module 16), service mesh et stockage distribué (Module 17) — a résolu des problèmes fondamentaux de déploiement, de scalabilité et de résilience. Mais cette résolution a un coût : chaque couche ajoutée apporte de la valeur et de la complexité.

Un développeur qui souhaite déployer un nouveau service dans une organisation cloud-native mature doit aujourd'hui écrire un Dockerfile, rédiger des manifestes Kubernetes (Deployment, Service, Ingress, ConfigMap, Secrets), configurer un pipeline CI/CD (build, test, scan, deploy), définir les règles GitOps (ArgoCD Application ou Fleet GitRepo), instrumenter l'application pour l'observabilité (métriques Prometheus, logs structurés, traces OpenTelemetry), configurer les politiques réseau (NetworkPolicies, mTLS via service mesh), spécifier les ressources et quotas (requests, limits, ResourceQuota) et gérer les secrets (Vault, External Secrets Operator).

Ce volume de configuration est incompatible avec la promesse initiale des conteneurs — empaqueter une application et la déployer simplement. La complexité s'est déplacée du déploiement lui-même vers la configuration de l'écosystème qui l'entoure. Ce constat est à l'origine de la première tendance : le Platform Engineering.

### Les limites des approches actuelles

Au-delà de la complexité opérationnelle, plusieurs limites techniques des approches actuelles alimentent les tendances émergentes.

**Observabilité à haute résolution.** Les stacks d'observabilité traditionnelles (Prometheus, Fluent Bit, Jaeger) fonctionnent par instrumentation applicative et scraping périodique. Cette approche a un coût en performance (overhead de l'instrumentation), en complétude (seules les métriques explicitement exposées sont collectées) et en granularité (le scraping à 15 secondes masque les événements sub-seconde). La technologie eBPF permet une observabilité au niveau du noyau, sans modification applicative, avec une granularité et une couverture supérieures.

**Overhead du runtime conteneur.** Les conteneurs Linux partagent le noyau de l'hôte, ce qui est à la fois leur force (légèreté, rapidité de démarrage) et leur limite (surface d'attaque noyau partagée, impossibilité d'exécuter du code non-Linux). WebAssembly (Wasm) émerge comme un runtime alternatif ou complémentaire, offrant une isolation plus fine, un cold start quasi instantané et une portabilité véritablement universelle (indépendante de l'OS et de l'architecture CPU).

**Convergence infrastructure et IA.** L'explosion des workloads d'intelligence artificielle et de machine learning crée de nouveaux besoins d'infrastructure : accès aux GPU/TPU, gestion de datasets volumineux, pipelines d'entraînement distribués, serving de modèles à faible latence. Kubernetes est devenu la plateforme de facto pour l'orchestration de ces workloads, mais les outils et les patterns spécifiques à l'IA/ML (MLOps) constituent un domaine en rapide structuration.

---

## Cartographie des tendances

Les quatre tendances couvertes dans cette section sont interconnectées et se renforcent mutuellement. Elles peuvent être organisées selon deux axes : leur orientation (plutôt orientée développeur ou plutôt orientée infrastructure) et leur maturité (adoption précoce ou adoption généralisée en cours).

**Platform Engineering et portails développeurs (18.3.1).** Tendance organisationnelle et technique visant à réduire la charge cognitive des développeurs en leur offrant une interface unifiée et simplifiée vers l'infrastructure cloud-native. Backstage (projet CNCF) en est l'implémentation de référence. Maturité : adoption généralisée en cours dans les grandes organisations, émergente dans les PME.

**WebAssembly et conteneurs (18.3.2).** Tendance technique explorant l'utilisation de WebAssembly comme runtime alternatif aux conteneurs Linux pour certains workloads, en particulier à l'edge, dans les fonctions serverless et pour les plugins d'infrastructure. Maturité : adoption précoce, spécifications en cours de stabilisation, cas d'usage de production limités mais en croissance.

**eBPF et observabilité nouvelle génération (18.3.3).** Tendance technique qui exploite la programmabilité du noyau Linux via eBPF pour fournir une observabilité sans instrumentation, un réseau plus performant et une sécurité renforcée. Cilium (CNI basé sur eBPF) est déjà un standard de production. Les outils d'observabilité eBPF (Tetragon, Pixie, Parca) gagnent en maturité. Maturité : eBPF pour le réseau est en production généralisée, l'observabilité et la sécurité eBPF sont en adoption rapide.

**IA/ML Ops sur Kubernetes (18.3.4).** Tendance technique et organisationnelle qui structure l'exécution des workloads d'intelligence artificielle sur Kubernetes, de l'entraînement au serving, avec des outils dédiés (Kubeflow, KServe, Ray). Maturité : adoption en forte croissance, tirée par la demande massive de capacité IA/ML.

---

## Pertinence pour l'administrateur Debian et le DevOps/SRE

Ces tendances ne sont pas réservées aux organisations de taille géante ni aux spécialistes d'un domaine pointu. Elles impactent directement le travail quotidien des profils ciblés par cette formation.

**L'administrateur système Debian** (Parcours 1) verra les noyaux Debian embarquer progressivement davantage de fonctionnalités eBPF. La compréhension de cette technologie sera nécessaire pour diagnostiquer les comportements réseau et sécurité des systèmes modernes. Le support WebAssembly côté serveur arrivera dans les dépôts Debian sous forme de runtimes (Wasmtime, WasmEdge).

**L'ingénieur infrastructure** (Parcours 2) sera amené à déployer et opérer des portails développeurs de type Backstage, à configurer Cilium comme CNI eBPF-native dans les clusters Kubernetes, et à gérer des node pools GPU pour les workloads IA/ML.

**Le DevOps/SRE** (Parcours 3) concevra des plateformes internes qui abstraient la complexité de l'infrastructure, exploitera les outils d'observabilité eBPF pour le troubleshooting avancé, évaluera WebAssembly pour les workloads edge et serverless, et structurera les pipelines MLOps sur Kubernetes.

L'objectif de cette section n'est pas de faire de chaque lecteur un expert de ces quatre domaines, mais de fournir une compréhension suffisante des concepts, des outils et des cas d'usage pour évaluer leur pertinence, commencer à les expérimenter et suivre leur évolution de manière éclairée.

---

## Liens avec les modules précédents

Chaque tendance s'appuie sur des fondamentaux couverts dans les modules antérieurs et les prolonge.

**Platform Engineering** s'appuie sur le CI/CD et le GitOps (Module 14), l'observabilité (Module 15), la sécurité (Module 16) et l'Infrastructure as Code (Module 13). Le portail développeur est la couche d'abstraction qui unifie ces briques pour l'utilisateur final.

**WebAssembly** s'inscrit dans la continuité des conteneurs (Module 10) et de Kubernetes à la périphérie (section 18.1). Il propose une alternative ou un complément au modèle de conteneur Linux, avec des implications particulières pour l'edge et le serverless.

**eBPF** prolonge les fondamentaux réseau et sécurité (Module 6), l'observabilité (Module 15) et la sécurité avancée (Module 16). Il fonctionne au niveau du noyau Linux, ce qui le relie directement à l'administration système Debian (Module 3).

**IA/ML Ops** s'appuie sur Kubernetes en production (Module 12), le stockage distribué (Module 17), l'autoscaling (section 12.4) et le GitOps (Module 14) pour orchestrer les workloads spécifiques à l'intelligence artificielle.

---

## Plan de la section

Les sous-sections suivantes explorent chacune de ces tendances en détail :

- **18.3.1 Platform Engineering et portails développeurs (Backstage)** — Le mouvement Platform Engineering, la construction de plateformes internes de développement, le portail Backstage (architecture, plugins, intégration avec Kubernetes et ArgoCD), le concept d'Internal Developer Platform (IDP), les golden paths et les templates de service.

- **18.3.2 WebAssembly (Wasm) et conteneurs** — Les concepts fondamentaux de WebAssembly côté serveur, les runtimes Wasm (Wasmtime, WasmEdge, Spin), l'intégration avec Kubernetes (runwasi, SpinKube), les cas d'usage (edge, serverless, plugins), les limites actuelles et la comparaison avec les conteneurs Linux.

- **18.3.3 eBPF et observabilité nouvelle génération** — L'architecture eBPF dans le noyau Linux, Cilium comme CNI eBPF-native sur Debian, les outils d'observabilité eBPF (Tetragon pour la sécurité runtime, Hubble pour le réseau, Parca pour le profiling continu), et les implications pour le troubleshooting avancé.

- **18.3.4 IA/ML Ops sur Kubernetes (concepts)** — Les concepts du MLOps, les composants d'une plateforme ML sur Kubernetes (Kubeflow, KServe, Ray, MLflow), la gestion des GPU dans Kubernetes, les patterns de serving de modèles, et les interactions entre MLOps et les pratiques DevOps/SRE.

⏭️ [Platform Engineering et portails développeurs (Backstage)](/module-18-edge-finops-tendances/03.1-platform-engineering-backstage.md)
