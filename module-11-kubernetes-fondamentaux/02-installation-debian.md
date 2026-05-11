🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 11.2 Installation sur Debian

## Introduction

La section 11.1 a posé les fondations théoriques : architecture du cluster, composants du plan de contrôle, nœuds de travail, modèle déclaratif et boucles de réconciliation. Cette section passe à la **pratique** : comment installer et faire fonctionner un cluster Kubernetes sur des serveurs Debian.

L'installation de Kubernetes n'est pas un acte unique avec une seule méthode. Il existe un éventail de distributions et d'outils d'installation, chacun adapté à un contexte différent — du poste de développeur qui a besoin d'un cluster éphémère en quelques secondes, jusqu'à l'infrastructure de production multi-nœuds qui exige un contrôle fin sur chaque composant. Le choix de la méthode d'installation est l'une des premières décisions structurantes d'un projet Kubernetes, et Debian, par sa stabilité et sa légèreté, se prête particulièrement bien à chacun de ces scénarios.

---

## Contexte : pourquoi plusieurs méthodes ?

Un cluster Kubernetes, même minimal, implique de coordonner plusieurs composants : un container runtime (containerd ou CRI-O), les binaires Kubernetes (kubelet, kubeadm, kubectl), un plugin réseau CNI, un service DNS interne (CoreDNS), des certificats TLS pour sécuriser les communications, et une base de données etcd. La manière dont ces composants sont installés, configurés et maintenus varie considérablement selon l'approche choisie.

Trois grandes philosophies d'installation se distinguent :

**Installation modulaire (kubeadm)** — L'outil officiel du projet Kubernetes. kubeadm installe un cluster « vanilla » en assemblant les composants upstream, sans couche d'abstraction ni simplification. L'opérateur conserve un contrôle total sur chaque composant et chaque paramètre. C'est l'approche de référence pour la production on-premise et pour la préparation à la certification CKA. En contrepartie, kubeadm exige une préparation minutieuse du système (prérequis noyau, container runtime, réseau) et laisse à l'opérateur la responsabilité de configurer la haute disponibilité, le plugin CNI et les add-ons.

**Distribution légère intégrée (K3s)** — K3s est une distribution Kubernetes certifiée, développée par SUSE (ex-Rancher Labs), qui empaquète l'ensemble du plan de contrôle dans un **binaire unique** d'environ 60 Mo. etcd est remplacé par défaut par SQLite (ou optionnellement par PostgreSQL/MySQL), le container runtime containerd est intégré, et un certain nombre de composants (Flannel CNI, CoreDNS, Traefik Ingress, local-path provisioner) sont pré-configurés. K3s est conçu pour les environnements à ressources limitées (edge, IoT, développement) mais est parfaitement utilisable en production légère.

**Distributions de développement local (MicroK8s, Kind, Minikube)** — Ces outils créent des clusters éphémères ou locaux, destinés au développement et aux tests. Kind (*Kubernetes in Docker*) exécute les nœuds Kubernetes comme des conteneurs Docker, ce qui permet de créer et détruire un cluster multi-nœuds en quelques secondes. MicroK8s (Canonical) est une distribution snap-based optimisée pour Ubuntu mais utilisable sur Debian. Minikube crée un cluster mono-nœud dans une machine virtuelle ou un conteneur.

---

## Le spectre des cas d'usage

Le tableau suivant positionne chaque méthode d'installation selon les critères les plus courants :

| Critère | kubeadm | K3s | Kind | MicroK8s |
|---------|---------|-----|------|----------|
| **Cas d'usage principal** | Production on-premise | Edge, dev, prod légère | Tests CI/CD, dev local | Dev local, prototypage |
| **Conformité CNCF** | Oui | Oui | Oui | Oui |
| **Complexité d'installation** | Élevée | Faible | Très faible | Faible |
| **Contrôle sur les composants** | Total | Partiel | Limité | Partiel |
| **Haute disponibilité** | Oui (manuelle) | Oui (intégrée) | Non | Oui (HA expérimental) |
| **Consommation de ressources** | Standard | Faible (~512 Mo RAM) | Très faible | Faible |
| **Container runtime** | Au choix | containerd intégré | containerd (dans Docker) | containerd intégré |
| **etcd** | Oui (standard) | SQLite / etcd / SQL | etcd (dans conteneur) | Dqlite |
| **CNI par défaut** | Aucun (au choix) | Flannel | kindnet | Calico |
| **Multi-nœuds** | Oui | Oui | Oui (simulé) | Oui |
| **Pertinence CKA/CKS** | Directe | Indirecte | Non | Non |
| **Support Debian natif** | Oui | Oui | Oui (via Docker) | Partiel (snap) |

