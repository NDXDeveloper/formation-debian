🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe E — Certifications et évaluation

## Formation Debian : du Desktop au Cloud-Native

---

## Présentation

Cette annexe est orientée vers la **validation des compétences** et la **progression professionnelle**. Elle répond à deux questions complémentaires : comment évaluer les compétences acquises pendant la formation, et comment les faire reconnaître par des certifications professionnelles sur le marché du travail.

L'évaluation interne à la formation (critères par module et par parcours) et la préparation aux certifications externes (CKA, CKS, Terraform Associate) sont deux démarches distinctes mais convergentes. La première mesure la maîtrise des contenus enseignés ; la seconde valide des compétences reconnues internationalement par l'industrie.

---

## Structure de cette annexe

### [E.1 — Critères d'évaluation par module et par parcours](/annexes/E.1-criteres-evaluation.md)

Cette section définit les **objectifs de compétence** associés à chaque module de la formation, organisés en trois niveaux : connaissances (savoir), aptitudes (savoir-faire) et autonomie (savoir-être opérationnel). Pour chaque module, les critères précisent ce que l'apprenant doit être capable de réaliser pour considérer le module comme acquis.

Les critères sont ensuite consolidés au niveau de chaque parcours, avec un profil de compétences cible décrivant le niveau attendu en sortie de parcours 1 (administrateur système Debian), de parcours 2 (ingénieur infrastructure et conteneurs) et de parcours 3 (expert cloud-native et Kubernetes).

Cette section sert de référence pour l'auto-évaluation de l'apprenant, pour le suivi pédagogique par le formateur et pour la communication avec les employeurs sur les compétences couvertes par la formation.

### [E.2 — Préparation certifications (CKA, CKS, Terraform Associate)](/annexes/E.2-preparation-certifications.md)

Cette section fournit un guide de préparation pour les trois certifications professionnelles visées par la formation. Pour chaque certification, elle détaille le format de l'examen, les domaines couverts avec leur pondération, la correspondance avec les modules de la formation, les ressources de préparation recommandées, les stratégies de passage et les points de vigilance identifiés par les candidats ayant passé l'examen.

Les certifications couvertes sont la CKA (Certified Kubernetes Administrator) de la Linux Foundation, la CKS (Certified Kubernetes Security Specialist) de la Linux Foundation et la Terraform Associate de HashiCorp. Ces certifications ont été choisies pour leur reconnaissance par l'industrie, leur pertinence par rapport au contenu de la formation et leur valeur sur le marché de l'emploi.

### [E.3 — Cas d'usage métier et architectures sectorielles](/annexes/E.3-cas-usage-metier.md)

Cette section illustre l'application des compétences de la formation dans des **contextes professionnels concrets**. Elle présente des architectures types adaptées à différents secteurs d'activité (startup web, entreprise industrielle, secteur public, hébergeur, e-commerce) et des scénarios métier qui mobilisent les compétences de plusieurs modules simultanément.

L'objectif est de montrer comment les briques techniques de la formation s'assemblent dans des projets réels et d'aider l'apprenant à identifier les compétences les plus pertinentes pour son contexte professionnel.

---

## Philosophie de l'évaluation

### Compétences opérationnelles plutôt que connaissances théoriques

L'évaluation dans cette formation privilégie la capacité à **réaliser une tâche en conditions réelles** plutôt que la capacité à restituer des connaissances de mémoire. Savoir que Kubernetes utilise etcd comme magasin de données est une connaissance ; savoir sauvegarder et restaurer etcd sur un cluster Debian en production est une compétence opérationnelle. C'est la seconde qui est évaluée.

Cette approche est alignée avec le format des certifications CKA et CKS, qui sont des examens pratiques où le candidat doit résoudre des problèmes sur un cluster réel, et non répondre à des questions à choix multiples.

### Progression plutôt que sanction

L'évaluation sert avant tout à mesurer la progression et à identifier les axes d'amélioration. Un module non maîtrisé n'est pas un échec : c'est une indication que des révisions supplémentaires ou une approche pédagogique différente sont nécessaires. Les critères d'évaluation sont transparents et communiqués dès le début de chaque module pour que l'apprenant puisse s'auto-évaluer en continu.

### Trois niveaux de maîtrise

Chaque compétence est évaluée selon trois niveaux qui reflètent la progression de l'apprenant vers l'autonomie.

