# Formation Complète Debian Desktop et Server

*Version finale optimisée - Cloud-Native Ready*

* * *

## **Module 1 : Fondamentaux de Debian**

*Durée : 8h | Niveau : Débutant*

### 1.1 Introduction à Debian

- 1.1.1 Histoire et philosophie de Debian
- 1.1.2 Les versions et cycles de release (Stable, Testing, Unstable)
- 1.1.3 Différences avec les autres distributions Linux
- 1.1.4 Architecture du système Debian
- **Lab** : Exploration de l'écosystème Debian

### 1.2 Installation de base

- 1.2.1 Préparation du support d'installation
- 1.2.2 Types d'installation (Netinst, DVD, USB)
- 1.2.3 Partitionnement du disque (GPT vs MBR)
- 1.2.4 Configuration réseau de base
- 1.2.5 Sélection des paquets de base
- **Lab** : Installation complète sur VM

### 1.3 Post-installation

- 1.3.1 Premier démarrage et configuration initiale
- 1.3.2 Gestion des utilisateurs et groupes
- 1.3.3 Configuration de sudo
- 1.3.4 Mise à jour du système
- **Lab** : Configuration post-installation

* * *

## **Module 2 : Debian Desktop**

*Durée : 12h | Niveau : Débutant-Intermédiaire*

### 2.1 Environnements de bureau

- 2.1.1 GNOME (environnement par défaut)
- 2.1.2 KDE Plasma
- 2.1.3 XFCE et LXDE
- 2.1.4 Installation et configuration des DE
- **Lab** : Comparaison des environnements

### 2.2 Gestion des applications desktop

- 2.2.1 Logithèque et centres d'applications
- 2.2.2 Installation de logiciels courants
- 2.2.3 Gestion des formats de fichiers
- 2.2.4 Configuration du multimédia
- **Lab** : Setup environnement utilisateur complet

### 2.3 Matériel et pilotes

- 2.3.1 Installation de pilotes propriétaires (NVIDIA, WiFi)
- 2.3.2 Gestion de l'alimentation et suspend/hibernate
- 2.3.3 Configuration multi-écrans
- 2.3.4 Bluetooth et périphériques
- **Lab** : Configuration matériel avancée

### 2.4 Personnalisation et optimisation

- 2.4.1 Thèmes et apparence
- 2.4.2 Raccourcis clavier
- 2.4.3 Optimisation des performances
- 2.4.4 Accessibilité
- **Lab** : Personnalisation complète

### 2.5 Bureautique et productivité

- 2.5.1 Suite LibreOffice
- 2.5.2 Navigateurs web et extensions
- 2.5.3 Clients de messagerie
- 2.5.4 Outils de développement (IDE, éditeurs)
- 2.5.5 Docker Desktop et VS Code
- **Lab** : Setup environnement développeur

* * *

## **Module 3 : Administration système de base**

*Durée : 16h | Niveau : Intermédiaire*

### 3.1 Système de fichiers

- 3.1.1 Structure des répertoires Linux/Debian
- 3.1.2 Permissions et propriétés (ACL avancées)
- 3.1.3 Montage et démontage
- 3.1.4 Liens symboliques et physiques
- **Lab** : Manipulation système de fichiers

### 3.2 Gestion des processus

- 3.2.1 Commandes ps, top, htop
- 3.2.2 Signaux et kill
- 3.2.3 Jobs et processus en arrière-plan
- 3.2.4 Surveillance système (systemctl, service)
- **Lab** : Monitoring et contrôle processus

### 3.3 Gestion des utilisateurs et groupes

- 3.3.1 Création et suppression d'utilisateurs
- 3.3.2 Modification des comptes
- 3.3.3 Gestion des mots de passe (PAM)
- 3.3.4 Sudo et privilèges avancés
- **Lab** : Administration utilisateurs complexe

### 3.4 Logs et monitoring

- 3.4.1 Système de logs (rsyslog, journald)
- 3.4.2 Analyse des logs (grep, awk, sed)
- 3.4.3 Outils de monitoring (nagios, zabbix)
- 3.4.4 Alertes et notifications
- **Lab** : Setup monitoring complet

