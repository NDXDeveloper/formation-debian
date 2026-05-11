🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe D.1 — Documentation officielle

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section référence les **documentations officielles** de chaque technologie abordée dans la formation. Pour chaque ressource, une description concise indique ce qu'on y trouve et dans quelle situation la consulter. Les ressources sont organisées par domaine, en suivant la progression des trois parcours.

Les documentations officielles sont la source de vérité : elles sont maintenues par les développeurs du projet, couvrent toutes les fonctionnalités et reflètent la version courante. Elles doivent toujours être consultées en priorité, avant les articles de blog ou les tutoriels tiers.

---

## 1. Debian et système Linux

### Debian — Documentation du projet

**Manuel d'installation Debian**
`https://www.debian.org/releases/stable/installmanual`
Guide complet du processus d'installation, du téléchargement de l'image au premier démarrage. Couvre les différentes architectures matérielles, les modes d'installation (graphique, texte, preseed) et le partitionnement. C'est la référence pour les modules 1 et 7.

**Manuel de l'administrateur Debian (Debian Handbook)**
`https://www.debian.org/doc/manuals/debian-handbook/`
Ouvrage de référence couvrant l'ensemble de l'administration Debian : gestion des paquets, configuration système, services réseau, sécurité. Disponible intégralement en français. Écrit par Raphaël Hertzog et Roland Mas, c'est la ressource la plus complète pour les parcours 1 et 2. Il est également disponible sous forme de paquet Debian (`apt install debian-handbook`).

**Wiki Debian**
`https://wiki.debian.org/`
Base de connaissances collaborative couvrant des sujets variés : guides matériels, configuration de services spécifiques, notes de migration entre versions. La qualité est variable selon les articles, mais les pages maintenues activement sont d'excellente facture. Le wiki francophone est accessible à `https://wiki.debian.org/fr/`.

**Référence Debian (Debian Reference)**
`https://www.debian.org/doc/manuals/debian-reference/`
Guide technique couvrant la gestion du système Debian au quotidien : ligne de commande, systèmes de fichiers, réseau, programmation shell. Plus concis que le Handbook, il cible un public ayant déjà des bases Linux. Disponible en français.

**Suivi de sécurité Debian**
`https://www.debian.org/security/`
Annonces de sécurité (DSA — Debian Security Advisories) pour tous les paquets de la branche stable. Indispensable pour le suivi des vulnérabilités et la gestion des mises à jour de sécurité. Le flux RSS permet une intégration dans les outils de veille.

**Debian Security Tracker**
`https://security-tracker.debian.org/`
Suivi détaillé de chaque CVE avec son statut par version de Debian (fixed, unfixed, no-dsa). Permet de vérifier si une vulnérabilité spécifique affecte le système et si un correctif est disponible.

**Notes de version Debian**
`https://www.debian.org/releases/stable/releasenotes`
Informations essentielles sur les changements entre versions majeures, les problèmes connus et les procédures de mise à niveau. À lire impérativement avant toute migration de version.

### Pages de manuel (man pages)

Les pages de manuel installées sur le système constituent la documentation la plus directement accessible. La commande `man <commande>` affiche la documentation complète d'une commande, d'un fichier de configuration ou d'un appel système.

```bash
man apt                                  # Documentation de la commande apt  
man 5 sshd_config                        # Section 5 = fichiers de configuration  
man 8 systemctl                          # Section 8 = commandes d'administration  
man -k <mot-clé>                         # Recherche par mot-clé  
apropos <mot-clé>                        # Équivalent de man -k  
```

Les sections du manuel sont : 1 (commandes utilisateur), 2 (appels système), 3 (fonctions de bibliothèque), 4 (fichiers spéciaux), 5 (formats de fichiers et conventions), 7 (divers), 8 (commandes d'administration).

### systemd

**Documentation systemd**
`https://systemd.io/`
Documentation complète du système d'initialisation, incluant les spécifications de tous les types d'unités, les directives des fichiers de configuration et les interfaces D-Bus. La page des man pages en ligne (`https://www.freedesktop.org/software/systemd/man/`) est le point d'entrée le plus pratique pour chercher une directive spécifique.

### Noyau Linux

**Documentation du noyau**
`https://www.kernel.org/doc/html/latest/`
Documentation officielle du noyau Linux, incluant les paramètres sysctl, les sous-systèmes réseau, les systèmes de fichiers et les pilotes. Référence avancée pour le tuning noyau abordé dans les modules 12 et 16.

---

## 2. Réseau et sécurité

### nftables

**Wiki nftables**
`https://wiki.nftables.org/`
Documentation complète du framework de filtrage réseau, incluant la syntaxe des règles, les exemples de configuration et le guide de migration depuis iptables. Référence pour le module 6.

### OpenSSH

**Manuel OpenSSH**
`https://www.openssh.com/manual.html`
Documentation officielle du client et du serveur SSH, incluant toutes les options de configuration de `sshd_config` et `ssh_config`. Complétée par les man pages locales (`man sshd_config`).

> **Évolutions OpenSSH 2025-2026** — **OpenSSH 10.0** (avril 2025) supprime totalement le support DSA (héritage SSHv2 limité à 160 bits + SHA1) ; les clés DSA encore utilisées dans les scripts ou serveurs ne fonctionnent plus, migration obligatoire vers **Ed25519** (recommandé) ou RSA 3072+. La version 10.0 introduit également le **post-quantum cryptography** par défaut via `mlkem768x25519-sha256` (hybride ML-KEM NIST + X25519). **OpenSSH 10.1** (octobre 2025) est la version stable courante. Les SSHFP en SHA1 sont en cours de dépréciation (`ssh-keygen -r` ne génère plus que du SHA256).

### WireGuard

**Documentation WireGuard**
`https://www.wireguard.com/`
Présentation du protocole, guides d'installation et référence de configuration. La page « Quick Start » est le point d'entrée recommandé. WireGuard est intégré au noyau Linux depuis 5.6 (2020) ; aucun module externe à installer sur Debian Bookworm/Trixie.

**Mesh VPN basés sur WireGuard** — Pour les déploiements multi-sites ou nomades sans avoir à gérer manuellement les paires de clés et les peers, plusieurs solutions de coordination apparues récemment encapsulent WireGuard avec un control-plane :

- **Tailscale** (`https://tailscale.com/`) — solution commerciale avec free tier (3 utilisateurs, 100 devices), DERP relays automatiques, MagicDNS, ACL Tailscale-style. Coordination centralisée via SaaS (control-plane fermé, data plane WireGuard ouvert).
- **Headscale** (`https://github.com/juanfont/headscale`) — implémentation open source (BSD-3) du control-plane Tailscale, à auto-héberger pour garder le contrôle complet.
- **NetBird** (`https://netbird.io/`) — alternative entièrement open source (BSD-3), control-plane et clients libres, peut être auto-hébergée. Fonctionnalités similaires à Tailscale (mesh, NAT traversal, ACL, SSO).

### Let's Encrypt / ACME

**Documentation Let's Encrypt**
`https://letsencrypt.org/docs/`
Guides d'utilisation, limites de taux, bonnes pratiques pour la gestion des certificats. La documentation de Certbot est disponible à `https://eff-certbot.readthedocs.io/`.

---

## 3. Services serveur

### Apache HTTP Server

**Documentation Apache**
`https://httpd.apache.org/docs/current/`
Référence complète de toutes les directives de configuration, des modules et des guides thématiques (virtual hosts, SSL/TLS, reverse proxy, authentification).

### Nginx

**Documentation Nginx**
`https://nginx.org/en/docs/`
Référence des directives, guide de l'administrateur et documentation des modules. La section « Beginner's Guide » est un bon point de départ, et la référence des directives (`https://nginx.org/en/docs/dirindex.html`) est le réflexe quotidien.

### Caddy

**Documentation Caddy**
`https://caddyserver.com/docs/`
Guide de la syntaxe Caddyfile, référence des directives et documentation de l'API JSON. La section « Caddyfile Concepts » explique la logique de configuration. Versions stables courantes en 2026 : **2.11.x** (2.10 a introduit l'**Encrypted ClientHello (ECH)** automatisé et la **cryptographie post-quantique** `x25519mlkem768` activée par défaut, ainsi que les certificats wildcard par défaut). Caddy reste très en avance sur Apache et Nginx pour la simplicité de configuration TLS moderne.

