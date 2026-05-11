🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 8.5 RAID, LVM et haute disponibilité

*Module 8 — Services réseau avancés, sauvegarde et HA · Niveau : Avancé*

---

## Introduction

Cette section clôt le module 8 par le second pilier de la résilience d'une infrastructure : la **haute disponibilité** (*High Availability*, HA). Là où la sauvegarde (traitée en 8.4) répond à la question « comment revenir à un état antérieur en cas de perte ? », la haute disponibilité répond à une question différente : « comment éviter que la panne se voie du côté des utilisateurs ? ». Les deux disciplines sont complémentaires et toutes deux nécessaires. Un système avec sauvegarde mais sans HA fonctionne après restauration, mais il a été indisponible pendant l'incident. Un système avec HA mais sans sauvegarde ne connaît pas d'interruption, mais il peut perdre toutes ses données si une corruption se propage ou si les deux nœuds tombent.

Les mécanismes de haute disponibilité se déploient à plusieurs couches de la pile logicielle. Au niveau **stockage**, la redondance RAID protège contre la panne d'un disque ; LVM apporte de la flexibilité et des fonctionnalités comme les snapshots. Au niveau **système**, la surveillance SMART détecte les disques en fin de vie avant la panne effective. Au niveau **service**, des mécanismes comme Pacemaker et Corosync permettent à plusieurs nœuds de coopérer pour maintenir un service disponible malgré la perte de l'un. Au niveau **réseau**, des load balancers comme HAProxy distribuent la charge entre plusieurs serveurs et redirigent automatiquement le trafic en cas de défaillance, et Keepalived gère le basculement d'adresses IP virtuelles.

Cette section présente ces technologies dans un ordre qui suit la progression de la pile : on commence par le stockage physique (RAID, LVM), on remonte vers la surveillance des disques (SMART), puis vers les mécanismes de clustering (Pacemaker, Corosync), le load balancing (HAProxy, Keepalived), et enfin le monitoring qui lie le tout. L'objectif est que vous disposiez d'une compréhension structurée de ces briques, de leurs forces et limites respectives, et de la manière dont elles se combinent dans des architectures complètes.

## Rappels fondamentaux

Avant d'entrer dans les technologies, quelques concepts structurent toute discussion sur la haute disponibilité.

### Disponibilité vs durabilité

Deux propriétés distinctes des systèmes doivent être différenciées.

La **disponibilité** (*availability*) mesure la fraction du temps pendant laquelle un service répond correctement aux requêtes. Elle s'exprime en pourcentage et se décline traditionnellement en « neufs » : 99 % (88 heures d'indisponibilité par an), 99,9 % (« trois neufs », 8h45), 99,99 % (« quatre neufs », 53 minutes), 99,999 % (« cinq neufs », 5 minutes). Chaque neuf supplémentaire coûte environ un ordre de grandeur plus cher à atteindre.

La **durabilité** (*durability*) mesure la probabilité que les données ne soient pas perdues à long terme. Un système peut être durable sans être disponible (vos archives sont sauves mais inaccessibles pendant une heure) ou disponible sans être durable (le service répond toujours mais les données récentes peuvent disparaître en cas de panne subtile).

Les mécanismes de cette section ciblent principalement la **disponibilité**. Ceux de la section 8.4 ciblent principalement la **durabilité**. Les deux sont nécessaires : un service durable mais souvent indisponible frustre les utilisateurs ; un service toujours disponible qui perd des données n'est pas fiable.

### Les niveaux de résilience

On peut classer les niveaux de résilience d'un système selon les pannes qu'il supporte sans indisponibilité visible.

**Niveau 0 : aucune résilience.** Toute panne entraîne une indisponibilité. Typique d'un serveur simple avec un disque, un CPU, une alimentation. Adapté uniquement aux environnements où une interruption est acceptable.

**Niveau 1 : résilience matérielle locale.** Le serveur est équipé de composants redondants : deux alimentations, RAID sur plusieurs disques, mémoire ECC. La panne d'un composant matériel isolé ne provoque pas d'indisponibilité. Mais la panne du serveur entier (CPU, carte mère, kernel crash, coupure réseau locale) reste fatale.

