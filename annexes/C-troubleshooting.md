🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe C — Troubleshooting par composant

## Formation Debian : du Desktop au Cloud-Native

---

## Présentation

Le diagnostic et la résolution de problèmes constituent une compétence centrale de l'administrateur système et de l'ingénieur DevOps/SRE. Quelle que soit la qualité de la configuration initiale, des incidents surviennent : un service refuse de démarrer après une mise à jour, un nœud Kubernetes passe en état `NotReady`, un conteneur entre en boucle de crash, un volume NFS ne se monte plus, les performances se dégradent brutalement sans raison apparente.

Cette annexe propose une approche structurée du troubleshooting, organisée par composant technique. Elle ne vise pas l'exhaustivité — chaque problème a sa spécificité — mais fournit une **méthodologie systématique** et un **catalogue des situations les plus fréquentes** avec leurs pistes de résolution.

---

## Méthodologie générale de diagnostic

Avant de plonger dans les guides spécifiques à chaque composant, il est essentiel de disposer d'une méthode de diagnostic reproductible. Face à un incident, la tentation est de chercher immédiatement la solution dans un moteur de recherche ou de modifier la configuration au hasard jusqu'à ce que le problème disparaisse. Cette approche est inefficace et dangereuse : elle masque souvent la cause réelle et introduit de nouvelles incohérences.

### La démarche en cinq étapes

La première étape est l'**observation**. Il s'agit de rassembler les faits sans interpréter : quel est le symptôme exact ? Depuis quand se manifeste-t-il ? Est-il constant ou intermittent ? Quels sont les utilisateurs ou services impactés ? Quel changement a précédé l'apparition du problème ? Cette étape repose principalement sur les logs (`journalctl`, logs applicatifs), les métriques (Prometheus, `top`, `vmstat`) et le retour des utilisateurs.

La deuxième étape est la **formulation d'hypothèses**. À partir des symptômes observés, on identifie les causes possibles en commençant par les plus probables. Un service qui ne démarre pas a probablement un problème de configuration, de dépendance ou de permissions. Un ralentissement progressif peut indiquer une fuite mémoire, une saturation disque ou un problème réseau. L'expérience et la connaissance de l'architecture du système guident cette étape.

La troisième étape est la **vérification**. Chaque hypothèse est testée méthodiquement, une à la fois, en utilisant les outils de diagnostic appropriés. On ne modifie rien à cette étape : on se contente de collecter des preuves pour confirmer ou infirmer chaque hypothèse. C'est la discipline la plus importante du troubleshooting : résister à la tentation de modifier le système avant d'avoir compris le problème.

La quatrième étape est la **résolution**. Une fois la cause identifiée avec certitude, on applique le correctif. Idéalement, ce correctif est d'abord testé dans un environnement non-production. En cas d'urgence sur un système de production, on documente précisément la modification effectuée pour pouvoir l'annuler si nécessaire.

La cinquième étape est le **post-mortem**. Après résolution, on documente l'incident : symptômes, cause racine, résolution, durée d'impact et actions préventives pour éviter la récurrence. Cette documentation enrichit les runbooks de l'équipe et réduit le temps de résolution des incidents futurs.

### Les réflexes universels

Quel que soit le composant en cause, certaines vérifications s'appliquent systématiquement.

Le premier réflexe est de consulter les logs. La commande `journalctl -u <service> --since "10 minutes ago"` couvre la majorité des cas pour les services systemd. Pour les applications conteneurisées, `docker logs <conteneur>` ou `kubectl logs <pod>` sont les équivalents. Les messages d'erreur sont souvent explicites et pointent directement vers la cause.

Le deuxième réflexe est de vérifier ce qui a changé. La commande `last` montre les connexions récentes. Le journal APT (`/var/log/apt/history.log`) liste les installations et mises à jour récentes. L'historique etckeeper (`cd /etc && git log --oneline -20`) révèle les modifications de configuration. L'historique shell (`history`) du ou des administrateurs ayant accès peut fournir des indices. Dans un contexte Kubernetes, `kubectl get events --sort-by=.metadata.creationTimestamp` et les logs ArgoCD/Flux montrent les changements récents.

Le troisième réflexe est de vérifier les ressources système. L'espace disque (`df -h`), la mémoire (`free -h`), le CPU (`top` ou `uptime` pour la charge) et les descripteurs de fichiers (`cat /proc/sys/fs/file-nr`) sont les quatre indicateurs à contrôler en priorité. Une saturation de l'un de ces quatre éléments est à l'origine d'une proportion très significative des incidents.

