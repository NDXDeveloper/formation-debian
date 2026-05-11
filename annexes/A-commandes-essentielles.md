🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe A — Commandes essentielles par module

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif de cette annexe

Cette annexe rassemble les commandes les plus importantes abordées tout au long de la formation, organisées module par module. Elle constitue une référence rapide destinée à être consultée au quotidien, que ce soit pendant l'apprentissage ou en situation opérationnelle.

Pour chaque module, les commandes sont présentées avec leur rôle principal et un exemple d'utilisation représentatif. Il ne s'agit pas d'une documentation exhaustive de chaque commande — la page de manuel (`man`) et la documentation officielle restent les sources de référence pour les options avancées — mais d'un aide-mémoire opérationnel couvrant les usages les plus courants.

---

## Sous-sections de cette annexe

- [A.1 — Référence des commandes par catégorie](/annexes/A.1-reference-commandes.md) : classement fonctionnel transversal (réseau, stockage, sécurité, etc.)
- [A.2 — Options courantes et exemples](/annexes/A.2-options-exemples.md) : détail des options les plus utilisées avec des exemples commentés
- [A.3 — Cheat sheets par technologie](/annexes/A.3-cheat-sheets.md) : fiches synthétiques imprimables pour Debian, Docker, Kubernetes, Terraform et Ansible

---

## Conventions utilisées

Tout au long de cette annexe, les conventions suivantes s'appliquent.

Les commandes précédées du symbole `#` doivent être exécutées avec les privilèges root, soit directement en tant que root, soit via `sudo`. Les commandes précédées de `$` s'exécutent en tant qu'utilisateur standard.

Les éléments entre chevrons `<valeur>` représentent des paramètres à remplacer par une valeur réelle. Les éléments entre crochets `[option]` indiquent des paramètres facultatifs. Les points de suspension `...` signalent qu'une liste d'arguments supplémentaires est possible.

Lorsqu'une commande possède un équivalent plus moderne ou recommandé, celui-ci est mentionné. Par exemple, `ip` est privilégié par rapport à `ifconfig`, et `ss` par rapport à `netstat`.

---

## Parcours 1 — Administrateur Système Debian

### Module 1 : Fondamentaux de Debian

Les commandes de ce module concernent l'installation et la configuration initiale du système.

`lsblk` permet de lister les périphériques de type bloc et leurs partitions, ce qui est indispensable lors du partitionnement. `fdisk` et `gdisk` sont les outils de partitionnement respectivement pour les tables MBR et GPT. `parted` offre une alternative unifiée capable de gérer les deux formats.

`tasksel` est l'outil utilisé pendant l'installation pour sélectionner des ensembles de paquets prédéfinis (serveur web, environnement de bureau, etc.).

Pour la post-installation, `dpkg-reconfigure locales` permet de reconfigurer les paramètres de langue et de localisation, `timedatectl` gère le fuseau horaire et la synchronisation de l'horloge, et `localectl` contrôle la disposition du clavier. La commande `adduser` crée un nouvel utilisateur de manière interactive, tandis que `usermod -aG sudo <utilisateur>` l'ajoute au groupe sudo pour lui accorder les privilèges d'administration.

### Module 2 : Debian Desktop

Ce module introduit les commandes liées à l'environnement graphique et à la gestion du poste de travail.

`tasksel` intervient à nouveau pour installer un environnement de bureau complet (`tasksel install desktop gnome-desktop` par exemple). La commande `update-alternatives` permet de gérer les choix par défaut du système, notamment l'éditeur de texte ou le terminal. `apt install` avec les noms de méta-paquets appropriés (`xfce4`, `kde-plasma-desktop`, `gnome`) installe les différents environnements.

Pour le matériel, `lspci` identifie les périphériques PCI (cartes graphiques, contrôleurs réseau), `lsusb` liste les périphériques USB, et `dmesg` affiche les messages du noyau, utile pour diagnostiquer les problèmes de pilotes. La commande `apt install firmware-linux-nonfree` installe les firmwares propriétaires nécessaires à certains composants matériels. `bluetoothctl` pilote la configuration Bluetooth en ligne de commande, et `pavucontrol` ou `wpctl` (pour PipeWire) contrôlent le système audio.

