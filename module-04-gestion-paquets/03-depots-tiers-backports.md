🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 4.3 Dépôts tiers et backports

## Introduction

Les dépôts officiels de Debian stable fournissent un socle logiciel remarquablement fiable, mais cette fiabilité a un coût : les versions des logiciels sont figées au moment de la publication de la release et ne reçoivent ensuite que des correctifs de sécurité et de bugs critiques. Ce choix architectural — la priorité à la stabilité sur la nouveauté — est au cœur de l'identité de Debian stable.

Cependant, de nombreuses situations opérationnelles exigent des versions plus récentes qu'un logiciel spécifique : une fonctionnalité absente des anciennes versions, une compatibilité requise avec une API externe, un logiciel tout simplement indisponible dans les dépôts officiels, ou encore un éditeur qui distribue son propre paquet `.deb`. C'est dans ce contexte que les dépôts tiers et le mécanisme de backports prennent tout leur sens.

Cette section explore les différentes sources de paquets disponibles en dehors du dépôt principal Debian, les risques associés, les mécanismes de protection offerts par APT et les bonnes pratiques pour maintenir un système cohérent tout en bénéficiant de logiciels récents.

---

## 1. Le dilemme stabilité vs nouveauté

### 1.1 Le modèle de Debian stable

Debian stable suit un cycle de publication d'environ deux ans. Au moment de la publication, les versions de tous les logiciels sont gelées. Pendant toute la durée de vie de la release (environ trois ans de support standard, prolongés par le support LTS et ELTS), seules les mises à jour de sécurité et les corrections de bugs critiques sont intégrées. Aucune nouvelle version majeure d'un logiciel n'est introduite dans stable.

Ce modèle garantit que le comportement du système est prévisible : une configuration qui fonctionne aujourd'hui fonctionnera de la même manière dans six mois. C'est cette propriété qui fait de Debian stable le choix de référence pour les serveurs de production, les systèmes embarqués et les infrastructures critiques.

En contrepartie, les versions disponibles dans stable peuvent accuser un retard significatif par rapport aux versions actuelles. Par exemple, Debian 13 (Trixie) fournit des versions de logiciels gelées lors du freeze de début 2025 : au fil du temps, le décalage avec les versions les plus récentes s'accroît progressivement.

### 1.2 Les situations qui imposent des versions récentes

Plusieurs cas de figure conduisent l'administrateur à chercher des paquets en dehors du dépôt stable :

**Logiciels à cycle rapide** — Certains logiciels évoluent vite et les anciennes versions perdent rapidement leur pertinence : navigateurs web, runtimes de langages (Node.js, Go, Rust), outils DevOps (Docker, Kubernetes, Terraform), bases de données (PostgreSQL avec des versions majeures annuelles).

**Fonctionnalités requises** — Une application métier peut nécessiter une fonctionnalité introduite dans une version récente d'une bibliothèque ou d'un service. Par exemple, une version spécifique de PostgreSQL pour une extension récente, ou une version de Nginx supportant HTTP/3.

**Logiciels absents des dépôts** — Certains logiciels ne sont pas du tout packagés dans Debian : logiciels propriétaires (Google Chrome, Visual Studio Code, Zoom), outils spécialisés, logiciels récents en attente d'intégration dans Debian.

**Exigences de support éditeur** — Certains éditeurs ne supportent que les versions qu'ils distribuent eux-mêmes via leur propre dépôt (Docker CE, Elasticsearch, Grafana, GitLab).

### 1.3 Le spectre des options disponibles

Face à ce besoin, plusieurs solutions existent, classées par ordre croissant de risque pour la stabilité du système :

| Solution | Risque | Intégration | Cas d'usage |
|----------|--------|-------------|-------------|
| Debian Backports | Très faible | Excellente | Version récente d'un paquet Debian |
| Dépôt officiel d'un éditeur | Faible à modéré | Bonne (si bien conçu) | Logiciel propriétaire, versions éditeur |
| Flatpak / Snap | Faible | Sandboxée | Applications desktop |
| Compilation manuelle + packaging | Variable | Bonne (si packagé) | Logiciel spécifique, version précise |
| Mélange stable/testing | Élevé | Risquée | Fortement déconseillé (*FrankenDebian*) |

---

## 2. Debian Backports

### 2.1 Concept et fonctionnement

Debian Backports est un service officiel du projet Debian qui fournit des versions plus récentes de certains paquets, recompilées pour être compatibles avec la version stable en cours. Les paquets des backports sont construits à partir des sources disponibles dans `testing` (ou parfois `unstable`), puis recompilés contre les bibliothèques de `stable`.

Ce processus de recompilation garantit que les paquets backportés ne cassent pas les dépendances du système stable. Sur Debian 13, le paquet est compilé contre les bibliothèques de Trixie, pas contre celles de Forky (testing). C'est cette propriété qui permet à un paquet backporté de cohabiter sans heurts avec le reste du système stable.

