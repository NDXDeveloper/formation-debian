🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe D.3 — Veille technologique

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

La veille technologique est un investissement continu qui permet de rester à jour sur les évolutions de l'écosystème, d'anticiper les changements (dépréciations, nouvelles pratiques, outils émergents) et de progresser au-delà du périmètre de la formation. Cette section propose une méthode d'organisation de la veille et une sélection de sources de qualité, classées par format.

La sélection privilégie le rapport signal/bruit : des contenus techniques approfondis, régulièrement mis à jour, rédigés ou présentés par des praticiens reconnus. Les sources purement commerciales, les agrégateurs sans valeur ajoutée et les contenus superficiels sont volontairement exclus.

---

## 1. Organiser sa veille

### Le budget temps

Une veille efficace ne nécessite pas un investissement massif. Trente minutes par semaine, consacrées à la lecture de quelques sources bien choisies, suffisent pour rester informé des évolutions majeures. L'erreur courante est de s'abonner à trop de sources et de se retrouver submergé par un flux d'information impossible à traiter, ce qui aboutit à l'abandon de toute veille.

La recommandation est de commencer avec un nombre restreint de sources (cinq à dix) et d'ajuster progressivement en fonction de la valeur perçue. Une source qui ne fournit pas régulièrement d'information utile doit être supprimée sans hésitation.

### Les outils

**Lecteur de flux RSS/Atom** — Le RSS reste le moyen le plus efficace d'agréger des sources diverses dans une interface unique. Des lecteurs comme Miniflux (auto-hébergeable sur Debian), FreshRSS (auto-hébergeable, interface web), Feedly ou Inoreader (services en ligne) permettent de centraliser les flux de blogs, de changelogs et de forums. La plupart des blogs techniques, des dépôts GitHub et des forums Discourse exposent un flux RSS.

**Newsletters par email** — Le format newsletter offre un contenu déjà sélectionné et résumé par un éditeur humain. C'est le format le moins exigeant en temps : la sélection est faite par quelqu'un d'autre, il suffit de lire. Créer une adresse email dédiée ou un filtre pour ne pas noyer les newsletters dans le flux de travail quotidien.

**Signets et lecture différée** — Des outils comme Wallabag (auto-hébergeable), Pocket ou une simple liste de signets dans le navigateur permettent de sauvegarder les articles découverts pendant la semaine pour les lire à un moment dédié, plutôt que d'interrompre le travail en cours.

### La routine

Un créneau hebdomadaire fixe (par exemple le vendredi après-midi ou le lundi matin) consacré à la veille est plus efficace qu'une consultation dispersée tout au long de la semaine. Ce créneau permet de lire les newsletters et les articles sauvegardés, de parcourir les flux RSS, de tester un outil ou une fonctionnalité découverte, et de partager les éléments pertinents avec l'équipe.

---

## 2. Newsletters

Les newsletters constituent le point d'entrée le plus accessible pour une veille régulière. Chaque édition représente un condensé de l'actualité de la semaine, sélectionné par un éditeur expérimenté.

### Écosystème Linux et DevOps

**DevOps Weekly**
Newsletter hebdomadaire couvrant l'ensemble du paysage DevOps : conteneurs, orchestration, observabilité, sécurité, culture. Chaque édition propose une dizaine de liens commentés vers des articles, des outils et des retours d'expérience. C'est l'une des newsletters les plus anciennes et les plus respectées de l'écosystème.

**SRE Weekly**
Centrée sur la fiabilité des systèmes (Site Reliability Engineering), cette newsletter couvre les incidents post-mortems publics, les pratiques de fiabilité et les outils de monitoring. Particulièrement pertinente pour les modules 15 et 19.

**Linux Weekly News (LWN)**
`https://lwn.net/`
Publication hebdomadaire de référence sur le noyau Linux, les distributions et l'écosystème du logiciel libre. Les articles sont d'une profondeur technique exceptionnelle. Une partie du contenu est réservée aux abonnés pendant la première semaine, puis devient accessible gratuitement. LWN couvre régulièrement les évolutions de Debian et les décisions du projet.

### Kubernetes et cloud-native

**KubeWeekly**
Newsletter officielle de la CNCF, publiée chaque semaine. Couvre les nouvelles versions, les articles techniques, les événements et les projets émergents de l'écosystème cloud-native. Le contenu est directement lié aux modules 11 à 18.

