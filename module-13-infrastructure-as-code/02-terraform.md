🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 13.2 Terraform

## Introduction

La section 13.1 a couvert Ansible, un outil qui excelle dans la **gestion de configuration** : installer des paquets, déployer des fichiers, configurer des services, orchestrer des opérations sur des machines existantes. Mais avant de configurer une machine, encore faut-il qu'elle existe. Qui crée les machines virtuelles, les réseaux, les volumes de stockage, les entrées DNS, les buckets de stockage objet, les clusters Kubernetes managés ? Dans une approche manuelle, un administrateur clique dans une console de virtualisation ou un portail cloud. Dans une approche Infrastructure as Code, **Terraform** prend en charge ce rôle.

Terraform est un outil de **provisionnement d'infrastructure** développé par HashiCorp, publié en 2014 et devenu le standard de facto pour la gestion déclarative des ressources d'infrastructure. Il permet de décrire dans des fichiers de code l'ensemble des ressources qui composent une infrastructure — machines virtuelles, réseaux, pare-feu, bases de données, certificats, enregistrements DNS — puis de créer, modifier et détruire ces ressources de manière contrôlée, reproductible et versionnée.

Là où Ansible pousse une configuration vers des machines existantes (modèle push déclaratif avec ordre d'exécution explicite), Terraform compare un état souhaité (le code) avec un état réel (le fichier d'état) et calcule les opérations nécessaires pour converger (modèle purement déclaratif avec plan d'exécution). Cette différence fondamentale d'approche est la clé de leur complémentarité, explorée en détail dans la section 13.3.

---

## Pourquoi Terraform dans une formation Debian

Une formation centrée sur Debian pourrait sembler éloignée des préoccupations de Terraform, souvent associé aux clouds publics (AWS, GCP, Azure). En réalité, Terraform est pertinent à chaque niveau de l'infrastructure Debian.

**Environnements on-premise.** Terraform dispose de providers pour libvirt/KVM (cf. Module 9), permettant de provisionner des machines virtuelles Debian sur des hyperviseurs locaux avec la même rigueur déclarative que dans le cloud. Un fichier Terraform peut décrire un cluster de VMs Debian, leurs réseaux virtuels, leurs volumes de stockage, et les créer ou les détruire en une commande.

**Clusters Kubernetes.** Terraform peut provisionner l'infrastructure sous-jacente d'un cluster Kubernetes : les nœuds Debian (VMs ou instances cloud), le load balancer du control plane, les réseaux, les règles de pare-feu. Il peut également gérer des ressources Kubernetes elles-mêmes via le provider Kubernetes, bien que cette approche soit moins courante que Helm ou ArgoCD pour les workloads applicatifs.

**Cloud hybride.** De nombreuses infrastructures Debian s'étendent vers le cloud : des serveurs Debian on-premise cohabitent avec des instances Debian sur AWS (AMI Debian officielles), Google Cloud (GCE images Debian) ou Azure. Terraform unifie la gestion de ces environnements hétérogènes dans un seul langage et un seul workflow, sujet couvert dans le Module 17.

**Services périphériques.** Même dans une infrastructure purement on-premise, Terraform gère les services périphériques : enregistrements DNS externes (Cloudflare, Route53), certificats TLS (Let's Encrypt via ACME), configuration de CDN, et alertes de monitoring.

L'association Terraform + Ansible constitue le pattern IaC le plus répandu : Terraform crée les ressources, Ansible les configure. Cette complémentarité, présentée en section 13.3, est le fil directeur de l'ensemble du Module 13.

---

## Le langage HCL

Terraform utilise **HCL** (HashiCorp Configuration Language), un langage déclaratif conçu spécifiquement pour décrire l'infrastructure. HCL n'est pas un langage de programmation à usage général : il est délibérément limité pour rester lisible, prévisible et auditable. Cette contrainte est un choix de conception, pas une limitation accidentelle.

HCL se situe à mi-chemin entre un format de données (comme YAML ou JSON) et un langage de programmation. Il supporte les variables, les expressions, les fonctions, les boucles et les conditions, mais ne permet pas les effets de bord, l'exécution de commandes arbitraires ou la logique procédurale complexe. Cette restriction garantit que la lecture d'un fichier Terraform suffit à comprendre l'infrastructure qu'il décrit, sans devoir tracer l'exécution d'un programme.

Voici un aperçu de la syntaxe HCL pour donner une première intuition avant l'étude détaillée en section 13.2.1 :

```hcl
# Déclarer une machine virtuelle Debian sur libvirt/KVM
resource "libvirt_domain" "webserver" {
  name   = "web01"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.debian_root.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}
```

Ce bloc de code décrit **ce que** l'infrastructure doit être (une VM nommée "web01" avec 2 Go de RAM et 2 vCPU), et non **comment** la créer. Terraform se charge de traduire cette description en appels API vers l'hyperviseur libvirt.

---

## Le modèle déclaratif et le fichier d'état

### Déclaratif vs impératif

La différence entre l'approche de Terraform et celle d'un script impératif (Bash, Python, ou même certaines utilisations d'Ansible) est fondamentale.

Un script impératif décrit une **séquence d'actions** : « créer une VM, puis créer un réseau, puis attacher la VM au réseau ». Si la VM existe déjà, le script échoue ou crée un doublon. Si le réseau a changé, le script ne le détecte pas. Chaque exécution nécessite une logique de vérification manuelle pour être idempotente.

Terraform décrit un **état final souhaité** : « il doit exister une VM avec ces caractéristiques, connectée à ce réseau ». Terraform compare cette description avec l'état réel de l'infrastructure (stocké dans le fichier d'état), calcule les différences, et génère un plan d'exécution qui ne contient que les opérations nécessaires. Si la VM existe déjà avec les bonnes caractéristiques, rien n'est fait. Si elle existe mais avec une mauvaise taille de mémoire, Terraform propose de la modifier (ou de la recréer si la modification n'est pas possible in-place).

### Le fichier d'état (state)

Le fichier d'état (`terraform.tfstate`) est un fichier JSON qui enregistre la correspondance entre les ressources décrites dans le code et les ressources réelles existantes dans l'infrastructure. C'est le composant le plus critique et le plus spécifique de Terraform.

Lorsque Terraform crée une VM, il enregistre dans le state l'identifiant unique de cette VM (son UUID libvirt, son instance ID AWS, etc.), ses attributs actuels (adresse IP, taille mémoire, état) et sa correspondance avec le bloc `resource` du code. Lors de l'exécution suivante, Terraform relit le state, interroge l'API du provider pour connaître l'état réel de la VM, compare avec le code, et détermine les actions à entreprendre.

Sans le state, Terraform ne saurait pas quelles ressources il gère. Il pourrait créer des doublons, tenter de supprimer des ressources qu'il n'a pas créées, ou perdre le suivi de ressources existantes. La gestion du state — son stockage, son verrouillage, son partage entre les membres de l'équipe — est un sujet central de la section 13.2.3.

### Le plan d'exécution

Avant d'effectuer toute modification, Terraform génère un **plan** qui détaille les opérations prévues. Ce plan est l'équivalent d'un `--check --diff` dans Ansible, mais avec une granularité et une fiabilité supérieures car Terraform connaît l'état complet de l'infrastructure via le state.

Le plan indique pour chaque ressource si elle sera créée (`+`), modifiée (`~`), détruite (`-`), ou remplacée (`-/+`, destruction puis recréation). L'administrateur peut examiner ce plan, le valider, puis l'appliquer. En production, ce workflow en deux étapes (`plan` puis `apply`) est un filet de sécurité indispensable.

---

## Écosystème et évolutions récentes

### Terraform et OpenTofu

En août 2023, HashiCorp a modifié la licence de Terraform, passant de la Mozilla Public License 2.0 (MPL) à la Business Source License (BSL). Ce changement a suscité une réaction de la communauté open source et a conduit à la création d'**OpenTofu**, un fork open source de Terraform maintenu par la Linux Foundation sous licence MPL 2.0.

OpenTofu est fonctionnellement compatible avec Terraform : les fichiers de configuration HCL, les providers et les modules existants fonctionnent sans modification. Les commandes CLI sont identiques (en remplaçant `terraform` par `tofu`). Pour les utilisateurs, le choix entre Terraform et OpenTofu dépend principalement de la politique de l'organisation vis-à-vis des licences logicielles.

Dans le cadre de cette formation, les concepts, la syntaxe et les pratiques enseignés sont valables pour les deux projets. Les exemples utilisent la commande `terraform` par convention, mais sont directement transposables à `tofu`. Les éventuelles divergences fonctionnelles entre les deux projets, apparues depuis le fork, sont signalées lorsqu'elles existent.

### Providers et registre

La force de Terraform réside dans son écosystème de **providers** — des plugins qui interfacent Terraform avec les API des fournisseurs d'infrastructure. Le Terraform Registry (registry.terraform.io) héberge des milliers de providers couvrant les clouds publics (AWS, GCP, Azure, OVH, Hetzner, Scaleway), les plateformes de virtualisation (libvirt, VMware, Proxmox), les services réseau (Cloudflare, Fastly), les bases de données, les outils de monitoring, et bien d'autres.

Chaque provider est développé et maintenu indépendamment, avec son propre cycle de release. Les providers des clouds majeurs sont maintenus par les fournisseurs eux-mêmes ou par HashiCorp, tandis que les providers communautaires sont maintenus par des contributeurs indépendants.

---

## Terraform vs Ansible : philosophies complémentaires

Bien que Terraform et Ansible soient parfois présentés comme des alternatives, ils occupent des niches distinctes dans le paysage IaC. Leur compréhension comparée éclaire le choix de l'outil approprié pour chaque situation.

| Aspect | Terraform | Ansible |
|---|---|---|
| Domaine principal | Provisionnement d'infrastructure | Configuration et orchestration |
| Modèle | Purement déclaratif | Déclaratif avec ordre d'exécution explicite |
| Langage | HCL | YAML |
| État | Fichier d'état explicite (stateful) | Sans état (stateless) |
| Agent | Aucun (appels API directs) | Aucun (SSH) |
| Cible | APIs de fournisseurs d'infra | Machines existantes (via SSH) |
| Idempotence | Garantie par le state | Garantie par les modules |
| Cycle de vie | Créer, modifier, détruire | Configurer, maintenir |
| Rollback | Implicite (appliquer l'ancien code) | Explicite (playbook de rollback) |
| Parallélisme | Graphe de dépendances automatique | Séquentiel avec forks |
| Gestion des dépendances | Automatique (graphe de ressources) | Manuelle (ordre des tâches) |
| Secret management | Variables sensibles, intégration Vault | Ansible Vault, intégration Vault |

Le pattern d'utilisation combinée le plus courant, détaillé en section 13.3, suit un flux en deux phases : Terraform crée l'infrastructure (VMs, réseaux, DNS), puis Ansible configure les systèmes créés (paquets, services, applications). Le state Terraform fournit les adresses IP et les identifiants des machines créées, qui alimentent l'inventaire dynamique Ansible.

---

## Ce que couvre cette section

La section 13.2 est structurée en cinq sous-sections progressives.

La sous-section **13.2.1 — Concepts (providers, ressources, data sources)** présente les concepts fondamentaux de Terraform et la syntaxe HCL en détail. Elle couvre les blocs de configuration (provider, resource, data, variable, output, locals), le système de types, les expressions et les fonctions intégrées.

La sous-section **13.2.2 — Installation sur Debian et premiers déploiements** couvre l'installation de Terraform sur un poste Debian, la configuration initiale, et la création de premières ressources avec le provider libvirt pour provisionner des VMs Debian localement.

La sous-section **13.2.3 — État (state) et backends** approfondit le fichier d'état, les backends de stockage distant (S3, Consul, PostgreSQL), le verrouillage, le partage en équipe et les opérations de maintenance du state (import, move, taint).

La sous-section **13.2.4 — Modules, workspaces et bonnes pratiques** couvre la structuration du code Terraform en modules réutilisables, la gestion multi-environnement avec les workspaces, les conventions de nommage et les bonnes pratiques de structuration de projet.

La sous-section **13.2.5 — Terraform pour multi-cloud et on-premise** explore l'utilisation de Terraform dans des environnements hybrides combinant infrastructure on-premise (libvirt/KVM) et cloud (AWS, GCP, Hetzner), avec des patterns pour l'abstraction multi-provider et l'intégration avec l'écosystème Debian.

---

## Prérequis

Pour aborder cette section dans les meilleures conditions, les connaissances et compétences suivantes sont attendues :

- Administration système Debian (Parcours 1) : les ressources créées par Terraform sont des systèmes Debian qu'il faudra comprendre et diagnostiquer.
- Virtualisation KVM/libvirt (Module 9) : les premiers exemples utilisent le provider libvirt pour provisionner des VMs Debian localement, sans nécessiter de compte cloud.
- Concepts réseau (Module 6) : adressage IP, DNS, sous-réseaux, routage — nécessaires pour définir l'infrastructure réseau dans Terraform.
- Notions de conteneurs et Kubernetes (Modules 10-12) : pour les exemples d'intégration Terraform-Kubernetes.
- Ansible (section 13.1) : la complémentarité Terraform-Ansible est un fil directeur de cette section.
- Familiarité avec Git : le code Terraform est versionné, les pratiques de branching et de revue de code s'appliquent directement.

Aucune expérience préalable avec un cloud provider n'est requise. Les exemples initiaux utilisent des ressources locales avec libvirt avant d'aborder les clouds publics dans la section 13.2.5.

---

## Conventions utilisées dans cette section

Les commandes Terraform sont exécutées depuis un poste Debian servant de station de travail IaC. Le prompt `iac$` identifie ces commandes.

Les fichiers de configuration Terraform utilisent l'extension `.tf` et sont rédigés en HCL. Par convention, un projet Terraform minimal contient au moins les fichiers suivants : `main.tf` pour les ressources principales, `variables.tf` pour les déclarations de variables, `outputs.tf` pour les sorties, `providers.tf` (ou `versions.tf`) pour la configuration des providers et les contraintes de version.

L'environnement de référence repose sur **Debian 13 "Trixie"**, **Terraform 1.13+** (ou OpenTofu 1.10+) et le provider **libvirt 0.8+** pour les exemples on-premise. Les exemples cloud utilisent les providers AWS, Google Cloud ou Hetzner Cloud selon le contexte.

⏭️ [Concepts (providers, ressources, data sources)](/module-13-infrastructure-as-code/02.1-concepts-providers-ressources.md)
