🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 12.2 Sécurité du cluster

## Module 12 — Kubernetes Production · Parcours 2

---

## Introduction

Un cluster Kubernetes de production est, par nature, un système complexe et exposé. Il orchestre des conteneurs provenant de sources variées, expose des services sur le réseau, manipule des secrets et des données sensibles, et offre une API puissante capable de créer, modifier ou détruire des ressources à grande échelle. Sans mesures de sécurité rigoureuses, cette puissance devient une surface d'attaque considérable.

La sécurité d'un cluster Kubernetes ne se réduit pas à un périmètre unique ni à un outil miracle. Elle s'articule en couches successives — de l'authentification des utilisateurs au cloisonnement réseau des pods, en passant par le contrôle de ce que chaque conteneur est autorisé à exécuter. Cette approche en profondeur, connue sous le nom de *defense in depth*, garantit que la compromission d'une couche ne suffit pas à compromettre l'ensemble du système.

---

## Le modèle de menaces Kubernetes

Pour sécuriser efficacement un cluster, il faut d'abord comprendre *contre quoi* on se protège. Le modèle de menaces Kubernetes identifie plusieurs vecteurs d'attaque, chacun ciblant un composant ou un mécanisme différent.

### Les acteurs de la menace

**L'utilisateur interne malveillant ou négligent** : un développeur disposant d'un accès légitime au cluster qui, intentionnellement ou par erreur, déploie un conteneur avec des privilèges excessifs, exfiltre des Secrets, ou consomme toutes les ressources disponibles au détriment des autres équipes.

**Le conteneur compromis** : une application conteneurisée présentant une vulnérabilité (injection SQL, RCE, dépendance vérolée) qui est exploitée par un attaquant externe. Le conteneur compromis tente alors de se propager latéralement dans le cluster, d'accéder à l'API Server, de lire les Secrets montés ou de compromettre le nœud hôte.

**L'attaquant externe** : un acteur qui cible les services exposés publiquement (Ingress, NodePort, API Server mal configuré) pour obtenir un point d'entrée initial dans le cluster.

**La supply chain compromise** : une image de conteneur contenant du code malveillant (backdoor, cryptominer, exfiltration de données) introduite via un registre public, une dépendance compromise ou un pipeline CI/CD altéré.

### Les cibles critiques

| Cible | Impact d'une compromission | Mécanisme de protection |
|:------|:---------------------------|:-----------------------|
| API Server | Contrôle total du cluster | RBAC, authentification forte, audit |
| etcd | Accès à tous les Secrets et à l'état complet | TLS mutuel, accès restreint, chiffrement at-rest |
| Kubelet | Exécution arbitraire de conteneurs sur le nœud | Authentification, autorisation webhook |
| Secrets Kubernetes | Exposition de credentials, tokens, clés | Chiffrement, RBAC, rotation, external secrets |
| Réseau inter-pods | Mouvement latéral entre services | Network Policies, micro-segmentation |
| Nœud hôte | Évasion de conteneur, accès root au nœud | Pod Security Standards, Seccomp, AppArmor |

---

## Les quatre piliers de la sécurité Kubernetes

La sécurité d'un cluster de production repose sur quatre piliers complémentaires, souvent désignés par le modèle des **4C** (*Cloud, Cluster, Container, Code*) adapté ici au contexte d'un cluster Kubernetes sur Debian.

### Pilier 1 — Contrôle d'accès (Qui peut faire quoi ?)

C'est la première ligne de défense : s'assurer que chaque entité (utilisateur humain, service account, composant du cluster) ne dispose que des permissions strictement nécessaires à sa fonction. Le principe du *least privilege* (moindre privilège) est le fondement de cette couche.

Les mécanismes Kubernetes associés sont le RBAC (*Role-Based Access Control*), les ServiceAccounts, l'authentification via certificats, tokens OIDC ou webhooks, et l'audit logging qui trace toutes les actions effectuées sur l'API Server.

### Pilier 2 — Sécurité des workloads (Que peuvent faire les pods ?)

Même avec un RBAC parfait, un pod peut être dangereux s'il s'exécute en tant que root, monte le filesystem de l'hôte, ou utilise des capabilities Linux excessives. Cette couche contrôle *ce que les conteneurs sont autorisés à faire* au niveau système, indépendamment de l'identité de celui qui les a déployés.

Les Pod Security Standards, les Admission Controllers et les profils Seccomp/AppArmor constituent les mécanismes de cette couche.