### PostgreSQL

**Documentation PostgreSQL**
`https://www.postgresql.org/docs/current/`
Documentation exhaustive couvrant l'installation, la configuration, le SQL, l'administration, la réplication et l'optimisation. La section « Server Configuration » est la référence pour `postgresql.conf` et `pg_hba.conf`. Chaque version majeure dispose de sa propre documentation.

### MariaDB

**Knowledge Base MariaDB**
`https://mariadb.com/kb/`
Base de connaissances officielle incluant la documentation du serveur, les guides de migration depuis MySQL et la référence SQL. La section « MariaDB Server Documentation » couvre la configuration et l'administration.

### BIND9

**Documentation BIND9 (ISC)**
`https://bind9.readthedocs.io/`
Manuel de référence du serveur DNS le plus déployé. Couvre la configuration des zones, DNSSEC, les vues et la haute disponibilité.

### ISC Kea

**Documentation Kea**
`https://kea.readthedocs.io/`
Manuel du serveur DHCP nouvelle génération, incluant la configuration DHCPv4, DHCPv6 et l'agent de contrôle REST.

### Postfix

**Documentation Postfix**
`https://www.postfix.org/documentation.html`
Documentation officielle du MTA, incluant la référence de tous les paramètres de `main.cf`, l'architecture interne et les guides de déploiement. La page « Postfix Configuration Parameters » est la référence quotidienne.

### Dovecot

**Documentation Dovecot**
`https://doc.dovecot.org/`
Documentation du serveur IMAP/POP3, couvrant l'authentification, le stockage des boîtes mail, les plugins et la configuration TLS.

---

## 4. Sauvegarde et haute disponibilité

### borgbackup

**Documentation Borg**
`https://borgbackup.readthedocs.io/`
Manuel d'utilisation complet, incluant les modes de chiffrement, la déduplication, la gestion des dépôts distants et les bonnes pratiques de rétention.

### restic

**Documentation restic**
`https://restic.readthedocs.io/`
Guide d'utilisation couvrant les backends supportés (local, S3, SFTP, etc.), le chiffrement et les stratégies de rétention.

### Kopia

**Documentation Kopia**
`https://kopia.io/docs/`
Outil moderne de sauvegarde déduplicée et chiffrée (Apache 2.0), alternative à restic et borgbackup. Architecture similaire (stockage objet ou local, chiffrement bout-en-bout, dédup à granularité variable), mais avec une **interface web** intégrée (`kopia server`), un **agent KopiaUI**, et des performances notables sur les très gros datasets. **Kopia est l'uploader fichier recommandé par Velero depuis la version 1.12** (à la place de Restic, qui reste supporté en mode legacy). Backends : S3, GCS, Azure Blob, B2, WebDAV, SFTP, filesystem local.

### HAProxy

**Documentation HAProxy**
`https://docs.haproxy.org/`
Référence de configuration du répartiteur de charge, incluant toutes les directives, les algorithmes de répartition et les guides de déploiement en production.

### Pacemaker / Corosync

**Documentation ClusterLabs**
`https://clusterlabs.org/pacemaker/doc/`
Documentation du framework de haute disponibilité, incluant les guides d'installation, la gestion des ressources et les stratégies de fencing.

---

## 5. Virtualisation

### KVM / libvirt

**Documentation libvirt**
`https://libvirt.org/docs.html`
Référence de l'API de virtualisation, documentation des formats XML pour les domaines, réseaux et stockage, et guide de la commande `virsh`.

### QEMU

**Documentation QEMU**
`https://www.qemu.org/docs/master/`
Manuel de l'émulateur et hyperviseur, incluant la gestion des images disque, les options de machine et l'intégration avec KVM.

### Vagrant

**Documentation Vagrant**
`https://developer.hashicorp.com/vagrant/docs`
Guide d'utilisation, référence du Vagrantfile, documentation des providers et des provisioners. **Licence : BSL v1.1 depuis août 2023** (comme tous les produits HashiCorp). Les versions antérieures restent disponibles sous MPL 2.0. Aucun fork open source équivalent à OpenTofu ou OpenBao n'a émergé pour Vagrant à ce jour ; les alternatives modernes pour des environnements de développement locaux sont **kind**, **minikube**, **devbox** ou **Lima** (Linux machines on macOS).

### Packer

**Documentation Packer**
`https://developer.hashicorp.com/packer/docs`
Référence des builders, provisioners et post-processors pour la création d'images machine. **Licence : BSL v1.1 depuis août 2023**. Comme pour Vagrant, aucun fork open source dédié n'a émergé. Les alternatives à considérer pour la construction d'images sont **diskimage-builder** (OpenStack), **kiwi** (SUSE) ou les solutions natives cloud (`aws ec2 register-image`, `gcloud compute images`).

---

## 6. Conteneurs

### Docker

**Documentation Docker**
`https://docs.docker.com/`
Documentation complète de la plateforme Docker. Les points d'entrée les plus utilisés sont la référence du Dockerfile (`https://docs.docker.com/reference/dockerfile/`), la référence de Docker Compose (`https://docs.docker.com/reference/compose-file/`) et le guide des bonnes pratiques de construction d'images.

### Podman

**Documentation Podman**
`https://podman.io/docs`
Guides d'utilisation et de migration depuis Docker. La page de comparaison Docker/Podman est particulièrement utile pour les utilisateurs en transition. Podman se distingue de Docker par son **architecture sans démon** (binaire client-serveur unique, exécutions rootless natives) et par son intégration avec les **pods** au sens Kubernetes (groupes de conteneurs partageant un namespace réseau).

**Quadlet** (`https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html`)
Sous-système de Podman qui permet de déclarer des conteneurs, pods, volumes, réseaux et workloads Kubernetes (`*.container`, `*.pod`, `*.volume`, `*.network`, `*.kube`, `*.image`) directement comme des unités systemd. Les fichiers vivent dans `/etc/containers/systemd/` (système) ou `~/.config/containers/systemd/` (rootless). Le générateur `/usr/lib/systemd/system-generators/podman-system-generator` les convertit en unités `.service` au boot. **Approche recommandée** depuis Podman 4.4 (fin 2022) à la place de `podman generate systemd` (déprécié), notamment pour la production. Plus déclaratif, mieux intégré aux mécanismes systemd (After=, Requires=, drop-in, journald).

### Buildah / Skopeo

**Documentation Buildah**
`https://buildah.io/`
Guide de construction d'images OCI sans démon et sans Dockerfile.

**Documentation Skopeo**
`https://github.com/containers/skopeo`
Documentation de l'outil d'inspection et de copie d'images entre registries.

### Incus (LXC/LXD)

**Documentation Incus**
`https://linuxcontainers.org/incus/docs/main/`
Guide d'utilisation des conteneurs système et des machines virtuelles, incluant la gestion du stockage, des réseaux et des profils.

### Trivy

**Documentation Trivy**
`https://aquasecurity.github.io/trivy/`
Scanner de vulnérabilités open source d'Aqua Security, couvrant un périmètre large : **images conteneurs** (CVE OS et dépendances applicatives), **systèmes de fichiers** (`trivy fs`), **dépôts Git distants** (`trivy repo`), **clusters Kubernetes** (`trivy k8s`), **misconfigurations IaC** (Terraform, Helm, Kubernetes manifests, Dockerfile via `trivy config`), **secrets en clair** (`--scanners secret`) et **génération de SBOM** (CycloneDX, SPDX). Sorties au format JSON, SARIF (intégration GitHub Security), table, ou template. Largement intégré aux pipelines CI/CD et aux registries (Harbor, GitLab Container Registry). Version stable courante en mai 2026 : **0.70.0** (sortie le 17 avril 2026). **⚠️ Alerte sécurité 2026** : un acteur malveillant a publié les versions compromises **0.69.4, 0.69.5, 0.69.6** ainsi que les GitHub Actions `trivy-action` et `setup-trivy` le 19 mars 2026. Versions saines : `trivy ≥ 0.70.0` ou `trivy 0.69.3` ; `trivy-action ≥ 0.36.0` (ou ≤ 0.35.0) ; `setup-trivy ≥ 0.2.7` (ou ≤ 0.2.6). Vérifier impérativement les checksums et signatures Cosign avant déploiement en pipeline.

