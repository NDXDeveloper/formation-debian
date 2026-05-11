# 📘 Formation Debian : du Desktop au Cloud-Native

*De l'installation de votre premier poste Debian à l'orchestration Kubernetes en production*

[![Licence CC BY 4.0](https://img.shields.io/badge/Licence-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)  
[![Debian 13 Trixie](https://img.shields.io/badge/Debian-13%20Trixie-A81D33?logo=debian&logoColor=white)](https://www.debian.org/releases/trixie/)  
[![Kubernetes 1.34+](https://img.shields.io/badge/Kubernetes-1.34%2B-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)  
[![19 modules](https://img.shields.io/badge/Modules-19-blue.svg)](SOMMAIRE.md)  
[![~280 heures](https://img.shields.io/badge/Dur%C3%A9e-~280h-green.svg)](#-structure-de-la-formation)

---

## 📋 Description

Cette formation complète et moderne vous accompagne dans la maîtrise de Debian, de l'installation desktop aux infrastructures cloud-native les plus avancées. Structurée en **3 parcours progressifs** et **19 modules**, elle couvre environ **280 heures** de contenu théorique approfondi, conçu pour répondre aux besoins actuels du DevOps, du SRE et de l'infrastructure moderne.

> 💡 **Approche théorique** : Cette formation privilégie la compréhension en profondeur des concepts, architectures et bonnes pratiques. Les commandes et fichiers de configuration sont présentés à titre illustratif — l'objectif est de savoir *pourquoi* avant de savoir *comment*.

<img src="https://www.debian.org/Pics/debian-logo-1024x576.png" alt="Logo Debian" width="50%">

### 🎯 Objectifs pédagogiques

- **Administrer Debian** de A à Z : installation, configuration, services, sécurisation
- **Automatiser** avec le scripting Bash/Python, Ansible et Terraform/OpenTofu
- **Conteneuriser** avec Docker, Podman et les bonnes pratiques OCI
- **Orchestrer** avec Kubernetes, de l'installation à la production HA
- **Déployer en continu** avec CI/CD et GitOps (ArgoCD, Flux)
- **Observer et sécuriser** les environnements hybrides et cloud-native
- **Construire une plateforme** interne (Backstage, golden paths, self-service)
- **Optimiser** les performances et les coûts (FinOps)

---

## 🚀 Structure de la formation

### 3 Parcours · 19 Modules

| Parcours | Modules | Profil cible | Durée |
|----------|---------|--------------|-------|
| 🟢 **Parcours 1** — Administrateur Système Debian | 1 à 8 | Adminsys, techniciens, étudiants | ~100h |
| 🔵 **Parcours 2** — Ingénieur Infrastructure & Conteneurs | 9 à 13 | Adminsys confirmés, DevOps juniors | ~90h |
| 🟣 **Parcours 3** — Expert Cloud-Native & Kubernetes | 14 à 19 | DevOps/SRE confirmés, architectes | ~90h |

Chaque parcours est conçu pour être suivi **indépendamment** (avec les prérequis du parcours précédent) ou **dans la continuité**.

### 📚 Détail des modules

#### 🟢 Parcours 1 — Administrateur Système Debian

| # | Module | Niveau |
|---|--------|--------|
| 1 | [Fondamentaux de Debian](/module-01-fondamentaux-debian.md) | Débutant |
| 2 | [Debian Desktop](/module-02-debian-desktop.md) | Débutant-Intermédiaire |
| 3 | [Administration système de base](/module-03-administration-systeme.md) | Intermédiaire |
| 4 | [Gestion des paquets](/module-04-gestion-paquets.md) | Intermédiaire |
| 5 | [Scripting et automatisation](/module-05-scripting-automatisation.md) | Intermédiaire |
| 6 | [Réseau et sécurité](/module-06-reseau-securite.md) | Intermédiaire |
| 7 | [Debian Server — Services de base](/module-07-debian-server.md) | Intermédiaire-Avancé |
| 8 | [Services réseau avancés, sauvegarde et HA](/module-08-services-avances-sauvegarde-ha.md) | Avancé |

#### 🔵 Parcours 2 — Ingénieur Infrastructure & Conteneurs

| # | Module | Niveau |
|---|--------|--------|
| 9 | [Virtualisation](/module-09-virtualisation.md) | Avancé |
| 10 | [Conteneurs](/module-10-conteneurs.md) | Avancé |
| 11 | [Kubernetes — Fondamentaux](/module-11-kubernetes-fondamentaux.md) | Avancé |
| 12 | [Kubernetes — Production](/module-12-kubernetes-production.md) | Expert |
| 13 | [Infrastructure as Code](/module-13-infrastructure-as-code.md) | Avancé-Expert |

#### 🟣 Parcours 3 — Expert Cloud-Native & Kubernetes

| # | Module | Niveau |
|---|--------|--------|
| 14 | [CI/CD et GitOps](/module-14-cicd-gitops.md) | Expert |
| 15 | [Observabilité et monitoring](/module-15-observabilite-monitoring.md) | Expert |
| 16 | [Sécurité avancée et cloud-native](/module-16-securite-avancee.md) | Expert |
| 17 | [Cloud, Service Mesh et stockage distribué](/module-17-cloud-service-mesh-stockage.md) | Expert |
| 18 | [Edge Computing, FinOps et tendances](/module-18-edge-finops-tendances.md) | Avancé-Expert |
| 19 | [Architectures de référence et cas d'usage](/module-19-architectures-reference.md) | Tous niveaux |

📖 Consultez le **[SOMMAIRE.md](SOMMAIRE.md)** pour la table des matières complète avec tous les sous-modules.

---

## 🔧 Technologies couvertes

**Système & Administration**
- Debian 13 « Trixie » (Desktop et Server)
- systemd en profondeur, gestion des paquets (APT, dpkg, Flatpak)
- Scripting Bash avancé et Python pour l'administration
- Réseau et sécurité (nftables, SSH, WireGuard, LUKS)

**Virtualisation & Conteneurs**
- KVM/QEMU, VirtualBox, Vagrant, Packer
- Docker, Podman, Buildah, Skopeo, Quadlet
- LXC/LXD (Incus)

**Orchestration & Kubernetes**
- Kubernetes (kubeadm, K3s, Kind)
- Helm, Kustomize, Operators et CRDs
- Service Mesh (Istio, Linkerd)

**Infrastructure as Code & GitOps**
- Ansible (playbooks, rôles, AWX)
- Terraform et **OpenTofu** (providers, modules, multi-cloud)
- GitOps (ArgoCD, Flux, Sealed Secrets, External Secrets Operator)

**CI/CD**
- GitLab CI, GitHub Actions (runners sur Debian et sur K8s)
- Jenkins, Tekton Pipelines

**Observabilité**
- Prometheus, Grafana, AlertManager
- ELK Stack, Loki, Fluent Bit
- Jaeger, OpenTelemetry

**Cloud & Stockage distribué**
- Multi-cloud (AWS, GCP, Azure) — CLI et images Debian
- Ceph, MinIO, Rook

**Platform Engineering**
- Backstage (catalogue de services, golden paths, TechDocs)
- Crossplane (Composition Functions, infrastructure self-service)
- Internal Developer Platforms et Developer Experience (DevEx)

**Sécurité**
- Hardening Debian (AppArmor, CIS benchmarks, Secure Boot)
- Sécurité Kubernetes (RBAC, PSS, **Kyverno**, OPA Gatekeeper, Falco)
- Secrets management (Vault, OpenBao, External Secrets Operator, cert-manager)
- DevSecOps (Trivy, Cosign, SBOM, SAST/DAST)

---

## 🎓 Public cible

### Profils adaptés

- **Administrateurs système** souhaitant évoluer vers le cloud-native
- **Développeurs** voulant comprendre l'infrastructure moderne
- **DevOps / SRE Engineers** cherchant à approfondir Kubernetes et l'IaC
- **Étudiants** en informatique (niveau bac+2 minimum)
- **Professionnels IT** en reconversion
- **Architectes** souhaitant maîtriser les concepts d'infrastructure moderne

### Prérequis

- Bases en informatique et familiarité avec un poste de travail
- Notions de réseau (TCP/IP, DNS, HTTP)
- Familiarité avec Git (recommandé)

> Pour les débutants complets en Linux, le **Parcours 1** reprend tout depuis zéro.

---

## 🛠️ Méthode pédagogique

### Format théorique approfondi

Cette formation adopte une approche conceptuelle. Chaque module comprend :

- **Concepts fondamentaux** — Architecture et principes de base
- **Théorie avancée** — Fonctionnement interne des technologies
- **Exemples concrets** — Commandes, fichiers de configuration et sorties terminal annotés
- **Bonnes pratiques** — Recommandations professionnelles issues de l'industrie
- **Comparaisons** — Analyse des alternatives et critères de choix
- **Troubleshooting** — Méthodologies de diagnostic et résolution

### Ancrage Debian

Même dans les modules avancés (Kubernetes, cloud, CI/CD), la formation conserve un **ancrage Debian explicite** : tuning du noyau Debian pour K8s, provisioning de nœuds via APT et paquets .deb, images Debian slim pour conteneurs, intégration journald, CIS benchmarks Debian, etc.

---

## 📊 Validation des connaissances

### Évaluation par parcours

- Quiz de compréhension par module
- Études de cas et analyses architecturales
- Synthèses conceptuelles

### Certifications préparées

| Certification | Parcours concerné |
|---------------|-------------------|
| **CKA** (Certified Kubernetes Administrator) | Parcours 2 |
| **CKS** (Certified Kubernetes Security Specialist) | Parcours 3 |
| **Terraform Associate** | Parcours 2 |

---

## 🚀 Comment utiliser cette formation

### Récupérer le contenu

```bash
git clone https://github.com/NDXDeveloper/formation-debian.git  
cd formation-debian  
```

### Choisir son parcours

1. Consultez le **[SOMMAIRE.md](SOMMAIRE.md)** pour identifier votre niveau
2. Choisissez votre parcours d'entrée :
   - 🟢 **Débutant** → Commencez au Module 1
   - 🔵 **Intermédiaire** (admin Linux confirmé) → Commencez au Module 9
   - 🟣 **Avancé** (expérience K8s) → Commencez au Module 14
3. Suivez les modules dans l'ordre au sein de votre parcours
4. Validez vos acquis avec les évaluations de chaque module

### Naviguer dans la formation

Chaque fichier contient des liens de navigation :
- ⬅️ **Précédent** / **Suivant** ➡️ pour parcourir linéairement
- 🔝 **Retour** vers la section ou le module parent
- 📖 Lien vers le **SOMMAIRE.md** depuis n'importe où

### Artefacts pratiques (dossiers `scripts/`)

Six modules sont accompagnés d'un sous-dossier `scripts/` contenant les
**configurations et playbooks complets** présentés dans le cours, extraits
sous forme de fichiers prêts à l'emploi, validés syntaxiquement et organisés  
par thème :  

| Module | Contenu | Fichiers |
|--------|---------|---------:|
| [Module 03 — Administration système](module-03-administration-systeme/scripts/) | systemd units, scripts d'admin Bash | 76 |
| [Module 05 — Scripting et automatisation](module-05-scripting-automatisation/scripts/) | Bash et Python pour l'admin | 30 |
| [Module 13 — Infrastructure as Code](module-13-infrastructure-as-code/scripts/) | Playbooks Ansible, modules Terraform | 54 |
| [Module 14 — CI/CD et GitOps](module-14-cicd-gitops/scripts/) | Pipelines GitLab/GitHub, ArgoCD/Flux | 49 |
| [Module 15 — Observabilité](module-15-observabilite-monitoring/scripts/) | Prometheus, Loki, Grafana, OTel | 32 |
| [Module 19 — Architectures de référence](module-19-architectures-reference/scripts/) | 5 architectures intégrées de bout en bout | 41 |

Chaque dossier contient son propre `README.md` détaillant les conventions,  
l'index des fichiers et leurs interdépendances.  

---

## 🔄 Mises à jour

Cette formation évolue avec l'écosystème technologique :

- **Debian** — Basée sur Debian 13 « Trixie » (publiée le 9 août 2025, noyau 6.12 LTS) ; Bookworm (12) en oldstable, EOL juin 2028
- **Kubernetes** — Versions 1.34/1.35/1.36 supportées en 2026, kubeadm v1beta4 (breaking change : `extraArgs` au format liste d'objets)
- **Écosystème cloud-native** — Crossplane v2.x (Composition Functions), External Secrets Operator v2.x (v1 GA en sept. 2024, v2.x en 2025-2026), Sealed Secrets v0.36, Cosign v3, BuildKit v0.29, Kyverno 1.18+ (`failureAction` au niveau de la règle, disponible depuis 1.13)
- **Outils** — Intégration des nouveaux standards (OpenTelemetry, Cilium, eBPF…)
- **Sécurité** — Mise à jour continue des bonnes pratiques (règle 3-2-1-1-0 pour les backups, supply chain SLSA, SBOM systématique)

---

## 📞 Support & Ressources

### Documentation intégrée

- Chaque module inclut une documentation conceptuelle complète
- Les [Annexes](/annexes/README.md) fournissent des cheat sheets, fichiers de configuration, guides de troubleshooting et ressources complémentaires

### Ressources externes

- [Documentation officielle Debian](https://www.debian.org/doc/)
- [Documentation Kubernetes](https://kubernetes.io/docs/)
- [Documentation Terraform](https://developer.hashicorp.com/terraform/docs)
- [Documentation Ansible](https://docs.ansible.com/)

---

## 👨‍💻 Auteur

**Nicolas DEOUX**

- 📧 **Email** : NDXDev@gmail.com
- 💼 **LinkedIn** : [nicolas-deoux-ab295980](https://www.linkedin.com/in/nicolas-deoux-ab295980/)
- 🐙 **GitHub** : [NDXDeveloper/formation-debian](https://github.com/NDXDeveloper/formation-debian)

---

## 📄 Licence

Ce projet est sous licence **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

Vous êtes libre de :
- **Partager** — copier et redistribuer le matériel
- **Adapter** — remixer, transformer et créer à partir du matériel
- **Usage commercial** autorisé

**Condition** : Vous devez créditer l'œuvre et indiquer les modifications apportées.

Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🌟 Remerciements

Cette formation s'appuie sur l'excellence de la communauté Debian et de l'écosystème open source. Merci à tous les contributeurs des projets qui rendent possible l'infrastructure moderne — de Debian à Kubernetes, en passant par Prometheus, Terraform et tant d'autres.