---

## Debian comme socle : avantages spécifiques

Le choix de Debian comme système d'exploitation pour les nœuds Kubernetes n'est pas anodin. Plusieurs caractéristiques de Debian en font un socle particulièrement adapté :

**Cycle de release prévisible** — Debian Stable suit un cycle de release d'environ deux ans, avec un support de sécurité de trois ans (cinq ans avec LTS). Cette prévisibilité est précieuse pour la planification des mises à jour du cluster : on sait quand le système sous-jacent devra être mis à jour, et on peut aligner les upgrades Kubernetes avec les cycles Debian.

**Installation minimale** — Une installation serveur Debian sans environnement graphique (netinst) occupe moins de 500 Mo de disque et consomme moins de 100 Mo de RAM au repos. Cela laisse un maximum de ressources aux composants Kubernetes et aux workloads. À titre de comparaison, une installation serveur Ubuntu ou RHEL est significativement plus lourde par défaut.

**systemd comme standard** — Debian utilise systemd comme init system depuis Debian 8 (Jessie). Le kubelet s'exécute comme un service systemd, et les compétences acquises dans le Module 3 (gestion des services, journald, timers) sont directement transposables à la gestion de Kubernetes.

**Noyau récent et stable** — Debian 13 (Trixie) embarque un noyau 6.12 LTS, qui supporte pleinement cgroups v2, les namespaces user, les modules eBPF nécessaires à Cilium, et les fonctionnalités réseau modernes (nftables natif, WireGuard intégré). Ce noyau bénéficie des mises à jour de sécurité de Debian sans changement de version majeure.

**Gestion des paquets rigoureuse** — APT et dpkg (Module 4) permettent une gestion précise des versions de paquets installés, le pinning de versions spécifiques, et l'ajout contrôlé de dépôts tiers (dépôt Kubernetes, dépôt Docker). Ces mécanismes sont essentiels pour maintenir la cohérence des versions entre les composants Kubernetes.

**Images de conteneurs** — Les images `debian:trixie-slim` sont parmi les bases les plus populaires pour la construction d'images de conteneurs. Utiliser Debian à la fois comme OS hôte et comme base d'images simplifie la chaîne de maintenance : un seul écosystème de paquets à connaître, un seul flux de mises à jour de sécurité à surveiller.

---

## Version de Kubernetes et compatibilité

Kubernetes suit un cycle de release rapide : une version mineure tous les quatre mois environ (1.33 en avril 2025, 1.34 en août 2025, 1.35 en décembre 2025…). Chaque version mineure est supportée pendant environ 14 mois (patches de sécurité et corrections de bugs).

Plusieurs règles de compatibilité sont essentielles à connaître (politique officielle « version skew » de Kubernetes) :

**kubelet ↔ kube-apiserver** — Depuis Kubernetes 1.28, un kubelet peut être jusqu'à **3 versions mineures** plus ancien que le kube-apiserver (auparavant la limite était 2). Le kubelet ne peut en revanche jamais être plus récent que l'API Server. Concrètement, un API Server 1.36 accepte des kubelets en 1.33, 1.34, 1.35 ou 1.36 — mais pas 1.37. Cette tolérance permet de mettre à jour le plan de contrôle en avance, puis de migrer les nœuds de travail à un rythme adapté à l'opération.

**kube-proxy** — Doit être à la même version mineure que le kubelet du nœud, ou jusqu'à 3 versions plus ancien que kube-apiserver (mêmes règles que le kubelet).

**kube-apiserver entre instances HA** — Dans un cluster à plusieurs API Servers, toutes les instances doivent être à la même version mineure ou à une version mineure adjacente pendant une mise à jour (skew toléré : 1 version).

**kubectl** — L'outil client supporte un décalage d'**une version mineure dans les deux sens** par rapport à l'API Server. Un kubectl 1.34 peut interagir avec un API Server 1.33, 1.34 ou 1.35.

Cette politique permet les mises à jour progressives sans interruption de service : on met d'abord à jour le plan de contrôle (composant par composant), puis les nœuds de travail un par un, en respectant l'ordre kube-apiserver → controllers/scheduler → kubelet/kube-proxy.