---

## 7. Kubernetes

### Documentation officielle Kubernetes

**Site principal**
`https://kubernetes.io/docs/`
C'est la référence incontournable. La documentation Kubernetes est organisée en plusieurs sections.

La section **Concepts** (`https://kubernetes.io/docs/concepts/`) explique l'architecture, les ressources fondamentales et les mécanismes internes. C'est le point d'entrée pour comprendre le fonctionnement de Kubernetes.

La section **Tasks** (`https://kubernetes.io/docs/tasks/`) fournit des guides procéduraux pour les opérations courantes : déployer une application, configurer un Ingress, gérer les secrets, etc.

La section **Tutorials** (`https://kubernetes.io/docs/tutorials/`) propose des parcours guidés pour les débutants.

La **Référence de l'API** (`https://kubernetes.io/docs/reference/`) documente chaque champ de chaque ressource Kubernetes. Indispensable pour écrire des manifestes YAML sans erreur.

La commande **kubectl reference** (`https://kubernetes.io/docs/reference/kubectl/`) détaille toutes les sous-commandes et options de kubectl.

**Blog Kubernetes**
`https://kubernetes.io/blog/`
Annonces de nouvelles versions, présentations de fonctionnalités et articles techniques rédigés par les contributeurs du projet.

### kubeadm

**Documentation kubeadm**
`https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/`
Guides d'installation, de mise à jour et de gestion du cycle de vie des clusters via kubeadm. Référence pour les modules 11 et 12.

### Distributions Kubernetes légères

**Documentation K3s**
`https://docs.k3s.io/`
Distribution légère de Kubernetes par SUSE/Rancher, projet CNCF. Binaire unique (~80 MB), datastore SQLite intégré (ou etcd embarqué pour HA), idéal pour edge/IoT, environnements à ressources contraintes et clusters de développement. Inclut Traefik comme Ingress et ServiceLB par défaut. Guide d'installation, options serveur/agent, stockage intégré et spécificités réseau.

**Documentation MicroK8s**
`https://microk8s.io/docs`
Distribution K8s par Canonical (Ubuntu) packagée en snap, idéale pour les postes de développement Ubuntu et les déploiements edge légers. Modèle d'addons (`microk8s enable dns ingress storage prometheus`) très accessible aux débutants. Fonctionne aussi sur Debian via le store snap (paquet `snapd`).

**Documentation k0s**
`https://docs.k0sproject.io/`
Distribution K8s minimale par Mirantis, sans dépendances système (pas besoin de package manager OS). Architecture single-binary similaire à K3s mais avec un focus sur la conformité CNCF stricte (pas de modifications, pas de Traefik intégré). Bonne option pour les déploiements air-gapped et les environnements à compliance forte.

### Outils de productivité kubectl

Quelques utilitaires qui complètent `kubectl` au quotidien et accélèrent significativement le travail interactif sur un cluster.

**k9s**
`https://k9scli.io/`
Interface en mode terminal (TUI) pour naviguer dans les ressources d'un cluster, consulter les logs, exécuter des commandes dans les pods et appliquer des actions (scale, edit, delete) sans quitter le terminal. Souvent considéré comme « le top » pour le diagnostic interactif, particulièrement en situation d'incident.

**stern**
`https://github.com/stern/stern`
Suit les logs de plusieurs pods en parallèle (par sélecteur de labels, namespace, regex). Sortie colorisée avec préfixe pod/conteneur, beaucoup plus pratique que `kubectl logs --prefix -l <label>` pour l'observation temps réel sur des Deployments/StatefulSets multi-réplicas.

**kubectx & kubens**
`https://github.com/ahmetb/kubectx`
Deux scripts shell : `kubectx` pour basculer rapidement entre contextes kubeconfig, `kubens` pour changer de namespace par défaut. Avec complétion bash/zsh et intégration `fzf` pour la sélection interactive — indispensables pour les administrateurs gérant plusieurs clusters.

**kubectl plugins via krew**
`https://krew.sigs.k8s.io/`
Gestionnaire officiel de plugins kubectl. Plus de 200 plugins disponibles (`kubectl resource-capacity`, `kubectl tree`, `kubectl neat`, `kubectl who-can`, etc.). Installation : `kubectl krew install <plugin>`.

**Lens / OpenLens / Headlamp / FreeLens**
`https://k8slens.dev/` — `https://headlamp.dev/` — `https://freelensapp.github.io/`
Interfaces graphiques desktop pour Kubernetes. Lens est devenu commercial mais OpenLens (fork) reste libre. **FreeLens** est un autre fork open source moderne d'OpenLens. **Headlamp** est désormais l'**alternative officiellement recommandée par Kubernetes SIG UI** depuis l'archivage du **Kubernetes Dashboard** historique le 21 janvier 2026 — projet CNCF Sandbox, extensible via plugins, déployable comme application desktop, dans le cluster ou en SaaS, support OIDC et RBAC granulaire. Particulièrement utiles pour découvrir un cluster ou pour les profils moins à l'aise avec la ligne de commande.

### Outils de développement local Kubernetes

**Documentation kind**
`https://kind.sigs.k8s.io/docs/`
**Kubernetes IN Docker** : crée un cluster K8s complet en utilisant des conteneurs Docker comme nœuds. Idéal pour les tests d'intégration, la CI/CD (utilisé par le projet Kubernetes lui-même) et l'apprentissage. Création d'un cluster en ~30 secondes avec `kind create cluster`.

**Documentation minikube**
`https://minikube.sigs.k8s.io/docs/`
Distribution K8s locale historique, supporte plusieurs runtimes (Docker, Podman, KVM, VirtualBox, Hyper-V) et l'activation de plugins via `minikube addons`. Plus complète que kind pour expérimenter des fonctionnalités avancées (Ingress, dashboard, registry local).

**Documentation Skaffold**
`https://skaffold.dev/docs/`
Outil Google pour le cycle de développement continu sur Kubernetes : `skaffold dev` rebuild et redéploie automatiquement à chaque modification du code. Compatible avec Helm, Kustomize, kpt et les manifestes plats.

**Documentation Tilt**
`https://docs.tilt.dev/`
Alternative à Skaffold avec une interface web moderne pour visualiser l'état des builds et des déploiements. Configuration via `Tiltfile` (langage Starlark, syntaxe Python). Particulièrement adapté aux projets multi-services en microservices.

### Helm