### Module 3 : Administration système de base

Ce module couvre un large éventail de commandes fondamentales pour l'administration quotidienne.

En matière de système de fichiers, `ls -la` affiche le contenu détaillé d'un répertoire avec les permissions et les propriétaires. `chmod` modifie les permissions d'un fichier ou répertoire, `chown` en change le propriétaire, et `setfacl` / `getfacl` gèrent les listes de contrôle d'accès (ACL) étendues. `mount` et `umount` réalisent le montage et le démontage des systèmes de fichiers, tandis que le fichier `/etc/fstab` en définit le montage automatique au démarrage. `ln -s` crée un lien symbolique et `ln` sans option crée un lien physique. `df -h` affiche l'espace disque disponible en format lisible et `du -sh` calcule la taille d'un répertoire.

Pour la gestion des utilisateurs, `adduser` et `deluser` créent et suppriment des utilisateurs de manière interactive. `usermod` modifie les propriétés d'un compte (groupes, shell, répertoire personnel). `passwd` change le mot de passe d'un utilisateur, `chage` configure les politiques d'expiration des mots de passe, et `visudo` édite la configuration de sudo en sécurité.

La gestion des processus s'appuie sur `ps aux` pour lister tous les processus actifs, `top` et `htop` pour la supervision interactive en temps réel, `kill` et `killall` pour envoyer des signaux aux processus, et `nice` / `renice` pour ajuster les priorités d'exécution. `bg` et `fg` gèrent les processus en arrière-plan et au premier plan, et `nohup` permet de lancer un processus qui survivra à la fermeture du terminal.

Le sous-système systemd constitue un ensemble majeur de commandes. `systemctl start|stop|restart|reload <service>` contrôle les services. `systemctl enable|disable <service>` gère leur activation au démarrage. `systemctl status <service>` affiche l'état détaillé d'un service. `journalctl` consulte les journaux du système, avec des filtres comme `-u <service>` pour cibler un service spécifique, `--since` et `--until` pour délimiter une période, ou `-f` pour suivre les nouveaux messages en temps réel. `systemd-analyze` permet d'analyser les temps de démarrage du système.

### Module 4 : Gestion des paquets

La gestion des paquets est au cœur de l'administration Debian.

`apt update` met à jour la liste des paquets disponibles depuis les dépôts configurés. `apt upgrade` installe les mises à jour disponibles pour les paquets déjà installés, tandis que `apt full-upgrade` gère également les changements de dépendances. `apt install <paquet>` installe un ou plusieurs paquets, `apt remove <paquet>` les désinstalle en conservant les fichiers de configuration, et `apt purge <paquet>` les supprime intégralement. `apt search <terme>` recherche un paquet par nom ou description, et `apt show <paquet>` affiche ses informations détaillées. `apt autoremove` nettoie les dépendances devenues orphelines.

Au niveau dpkg, `dpkg -i <fichier.deb>` installe un paquet depuis un fichier local, `dpkg -l` liste les paquets installés, `dpkg -L <paquet>` affiche les fichiers fournis par un paquet, et `dpkg -S <fichier>` identifie le paquet propriétaire d'un fichier donné. `dpkg-reconfigure <paquet>` relance la configuration d'un paquet déjà installé.

