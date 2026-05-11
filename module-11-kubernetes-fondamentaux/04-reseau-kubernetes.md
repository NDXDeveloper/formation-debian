🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 11.4 Réseau Kubernetes

## Introduction

Les sections précédentes ont couvert le déploiement des applications (Pods, Deployments), leur exposition interne (Services) et leur configuration (ConfigMaps, Secrets). Cette section plonge dans la couche qui rend tout cela possible : le **réseau**.

Le réseau Kubernetes est souvent perçu comme l'aspect le plus complexe de la plateforme. Cette réputation n'est pas usurpée : contrairement à un serveur Debian classique où la configuration réseau se résume à une interface, une adresse IP et une route par défaut, un cluster Kubernetes superpose plusieurs couches de réseau — réseau des nœuds, réseau des Pods, réseau des Services, réseau d'Ingress — chacune avec ses propres mécanismes et abstractions. Comprendre ces couches est indispensable pour diagnostiquer les problèmes de connectivité, concevoir des architectures performantes et sécuriser les communications.

Cette section ne réexplique pas les fondamentaux réseau TCP/IP couverts dans le Module 6 (interfaces, routage, pare-feu, DNS). Elle se concentre sur les spécificités du réseau dans Kubernetes : le modèle réseau et ses exigences, les plugins CNI qui l'implémentent, les Ingress Controllers qui exposent les applications HTTP/HTTPS, et le DNS interne qui permet la découverte de services.

---

## Les couches du réseau Kubernetes

Un cluster Kubernetes fait coexister quatre couches réseau distinctes, chacune opérant à un niveau différent :

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  COUCHE 4 — INGRESS                                             │
│  Routage HTTP/HTTPS depuis l'extérieur vers les Services        │
│  (NGINX Ingress, Traefik, Cilium Gateway API)                   │
│  → Noms d'hôte, chemins URL, terminaison TLS                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  COUCHE 3 — SERVICES                                            │
│  Adresses IP virtuelles stables pour accéder aux Pods           │
│  (kube-proxy : iptables / IPVS / nftables)                      │
│  → ClusterIP, NodePort, LoadBalancer                            │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  COUCHE 2 — RÉSEAU DES PODS (CNI)                               │
│  Attribution d'IP aux Pods et routage inter-nœuds               │
│  (Flannel, Calico, Cilium)                                      │
│  → Chaque Pod a sa propre adresse IP routable                   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  COUCHE 1 — RÉSEAU DES NŒUDS                                    │
│  Réseau physique/virtuel entre les serveurs Debian              │
│  (Ethernet, systemd-networkd, bridges, VLANs)                   │
│  → Infrastructure existante, non gérée par Kubernetes           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Couche 1 — Réseau des nœuds** : le réseau « traditionnel » entre les serveurs Debian. C'est l'infrastructure sous-jacente que Kubernetes utilise sans la gérer. Chaque nœud a une adresse IP sur ce réseau, configurée selon les méthodes vues dans le Module 6 (systemd-networkd, `/etc/network/interfaces`). Ce réseau doit permettre la communication entre tous les nœuds du cluster sur les ports requis par Kubernetes (6443, 10250, etc.).

**Couche 2 — Réseau des Pods** : un réseau virtuel superposé (*overlay*) ou routé qui attribue une adresse IP unique à chaque Pod et permet la communication directe entre tous les Pods du cluster, quel que soit le nœud sur lequel ils se trouvent. Ce réseau est implémenté par un **plugin CNI** (Container Network Interface). C'est la couche la plus spécifique à Kubernetes.

**Couche 3 — Réseau des Services** : une couche d'abstraction qui fournit des adresses IP virtuelles stables (ClusterIP) pour accéder à des groupes de Pods. Cette couche est implémentée par **kube-proxy** (ou par Cilium en mode kube-proxy replacement) via des règles iptables, nftables ou IPVS. Les Services ont été couverts en détail dans le sous-chapitre 11.3.2.

