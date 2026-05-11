🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 16.1 Hardening système Debian

## Prérequis

- Maîtrise de l'administration système Debian (Parcours 1, modules 3 à 8)
- Connaissances solides en réseau et sécurité (module 6)
- Expérience avec systemd, la gestion des services et des paquets
- Familiarité avec les concepts de conteneurisation et Kubernetes (modules 10 à 12)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre les principes fondamentaux du durcissement système et leur importance dans une stratégie de défense en profondeur
- Sécuriser le noyau Linux via les paramètres `sysctl`, le mode lockdown et les mécanismes de self-protection
- Configurer et exploiter AppArmor sur Debian pour confiner les applications et les services
- Auditer un système Debian selon les référentiels de conformité reconnus (CIS Benchmarks)
- Sécuriser la chaîne de démarrage avec Secure Boot et dm-verity
- Durcir la couche réseau et éliminer les surfaces d'attaque inutiles

---

## Introduction

Le **hardening** (ou durcissement) d'un système consiste à réduire sa surface d'attaque en éliminant tout ce qui n'est pas strictement nécessaire à son fonctionnement, puis en renforçant chaque composant restant. Sur Debian, cette démarche s'appuie sur une base solide : la distribution est réputée pour sa stabilité, la rigueur de son processus de packaging et sa politique de sécurité portée par l'équipe Debian Security. Cependant, une installation par défaut — même minimale — n'est jamais durcie. Elle constitue un point de départ fonctionnel, pas un état sécurisé.

Le durcissement n'est pas une action ponctuelle. C'est un processus continu, itératif, qui doit être intégré dès la conception de l'infrastructure et maintenu tout au long du cycle de vie du système. Un serveur durci à l'installation mais jamais audité par la suite finira par accumuler des dérives de configuration, des services ajoutés sans contrôle et des vulnérabilités non corrigées.

## Pourquoi durcir un système Debian ?

### La surface d'attaque par défaut

Une installation Debian, même en mode serveur minimal, embarque un certain nombre d'éléments qui élargissent la surface d'attaque sans nécessairement servir le rôle prévu de la machine. Parmi les points courants :

- Des **paramètres noyau permissifs** : le forwarding IP peut être activé, les ICMP redirects acceptés, le SYN flood insuffisamment mitigé. Ces réglages par défaut privilégient la compatibilité au détriment de la sécurité.
- Des **services actifs non nécessaires** : un démon SSH configuré avec des options par défaut, des services réseau en écoute sur `0.0.0.0`, des timers systemd superflus. Chaque port ouvert et chaque processus actif représente un vecteur d'attaque potentiel.
- Une **absence de confinement applicatif** : sans profils AppArmor activés et affinés, les applications s'exécutent avec l'intégralité des permissions de leur utilisateur système, sans cloisonnement supplémentaire.
- Un **boot non vérifié** : sans Secure Boot ni vérification d'intégrité du système de fichiers, rien ne garantit que le noyau et l'initramfs chargés au démarrage n'ont pas été altérés.

### La défense en profondeur

Le hardening s'inscrit dans une stratégie de **défense en profondeur** (*defense in depth*), où la sécurité ne repose jamais sur un seul mécanisme mais sur la superposition de plusieurs couches indépendantes. Chaque couche est conçue pour limiter l'impact d'une compromission de la couche précédente :

```
┌─────────────────────────────────────────────────────┐
│                   Couche physique                   │
│              (accès datacenter, BIOS)               │
├─────────────────────────────────────────────────────┤
│                 Chaîne de démarrage                 │
│           (Secure Boot, dm-verity, GRUB)            │
├─────────────────────────────────────────────────────┤
│                      Noyau                          │
│     (sysctl, lockdown, kernel self-protection)      │
├─────────────────────────────────────────────────────┤
│              Confinement applicatif                 │
│          (AppArmor, seccomp, capabilities)          │
├─────────────────────────────────────────────────────┤
│               Réseau et pare-feu                    │
│          (nftables, segmentation, VPN)              │
├─────────────────────────────────────────────────────┤
│              Audit et conformité                    │
│         (CIS Benchmarks, AIDE, auditd)              │
└─────────────────────────────────────────────────────┘
```

Si un attaquant parvient à exploiter une vulnérabilité applicative, le confinement AppArmor limite les actions qu'il peut effectuer. S'il réussit à contourner AppArmor, les protections noyau (`lockdown`, restrictions `sysctl`) bloquent l'escalade de privilèges. S'il parvient néanmoins à modifier le système, l'audit détecte la modification. Aucune couche n'est infaillible isolément ; c'est leur combinaison qui rend l'exploitation réellement difficile.

## Principes fondamentaux du durcissement

### Principe du moindre privilège

Chaque utilisateur, processus et service ne doit disposer que des permissions strictement nécessaires à l'accomplissement de sa fonction. Ce principe se décline à tous les niveaux :

