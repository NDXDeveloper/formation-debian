🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe E.1 — Critères d'évaluation par module et par parcours

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section définit les **compétences attendues** à l'issue de chaque module, puis les consolide en profils de sortie pour chacun des trois parcours. Elle sert de référentiel pour l'auto-évaluation de l'apprenant, le suivi pédagogique par le formateur et la communication des acquis vers les employeurs.

---

## Conventions

Chaque compétence est associée à l'un des trois niveaux de maîtrise définis dans l'introduction de l'annexe E.

- **F** — Fondamental : exécuter une procédure documentée en comprenant chaque étape.
- **O** — Opérationnel : réaliser la tâche de manière autonome et l'adapter au contexte.
- **E** — Expert : concevoir, optimiser, diagnostiquer les cas complexes et former d'autres personnes.

Le niveau indiqué pour chaque compétence est le **niveau cible** dans le contexte du parcours correspondant. Un apprenant du parcours 1 vise le niveau O sur les modules 1 à 8 ; un apprenant du parcours 3 vise le niveau E sur les modules 14 à 19 et conserve le niveau O sur les modules précédents.

---

## Parcours 1 — Administrateur Système Debian

### Module 1 : Fondamentaux de Debian

| Compétence | Niveau |
|-----------|:------:|
| Expliquer les principes du projet Debian (contrat social, DFSG, branches) | O |
| Réaliser une installation Debian complète en choisissant le schéma de partitionnement adapté au besoin (poste de travail, serveur) | O |
| Distinguer GPT et MBR et choisir le format approprié selon le matériel | O |
| Configurer le réseau, les locales, le fuseau horaire et le clavier en post-installation | O |
| Créer un utilisateur, le configurer dans le groupe sudo et vérifier le fonctionnement | O |
| Effectuer la première mise à jour du système après installation | O |

### Module 2 : Debian Desktop

| Compétence | Niveau |
|-----------|:------:|
| Installer et configurer un environnement de bureau (GNOME, KDE, XFCE) | O |
| Installer des applications courantes via APT, Flatpak ou la logithèque | O |
| Installer les firmwares et pilotes nécessaires (NVIDIA, WiFi) à partir des dépôts non-free | O |
| Configurer le multimédia (codecs, PipeWire) et le multi-écrans | F |
| Expliquer les différences entre Wayland et Xorg | F |
| Personnaliser l'environnement (thèmes, raccourcis, optimisations de performances) | F |

### Module 3 : Administration système de base

| Compétence | Niveau |
|-----------|:------:|
| Naviguer dans l'arborescence FHS et expliquer le rôle de chaque répertoire principal | O |
| Gérer les permissions Unix (chmod, chown) et les ACL étendues (setfacl) | O |
| Configurer le montage des systèmes de fichiers via `/etc/fstab` | O |
| Créer, modifier et supprimer des utilisateurs et des groupes | O |
| Configurer les politiques de mot de passe et les règles sudo | O |
| Superviser les processus (ps, top, htop) et gérer les signaux (kill) | O |
| Gérer les services avec systemctl : démarrer, arrêter, activer, diagnostiquer | O |
| Créer une unité systemd personnalisée (service et timer) | O |
| Exploiter les logs avec journalctl (filtrage par unité, priorité, période) | O |
| Configurer journald (persistance, rotation, taille maximale) | F |
| Intégrer un poste dans un annuaire LDAP via SSSD | F |

### Module 4 : Gestion des paquets

| Compétence | Niveau |
|-----------|:------:|
| Utiliser apt pour installer, mettre à jour, supprimer et rechercher des paquets | O |
| Configurer les sources APT (sources.list, dépôts tiers, clés GPG) | O |
| Utiliser dpkg pour l'inspection et l'installation de paquets locaux | O |
| Résoudre les problèmes de dépendances et de paquets cassés | O |
| Configurer le pinning APT pour gérer les priorités entre dépôts | F |
| Créer un paquet .deb simple | F |
| Installer et gérer des applications Flatpak | F |
| Comparer les avantages et inconvénients de .deb, Flatpak et Snap | F |