Le quatrième réflexe est de tester la connectivité. Si un service réseau est en cause, vérifier dans l'ordre : le service écoute-t-il (`ss -tlnp`) ? Le pare-feu autorise-t-il le trafic (`nft list ruleset` ou `ufw status`) ? La résolution DNS fonctionne-t-elle (`dig <domaine>`) ? La route réseau est-elle correcte (`ip route get <destination>`) ? Un test de bout en bout est-il possible (`curl -v <url>`) ?

---

## Structure de cette annexe

Les guides de diagnostic sont organisés en quatre sections, chacune ciblant un niveau de l'infrastructure.

### [C.1 — Guide diagnostic système Debian](/annexes/C.1-diagnostic-systeme.md)

Cette section couvre les problèmes au niveau du système d'exploitation lui-même : échecs de démarrage, services qui ne démarrent pas, problèmes de performances système, saturation des ressources, erreurs de paquets, dysfonctionnements d'authentification et de permissions. C'est le socle commun à tous les parcours de la formation, et les compétences qui y sont décrites s'appliquent à toute machine Debian, qu'elle serve de poste de travail, de serveur web ou de nœud Kubernetes.

Les catégories de problèmes traitées incluent les échecs de boot et GRUB, les services systemd en échec, les problèmes d'espace disque et d'inodes, les fuites mémoire et la saturation CPU, les erreurs APT et dpkg, les problèmes d'authentification PAM et sudo, ainsi que les dysfonctionnements matériels (disques, réseau, pilotes).

### [C.2 — Problèmes courants Kubernetes](/annexes/C.2-problemes-kubernetes.md)

Cette section aborde les incidents spécifiques aux clusters Kubernetes, depuis les problèmes de nœuds jusqu'aux dysfonctionnements applicatifs en passant par les erreurs de réseau et de stockage dans le cluster. Elle couvre les états anormaux des pods (`CrashLoopBackOff`, `ImagePullBackOff`, `Pending`, `OOMKilled`), les problèmes de nœuds (`NotReady`, pression de ressources), les erreurs de réseau interne (CNI, DNS CoreDNS, Ingress), les défaillances du control plane (API server, etcd, scheduler) et les problèmes de stockage persistant (PV/PVC non liés, erreurs de montage).

### [C.3 — Résolution réseau et stockage](/annexes/C.3-resolution-reseau-stockage.md)

Cette section traite des problèmes transversaux de réseau et de stockage qui affectent plusieurs couches de l'infrastructure. Elle couvre le diagnostic réseau à tous les niveaux du modèle OSI (couche physique, liaison, réseau, transport, application), les problèmes DNS (résolution, propagation, DNSSEC), les problèmes TLS/SSL (certificats expirés, chaîne de confiance, compatibilité de protocoles), les dysfonctionnements de pare-feu et de NAT, les pannes de stockage (RAID dégradé, LVM saturé, montages NFS perdus), les problèmes de conteneurs réseau (Docker networking, Kubernetes CNI, Service Mesh) et les problèmes de performances réseau (latence, perte de paquets, saturation de bande passante).

### [C.4 — Procédures recovery](/annexes/C.4-procedures-recovery.md)

Cette section fournit des procédures pas à pas pour les situations de recovery les plus critiques : restauration d'un système Debian qui ne démarre plus, récupération d'un cluster Kubernetes après une perte de nœuds ou une corruption etcd, restauration de bases de données à partir de sauvegardes, reconstruction d'un RAID dégradé et reprise après incident majeur. Chaque procédure est conçue pour être suivie sous pression, en situation d'urgence, avec un minimum de prérequis.

---

## Outils de diagnostic par couche

Le tableau ci-dessous récapitule les outils de diagnostic essentiels, classés par couche d'infrastructure. Chaque outil est détaillé dans la section appropriée.