### Pilier 3 — Sécurité réseau (Qui peut communiquer avec qui ?)

Par défaut, tout pod dans un cluster Kubernetes peut communiquer avec n'importe quel autre pod, quel que soit le namespace. Ce comportement *open by default* est commode pour le développement mais inacceptable en production. La segmentation réseau via les Network Policies permet de restreindre les communications aux seuls flux légitimes.

### Pilier 4 — Gouvernance des ressources (Combien peut consommer chaque tenant ?)

Dans un cluster partagé entre plusieurs équipes ou applications, un workload mal dimensionné ou malveillant peut consommer la totalité des ressources (CPU, mémoire, stockage) et provoquer un déni de service pour les autres. Les Resource Quotas et LimitRanges établissent des garde-fous qui garantissent un partage équitable et prévisible des ressources.

---

## Principes de sécurité directeurs

Au-delà des mécanismes techniques, plusieurs principes guident les décisions de sécurité tout au long de cette section.

**Least privilege (moindre privilège)** : chaque entité — utilisateur, service account, pod, conteneur — ne doit disposer que des permissions minimales nécessaires à l'accomplissement de sa fonction. Un développeur qui déploie des applications n'a pas besoin d'accéder aux Secrets du namespace `kube-system`. Un pod qui sert une API REST n'a pas besoin de la capability `SYS_ADMIN`.

**Defense in depth (défense en profondeur)** : aucun mécanisme de sécurité n'est infaillible. La superposition de plusieurs couches de protection — RBAC, Pod Security Standards, Network Policies, chiffrement — garantit qu'un attaquant doit franchir plusieurs barrières pour atteindre son objectif.

**Deny by default (refus par défaut)** : toute action, toute communication, tout accès doit être explicitement autorisé. Ce principe s'applique au RBAC (pas de ClusterRoleBinding `cluster-admin` par défaut pour les utilisateurs), aux Network Policies (politique de refus global puis ouvertures ciblées) et aux Pod Security Standards (mode `Restricted` comme baseline).

**Immutabilité** : les conteneurs en production doivent être traités comme immuables. Pas de shell interactif, pas de modification du filesystem racine, pas d'installation de paquets à chaud. Toute modification passe par une nouvelle image construite via le pipeline CI/CD. Ce principe réduit considérablement la surface d'attaque d'un conteneur compromis.

**Auditabilité** : chaque action sensible doit être tracée, horodatée et attribuable à une identité. L'audit logging de l'API Server, combiné à un pipeline de centralisation des logs (cf. Module 15), permet la détection d'anomalies et l'investigation post-incident.

---

## État de la sécurité par défaut d'un cluster kubeadm sur Debian

Un cluster fraîchement initialisé avec `kubeadm` sur Debian dispose de certaines protections de base, mais présente également des lacunes significatives qu'il faut combler avant toute mise en production.

### Ce qui est sécurisé par défaut

- **TLS entre les composants** : toutes les communications entre l'API Server, etcd, les kubelets et kube-proxy sont chiffrées et authentifiées par des certificats TLS générés automatiquement par kubeadm.
- **RBAC activé** : le mode d'autorisation RBAC est activé par défaut. L'API Server refuse les requêtes non autorisées.
- **Taint sur le control plane** : le taint `node-role.kubernetes.io/control-plane:NoSchedule` empêche les pods applicatifs de s'exécuter sur les nœuds control plane.
- **Authentification kubelet** : les kubelets s'authentifient auprès de l'API Server via des certificats clients.

### Ce qui n'est PAS sécurisé par défaut

- **Pas de Pod Security Standards appliqués** : aucune restriction n'est imposée sur les pods. Un utilisateur peut déployer un conteneur en mode `privileged: true` avec un accès complet au nœud hôte.
- **Pas de Network Policies** : tous les pods peuvent communiquer librement entre eux, sans aucune restriction.
- **Pas de Resource Quotas** : aucune limite de consommation n'est définie. Un seul pod peut consommer toutes les ressources d'un nœud.
- **Secrets non chiffrés at-rest** : les Secrets Kubernetes sont stockés en clair (encodés en base64, mais non chiffrés) dans etcd. Pour activer le chiffrement, configurer un `EncryptionConfiguration` avec un provider local (`aescbc`, `aesgcm`) ou un fournisseur KMS externe (HashiCorp Vault, AWS KMS, GCP KMS, Azure Key Vault) via le mécanisme **KMS v2** (stable depuis Kubernetes 1.29 ; KMS v1 est déprécié et désactivé par défaut). Cette configuration est traitée en détail dans le Module 16.3.
- **Audit logging désactivé** : par défaut, l'API Server ne journalise pas les actions effectuées.
- **ServiceAccount par défaut monté automatiquement** : chaque pod reçoit automatiquement un token de service account, même s'il n'en a pas besoin, offrant un accès potentiel à l'API Server.
- **API Server potentiellement exposé** : si le pare-feu du nœud n'est pas correctement configuré, le port 6443 est accessible depuis n'importe quelle source.