Pour les dépôts tiers sur Debian Trixie, la méthode standard consiste à créer manuellement un fichier dans `/etc/apt/sources.list.d/` (au format `.sources` recommandé, ou `.list` pour la compatibilité legacy). Le paquet `software-properties-common` (qui fournissait `add-apt-repository` / `apt-add-repository`) **n'est plus distribué dans Debian 13** ; il faut donc éditer les fichiers à la main, ou utiliser un script d'automatisation. La méthode recommandée pour gérer les clés GPG des dépôts tiers consiste à les déposer dans `/etc/apt/keyrings/` puis à les référencer explicitement dans le fichier source (clause `Signed-By:` du format DEB822, ou option `[signed-by=…]` du format one-line). L'ancien `apt-key` est **déprécié depuis Debian 11 Bullseye** (warning au moindre usage), reste **fonctionnel mais déprécié dans Debian 12 Bookworm**, et est **complètement supprimé dans Debian 13 Trixie** (le binaire `/usr/bin/apt-key` n'est plus livré). Le dépôt global `/etc/apt/trusted.gpg.d/` est à éviter pour les nouvelles intégrations car il fait confiance à la clé pour toutes les sources. Le fichier `/etc/apt/preferences.d/` accueille les règles de pinning qui contrôlent la priorité entre dépôts.

Flatpak se gère via `flatpak install <remote> <application>`, `flatpak run <application>`, `flatpak update` et `flatpak list`.

### Module 5 : Scripting et automatisation

Ce module s'articule autour de l'écriture et de l'exécution de scripts.

En Bash, `bash -x <script>` exécute un script en mode débogage. L'en-tête `#!/bin/bash` suivi de `set -euo pipefail` constitue la base d'un script robuste. `shellcheck <script>` analyse statiquement un script pour détecter les erreurs et mauvaises pratiques. `trap '<commande>' EXIT ERR` définit des actions à exécuter lors de la réception de signaux ou en cas d'erreur.

Pour le traitement de texte, `grep` filtre les lignes correspondant à un motif, `sed` effectue des transformations sur un flux de texte, `awk` permet un traitement structuré par colonnes, et `jq` analyse et transforme des données JSON. La combinaison de ces outils via les pipes (`|`) forme la base du traitement de données en ligne de commande.

`crontab -e` édite la table de planification de l'utilisateur courant, et `systemctl list-timers` affiche les timers systemd actifs. `curl` effectue des requêtes HTTP depuis la ligne de commande, ce qui est essentiel pour interagir avec les APIs REST.

Côté Python, sur Debian 12+ l'environnement Python système est marqué `externally-managed` (PEP 668) : `pip install` global échoue volontairement. Pour des bibliothèques de projet, créer un environnement virtuel isolé avec `python3 -m venv <répertoire>`, l'activer avec `source <répertoire>/bin/activate` puis `pip install <paquet>`. Pour des **applications Python autonomes** (httpie, ansible, black, etc.), préférer `pipx install <application>` qui isole automatiquement chaque outil dans son propre venv tout en exposant ses commandes dans `~/.local/bin`.

### Module 6 : Réseau et sécurité

Les commandes réseau et sécurité sont parmi les plus utilisées au quotidien.

`ip addr show` affiche les adresses IP des interfaces réseau. `ip link set <interface> up|down` active ou désactive une interface. `ip route show` affiche la table de routage. `ss -tlnp` liste les ports TCP en écoute avec les processus associés. `ping` teste la connectivité réseau, `traceroute` et `mtr` analysent le chemin réseau vers une destination, et `tcpdump` capture le trafic réseau pour analyse.

Pour le pare-feu, `nft list ruleset` affiche l'ensemble des règles nftables actives. `nft add rule <famille> <table> <chaîne> <règle>` ajoute une règle de filtrage. `ufw enable`, `ufw allow <port>` et `ufw status` fournissent une interface simplifiée. `fail2ban-client status` affiche l'état des jails de protection contre les tentatives d'intrusion.

SSH est piloté par `ssh <utilisateur>@<hôte>` pour la connexion distante, `ssh-keygen -t ed25519` pour la génération de clés, `ssh-copy-id <utilisateur>@<hôte>` pour le déploiement de la clé publique, et `ssh -L` / `ssh -R` pour le tunneling de ports.

WireGuard se configure via `wg genkey`, `wg pubkey` pour la génération des clés, et `wg-quick up|down <interface>` pour l'activation de l'interface VPN. Pour le chiffrement des disques, `cryptsetup luksFormat <device>` initialise un volume chiffré et `cryptsetup luksOpen <device> <nom>` le déverrouille.