**Documentation Helm**
`https://helm.sh/docs/`
Guide d'utilisation du gestionnaire de paquets Kubernetes, référence de la syntaxe des charts, documentation des fonctions de template et bonnes pratiques. **Helm 4** (sortie le 12 novembre 2025 à KubeCon NA Atlanta, pour les 10 ans du projet) introduit le **Server-Side Apply** comme changement majeur (la création et le patching des ressources sont délégués à l'API server K8s plutôt qu'effectués via un three-way merge côté client). **SSA n'est activé que pour les nouvelles installations** ; les releases déjà gérées par Helm 3 conservent le three-way merge même après l'upgrade vers Helm 4. Helm 4 apporte aussi de nouvelles annotations `helm.sh/readiness-success` et `helm.sh/readiness-failure` pour la mise en attente conditionnelle du déploiement, et un runtime optionnel basé sur **WebAssembly** pour les plugins (CLI, getter, post-renderer). La CLI reste largement compatible avec Helm 3, qui passe en EOL à l'automne 2026 (corrections de sécurité jusqu'au 11 novembre 2026). Un nouveau format de chart v3 est prévu mais pas encore inclus dans Helm 4.0.

### etcd

**Documentation etcd**
`https://etcd.io/docs/`
Guide d'opération du magasin clé-valeur distribué, incluant les procédures de sauvegarde/restauration, la gestion du cluster et le tuning de performance. **etcd 3.6** (sortie le 15 mai 2025, première release majeure depuis 3.5 en juin 2021) supprime `etcdctl snapshot restore` (déplacé vers `etcdutl snapshot restore`) et retire le legacy v2store. La 3.5 reste maintenue en parallèle.

### Velero

**Documentation Velero**
`https://velero.io/docs/main/`
Outil de sauvegarde, restauration, migration et disaster recovery pour Kubernetes (projet VMware Tanzu open source, Apache 2.0). Sauvegarde simultanément les **manifestes Kubernetes** (via l'API server) et les **volumes persistants** (via les snapshots CSI ou via les uploaders fichier **Kopia** — recommandé depuis Velero 1.12 — ou **Restic** legacy). Backends de stockage : S3 et compatibles, Azure Blob, GCS. Cas d'usage : migration cluster-à-cluster (y compris cross-cloud), DR planifié, restauration sélective par namespace/sélecteur. À distinguer des snapshots etcd (qui capturent uniquement l'état brut du control plane et nécessitent des certificats compatibles pour la restauration).

### CoreDNS

**Documentation CoreDNS**
`https://coredns.io/manual/toc/`
Serveur DNS modulaire écrit en Go, projet CNCF gradué. CoreDNS est le serveur DNS interne par défaut de Kubernetes depuis 1.13 (remplaçant kube-dns). Sa configuration via le fichier `Corefile` repose sur des **plugins** chaînés (`kubernetes`, `forward`, `cache`, `loop`, `prometheus`, etc.) ; le ConfigMap `coredns` du namespace `kube-system` contient ce Corefile dans un cluster K8s standard. Diagnostic des boucles et des SERVFAIL souvent au cœur des problèmes de résolution DNS dans les pods.

### Ingress Controllers et LoadBalancer bare-metal

Les ressources Kubernetes `Ingress` et `Service type=LoadBalancer` nécessitent un contrôleur ou un fournisseur réel pour fonctionner. Voici les solutions de référence pour les déploiements sur Debian/bare-metal.

**Documentation ingress-nginx**
`https://kubernetes.github.io/ingress-nginx/`
Ingress Controller maintenu par le projet Kubernetes lui-même (à ne pas confondre avec le contrôleur commercial NGINX Inc.). Historiquement le plus largement déployé, configuration via annotations Ingress et ConfigMap. L'IngressClass `nginx` est attendue par la plupart des charts Helm. **⚠️ Important — Retraite officielle le 31 mars 2026** : la SIG Network et le Security Response Committee de Kubernetes ont annoncé en novembre 2025 la fin du projet faute de mainteneurs (un à deux contributeurs sur leur temps libre depuis des années). Plus de releases, ni correctifs de bugs, ni patches de sécurité après cette date. Les déploiements existants continuent de fonctionner mais doivent être migrés vers une **alternative supportée** : la **Gateway API** (recommandation officielle), **NGINX Gateway Fabric** (par F5/NGINX Inc., différent du commercial NGINX Plus Ingress), **kgateway** (anciennement Gloo Gateway, par Solo.io), **Traefik**, **HAProxy Ingress**, **Cilium Gateway** ou **Envoy Gateway**.

**Documentation Traefik**
`https://doc.traefik.io/traefik/`
Ingress Controller et reverse proxy moderne, configuration majoritairement déclarative via CRD (`IngressRoute`, `Middleware`, `TLSStore`). **Ingress Controller par défaut de K3s** (le CNI par défaut de K3s est Flannel). Tableau de bord intégré, support natif de l'**HTTP/3** et du routage sur métadonnées avancées.

**Documentation MetalLB**
`https://metallb.universe.tf/`
Implémentation LoadBalancer pour cluster bare-metal (sans cloud provider). Deux modes : **L2** (annonces ARP/NDP, simple à déployer mais avec un seul nœud actif par adresse) et **BGP** (annonces aux routeurs upstream, supporte la haute disponibilité réelle et le ECMP). Indispensable pour exposer des services hors cluster sur du bare-metal Debian.

**Documentation Kubernetes Gateway API**
`https://gateway-api.sigs.k8s.io/`
Évolution standardisée de Ingress, projet officiel SIG Network. CRD plus expressifs (`Gateway`, `HTTPRoute`, `GRPCRoute`, `TCPRoute`), modèle de rôles séparant infrastructure (Gateway) et application (HTTPRoute). Implémenté nativement par Cilium 1.18+, Istio, Envoy Gateway, Traefik, NGINX Gateway Fabric. Recommandé pour les nouveaux déploiements en 2026.

### Plugins CNI (réseau Kubernetes)

**Spécification CNI**
`https://www.cni.dev/`
Spécification du standard Container Network Interface, qui définit l'interface entre orchestrateurs (Kubernetes) et plugins réseau. Toute distribution K8s (kubeadm, K3s, EKS, GKE, AKS) installe au moins un plugin CNI.

**Documentation Calico**
`https://docs.tigera.io/calico/latest/`
CNI éprouvé combinant routage L3 (BGP, VXLAN, IPIP) et NetworkPolicy avancées. Calico Open Source reste largement utilisé comme solution simple ; Calico Enterprise (Tigera) ajoute observabilité et sécurité commerciales.

**Documentation Cilium**
`https://docs.cilium.io/`
CNI basé sur eBPF, projet CNCF gradué. Apporte service mesh (sans sidecar via Cilium Service Mesh), Hubble pour l'observabilité réseau, support Gateway API embarqué (v1.3.0 dans Cilium 1.18) et chiffrement IPsec/WireGuard de l'overlay. Version stable courante en 2026 : 1.18.x. Cilium est devenu le CNI par défaut de plusieurs offres K8s managées (GKE Dataplane V2, AKS Azure CNI Powered by Cilium, EKS Auto Mode).

**Documentation Flannel**
`https://github.com/flannel-io/flannel`
CNI léger et minimaliste (overlay VXLAN par défaut), idéal pour les clusters de développement et K3s (où il est le CNI par défaut). N'implémente pas les NetworkPolicy.

---

## 8. Infrastructure as Code

### Ansible

**Documentation Ansible**
`https://docs.ansible.com/ansible/latest/`
Documentation complète de l'outil d'automatisation. Les sections les plus consultées sont l'index des modules (`https://docs.ansible.com/ansible/latest/collections/index.html`), le guide des playbooks et la référence Jinja2 pour les templates. La documentation de chaque module est accessible directement depuis la ligne de commande avec `ansible-doc <module>`.

**Ansible Galaxy**
`https://galaxy.ansible.com/`
Dépôt communautaire de rôles et de collections. Les collections certifiées et les rôles avec un score élevé sont les plus fiables.

### Terraform

**Documentation Terraform**
`https://developer.hashicorp.com/terraform/docs`
Documentation du langage HCL, des commandes CLI et des concepts fondamentaux (state, providers, modules). La référence du langage HCL est à `https://developer.hashicorp.com/terraform/language`.

**Registre Terraform**
`https://registry.terraform.io/`
Catalogue des providers et des modules communautaires. Chaque provider dispose de sa propre documentation détaillant les ressources et data sources disponibles. C'est la référence quotidienne pour écrire du code Terraform.

### OpenTofu

**Documentation OpenTofu**
`https://opentofu.org/docs/`
Fork open source de Terraform (MPL 2.0) sous gouvernance de la Linux Foundation, créé après le changement de licence Terraform vers la BSL en août 2023. Drop-in replacement de Terraform 1.5.x (mêmes providers, mêmes modules du Registre Terraform). La documentation couvre les commandes (`tofu init`, `tofu plan`, `tofu apply`…) et les fonctionnalités spécifiques comme le chiffrement de l'état côté client. Le registre dédié est à `https://search.opentofu.org/`.

---

## 9. CI/CD et GitOps

### GitLab CI

**Documentation GitLab CI/CD**
`https://docs.gitlab.com/ci/`
Référence de la syntaxe `.gitlab-ci.yml`, documentation des runners et guides d'architecture des pipelines.

### GitHub Actions

**Documentation GitHub Actions**
`https://docs.github.com/en/actions`
Guides d'utilisation, syntaxe des workflows, documentation des runners self-hosted et marketplace des actions.

### Argo (CD, Rollouts, Workflows, Events)

**Documentation Argo CD**
`https://argo-cd.readthedocs.io/`
Guide d'installation, référence de la CLI, architecture et bonnes pratiques de déploiement GitOps. Versions stables courantes en mai 2026 : Argo CD **3.3.x** (sortie début 2026) et Argo CD **3.4** (GA cible début mai 2026). Les trois versions mineures les plus récentes sont supportées (politique : 3.2, 3.3, 3.4 actuellement). Les changements notables d'Argo CD 3.0 (mai 2025) à connaître pour une migration depuis 2.x : RBAC plus strict par défaut (notamment `logs, get` doit désormais être explicite), suppression du support legacy `argocd-cm` pour la configuration des dépôts, métriques `argocd_app_sync_status`/`argocd_app_health_status` consolidées dans `argocd_app_info`. Le guide officiel de migration `2.14 → 3.0` détaille la procédure.

**Documentation Argo Rollouts**
`https://argoproj.github.io/argo-rollouts/`
Contrôleur Kubernetes qui étend les `Deployment` natifs avec des stratégies avancées : **Blue/Green**, **Canary** (par étapes, avec analyse automatique des métriques Prometheus/Datadog/CloudWatch), **promotion progressive** et **rollback automatique** sur SLO non respecté. CRD `Rollout` (drop-in du `Deployment`), `AnalysisTemplate` et `AnalysisRun`. Intégration native avec Istio, NGINX Ingress, Traefik, AWS ALB et le service mesh pour le pilotage du trafic. Alternative dans le même espace : **Flagger** (FluxCD).

**Documentation Argo Workflows et Argo Events**
`https://argoproj.github.io/argo-workflows/` et `https://argoproj.github.io/argo-events/`
**Argo Workflows** : moteur d'orchestration de workflows containerisés pour Kubernetes (DAG ou step-by-step), utilisé pour le ML/data engineering, les pipelines CI/CD complexes ou les jobs batch. **Argo Events** : framework de gestion d'événements (sources : webhook, S3, GitHub, Kafka, Slack…) qui déclenche des workflows ou d'autres ressources Kubernetes. Ces deux composants sont indépendants d'Argo CD mais combinables. Toute la suite Argo est CNCF graduée.

### Flux

**Documentation Flux**
`https://fluxcd.io/docs/`
Guide d'installation, concepts GitOps, référence des Custom Resources et guides de migration.

### Tekton

**Documentation Tekton**
`https://tekton.dev/docs/`
Framework de pipelines CI/CD natif Kubernetes. **Tekton Pipelines 1.0** (sortie le 23 mai 2025) marque la stabilisation des API. Projet **gradué** au sein de la **CD Foundation** (CDF), puis accepté comme **CNCF Incubating le 24 mars 2026** (transfert de la CDF à la CNCF, sans changement pour les utilisateurs : même code, mêmes mainteneurs). Couvre les CRD `Task`, `Pipeline`, `TaskRun`, `PipelineRun`, `Workspace`, `EventListener`, etc. Le **Tekton Hub** (`https://hub.tekton.dev/`) recense des `Tasks` et `Pipelines` réutilisables (clone Git, builds Buildah/Kaniko, scans Trivy, déploiements ArgoCD, signatures Cosign). À noter l'intégration **Tekton Chains** : signe automatiquement les images produites par les pipelines avec Cosign en mode keyless, et publie les attestations SLSA dans le journal Rekor. CLI `tkn` (séparée du contrôleur). Pertinent quand un cluster Kubernetes est la plateforme cible, alternative à GitLab CI/GitHub Actions self-hosted.

---

## 10. Observabilité

### Prometheus

**Documentation Prometheus**
`https://prometheus.io/docs/`
Architecture, configuration, référence PromQL et guides d'instrumentation. La section PromQL (`https://prometheus.io/docs/prometheus/latest/querying/`) est la référence pour l'écriture des requêtes et des règles d'alerte. **Prometheus 3.0** est sorti en novembre 2024 (première release majeure depuis 7 ans) et apporte une nouvelle UI (Mantine UI, vue arborescente PromQL, explorateur de métriques amélioré), le **Remote Write 2.0** (support natif des métadonnées, exemplars, histogrammes natifs), une **compatibilité OpenTelemetry** renforcée et l'**Agent mode** stabilisé. Recommandation officielle : passer par 2.55 avant l'upgrade vers 3.0 ; rollback possible vers 2.55 mais pas vers les versions antérieures. Versions stables courantes en 2026 : branche 3.x.

### Grafana

**Documentation Grafana**
`https://grafana.com/docs/grafana/latest/`
Guide d'installation, configuration des data sources, création de dashboards et gestion des alertes. La bibliothèque de dashboards communautaires (`https://grafana.com/grafana/dashboards/`) fournit des dashboards prêts à l'emploi pour la majorité des services. **Grafana 13** (sortie le 20 avril 2026 à GrafanaCON 2026 Barcelone) introduit les **dashboards dynamiques** GA (s'adaptent aux variables et au contexte au lieu de multiplier des copies statiques), des **layout templates** basés sur des méthodologies standards (DORA, USE/RED method), un workflow **Git bidirectionnel** sur le schéma de dashboard redessiné (GitHub, GitLab, Bitbucket), et le **Grafana Assistant** (agent IA, Grafana Cloud uniquement). 170+ data sources et 120+ panels disponibles. Pour le self-managed, Grafana est distribué en **OSS (AGPLv3 depuis 2021)** et Enterprise.

### Loki

**Documentation Loki**
`https://grafana.com/docs/loki/latest/`
Architecture, référence LogQL et guides de déploiement pour la solution d'agrégation de logs (sous **AGPLv3** depuis avril 2021, comme Grafana, Tempo et Mimir). Versions stables courantes en mai 2026 : **3.7.x** (la 3.7.0 est sortie le 26 mars 2026). La nouvelle architecture **Loki "Thor"** (annoncée à GrafanaCON 2026 Barcelone, prévue pour Loki 4.0) introduit une ingestion via Kafka comme couche de durabilité, un stockage **colonnaire**, et un nouveau moteur de requêtage qui distribue le travail entre partitions ; Grafana Labs annonce jusqu'à 20× moins de données scannées et 10× plus rapide sur les requêtes agrégées. Trade-off : les déploiements distribués nécessitent Kafka + stockage objet.

### Tempo

**Documentation Tempo**
`https://grafana.com/docs/tempo/latest/`
Backend de tracing distribué de la stack Grafana (sous **AGPLv3** depuis avril 2021), alternative open source à Jaeger. Tempo s'intègre nativement avec Loki (via les exemplars et les liens trace-to-logs) et Prometheus (via les service graphs et les span metrics). Stockage objet seul (S3, GCS, Azure Blob), pas de base de données distincte. À privilégier dans une stack 100% Grafana ; Jaeger reste pertinent pour les déploiements où le stockage objet n'est pas disponible.

### Mimir

**Documentation Mimir**
`https://grafana.com/docs/mimir/latest/`
Backend de stockage long terme et requêtage distribué pour Prometheus, **sous licence AGPLv3** (alignée sur Grafana, Loki et Tempo depuis avril 2021), maintenu par Grafana Labs. Fork de Cortex côté Grafana incluant des fonctionnalités précédemment commerciales (GEM, Grafana Cloud) ; **Cortex** reste un projet CNCF actif **sous Apache 2.0** avec une gouvernance distincte — préférer Cortex si la dépendance à AGPLv3 pose problème. Mimir 3.0 (sortie novembre 2025 à KubeCon NA) introduit un nouveau query engine PromQL-compatible (MQE), la séparation read/write via une couche Kafka asynchrone, et annonce jusqu'à 92% de mémoire en moins. À considérer quand la rétention dépasse plusieurs mois ou quand on agrège plusieurs Prometheus dans une vue unique.

### Grafana Alloy

**Documentation Alloy**
`https://grafana.com/docs/alloy/latest/`
Collecteur unifié (logs, métriques, traces, profils) basé sur la **Alloy configuration syntax** (anciennement nommée « River », renommée lors de la création d'Alloy ; le langage reste le même, inspiré de HCL avec composants chaînables explicitement). Alloy est une **distribution de l'OpenTelemetry Collector** (annoncée à GrafanaCON 2024) qui wrappe les composants OTel et y ajoute des pipelines natifs Prometheus, le tout 100% OTLP-compatible — pas un fork mais une distribution avec une syntaxe de configuration différente du YAML traditionnel d'OTel Collector. Successeur officiel de Promtail (EOL le 2 mars 2026) et du **Grafana Agent** (Static, Flow et Operator — tous en **EOL depuis le 1er novembre 2025**, plus aucun correctif de sécurité). La page « Migrate from Promtail » (`https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/`) couvre la commande `alloy convert --source-format=promtail`.

### OpenTelemetry

**Documentation OpenTelemetry**
`https://opentelemetry.io/docs/`
Spécifications du standard d'observabilité unifié, guides d'instrumentation par langage et documentation du collecteur. OpenTelemetry est une convention d'**instrumentation** (SDK et collecteur de relais) ; les **backends** de stockage et visualisation sont Jaeger, Tempo, Zipkin (traces), Prometheus, Mimir, Cortex (métriques), Loki, Elasticsearch (logs).

### Jaeger

**Documentation Jaeger**
`https://www.jaegertracing.io/docs/`
Guide de déploiement et d'utilisation de la plateforme de tracing distribué. Projet CNCF gradué. Jaeger v2 (sortie 2024-2025) est désormais basée sur l'OpenTelemetry Collector et apporte de nombreuses améliorations de configuration et de stockage. Jaeger v1 a atteint son EOL le 31 décembre 2025.

---

## 11. Sécurité

### AppArmor

**Documentation AppArmor**
`https://apparmor.net/`
Documentation du framework de contrôle d'accès obligatoire. Le wiki Debian sur AppArmor (`https://wiki.debian.org/AppArmor`) fournit des informations spécifiques à Debian.

### HashiCorp Vault

**Documentation Vault**
`https://developer.hashicorp.com/vault/docs`
Guide complet de la gestion centralisée des secrets, incluant les moteurs de secrets, les méthodes d'authentification et l'intégration Kubernetes. Versions notables en 2026 : **Vault 1.19** (LTS), **Vault 1.20.x** (sortie GA juin 2025, dernière 1.x stable), et **Vault Enterprise 2.0** (sortie le 13 avril 2026). HashiCorp passe directement de la 1.21 à la 2.0 pour s'aligner sur le **modèle de cycle de support IBM** (Cycle-2 : 2 ans de support standard, +1 an de correctifs critiques, +3 ans de support étendu). Vault 2.0 introduit la fédération d'identité workload (SPIFFE), le SCIM 2.0 (beta) et l'envelope encryption pour les workloads streaming, mais comporte des breaking changes (configuration Azure auth notamment) — consulter le guide de migration officiel avant l'upgrade. La licence reste BSL pour Vault et Vault Enterprise depuis août 2023 ; pour l'open source, voir OpenBao ci-dessous.

### OpenBao

**Documentation OpenBao**
`https://openbao.org/docs/`
Fork open source (MPL 2.0) de HashiCorp Vault, créé après le passage de Vault sous licence BSL en août 2023. OpenBao est issu du fork de Vault 1.14.0 (dernière version MPL) et est désormais sous gouvernance de la Linux Foundation, avec des contributions notamment d'IBM. Version stable courante en 2026 : 2.5.x. Drop-in replacement de Vault 1.14.x : la CLI `bao` reprend exactement la même syntaxe que `vault`, et les fonctionnalités essentielles (KV v2, transit, PKI, Kubernetes auth, etc.) sont identiques. À privilégier pour les nouveaux déploiements souhaitant rester sur une licence open source reconnue par l'OSI.

### CIS Benchmarks

**CIS Benchmarks**
`https://www.cisecurity.org/cis-benchmarks`
Référentiels de durcissement pour Debian, Kubernetes, Docker et les cloud providers. Les benchmarks sont disponibles gratuitement après inscription. Ils constituent la base des audits de conformité abordés dans le module 16.

### Falco

**Documentation Falco**
`https://falco.org/docs/`
Guide de la solution de détection d'intrusion en temps réel pour les conteneurs et Kubernetes. Falco est un projet CNCF **gradué le 29 février 2024**, basé sur eBPF (driver moderne, recommandé) ou un module noyau (driver legacy). Les règles s'écrivent au format **YAML** avec un DSL d'expressions de filtrage propre à Falco (composé de `rule`, `desc`, `condition`, `output`, `priority`, plus des `macro` et `list` réutilisables) — ce n'est ni Rego ni une autre syntaxe de policy. Les règles communautaires sont distribuées via `https://github.com/falcosecurity/rules` et installables avec `falcoctl`.

### Tetragon

**Documentation Tetragon**
`https://tetragon.io/`
Outil de sécurité runtime basé sur eBPF, sous-projet de Cilium (CNCF). Créé par Isovalent, dont l'acquisition par Cisco a été annoncée en décembre 2023 et finalisée le 12 avril 2024 ; Cilium et Tetragon restent open source au sein de la CNCF. Version stable courante en 2026 : **1.7.x** (1.0 GA atteinte en 2024, série 1.x en évolution rapide). Complément/alternative à Falco avec une **capacité d'enforcement** (pas seulement détection) : peut tuer un processus ou refuser un appel système au niveau du noyau au moment de la violation de politique, avant que l'action malveillante ne se termine. Politiques exprimées via la CRD `TracingPolicy`. Particulièrement adapté aux environnements ayant déjà déployé Cilium comme CNI.

### Policy as Code Kubernetes — OPA Gatekeeper

**Documentation OPA Gatekeeper**
`https://open-policy-agent.github.io/gatekeeper/website/docs/`
Admission controller pour Kubernetes basé sur OPA (Open Policy Agent, projet CNCF gradué). Les politiques s'écrivent dans le langage **Rego** et sont distribuées via les CRD `ConstraintTemplate` et `Constraint`. L'écosystème **Gatekeeper Library** (`https://open-policy-agent.github.io/gatekeeper-library/`) fournit des contraintes prêtes à l'emploi. Outil `gator` pour tester les contraintes hors cluster.

### Policy as Code Kubernetes — Kyverno

**Documentation Kyverno**
`https://kyverno.io/docs/`
Alternative à Gatekeeper, projet CNCF passé au statut **graduated le 24 mars 2026** (annoncé officiellement à KubeCon + CloudNativeCon Europe à Amsterdam). Les politiques sont écrites directement en **YAML** (sans nécessiter Rego), ce qui réduit la courbe d'apprentissage. Quatre familles de politiques : **validate** (admission), **mutate** (modification automatique avant création), **generate** (création de ressources dérivées) et **cleanup** (suppression planifiée). La CLI `kyverno` permet de tester les politiques en local et de scanner les manifestes existants. Les versions récentes adoptent **CEL** (Common Expression Language) pour s'aligner avec la direction de Kubernetes en matière d'admission control. Kyverno s'utilise comme admission controller K8s mais aussi via la CLI, comme image conteneur ou SDK pour intégrer la gouvernance de politiques au-delà de Kubernetes.

### cert-manager

**Documentation cert-manager**
`https://cert-manager.io/docs/`
Guide de gestion automatisée des certificats TLS dans Kubernetes, incluant l'intégration avec Let's Encrypt et les PKI internes.

### Sigstore (Cosign, Rekor, Fulcio)

**Documentation Sigstore**
`https://docs.sigstore.dev/`
Projet OpenSSF (Linux Foundation) pour la signature et la vérification d'artefacts logiciels (images conteneur, binaires, attestations SLSA). Trois outils principaux : **Cosign** pour signer/vérifier (`cosign sign`, `cosign verify`, `cosign attest`), **Rekor** comme journal de transparence immuable, et **Fulcio** comme autorité de certification éphémère pour la signature keyless via OIDC. **Cosign 3.x** est sorti en octobre 2025 (la 3.0.1 étant la première version publiée) ; version stable courante en mai 2026 : **3.0.6**. Cosign 3 adopte par défaut le **Sigstore Bundle Format** (un seul fichier contient tout le matériel de vérification), rend le flag `--bundle` obligatoire pour les signatures, et stocke les signatures de conteneur comme **OCI Image 1.1 referring artifacts** (au lieu du schéma cosign legacy). La 2.x reste maintenue avec corrections de bugs. Toutes les versions supportent les attestations SLSA, les SBOM (CycloneDX, SPDX), la signature keyless, et l'intégration native avec GitHub Actions / GitLab CI / Tekton Chains.

### Gestion des secrets Kubernetes — Sealed Secrets, SOPS, External Secrets

**Sealed Secrets (Bitnami)**
`https://sealed-secrets.netlify.app/`
Contrôleur Kubernetes (Bitnami, désormais VMware) qui chiffre les Secrets côté client avec une clé publique du cluster, produisant des `SealedSecret` (CRD) versionnables dans Git. Seul le contrôleur dans le cluster peut les déchiffrer en `Secret` natifs. CLI : `kubeseal`. Adapté aux workflows GitOps simples sans dépendance externe.

**SOPS — Mozilla / getsops**
`https://github.com/getsops/sops`
Outil de chiffrement de fichiers structurés (YAML, JSON, ENV, INI) avec gestion granulaire (les valeurs sont chiffrées, pas les clés). Support multi-backends : AWS KMS, GCP KMS, Azure Key Vault, HashiCorp Vault, age, PGP. Largement utilisé dans Flux (`SOPSOperator`) et combinable avec Helm via `helm-secrets`. Le projet est passé sous gouvernance CNCF Sandbox en 2024.

**External Secrets Operator (ESO)**
`https://external-secrets.io/`
Opérateur Kubernetes qui synchronise des secrets depuis un store externe (HashiCorp Vault, OpenBao, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault, IBM Cloud Secrets Manager, etc.) vers des Secrets natifs Kubernetes. Définit les CRD `SecretStore`/`ClusterSecretStore` (configuration du backend) et `ExternalSecret` (mapping). Projet CNCF Sandbox (depuis 2022, sponsorisé par TAG Security). Approche complémentaire de Sealed Secrets : préférer ESO quand la source de vérité est un gestionnaire de secrets centralisé externe.

---

## 12. Cloud providers

### AWS

**Documentation AWS**
`https://docs.aws.amazon.com/`
Documentation exhaustive de tous les services AWS. Les points d'entrée les plus pertinents pour cette formation sont la documentation EC2, EKS, S3, IAM et la CLI AWS.

**Documentation EKS**
`https://docs.aws.amazon.com/eks/`
Guide spécifique au service Kubernetes managé d'AWS.

### Google Cloud

**Documentation Google Cloud**
`https://cloud.google.com/docs`
Documentation de l'ensemble des services GCP. Les guides GKE, Compute Engine et Cloud Storage sont les plus pertinents.

**Documentation GKE**
`https://cloud.google.com/kubernetes-engine/docs`
Guide du service Kubernetes managé de Google Cloud.

### Azure

**Documentation Azure**
`https://learn.microsoft.com/en-us/azure/`
Documentation complète de la plateforme Azure. Les sections AKS, Virtual Machines et Azure Storage sont les plus pertinentes.

**Documentation AKS**
`https://learn.microsoft.com/en-us/azure/aks/`
Guide du service Kubernetes managé d'Azure.

### FinOps Kubernetes — OpenCost et Kubecost

**Documentation OpenCost**
`https://opencost.io/docs/`
Spécification ouverte et implémentation de référence pour la **mesure des coûts cloud-native** sur Kubernetes. Projet **CNCF Incubating depuis le 25 octobre 2024** et solution **FinOps Foundation Certified** — la seule à porter cette double étiquette. Permet de calculer les coûts par pod, namespace, label, ServiceAccount, et de les rapprocher des factures cloud (AWS, GCP, Azure, on-premise via custom pricing). Expose des métriques Prometheus (`opencost_*`) consommables dans Grafana. Distribué sous Apache 2.0. Pour le module 18 (FinOps).

**Documentation Kubecost**
`https://docs.kubecost.com/`
Solution commerciale construite sur OpenCost, **acquise par IBM en septembre 2024** et désormais intégrée à la **IBM FinOps Suite** (avec IBM Cloudability et IBM Turbonomic). Apporte une UI riche, des rapports avancés, le multi-cluster, l'optimisation automatique et les recommandations de right-sizing. Existe en édition gratuite limitée et en édition Enterprise (payante). Pour la majorité des cas d'usage open source, **OpenCost** suffit ; **Kubecost** se justifie pour les organisations multi-cluster qui veulent une expérience clé en main avec support commercial.

---

## 13. Service Mesh et stockage distribué

### Istio

**Documentation Istio**
`https://istio.io/latest/docs/`
Guide de la plateforme de service mesh, incluant l'architecture, la gestion du trafic, la sécurité mTLS et l'observabilité. Versions stables courantes en mai 2026 : **Istio 1.29.x**. Évolution majeure depuis 2024 : le mode **Ambient** (sans sidecar) est **GA depuis Istio 1.22** (2024) — les pods n'ont plus besoin d'injection ni de sidecar Envoy, le trafic L4 passe par un `ztunnel` par nœud (eBPF) et le L7 par des `waypoint proxies` optionnels. **Ambient Multicluster** est en Alpha depuis 1.27 et passe en Beta avec les annonces de KubeCon Europe 2026 (Amsterdam) qui ajoutent également la **Gateway API Inference Extension** et un support expérimental d'**Agentgateway**. Le mode classique avec sidecars Envoy reste pleinement supporté ; le choix dépend des contraintes opérationnelles (Ambient = moins de surcharge mémoire, Sidecar = portabilité maximale et écosystème mature).

### Linkerd

**Documentation Linkerd**
`https://linkerd.io/2/docs/`
Documentation du service mesh léger, incluant les guides d'installation, les fonctionnalités de sécurité et les outils de diagnostic. Le code source reste open source (Apache v2) et Linkerd est un projet CNCF gradué.

> **Important — Modèle de release depuis Linkerd 2.15 (février 2024)** — Buoyant (vendor commercial qui emploie les mainteneurs principaux) ne distribue plus gratuitement les **stable releases** de Linkerd. Les **edge releases** (hebdomadaires, sans garantie de stabilité) restent disponibles librement, ainsi que le code source pour reconstruire ses propres binaires. Pour les builds stables prêts à la production, Buoyant Enterprise for Linkerd (BEL) est **gratuit pour les organisations de moins de 50 personnes** ; au-delà, une licence commerciale est requise. Documentation BEL : `https://docs.buoyant.io/buoyant-enterprise-linkerd/`.

### Ceph

**Documentation Ceph**
`https://docs.ceph.com/`
Guide du système de stockage distribué, couvrant RADOS, RBD, CephFS et RGW.

### Rook

**Documentation Rook**
`https://rook.io/docs/rook/latest/`
Guide de l'opérateur Kubernetes pour le stockage distribué, incluant le déploiement de Ceph sur Kubernetes.

### MinIO et alternatives S3-compatibles open source

**Documentation MinIO**
`https://min.io/docs/minio/linux/`
Guide de la solution de stockage objet compatible S3 (AGPLv3), incluant les déploiements standalone et distribués. **Important : le dépôt GitHub minio/minio a été archivé le 25 avril 2026** ; la Community Edition n'est plus maintenue (passage en maintenance mode en décembre 2025, archivage en février puis avril 2026). Les binaires précompilés ne sont plus distribués pour la version communautaire — le code source reste disponible sous AGPLv3 mais sans nouvelles fonctionnalités, mises à jour de compatibilité, ni correctifs de sécurité garantis. La société pousse désormais sa solution propriétaire **AIStor**. Les déploiements existants continuent de fonctionner mais doivent envisager une migration.

**Alternatives open source recommandées en 2026** :

- **SeaweedFS** (`https://seaweedfs.github.io/`) — Stockage distribué Apache 2.0, S3-compatible, optimisé pour les petits objets, performances I/O élevées. Choix le plus stable pour un usage général.
- **Garage** (`https://garagehq.deuxfleurs.fr/`) — Object storage Rust/AGPLv3 conçu pour l'auto-hébergement par sysadmins, légère réplication multi-zones, prêt sur matériel modeste.
- **RustFS** (`https://rustfs.com/`) — Fork-like Apache 2.0 (sans clause AGPL), drop-in MinIO-compatible, adapté aux usages commerciaux où l'AGPL pose problème.
- **Ceph RGW** (déjà documenté ci-dessus) — Gateway S3 de Ceph, à privilégier quand on déploie déjà Ceph pour bloc/fichier.

La CLI **`mc`** (MinIO Client) reste utilisable comme client S3 polyvalent contre n'importe quel backend compatible (AWS S3, Garage, SeaweedFS, Ceph RGW, etc.).

### Chaos Engineering — Chaos Mesh et LitmusChaos

**Documentation Chaos Mesh**
`https://chaos-mesh.org/docs/`
Plateforme de chaos engineering native Kubernetes, projet **CNCF Incubating depuis février 2022**. Couvre un large éventail de scénarios via des CRD : `PodChaos` (kill, latence), `NetworkChaos` (perte, latence, partition, corruption), `IOChaos`, `StressChaos` (CPU/mémoire), `KernelChaos`, `TimeChaos`, `DNSChaos`, `HTTPChaos`. Tableau de bord web (Chaos Dashboard) et CLI `chaosctl` ; orchestration de scénarios via `Schedule` et `Workflow`. Origine : PingCAP (TiDB).

**Documentation LitmusChaos**
`https://docs.litmuschaos.io/`
Alternative à Chaos Mesh, projet **CNCF Incubating depuis janvier 2022**. Architecture orientée **ChaosCenter** (portail multi-cluster avec RBAC) et **ChaosHub** (catalogue d'expériences réutilisables). Les expériences sont packagées via la CRD `ChaosExperiment` et orchestrées via `ChaosEngine`. Privilégier LitmusChaos pour les organisations multi-tenants (ChaosCenter), Chaos Mesh pour la simplicité de mise en œuvre et la richesse des chaos réseau natifs.

---

## 14. Standards et spécifications

### OCI (Open Container Initiative)

**Spécifications OCI**
`https://opencontainers.org/`
Standards de l'industrie pour les formats d'images conteneurs et les runtimes. Référence pour comprendre la portabilité entre Docker, Podman, Buildah et les runtimes Kubernetes.

### CNCF (Cloud Native Computing Foundation)

**Paysage CNCF**
`https://landscape.cncf.io/`
Cartographie de l'ensemble des projets de l'écosystème cloud-native, classés par catégorie (orchestration, runtime, observabilité, etc.). Outil précieux pour découvrir des alternatives et comprendre l'écosystème.

**Trail Map CNCF**
`https://www.cncf.io/certification/training/`
Parcours d'apprentissage recommandé par la CNCF pour progresser dans l'écosystème cloud-native.

---

## 15. Certifications

### KCNA (Kubernetes and Cloud Native Associate) — pré-professionnel

**Programme KCNA**
`https://training.linuxfoundation.org/certification/kubernetes-cloud-native-associate/`
Certification d'entrée de gamme (multi-choice, ~60 questions, 1h30) sans prérequis. Valide la compréhension de Kubernetes, de l'architecture cloud-native et des principes CNCF. Tarif autour de 250 USD avec un retake gratuit. Bonne préparation à la CKA et à la CKAD.

### KCSA (Kubernetes and Cloud Native Security Associate) — pré-professionnel

**Programme KCSA**
`https://training.linuxfoundation.org/certification/kubernetes-cloud-native-security-associate/`
Certification théorique (multi-choice, ~60 questions, 1h30) sans prérequis. Couvre six domaines : Cluster Component Security (22%), Security Fundamentals (22%), Threat Model (16%), Platform Security (16%), Cloud Native Security (14%), Compliance & Frameworks (10%). Bonne préparation à la CKS qui exige la CKA en prérequis.

### CKA (Certified Kubernetes Administrator)

**Programme CKA**
`https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/`
Informations sur l'examen, domaines couverts, ressources de préparation et conditions de passage. L'examen est pratique (résolution de problèmes sur un cluster réel) et couvre les modules 11, 12 et une partie du module 16. Examen aligné sur Kubernetes 1.34/1.35 (mai 2026), inclut désormais le **Gateway API** (révision de scope février 2025) et les **native sidecars** (GA depuis K8s 1.29).

### CKS (Certified Kubernetes Security Specialist)

**Programme CKS**
`https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/`
Examen avancé centré sur la sécurité Kubernetes. Correspond au module 16 et aux aspects sécurité des modules 12 et 14. La PodSecurityPolicy a été supprimée du périmètre depuis K8s 1.25 ; les **Pod Security Standards** + admission controllers sont désormais obligatoires. La CKA est un prérequis obligatoire.

### Terraform Associate

**Programme Terraform Associate**
`https://developer.hashicorp.com/certifications/infrastructure-automation`
Certification validant les compétences fondamentales Terraform. Correspond au module 13. **Version courante 004 depuis le 8 janvier 2026** (alignée Terraform 1.12), score de passage 70%, ~60 questions en 1h. La 003 n'est plus disponible.

### Programme Kubestronaut

**Page Kubestronaut**
`https://www.cncf.io/training/kubestronaut/`
Programme de reconnaissance CNCF pour les personnes ayant obtenu et maintenu **les cinq certifications Kubernetes** simultanément (KCNA + KCSA + CKA + CKAD + CKS). Donne droit à une veste exclusive et à un statut spécial dans la communauté. Un bundle commercial regroupe les cinq examens à tarif préférentiel.

### HashiCorp Vault Associate

**Programme Vault Associate (003)**
`https://developer.hashicorp.com/certifications/security-automation`
Certification HashiCorp pour les ingénieurs sécurité, développeurs et opérateurs travaillant avec Vault. Examen QCM en ligne (1h, ~60 questions) aligné sur **Vault 1.16**. Couvre les auth methods, les policies, les secrets dynamiques, le moteur Transit et les API. Les compétences acquises sont directement transférables à **OpenBao** (fork open source de Vault 1.14.x).

---

## Utilisation efficace de la documentation

Savoir naviguer dans la documentation officielle est une compétence en soi. Quelques techniques accélèrent considérablement la recherche.

**Utiliser la recherche intégrée** — La plupart des documentations officielles disposent d'un moteur de recherche. Sur kubernetes.io, la recherche indexe l'intégralité de la documentation, incluant la référence de l'API.

**Consulter la référence de l'API Kubernetes directement depuis kubectl** — La commande `kubectl explain <ressource>` affiche la documentation de n'importe quel champ d'une ressource Kubernetes, sans quitter le terminal.

```bash
kubectl explain deployment.spec.strategy  
kubectl explain pod.spec.containers.resources  
kubectl explain service.spec.type  
```

**Utiliser les man pages locales** — Sur un système Debian, `man -k <mot-clé>` recherche dans l'ensemble des man pages installées. Le paquet `manpages-fr` installe les traductions françaises des pages de manuel les plus courantes.

**Consulter la documentation embarquée des paquets** — Le répertoire `/usr/share/doc/<paquet>/` contient souvent des exemples de configuration, des changelogs et des fichiers README spécifiques à Debian.

```bash
ls /usr/share/doc/nginx/  
zless /usr/share/doc/nginx/changelog.Debian.gz  
```

⏭️ [Communautés et forums](/annexes/D.2-communautes-forums.md)