### Module 5 : Scripting et automatisation

| Compétence | Niveau |
|-----------|:------:|
| Écrire des scripts Bash utilisant variables, boucles, conditions et fonctions | O |
| Appliquer les bonnes pratiques de scripting (set -euo pipefail, shellcheck, trap) | O |
| Utiliser grep, sed, awk et jq pour le traitement de texte et de données JSON | O |
| Planifier des tâches avec cron et les timers systemd | O |
| Interagir avec des APIs REST via curl et jq | O |
| Écrire des scripts Python simples pour l'administration système | F |
| Gérer des environnements virtuels Python et installer des dépendances pip | F |
| Choisir entre Bash et Python en fonction du cas d'usage | F |

### Module 6 : Réseau et sécurité

| Compétence | Niveau |
|-----------|:------:|
| Configurer les interfaces réseau (statique, DHCP, bonding, VLAN) | O |
| Diagnostiquer les problèmes réseau avec ip, ss, ping, traceroute, mtr et tcpdump | O |
| Configurer un pare-feu avec nftables ou ufw | O |
| Installer et configurer fail2ban pour protéger les services exposés | O |
| Installer et configurer OpenSSH (authentification par clés, durcissement) | O |
| Configurer un tunnel SSH (local et remote forwarding) | O |
| Mettre en place un VPN WireGuard (client et serveur) | F |
| Chiffrer un volume avec LUKS/dm-crypt | F |
| Expliquer les bases de la PKI et de la gestion des certificats | F |
| Choisir entre NetworkManager, systemd-networkd et ifupdown selon le contexte | F |

### Module 7 : Debian Server — Services de base

| Compétence | Niveau |
|-----------|:------:|
| Réaliser une installation serveur minimale et appliquer le hardening de base | O |
| Installer et configurer Nginx comme serveur web et reverse proxy | O |
| Installer et configurer Apache avec virtual hosts | O |
| Mettre en place HTTPS avec Let's Encrypt et certbot | O |
| Installer et administrer PostgreSQL (création de bases, utilisateurs, sauvegardes) | O |
| Installer et administrer MariaDB (configuration, sécurisation, sauvegardes) | O |
| Configurer un partage de fichiers Samba ou NFS | F |
| Configurer Caddy comme alternative à Nginx/Apache | F |
| Mettre en place la réplication d'une base de données | F |

### Module 8 : Services réseau avancés, sauvegarde et HA

| Compétence | Niveau |
|-----------|:------:|
| Configurer un serveur DNS BIND9 (zones, enregistrements, transferts) | O |
| Configurer un serveur DHCP Kea avec réservations statiques | O |
| Concevoir et mettre en œuvre une stratégie de sauvegarde 3-2-1 | O |
| Utiliser borgbackup ou restic pour des sauvegardes chiffrées et dédupliquées | O |
| Automatiser les sauvegardes avec des timers systemd | O |
| Effectuer un test de restauration complet | O |
| Définir et calculer les RTO/RPO adaptés au contexte | O |
| Configurer un RAID logiciel avec mdadm | F |
| Gérer des volumes LVM (création, extension, snapshots) | F |
| Configurer un serveur mail Postfix/Dovecot avec DKIM, SPF et DMARC | F |
| Mettre en place un cluster HA avec Pacemaker/Corosync | F |
| Configurer HAProxy comme répartiteur de charge | F |

---

## Parcours 2 — Ingénieur Infrastructure & Conteneurs

### Module 9 : Virtualisation