Lors de l'installation sur Debian, il est recommandé de fixer la version de Kubernetes (via le pinning APT) pour éviter les mises à jour involontaires qui pourraient introduire une incompatibilité de version entre les nœuds.

---

## Architecture réseau : considérations préalables

Avant de commencer l'installation, la topologie réseau du cluster doit être planifiée. Trois plages d'adresses IP distinctes coexistent dans un cluster Kubernetes, et elles ne doivent pas se chevaucher entre elles ni avec le réseau existant de l'infrastructure :

**Réseau des nœuds** (*node network*) — Les adresses IP des serveurs Debian eux-mêmes, attribuées par l'infrastructure réseau existante (DHCP ou configuration statique). C'est le réseau « physique » sur lequel les nœuds communiquent. Exemple : `192.168.1.0/24`.

**Réseau des Pods** (*pod network* ou *cluster CIDR*) — La plage d'adresses IP attribuée aux Pods par le plugin CNI. Chaque Pod reçoit une IP unique dans cette plage. La taille de cette plage détermine le nombre maximum de Pods dans le cluster. Exemple : `10.244.0.0/16` (plage par défaut de Flannel), ce qui offre 65 534 adresses. Chaque nœud reçoit un sous-réseau (typiquement un `/24` offrant 254 adresses Pod par nœud).

**Réseau des Services** (*service network* ou *service CIDR*) — La plage d'adresses IP virtuelles attribuée aux Services (ClusterIP). Ces adresses n'existent pas sur le réseau physique — elles sont gérées par kube-proxy via des règles iptables/IPVS. Exemple : `10.96.0.0/12` (plage par défaut de kubeadm).

La planification de ces trois plages est une étape préalable indispensable. Un mauvais choix (chevauchement avec un réseau existant, plage trop petite) est difficile à corriger après l'installation du cluster.

---

## Ce que vous allez apprendre

Cette section 11.2 est découpée en cinq sous-chapitres qui couvrent l'ensemble du processus d'installation :

**11.2.1 — Prérequis système et préparation des nœuds Debian** : configuration du système d'exploitation, désactivation du swap, modules noyau, paramètres sysctl, installation du container runtime, préparation réseau. Ce sous-chapitre détaille toutes les étapes de préparation communes à toutes les méthodes d'installation.

**11.2.2 — Installation avec kubeadm** : installation pas à pas d'un cluster Kubernetes avec kubeadm sur Debian, de l'initialisation du premier nœud de contrôle à l'ajout de nœuds de travail, en passant par le choix et le déploiement du plugin CNI. C'est la méthode de référence pour la production et la certification CKA.

**11.2.3 — K3s (lightweight Kubernetes)** : installation et configuration de K3s sur Debian, y compris en mode multi-nœuds et haute disponibilité. Ce sous-chapitre présente les différences architecturales avec un cluster kubeadm et les compromis associés.

**11.2.4 — MicroK8s et Kind (développement local)** : mise en place d'environnements de développement Kubernetes sur un poste Debian, avec Kind pour les tests éphémères et MicroK8s pour un cluster local persistant.

**11.2.5 — Comparaison des distributions** : synthèse des critères de choix (performance, maintenabilité, conformité, écosystème) et recommandations selon le contexte (développement, staging, production, edge, formation).

---

## Prérequis pour cette section

Les compétences suivantes, acquises dans les modules précédents, sont directement mobilisées dans cette section :

- **Administration Debian** (Modules 3-4) : gestion des paquets avec APT, ajout de dépôts tiers, gestion des services systemd, configuration sysctl, manipulation des modules noyau.
- **Réseau** (Module 6) : configuration d'interfaces réseau, pare-feu nftables, diagnostic réseau (ip, ss, ping), concepts de NAT et de routage.
- **Conteneurs** (Module 10) : installation et configuration de containerd, concepts de namespaces, cgroups v2, images OCI.
- **Scripting** (Module 5) : automatisation des étapes répétitives d'installation et de configuration.

---

*Dans le sous-chapitre suivant (11.2.1), nous commencerons par préparer un nœud Debian pour qu'il puisse accueillir les composants Kubernetes — une étape fondamentale qui conditionne la réussite de toute installation, quelle que soit la méthode choisie.*

⏭️ [Prérequis système et préparation des nœuds Debian](/module-11-kubernetes-fondamentaux/02.1-prerequis-preparation-noeuds.md)
