🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 19.5 Disaster Recovery et résilience

## Parcours 2-3 — Concevoir, tester et opérer une infrastructure capable de survivre aux pannes les plus graves

---

## Objectifs de la section

À l'issue de cette section, vous serez en mesure de :

- Comprendre les concepts fondamentaux de la résilience et du Disaster Recovery (DR) et leur application à une infrastructure hybride Debian/Kubernetes.
- Dimensionner les objectifs de reprise (RTO/RPO) en fonction des exigences métier et des contraintes techniques.
- Concevoir des architectures résilientes à différents niveaux de panne (composant, nœud, rack, datacenter, région).
- Intégrer les principes du Chaos Engineering pour valider proactivement la résilience de l'infrastructure.
- Structurer des runbooks de reprise automatisés et testés régulièrement.
- Articuler le DR avec l'ensemble de l'infrastructure construite dans les sections précédentes (cluster HA, GitOps, monitoring, plateforme).

---

## Pourquoi le Disaster Recovery ?

### L'illusion de la disponibilité

L'infrastructure construite dans les sections 19.2 et 19.3 est robuste : cluster Kubernetes HA avec 3 control planes, stockage Ceph répliqué, services DNS en maître/esclave, pipeline CI/CD redondant, monitoring avec alertes. Cette architecture tolère la perte d'un nœud, d'un disque, d'un pod sans interruption de service. Mais elle ne tolère pas tous les scénarios.

Que se passe-t-il si le datacenter entier subit une coupure électrique prolongée ? Si un incendie détruit les serveurs physiques ? Si une erreur humaine supprime l'intégralité du namespace de production ? Si une attaque ransomware chiffre les données du cluster etcd ? Si le provider de la ligne dédiée vers le cloud subit une panne de plusieurs jours ?

Ces scénarios ne sont pas théoriques. L'incendie du datacenter OVH à Strasbourg en mars 2021 a détruit des milliers de serveurs. Des erreurs `kubectl delete namespace production` se produisent dans des organisations réelles. Les attaques ransomware ciblant les infrastructures IT sont en augmentation constante. Chaque organisation qui dépend de son infrastructure informatique doit se poser la question : « que se passe-t-il quand l'impensable se produit ? ».

Le Disaster Recovery est la réponse structurée à cette question.

### Ce que le DR n'est pas

Le DR n'est pas la haute disponibilité. La haute disponibilité (HA) protège contre les pannes courantes et prévisibles : perte d'un nœud, crash d'un pod, défaillance d'un disque. Le DR protège contre les pannes majeures et souvent imprévisibles : perte d'un site entier, corruption généralisée des données, compromission de sécurité.

Le DR n'est pas la sauvegarde. La sauvegarde est un composant du DR, mais elle ne suffit pas. Avoir un backup d'etcd ne sert à rien si l'on ne sait pas le restaurer, si le processus n'a jamais été testé, ou si le backup est stocké dans le même datacenter que le cluster qu'il protège.

Le DR n'est pas un projet ponctuel. C'est un processus continu qui doit être conçu, implémenté, testé, mis à jour et re-testé régulièrement. Un plan de DR non testé est une fausse assurance.

---

## Concepts fondamentaux

### RTO et RPO

Deux métriques définissent les exigences de Disaster Recovery :

**RPO (Recovery Point Objective)** — La quantité maximale de données que l'organisation accepte de perdre en cas de sinistre. Un RPO de 1 heure signifie que les sauvegardes doivent être réalisées au moins toutes les heures, et que l'organisation accepte de perdre au maximum 1 heure de données.

**RTO (Recovery Time Objective)** — Le temps maximal acceptable pour restaurer le service après un sinistre. Un RTO de 4 heures signifie que le service doit être opérationnel dans les 4 heures suivant la déclaration du sinistre.

```
         Temps ────────────────────────────────────────────►

         Dernière        Sinistre           Service
         sauvegarde      se produit         restauré
              │               │                  │
              ▼               ▼                  ▼
    ──────────●───────────────●──────────────────●──────────
              │◄─────────────►│◄────────────────►│
              │               │                  │
              │     RPO       │       RTO        │
              │ (données      │  (temps de       │
              │  perdues)     │   reprise)       │
```

### Dimensionnement RTO/RPO par service

Chaque service de l'infrastructure n'a pas les mêmes exigences. Un service de facturation qui perd 24 heures de données est un problème majeur ; un service de cache qui perd ses données est un inconvénient mineur. Le dimensionnement doit être discuté avec les parties prenantes métier et formalisé.