### Module 7 : Debian Server — Services de base

Ce module introduit les commandes de gestion des services serveur courants.

Pour les serveurs web, `apache2ctl -t` teste la syntaxe de la configuration Apache, `a2ensite` / `a2dissite` activent ou désactivent un virtual host, et `a2enmod` / `a2dismod` gèrent les modules. Côté Nginx, `nginx -t` vérifie la configuration. Caddy se pilote via `caddy run`, `caddy adapt` et `caddy reload`. La commande `certbot` gère l'obtention et le renouvellement des certificats Let's Encrypt.

Pour les bases de données, `mariadb -u root -p` ouvre une session MariaDB, `mysqldump` exporte une base de données, et `mariadb-secure-installation` sécurise l'installation initiale. Côté PostgreSQL, `sudo -u postgres psql` ouvre une session, `pg_dump` exporte une base, et `pg_restore` la restaure. `pg_lsclusters` liste les instances PostgreSQL installées.

Les serveurs de fichiers se gèrent via `smbclient` pour tester les partages Samba, `testparm` pour valider la configuration Samba, et `exportfs -ra` pour recharger les exports NFS.

### Module 8 : Services réseau avancés, sauvegarde et HA

Ce module couvre des services d'infrastructure plus spécialisés.

Pour le DNS, `named-checkconf` et `named-checkzone` valident respectivement la configuration et les fichiers de zones BIND9. `rndc reload` recharge la configuration sans redémarrer le service. `dig` et `nslookup` interrogent les serveurs DNS pour vérifier la résolution.

Le serveur DHCP Kea se contrôle via `keactrl start|stop|status`. Pour le serveur mail, `postconf` affiche et modifie les paramètres de Postfix, `postqueue -p` affiche la file d'attente, et `doveadm` administre Dovecot.

En matière de sauvegarde, `rsync -avz --delete <source> <destination>` synchronise des répertoires en mode incrémental. `borgbackup` (alias `borg`) offre une sauvegarde dédupliquée et chiffrée avec `borg init`, `borg create` et `borg extract`. `restic` fournit des fonctionnalités équivalentes avec `restic init`, `restic backup` et `restic restore`.

Pour le stockage et la haute disponibilité, `mdadm --create` crée un RAID logiciel et `mdadm --detail` en affiche l'état. `pvcreate`, `vgcreate` et `lvcreate` construisent la pile LVM (volume physique, groupe de volumes, volume logique). `smartctl -a <device>` interroge les données SMART d'un disque. `crm` ou `pcs` administrent un cluster Pacemaker/Corosync, et `haproxy -c -f <fichier>` valide la configuration HAProxy.

---

## Parcours 2 — Ingénieur Infrastructure & Conteneurs

### Module 9 : Virtualisation

Les commandes de virtualisation s'organisent autour de libvirt et de ses outils.

`virsh list --all` affiche toutes les machines virtuelles, quel que soit leur état. `virsh start|shutdown|destroy <vm>` contrôle le cycle de vie d'une VM. `virsh snapshot-create-as <vm> <nom>` crée un instantané, et `virsh migrate` assure la migration à chaud entre hyperviseurs. `virt-install` crée une nouvelle machine virtuelle depuis la ligne de commande, et `virt-manager` offre une interface graphique pour la gestion.

`qemu-img create -f qcow2 <fichier> <taille>` crée un disque virtuel, et `qemu-img info <fichier>` en affiche les propriétés.

Vagrant se pilote via `vagrant init <box>` pour initialiser un projet, `vagrant up` pour démarrer l'environnement, `vagrant ssh` pour s'y connecter, et `vagrant destroy` pour le supprimer. Packer utilise `packer validate <fichier>` et `packer build <fichier>` pour construire des images système personnalisées. **Note : Vagrant et Packer sont passés sous licence BSL en août 2023** comme tous les produits HashiCorp ; aucun fork open source équivalent à OpenTofu/OpenBao n'a émergé pour ces deux outils. Pour les nouveaux projets, envisager **kind**, **minikube** ou **Lima** pour les environnements de développement Kubernetes/Linux locaux.

