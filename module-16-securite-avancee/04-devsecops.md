🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 16.4 DevSecOps

## Prérequis

- Maîtrise du hardening système Debian (section 16.1) et de la sécurité Kubernetes (section 16.2)
- Connaissance de la gestion des secrets et du chiffrement (section 16.3)
- Expérience avec les pipelines CI/CD (module 14) et les pratiques GitOps (section 14.4)
- Familiarité avec la conteneurisation et la construction d'images (module 10)
- Connaissance des principes de la sécurité des conteneurs (section 10.5)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre la philosophie DevSecOps et son intégration dans le cycle de développement logiciel
- Intégrer des outils d'analyse de sécurité (SAST, DAST, SCA) dans les pipelines CI/CD
- Sécuriser la chaîne d'approvisionnement logicielle avec la signature d'images, les SBOM et la vérification de provenance
- Automatiser les vérifications de conformité et les intégrer dans les workflows de déploiement
- Mettre en place un système de détection d'intrusion et de réponse aux incidents

---

## Introduction

Les trois sections précédentes de ce module ont couvert la sécurité sous l'angle de l'infrastructure : durcissement du système d'exploitation (16.1), sécurité du cluster Kubernetes (16.2), gestion des secrets et chiffrement (16.3). Ces mécanismes protègent la plateforme sur laquelle les applications s'exécutent. Mais la surface d'attaque la plus vaste et la plus dynamique n'est pas l'infrastructure — ce sont les **applications elles-mêmes** et la **chaîne qui les produit** : le code source, les dépendances, les images de conteneurs, les pipelines de build, les artefacts de déploiement.

**DevSecOps** est l'intégration de la sécurité dans chaque étape du cycle de vie du logiciel, depuis l'écriture du code jusqu'à l'exploitation en production. Le terme fusionne trois disciplines qui, historiquement, fonctionnaient en silos :

- **Dev** (développement) : écriture du code, choix des dépendances, construction des images
- **Sec** (sécurité) : analyse des vulnérabilités, conformité, réponse aux incidents
- **Ops** (opérations) : déploiement, monitoring, maintenance

L'approche traditionnelle — où la sécurité intervient en fin de cycle, juste avant la mise en production, sous la forme d'un audit ou d'un pentest ponctuel — ne fonctionne pas dans un environnement cloud-native où les déploiements se font plusieurs fois par jour. Le DevSecOps remplace ce modèle par une sécurité **continue**, **automatisée** et **intégrée**, qui détecte les problèmes au plus tôt (*shift-left*) et surveille en continu en production (*shift-right*).

## Le modèle shift-left / shift-right

### Shift-left : détecter au plus tôt

Le concept de **shift-left** consiste à déplacer les vérifications de sécurité le plus à gauche possible dans le cycle de développement — c'est-à-dire le plus tôt possible. Plus un problème de sécurité est détecté tard, plus il est coûteux à corriger :

```
Coût de correction d'une vulnérabilité (ordre de grandeur)

  Phase           │  Coût relatif  │  Exemple
  ────────────────┼────────────────┼──────────────────────────
  Développement   │      1x        │  Le développeur corrige
  (IDE, commit)   │                │  immédiatement
                  │                │
  CI/CD           │      5x        │  Le pipeline bloque,
  (build, test)   │                │  le dev doit revenir
                  │                │  sur sa modification
                  │                │
  Staging         │     15x        │  Bug trouvé en recette,
  (pré-prod)      │                │  cycle de correction
                  │                │
  Production      │     50x        │  Incident en prod,
  (runtime)       │                │  mobilisation d'équipe
                  │                │
  Post-incident   │    100x+       │  Fuite de données,
  (compromission) │                │  impact réglementaire,
                  │                │  image de marque
```

Le shift-left se concrétise par l'intégration d'outils de sécurité à chaque étape :

```
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  CODE   │  │  BUILD  │  │  TEST   │  │ DEPLOY  │  │   RUN   │
│         │  │         │  │         │  │         │  │         │
│ IDE     │  │ SAST    │  │ DAST    │  │ Signing │  │ Falco   │
│ Linting │  │ SCA     │  │ Pentest │  │ Verify  │  │ SIEM    │
│ Secrets │  │ Image   │  │ Fuzzing │  │ Policy  │  │ IDS/IPS │
│ scan    │  │ scan    │  │         │  │ check   │  │ Audit   │
│         │  │ SBOM    │  │         │  │         │  │         │
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │            │
     └────────────┴────────────┴────────────┴────────────┘
                    ◄── Shift-left ──►  ◄── Shift-right ──►
                    Détecter tôt          Surveiller en continu
```

### Shift-right : surveiller en continu