Le niveau **fondamental** correspond à la capacité d'exécuter une procédure documentée en suivant les instructions pas à pas. L'apprenant comprend ce qu'il fait et pourquoi, mais a besoin de la documentation comme support. Ce niveau est attendu pour les modules en dehors du parcours principal de l'apprenant (par exemple, les modules Kubernetes pour un apprenant du parcours 1 qui les aborde en découverte).

Le niveau **opérationnel** correspond à la capacité de réaliser une tâche de manière autonome, d'adapter une procédure standard à un contexte spécifique et de diagnostiquer les problèmes courants. L'apprenant n'a plus besoin de la documentation pour les opérations courantes, mais la consulte pour les cas avancés. Ce niveau est l'objectif principal de chaque module dans le parcours correspondant.

Le niveau **expert** correspond à la capacité de concevoir des architectures, de prendre des décisions techniques argumentées, d'optimiser les performances, de gérer des incidents complexes et de former d'autres personnes. L'apprenant maîtrise les subtilités, connaît les limites des outils et sait choisir la bonne solution parmi plusieurs alternatives. Ce niveau est visé pour les modules avancés des parcours 2 et 3 et correspond au profil des candidats aux certifications CKA, CKS et Terraform Associate.

---

## Les certifications dans le paysage professionnel

### Rôle des certifications

Les certifications professionnelles remplissent plusieurs fonctions complémentaires dans une carrière technique. Elles fournissent un **objectif structurant** pour l'apprentissage : la préparation à un examen impose de couvrir systématiquement tous les domaines, y compris ceux qu'on aurait tendance à négliger. Elles offrent une **validation externe** des compétences : un employeur ou un client peut vérifier objectivement qu'un professionnel maîtrise un socle de compétences défini. Elles constituent un **signal sur le marché de l'emploi** : les certifications CKA et CKS sont explicitement mentionnées dans de nombreuses offres d'emploi DevOps et SRE.

### Limites des certifications

Les certifications ne sont pas une fin en soi et présentent des limites qu'il est important de reconnaître. Elles évaluent des compétences à un instant donné, sur un périmètre défini ; elles ne garantissent pas la capacité à résoudre tout problème dans un environnement de production complexe. La préparation orientée uniquement vers le passage de l'examen (« teaching to the test ») peut conduire à une maîtrise superficielle. L'expérience opérationnelle réelle, acquise en situation de travail, reste irremplaçable.

La recommandation de cette formation est de viser les certifications **après** avoir acquis une expérience pratique suffisante, pas comme un substitut à cette expérience. Un administrateur qui gère quotidiennement un cluster Kubernetes depuis six mois et passe ensuite la CKA en retire beaucoup plus qu'un candidat qui la prépare en mode « bachotage » sans expérience opérationnelle.

### Cartographie des certifications pertinentes

Les trois certifications directement préparées par cette formation ne sont pas les seules du paysage. Le tableau ci-dessous les positionne dans un contexte plus large.

| Certification | Éditeur | Parcours | Modules principaux | Format |
|--------------|---------|----------|-------------------|--------|
| **CKA** — Certified Kubernetes Administrator | Linux Foundation | 2, 3 | 11, 12 | Pratique (2h, cluster réel) |
| **CKS** — Certified Kubernetes Security Specialist | Linux Foundation | 3 | 12, 16 | Pratique (2h, cluster réel) |
| **Terraform Associate** (004 depuis janvier 2026) | HashiCorp | 2, 3 | 13 | QCM (1h, ~60 questions) |
| KCNA — Kubernetes and Cloud Native Associate | Linux Foundation | 2 | 11 | QCM (1h30, ~60 questions) — pré-pro |
| KCSA — Kubernetes and Cloud Native Security Associate | Linux Foundation | 3 | 16 | QCM (1h30, ~60 questions) — pré-pro |
| CKAD — Certified Kubernetes Application Developer | Linux Foundation | 2 | 11 | Pratique (2h) |
| Vault Associate (003) | HashiCorp | 3 | 16 | QCM (1h, ~60 questions, aligné Vault 1.16) |
| LFCS — Linux Foundation Certified System Administrator | Linux Foundation | 1 | 1-8 | Pratique (2h) |
| RHCSA — Red Hat Certified System Administrator | Red Hat | 1 | 3-7 | Pratique (2h30) |
| AWS SAA — Solutions Architect Associate | AWS | 3 | 17 | QCM (2h10) |
| GCP ACE — Associate Cloud Engineer | Google | 3 | 17 | QCM (2h) |
| AZ-104 — Azure Administrator | Microsoft | 3 | 17 | QCM (2h30) |