### Module 10 : Conteneurs

Docker constitue le cœur de ce module. `docker build -t <image>:<tag> .` construit une image à partir d'un Dockerfile. `docker run -d --name <nom> -p <hôte>:<conteneur> <image>` lance un conteneur en arrière-plan. `docker ps` liste les conteneurs actifs (`-a` pour inclure les arrêtés). `docker logs <conteneur>` affiche les journaux, `docker exec -it <conteneur> /bin/bash` ouvre un shell interactif dans un conteneur en cours d'exécution. `docker compose up -d` lance une stack multi-conteneurs définie dans un fichier `compose.yaml`, et `docker compose down` l'arrête.

`docker image ls` liste les images locales, `docker image prune` nettoie les images inutilisées, et `docker system df` affiche l'utilisation de l'espace disque par Docker.

Podman reprend une syntaxe quasi identique : `podman run`, `podman build`, `podman ps`, avec l'avantage de fonctionner sans démon et en mode rootless. `buildah` construit des images sans Dockerfile via des commandes pas à pas, et `skopeo inspect` inspecte des images dans un registry distant sans les télécharger.

Pour LXC/Incus, `incus launch <image> <nom>` crée et démarre un conteneur système, `incus list` les affiche, et `incus exec <nom> -- <commande>` exécute une commande dans le conteneur.

En matière de sécurité, `trivy image <image>` scanne une image à la recherche de vulnérabilités connues, et `grype <image>` offre une alternative équivalente.

### Module 11 : Kubernetes — Fondamentaux

`kubectl` est la commande centrale de l'écosystème Kubernetes.

`kubectl get pods|services|deployments|nodes` affiche les ressources du cluster. `kubectl describe <type> <nom>` donne des informations détaillées sur une ressource. `kubectl apply -f <fichier.yaml>` crée ou met à jour des ressources à partir d'un manifeste déclaratif. `kubectl delete <type> <nom>` supprime une ressource. `kubectl logs <pod>` affiche les journaux d'un pod, avec `-f` pour le suivi en temps réel et `-c <conteneur>` pour cibler un conteneur spécifique dans un pod multi-conteneurs.

`kubectl exec -it <pod> -- /bin/sh` ouvre un shell dans un pod. `kubectl port-forward <pod> <port-local>:<port-pod>` redirige un port pour le débogage local. `kubectl get events --sort-by=.metadata.creationTimestamp` affiche les événements récents du cluster.

Pour l'installation, `kubeadm init` initialise un nœud control plane, `kubeadm join` y rattache un nœud worker, et `kubeadm token create --print-join-command` génère la commande de jonction. `k3s` s'installe via son script d'installation et se pilote avec `k3s kubectl` ou un `kubectl` standard pointant vers sa configuration.

`kubectl create namespace <nom>` crée un espace de noms, `kubectl config set-context --current --namespace=<nom>` définit le namespace par défaut du contexte courant, et `kubectl get all -n <namespace>` liste toutes les ressources d'un namespace.

### Module 12 : Kubernetes — Production

Ce module approfondit l'utilisation de `kubectl` et introduit les outils d'écosystème.

`kubectl top nodes` et `kubectl top pods` affichent la consommation de ressources (nécessite le metrics-server). `kubectl drain <nœud>` évacue les pods d'un nœud en vue d'une maintenance, et `kubectl uncordon <nœud>` le remet en service. `kubectl cordon <nœud>` empêche le placement de nouveaux pods sans évacuer ceux en cours.