**Couche 4 — Ingress** : une couche de routage applicatif (couche 7 OSI) qui expose les Services HTTP/HTTPS vers l'extérieur du cluster. Un **Ingress Controller** (NGINX, Traefik) joue le rôle de reverse proxy et de terminaison TLS, routant les requêtes vers les Services appropriés en fonction du nom d'hôte ou du chemin URL.

---

## Les défis du réseau dans Kubernetes

Le réseau Kubernetes doit résoudre plusieurs problèmes que l'on ne rencontre pas dans une architecture classique :

**Adressage dynamique à grande échelle** — Un cluster peut héberger des milliers de Pods, chacun avec sa propre adresse IP, créés et détruits en permanence. Le réseau doit attribuer et révoquer des adresses IP en continu, sans conflit et sans intervention manuelle.

**Communication transparente inter-nœuds** — Un Pod sur le nœud A doit pouvoir contacter un Pod sur le nœud B aussi simplement que s'ils étaient sur la même machine. Le réseau doit masquer la topologie physique et fournir une connectivité « plate » (*flat network*) entre tous les Pods.

**Découverte de services** — Les applications ne connaissent pas les adresses IP des Pods auxquels elles doivent parler. Le réseau doit fournir un mécanisme de résolution de noms stable (DNS) et de load balancing transparent (Services).

**Isolation et sécurité** — Dans un cluster multi-tenant, le réseau doit pouvoir restreindre les communications entre Pods, namespaces ou applications selon des politiques de sécurité (Network Policies). Par défaut, tout est ouvert — la sécurisation est opt-in.

**Performance** — Le réseau Kubernetes ajoute des couches d'abstraction (overlay, NAT, proxy) qui introduisent de la latence et une surcharge (*overhead*). Le choix du plugin CNI et du mode de kube-proxy impacte directement les performances réseau.

**Exposition externe** — Les applications doivent être accessibles depuis l'extérieur du cluster (Internet, réseau d'entreprise) via des mécanismes standardisés (NodePort, LoadBalancer, Ingress), avec terminaison TLS et routage applicatif.

---

## Le réseau vu depuis un Pod

Pour ancrer ces concepts dans la réalité, examinons ce que voit un Pod du point de vue réseau :

```bash
# Depuis un Pod de diagnostic dans le cluster
kubectl run net-debug --image=nicolaka/netshoot --rm -it -- bash

# Interface réseau du Pod
ip addr show eth0
# eth0@if12: <BROADCAST,MULTICAST,UP> mtu 1450 qdisc noqueue
#     inet 10.244.1.47/24 brd 10.244.1.255 scope global eth0

# Route par défaut
ip route
# default via 10.244.1.1 dev eth0
# 10.244.0.0/16 via 10.244.1.1 dev eth0
# 10.244.1.0/24 dev eth0 proto kernel scope link src 10.244.1.47

# Résolution DNS
cat /etc/resolv.conf
# nameserver 10.96.0.10          ← CoreDNS (ClusterIP)
# search default.svc.cluster.local svc.cluster.local cluster.local
# options ndots:5
```

Le Pod possède une **interface réseau propre** (`eth0`) avec une adresse IP dans le sous-réseau Pod du nœud (`10.244.1.0/24`). Sa route par défaut pointe vers la passerelle du sous-réseau nœud (`10.244.1.1`), qui est gérée par le plugin CNI. Son résolveur DNS pointe vers CoreDNS (`10.96.0.10`), qui est un Service de type ClusterIP dans le namespace `kube-system`. Les domaines de recherche DNS permettent la résolution abrégée des noms de Services.

Le paramètre `ndots:5` signifie que tout nom contenant moins de 5 points est considéré comme un nom relatif et sera complété par les domaines de recherche avant d'être résolu. Cette valeur — parfois considérée comme trop agressive car elle génère beaucoup de requêtes DNS — est le défaut de Kubernetes.

---

## Relation avec le réseau Debian sous-jacent