Le shift-left ne suffit pas à lui seul. Certaines vulnérabilités ne sont découvertes qu'après le déploiement (zero-days, nouvelles CVE affectant des dépendances déjà en production, comportements anormaux non détectables statiquement). Le **shift-right** complète le shift-left avec une surveillance continue en production :

- **Falco** (section 16.2.4) détecte les comportements anormaux au runtime
- Les **scanners d'images en continu** réévaluent les images déployées contre les nouvelles CVE publiées
- Les **SIEM** (Security Information and Event Management) corrèlent les événements de sécurité provenant de toutes les couches
- Les **IDS/IPS** (Intrusion Detection/Prevention Systems) surveillent le trafic réseau pour détecter les patterns d'attaque connus

## La chaîne d'approvisionnement logicielle (Software Supply Chain)

### L'importance de la supply chain

Les attaques contre la chaîne d'approvisionnement logicielle sont devenues l'un des vecteurs d'attaque les plus redoutables. Au lieu de cibler directement l'application ou l'infrastructure, l'attaquant compromet un composant en amont — une dépendance open source, un outil de build, une image de base, un pipeline CI/CD — et le code malveillant se propage automatiquement vers toutes les applications qui en dépendent.

Les incidents récents ont démontré la réalité de cette menace : des bibliothèques npm populaires piégées par des mainteneurs compromis, des images Docker officielles contenant des malwares, des pipelines CI/CD dont les runners ont été utilisés comme point d'entrée vers des infrastructures de production. La sécurité de la supply chain ne peut plus être traitée comme un sujet secondaire.

### Points de compromission

La supply chain logicielle dans un environnement Debian/Kubernetes présente de multiples points de compromission :

```
    Code source               Dépendances              Build
    ┌─────────┐              ┌──────────────┐         ┌──────────┐
    │ Dépôt   │              │ Bibliothèques│         │ Pipeline │
    │ Git     │              │ (npm, pip,   │         │ CI/CD    │
    │         │              │  Go modules) │         │          │
    │ ⚠ Code  │              │              │         │ ⚠ Runner │
    │ malveil-│              │ ⚠ Dépendance │         │ compromis│
    │ lant    │              │ piégée       │         │          │
    │ injecté │              │ (typosquat,  │         │ ⚠ Secrets│
    │         │              │  mainteneur  │         │ exposés  │
    └────┬────┘              │  compromis)  │         └────┬─────┘
         │                   └──────┬───────┘              │
         │                          │                      │
         └──────────┬───────────────┴──────────────────────┘
                    │
                    ▼
    Image conteneur              Registry              Déploiement
    ┌─────────────┐            ┌──────────┐          ┌──────────┐
    │ Dockerfile  │            │ Registry │          │ Manifeste│
    │             │            │ privé    │          │ K8s      │
    │ ⚠ Image de  │            │          │          │          │
    │ base compro-│            │ ⚠ Image  │          │ ⚠ Image  │
    │ mise        │            │ altérée  │          │ non      │
    │             │            │ après    │          │ vérifiée │
    │ ⚠ Secrets   │            │ push     │          │ déployée │
    │ dans le     │            │          │          │          │
    │ layer       │            │          │          │          │
    └─────────────┘            └──────────┘          └──────────┘
```

### Le cadre SLSA

**SLSA** (Supply-chain Levels for Software Artifacts, prononcé « salsa ») est un framework de sécurité de la supply chain développé initialement par Google et désormais maintenu par l'OpenSSF (Open Source Security Foundation). La version courante en 2026 est **SLSA v1.2** (publication finale le **24 novembre 2025**), qui structure le framework en **tracks** thématiques. Deux tracks sont aujourd'hui stables — le **Build Track** (hérité de v1.0, avril 2023) et le **Source Track** (introduit par v1.2) — chacun définissant des niveaux de maturité progressifs ciblant un maillon distinct de la chaîne :

| Niveau | Exigences | Protection |
|---|---|---|
| **Build L0** | Aucune exigence SLSA | Point de départ — pas de garanties |
| **Build L1** | Provenance documentée et générée automatiquement, builds consistants | Visibilité sur l'origine de l'artefact, protection contre les accidents |
| **Build L2** | Provenance **signée numériquement** par la plateforme de build, build hébergé | Détection de la falsification de l'artefact ou de la provenance |
| **Build L3** | Plateforme de build **isolée** et durcie, provenance non falsifiable même par un build malveillant | Protection contre la compromission du pipeline lui-même |

Le **Source Track** (v1.2) introduit quatre niveaux portant sur la gestion du dépôt, l'historique des changements, les contrôles techniques (signatures de commits, branches protégées) et la revue à deux parties.