Le dépôt backports fait partie de l'infrastructure officielle Debian. Il est hébergé sur les mêmes miroirs que le dépôt principal et signé par les clés de l'archive Debian. Ce n'est pas un dépôt tiers : c'est un service intégré à l'écosystème Debian.

### 2.2 Règles de fonctionnement

Les backports suivent des règles précises qui les distinguent des autres sources de paquets :

**Installation explicite uniquement.** Les paquets des backports ne sont jamais installés automatiquement par `apt upgrade` ou `apt full-upgrade`. Ils doivent être demandés explicitement avec l'option `-t trixie-backports`. Cette propriété fondamentale garantit que l'activation du dépôt backports ne modifie pas le comportement du système existant.

**Mise à jour automatique une fois installés.** Une fois qu'un paquet a été explicitement installé depuis les backports, les mises à jour ultérieures de ce paquet dans les backports seront proposées par `apt upgrade`. Le paquet « suit » désormais le dépôt backports.

**Pas de support de sécurité dédié.** Les paquets des backports ne bénéficient pas du même suivi de sécurité que les paquets de stable. Les correctifs de sécurité arrivent lorsque la version corrigée est disponible dans testing, ce qui peut introduire un délai.

**Pas de garantie de disponibilité permanente.** Un paquet peut être retiré des backports si sa recompilation contre stable n'est plus possible (dépendances incompatibles) ou si le mainteneur n'assure plus le suivi.

### 2.3 Mécanique de priorité

Le fonctionnement « installation explicite uniquement » repose sur le mécanisme de pinning d'APT. Par défaut, les paquets du dépôt backports ont une priorité de 100, contre 500 pour les paquets de stable. APT choisit toujours la version de priorité la plus élevée comme candidat d'installation. Avec une priorité de 100, un paquet backporté ne sera jamais le candidat par défaut.

L'option `-t trixie-backports` modifie temporairement la priorité des paquets de ce dépôt à 990 pour la durée de la commande, ce qui les rend prioritaires sur la version stable.

---

## 3. Dépôts tiers : panorama et risques

### 3.1 Types de dépôts tiers

Les dépôts tiers peuvent être classés en plusieurs catégories :

**Dépôts d'éditeurs logiciels** — Maintenus par l'éditeur du logiciel lui-même. Exemples : Docker (`download.docker.com`), Google (`dl.google.com`), Microsoft (`packages.microsoft.com`), Grafana (`apt.grafana.com`), HashiCorp (`apt.releases.hashicorp.com`). Ces dépôts sont généralement bien maintenus, signés et conçus pour coexister avec Debian stable.

**Dépôts de projets communautaires** — Maintenus par des communautés ou des mainteneurs individuels. Exemples : dépôt PostgreSQL PGDG (`apt.postgresql.org`), dépôt Nodesource pour Node.js, dépôt Wine HQ. La qualité et la pérennité varient.

**Dépôts institutionnels internes** — Maintenus par une organisation pour ses propres besoins (paquets internes, configurations, logiciels personnalisés).

### 3.2 Risques associés aux dépôts tiers

L'ajout d'un dépôt tiers étend la surface de confiance du système. Plusieurs risques doivent être évalués :

**Conflit de paquets.** Un dépôt tiers peut fournir un paquet portant le même nom qu'un paquet Debian officiel mais dans une version différente ou avec des dépendances incompatibles. Cela peut entraîner des conflits lors des mises à jour ou la rétrogradation involontaire de paquets système.

**Rupture de dépendances.** Un paquet tiers peut introduire des dépendances sur des bibliothèques absentes de Debian stable, tirant le système vers un état incohérent.

**Compromission de la chaîne de confiance.** Si la clé GPG d'un dépôt tiers est compromise, un attaquant peut publier des paquets modifiés qui seront installés comme s'ils étaient légitimes. Le cloisonnement des clés via `signed-by` (traité en 4.1.4) atténue ce risque en limitant la portée d'une clé compromise.

**Abandon du dépôt.** Un dépôt tiers peut cesser d'être maintenu, laissant des paquets sans mises à jour de sécurité. Pire, si le nom de domaine expire, il pourrait être réenregistré par un acteur malveillant.

**Instabilité.** Certains dépôts tiers publient des versions de développement ou des builds non testés contre Debian stable, ce qui peut introduire des régressions.

### 3.3 Le concept de *FrankenDebian*

Le terme *FrankenDebian* désigne un système Debian dont les paquets proviennent d'un mélange incohérent de sources : stable, testing, unstable, dépôts tiers multiples. Ce type de configuration est la première cause de systèmes instables et de dépendances irréparables.