Les certifications en **gras** sont celles directement préparées par la formation. Les autres sont des certifications complémentaires que l'apprenant peut envisager selon son orientation professionnelle. La LFCS valide les compétences du parcours 1, les certifications cloud (AWS, GCP, Azure) approfondissent le module 17, et la CKAD est une alternative à la CKA orientée développement plutôt qu'administration. Les **KCNA** et **KCSA** sont des certifications « Associate » récentes (multi-choice, sans prérequis), idéales pour valider les bases avant d'attaquer les certifications « pro » CKA/CKS/CKAD. La **Vault Associate (003)** valide les compétences sur HashiCorp Vault 1.16 (auth methods, policies, dynamic secrets, Transit) ; les compétences acquises s'appliquent largement à OpenBao puisque c'est un drop-in replacement de Vault 1.14.x.

> **Programme Kubestronaut** — La CNCF reconnaît un statut « Kubestronaut » à toute personne détenant simultanément les 5 certifications Kubernetes (KCNA + KCSA + CKA + CKAD + CKS). Les détenteurs reçoivent une veste exclusive et un statut de reconnaissance dans la communauté CNCF. Un bundle « Kubestronaut Bundle » est commercialisé par la Linux Foundation pour passer l'ensemble à tarif réduit. La communauté Kubestronaut a dépassé 3 500 membres en mars 2026.

> **CNCF CARE Program (2026)** — Le **Certification Advancement & Recertification Experience** (annoncé en mars 2026, effectif depuis le 1er janvier 2026) introduit un mécanisme de **renouvellement automatique en cascade** : passer/recertifier une certification de niveau Pro renouvelle automatiquement les Associate correspondantes (CKA/CKAD → KCNA, CKS → KCSA). Cela évite aux praticiens expérimentés de devoir maintenir manuellement les certifications fondationnelles.

---

## Correspondance parcours — profils métier — certifications

| Parcours | Profil métier cible | Certifications recommandées |
|----------|--------------------|-----------------------------|
| **Parcours 1** | Administrateur système Debian, technicien infrastructure | LFCS (optionnel) |
| **Parcours 2** | Ingénieur infrastructure, DevOps junior, ingénieur conteneurs | KCNA (échauffement) → **CKA** + **Terraform Associate** |
| **Parcours 3** | DevOps/SRE confirmé, architecte cloud-native, platform engineer | KCSA (échauffement) → **CKA** + **CKS** + **Terraform Associate** (objectif Kubestronaut accessible avec en plus KCNA + CKAD) |

Le parcours 1 ne vise pas directement une certification, mais fournit les bases nécessaires pour la LFCS (Linux Foundation Certified System Administrator). Les parcours 2 et 3 préparent progressivement aux certifications CKA, CKS et Terraform Associate, qui constituent aujourd'hui un différenciant significatif sur le marché des profils DevOps et SRE. Les certifications KCNA (généraliste) et KCSA (sécurité), plus accessibles car en QCM sans prérequis, sont une excellente porte d'entrée pour valider les fondamentaux avant les examens pratiques CKA/CKS.

---

## Comment utiliser cette annexe

**En début de formation** — Consulter E.1 pour comprendre les objectifs de compétence de chaque module et orienter son apprentissage. Identifier les certifications pertinentes pour son projet professionnel en parcourant E.2.

**Pendant la formation** — Utiliser les critères de E.1 pour l'auto-évaluation continue. Après chaque module, vérifier que les compétences listées sont maîtrisées au niveau attendu.

**En fin de parcours** — Consolider l'auto-évaluation avec les profils de compétences par parcours (E.1). Planifier le passage des certifications en suivant les guides de préparation (E.2). Identifier les cas d'usage métier pertinents pour son contexte (E.3).

**Dans la vie professionnelle** — Utiliser les cas d'usage de E.3 comme source d'inspiration pour les projets d'infrastructure. Revenir aux critères de E.1 lors des entretiens annuels ou des bilans de compétences pour identifier les axes de progression.

---

> **Note** — Les informations sur les certifications (format, prix, durée de validité, domaines couverts) reflètent l'état au moment de la rédaction de cette édition (2026). Les éditeurs de certification font évoluer régulièrement le contenu et les modalités de leurs examens. Consulter les sites officiels (training.linuxfoundation.org, developer.hashicorp.com) pour les informations les plus récentes avant de planifier un passage.

⏭️ [Critères d'évaluation par module et par parcours](/annexes/E.1-criteres-evaluation.md)