| Service | RPO | RTO | Justification |
|---|---|---|---|
| Base de données GestCom | 1 heure | 2 heures | Données transactionnelles critiques |
| Fichiers uploads GestCom | 24 heures | 4 heures | Moins volatils, re-créables partiellement |
| Cluster etcd Kubernetes | 6 heures | 4 heures | Cluster reconstituable, mais données d'état à restaurer |
| Configuration GitOps (Git) | ~0 (répliqué) | 1 heure | Git est distribué, chaque clone est un backup |
| Registry Harbor (images) | 24 heures | 4 heures | Images reconstruisibles depuis le code source |
| Monitoring (Prometheus) | 48 heures | 8 heures | Métriques historiques, pas critique opérationnellement |
| DNS (zones BIND9) | 1 heure | 30 minutes | Service de niveau 0, zones petites et rapides à restaurer |
| Mail (boîtes Dovecot) | 4 heures | 4 heures | Données utilisateur importantes |
| Serveur DHCP (baux Kea) | 24 heures | 1 heure | Baux recréés automatiquement par les clients |

Le coût du DR augmente de manière exponentielle quand le RPO et le RTO diminuent. Un RPO de 0 (zéro perte de données) nécessite une réplication synchrone en temps réel vers un site distant — techniquement complexe et coûteux. Un RPO de 24 heures nécessite un simple backup quotidien — simple et économique. Le bon dimensionnement est celui qui aligne le coût du DR avec la criticité métier.

### Niveaux de panne

Les pannes sont classées par périmètre d'impact, chacun nécessitant des mécanismes de protection différents :

```
Niveau 5 : RÉGION / MULTI-SITE
├── Catastrophe naturelle, coupure réseau nationale
├── Protection : architecture multi-région, DR cross-cloud
│
Niveau 4 : DATACENTER / SITE
├── Incendie, inondation, panne électrique prolongée, vol
├── Protection : site de repli, backups hors site, réplication
│
Niveau 3 : RACK / ZONE
├── Panne d'alimentation d'un rack, défaillance switch
├── Protection : distribution sur plusieurs racks (topologySpreadConstraints)
│
Niveau 2 : SERVEUR / NŒUD
├── Panne matérielle, crash noyau, disque défaillant
├── Protection : HA Kubernetes, réplication etcd, RAID
│
Niveau 1 : SERVICE / POD
├── Crash applicatif, OOM, erreur de configuration
├── Protection : restart automatique, PDB, rolling updates
│
Niveau 0 : ERREUR HUMAINE / SÉCURITÉ
├── Suppression accidentelle, ransomware, compromission
├── Protection : RBAC, backups immuables, GitOps, audit
```

L'infrastructure construite en section 19.2 protège nativement contre les niveaux 1 à 3. Cette section étend la protection aux niveaux 4 et 5, et renforce la protection contre le niveau 0 (souvent le plus fréquent et le plus destructeur).

---

## Architecture de DR de référence

### Vue d'ensemble

L'architecture de DR s'appuie sur trois piliers : la **réplication** (copier les données critiques vers un site distant en continu ou périodiquement), le **plan de reprise** (procédures documentées et testées pour restaurer les services) et la **validation** (tests réguliers prouvant que le plan fonctionne).

```
┌──────────────────────────────────────┐    ┌──────────────────────────────────┐
│         SITE PRINCIPAL (DC1)         │    │      SITE DE REPLI (DR)          │
│                                      │    │                                  │
│  ┌──────────────────────────────┐    │    │  ┌──────────────────────────┐    │
│  │ Cluster K8s HA (production)  │    │    │  │ Cluster K8s (standby)    │    │
│  │ 3 CP + 3+ Workers            │    │    │  │ ou reconstituable        │    │
│  └──────────┬───────────────────┘    │    │  └──────────────────────────┘    │
│             │                        │    │           ▲                      │
│  ┌──────────▼───────────────────┐    │    │  ┌────────┴─────────────────┐    │
│  │ Données                      │    │    │  │ Données répliquées       │    │
│  │ · etcd (snapshots)           │────┼────┼──► · etcd snapshots         │    │
│  │ · MySQL/PostgreSQL           │────┼────┼──► · DB répliquées          │    │
│  │ · Fichiers (uploads, PVC)    │────┼────┼──► · Fichiers synchronisés  │    │
│  │ · Configs (Git — distribué)  │    │    │  │ · Configs (clone Git)    │    │
│  └──────────────────────────────┘    │    │  └──────────────────────────┘    │
│                                      │    │                                  │
│  ┌──────────────────────────────┐    │    │  ┌──────────────────────────┐    │
│  │ Services infra (bare-metal)  │    │    │  │ Services infra (standby) │    │
│  │ DNS, DHCP, Mail, Proxy       │    │    │  │ DNS secondaire actif     │    │
│  └──────────────────────────────┘    │    │  │ Autres : cold standby    │    │
│                                      │    │  └──────────────────────────┘    │
└──────────────────────────────────────┘    └──────────────────────────────────┘
           │                                                 ▲
           │              Réplication                        │
           │  ┌───────────────────────────────────────┐      │
           └──┤ Lien dédié / VPN / Internet           ├──────┘
              │ · BorgBackup (incrémental chiffré)    │
              │ · Réplication MySQL async             │
              │ · Velero (backups K8s)                │
              │ · rsync / rclone (fichiers)           │
              └───────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│                     CLOUD (troisième copie)                   │
│  · Backups chiffrés dans S3 (règle 3-2-1)                     │
│  · Images de conteneurs répliquées dans ECR/GCR               │
│  · GitOps repo miroir (GitLab → GitHub/GitLab cloud)          │
└───────────────────────────────────────────────────────────────┘
```