**Niveau 2 : résilience au niveau du serveur.** Plusieurs serveurs assurent le service, avec un mécanisme de bascule en cas de panne de l'un d'eux. La panne complète d'un serveur est absorbée. Mais la panne du site entier (datacenter, salle) reste fatale.

**Niveau 3 : résilience au niveau du site.** Plusieurs sites géographiquement distribués, avec bascule inter-sites. La panne d'un site est absorbée. Niveau habituel pour les infrastructures critiques — banques, santé, services cloud majeurs.

**Niveau 4 : résilience multi-région/continent.** Plusieurs régions, bascule continentale. Typique des grandes plateformes internet et de certains systèmes de paiement.

Chaque niveau supplémentaire coûte plus cher, ajoute de la complexité, et protège contre des événements de plus en plus rares. Le niveau cible est une décision métier, alignée avec les RTO/RPO vus en 8.4.5.

### La chaîne de disponibilité

Un service en production fait intervenir de nombreux composants, chacun avec sa propre disponibilité. La disponibilité globale est limitée par le **maillon faible** de la chaîne — elle est le **produit** des disponibilités individuelles quand les composants sont en série.

Exemple : un service web dépend de :
- Connexion Internet : 99,9 %
- Serveur web : 99,9 %
- Serveur de base de données : 99,9 %
- Stockage : 99,9 %

Disponibilité globale : 0,999 × 0,999 × 0,999 × 0,999 ≈ **99,6 %** — moins que chaque composant individuel. Cette multiplication explique pourquoi atteindre 99,99 % demande que chaque composant soit à 99,995 % ou plus, ou que plusieurs composants soient en parallèle (la redondance multiplie la *fiabilité*, pas la disponibilité individuelle).

La haute disponibilité consiste à identifier les maillons faibles de la chaîne et à les renforcer — soit par la qualité intrinsèque (matériel plus fiable), soit par la redondance (plusieurs exemplaires en parallèle).

### Ce que la HA ne résout pas

La haute disponibilité a des limites intrinsèques qu'il faut connaître.

**Elle ne protège pas contre les erreurs logiques.** Un `rm -rf` exécuté sur un cluster est exécuté sur tous les nœuds. Une mise à jour applicative buggée est déployée sur tous les serveurs. La réplication synchrone propage immédiatement la corruption.

**Elle n'élimine pas la panne, elle la rend invisible au bon endroit.** Les composants défaillent encore, simplement les clients ne le voient pas. L'équipe opérationnelle, elle, doit détecter et réparer pour restaurer la redondance.

**Elle introduit sa propre complexité.** Un système à deux nœuds HA est plus complexe qu'un système à un nœud. Il y a plus de choses qui peuvent casser. Paradoxalement, la HA mal faite peut **réduire** la disponibilité en ajoutant des modes de défaillance nouveaux (split-brain, désynchronisation, bascules intempestives).

**Elle n'est pas une substitution à la sauvegarde.** La redondance protège contre la panne matérielle ; elle ne protège pas contre la suppression, la corruption, le rançongiciel. Les deux sont complémentaires, pas substituables.

**Elle coûte cher.** En matériel, en licences, en bande passante, en complexité opérationnelle, en temps humain. Le retour sur investissement doit être analysé service par service.

## Les couches de haute disponibilité

Une architecture HA complète empile plusieurs couches de résilience, chacune protégeant contre un type de panne différent.

### Couche matérielle et stockage

À la base, le matériel physique et son stockage. **Le RAID** (*Redundant Array of Independent Disks*) distribue les données sur plusieurs disques pour protéger contre la panne de l'un ou de plusieurs. **LVM** (*Logical Volume Manager*) apporte une couche d'abstraction flexible au-dessus des disques ou du RAID, permettant de gérer dynamiquement l'espace (redimensionnement, snapshots, déplacement). **SMART** (*Self-Monitoring, Analysis and Reporting Technology*) surveille les indicateurs internes des disques pour détecter les pannes naissantes.