| Compétence | Niveau |
|-----------|:------:|
| Expliquer les concepts de virtualisation (type 1, type 2, paravirtualisation) | O |
| Installer et configurer KVM/QEMU sur Debian avec libvirt | O |
| Créer, gérer et migrer des machines virtuelles avec virsh et virt-manager | O |
| Configurer les réseaux virtuels et les bridges | O |
| Optimiser les performances des VM (virtio, hugepages) | F |
| Utiliser Vagrant pour des environnements de développement reproductibles | O |
| Créer des images personnalisées avec Packer | F |

### Module 10 : Conteneurs

| Compétence | Niveau |
|-----------|:------:|
| Expliquer les mécanismes fondamentaux (namespaces, cgroups v2, overlay FS) | O |
| Écrire des Dockerfiles optimisés (multi-stage, utilisateur non-root, couches minimales) | O |
| Gérer le cycle de vie des conteneurs Docker (run, stop, logs, exec, rm) | O |
| Orchestrer des services locaux avec Docker Compose | O |
| Gérer les volumes et les réseaux Docker | O |
| Utiliser un registry privé pour distribuer des images | O |
| Utiliser Podman en mode rootless comme alternative à Docker | O |
| Construire des images avec Buildah et inspecter avec Skopeo | F |
| Intégrer des conteneurs Podman dans systemd via Quadlet | F |
| Gérer des conteneurs système avec Incus (LXC) | F |
| Scanner les images avec Trivy ou Grype et interpréter les résultats | O |
| Appliquer les principes de sécurité des conteneurs (least privilege, immutabilité) | O |

### Module 11 : Kubernetes — Fondamentaux

| Compétence | Niveau |
|-----------|:------:|
| Expliquer l'architecture d'un cluster Kubernetes (control plane, workers, etcd) | O |
| Installer un cluster avec kubeadm sur des nœuds Debian | O |
| Installer et utiliser K3s pour un cluster léger | O |
| Déployer des applications avec des Deployments, Services et ConfigMaps | O |
| Gérer les namespaces et organiser les ressources | O |
| Exposer des services (ClusterIP, NodePort, LoadBalancer) | O |
| Configurer un Ingress Controller (Traefik, NGINX Gateway Fabric, kgateway, HAProxy Ingress, Cilium/Envoy Gateway — note : ingress-nginx K8s est en retraite officielle depuis le 31 mars 2026) ou la **Gateway API** (HTTPRoute) recommandée pour les nouveaux déploiements | O |
| Gérer le stockage avec PV, PVC et StorageClasses | O |
| Diagnostiquer les problèmes de pods (logs, describe, events, exec) | O |
| Expliquer le modèle réseau Kubernetes et le rôle du CNI | F |
| Comparer Flannel, Calico et Cilium | F |

### Module 12 : Kubernetes — Production

| Compétence | Niveau |
|-----------|:------:|
| Concevoir un cluster multi-nœuds haute disponibilité sur Debian | O |
| Configurer RBAC (Roles, ClusterRoles, Bindings) | O |
| Appliquer les Pod Security Standards aux namespaces | O |
| Configurer les Network Policies pour la segmentation réseau | O |
| Définir les ResourceQuotas et LimitRanges | O |
| Utiliser Helm pour déployer et gérer des applications | O |
| Utiliser Kustomize pour la gestion multi-environnement | O |
| Configurer le Horizontal Pod Autoscaler (HPA) | O |
| Sauvegarder et restaurer etcd | O |
| Réaliser un upgrade de cluster Kubernetes sur Debian | O |
| Mettre en place des stratégies de déploiement Blue/Green, Canary ou progressives (avec Argo Rollouts ou Flagger) | F |
| Développer ou comprendre un Operator Kubernetes | F |

### Module 13 : Infrastructure as Code