Chacune de ces lacunes est adressée dans les sous-sections qui suivent.

---

## Matrice des responsabilités

La sécurité d'un cluster Kubernetes est une responsabilité partagée entre plusieurs rôles au sein de l'organisation. La matrice suivante clarifie qui est responsable de quoi :

| Domaine de sécurité | Administrateur cluster | Développeur / DevOps | Équipe sécurité |
|:---------------------|:----------------------:|:--------------------:|:---------------:|
| RBAC et ServiceAccounts | Définit les rôles et bindings | Respecte le périmètre attribué | Audite les permissions |
| Pod Security Standards | Applique les politiques par namespace | Adapte les manifestes aux contraintes | Définit le niveau de restriction |
| Network Policies | Déploie les politiques par défaut | Définit les flux de ses applications | Valide les règles de segmentation |
| Resource Quotas | Définit les quotas par namespace | Dimensionne ses requests/limits | Surveille la consommation |
| Chiffrement des Secrets | Configure le chiffrement at-rest | Utilise les mécanismes fournis | Audite l'accès aux Secrets |
| Audit logging | Active et configure l'audit | — | Analyse les logs d'audit |
| Hardening des nœuds | Applique les CIS benchmarks | — | Vérifie la conformité |

---

## Prérequis pour cette section

Cette section s'appuie sur les connaissances acquises dans les sections et modules suivants :

- Architecture d'un cluster Kubernetes (Module 11.1) : compréhension des composants du control plane et de leur rôle.
- Ressources fondamentales (Module 11.3) : Pods, Deployments, Services, Namespaces, ConfigMaps, Secrets.
- Réseau Kubernetes (Module 11.4) : modèle réseau, CNI, communication inter-pods.
- Cluster haute disponibilité (Section 12.1) : architecture du cluster, TLS etcd, configuration du load balancer.
- Sécurité système Debian (Module 6.2) : pare-feu nftables, SSH, principes de hardening.

---

## Plan de la section

Cette section 12.2 se décompose en quatre sous-parties qui couvrent les quatre piliers de la sécurité identifiés précédemment :

- **12.2.1 — RBAC et ServiceAccounts** : configuration fine du contrôle d'accès, rôles, bindings, service accounts, authentification et audit. C'est le pilier « Qui peut faire quoi ? ».
- **12.2.2 — Pod Security Standards (admission control)** : application des politiques de sécurité aux pods, niveaux Privileged/Baseline/Restricted, admission controllers et migration depuis les PodSecurityPolicies. C'est le pilier « Que peuvent faire les pods ? ».
- **12.2.3 — Network Policies et micro-segmentation** : restriction des communications réseau entre pods et namespaces, politiques par défaut, intégration avec les CNI. C'est le pilier « Qui peut communiquer avec qui ? ».
- **12.2.4 — Resource Quotas et LimitRanges** : gouvernance des ressources, quotas par namespace, limites par défaut, prévention du déni de service interne. C'est le pilier « Combien peut consommer chaque tenant ? ».

Ces quatre sous-sections forment un ensemble cohérent. Elles sont conçues pour être appliquées conjointement : un cluster où le RBAC est parfait mais sans Network Policies reste vulnérable au mouvement latéral ; un cluster avec des Network Policies strictes mais sans Pod Security Standards reste exposé à l'évasion de conteneur.

---

*La sécurité n'est pas un état atteint une fois pour toutes, mais un processus continu d'évaluation, de renforcement et de surveillance. Les sous-sections qui suivent fournissent les fondations techniques de ce processus pour un cluster Kubernetes de production sur Debian.*

⏭️ [RBAC et ServiceAccounts](/module-12-kubernetes-production/02.1-rbac-serviceaccounts.md)
