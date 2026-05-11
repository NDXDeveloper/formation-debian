🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 12.1 Cluster haute disponibilité

## Module 12 — Kubernetes Production · Parcours 2

---

## Introduction

Un cluster Kubernetes de développement ou de test peut fonctionner avec un seul nœud control plane sans conséquence majeure en cas de panne. En production, cette architecture devient un point de défaillance unique (*Single Point of Failure* — SPOF) inacceptable : si le control plane tombe, plus aucun nouveau pod ne peut être planifié, plus aucune réconciliation ne s'opère, et le cluster devient effectivement ingérable, même si les workloads existants continuent temporairement de tourner sur les workers.

La haute disponibilité (HA) d'un cluster Kubernetes consiste à éliminer ces SPOF à tous les niveaux de l'architecture — control plane, stockage d'état, réseau et nœuds de calcul — afin de garantir la continuité de service même en cas de défaillance matérielle, logicielle ou réseau.

---

## Pourquoi la haute disponibilité est indispensable en production

La question n'est pas *si* une panne surviendra, mais *quand*. Les causes de défaillance en environnement réel sont multiples et souvent imprévisibles :

- **Pannes matérielles** : disque défaillant, mémoire corrompue, alimentation ou carte réseau en erreur.
- **Pannes logicielles** : crash d'un composant du control plane (API Server, etcd, scheduler), bug noyau, OOM killer activé sur un processus critique.
- **Incidents réseau** : perte de connectivité entre nœuds, partition réseau (*split-brain*), latence excessive sur le lien vers etcd.
- **Maintenance planifiée** : mise à jour du noyau Debian, upgrade de version Kubernetes, remplacement d'un serveur — autant d'opérations qui nécessitent de pouvoir retirer temporairement un nœud sans impact sur le service.

Sans haute disponibilité, chacun de ces événements entraîne une interruption de la capacité de gestion du cluster, voire une perte de données d'état si etcd n'est pas répliqué.

---

## Les composants critiques à rendre hautement disponibles

Un cluster Kubernetes HA repose sur la redondance de plusieurs couches distinctes, chacune ayant ses propres contraintes et mécanismes.

### etcd — Le cerveau du cluster

etcd est la base de données distribuée clé-valeur qui stocke l'intégralité de l'état du cluster : définitions de ressources, état des pods, ConfigMaps, Secrets, leases, etc. C'est le composant le plus critique.

etcd utilise l'algorithme de consensus **Raft**, qui nécessite qu'une majorité de membres (un *quorum*) soit disponible pour accepter des écritures. Cela impose un nombre impair de nœuds etcd, avec les configurations les plus courantes :

| Nœuds etcd | Quorum requis | Tolérance de panne  |
|:----------:|:-------------:|:-------------------:|
| 1          | 1             | 0 nœud              |
| 3          | 2             | 1 nœud              |
| 5          | 3             | 2 nœuds             |
| 7          | 4             | 3 nœuds             |

En pratique, **3 nœuds etcd** représentent le standard pour la grande majorité des déploiements de production, offrant un bon compromis entre résilience et complexité opérationnelle. Au-delà de 5, la latence de consensus augmente sans bénéfice proportionnel.

### API Server — La porte d'entrée du cluster

L'API Server est le seul point d'accès au cluster pour tous les clients : `kubectl`, les kubelets, les controllers, le scheduler, les Ingress controllers, les opérateurs. Il est intrinsèquement *stateless* — tout son état est dans etcd — ce qui facilite grandement sa mise en haute disponibilité : il suffit d'en déployer plusieurs instances derrière un load balancer.

### Scheduler et Controller Manager

Le scheduler et le controller manager utilisent un mécanisme d'**élection de leader** (*leader election*) intégré. Lorsque plusieurs instances de ces composants tournent simultanément, une seule est active à un instant donné ; les autres restent en veille et prennent le relais automatiquement si le leader disparaît. Ce basculement s'effectue en quelques secondes grâce au système de *leases* Kubernetes.

### Load Balancer du control plane

Un load balancer placé devant les API Servers est essentiel pour distribuer les requêtes et assurer le basculement transparent. Plusieurs approches sont possibles sur une infrastructure Debian bare-metal :

- **HAProxy + Keepalived** : solution éprouvée qui combine un load balancer TCP/HTTP performant avec une VIP (*Virtual IP*) flottante via VRRP. C'est l'approche la plus courante en on-premise.
- **kube-vip** : solution plus récente, conçue spécifiquement pour Kubernetes, capable de fournir à la fois la VIP et le load balancing du control plane sans composant externe.
- **Load balancer matériel ou cloud** : dans les environnements cloud ou disposant d'un équipement réseau dédié (F5, Citrix), le load balancing est délégué à l'infrastructure sous-jacente.

### Nœuds worker

La redondance des workers est plus directe : il suffit de disposer de suffisamment de nœuds pour que la perte de l'un d'entre eux ne compromette pas la capacité de calcul. Kubernetes gère nativement le rescheduling des pods lorsqu'un nœud devient `NotReady`, à condition que les *PodDisruptionBudgets* et les *resource requests* soient correctement configurés.

---

## Topologies HA standard

Deux topologies principales existent pour déployer un cluster Kubernetes en haute disponibilité.

### Topologie « stacked » (empilée)

Dans cette topologie, chaque nœud control plane héberge à la fois les composants du control plane (API Server, scheduler, controller manager) et un membre etcd. C'est l'approche par défaut de `kubeadm`.