`kubectl auth can-i <verbe> <ressource>` vérifie les permissions RBAC de l'utilisateur courant. `kubectl debug <pod>` attache un conteneur éphémère de débogage à un pod existant ; la variante `kubectl debug -it node/<nœud> --image=ubuntu` lance un pod privilégié avec le rootfs du nœud monté dans `/host` (utile pour déboguer un nœud sans SSH, notamment sur les clusters managés). Les outils tiers `k9s` (TUI), `stern` (logs multi-pods), `kubectx`/`kubens` (bascule de contexte/namespace) et le gestionnaire `kubectl krew` (plugins) accélèrent significativement le travail interactif au quotidien.

Helm se pilote via `helm repo add <nom> <url>` pour ajouter un dépôt de charts, `helm install <release> <chart>` pour déployer une application, `helm upgrade <release> <chart>` pour la mettre à jour, et `helm list` pour afficher les releases installées. `helm template <chart>` génère les manifestes YAML sans les appliquer, ce qui est utile pour la revue et le débogage.

Kustomize s'utilise directement via `kubectl apply -k <répertoire>` ou en mode autonome avec `kustomize build <répertoire>`.

`etcdctl snapshot save <fichier>` sauvegarde l'état du cluster etcd. Pour la restauration, l'outil officiel est désormais `etcdutl snapshot restore <fichier>` — `etcdctl snapshot restore` est déprécié depuis etcd 3.5 et **a été supprimé dans etcd 3.6** (sortie le 15 mai 2025), car la restauration opère directement sur les fichiers et n'utilise pas la connexion réseau au cluster. La sous-commande `etcdctl snapshot status` a aussi été déplacée vers `etcdutl snapshot status`.

### Module 13 : Infrastructure as Code

Ansible utilise `ansible-inventory --list` pour vérifier l'inventaire, `ansible <groupe> -m ping` pour tester la connectivité avec les hôtes gérés, `ansible-playbook <fichier.yaml>` pour exécuter un playbook, et `ansible-galaxy install <rôle>` pour installer un rôle depuis Galaxy. `ansible-vault encrypt|decrypt|edit <fichier>` gère le chiffrement des données sensibles. L'option `--check --diff` simule l'exécution d'un playbook en affichant les modifications prévues sans les appliquer.

Terraform repose sur `terraform init` pour initialiser un répertoire de travail et télécharger les providers, `terraform plan` pour prévisualiser les changements, `terraform apply` pour les appliquer, et `terraform destroy` pour supprimer l'infrastructure. `terraform state list` affiche les ressources dans l'état courant, et `terraform import <ressource> <id>` importe une ressource existante. `terraform fmt` formate les fichiers de configuration et `terraform validate` en vérifie la syntaxe.

**OpenTofu** est le fork open source (MPL 2.0) de Terraform, créé après le changement de licence de HashiCorp vers la BSL en août 2023 et désormais maintenu par la Linux Foundation. Il sert de remplacement direct (drop-in) pour Terraform 1.5.x : la CLI utilise `tofu` à la place de `terraform` (`tofu init`, `tofu plan`, `tofu apply`…), avec la même syntaxe HCL, les mêmes providers et le même format d'état. OpenTofu apporte en plus le chiffrement de l'état côté client (AES-GCM, AWS KMS, GCP KMS), absent de Terraform OSS.

---

## Parcours 3 — Expert Cloud-Native & Kubernetes

### Module 14 : CI/CD et GitOps

Les runners CI/CD se gèrent via `gitlab-runner register` et `gitlab-runner verify` pour GitLab, ou via le script `config.sh` pour les runners GitHub Actions self-hosted.

Pour Jenkins sur Kubernetes, `kubectl` est utilisé pour déployer et superviser les pods Jenkins. Tekton s'administre via la CLI `tkn` : `tkn pipeline list`, `tkn pipelinerun logs <nom>`, `tkn task start <nom>`.

ArgoCD se pilote avec `argocd login <serveur>`, `argocd app create` pour déclarer une application, `argocd app sync <nom>` pour déclencher une synchronisation, et `argocd app get <nom>` pour afficher son état. Flux utilise `flux bootstrap` pour l'installation initiale, `flux get kustomizations` pour vérifier l'état des réconciliations, et `flux reconcile kustomization <nom>` pour forcer une synchronisation.

