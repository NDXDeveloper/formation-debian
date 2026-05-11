🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe B — Fichiers de configuration Debian

## Formation Debian : du Desktop au Cloud-Native

---

## Présentation

L'administration d'un système Debian repose en grande partie sur la modification de fichiers texte. Contrairement aux systèmes exploitant des bases de registre ou des interfaces de configuration propriétaires, Debian — comme l'ensemble des distributions GNU/Linux — centralise la quasi-totalité de ses paramètres dans des fichiers lisibles et modifiables avec un simple éditeur de texte. Cette approche offre une transparence totale, une facilité de sauvegarde et de versionning, ainsi qu'une automatisation naturelle via des outils comme Ansible ou des scripts shell.

Cependant, la richesse de l'écosystème Debian implique une dispersion de ces fichiers à travers l'arborescence du système, chacun suivant sa propre syntaxe. Un administrateur doit savoir rapidement localiser le bon fichier, en comprendre la structure et le modifier sans introduire d'erreur. C'est l'objectif de cette annexe.

---

## Périmètre couvert

Cette annexe couvre les fichiers de configuration abordés dans les 19 modules de la formation, depuis les fichiers système fondamentaux de Debian (parcours 1) jusqu'aux fichiers de configuration des outils cloud-native (parcours 3). Elle s'organise autour de trois axes complémentaires.

### [B.1 — Localisation des fichiers importants par service](/annexes/B.1-localisation-fichiers.md)

Cette première section est un annuaire : pour chaque service ou composant étudié dans la formation, elle indique l'emplacement exact des fichiers de configuration, des fichiers de données, des journaux et des fichiers de travail. Elle couvre le système de base (réseau, authentification, démarrage), les services serveur (web, bases de données, DNS, DHCP, mail), les outils de conteneurisation (Docker, Podman), Kubernetes et ses composants, ainsi que les outils d'Infrastructure as Code (Ansible, Terraform). L'objectif est de répondre à la question « où se trouve le fichier à modifier ? » en quelques secondes.

### [B.2 — Syntaxe et exemples annotés](/annexes/B.2-syntaxe-exemples.md)

Une fois le fichier localisé, encore faut-il en comprendre la syntaxe. Cette section présente les formats de configuration rencontrés dans la formation — INI, YAML, TOML, JSON, directives clé-valeur, syntaxes spécifiques à certains services — avec des exemples annotés ligne par ligne. Chaque exemple correspond à une configuration fonctionnelle et commentée, directement exploitable comme point de départ. Les pièges courants propres à chaque format (indentation YAML, échappement des caractères spéciaux, ordre des directives) sont signalés.

### [B.3 — Templates et bonnes pratiques](/annexes/B.3-templates-bonnes-pratiques.md)

Cette dernière section va au-delà de la syntaxe pour proposer des modèles de configuration complets, prêts à être adaptés à un environnement de production. Elle couvre les templates pour les services les plus courants (virtual host Nginx, pool PHP-FPM, unité systemd personnalisée, fichier Compose Docker, manifeste Kubernetes, playbook Ansible), accompagnés des bonnes pratiques de gestion : organisation des fichiers, utilisation des répertoires drop-in, versionning avec Git, validation avant application et stratégies de sauvegarde.

---

## Principes fondamentaux de la configuration sous Debian

Avant de plonger dans les fichiers spécifiques, il est utile de rappeler les principes structurants qui gouvernent l'organisation de la configuration dans un système Debian.

### La hiérarchie /etc

Le répertoire `/etc` est le point central de la configuration système. Son nom, hérité des premières versions d'Unix, abritait à l'origine les fichiers « et cetera » — tout ce qui ne trouvait pas sa place ailleurs. Dans un système Debian moderne, `/etc` contient exclusivement des fichiers de configuration et constitue le premier endroit où chercher lorsqu'on souhaite modifier le comportement d'un service.

À l'intérieur de `/etc`, chaque service dispose généralement de son propre répertoire ou fichier. La convention est simple : un service nommé `nginx` aura sa configuration dans `/etc/nginx/`, un service nommé `ssh` dans `/etc/ssh/`, et ainsi de suite. Cette régularité facilite la découverte : même face à un service inconnu, la première action réflexe de l'administrateur est de regarder dans `/etc/<nom-du-service>/`.

### Le modèle drop-in

De nombreux services Debian adoptent le modèle « drop-in » : au lieu de concentrer toute la configuration dans un seul fichier monolithique, ils définissent un fichier principal qui inclut automatiquement le contenu d'un répertoire auxiliaire, généralement suffixé en `.d`. Ce mécanisme se retrouve dans APT (`/etc/apt/sources.list.d/`), sudo (`/etc/sudoers.d/`), sysctl (`/etc/sysctl.d/`), systemd (`/etc/systemd/system/<service>.d/`), rsyslog (`/etc/rsyslog.d/`) et de nombreux autres composants.