| Compétence | Niveau |
|-----------|:------:|
| Écrire des playbooks Ansible structurés (tâches, handlers, templates, variables) | O |
| Organiser le code Ansible en rôles et collections | O |
| Utiliser ansible-vault pour chiffrer les données sensibles | O |
| Provisionner des nœuds Debian avec Ansible (paquets, configuration, services) | O |
| Écrire du code Terraform / OpenTofu pour provisionner de l'infrastructure (variables, ressources, outputs) | O |
| Gérer l'état Terraform / OpenTofu (backends, locking, import) | O |
| Structurer le code Terraform / OpenTofu en modules réutilisables | O |
| Articuler Terraform / OpenTofu (provisionnement) et Ansible (configuration) dans un workflow combiné | O |
| Mettre en place un workflow collaboratif Terraform / OpenTofu (workspaces, CI/CD) | F |
| Utiliser AWX/Ansible Automation Platform | F |

---

## Parcours 3 — Expert Cloud-Native & Kubernetes

### Module 14 : CI/CD et GitOps

| Compétence | Niveau |
|-----------|:------:|
| Concevoir un pipeline CI/CD complet (build, test, scan, deploy) | E |
| Configurer un GitLab Runner ou GitHub Actions runner sur Debian | O |
| Déployer et configurer ArgoCD pour le déploiement GitOps | E |
| Configurer Flux comme alternative GitOps | O |
| Gérer les secrets dans un workflow GitOps (Sealed Secrets, SOPS, External Secrets Operator) | E |
| Mettre en place un déploiement automatisé multi-environnement | E |
| Comparer les approches CI/CD serveur Debian vs Kubernetes | O |
| Configurer Tekton Pipelines sur Kubernetes | F |

### Module 15 : Observabilité et monitoring

| Compétence | Niveau |
|-----------|:------:|
| Expliquer les trois piliers de l'observabilité (métriques, logs, traces) | E |
| Définir des SLO, SLI et error budgets pour un service | E |
| Déployer et configurer Prometheus (scraping, rules, alerting) | E |
| Écrire des requêtes PromQL pour le monitoring et l'alerting | E |
| Créer des dashboards Grafana exploitables et maintenables | O |
| Configurer AlertManager avec routage et silencing | O |
| Déployer une stack de logs (Loki + Grafana Alloy — ex-Promtail EOL le 2 mars 2026 — ou ELK) | O |
| Intégrer le monitoring avec journald sur les nœuds Debian | O |
| Mettre en place du tracing distribué (instrumentation avec OpenTelemetry, backend Jaeger ou Tempo) | F |
| Concevoir une stratégie d'observabilité globale pour une plateforme | E |

### Module 16 : Sécurité avancée et cloud-native