> **Note version** : la spécification SLSA v0.1 (initiale) définissait 4 niveaux (1 à 4) mêlant Build et Source. SLSA v1.0 (avril 2023) a réorganisé le framework en tracks séparés en ne couvrant que le Build ; le L4 historique a été abandonné. SLSA v1.2 (novembre 2025) ajoute le Source Track et reste compatible avec les niveaux Build de v1.0. De futurs tracks couvriront les opérations de plateforme et la distribution.

Les outils couverts dans les sous-sections suivantes — scanning d'images, signature avec Cosign, génération de SBOM, vérification de provenance — sont les briques techniques qui permettent d'atteindre progressivement les niveaux SLSA Build L1 → L3.

## La sécurité comme code

### Principes

Le DevSecOps pousse le paradigme de l'Infrastructure as Code (module 13) un cran plus loin en traitant **la sécurité elle-même comme du code** :

- Les **politiques de sécurité** sont du code : OPA Gatekeeper Rego (section 16.2.3), Kyverno YAML, politiques RBAC versionnées dans Git
- Les **vérifications de sécurité** sont du code : pipelines CI/CD avec des stages de scan, configurations de scanners versionnées
- Les **réponses aux incidents** sont du code : runbooks automatisés (section 19.5.3), règles Falco, actions de remédiation Falco Talon
- La **conformité** est du code : profils OpenSCAP, règles Lynis personnalisées, CIS Benchmarks automatisés (section 16.1.3)

Cette approche offre les mêmes avantages que l'IaC pour l'infrastructure : versionnement (historique des changements), revue par les pairs (merge requests), reproductibilité (même politique sur tous les environnements), testabilité (tests unitaires des politiques Rego, cf. section 16.2.3).

### Le pipeline sécurisé

Un pipeline CI/CD intégrant la sécurité à chaque étape constitue le cœur opérationnel du DevSecOps :