Le modèle drop-in présente trois avantages majeurs. Il permet d'ajouter de la configuration sans modifier le fichier principal fourni par le paquet, ce qui évite les conflits lors des mises à jour. Il facilite l'automatisation, chaque outil pouvant déposer son propre fichier de configuration sans risquer d'écraser ceux des autres. Il améliore la lisibilité en séparant les préoccupations dans des fichiers distincts et nommés de manière explicite.

Les fichiers dans les répertoires `.d` sont généralement lus par ordre alphabétique. La convention de nommage `XX-description.conf` (où XX est un nombre de 00 à 99) permet de contrôler l'ordre de chargement et donc la priorité des directives.

### Configuration par défaut et overrides

Debian distingue systématiquement la configuration par défaut, fournie par les paquets et installée dans `/etc`, de la configuration de l'administrateur, qui vient la compléter ou la surcharger. Lors de la mise à jour d'un paquet, si le fichier de configuration d'origine a été modifié par l'administrateur, `dpkg` propose un choix : conserver la version locale, installer la nouvelle version du mainteneur, examiner les différences ou fusionner manuellement.

Pour les services utilisant systemd, le mécanisme d'override est particulièrement élégant. La commande `systemctl edit <service>` crée automatiquement un fichier de surcharge dans `/etc/systemd/system/<service>.d/override.conf` qui complète ou remplace les directives du fichier d'unité d'origine sans le toucher. La commande `systemctl cat <service>` affiche la configuration résultante en indiquant la provenance de chaque directive.

### Formats de configuration rencontrés

La formation couvre un éventail large de formats de configuration, reflet de la diversité de l'écosystème.

Les fichiers système Debian traditionnels utilisent des formats spécifiques à chaque service. `/etc/fstab` utilise un format tabulaire à six colonnes. `/etc/network/interfaces` emploie un format déclaratif avec des strophes `iface`. Les fichiers Apache suivent une syntaxe de directives avec des blocs `<VirtualHost>`. Nginx utilise des blocs hiérarchiques délimités par des accolades. Chacun de ces formats a ses propres règles pour les commentaires, les espaces et les caractères spéciaux.

Les outils modernes privilégient des formats structurés standardisés. YAML est le format dominant dans l'écosystème cloud-native : Ansible, Kubernetes, Docker Compose, les charts Helm et la majorité des outils CI/CD l'utilisent. HCL (HashiCorp Configuration Language) est employé par Terraform. TOML est utilisé par certains outils comme les registries de conteneurs. JSON apparaît dans les configurations de Docker daemon et certaines APIs.

### Validation avant application

Un principe essentiel de l'administration système est de toujours valider un fichier de configuration avant de l'appliquer. La plupart des services fournissent une commande de vérification dédiée. Le tableau ci-dessous résume les principales commandes de validation.

| Service | Commande de validation |
|---------|----------------------|
| Apache | `apache2ctl -t` |
| Nginx | `nginx -t` |
| Caddy | `caddy validate --config Caddyfile` |
| Postfix | `postfix check` |
| BIND9 | `named-checkconf` / `named-checkzone` |
| HAProxy | `haproxy -c -f /etc/haproxy/haproxy.cfg` |
| sshd | `sshd -t` |
| sudo | `visudo -c` |
| nftables | `nft -c -f /etc/nftables.conf` |
| systemd (unité) | `systemd-analyze verify <fichier.service>` |
| Prometheus | `promtool check config prometheus.yml` |
| AlertManager | `amtool check-config alertmanager.yml` |
| Kea DHCP | `kea-dhcp4 -t /etc/kea/kea-dhcp4.conf` |
| Ansible | `ansible-playbook --syntax-check playbook.yaml` (lint avancé : `ansible-lint`) |
| Terraform / OpenTofu | `terraform validate` ou `tofu validate` |
| Helm chart | `helm lint ./chart` |
| Kustomize | `kustomize build <overlay>` (rendu hors cluster) |
| Docker Compose | `docker compose config` |
| Dockerfile | `hadolint Dockerfile` |
| Kubernetes (manifeste) | `kubectl apply --dry-run=server -f manifest.yaml` |
| Kubernetes (politique) | `kyverno apply <policy.yaml> --resource <res.yaml>` ou `gator test` (Gatekeeper) |

Prendre l'habitude de valider systématiquement avant de recharger un service évite les interruptions accidentelles. Certains services refusent de recharger une configuration invalide (Nginx, Apache), d'autres peuvent s'arrêter (BIND9 dans certains cas), et d'autres encore appliquent partiellement la configuration — ce qui est souvent pire qu'un échec franc.

### Versionning de la configuration

