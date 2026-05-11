🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 19.2 Architecture infrastructure hybride

## Parcours 2-3 — Du datacenter physique au cloud, en passant par Kubernetes : concevoir, construire et opérer une infrastructure de production complète

---

## Objectifs de la section

À l'issue de cette section, vous serez en mesure de :

- Concevoir l'architecture complète d'une infrastructure de production hybride combinant un datacenter on-premise et des ressources cloud.
- Construire un cluster Kubernetes haute disponibilité sur des nœuds Debian bare-metal, avec tous les composants nécessaires à la production.
- Déployer et intégrer les services fondamentaux d'infrastructure (DNS, DHCP, mail, web) dans l'écosystème hybride.
- Mettre en place un pipeline CI/CD de bout en bout, du commit du développeur au déploiement en production via GitOps.
- Documenter et automatiser les procédures d'exploitation via des runbooks testés et progressivement automatisés.

---

## Contexte et motivation

### De l'artisanal à l'industriel

La section 19.1 a équipé le développeur individuel : un poste Debian configuré pour le cloud-native, avec un cluster Kubernetes local, des outils de productivité et une intégration dans le workflow GitOps. Ce poste est le cockpit depuis lequel le développeur interagit avec l'infrastructure.

Mais cette infrastructure, justement, reste à construire.

Dans la plupart des organisations, l'infrastructure de production n'est pas un service cloud managé que l'on consomme via une API. C'est un ensemble de serveurs physiques dans un datacenter, de services réseau configurés manuellement, de bases de données installées il y a des années, de scripts de déploiement hérités et de procédures connues de quelques personnes seulement. Cette infrastructure fonctionne — mais elle est fragile, difficile à faire évoluer et coûteuse à opérer.

Cette section transforme cette infrastructure artisanale en une plateforme industrielle. Le mot « industrielle » n'est pas choisi par hasard : il implique la **reproductibilité** (l'infrastructure peut être reconstruite à partir de sa description), la **fiabilité** (les pannes sont anticipées et tolérées), l'**observabilité** (l'état de chaque composant est mesuré en permanence), et l'**automatisation** (les opérations répétitives sont déléguées aux machines).

### Pourquoi l'hybride est le cas réel

Le titre de cette section inclut le mot « hybride » parce que c'est la réalité de la très grande majorité des organisations en 2026. Le full cloud existe (startups nées dans le cloud, entreprises ayant achevé leur migration), le full on-premise existe (environnements classifiés, industries à forte inertie), mais le cas dominant est l'hybride : un datacenter existant avec du matériel, des compétences et des données, complété par des ressources cloud pour l'élasticité, la redondance géographique ou les services managés.

L'hybride n'est pas un compromis temporaire en attendant le « vrai » cloud. C'est une architecture à part entière, avec ses propres patterns de conception, ses contraintes spécifiques (connectivité, latence, cohérence des données, identité unifiée) et ses avantages (contrôle, coût prévisible, souveraineté, proximité des données).