| Compétence | Niveau |
|-----------|:------:|
| Appliquer le durcissement noyau Debian (sysctl, lockdown, AppArmor) | E |
| Réaliser un audit CIS Benchmark sur un système Debian | O |
| Configurer le RBAC avancé Kubernetes (least privilege, ServiceAccounts dédiés) | E |
| Mettre en place OPA Gatekeeper ou Kyverno pour le Policy as Code | E |
| Déployer et configurer HashiCorp Vault (ou OpenBao, son fork open source MPL 2.0) — moteurs de secrets, auth Kubernetes | O |
| Gérer les certificats avec cert-manager | O |
| Intégrer la sécurité dans les pipelines CI/CD (SAST, DAST, scanning d'images) | E |
| Mettre en place la supply chain security (signatures d'images avec Cosign/Sigstore, attestations SLSA, SBOM CycloneDX/SPDX) | O |
| Configurer Falco pour la détection d'intrusion runtime | F |

### Module 17 : Cloud, Service Mesh et stockage distribué

| Compétence | Niveau |
|-----------|:------:|
| Utiliser les CLI des cloud providers (AWS, GCP, Azure) depuis Debian | O |
| Déployer et administrer des images Debian dans le cloud | O |
| Comparer les offres Kubernetes managées (EKS, GKE, AKS) | E |
| Expliquer les cas d'usage d'un service mesh (mTLS, traffic management) | E |
| Déployer et configurer Istio ou Linkerd | O |
| Déployer un stockage distribué (Ceph, ou alternative S3 open source : SeaweedFS, Garage, RustFS — MinIO Community archivé en avril 2026) | F |
| Configurer Rook pour le stockage Kubernetes | F |

### Module 18 : Edge Computing, FinOps et tendances

| Compétence | Niveau |
|-----------|:------:|
| Déployer K3s sur des edge devices Debian | O |
| Concevoir une architecture edge-to-cloud | F |
| Mettre en place le suivi des coûts avec Kubecost ou OpenCost | O |
| Appliquer les stratégies d'optimisation FinOps (right-sizing, spot instances) | O |
| Expliquer les tendances émergentes (Platform Engineering, WebAssembly, eBPF) | F |
| Évaluer la pertinence de ces tendances pour un contexte donné | E |

### Module 19 : Architectures de référence et cas d'usage

| Compétence | Niveau |
|-----------|:------:|
| Configurer un poste développeur cloud-native complet sur Debian | O |
| Concevoir une infrastructure hybride on-premise + cloud | E |
| Mettre en place un pipeline CI/CD de bout en bout | E |
| Concevoir une plateforme interne de développement (Platform Engineering) | E |
| Planifier et exécuter une migration d'application legacy vers les conteneurs | E |
| Concevoir et tester un plan de Disaster Recovery | E |
| Rédiger des runbooks opérationnels et des procédures d'exploitation | O |
| Mettre en place du Chaos Engineering pour valider la résilience | F |

---

## Profils de compétences par parcours

### Profil de sortie — Parcours 1 : Administrateur Système Debian

L'apprenant qui termine le parcours 1 est capable d'installer, configurer et maintenir des serveurs Debian en production. Il maîtrise l'administration système quotidienne (utilisateurs, services, paquets, logs, réseau) et sait déployer les services fondamentaux (web, base de données, DNS, DHCP, mail). Il applique les bonnes pratiques de sécurité (pare-feu, SSH, fail2ban) et de sauvegarde (stratégie 3-2-1, tests de restauration). Il automatise les tâches répétitives avec Bash et sait diagnostiquer les problèmes courants de manière méthodique.

**Compétences transversales acquises** — Rigueur opérationnelle (valider avant d'appliquer, documenter les modifications, tester les restaurations). Méthodologie de diagnostic (logs, changements récents, ressources, connectivité). Autonomie sur la documentation officielle Debian.

**Compétences non couvertes** — Conteneurisation, orchestration Kubernetes, Infrastructure as Code, architectures distribuées. Ces compétences sont abordées dans les parcours 2 et 3.

### Profil de sortie — Parcours 2 : Ingénieur Infrastructure & Conteneurs

L'apprenant qui termine le parcours 2 possède les compétences du parcours 1 et maîtrise en plus la virtualisation, la conteneurisation et les fondamentaux de Kubernetes. Il sait construire des images Docker optimisées, déployer des applications sur Kubernetes, gérer le cycle de vie d'un cluster et automatiser l'infrastructure avec Ansible et Terraform. Il comprend les principes de la haute disponibilité, du stockage persistant et du réseau dans un environnement conteneurisé.

**Compétences transversales acquises** — Pensée déclarative (manifestes Kubernetes, playbooks Ansible, code Terraform). Approche Infrastructure as Code (reproductibilité, idempotence, versionning). Capacité à articuler plusieurs technologies dans une architecture cohérente.

**Compétences non couvertes** — GitOps avancé, observabilité complète, sécurité cloud-native approfondie, service mesh, architectures multi-cloud. Ces compétences sont abordées dans le parcours 3.

**Certifications accessibles** — KCNA (Kubernetes and Cloud Native Associate, échauffement), CKA (Certified Kubernetes Administrator), Terraform Associate (version 004 depuis janvier 2026), CKAD si orientation développement.

### Profil de sortie — Parcours 3 : Expert Cloud-Native & Kubernetes

L'apprenant qui termine le parcours 3 possède les compétences des parcours 1 et 2 et maîtrise en plus l'ensemble de la chaîne DevOps/SRE. Il conçoit des pipelines CI/CD et des workflows GitOps, met en place une observabilité complète (métriques, logs, traces), applique les pratiques de sécurité cloud-native (RBAC avancé, Policy as Code, supply chain security) et sait concevoir des architectures résilientes multi-environnement. Il est capable de prendre des décisions d'architecture argumentées, d'évaluer les compromis entre solutions et de piloter des projets de migration ou de modernisation.

**Compétences transversales acquises** — Vision architecturale (comprendre les interactions entre les composants et anticiper les impacts des décisions). Approche SRE (SLO, error budgets, toil reduction, incident management). Capacité à évaluer et adopter de nouvelles technologies de manière critique.

**Certifications accessibles** — KCNA + KCSA (échauffement), CKA, CKS (Certified Kubernetes Security Specialist), Terraform Associate (version 004). Le statut **Kubestronaut** (CNCF) est accessible avec en plus la CKAD.

---

## Grille d'auto-évaluation

L'apprenant peut utiliser la grille suivante pour suivre sa progression. Pour chaque module, évaluer honnêtement son niveau actuel (F, O ou E) et le comparer au niveau cible de son parcours.

| Module | Thème | Cible P1 | Cible P2 | Cible P3 | Mon niveau |
|--------|-------|:--------:|:--------:|:--------:|:----------:|
| 1 | Fondamentaux Debian | O | O | O | |
| 2 | Debian Desktop | O | F | F | |
| 3 | Administration système | O | O | O | |
| 4 | Gestion des paquets | O | O | O | |
| 5 | Scripting et automatisation | O | O | O | |
| 6 | Réseau et sécurité | O | O | O | |
| 7 | Debian Server | O | O | O | |
| 8 | Services avancés, sauvegarde et HA | F-O | O | O | |
| 9 | Virtualisation | — | O | O | |
| 10 | Conteneurs | — | O | O | |
| 11 | Kubernetes fondamentaux | — | O | O | |
| 12 | Kubernetes production | — | O | E | |
| 13 | Infrastructure as Code | — | O | O | |
| 14 | CI/CD et GitOps | — | — | E | |
| 15 | Observabilité et monitoring | — | — | E | |
| 16 | Sécurité avancée | — | — | E | |
| 17 | Cloud, Service Mesh, stockage | — | — | O-E | |
| 18 | Edge, FinOps, tendances | — | — | O | |
| 19 | Architectures de référence | — | — | E | |

Le tiret (—) indique que le module n'est pas dans le périmètre du parcours. L'apprenant peut néanmoins l'aborder en exploration avec un niveau cible F.

---

## Indicateurs de réussite par niveau

Pour s'auto-évaluer de manière fiable, l'apprenant peut se poser les questions suivantes.

**Niveau Fondamental atteint ?** — « Avec la documentation ouverte devant moi, suis-je capable de réaliser cette tâche en moins de 30 minutes sans aide extérieure ? » Si oui, le niveau F est acquis.

**Niveau Opérationnel atteint ?** — « Sans documentation (ou avec uniquement les man pages), suis-je capable de réaliser cette tâche, de l'adapter à un contexte légèrement différent et de diagnostiquer un problème courant ? » Si oui, le niveau O est acquis.

**Niveau Expert atteint ?** — « Suis-je capable d'expliquer cette technologie à un collègue, de justifier les choix d'architecture associés, d'optimiser la configuration pour un cas de charge spécifique et de résoudre un incident complexe impliquant cette technologie ? » Si oui, le niveau E est acquis.

La progression de F à O se fait principalement par la **pratique répétée**. La progression de O à E se fait par l'**expérience en production**, la **confrontation à des incidents réels** et l'**approfondissement théorique**.

⏭️ [Préparation certifications (CKA, CKS, Terraform Associate)](/annexes/E.2-preparation-certifications.md)
