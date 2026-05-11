🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexes

## Formation Debian : du Desktop au Cloud-Native

---

## Présentation des annexes

Les annexes de cette formation constituent un ensemble de ressources de référence conçues pour accompagner l'apprenant tout au long de son parcours, puis dans sa pratique professionnelle quotidienne. Contrairement aux modules qui suivent une progression pédagogique structurée, les annexes sont organisées par thématique et pensées pour être consultées **à la demande**, en fonction des besoins rencontrés sur le terrain.

Ces documents ne se substituent pas aux modules de formation : ils les complètent en offrant un accès rapide et synthétique aux informations les plus fréquemment recherchées par un administrateur système ou un ingénieur DevOps/SRE travaillant dans un environnement Debian.

---

## Structure des annexes

Les annexes sont organisées en cinq parties complémentaires, chacune répondant à un besoin spécifique.

### [A. Commandes essentielles par module](/annexes/A-commandes-essentielles.md)

Cette annexe regroupe l'ensemble des commandes abordées dans la formation, classées par catégorie fonctionnelle et par technologie. Elle comprend une référence détaillée des commandes avec leurs options courantes, des exemples d'utilisation concrets, ainsi que des cheat sheets synthétiques pour Debian, Docker, Kubernetes, Terraform et Ansible. C'est la ressource à garder sous la main au quotidien, que ce soit pour retrouver rapidement la syntaxe d'une commande `kubectl` ou les options de `apt`.

- [A.1 — Référence des commandes par catégorie](/annexes/A.1-reference-commandes.md)
- [A.2 — Options courantes et exemples](/annexes/A.2-options-exemples.md)
- [A.3 — Cheat sheets par technologie](/annexes/A.3-cheat-sheets.md)

### [B. Fichiers de configuration Debian](/annexes/B-fichiers-configuration.md)

Debian repose sur une multitude de fichiers de configuration répartis dans l'arborescence du système. Cette annexe centralise la localisation des fichiers importants pour chaque service étudié dans la formation, leur syntaxe commentée avec des exemples annotés, ainsi que des templates prêts à l'emploi respectant les bonnes pratiques. Qu'il s'agisse de configurer un virtual host Nginx, d'ajuster les paramètres de PostgreSQL ou de mettre en place une règle nftables, cette annexe fournit un point de départ fiable.

- [B.1 — Localisation des fichiers importants par service](/annexes/B.1-localisation-fichiers.md)
- [B.2 — Syntaxe et exemples annotés](/annexes/B.2-syntaxe-exemples.md)
- [B.3 — Templates et bonnes pratiques](/annexes/B.3-templates-bonnes-pratiques.md)

### [C. Troubleshooting par composant](/annexes/C-troubleshooting.md)

Le diagnostic et la résolution de problèmes représentent une part significative du travail d'un administrateur système ou d'un ingénieur infrastructure. Cette annexe propose des guides de diagnostic structurés, couvrant le système Debian lui-même, les clusters Kubernetes, les problèmes réseau et stockage, ainsi que les procédures de recovery en cas d'incident majeur. Chaque guide suit une méthodologie systématique : identification des symptômes, collecte d'informations, analyse et résolution.

- [C.1 — Guide diagnostic système Debian](/annexes/C.1-diagnostic-systeme.md)
- [C.2 — Problèmes courants Kubernetes](/annexes/C.2-problemes-kubernetes.md)
- [C.3 — Résolution réseau et stockage](/annexes/C.3-resolution-reseau-stockage.md)
- [C.4 — Procédures recovery](/annexes/C.4-procedures-recovery.md)

### [D. Ressources et documentation](/annexes/D-ressources-documentation.md)

L'écosystème Debian et cloud-native évolue en permanence. Cette annexe rassemble les liens vers la documentation officielle des projets abordés dans la formation (Debian, Kubernetes, les principaux cloud providers), les communautés et forums francophones et anglophones où poser des questions et échanger avec d'autres professionnels, ainsi que des recommandations pour organiser une veille technologique efficace. L'objectif est de fournir à l'apprenant les clés pour continuer à progresser de manière autonome après la formation.

- [D.1 — Documentation officielle](/annexes/D.1-documentation-officielle.md)
- [D.2 — Communautés et forums](/annexes/D.2-communautes-forums.md)
- [D.3 — Veille technologique](/annexes/D.3-veille-technologique.md)

### [E. Certifications et évaluation](/annexes/E-certifications-evaluation.md)

Cette dernière annexe est orientée vers la validation des compétences et la progression professionnelle. Elle détaille les critères d'évaluation associés à chaque module et à chaque parcours, propose des conseils de préparation pour les certifications professionnelles visées par la formation (CKA, CKS, Terraform Associate), et présente des cas d'usage métier qui illustrent l'application concrète des compétences acquises dans différents contextes sectoriels.

- [E.1 — Critères d'évaluation par module et par parcours](/annexes/E.1-criteres-evaluation.md)
- [E.2 — Préparation certifications](/annexes/E.2-preparation-certifications.md)
- [E.3 — Cas d'usage métier et architectures sectorielles](/annexes/E.3-cas-usage-metier.md)

---

## Comment utiliser ces annexes

**Pendant la formation** — Chaque module fait référence aux annexes correspondantes lorsqu'un complément d'information est pertinent. Les cheat sheets de l'annexe A et les fichiers de configuration de l'annexe B sont particulièrement utiles pendant les phases de mise en pratique.

**En situation professionnelle** — Les annexes C (troubleshooting) et B (fichiers de configuration) deviennent des outils de travail quotidiens. Elles sont conçues pour permettre une recherche rapide en situation opérationnelle, lorsqu'un problème survient ou qu'une configuration doit être mise en place dans des délais contraints.

**Pour la progression continue** — Les annexes D (ressources) et E (certifications) accompagnent l'apprenant dans la durée, au-delà de la formation elle-même, en lui fournissant les moyens de maintenir ses compétences à jour et de les faire reconnaître par des certifications professionnelles.

---

## Correspondance annexes / parcours

| Annexe | Parcours 1 | Parcours 2 | Parcours 3 |
|--------|:-----------:|:-----------:|:-----------:|
| **A** — Commandes essentielles | ✔ | ✔ | ✔ |
| **B** — Fichiers de configuration | ✔ | ✔ | ✔ |
| **C** — Troubleshooting | ✔ | ✔ | ✔ |
| **D** — Ressources et documentation | ✔ | ✔ | ✔ |
| **E** — Certifications et évaluation | ✔ | ✔ | ✔ |

Les cinq annexes sont transversales et exploitables quel que soit le parcours suivi. Leur contenu couvre l'ensemble du périmètre de la formation, des commandes Debian de base (parcours 1) jusqu'aux architectures Kubernetes avancées (parcours 3).

---

> **Note de maintenance** — Ces annexes sont mises à jour à chaque nouvelle édition de la formation pour refléter les évolutions des outils et des bonnes pratiques. Les versions des logiciels mentionnées correspondent à celles disponibles dans les dépôts Debian Stable au moment de la rédaction (édition 2026).

⏭️ [Commandes essentielles par module](/annexes/A-commandes-essentielles.md)