L'architecture de référence de cette section est conçue pour fonctionner dans les trois configurations : full on-premise (si le cloud n'est pas utilisé, les composants cloud sont simplement absents), hybride on-premise + cloud (le cas de référence), et full cloud (les nœuds Kubernetes tournent sur des instances cloud au lieu de bare-metal, les services d'infrastructure sont remplacés par leurs équivalents managés).

---

## Vue d'ensemble de l'architecture

### Les couches de l'infrastructure

L'infrastructure hybride s'organise en cinq couches, de la plus physique à la plus applicative :

```
┌─────────────────────────────────────────────────────────────────────┐
│                COUCHE 5 : EXPLOITATION                              │
│  Runbooks · Astreintes · Monitoring · Alertes · Postmortems         │
│  "Comment opère-t-on l'infrastructure au quotidien ?"               │
├─────────────────────────────────────────────────────────────────────┤
│                COUCHE 4 : LIVRAISON CONTINUE                        │
│  GitLab · Harbor · Pipeline CI/CD · ArgoCD · GitOps                 │
│  "Comment le code arrive-t-il en production ?"                      │
├─────────────────────────────────────────────────────────────────────┤
│                COUCHE 3 : SERVICES D'INFRASTRUCTURE                 │
│  DNS (BIND9) · DHCP (Kea) · Mail (Postfix/Dovecot)                  │
│  Reverse Proxy (Nginx) · Monitoring (Prometheus/Grafana)            │
│  "Quels services fondamentaux font fonctionner le réseau ?"         │
├─────────────────────────────────────────────────────────────────────┤
│                COUCHE 2 : ORCHESTRATION                             │
│  Kubernetes HA (kubeadm sur Debian bare-metal)                      │
│  etcd cluster · CNI (Cilium/Calico) · Stockage (Ceph/NFS)           │
│  Ingress (NGINX + MetalLB) · Service Mesh (optionnel)               │
│  "Comment les applications sont-elles orchestrées ?"                │
├─────────────────────────────────────────────────────────────────────┤
│                COUCHE 1 : FONDATION                                 │
│  Debian Stable (bare-metal + cloud) · Réseau (VPN, VLAN)            │
│  Identité (FreeIPA/LDAP) · Sécurité (nftables, AppArmor)            │
│  Connectivité hybride (IPsec/WireGuard/Direct Connect)              │
│  IaC (Ansible + Terraform)                                          │
│  "Sur quoi tout repose-t-il ?"                                      │
└─────────────────────────────────────────────────────────────────────┘
```

Chaque couche dépend des couches inférieures et fournit des services aux couches supérieures. Cette dépendance ordonne le déploiement (on construit de bas en haut) et la résolution des incidents (on diagnostique de bas en haut : le réseau avant les pods, les pods avant les applications).

### Topologie physique et logique

L'architecture de référence s'appuie sur la topologie suivante :

```
                          INTERNET
                              │
                     ┌────────▼────────┐
                     │ Firewall / Edge │
                     │ Router          │
                     └────────┬────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          │            ┌──────▼──────┐            │
          │            │ VPN Gateway │            │
          │            │ (WireGuard/ │            │
          │            │  IPsec)     │            │
          │            └──────┬──────┘            │
          │                   │                   │
   ┌──────▼──────┐    ┌──────▼──────┐    ┌────────▼─────┐
   │ VLAN Infra  │    │ VLAN K8s    │    │ VLAN Clients │
   │ 10.0.0.0/16 │    │ 10.2.0.0/16 │    │ 10.3.0.0/16  │
   │             │    │             │    │              │
   │ DNS-1       │    │ CP-1  CP-2  │    │ Postes de    │
   │ DNS-2       │    │ CP-3        │    │ travail      │
   │ Mail        │    │ WK-1  WK-2  │    │ (Debian)     │
   │ DHCP        │    │ WK-3  ...   │    │              │
   │ FreeIPA     │    │             │    │              │
   │ Proxy       │    │ MetalLB VIP │    │              │
   │ Backup      │    │ NFS/Ceph    │    │              │
   └─────────────┘    └─────────────┘    └──────────────┘
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                     ┌────────▼────────┐
                     │ Connectivité    │
                     │ hybride         │
                     │ (VPN/Direct     │
                     │  Connect)       │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │ Cloud Provider  │
                     │ (AWS/GCP/Azure) │
                     │                 │
                     │ VPC/VNet        │
                     │ EKS/GKE (opt.)  │
                     │ S3/GCS (backup) │
                     │ Registry miroir │
                     └─────────────────┘
```

**Le VLAN Infrastructure** héberge les services de niveau 0 (DNS, DHCP, mail, identité, proxy, backup) sur des serveurs Debian bare-metal. Ces services sont les fondations dont tout le reste dépend : sans DNS, pas de résolution de noms ; sans DHCP, pas d'adresses IP automatiques ; sans identité, pas d'authentification.

**Le VLAN Kubernetes** héberge le cluster de production : trois nœuds control plane (CP), trois nœuds workers ou plus (WK), les VIP MetalLB pour les Services LoadBalancer, et le stockage partagé (NFS ou Ceph). Ce VLAN est le cœur de l'orchestration des applications.

**Le VLAN Clients** héberge les postes de travail des développeurs et des utilisateurs (configurés en section 19.1). Les postes accèdent aux services via les VIP du cluster Kubernetes et les services d'infrastructure.

**La connectivité hybride** relie le datacenter on-premise au cloud provider via un tunnel VPN (IPsec ou WireGuard) ou une liaison dédiée (Direct Connect, ExpressRoute, Cloud Interconnect). Cette connexion permet aux workloads cloud d'accéder aux services on-premise (et inversement), aux backups d'être répliqués vers le stockage cloud, et au monitoring de couvrir les deux environnements.

---

## Ce que cette section construit

### Le parcours de construction

Cette section suit un ordre de construction logique, de la fondation vers les couches supérieures. Chaque sous-section produit un livrable concret et testable.

**19.2.1 — Conception d'une infrastructure on-premise + cloud.** Poser les fondations : plan d'adressage réseau, connectivité hybride (VPN, DNS inter-sites), identité unifiée (FreeIPA fédéré avec les IAM cloud), sécurité (Zero Trust, Vault), stratégie de placement des workloads et Infrastructure as Code (Ansible + Terraform). C'est la phase d'architecture et de planification.

**19.2.2 — Cluster Kubernetes multi-nœuds HA sur Debian.** Construire le cœur de l'orchestration : préparation des nœuds Debian (noyau, containerd, paramètres réseau), load balancer pour le control plane (HAProxy + Keepalived), déploiement avec kubeadm (etcd en cluster, certificats, chiffrement des secrets), plugin réseau (Cilium ou Calico), stockage persistant (NFS et Rook-Ceph), composants d'infrastructure (MetalLB, Ingress Controller, monitoring de base), sécurité (RBAC, Pod Security Standards, Network Policies), et opérations courantes (backup etcd, montée de version, rotation des certificats).

**19.2.3 — Services intégrés (web, mail, DNS, DHCP).** Déployer les services fondamentaux : DNS autoritaire et récursif (BIND9 + Unbound) avec forwarding conditionnel entre on-premise, cloud et Kubernetes ; DHCP moderne (ISC Kea) avec DNS dynamique ; serveur mail complet (Postfix + Dovecot + Rspamd) intégré à l'annuaire LDAP ; reverse proxy d'entrée (Nginx) faisant le pont entre le réseau interne et les applications Kubernetes. Chaque service est monitoré par Prometheus et provisionné par Ansible.

**19.2.4 — Pipeline CI/CD de bout en bout.** Mettre en place la chaîne de livraison : GitLab auto-hébergé dans Kubernetes, Harbor comme registry d'entreprise avec scanning et réplication, runners CI sur Kubernetes avec un builder daemonless (BuildKit en mode rootless est aujourd'hui la référence ; Kaniko a été archivé par Google en juin 2025 mais survit via les forks `chainguard-forks/kaniko` et `osscontainertools/kaniko`) et runners bare-metal (Docker/BuildKit), pipeline `.gitlab-ci.yml` complet (lint → build → test → scan → package → publish → deploy), GitOps avec ArgoCD (ApplicationSets multi-environnement, promotion dev → staging → production, stratégie canary avec Argo Rollouts), sécurité du pipeline (signature d'images Cosign, admission controller Kyverno, gestion des secrets), et observabilité du pipeline (métriques DORA, notifications).

**19.2.5 — Procédures d'exploitation et runbooks.** Opérer l'infrastructure au quotidien : structure et rédaction des runbooks (routine, incident, disaster recovery), runbooks détaillés pour les opérations courantes (mises à jour Debian, backup etcd, rotation des certificats) et la réponse aux incidents (nœud NotReady, pod CrashLoop, disque critique, VPN down, restauration etcd), gestion des astreintes (organisation L1/L2, processus de réponse, postmortems blameless), automatisation progressive des runbooks (du script à l'opérateur Kubernetes), et maintenance de la documentation opérationnelle.

### Ce qui relie les sous-sections entre elles

Les cinq sous-sections ne sont pas indépendantes. Elles forment un tout cohérent où chaque composant interagit avec les autres :

```
19.2.1 Fondation                    19.2.5 Exploitation
(réseau, identité, IaC)             (runbooks, astreintes)
    │                                       ▲
    │ construit le socle sur lequel         │ opère
    ▼                                       │
19.2.2 Cluster K8s HA ◄─────────────────────┤
    │                                       │
    │ héberge et orchestre                  │
    ▼                                       │
19.2.3 Services intégrés ◄──────────────────┤
(DNS, DHCP, mail, web)                      │
    │                                       │
    │ supportent le fonctionnement de       │
    ▼                                       │
19.2.4 Pipeline CI/CD ◄─────────────────────┘
(GitLab, Harbor, ArgoCD)
    │
    │ déploie les applications
    │ sur l'infrastructure
    ▼
Applications de production
```

Le DNS (19.2.3) est nécessaire au fonctionnement du cluster Kubernetes (19.2.2) et du pipeline CI/CD (19.2.4). Le cluster Kubernetes (19.2.2) héberge le pipeline CI/CD (19.2.4) et certains services d'infrastructure (19.2.3). Le pipeline CI/CD (19.2.4) déploie les applications sur le cluster (19.2.2). Les runbooks (19.2.5) couvrent les incidents de tous les composants. Et la fondation (19.2.1) — réseau, identité, IaC — est le socle commun.

---

## Prérequis et compétences mobilisées

Cette section est la synthèse pratique du Parcours 2 de la formation. Elle mobilise directement les compétences des modules suivants :

| Module | Compétences utilisées | Section de référence |
|---|---|---|
| Module 1-3 | Installation Debian, administration système, systemd | 19.2.2 (nœuds K8s) |
| Module 4 | Gestion des paquets, dépôts tiers | 19.2.2, 19.2.3 |
| Module 5 | Scripting Bash, automatisation | 19.2.5 (runbooks) |
| Module 6 | Réseau, pare-feu, SSH, VPN | 19.2.1 (fondation réseau) |
| Module 7 | Serveurs web, bases de données, fichiers | 19.2.3 (services) |
| Module 8 | DNS, DHCP, mail, sauvegarde, HA | 19.2.3, 19.2.2 |
| Module 9 | Virtualisation KVM | 19.2.1 (si VMs utilisées) |
| Module 10 | Conteneurs, Docker, Podman | 19.2.2, 19.2.4 |
| Module 11 | Kubernetes fondamentaux, kubeadm | 19.2.2 |
| Module 12 | Kubernetes production, sécurité, HA | 19.2.2 |
| Module 13 | Ansible, Terraform | 19.2.1, toutes les sections |
| Module 14 | CI/CD, GitOps | 19.2.4 |
| Module 15 | Prometheus, Grafana, observabilité | 19.2.3, 19.2.4 |

Un lecteur qui aborde cette section doit avoir complété le Parcours 1 (Modules 1 à 8) et au minimum les Modules 10 à 13 du Parcours 2. Les Modules 14 et 15 sont nécessaires pour les sous-sections 19.2.4 et 19.2.5.

---

## Conventions et hypothèses

### Environnement de référence

L'architecture de référence suppose les éléments suivants, qui peuvent être adaptés au contexte de chaque organisation :

**Datacenter on-premise** avec 6 à 10 serveurs bare-metal sous Debian Stable (Trixie est la version Stable de référence depuis août 2025 ; Bookworm reste utilisable en oldstable jusqu'en juin 2028 LTS), un réseau 1 Gbps minimum (10 Gbps recommandé pour le backbone), une connectivité Internet et un lien vers un cloud provider.

**Cloud provider** : AWS est utilisé dans les exemples (VPC, EKS, S3, Route53), mais les concepts et la majorité des configurations sont transposables à GCP ou Azure. Les commandes spécifiques au provider sont identifiées et accompagnées de commentaires pour l'adaptation.

**Domaine interne** : `internal.entreprise.fr` pour les ressources on-premise, `cloud.entreprise.fr` pour les ressources cloud. Ces noms sont utilisés de manière cohérente dans toutes les sous-sections.

**Plan d'adressage** : `10.0.0.0/8` pour le on-premise (subdivisé en VLANs), `172.16.0.0/12` pour le cloud AWS. Le plan complet est détaillé en section 19.2.1.

### Outils et versions

Les outils utilisés dans cette section sont ceux installés et configurés sur le poste développeur (section 19.1) : `kubectl`, `helm`, `ansible`, `terraform`, `argocd`, les CLI cloud, et les outils de productivité shell. Les versions sont celles disponibles dans Debian Stable ou ses backports au moment de la rédaction. Les numéros de version spécifiques (Kubernetes — versions supportées en standard : v1.34, v1.35, v1.36 ; Cilium ; etc.) sont fournis à titre indicatif ; les concepts et l'architecture restent valables avec les versions ultérieures, et le projet Kubernetes maintient une politique de compatibilité ascendante de trois versions mineures (≈ 14 mois).

---

## Plan de la section

- **19.2.1 — Conception d'une infrastructure on-premise + cloud** : fondation réseau, identité, sécurité, stratégie de placement, Infrastructure as Code.

- **19.2.2 — Cluster Kubernetes multi-nœuds HA sur Debian** : préparation des nœuds, load balancer, kubeadm, CNI, stockage, composants d'infrastructure, sécurité, opérations.

- **19.2.3 — Services intégrés (web, mail, DNS, DHCP)** : DNS hybride, DHCP avec DDNS, mail complet, reverse proxy, monitoring unifié, gestion Ansible.

- **19.2.4 — Pipeline CI/CD de bout en bout** : GitLab, Harbor, runners, pipeline complet, GitOps ArgoCD, sécurité, observabilité.

- **19.2.5 — Procédures d'exploitation et runbooks** : structure des runbooks, procédures de routine et d'incident, gestion des astreintes, automatisation progressive, maintenance.

---

*Prérequis : Parcours 1 complet (Modules 1 à 8), Modules 10 à 13 du Parcours 2. Section 19.1 recommandée (poste développeur).*

⏭️ [Conception d'une infrastructure on-premise + cloud](/module-19-architectures-reference/02.1-conception-on-premise-cloud.md)