`kubeseal --format yaml < secret.yaml > sealed-secret.yaml` chiffre un secret Kubernetes pour le stocker dans Git avec Sealed Secrets. L'outil `sops` chiffre et déchiffre des fichiers de configuration avec `sops --encrypt` et `sops --decrypt`. **External Secrets Operator** suit une approche complémentaire : il synchronise des secrets depuis un store externe (Vault, OpenBao, AWS Secrets Manager, GCP Secret Manager…) vers des Secrets natifs Kubernetes via les CRD `SecretStore` et `ExternalSecret` ; aucune CLI dédiée, l'opérateur se pilote en appliquant ces ressources avec `kubectl apply`.

### Module 15 : Observabilité et monitoring

Prometheus se gère via `promtool check config <fichier>` pour valider la configuration et `promtool check rules <fichier>` pour vérifier les règles d'alerte. `amtool check-config <fichier>` valide la configuration d'AlertManager.

Pour les logs, la stack ELK s'administre via les APIs REST d'Elasticsearch (`curl -X GET "localhost:9200/_cat/indices"`) et via Kibana. Loki est interrogé via LogQL dans Grafana. La collecte se fait avec **Grafana Alloy** (`alloy run`, configuration en **Alloy syntax** — anciennement « River » — successeur officiel de Promtail qui est EOL depuis le 2 mars 2026), `fluent-bit` (alternative légère multi-destinations), ou directement avec l'OTel Collector (`otelcol`).

Jaeger se déploie sur Kubernetes et s'interroge via son interface web. L'instrumentation OpenTelemetry s'intègre au niveau du code applicatif et n'expose pas de commande CLI spécifique, mais le collecteur `otelcol` se configure via un fichier YAML.

### Module 16 : Sécurité avancée et cloud-native

Le hardening système utilise `sysctl -a` pour afficher les paramètres noyau, `sysctl -w <paramètre>=<valeur>` pour les modifier à chaud, et `/etc/sysctl.d/` pour les rendre persistants. `aa-status` affiche l'état des profils AppArmor, `aa-enforce` et `aa-complain` basculent un profil entre les modes. `lynis audit system` réalise un audit de conformité CIS du système.

Pour Kubernetes, l'API PodSecurityPolicy (`kubectl get psp`) a été **supprimée** dans Kubernetes 1.25 (août 2022) ; elle est remplacée par les Pod Security Standards appliqués au niveau du namespace via `kubectl label namespace <ns> pod-security.kubernetes.io/enforce=<level>` (avec `level` = `privileged`, `baseline` ou `restricted`). La commande `gator test` vérifie les contraintes OPA Gatekeeper, et `falco` s'exécute comme un DaemonSet dont les alertes se consultent via `kubectl logs`.

Vault se pilote avec `vault operator init`, `vault operator unseal`, `vault kv put <chemin> <clé>=<valeur>` et `vault kv get <chemin>`. **OpenBao** est le fork open source (MPL 2.0) de Vault, créé après le passage de HashiCorp sous BSL en août 2023, désormais sous gouvernance de la Linux Foundation (OpenSSF). La CLI `bao` reprend la même syntaxe que `vault` (`bao operator init`, `bao kv put`…), avec une compatibilité directe issue du fork de Vault 1.14.x. La version OpenBao 2.5.0 (février 2026) ajoute notamment la lecture locale sur les nœuds HA standby (équivalent de la fonctionnalité « Performance Standby Nodes » de Vault Enterprise). `cosign sign` et `cosign verify` assurent la signature et la vérification des images conteneurs (Cosign 3.0 sorti en octobre 2025 — préférer le mode keyless OIDC + Fulcio + Rekor au mode clé classique pour la production).

### Module 17 : Cloud, Service Mesh et stockage distribué

Les CLI cloud se déclinent en `aws <service> <commande>` pour AWS, `gcloud <service> <commande>` pour Google Cloud, et `az <service> <commande>` pour Azure. Par exemple, `aws ec2 describe-instances`, `gcloud compute instances list` et `az vm list` listent les instances de calcul sur chaque provider.