* * *

## **Module 4 : Gestion des paquets**

*Durée : 10h | Niveau : Intermédiaire*

### 4.1 APT (Advanced Package Tool)

- 4.1.1 Configuration d'APT
- 4.1.2 Sources.list et dépôts
- 4.1.3 Commandes apt et apt-get
- 4.1.4 Gestion des clés GPG
- **Lab** : Configuration dépôts avancée

### 4.2 Dpkg et paquets .deb

- 4.2.1 Installation manuelle de paquets
- 4.2.2 Création de paquets personnalisés
- 4.2.3 Résolution des dépendances
- 4.2.4 Outils complémentaires (gdebi, dpkg-reconfigure)
- **Lab** : Création paquet personnalisé

### 4.3 Dépôts tiers et backports

- 4.3.1 Ajout de dépôts externes
- 4.3.2 Debian Backports
- 4.3.3 Sécurité et vérification
- 4.3.4 Pinning des paquets
- **Lab** : Gestion dépôts multiples

### 4.4 Flatpak et Snap

- 4.4.1 Installation et configuration
- 4.4.2 Gestion des applications sandboxées
- 4.4.3 Avantages et inconvénients
- **Lab** : Comparaison formats packaging

* * *

## **Module 5 : Réseau et sécurité**

*Durée : 14h | Niveau : Intermédiaire*

### 5.1 Configuration réseau avancée

- 5.1.1 Interfaces réseau et bonding/teaming
- 5.1.2 Configuration statique et DHCP
- 5.1.3 IPv6 et dual-stack
- 5.1.4 VLAN et réseaux virtuels
- 5.1.5 NetworkManager vs systemd-networkd
- 5.1.6 Diagnostic réseau
- **Lab** : Configuration réseau complexe

### 5.2 Pare-feu et sécurité

- 5.2.1 iptables et nftables
- 5.2.2 ufw (Uncomplicated Firewall)
- 5.2.3 Configuration de base et règles avancées
- 5.2.4 fail2ban et protection intrusion
- **Lab** : Mise en place sécurité réseau

### 5.3 SSH et accès distant

- 5.3.1 Installation et configuration d'OpenSSH
- 5.3.2 Authentification par clés
- 5.3.3 Tunneling et port forwarding
- 5.3.4 Sécurisation d'SSH (fail2ban, port knocking)
- **Lab** : Sécurisation accès distant

### 5.4 VPN et chiffrement

- 5.4.1 OpenVPN et WireGuard
- 5.4.2 Configuration client/serveur
- 5.4.3 Certificats et PKI
- 5.4.4 Chiffrement des données
- **Lab** : Déploiement VPN complet

* * *

## **Module 6 : Debian Server - Services de base**

*Durée : 18h | Niveau : Intermédiaire-Avancé*

### 6.1 Installation serveur

- 6.1.1 Installation minimale
- 6.1.2 Configuration réseau serveur
- 6.1.3 Sécurisation initiale (hardening)
- 6.1.4 Outils d'administration à distance
- **Lab** : Setup serveur production-ready

### 6.2 Serveur web (Apache/Nginx)