### La règle 3-2-1 (et son extension moderne 3-2-1-1-0)

La règle historique 3-2-1 reste la fondation de la protection des données :

**3 copies** de chaque donnée critique (l'original + 2 copies).  
**2 supports** différents (par exemple, disque SSD local + stockage objet distant).  
**1 copie hors site** (dans un lieu géographiquement séparé du site principal).  

Pour l'infrastructure hybride Debian/Kubernetes, cela se traduit concrètement par la copie 1 (originale) qui vit dans le cluster de production (etcd, bases de données, PVC), la copie 2 (sur site) qui est un backup sur un serveur de sauvegarde dans le même datacenter (BorgBackup, snapshots), et la copie 3 (hors site) qui est un backup chiffré dans un bucket S3 cloud ou sur un serveur dans un datacenter distant.

> **Évolution 2026 — la règle 3-2-1-1-0** : face à la généralisation des ransomwares (qui chiffrent en priorité les cibles de sauvegarde réseau-accessibles avant de toucher la production), la règle historique 3-2-1 a été étendue en **3-2-1-1-0**, désormais considérée comme le standard de référence par la majorité des éditeurs et frameworks de sauvegarde :  
>  
> - **+ 1 copie immuable ou air-gapped** — au moins une copie doit être inaccessible aux processus d'écriture du SI (object lock S3 / WORM, bande LTO hors-ligne, immutable backup d'un appliance dédié). Borg supporte le mode `--append-only` côté repository ; restic + REST server peuvent être configurés en mode append-only ; AWS S3 Object Lock fournit le niveau matériel équivalent dans le cloud.  
> - **+ 0 erreur** — chaque backup doit être *vérifié* (lecture intégrale + checksum) et au moins une restauration test est réalisée régulièrement (typiquement chaque mois pour les jeux critiques, chaque trimestre pour le reste). La maxime « un backup non testé n'est pas un backup » est ici formalisée — la sous-section 19.5.4 détaille la mise en œuvre.  
>  
> Concrètement pour cette architecture de référence : la copie 3 (cloud) est versionnée avec object lock (≥ 30 jours), un repository BorgBackup `--append-only` est dédié à la rétention longue, et un cron mensuel exécute un test de restauration vers un environnement isolé.

### Modes de reprise

Le site de repli peut fonctionner selon trois modes, du plus coûteux au plus économique :

**Hot standby.** Le site de repli est un clone opérationnel du site principal. Les données sont répliquées en quasi temps réel. La bascule prend quelques minutes. Ce mode offre le RTO le plus bas mais double le coût d'infrastructure. Il est justifié pour les services dont le RTO est inférieur à 30 minutes.

**Warm standby.** Le site de repli dispose de l'infrastructure (serveurs, réseau) mais les services ne tournent pas ou tournent en mode minimal. Les données sont répliquées périodiquement (toutes les heures). La bascule nécessite le démarrage des services et la restauration des données les plus récentes. Le RTO typique est de 1 à 4 heures. C'est le compromis le plus courant pour les infrastructures d'entreprise.

**Cold standby.** Le site de repli est un espace réservé (espace rack, connectivité réseau) mais sans matériel actif. Les backups sont stockés hors site. La reprise nécessite l'installation et la configuration de l'infrastructure à partir de zéro, guidée par les playbooks Ansible et les backups. Le RTO est de plusieurs heures à plusieurs jours. Ce mode est adapté aux services avec un RTO supérieur à 8 heures.

Pour l'architecture de référence de cette formation, le mode **warm standby** est recommandé : un second datacenter (ou une zone cloud) dispose de l'infrastructure de base, les données critiques sont répliquées périodiquement, et les procédures de reprise sont documentées et testées.