Istio s'installe et se gère via `istioctl install`, `istioctl analyze` pour détecter les problèmes de configuration, et `istioctl proxy-status` pour vérifier l'état des sidecars Envoy. Linkerd utilise `linkerd install`, `linkerd check` et `linkerd viz dashboard`.

Ceph s'administre avec `ceph status`, `ceph osd tree` et `ceph health detail`. MinIO utilise la CLI `mc` : `mc alias set <nom> <url> <accès> <secret>`, `mc mb <alias>/<bucket>`, `mc cp <source> <alias>/<bucket>/`. **Important** : la Community Edition de MinIO a été archivée définitivement le **25 avril 2026** (un premier archivage avait eu lieu en février 2026, puis le dépôt avait été temporairement rouvert avant d'être à nouveau verrouillé en lecture seule). Le dépôt GitHub `minio/minio` est désormais figé, sans nouvelle release ni image officielle ; tout le développement actif a basculé sur le produit propriétaire MinIO AIStor. Pour les nouveaux déploiements open source S3-compatibles, envisager **SeaweedFS** (Apache 2.0), **Garage** (AGPLv3, lightweight, multi-site), **RustFS** (Apache 2.0, drop-in MinIO mais encore en alpha en 2026) ou **Ceph RGW**. La CLI `mc` reste un client S3 polyvalent contre n'importe quel backend compatible. Rook se gère principalement via `kubectl` en appliquant des manifestes CRD.

### Module 18 : Edge Computing, FinOps et tendances

K3s en contexte edge utilise les mêmes commandes que l'installation standard, avec des options supplémentaires comme `--node-external-ip` ou `--flannel-iface` pour adapter le déploiement aux contraintes réseau.

Kubecost et OpenCost se déploient via Helm et s'interrogent à travers leurs interfaces web ou leurs APIs REST. `kubectl resource-capacity` (plugin krew) affiche un résumé de la capacité et de l'utilisation des ressources du cluster.

`bpftool` et `bpftrace` sont les outils de base pour interagir avec eBPF. Cilium propose `cilium status`, `cilium connectivity test` et `hubble observe` pour l'observabilité réseau basée sur eBPF.

### Module 19 : Architectures de référence et cas d'usage

Ce module de synthèse réutilise les commandes des modules précédents dans des contextes intégrés. Les outils spécifiques au développement local incluent `kind create cluster` et `kind delete cluster` pour gérer des clusters Kubernetes dans Docker, `minikube start` pour une alternative supportant plusieurs runtimes (Docker, KVM, Podman) et l'activation d'addons, `skaffold dev` pour le cycle de développement continu, et `tilt up` pour une alternative avec interface web.

Velero gère les sauvegardes et restaurations de clusters avec `velero backup create <nom>`, `velero restore create --from-backup <nom>`, et `velero schedule create` pour les sauvegardes planifiées.

Pour le chaos engineering, `chaos-mesh` et `litmus` se déploient via Helm et se pilotent à travers leurs CRD et interfaces web respectives.

---

## Conseils d'utilisation

Cette annexe est conçue pour être parcourue de manière non linéaire. Lorsqu'une commande apparaît dans le contexte d'un module, la section correspondante fournit suffisamment de contexte pour comprendre son rôle sans devoir relire le module complet. Pour les commandes récurrentes comme `kubectl`, `docker`, `systemctl` ou `apt`, les usages les plus avancés apparaissent dans les modules de niveau supérieur, chaque occurrence enrichissant les précédentes.

Les sous-sections A.1, A.2 et A.3 reprennent ces mêmes commandes sous des angles différents : par catégorie fonctionnelle, avec leurs options détaillées, et sous forme de cheat sheets synthétiques destinées à être imprimées ou gardées à portée de main.

⏭️ [Référence des commandes par catégorie](/annexes/A.1-reference-commandes.md)