La totalité du répertoire `/etc` se prête naturellement au suivi de versions avec Git. L'outil `etckeeper`, disponible dans les dépôts Debian, automatise ce suivi en créant un commit à chaque installation ou mise à jour de paquet. Cette pratique est fortement recommandée : elle fournit un historique complet des modifications, facilite le retour arrière en cas de problème et documente les changements même lorsque l'administrateur oublie de le faire manuellement.

Pour les projets d'Infrastructure as Code, la configuration est par nature versionnée dans un dépôt Git : playbooks Ansible, fichiers Terraform, manifestes Kubernetes et charts Helm vivent dans le même workflow de gestion de code que le reste de l'infrastructure.

---

## Correspondance avec les modules de la formation

| Modules | Services et composants couverts |
|---------|-------------------------------|
| 1-2 | Système de base, locales, réseau, environnement de bureau |
| 3 | systemd, PAM, sudo, fstab, rsyslog, journald |
| 4 | APT, dpkg, sources.list, preferences |
| 5 | cron, timers systemd, scripts |
| 6 | SSH, nftables, ufw, WireGuard, LUKS |
| 7 | Apache, Nginx, Caddy, MariaDB, PostgreSQL, Samba, NFS |
| 8 | BIND9, Kea DHCP, Postfix, Dovecot, borgbackup, restic, HAProxy, Pacemaker |
| 9 | libvirt, QEMU/KVM, Vagrant |
| 10 | Docker daemon, Dockerfiles, Compose, Podman, Quadlet (intégration systemd), Incus |
| 11-12 | kubeadm, kubelet, manifestes K8s, Helm values (Helm 4 SSA depuis nov. 2025), Kustomize, etcd, CNI (Calico/Cilium/Flannel), Ingress Controllers (post-ingress-nginx) |
| 13 | Ansible (ansible.cfg, inventaire, playbooks), Terraform et OpenTofu (.tf, backends, .tfvars) |
| 14 | GitLab Runner, GitHub Actions runners, ArgoCD (et Argo Rollouts/Workflows/Events), Flux, Tekton (Pipelines, Chains) |
| 15 | Prometheus, Grafana (13.x), AlertManager, Loki, Tempo, Mimir, Grafana Alloy (ex-Promtail/Grafana Agent), Fluent Bit, Jaeger v2, OpenTelemetry Collector |
| 16 | AppArmor, sysctl, Vault/OpenBao, cert-manager, Sigstore (Cosign), OPA Gatekeeper, Kyverno, Sealed Secrets, SOPS, External Secrets Operator, Falco, Tetragon |
| 17 | CLI cloud (aws, gcloud, az), Istio (Ambient mode), Linkerd, Cilium Service Mesh, Ceph, MinIO/SeaweedFS/Garage/RustFS, Rook |
| 18 | K3s en edge, configuration Kubecost/OpenCost, profils Cilium/Hubble (réutilise B.1 §24-25) |
| 19 | Architectures de référence — combine les fichiers des modules précédents (poste développeur K8s, runbooks, manifestes Velero) |

---

## Comment utiliser cette annexe

**En situation de diagnostic** — Un service ne démarre pas ou se comporte de manière inattendue. La section B.1 permet de localiser immédiatement tous les fichiers de configuration impliqués. La section B.2 aide à comprendre la syntaxe et à repérer une éventuelle erreur. Le tableau de validation ci-dessus indique la commande à exécuter pour confirmer ou infirmer un problème de syntaxe.

**Lors d'un nouveau déploiement** — La section B.3 fournit des templates de configuration prêts à l'emploi pour les services les plus courants. L'administrateur part d'un modèle fonctionnel et l'adapte à son contexte, plutôt que de construire sa configuration de zéro.

**Pour l'automatisation** — Les fichiers de configuration documentés dans cette annexe sont les mêmes que ceux gérés par les modules Ansible `template`, `copy` et `lineinfile`, ou par les ressources Terraform de type `file`. La connaissance de leur emplacement et de leur syntaxe est un prérequis pour écrire des playbooks et des manifestes fiables.

**En préparation de certification** — Les examens CKA et CKS exigent de connaître l'emplacement des fichiers de configuration de Kubernetes sur les nœuds, les options de kubelet et les manifestes statiques du control plane. Cette annexe sert de support de révision pour ces aspects.

---

> **Note** — Les chemins indiqués dans cette annexe correspondent à l'installation par défaut des paquets Debian Stable (Bookworm / Trixie selon l'édition). Des installations depuis les sources ou via des gestionnaires de versions tiers peuvent utiliser des emplacements différents (typiquement sous `/usr/local/` ou `/opt/`). Les fichiers de configuration des services déployés dans des conteneurs ou sur Kubernetes suivent leurs propres conventions, documentées dans les sections correspondantes.

⏭️ [Localisation des fichiers importants par service](/annexes/B.1-localisation-fichiers.md)