- 6.2.1 Installation et configuration
- 6.2.2 Virtual hosts et reverse proxy
- 6.2.3 Modules et extensions
- 6.2.4 SSL/TLS et certificats (Let's Encrypt)
- 6.2.5 Performance tuning
- **Lab** : Déploiement serveur web HA

### 6.3 Base de données

- 6.3.1 MySQL/MariaDB
- 6.3.2 PostgreSQL
- 6.3.3 Configuration et optimisation
- 6.3.4 Sauvegarde et restauration
- 6.3.5 Réplication et clustering
- **Lab** : Cluster base de données

### 6.4 Serveur de fichiers

- 6.4.1 Samba (partage Windows)
- 6.4.2 NFS (partage Linux)
- 6.4.3 FTP/SFTP sécurisé
- 6.4.4 Configuration et sécurisation
- **Lab** : Infrastructure partage fichiers

* * *

## **Module 7 : Services réseau avancés**

*Durée : 16h | Niveau : Avancé*

### 7.1 Serveur DNS

- 7.1.1 BIND9 configuration avancée
- 7.1.2 Zones et enregistrements
- 7.1.3 DNS dynamique et DNSSEC
- 7.1.4 Sécurité DNS
- **Lab** : Infrastructure DNS complète

### 7.2 Serveur DHCP

- 7.2.1 ISC DHCP Server
- 7.2.2 Configuration des plages et failover
- 7.2.3 Réservations statiques
- 7.2.4 Intégration DNS-DHCP
- **Lab** : DHCP haute disponibilité

### 7.3 Serveur mail

- 7.3.1 Postfix configuration complète
- 7.3.2 Dovecot (IMAP/POP3)
- 7.3.3 Filtrage anti-spam (SpamAssassin)
- 7.3.4 Webmail et clients
- 7.3.5 DKIM, SPF, DMARC
- **Lab** : Plateforme mail sécurisée

### 7.4 Serveur proxy et cache

- 7.4.1 Squid proxy avancé
- 7.4.2 Configuration et ACL
- 7.4.3 Cache web et optimisation
- 7.4.4 Authentification LDAP
- **Lab** : Proxy d'entreprise

* * *

## **Module 8 : Virtualisation et conteneurs**

*Durée : 20h | Niveau : Avancé*

### 8.1 Virtualisation système

- 8.1.1 KVM et QEMU
- 8.1.2 libvirt et virt-manager
- 8.1.3 VirtualBox
- 8.1.4 Gestion des machines virtuelles
- 8.1.5 Réseaux virtuels avancés
- **Lab** : Infrastructure virtualisée

### 8.2 Conteneurs Docker

- 8.2.1 Installation et configuration
- 8.2.2 Images et conteneurs avancés
- 8.2.3 Docker Compose et orchestration
- 8.2.4 Volumes et réseaux
- 8.2.5 Registry privé et distribution
- 8.2.6 Sécurité des conteneurs
- **Lab** : Plateforme containers

### 8.3 LXC/LXD

- 8.3.1 Conteneurs système
- 8.3.2 Configuration et gestion avancée
- 8.3.3 Snapshots et migration
- 8.3.4 Intégration réseau
- **Lab** : Infrastructure LXD

### 8.4 Podman et alternatives

- 8.4.1 Podman rootless
- 8.4.2 Buildah et Skopeo
- 8.4.3 Compatibilité Docker
- 8.4.4 Sécurité des conteneurs
- **Lab** : Migration Docker vers Podman

* * *

## **Module 9 : Kubernetes et orchestration**

*Durée : 24h | Niveau : Avancé*

### 9.1 Introduction à Kubernetes

- 9.1.1 Architecture et concepts fondamentaux
- 9.1.2 Pods, Services, Deployments
- 9.1.3 Namespaces et RBAC
- 9.1.4 Installation sur Debian (kubeadm)
- **Lab** : Premier cluster Kubernetes

### 9.2 Cluster Kubernetes production

- 9.2.1 Configuration multi-nœuds HA
- 9.2.2 Networking (CNI, Flannel, Calico)
- 9.2.3 Storage (PV, PVC, StorageClass)
- 9.2.4 Ingress Controllers
- **Lab** : Cluster production-ready

### 9.3 Distributions Kubernetes

- 9.3.1 K3s (lightweight Kubernetes)
- 9.3.2 MicroK8s et alternatives
- 9.3.3 Rancher sur Debian
- 9.3.4 Kind pour développement
- **Lab** : Comparaison distributions

### 9.4 Outils d'écosystème K8s

- 9.4.1 Helm (gestionnaire de paquets)
- 9.4.2 Kubectl avancé
- 9.4.3 Kustomize
- 9.4.4 Monitoring (Prometheus, Grafana)
- **Lab** : Écosystème K8s complet

### 9.5 GitOps et CI/CD

- 9.5.1 ArgoCD et Flux
- 9.5.2 Tekton Pipelines
- 9.5.3 Jenkins sur Kubernetes
- 9.5.4 Intégration GitLab CI
- **Lab** : Pipeline GitOps complet

* * *

## **Module 10 : Infrastructure as Code**

*Durée : 16h | Niveau : Avancé*

### 10.1 Terraform

- 10.1.1 Installation sur Debian
- 10.1.2 Providers et ressources
- 10.1.3 État et backend S3/Consul
- 10.1.4 Modules et bonnes pratiques
- **Lab** : Infrastructure complète avec Terraform

### 10.2 Ansible avancé

- 10.2.1 Ansible sur Debian
- 10.2.2 Playbooks Kubernetes et cloud
- 10.2.3 AWX/Tower
- 10.2.4 Collections et Galaxy
- **Lab** : Automatisation complète

### 10.3 Vagrant et Packer

- 10.3.1 Environnements de développement
- 10.3.2 Images personnalisées
- 10.3.3 Intégration avec cloud providers
- 10.3.4 Templates Debian optimisés
- **Lab** : Création images custom

* * *

## **Module 11 : Cloud et orchestration avancée**

*Durée : 20h | Niveau : Expert*

### 11.1 Cloud providers

- 11.1.1 AWS CLI et outils sur Debian
- 11.1.2 Google Cloud SDK
- 11.1.3 Azure CLI
- 11.1.4 Instances Debian dans le cloud
- **Lab** : Déploiement multi-cloud

### 11.2 Service Mesh

- 11.2.1 Istio installation et configuration
- 11.2.2 Linkerd sur Kubernetes
- 11.2.3 Consul Connect
- 11.2.4 Observabilité et sécurité
- **Lab** : Service mesh complet

### 11.3 Monitoring cloud-native

- 11.3.1 Prometheus et AlertManager
- 11.3.2 Grafana et dashboards
- 11.3.3 Jaeger (tracing distribué)
- 11.3.4 ELK Stack sur Debian
- **Lab** : Observabilité complète

### 11.4 Stockage distribué

- 11.4.1 Ceph sur Debian
- 11.4.2 GlusterFS
- 11.4.3 MinIO (S3 compatible)
- 11.4.4 Rook pour Kubernetes
- **Lab** : Stockage distribué

* * *

## **Module 12 : Sauvegarde et haute disponibilité**

*Durée : 14h | Niveau : Avancé*

### 12.1 Stratégies de sauvegarde cloud-native

- 12.1.1 Types de sauvegardes (traditionnelles et cloud)
- 12.1.2 Outils (rsync, tar, borgbackup, Velero)
- 12.1.3 Sauvegarde Kubernetes (ETCD, PV)
- 12.1.4 Automatisation avec cron et CronJobs K8s
- 12.1.5 Sauvegarde distante et cross-cloud
- 12.1.6 Tests de restauration et validation
- 12.1.7 Calcul RTO/RPO et stratégies 3-2-1
- **Lab** : Stratégie sauvegarde complète

### 12.2 RAID, stockage et persistance

- 12.2.1 Configuration RAID logiciel
- 12.2.2 LVM (Logical Volume Manager)
- 12.2.3 Stockage Kubernetes (CSI drivers)
- 12.2.4 Surveillance des disques
- 12.2.5 Récupération de données
- **Lab** : Stockage haute performance

### 12.3 Haute disponibilité moderne

- 12.3.1 Clustering avec Pacemaker
- 12.3.2 Load balancing (HAProxy, NGINX)
- 12.3.3 Kubernetes HA (control plane)
- 12.3.4 Réplication de services
- 12.3.5 Monitoring et failover automatique
- **Lab** : Infrastructure HA complète

* * *

## **Module 13 : Automatisation et scripting avancé**

*Durée : 12h | Niveau : Avancé*

### 13.1 Scripts Bash avancés

- 13.1.1 Automatisation des tâches système et K8s
- 13.1.2 Gestion des erreurs et logging
- 13.1.3 Interaction avec APIs (K8s, cloud)
- 13.1.4 Bonnes pratiques DevOps
- **Lab** : Scripts d'automatisation complexes

### 13.2 Cron et systemd timers cloud-native

- 13.2.1 Planification des tâches traditionnelles
- 13.2.2 CronJobs Kubernetes
- 13.2.3 Configuration avancée
- 13.2.4 Gestion des logs et alerting
- 13.2.5 Alternatives modernes (Tekton, Argo Workflows)
- **Lab** : Automatisation scheduling

### 13.3 Infrastructure as Code avancée

- 13.3.1 Ansible pour infrastructure complète
- 13.3.2 Terraform pour cloud et on-premise
- 13.3.3 GitOps avec ArgoCD/Flux
- 13.3.4 Déploiement automatisé multi-environnement
- **Lab** : Pipeline IaC complet

* * *

## **Module 14 : Sécurité avancée et cloud-native**

*Durée : 18h | Niveau : Expert*

### 14.1 Hardening système et conteneurs

- 14.1.1 Sécurisation du kernel Linux (grsecurity)
- 14.1.2 AppArmor et SELinux
- 14.1.3 Sécurité des conteneurs (rootless, capabilities)
- 14.1.4 Pod Security Standards
- 14.1.5 Audit et conformité (CIS benchmarks)
- **Lab** : Hardening complet

### 14.2 Sécurité Kubernetes

- 14.2.1 RBAC et ServiceAccounts avancés
- 14.2.2 Network Policies et micro-segmentation
- 14.2.3 Security Contexts et PSP
- 14.2.4 Admission Controllers (OPA Gatekeeper)
- 14.2.5 Falco (runtime security)
- **Lab** : Sécurisation cluster K8s

### 14.3 Surveillance et détection cloud-native

- 14.3.1 IDS/IPS (Suricata, Snort)
- 14.3.2 SIEM avec ELK Stack
- 14.3.3 Monitoring sécurité K8s
- 14.3.4 Détection d'intrusion conteneurs
- 14.3.5 Réponse aux incidents automatisée
- **Lab** : SOC cloud-native

### 14.4 Secrets et chiffrement

- 14.4.1 Vault (HashiCorp)
- 14.4.2 Kubernetes Secrets avancés
- 14.4.3 External Secrets Operator
- 14.4.4 Chiffrement at-rest et in-transit
- 14.4.5 Certificate management (cert-manager)
- **Lab** : Gestion secrets enterprise

### 14.5 DevSecOps

- 14.5.1 Scanning d'images (Trivy, Clair)
- 14.5.2 Policy as Code (OPA/Gatekeeper)
- 14.5.3 SAST/DAST dans CI/CD
- 14.5.4 Compliance automation
- 14.5.5 Supply chain security
- **Lab** : Pipeline DevSecOps

* * *

## **Module 15 : Troubleshooting et maintenance cloud-native**

*Durée : 16h | Niveau : Expert*

### 15.1 Diagnostic système hybride

- 15.1.1 Outils de diagnostic traditionnels
- 15.1.2 Debugging conteneurs et pods
- 15.1.3 Analyse des performances K8s
- 15.1.4 Résolution de problèmes réseau service mesh
- 15.1.5 Recovery et réparation
- **Lab** : Troubleshooting avancé

### 15.2 Observabilité moderne

- 15.2.1 Les trois pilliers (metrics, logs, traces)
- 15.2.2 Prometheus et métriques custom
- 15.2.3 Distributed tracing avec Jaeger
- 15.2.4 Log aggregation multi-cluster
- 15.2.5 SLO/SLI monitoring
- **Lab** : Observabilité end-to-end

### 15.3 Optimisation des performances

- 15.3.1 Tuning du kernel pour conteneurs
- 15.3.2 Optimisation I/O et réseau
- 15.3.3 Resource management K8s
- 15.3.4 HPA et VPA (autoscaling)
- 15.3.5 Monitoring proactif et alerting
- **Lab** : Optimisation performance

### 15.4 Migration et mise à niveau

- 15.4.1 Migration VM vers conteneurs
- 15.4.2 Upgrade Kubernetes clusters
- 15.4.3 Migration inter-cloud
- 15.4.4 Blue/Green et Canary deployments
- 15.4.5 Tests et validation automatisés
- **Lab** : Stratégie migration

### 15.5 Disaster Recovery cloud-native

- 15.5.1 Backup/Restore multi-cluster
- 15.5.2 Cross-region replication
- 15.5.3 Chaos Engineering (Chaos Monkey)
- 15.5.4 RTO/RPO planning
- 15.5.5 Runbooks automatisés
- **Lab** : Plan disaster recovery

* * *

## **Module 16 : Edge Computing et IoT**

*Durée : 12h | Niveau : Avancé*

### 16.1 Kubernetes à la périphérie

- 16.1.1 K3s pour edge devices
- 16.1.2 Configuration devices contraints
- 16.1.3 Networking edge-to-cloud
- **Lab** : Déploiement edge

### 16.2 Monitoring distribué

- 16.2.1 Monitoring offline/déconnecté
- 16.2.2 Synchronisation données
- 16.2.3 Alerting edge
- **Lab** : Monitoring edge

### 16.3 Déploiements IoT

- 16.3.1 Gestion devices à grande échelle
- 16.3.2 Updates OTA
- 16.3.3 Sécurité IoT
- **Lab** : Infrastructure IoT

* * *

## **Module 17 : FinOps et optimisation coûts**

*Durée : 8h | Niveau : Avancé*

### 17.1 Gestion des coûts cloud-native

- 17.1.1 Resource quotas et limits
- 17.1.2 Cost monitoring et alerting
- 17.1.3 Right-sizing automatisé
- **Lab** : Optimisation coûts

### 17.2 Multi-cloud cost optimization

- 17.2.1 Comparaison coûts providers
- 17.2.2 Reserved instances et spot
- 17.2.3 Automated cost optimization
- **Lab** : Stratégie multi-cloud

* * *

## **Module 18 : Projets pratiques cloud-native**

*Durée : 24h | Niveau : Tous niveaux*

### 18.1 Projet Desktop moderne

- 18.1.1 Configuration complète poste développeur
- 18.1.2 Intégration outils cloud-native
- 18.1.3 Environnement développement K8s local
- 18.1.4 Personnalisation avancée
- 18.1.5 Documentation utilisateur

### 18.2 Projet Infrastructure hybride

- 18.2.1 Déploiement infrastructure on-premise + cloud
- 18.2.2 Cluster Kubernetes multi-nœuds HA
- 18.2.3 Services intégrés (web, mail, DNS, DHCP)
- 18.2.4 Service mesh et observabilité complète
- 18.2.5 Sécurisation et monitoring
- 18.2.6 CI/CD pipeline complet
- 18.2.7 Procédures d'exploitation automatisées

### 18.3 Projet Platform Engineering

- 18.3.1 Plateforme interne de développement
- 18.3.2 Self-service portal développeurs
- 18.3.3 GitOps workflow complet
- 18.3.4 Multi-tenancy et isolation
- 18.3.5 Policy enforcement automatisé
- 18.3.6 Developer experience optimization

### 18.4 Projet Migration cloud-native

- 18.4.1 Modernisation application legacy
- 18.4.2 Containerisation et orchestration
- 18.4.3 Refactoring en microservices
- 18.4.4 Mise en place monitoring/alerting
- 18.4.5 Performance testing et optimization
- 18.4.6 Migration zero-downtime

* * *

## **Annexes**

### Commandes essentielles par module

- Référence des commandes par catégorie
- Options courantes et exemples
- Cheat sheets par technologie

### Fichiers de configuration

- Localisation des fichiers importants
- Syntaxe et exemples annotés
- Templates et bonnes pratiques

### Troubleshooting par composant

- Guide diagnostic système
- Problèmes courants Kubernetes
- Résolution réseau et stockage
- Procédures recovery

### Ressources et documentation

- Documentation officielle
- Communauté et forums
- Outils complémentaires
- Veille technologique

### Certification et évaluation

- Critères d'évaluation par module
- Exercices pratiques corrigés
- Projets de validation
- Préparation certifications (CKA, CKS, RHCSA)
- Portfolio projets

### Cas d'usage métier

- Exemples d'architectures par secteur
- ROI et justification business
- Migration planning templates
- Best practices entreprise

* * *

**Durée totale estimée : 280 heures**
**Prérequis : Bases Linux et réseau**
**Certifications préparées : CKA, CKS, RHCSA, Terraform Associate**