---

## Les composants du DR dans notre architecture

### Ce qui est déjà résilient

Plusieurs composants de l'architecture construite dans les sections précédentes sont intrinsèquement résilients au Disaster Recovery :

**Le code source et les configurations (Git).** Git est un système distribué. Chaque clone du dépôt (sur les postes développeurs, les runners CI, le serveur GitLab, un miroir) est un backup complet. La perte du serveur GitLab n'entraîne pas la perte du code — il peut être restauré depuis n'importe quel clone. Le GitOps repo, qui décrit l'état complet de l'infrastructure Kubernetes, est également protégé par cette distribution naturelle.

**Les images de conteneurs (Harbor).** Les images sont reconstruisibles à partir du code source via le pipeline CI/CD. La perte du registry Harbor est un inconvénient (temps de rebuild) mais pas une perte de données irréversible. La réplication Harbor vers un registry cloud (cf. section 19.2.4) ajoute une couche de protection.

**L'infrastructure as Code (Ansible, Terraform).** L'infrastructure physique et cloud est décrite de manière déclarative dans des playbooks et des fichiers Terraform versionnés dans Git. Un datacenter entièrement détruit peut être reconstruit à partir de ces définitions, à condition de disposer du matériel.

### Ce qui nécessite une protection DR spécifique

**Les données d'état** sont le cœur du problème DR. Les bases de données applicatives (MySQL, PostgreSQL) contiennent les données métier qui ne sont pas reconstruisibles. Les snapshots etcd contiennent l'état du cluster Kubernetes. Les fichiers uploadés par les utilisateurs (factures, documents) sont des données uniques. Les boîtes mail contiennent des communications non reproductibles.

**Les secrets et certificats** (clés GPG, certificats TLS, clés de chiffrement LUKS, tokens Vault) sont critiques : leur perte rend les données chiffrées inaccessibles, même si les backups sont intacts.

**La configuration runtime** (baux DHCP, état des sessions, cache) est généralement reconstructible automatiquement mais sa perte peut causer une interruption temporaire.

---

## Positionnement dans la formation

Cette section est transversale aux Parcours 2 et 3. Elle s'appuie sur les compétences et l'infrastructure suivantes :

| Composant DR | Modules et sections de référence |
|---|---|
| Sauvegarde etcd | Section 19.2.2 (cluster HA), Module 12 (cycle de vie cluster) |
| Réplication de bases de données | Module 7 (sauvegarde et restauration) |
| Backup avec BorgBackup/restic | Module 8 (stratégies de sauvegarde, RTO/RPO) |
| Velero pour Kubernetes | Module 12 (sauvegarde etcd et Velero) |
| Architecture multi-site | Section 19.2.1 (conception on-premise + cloud) |
| Monitoring et alertes | Module 15, section 19.2.3 (monitoring unifié) |
| Runbooks et gestion d'incidents | Section 19.2.5 (procédures d'exploitation) |
| Chaos Engineering | Section 19.5.2 (concepts et outils, traités dans cette section) |
| GitOps et reconstruction | Section 19.3.3 (GitOps workflow complet) |
| Ansible pour le reprovisionnement | Module 13, section 19.2.1 (IaC multi-cible) |

---

## Plan de la section

Cette section se décompose en quatre sous-parties couvrant les différentes facettes du Disaster Recovery :

- **19.5.1 — Architectures multi-région et cross-cloud** : conception d'un site de repli, réplication des données entre sites, bascule DNS, DR sur cloud public, coûts et compromis.

- **19.5.2 — Chaos Engineering (principes et outils)** : principes du Chaos Engineering, mise en place de Litmus ou Chaos Mesh sur le cluster Debian, conception d'expériences de chaos, game days et culture de la résilience.

- **19.5.3 — Runbooks automatisés et réponse aux incidents** : automatisation des procédures de reprise avec Ansible, intégration avec le monitoring pour le déclenchement automatique, escalade et communication pendant un sinistre, coordination multi-équipes.

- **19.5.4 — RTO/RPO : dimensionnement et validation** : méthodologie de dimensionnement RTO/RPO, tests de restauration planifiés, métriques de validation, rapport de conformité DR et processus d'amélioration continue.

---

*Prérequis : Parcours 2 complet (Modules 9 à 13), sections 19.2.1 à 19.2.5 (architecture hybride), Module 8 (sauvegarde et haute disponibilité), Module 12 (cycle de vie cluster Kubernetes).*

⏭️ [Architectures multi-région et cross-cloud](/module-19-architectures-reference/05.1-multi-region-cross-cloud.md)