Le réseau Kubernetes ne remplace pas le réseau Debian — il s'appuie dessus. Les compétences acquises dans le Module 6 sont directement mobilisées :

**Configuration des interfaces** — Les nœuds Debian doivent avoir une connectivité réseau fonctionnelle entre eux. La configuration IP statique (systemd-networkd ou `/etc/network/interfaces`) est le socle sur lequel Kubernetes construit.

**Pare-feu nftables** — Les ports Kubernetes (6443, 10250, etc.) et les ports CNI (8472 pour VXLAN, 179 pour BGP, etc.) doivent être ouverts. Les règles nftables configurées dans le sous-chapitre 11.2.1 sont essentielles.

**Diagnostic réseau** — Les outils Linux classiques (`ip`, `ss`, `tcpdump`, `traceroute`, `nslookup`) restent les outils de première ligne pour diagnostiquer les problèmes réseau dans Kubernetes. Ils sont complétés par des outils spécifiques (`kubectl exec`, `kubectl port-forward`, Hubble pour Cilium).

**Bridges et VXLAN** — Le plugin CNI utilise des bridges Linux pour la connectivité locale des Pods et des tunnels VXLAN (ou d'autres technologies d'encapsulation) pour la connectivité inter-nœuds. La compréhension de ces technologies, abordée dans le Module 6, aide au diagnostic des problèmes de couche 2.

**Routage IP** — Le paramètre `net.ipv4.ip_forward = 1`, activé dans les prérequis (11.2.1), est fondamental : sans lui, le noyau Linux refuse de transmettre les paquets entre interfaces, ce qui bloque toute communication inter-Pods.

---

## Ce que vous allez apprendre

Cette section 11.4 est découpée en quatre sous-chapitres :

**11.4.1 — Modèle réseau Kubernetes** : les trois règles fondamentales du modèle réseau Kubernetes, la communication Pod-to-Pod sur un même nœud et entre nœuds, la communication Pod-to-Service, et la communication vers/depuis l'extérieur du cluster. Ce sous-chapitre pose le cadre théorique que tous les plugins CNI doivent respecter.

**11.4.2 — CNI : Flannel, Calico, Cilium** : présentation détaillée des trois plugins CNI les plus utilisés sur Debian. Architecture, mode de fonctionnement (overlay VXLAN, routage BGP, eBPF), support des Network Policies, performances et critères de choix. Ce sous-chapitre couvre également l'installation et la configuration de chaque CNI.

**11.4.3 — Ingress Controllers (NGINX Ingress, Traefik)** : exposition des applications HTTP/HTTPS vers l'extérieur du cluster via un point d'entrée unique. Création de ressources Ingress, routage par nom d'hôte et par chemin, terminaison TLS, intégration avec cert-manager pour les certificats automatiques. Introduction à la Gateway API, successeur de l'API Ingress.

**11.4.4 — DNS interne (CoreDNS)** : fonctionnement de CoreDNS, structure des enregistrements DNS, configuration du Corefile, personnalisation (forwarding conditionnel, réécriture de noms), diagnostic des problèmes de résolution DNS.

---

## Prérequis pour cette section

- **Réseau Linux** (Module 6) : TCP/IP, interfaces, routage, DNS, pare-feu nftables, VLANs, diagnostic réseau.
- **Services Kubernetes** (Section 11.3.2) : ClusterIP, NodePort, LoadBalancer, Endpoints, découverte DNS.
- **Architecture Kubernetes** (Section 11.1) : rôle de kube-proxy, composants des nœuds de travail.
- **Installation du cluster** (Section 11.2) : configuration CNI lors de l'installation (pod-network-cidr, choix du plugin).

---

*Dans le sous-chapitre suivant (11.4.1), nous examinerons le modèle réseau de Kubernetes — les règles fondamentales que tout plugin CNI doit respecter et les mécanismes qui permettent à des milliers de Pods de communiquer entre eux de manière transparente.*

⏭️ [Modèle réseau Kubernetes](/module-11-kubernetes-fondamentaux/04.1-modele-reseau.md)