**Last Week in Kubernetes Development**
Résumé hebdomadaire des changements dans le code de Kubernetes : nouvelles fonctionnalités en cours de développement, KEP (Kubernetes Enhancement Proposals) avancés, bugs corrigés. Destinée aux utilisateurs avancés qui veulent anticiper les évolutions des prochaines versions.

**CNCF End User Technology Radar**
Publication périodique (non hebdomadaire) qui synthétise les choix technologiques des entreprises utilisatrices de Kubernetes. Organisée par thème (observabilité, stockage, CI/CD, etc.), elle montre quels outils sont adoptés, testés ou abandonnés par les praticiens.

### Infrastructure as Code

**Ansible Bullhorn**
Newsletter officielle de la communauté Ansible, publiée toutes les deux semaines. Couvre les nouvelles collections, les changements dans Ansible Core et les événements communautaires.

**HashiCorp Newsletter**
Newsletter couvrant Terraform, Vault, Consul et les autres produits HashiCorp. Mélange d'annonces produit et de contenus techniques.

### Sécurité

**This Week in Security**
Résumé hebdomadaire des actualités en sécurité informatique : nouvelles vulnérabilités, correctifs publiés, techniques d'attaque et de défense. Couvre un spectre large, du système au cloud-native.

**Debian Security Announce (flux RSS)**
`https://www.debian.org/security/dsa`
Flux RSS des annonces de sécurité Debian. Indispensable pour tout administrateur de systèmes Debian en production.

---

## 3. Blogs techniques

Les blogs techniques offrent des analyses approfondies, des retours d'expérience et des tutoriels avancés qui complètent la documentation officielle.

### Blogs des projets

**Blog Kubernetes**
`https://kubernetes.io/blog/`
Articles officiels du projet : annonces de versions, présentations de fonctionnalités, guides d'architecture. Chaque release majeure est accompagnée d'un article détaillant les nouveautés et les dépréciations.

**Blog Debian (Bits from Debian)**
`https://bits.debian.org/`
Communications officielles du projet Debian : annonces de versions, rapports de sprints, décisions du projet. Fréquence modérée mais contenu important.

**Blog Grafana Labs**
`https://grafana.com/blog/`
Articles techniques sur l'observabilité, Prometheus, Loki, Grafana et les pratiques de monitoring. Les articles « How to » sont particulièrement pratiques pour les modules 15 et 19.

**Blog Docker**
`https://www.docker.com/blog/`
Annonces produit, bonnes pratiques de conteneurisation et évolutions de l'écosystème Docker.

**Blog HashiCorp**
`https://www.hashicorp.com/blog`
Articles sur Terraform, Vault et les pratiques d'Infrastructure as Code. Les articles « patterns and practices » sont utiles pour le module 13.

### Blogs d'entreprises et d'équipes SRE

**Cloudflare Blog**
`https://blog.cloudflare.com/`
Articles techniques de très haute qualité sur les réseaux, le DNS, la performance web, la sécurité et l'infrastructure à grande échelle. Les post-mortems d'incidents sont particulièrement instructifs.

**Brendan Gregg's Blog**
`https://www.brendangregg.com/blog/`
Référence en matière de performance système et d'observabilité. Brendan Gregg est l'auteur des flamegraphs et un expert reconnu en analyse de performances Linux. Ses articles couvrent eBPF, le tracing, le profilage et le tuning système.

**Julia Evans (b0rk)**
`https://jvns.ca/`
Blog axé sur la compréhension des concepts systèmes et réseau Linux, avec une approche pédagogique unique mêlant texte et illustrations (zines). Les articles couvrent DNS, les namespaces, les conteneurs, le réseau et les outils de diagnostic.