**Avantages** : moins de machines nécessaires, déploiement plus simple, communication locale entre l'API Server et etcd (faible latence).

**Inconvénients** : la perte d'un nœud control plane entraîne simultanément la perte d'un membre etcd. Avec 3 nœuds, la perte de 2 nœuds signifie à la fois la perte du quorum etcd et de la majorité des API Servers.

### Topologie « external etcd » (etcd externe)

Les membres etcd sont déployés sur des machines dédiées, séparées des nœuds control plane. L'API Server communique avec etcd via le réseau.

**Avantages** : découplage complet entre le control plane et le stockage d'état, possibilité de dimensionner indépendamment (disques rapides pour etcd, plus de CPU pour les API Servers), meilleure résilience globale.

**Inconvénients** : davantage de machines à gérer (minimum 6 au lieu de 3), latence réseau entre l'API Server et etcd à surveiller, complexité opérationnelle accrue.

Le choix entre les deux dépend de la criticité du service, du budget infrastructure et de la maturité opérationnelle de l'équipe. Pour la majorité des déploiements de production sur Debian, la topologie stacked à 3 nœuds constitue un point de départ solide.

---

## Spécificités de Debian pour un cluster HA

Déployer un cluster Kubernetes HA sur des nœuds Debian implique de prendre en compte certaines particularités de la distribution :

- **Stabilité des paquets** : Debian Stable privilégie la fiabilité sur la nouveauté. Les versions du noyau, de containerd et des bibliothèques système sont éprouvées, ce qui est un avantage en production. En contrepartie, certaines fonctionnalités récentes de Kubernetes peuvent nécessiter des ajustements (backports de noyau, configuration manuelle de cgroups v2).
- **Gestion du noyau** : les mises à jour du noyau nécessitent un reboot. En environnement HA, le processus de *rolling reboot* — drain d'un nœud, reboot, réintégration — doit être planifié et, idéalement, automatisé (par exemple avec `kured` pour Kubernetes).
- **Paramètres sysctl** : certains paramètres du noyau doivent être ajustés pour les workloads Kubernetes (forwarding IP, paramètres réseau bridge, limites de fichiers ouverts, taille des buffers réseau). Ces réglages sont persistés dans `/etc/sysctl.d/` et doivent être homogènes sur tous les nœuds du cluster.
- **Absence de swap** : par défaut, Kubernetes exige que le swap soit désactivé sur les nœuds. Sur Debian, cela implique de commenter les entrées swap dans `/etc/fstab` et de s'assurer que le swap reste désactivé après chaque redémarrage. Depuis Kubernetes 1.34 (août 2025, GA), le mode `LimitedSwap` opt-in permet aux pods **Burstable** d'utiliser le swap proportionnellement à leurs `requests` mémoire (les pods `Guaranteed` et `BestEffort` n'ont jamais accès au swap, par conception). L'activation requiert deux paramètres dans la `KubeletConfiguration` : `failSwapOn: false` (autoriser le démarrage du kubelet en présence de swap) **et** `memorySwap.swapBehavior: LimitedSwap` (activer effectivement l'allocation). Le détail de la configuration est traité en 12.1.4.
- **Systemd** : tous les composants du cluster (kubelet, containerd, HAProxy, keepalived, etcd dans le cas d'un déploiement external) sont gérés comme des services systemd, ce qui permet de bénéficier de la supervision, du redémarrage automatique et de la journalisation centralisée via `journald`.

---

## Prérequis pour cette section

Avant d'aborder les sous-sections de ce chapitre, il est attendu que le lecteur maîtrise les concepts suivants :

- Architecture générale d'un cluster Kubernetes (Module 11.1) : rôles du control plane et des workers, fonction de chaque composant.
- Installation d'un cluster avec `kubeadm` (Module 11.2) : processus d'initialisation, jonction de nœuds, fichier kubeconfig.
- Réseaux Kubernetes (Module 11.4) : modèle réseau, CNI, communication inter-pods et inter-nœuds.
- Services réseau Debian (Modules 6 et 8) : configuration réseau avancée, pare-feu, load balancing, DNS.
- systemd en profondeur (Module 3.4) : gestion des services, journald, timers.

---

## Plan de la section

Cette section 12.1 se décompose en quatre sous-parties qui couvrent l'ensemble du processus de mise en haute disponibilité d'un cluster Kubernetes sur Debian :

- **12.1.1 — Architecture multi-nœuds HA sur Debian** : conception de l'architecture, dimensionnement, choix de topologie et planification réseau.
- **12.1.2 — Configuration etcd en cluster** : déploiement, réplication, sécurisation TLS et opérations de maintenance d'un cluster etcd.
- **12.1.3 — Load balancing du control plane** : mise en place de HAProxy et Keepalived (ou kube-vip) pour l'accès aux API Servers.
- **12.1.4 — Tuning du noyau Debian pour workloads K8s** : optimisation des paramètres sysctl, ulimits, configuration cgroups v2 et bonnes pratiques de performance.

---

*Chacune de ces sous-sections abordera la théorie, la configuration détaillée et les points de vigilance opérationnels pour construire un cluster Kubernetes de production robuste et résilient sur infrastructure Debian.*

⏭️ [Architecture multi-nœuds HA sur Debian](/module-12-kubernetes-production/01.1-architecture-ha-debian.md)