Au-delà du stockage, la couche matérielle inclut les alimentations redondantes, la mémoire ECC, les cartes réseau en bonding. Ces aspects sont traités brièvement par les fournisseurs de matériel serveur ; ils ne font pas l'objet de sous-sections dédiées dans ce chapitre parce qu'ils sont largement dépendants du matériel utilisé.

### Couche système d'exploitation et services

Au niveau du système, des mécanismes comme **Pacemaker** et **Corosync** permettent à plusieurs nœuds de coopérer pour maintenir un service. Corosync est la couche de communication de bas niveau (messagerie entre nœuds, détection de la vivacité) ; Pacemaker est le gestionnaire de ressources qui décide où les services doivent tourner et orchestre les bascules.

Cette couche est complémentaire à la couche matérielle : RAID protège contre la panne d'un disque, Pacemaker protège contre la panne complète d'un serveur.

### Couche réseau et équilibrage

**HAProxy** et les équilibreurs de charge distribuent les requêtes entrantes entre plusieurs serveurs et détectent automatiquement ceux qui sont défaillants. **Keepalived** utilise le protocole VRRP pour gérer des adresses IP virtuelles qui migrent entre plusieurs serveurs selon leur disponibilité.

Ces outils sont souvent le point d'entrée visible de l'architecture HA : c'est par eux que les clients atteignent le service, et c'est eux qui masquent les pannes en redirigeant le trafic.

### Couche applicative et monitoring

Certaines applications modernes ont leur propre logique de HA : bases de données (PostgreSQL streaming replication, MySQL Group Replication, MongoDB replica sets), file systems distribués (Ceph, GlusterFS), et bien sûr Kubernetes qui est essentiellement une plateforme de HA pour conteneurs (traité dans le parcours 2, modules 11-12).

Au-dessus de tout cela, le **monitoring** surveille l'état de chaque composant, détecte les défaillances, déclenche les alertes, parfois orchestre les actions automatiques. Sans monitoring, la HA est aveugle : on ne sait pas qu'un nœud est tombé jusqu'à ce que le dernier tombe. La section 15 (Parcours 3) approfondit ce sujet ; la sous-section 8.5.6 traite spécifiquement le failover automatique dans le cadre HA.

## Enjeux en 2026

Le paysage de la haute disponibilité a évolué avec les technologies modernes, en particulier le cloud et les conteneurs.

### Le cloud-native vs l'infrastructure classique

Les services cloud offrent souvent la haute disponibilité comme propriété native des offres managées : bases de données avec réplication multi-AZ, stockage objet répliqué par design, load balancers managés, Kubernetes managé. Pour un déploiement cloud, beaucoup des mécanismes traités dans cette section sont fournis par le prestataire — on ne configure pas de RAID sur une instance AWS, on choisit une classe de stockage adaptée.