```
┌────────────────────────────────────────────────────────────┐
│                Pipeline DevSecOps complet                  │
│                                                            │
│  ┌─────────┐                                               │
│  │ Commit  │                                               │
│  │ + Push  │                                               │
│  └────┬────┘                                               │
│       │                                                    │
│       ▼                                                    │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 1 — Analyse statique (SAST)            │          │
│  │                                              │          │
│  │ • Scan du code source (Semgrep, SonarQube)   │          │
│  │ • Détection de secrets committés (gitleaks)  │          │
│  │ • Analyse des dépendances (SCA — Trivy, Grype)          │
│  │ • Linting de sécurité (Dockerfile, K8s YAML) │          │
│  └──────────────────────┬───────────────────────┘          │
│                         │ ✓ Pass                           │
│                         ▼                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 2 — Build et scan d'image              │          │
│  │                                              │          │
│  │ • Construction de l'image conteneur          │          │
│  │ • Scan de vulnérabilités de l'image (Trivy)  │          │
│  │ • Génération du SBOM (Syft)                  │          │
│  │ • Vérification de conformité de l'image      │          │
│  └──────────────────────┬───────────────────────┘          │
│                         │ ✓ Pass                           │
│                         ▼                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 3 — Signature et attestation           │          │
│  │                                              │          │
│  │ • Signature de l'image (Cosign)              │          │
│  │ • Attachement du SBOM et des résultats de    │          │
│  │   scan comme attestations                    │          │
│  │ • Push vers le registry                      │          │
│  └──────────────────────┬───────────────────────┘          │
│                         │ ✓ Pass                           │
│                         ▼                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 4 — Validation des manifestes          │          │
│  │                                              │          │
│  │ • Validation contre les politiques Gatekeeper│          │
│  │   (gator test)                               │          │
│  │ • Vérification des Network Policies          │          │
│  │ • Conformité des security contexts           │          │
│  └──────────────────────┬───────────────────────┘          │
│                         │ ✓ Pass                           │
│                         ▼                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 5 — Tests de sécurité dynamiques       │          │
│  │            (staging uniquement)              │          │
│  │                                              │          │
│  │ • DAST (ZAP, Nuclei) sur l'application       │          │
│  │   déployée en staging                        │          │
│  │ • Tests de conformité réseau                 │          │
│  └──────────────────────┬───────────────────────┘          │
│                         │ ✓ Pass                           │
│                         ▼                                  │
│  ┌──────────────────────────────────────────────┐          │
│  │ STAGE 6 — Déploiement en production          │          │
│  │                                              │          │
│  │ • Vérification de la signature de l'image    │          │
│  │   (admission controller Sigstore/Cosign)     │          │
│  │ • Déploiement via GitOps (ArgoCD/Flux)       │          │
│  │ • Surveillance runtime (Falco)               │          │
│  └──────────────────────────────────────────────┘          │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

Chaque stage peut bloquer le pipeline en cas de violation. Le pipeline n'est pas un simple garde-fou : c'est la matérialisation opérationnelle de la politique de sécurité de l'organisation. Si le pipeline laisse passer une image avec une CVE critique ou un secret dans le code, la politique n'est pas appliquée.

## Responsabilité partagée dans le DevSecOps

Le modèle DevSecOps modifie la répartition des responsabilités de sécurité par rapport au modèle traditionnel :

**Les développeurs** deviennent la première ligne de défense. Ils choisissent les dépendances (et leur posture de sécurité), écrivent le Dockerfile (et les contrôles de sécurité de l'image), déclarent les security contexts dans les manifestes Kubernetes, et corrigent les vulnérabilités détectées par les scanners. Les outils intégrés dans leur workflow (IDE, pre-commit hooks, scanners dans le pipeline) leur fournissent le feedback immédiat nécessaire.

**L'équipe plateforme/SRE** fournit l'outillage sécurisé : le pipeline CI/CD avec les stages de sécurité préconfigurés, les images de base approuvées et durcies, les politiques Gatekeeper/PSA appliquées dans le cluster, les templates de manifestes conformes aux exigences de sécurité. Elle opère aussi la stack de détection runtime (Falco, SIEM) et la réponse aux incidents.

**L'équipe sécurité** définit les politiques (quels seuils de vulnérabilités bloquent le pipeline, quels registries sont autorisés, quelles certifications sont exigées), audite les résultats, pilote la réponse aux incidents majeurs, et évalue les risques résiduels. Elle n'est plus un goulot d'étranglement en fin de cycle mais un facilitateur qui conçoit les guardrails automatisés.

## Plan de la section

Cette section est organisée en quatre sous-parties, chacune couvrant un aspect du DevSecOps :

**16.4.1 — Intégration sécurité dans les pipelines CI/CD (SAST/DAST)** : analyse statique du code source (SAST avec Semgrep, SonarQube), analyse des dépendances (SCA avec Trivy, Grype), scanning d'images conteneur, analyse dynamique (DAST avec ZAP), détection de secrets committés (gitleaks, trufflehog), intégration dans les pipelines GitLab CI et GitHub Actions.

**16.4.2 — Supply chain security (signatures d'images, SBOM, Cosign)** : signature et vérification d'images avec Sigstore/Cosign, génération et exploitation de SBOM (Software Bill of Materials) avec Syft et Grype, vérification de la provenance des artefacts, admission controllers vérifiant les signatures (Connaisseur, Kyverno).

**16.4.3 — Compliance automation** : automatisation des vérifications de conformité (CIS Benchmarks, ANSSI BP-028), intégration des scans de conformité dans les pipelines CI/CD, reporting continu pour les audits externes, gestion de la dette de conformité.

**16.4.4 — Détection d'intrusion et réponse aux incidents (SIEM, IDS/IPS)** : architecture d'un SIEM pour un environnement Debian/Kubernetes, corrélation des événements multi-sources (auditd, Falco, audit logs K8s, logs applicatifs), détection d'intrusion réseau et système, procédures de réponse aux incidents, forensique post-incident dans un environnement conteneurisé.

---

## Résumé

> Le **DevSecOps** intègre la sécurité dans chaque étape du cycle de vie logiciel, remplaçant l'audit ponctuel de fin de cycle par une sécurité **continue** et **automatisée**. Le modèle **shift-left** déplace les vérifications au plus tôt — analyse statique du code, scan des dépendances, vérification des images dès le build — tandis que le **shift-right** maintient la surveillance en production via la détection runtime et la corrélation d'événements. La **chaîne d'approvisionnement logicielle** est sécurisée à chaque maillon — code source, dépendances, images de base, pipeline de build, registry, déploiement — selon le cadre **SLSA** qui définit des niveaux de maturité progressifs. La **sécurité comme code** étend le paradigme de l'IaC aux politiques de sécurité, aux vérifications automatisées et aux réponses aux incidents, les rendant versionnées, testables et reproductibles. Le **pipeline DevSecOps** matérialise cette approche en six stages — analyse statique, build et scan d'image, signature et attestation, validation des manifestes, tests dynamiques, déploiement avec vérification — où chaque stage peut bloquer la progression en cas de violation. Les quatre sous-sections suivantes détaillent la mise en œuvre de chaque composant, de l'intégration SAST/DAST dans les pipelines CI/CD à la détection d'intrusion et la réponse aux incidents en production.

⏭️ [Intégration sécurité dans les pipelines CI/CD (SAST/DAST)](/module-16-securite-avancee/04.1-securite-cicd-sast-dast.md)