- **Utilisateurs** : pas de connexion root directe, utilisation de `sudo` avec des règles granulaires, comptes de service dédiés avec shells restreints (`/usr/sbin/nologin`).
- **Processus** : exécution sous des utilisateurs non privilégiés, suppression des capabilities Linux inutiles, confinement par AppArmor ou seccomp.
- **Réseau** : services en écoute uniquement sur les interfaces nécessaires (`127.0.0.1` ou l'IP de gestion plutôt que `0.0.0.0`), pare-feu en politique `drop` par défaut.

### Réduction de la surface d'attaque

Tout composant non utilisé est un vecteur potentiel. Le durcissement passe par l'élimination systématique du superflu :

- Désinstallation des paquets non nécessaires au rôle de la machine
- Désactivation des services inutiles (`systemctl disable --now`)
- Suppression des comptes utilisateurs obsolètes
- Fermeture des ports non utilisés
- Retrait des modules noyau non nécessaires (chargement contrôlé via `/etc/modprobe.d/`)

### Immutabilité et vérification d'intégrité

Dans les architectures modernes, en particulier cloud-native, le paradigme évolue vers des systèmes **immutables** où les modifications en place sont proscrites. Toute modification passe par un redéploiement. Même sur des systèmes plus classiques, la vérification d'intégrité reste essentielle :

- Contrôle de l'intégrité des fichiers critiques (AIDE, dm-verity)
- Vérification de la chaîne de démarrage (Secure Boot)
- Signatures des paquets et vérification GPG systématique

### Traçabilité et auditabilité

Un système durci est un système dont on peut reconstituer l'historique. La journalisation complète et la conservation des logs sont indissociables du hardening :

- Activation d'`auditd` pour tracer les accès aux fichiers sensibles, les changements de privilèges et les appels système critiques
- Centralisation des logs vers un collecteur distant (les logs locaux peuvent être altérés en cas de compromission)
- Horodatage fiable via NTP pour garantir la cohérence des traces

## Hardening Debian dans le contexte cloud-native

Le durcissement système ne s'arrête pas aux serveurs traditionnels. Dans un environnement cloud-native, il prend une dimension supplémentaire :

- Les **nœuds Kubernetes** sont des serveurs Debian dont le noyau et la configuration système ont un impact direct sur la sécurité de tous les workloads qui y sont exécutés. Un nœud mal durci compromet l'ensemble des pods qu'il héberge.
- Les **images de conteneurs** basées sur Debian (y compris les variantes `slim`) héritent de certains comportements par défaut qu'il faut maîtriser et restreindre.
- Les **pipelines CI/CD** qui s'exécutent sur des runners Debian doivent être durcis pour éviter qu'un pipeline compromis ne devienne un pivot vers l'infrastructure.

Les principes restent les mêmes — moindre privilège, réduction de la surface, vérification d'intégrité — mais leur mise en œuvre s'adapte au contexte. Les sections suivantes de ce module couvriront ces aspects en détail.

## Plan de la section

Cette section est organisée en cinq sous-parties, chacune ciblant une couche spécifique du durcissement :

**16.1.1 — Sécurisation du noyau** : paramétrage de `sysctl` pour restreindre les comportements réseau et système, activation du mode lockdown, mécanismes de kernel self-protection (KASLR, stack protector, SMEP/SMAP).

**16.1.2 — AppArmor sur Debian** : fonctionnement du framework de confinement mandatory access control (MAC) par défaut de Debian, gestion des profils, modes enforce et complain, création de profils personnalisés.

**16.1.3 — Audit et conformité** : utilisation des CIS Benchmarks pour Debian comme référentiel d'audit, automatisation des vérifications avec des outils comme Lynis et OpenSCAP, intégration dans un processus de conformité continue.

**16.1.4 — Sécurisation du boot** : mise en place de Secure Boot sur Debian, vérification de l'intégrité du système de fichiers avec dm-verity, protection du bootloader GRUB.

**16.1.5 — Durcissement réseau et services** : identification et fermeture des ports inutiles, restriction des services au strict nécessaire, configuration réseau défensive, réduction de l'exposition réseau.

---

## Résumé

> Le hardening système Debian est un processus structuré de réduction de la surface d'attaque et de renforcement de chaque couche du système. Il repose sur quatre principes directeurs — moindre privilège, réduction de la surface, immutabilité/intégrité et traçabilité — appliqués de manière systématique du noyau jusqu'au réseau. Dans un contexte cloud-native, ces pratiques sont d'autant plus critiques qu'un nœud compromis peut affecter l'ensemble des workloads qu'il héberge. Les cinq sous-sections suivantes détaillent la mise en œuvre concrète de chaque couche de durcissement sur Debian.

⏭️ [Sécurisation du noyau (sysctl, lockdown mode, kernel self-protection)](/module-16-securite-avancee/01.1-securisation-noyau.md)