Pour les **déploiements Debian classiques** (ceux auxquels cette section s'adresse principalement), les mécanismes restent à mettre en place manuellement. Ce qui, d'un point de vue pédagogique, est une bonne nouvelle : comprendre RAID et Pacemaker donne une compréhension profonde de ce que le cloud automatise sous le capot. Un ingénieur qui comprend ces mécanismes lit les documentations cloud avec une vision claire de ce qui se passe.

Le choix entre cloud managé et infrastructure classique est avant tout un choix économique et stratégique, pas purement technique. Beaucoup d'organisations maintiennent des deux : cloud pour certains services, infrastructure dédiée pour d'autres.

### Coûts et complexité

Chaque niveau de HA supplémentaire multiplie au moins par deux le matériel nécessaire (deux serveurs au lieu d'un, deux datacenters au lieu d'un), introduit une complexité opérationnelle importante (synchronisation, détection de panne, bascule, tests), et demande des compétences plus pointues. Le retour sur investissement se calcule service par service :

- Pour un service peu critique, la simplicité d'un serveur unique avec sauvegarde rapide suffit généralement.
- Pour un service Tier 2, la HA locale (RAID + deux serveurs en cluster) est un bon compromis.
- Pour un service Tier 1, la HA multi-site devient pertinente.

Le piège est d'appliquer uniformément le même niveau partout : sur-investir sur des services secondaires, sous-investir sur des services critiques.

### Choix techniques vs organisationnels

Certains problèmes qui se présentent comme techniques sont en réalité organisationnels. Un service qui tombe toutes les semaines à cause d'un bug applicatif ne sera pas sauvé par du RAID ou un cluster Pacemaker — il faut corriger le bug. Un service qui est indisponible parce qu'un administrateur unique est en vacances ne sera pas sauvé par de la HA technique — il faut former une équipe.

La haute disponibilité technique est un pilier de la résilience, mais elle ne se substitue pas à une organisation saine : tests de charge, revues de code, procédures d'astreinte, formation continue, culture de la fiabilité.

## Les technologies couvertes dans cette section

La section 8.5 est organisée en six sous-parties.

La sous-section **8.5.1 — Configuration RAID logiciel (mdadm)** présente les concepts RAID (niveaux 0, 1, 5, 6, 10) et leur implémentation Linux via `mdadm`. Création d'un array, monitoring, remplacement de disque défaillant, considérations de performance selon le niveau choisi.

La sous-section **8.5.2 — LVM (Logical Volume Manager)** explore la couche d'abstraction LVM : physical volumes, volume groups, logical volumes, snapshots, thin provisioning, redimensionnement dynamique. LVM est un compagnon essentiel du RAID et se combine avec lui pour offrir flexibilité et résilience au niveau stockage.

La sous-section **8.5.3 — Surveillance des disques (SMART)** traite la détection précoce des défaillances de disques via `smartctl` et `smartd`. Comment interpréter les attributs SMART, configurer des tests automatiques, alerter avant la panne effective pour remplacer sereinement.

La sous-section **8.5.4 — Clustering avec Pacemaker/Corosync** monte d'un cran : comment faire coopérer plusieurs serveurs Debian pour maintenir un service disponible même en cas de panne d'un nœud. Architecture, primitives de ressources, contraintes, gestion des failovers, fencing.

La sous-section **8.5.5 — Load balancing (HAProxy, Keepalived)** couvre les deux outils qui forment l'épine dorsale de la HA de services TCP/HTTP. HAProxy pour la répartition de charge et les health checks, Keepalived pour la gestion des VIP via VRRP. Configurations classiques actif-passif et actif-actif.

La sous-section **8.5.6 — Monitoring et failover automatique** ferme le chapitre en reliant les sujets précédents : comment surveiller un système en HA pour détecter les dérives (perte de redondance, désynchronisation), déclencher les bonnes alertes, piloter éventuellement des actions automatiques de remédiation, et intégrer le tout dans une chaîne de supervision globale.

## Objectifs pédagogiques

À l'issue de cette section, vous serez en mesure de concevoir et déployer une infrastructure Debian avec redondance à plusieurs niveaux : RAID logiciel pour la protection des disques, LVM pour la flexibilité du stockage, SMART pour la surveillance proactive, cluster Pacemaker/Corosync pour des services hautement disponibles, HAProxy et Keepalived pour la distribution du trafic et les VIP. Vous saurez dimensionner ces mécanismes en fonction des besoins (RTO/RPO définis en 8.4.5), en comprendre les coûts et les limites, et les articuler avec les services d'infrastructure vus dans les sections précédentes (DNS, DHCP, mail).

Cette section conclut le **module 8** et le **Parcours 1** (Administrateur Système Debian). Les compétences acquises dans ce parcours — administration système, réseau, services d'infrastructure, sauvegarde, haute disponibilité — forment une base solide pour aborder le Parcours 2 (Ingénieur Infrastructure et Conteneurs) qui introduit la virtualisation, la conteneurisation, Kubernetes et l'Infrastructure as Code. Les concepts de résilience vus ici sont précisément ce que les orchestrateurs modernes automatisent : comprendre RAID et Pacemaker en 2026 éclaire la logique des StatefulSets Kubernetes et des volumes persistants distribués.

---


⏭️ [Configuration RAID logiciel (mdadm)](/module-08-services-avances-sauvegarde-ha/05.1-raid-mdadm.md)