| Couche | Outils principaux | Usage |
|--------|------------------|-------|
| Boot / noyau | `dmesg`, `journalctl -b`, `systemd-analyze` | Messages de démarrage, erreurs noyau |
| Services | `systemctl status`, `journalctl -u`, `strace` | État et logs des services |
| Processus | `ps`, `top`, `htop`, `pidstat`, `strace` | Activité et comportement des processus |
| Mémoire | `free`, `vmstat`, `slabtop`, `/proc/meminfo` | Utilisation et pression mémoire |
| CPU | `top`, `mpstat`, `perf`, `uptime` | Charge et distribution CPU |
| Disque | `df`, `du`, `iostat`, `iotop`, `smartctl` | Espace, I/O et santé des disques |
| Réseau L2-L3 | `ip`, `ping`, `traceroute`, `mtr`, `arping` | Connectivité et routage |
| Réseau L4 | `ss`, `tcpdump`, `nmap` | Ports, connexions, trafic |
| Réseau L7 | `curl`, `dig`, `openssl s_client` | HTTP, DNS, TLS |
| Pare-feu | `nft list`, `ufw status`, `conntrack` | Règles et suivi de connexions |
| Paquets | `apt`, `dpkg`, `debsums` | Intégrité et état des paquets |
| Docker | `docker logs`, `docker inspect`, `docker stats` | Conteneurs et images |
| Kubernetes | `kubectl describe`, `kubectl logs`, `kubectl events` | Pods, nœuds, ressources |
| Performances | `perf`, `bpftrace`, `flamegraph` | Profilage avancé |

---

## Niveaux de sévérité et temps de réponse

Dans un contexte professionnel, les incidents sont classés par niveau de sévérité qui détermine le temps de réponse attendu et les actions à entreprendre.

Un incident de **sévérité 1 (critique)** correspond à une interruption complète du service en production : le site est inaccessible, les données sont en danger, la sécurité est compromise. La réponse est immédiate, toute l'équipe concernée est mobilisée et la communication vers les parties prenantes est déclenchée. L'objectif est la restauration du service, même partielle, avant l'analyse de la cause racine.

Un incident de **sévérité 2 (majeur)** correspond à une dégradation significative du service : performances très dégradées, fonctionnalité importante indisponible, perte de redondance. La réponse se fait dans l'heure, un ingénieur est assigné et les contournements sont mis en place rapidement.

Un incident de **sévérité 3 (mineur)** correspond à un dysfonctionnement limité sans impact visible pour les utilisateurs : alerte de monitoring non critique, composant redondant en panne, dégradation de performances sous les seuils d'alerte. La résolution se fait dans les heures ou jours ouvrés suivants.

Un incident de **sévérité 4 (cosmétique)** correspond à une anomalie sans impact opérationnel : avertissement dans les logs, comportement non standard mais fonctionnel. La résolution est planifiée lors d'un sprint de maintenance.

---

## Correspondance avec les modules de la formation

| Section | Parcours | Modules principalement concernés |
|---------|----------|--------------------------------|
| C.1 — Système Debian | 1 | 1, 2, 3, 4, 5, 6, 7, 8 |
| C.2 — Kubernetes | 2, 3 | 11, 12, 14, 15, 16 |
| C.3 — Réseau et stockage | 1, 2, 3 | 6, 7, 8, 9, 10, 11, 17 |
| C.4 — Recovery | 1, 2, 3 | 8, 12, 19 |

---

## Comment utiliser cette annexe

**En situation d'incident** — Identifier d'abord la couche concernée (système, réseau, stockage, Kubernetes), puis consulter la section correspondante. Chaque problème est présenté avec ses symptômes, ses commandes de diagnostic et ses pistes de résolution. Il ne s'agit pas de lire ces sections de manière linéaire, mais de naviguer rapidement vers le problème rencontré.

**En prévention** — Parcourir les problèmes courants de chaque section permet d'anticiper les points de fragilité d'une infrastructure et de mettre en place les vérifications appropriées (monitoring, alertes, tests réguliers).

**En formation** — Les scénarios de troubleshooting constituent un excellent exercice de synthèse : résoudre un problème demande de mobiliser simultanément les connaissances réseau, système, service et sécurité acquises dans les différents modules.

**En préparation de certification** — Les examens CKA et CKS comportent une part significative de dépannage de clusters Kubernetes. La section C.2 couvre les situations les plus fréquemment rencontrées dans ces certifications.

---

> **Rappel méthodologique** — Face à un problème, la séquence la plus productive est toujours : lire les logs, vérifier ce qui a changé, contrôler les ressources, tester la connectivité, puis formuler et tester des hypothèses une par une. La précipitation est l'ennemi du diagnostic efficace.

⏭️ [Guide diagnostic système Debian](/annexes/C.1-diagnostic-systeme.md)