**Sysadvent**
`https://sysadvent.blogspot.com/`
Publication annuelle (calendrier de l'avent) proposant un article technique par jour en décembre, rédigé par différents praticiens. Les archives constituent une bibliothèque riche de retours d'expérience en administration système et DevOps.

### Blogs francophones

**Blog Stéphane Bortzmeyer**
`https://www.bortzmeyer.org/`
Blog d'un ingénieur français spécialiste du DNS, des réseaux et des standards Internet (RFC). Les articles sont techniques, précis et font référence dans la communauté francophone. Pertinent pour les modules 6 et 8.

**Le Journal du Hacker**
`https://www.journalduhacker.net/`
Agrégateur francophone d'articles techniques sur le modèle de Hacker News, voté par la communauté. Couvre le développement, l'administration système, la sécurité et le logiciel libre. Le filtre communautaire assure un niveau de qualité correct.

---

## 4. Podcasts

Le format podcast permet d'intégrer la veille dans les temps de trajet, de sport ou d'activités manuelles.

### Podcasts anglophones

**Kubernetes Podcast from Google**
Podcast bimensuel couvrant l'actualité de l'écosystème Kubernetes avec des interviews de contributeurs, d'opérateurs et d'architectes. Chaque épisode commence par un résumé des nouvelles de la semaine, suivi d'un entretien approfondi avec un invité.

**The Changelog**
Podcast de longue date couvrant le logiciel libre et open source au sens large. Les épisodes dédiés à l'infrastructure, aux conteneurs et à l'observabilité sont pertinents pour cette formation.

**Ship It!**
Spin-off de The Changelog, centré sur le déploiement, le CI/CD, le GitOps et l'infrastructure. Les épisodes sont des conversations avec des praticiens sur leurs choix techniques et leurs retours d'expérience.

**Arrested DevOps**
Podcast couvrant la culture et les pratiques DevOps, avec un accent sur les aspects humains et organisationnels (collaboration, incidents, on-call, postmortems).

### Podcasts francophones

**Radio DevOps**
Podcast francophone dédié aux pratiques DevOps, au cloud et à l'infrastructure. Les épisodes alternent entre retours d'expérience, présentations d'outils et discussions sur les tendances.

**Message à caractère informatique**
Podcast francophone couvrant l'actualité du logiciel libre et de l'open source, avec des épisodes régulièrement consacrés à l'administration système et à l'infrastructure.

**NoLimitSecu**
Podcast francophone spécialisé en sécurité informatique. Les épisodes couvrent les vulnérabilités, les techniques de défense, la conformité et les retours d'expérience d'incidents. Pertinent pour le module 16.

---

## 5. Chaînes vidéo et conférences en ligne

### Chaînes YouTube et PeerTube

**CNCF (Cloud Native Computing Foundation)**
`https://www.youtube.com/@cncf`
Chaîne officielle de la CNCF publiant l'intégralité des présentations de KubeCon et des webinaires communautaires. Des centaines d'heures de contenu technique de haut niveau, couvrant tous les aspects du cloud-native. Les playlists par événement et par thème facilitent la navigation.

**FOSDEM**
`https://video.fosdem.org/`
Archives vidéo complètes de toutes les éditions du FOSDEM. Les devrooms « Containers & Virtualization », « Distributions », « DNS » et « Monitoring & Observability » sont les plus pertinentes.

**DebConf**
`https://meetings-archive.debian.net/pub/debian-meetings/`
Enregistrements des présentations DebConf. Contenu pointu sur le développement et l'administration Debian.

**TechWorld with Nana**
Chaîne pédagogique couvrant Docker, Kubernetes, Terraform, Ansible et les pratiques DevOps. Les tutoriels sont structurés, progressifs et accessibles aux débutants. Particulièrement utile pour accompagner les modules 10 à 14.

**That DevOps Guy (Marcel Dempers)**
Chaîne orientée pratique avec des démonstrations de déploiement Kubernetes, de configuration de pipelines CI/CD et de mise en place d'observabilité.

### Plateformes de conférences

**InfoQ**
`https://www.infoq.com/`
Publication technique proposant des articles, des présentations enregistrées et des interviews. La section « DevOps » et la section « Cloud Computing » sont pertinentes. Les présentations de QCon sont de très haute qualité.

---

## 6. Réseaux professionnels et microblogging

### Plateformes à suivre

**LinkedIn**
Le fil d'actualité LinkedIn est devenu un canal significatif pour la veille technique, à condition de suivre les bonnes personnes. Suivre les contributeurs des projets majeurs (Kubernetes, CNCF, Debian), les ingénieurs SRE des grandes entreprises et les auteurs des blogs listés ci-dessus. La fonctionnalité de newsletter LinkedIn permet à certains auteurs de publier du contenu technique approfondi.

**Mastodon / Fediverse**
L'instance `https://fosstodon.org/` rassemble une communauté active de praticiens du logiciel libre et de l'administration système. Les hashtags `#Kubernetes`, `#DevOps`, `#Debian`, `#Linux` et `#SRE` sont actifs. Plusieurs développeurs Debian et contributeurs Kubernetes y publient régulièrement.

**Hacker News**
`https://news.ycombinator.com/`
Agrégateur de la communauté Y Combinator, couvrant un spectre très large (développement, infrastructure, sécurité, startups). Le système de vote communautaire fait remonter les articles les plus intéressants. La section commentaires est souvent aussi instructive que l'article lui-même, avec des interventions d'experts du domaine.

### Comptes et profils à suivre

Plutôt qu'une liste de noms qui deviendrait rapidement obsolète, voici les profils types à identifier et suivre dans l'écosystème de la formation.

Les **mainteneurs des projets** — Les développeurs principaux de Kubernetes, Debian, Prometheus, Terraform, Ansible publient régulièrement des analyses et des annonces. Leurs profils sont identifiables via les pages « Community » des projets.

Les **SIG leads Kubernetes** — Les responsables des Special Interest Groups (SIG Network, SIG Storage, SIG Security, etc.) partagent les évolutions en cours dans leur domaine.

Les **Developer Advocates** — Les équipes de developer relations des CNCF, Red Hat, HashiCorp, Grafana Labs et des cloud providers produisent du contenu pédagogique de qualité.

Les **auteurs de livres techniques** — Les auteurs d'ouvrages sur Kubernetes, Terraform ou l'administration Linux partagent régulièrement des compléments et des mises à jour.

---

## 7. Flux RSS et agrégateurs

### Flux RSS recommandés

La plupart des sources citées dans cette annexe exposent un flux RSS. Voici les flux à ajouter en priorité pour démarrer une veille structurée.

Pour l'**écosystème Debian** : le flux des DSA (Debian Security Advisories), le blog Bits from Debian, le Planet Debian et les notes de version.

Pour **Kubernetes et le cloud-native** : le blog Kubernetes, le blog CNCF, les releases de Kubernetes sur GitHub (`https://github.com/kubernetes/kubernetes/releases.atom`) et le blog Helm.

Pour l'**Infrastructure as Code** : les changelogs Terraform (`https://github.com/hashicorp/terraform/releases.atom`) et OpenTofu (`https://github.com/opentofu/opentofu/releases.atom`), le blog Ansible et les collections Ansible Galaxy.

Pour l'**observabilité** : le blog Grafana Labs, le blog Prometheus et le blog OpenTelemetry.

Pour la **sécurité** : les DSA Debian, les advisories des CVE Kubernetes, les releases de Trivy, Vault (`https://github.com/hashicorp/vault/releases.atom`) ou OpenBao (`https://github.com/openbao/openbao/releases.atom`), et les annonces Sigstore (`https://github.com/sigstore/cosign/releases.atom`).

### Surveiller les releases sur GitHub

Les pages de releases des projets hébergés sur GitHub exposent toutes un flux Atom. Ajouter ces flux à un lecteur RSS permet d'être informé des nouvelles versions sans consulter manuellement chaque projet.

```
https://github.com/<organisation>/<projet>/releases.atom
```

Les projets dont il est utile de suivre les releases sont notamment le noyau Linux (pour les noyaux Debian), Kubernetes, containerd, Helm (4.x depuis novembre 2025), ArgoCD (3.x depuis mai 2025), Flux, Terraform et OpenTofu, Vault (2.0 depuis avril 2026) et OpenBao, Ansible Core, Prometheus (3.x depuis novembre 2024), Grafana, Grafana Alloy (collecteur successeur de Promtail), Loki, Tempo, Mimir, Trivy, Cosign (Sigstore — 3.x depuis octobre 2025), Kyverno (CNCF graduated mars 2026), Falco (CNCF graduated février 2024), Cilium (1.18.x stable, 1.19 en pre-release) et Tetragon, **Velero** (sauvegarde Kubernetes), Istio (1.29.x avec mode Ambient GA depuis 1.22), et cert-manager. À surveiller particulièrement : les annonces de fin de vie ou de changement de licence (cas récents : MinIO Community archivé en avril 2026, Bitnami catalog déprécié en septembre 2025, Promtail EOL le 2 mars 2026).

---

## 8. Livres de référence

Les livres techniques offrent une profondeur d'analyse que les articles de blog et les newsletters ne peuvent pas atteindre. Quelques ouvrages font référence dans les domaines couverts par la formation.

En **administration Debian**, le Cahier de l'administrateur Debian (Raphaël Hertzog et Roland Mas) est l'ouvrage francophone de référence, disponible librement en ligne et dans les dépôts Debian.

En **administration Linux** au sens large, les ouvrages « UNIX and Linux System Administration Handbook » (Evi Nemeth et al.) et « How Linux Works » (Brian Ward) sont des classiques qui couvrent les fondamentaux avec une profondeur remarquable.

En **Kubernetes**, « Kubernetes: Up and Running » (Brendan Burns et al.) est l'introduction de référence, et « Kubernetes in Action » (Marko Lukša) offre un approfondissement complet. Pour la sécurité, « Hacking Kubernetes » (Andrew Martin et Michael Hausenblas) couvre les aspects offensifs et défensifs.

En **pratiques SRE**, « Site Reliability Engineering » et « The Site Reliability Workbook » (Google) sont les ouvrages fondateurs de la discipline. Ils sont disponibles gratuitement en ligne sur `https://sre.google/books/`.

En **Infrastructure as Code**, « Terraform: Up and Running » (Yevgeniy Brikman) est la référence pour Terraform, et « Ansible for DevOps » (Jeff Geerling) est l'ouvrage le plus recommandé pour Ansible.

En **observabilité**, « Observability Engineering » (Charity Majors et al.) pose les bases conceptuelles, et « Prometheus: Up and Running » (Brian Brazil) est la référence pour la stack Prometheus/Grafana.

---

## 9. Construire sa veille — Plan de démarrage

Pour un apprenant qui termine la formation et souhaite mettre en place sa veille, voici un plan de démarrage progressif.

**Semaine 1** — S'abonner à trois newsletters correspondant à son parcours : une newsletter généraliste DevOps (DevOps Weekly), une newsletter centrée sur sa technologie principale (KubeWeekly pour le parcours 3, par exemple) et le flux de sécurité Debian. Installer un lecteur RSS (FreshRSS, Miniflux ou Feedly).

**Semaine 2** — Ajouter cinq à dix flux RSS : le blog Kubernetes, le blog de deux ou trois sources techniques listées ci-dessus, et les releases GitHub des outils utilisés quotidiennement. Configurer un créneau hebdomadaire de 30 minutes pour la lecture.

**Semaine 3** — Identifier et suivre cinq à dix comptes pertinents sur LinkedIn ou Mastodon : mainteneurs de projets utilisés, developer advocates, auteurs de blogs déjà lus. S'inscrire à un meetup local.

**Mois 2** — Évaluer les sources : supprimer celles qui n'apportent pas de valeur, en ajouter de nouvelles découvertes via les lectures précédentes. Tester un podcast pendant les trajets.

**Mois 3 et au-delà** — La veille est installée comme habitude. L'ajuster au fil du temps en fonction des centres d'intérêt et des responsabilités professionnelles. Envisager de contribuer en retour : un article de blog, une présentation en meetup ou une réponse sur un forum sont d'excellents moyens de consolider ses connaissances tout en enrichissant la communauté.

---

## Synthèse des sources par parcours

| Source | Parcours 1 | Parcours 2 | Parcours 3 |
|--------|:---------:|:---------:|:---------:|
| LWN.net | ✔ | ✔ | |
| Debian Security RSS | ✔ | ✔ | ✔ |
| DevOps Weekly | | ✔ | ✔ |
| KubeWeekly | | ✔ | ✔ |
| SRE Weekly | | | ✔ |
| Blog Kubernetes | | ✔ | ✔ |
| Blog Grafana Labs | | | ✔ |
| Cloudflare Blog | | ✔ | ✔ |
| Julia Evans (jvns.ca) | ✔ | ✔ | |
| Blog Bortzmeyer | ✔ | ✔ | |
| CNCF YouTube | | ✔ | ✔ |
| Kubernetes Podcast | | | ✔ |
| NoLimitSecu (FR) | ✔ | ✔ | ✔ |
| Radio DevOps (FR) | | ✔ | ✔ |
| LinuxFr.org | ✔ | ✔ | |
| Le Journal du Hacker | ✔ | ✔ | ✔ |
| Hacker News | ✔ | ✔ | ✔ |

⏭️ [Certifications et évaluation](/annexes/E-certifications-evaluation.md)