Le scénario classique est l'installation d'un paquet depuis `testing` qui tire une nouvelle version de `libc6` ou `libssl`, ce qui déclenche la mise à jour en cascade de dizaines de paquets système vers des versions non testées pour stable. Le résultat est un système qui n'est ni stable, ni testing, ni unstable, mais un hybride imprévisible.

Les backports existent précisément pour éviter ce piège : ils fournissent des versions récentes recompilées contre les bibliothèques de stable, sans contaminer le reste du système.

---

## 4. Mécanismes de protection d'APT

### 4.1 Le pinning comme garde-fou

Le mécanisme de pinning (traité en détail dans la section 4.3.4) est le premier rempart contre l'installation involontaire de paquets depuis des sources non souhaitées. En attribuant des priorités différentes aux dépôts, l'administrateur contrôle quel dépôt est utilisé par défaut et dans quelles conditions un dépôt alternatif peut être sollicité.

### 4.2 Le cloisonnement des clés GPG

L'option `signed-by` (traitée en 4.1.4) empêche un dépôt tiers de signer des paquets pour un autre dépôt. Sans ce cloisonnement, un mainteneur de dépôt tiers dont la clé est dans le trousseau global pourrait théoriquement publier une version modifiée de `openssh-server` qui serait acceptée par APT.

### 4.3 La vérification des architectures

L'option `Architectures` dans la configuration des dépôts limite les index téléchargés à une ou plusieurs architectures spécifiques. Cela évite les erreurs lors de `apt update` lorsqu'un dépôt tiers ne fournit pas de paquets pour toutes les architectures et prévient l'installation accidentelle de paquets pour une architecture non souhaitée.

### 4.4 Le champ `Valid-Until`

Les fichiers `InRelease` des dépôts contiennent un champ `Valid-Until` qui fixe une date d'expiration pour les métadonnées. APT refuse d'utiliser des métadonnées expirées, ce qui protège contre les attaques par rejeu (un attaquant qui servirait d'anciens fichiers d'index référençant des paquets vulnérables).

---

## 5. Critères de choix d'un dépôt tiers

Avant d'ajouter un dépôt tiers à un système de production, l'administrateur doit évaluer plusieurs critères :

**Mainteneur et réputation.** Un dépôt maintenu par l'éditeur du logiciel (Docker, PostgreSQL, Google) offre de meilleures garanties qu'un dépôt personnel hébergé sur un blog. La présence d'une documentation claire, d'une politique de sécurité et d'un historique de maintenance sont des indicateurs positifs.

**Signature GPG.** Un dépôt de confiance fournit une clé GPG publique et signe ses fichiers `Release`. Un dépôt non signé ne doit jamais être utilisé en production.

**Compatibilité déclarée avec Debian stable.** Le dépôt doit explicitement indiquer qu'il supporte la version de Debian en cours. Un dépôt conçu pour Ubuntu peut fonctionner partiellement sur Debian mais sans aucune garantie.

**Politique de nommage des paquets.** Un dépôt bien conçu utilise des noms de paquets qui n'entrent pas en conflit avec les paquets Debian officiels, ou fournit des métadonnées de pinning claires.

**HTTPS.** Le dépôt doit être accessible via HTTPS pour protéger la confidentialité des paquets téléchargés et prévenir les attaques par interception.

**Pérennité.** Un dépôt qui disparaît génère des erreurs à chaque `apt update` et laisse des paquets installés sans source de mises à jour. Évaluer la probabilité que le dépôt soit maintenu sur la durée de vie prévue du système.

---

## Ce que couvrent les sous-sections suivantes

Les sous-sections qui suivent détaillent les aspects pratiques :

- **4.3.1 — Ajout de dépôts externes** : procédure complète d'ajout d'un dépôt tiers (clé GPG, fichier sources, vérification), exemples concrets pour les dépôts les plus courants et gestion du cycle de vie d'un dépôt.
- **4.3.2 — Debian Backports** : activation, utilisation, gestion des mises à jour, cas d'usage typiques et limites.
- **4.3.3 — Sécurité et vérification des sources** : évaluation de la fiabilité d'un dépôt, audit des clés GPG, surveillance des paquets tiers installés et procédures de retrait.
- **4.3.4 — Pinning des paquets (APT preferences)** : syntaxe des fichiers `preferences`, gestion des priorités, scénarios courants de pinning et diagnostic des problèmes liés aux priorités.

## Prérequis

Pour aborder cette section dans de bonnes conditions :

- Maîtrise de la configuration des dépôts APT et des formats `sources.list` / DEB822 (section 4.1.2).
- Compréhension de la chaîne de confiance GPG et de la gestion des clés (section 4.1.4).
- Familiarité avec le mécanisme de résolution des dépendances (section 4.2.3).

⏭️ [Ajout de dépôts externes](/module-04-gestion-paquets/03.1-ajout-depots-externes.md)
