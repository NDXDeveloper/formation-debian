🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 9.3 Vagrant et Packer

## Parcours 2 — Ingénieur Infrastructure & Conteneurs

**Module 9 : Virtualisation · Niveau : Avancé**

---

## Introduction

Les sections précédentes ont couvert deux hyperviseurs — KVM (9.1) et VirtualBox (9.2) — en se concentrant sur la création, la configuration et la gestion des machines virtuelles. Dans les deux cas, le processus de mise en place d'un environnement reste largement manuel : télécharger une ISO, lancer l'installation, répondre aux questions de l'installateur, configurer le réseau, installer les paquets nécessaires, ajuster la configuration. Ce processus prend du temps, n'est pas reproductible de manière fiable, et ne se prête pas à la collaboration ni au versionnement.

**Vagrant** et **Packer**, tous deux créés par HashiCorp, résolvent ce problème en apportant à la virtualisation les principes fondamentaux de l'Infrastructure as Code : déclarativité, reproductibilité, versionnement et automatisation.

**Vagrant** est un outil de gestion d'environnements de développement virtualisés. Il permet de décrire un environnement complet (VM, réseau, provisioning) dans un fichier texte — le `Vagrantfile` — et de le déployer en une seule commande (`vagrant up`). Vagrant ne remplace pas l'hyperviseur : il le pilote. Il s'appuie sur des **providers** (VirtualBox, libvirt/KVM, VMware, Hyper-V, Docker, cloud) pour créer et gérer les VM, et sur des **provisioners** (scripts shell, Ansible, Puppet, Chef) pour les configurer.

**Packer** est un outil de construction d'images machine. Là où Vagrant consomme des images pré-fabriquées (les *boxes*), Packer les crée. Il automatise l'intégralité du processus de construction d'une image — depuis l'installation de l'OS à partir d'une ISO jusqu'à la configuration finale — et produit des images identiques pour plusieurs plateformes simultanément (VirtualBox, KVM/QEMU, AWS AMI, Azure, GCP, Docker).

Ensemble, ces deux outils forment une chaîne cohérente :

```
                    Chaîne de production des environnements virtualisés

┌─────────────────────────────┐     ┌──────────────────────────────────┐
│          Packer             │     │            Vagrant               │
│                             │     │                                  │
│  ISO Debian                 │     │  Vagrantfile (déclaratif)        │
│       │                     │     │       │                          │
│       ▼                     │     │       ▼                          │
│  Template HCL/JSON          │     │  vagrant up                      │
│  (installation automatisée, │     │       │                          │
│   configuration, hardening) │     │       ▼                          │
│       │                     │     │  ┌──────────────┐                │
│       ▼                     │     │  │  Provider    │                │
│  ┌──────────┐               │     │  │  (VBox, KVM) │                │
│  │ Box      │───────────────┼────►│  └──────┬───────┘                │
│  │ Vagrant  │  publication  │     │         │                        │
│  └──────────┘               │     │         ▼                        │
│  ┌──────────┐               │     │  ┌──────────────┐                │
│  │ AMI AWS  │               │     │  │ Provisioner  │                │
│  └──────────┘               │     │  │ (Shell,      │                │
│  ┌──────────┐               │     │  │  Ansible...) │                │
│  │ Image    │               │     │  └──────┬───────┘                │
│  │ qcow2    │               │     │         │                        │
│  └──────────┘               │     │         ▼                        │
│                             │     │  Environnement prêt à l'emploi   │
└─────────────────────────────┘     └──────────────────────────────────┘
```

Packer construit les images de base (les fondations), Vagrant les instancie et les configure pour un usage spécifique (la maison construite sur les fondations). Cette séparation des responsabilités permet de maintenir des images de base optimisées et standardisées tout en offrant la flexibilité de personnalisation au niveau du projet.

---

## Pourquoi ces outils dans une formation Debian ?

L'introduction de Vagrant et Packer dans le module de virtualisation n'est pas anecdotique. Ces outils occupent une place charnière dans la progression de cette formation, pour plusieurs raisons.

**Transition vers l'Infrastructure as Code.** Vagrant et Packer introduisent le paradigme déclaratif appliqué à la virtualisation. Au lieu de documenter une procédure d'installation en 50 étapes ("cliquer ici, taper cela"), on décrit l'état souhaité dans un fichier texte versionné. C'est exactement le paradigme que l'on retrouvera avec Ansible et Terraform au module 13, avec les Dockerfiles au module 10, et avec les manifestes Kubernetes aux modules 11-12.

**Reproductibilité des environnements.** Le problème classique "ça fonctionne sur ma machine" est largement atténué lorsque chaque membre d'une équipe utilise le même Vagrantfile pour créer son environnement de développement. La VM résultante est identique, quel que soit le poste de travail, le système d'exploitation hôte, ou le moment de la création.

**Abstraction de l'hyperviseur.** Vagrant masque les différences entre VirtualBox, KVM et les autres providers derrière une interface unifiée. Un même Vagrantfile peut produire une VM VirtualBox sur le poste d'un développeur Windows et une VM KVM sur le poste d'un développeur Linux. Cette abstraction prépare la transition vers les conteneurs (module 10) où Docker joue un rôle d'abstraction similaire.

**Préparation aux images cloud.** Packer est l'outil standard pour construire les images machine (AMI, images GCE, images Azure) utilisées dans le cloud. Maîtriser Packer sur Debian prépare directement au module 17 sur les cloud providers. Les compétences sont transférables : un template Packer qui construit une image Debian pour VirtualBox peut être étendu pour produire simultanément une AMI AWS.

**Accélération des tests et de l'apprentissage.** Pour la suite de cette formation (conteneurs, Kubernetes, CI/CD), la capacité de créer rapidement des environnements multi-machines reproductibles est un prérequis pratique. Vagrant réduit cette opération à quelques secondes, là où la création manuelle de VM prend des dizaines de minutes.

---

## Positionnement dans l'écosystème HashiCorp

Vagrant et Packer font partie de l'écosystème d'outils HashiCorp, aux côtés de Terraform (provisioning d'infrastructure), Vault (gestion des secrets), Consul (service discovery) et Nomad (orchestration de workloads). Bien que chaque outil soit indépendant, ils sont conçus pour fonctionner ensemble :

```
Cycle de vie d'une infrastructure

  Construction       Provisioning        Configuration      Déploiement
  des images         de l'infra          des instances      des applications
                                                            
 ┌─────────┐       ┌───────────┐       ┌────────────┐      ┌───────────┐
 │  Packer │──────►│ Terraform │──────►│  Ansible   │─────►│  Nomad /  │
 │         │       │           │       │  (ou autre)│      │  K8s      │
 └─────────┘       └───────────┘       └────────────┘      └───────────┘
                                                            
 Images Debian      Instances VM        Configuration       Applications
 optimisées         ou cloud            logicielle          en production
```

Dans le cadre de cette formation, Packer et Vagrant sont les premiers maillons de cette chaîne. Terraform sera abordé au module 13, et Kubernetes aux modules 11-12.

### Modèle de licence

HashiCorp a annoncé en **août 2023** le passage de l'ensemble de ses outils (Vagrant, Packer, Terraform, Vault, Consul, Nomad) de la **MPL 2.0** (Mozilla Public License) à la **Business Source License (BSL) 1.1**, applicable aux versions futures.

**Vagrant** : passage à BSL 1.1 avec la version **2.4.0** (novembre 2023). Les versions ≤ 2.3.x restent sous MPL 2.0.

**Packer** : passage à BSL 1.1 avec la version **1.10.0** (fin 2023). Les versions ≤ 1.9.x restent sous MPL 2.0.

La BSL autorise tout usage non compétitif : développement, formation, usage interne en entreprise (y compris commercial). Elle interdit uniquement de créer un produit ou un service concurrent directement basé sur le code BSL-couvert. Après quatre ans, chaque version BSL bascule automatiquement en open source (Mozilla Public License 2.0 dans le cas HashiCorp).

> Conséquence pour Debian : **Debian Trixie livre Vagrant 2.3.7** dans `main` (la dernière version sous MPL 2.0, datée de juillet 2023). Les versions BSL ne seront pas packagées tant que la licence ne devient pas DFSG-compatible. Pour utiliser Vagrant 2.4+ ou Packer 1.10+, il faut passer par les binaires officiels HashiCorp (`https://releases.hashicorp.com/`) ou un dépôt tiers. La même contrainte s'applique à Terraform et aux autres outils HashiCorp.

---

## Vue d'ensemble de Vagrant

### Le concept central : le Vagrantfile

Le cœur de Vagrant est le **Vagrantfile** — un fichier Ruby déclaratif qui décrit l'intégralité d'un environnement virtualisé. Un exemple minimal :

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/trixie64"
  config.vm.hostname = "dev-server"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
  SHELL
end
```

Ce fichier, versionné dans Git aux côtés du code source d'un projet, suffit à n'importe quel membre de l'équipe pour recréer un environnement identique avec une seule commande : `vagrant up`.

### Le concept de box

Une **box** Vagrant est une image de VM pré-empaquetée, prête à être instanciée. Elle contient l'image disque d'un OS installé et préconfigurée, les métadonnées de configuration (RAM par défaut, provider cible), et éventuellement les Guest Additions (VirtualBox) ou les pilotes virtio (libvirt). Les boxes sont distribuées via le registre public **Vagrant Cloud / HashiCorp Cloud Platform** ([portal.cloud.hashicorp.com](https://portal.cloud.hashicorp.com/vagrant/discover)) ou via des registres privés.

> Statut des boxes Debian officielles en 2026 : la maintenance de la box officielle `debian/trixie64` a été interrompue à un moment donné (le mainteneur historique a cessé son activité fin 2025 sur fond de désaccord avec HashiCorp sur la licence et la plateforme). Selon le moment, la box officielle peut être indisponible ou en cours de reprise par un nouveau mainteneur. Les alternatives stables sont la box communautaire `generic/debian13` (maintenue par Roboxes), la construction d'une box maison avec Packer (objet de la sous-section 9.3.2), ou — pour les usages legacy — la box `debian/bookworm64` qui reste maintenue.

### Le cycle de vie Vagrant

```
vagrant up          Crée et démarre la VM (télécharge la box si nécessaire,
                    exécute le provisioning au premier lancement)

vagrant ssh         Ouvre une session SSH dans la VM

vagrant halt        Arrête la VM proprement (équivalent shutdown)

vagrant reload      Redémarre la VM (applique les changements de Vagrantfile)

vagrant provision   Ré-exécute les provisioners sans redémarrer

vagrant suspend     Suspend la VM (sauvegarde en mémoire)

vagrant resume      Reprend une VM suspendue

vagrant destroy     Supprime la VM et ses disques (la box reste en cache)

vagrant status      Affiche l'état de la VM
```

---

## Vue d'ensemble de Packer

### Le concept central : le template

Packer utilise un **template** (au format HCL2 — HashiCorp Configuration Language, ou JSON pour les versions antérieures) qui décrit le processus complet de construction d'une image machine. Un template contient trois éléments principaux.

Les **sources** (anciennement *builders*) définissent la plateforme cible et les paramètres de la VM temporaire utilisée pendant la construction : type d'hyperviseur, ISO d'installation, taille du disque, mémoire, configuration réseau.

Les **provisioners** configurent l'image pendant la construction : scripts shell, playbooks Ansible, configurations Puppet/Chef, copie de fichiers. Ils sont exécutés dans la VM temporaire après l'installation de l'OS.

Les **post-processors** transforment l'image produite après la construction : compression, conversion de format, empaquetage en box Vagrant, upload vers un registre ou un cloud provider.

```
Template Packer (HCL2)
│
├── source "qemu" "debian13"           ← VM temporaire QEMU/KVM
│   ├── iso_url = "debian-13-netinst"
│   ├── disk_size = "20G"
│   ├── preseed / cloud-init           ← Installation automatisée
│   └── ssh_username = "admin"
│
├── build {
│   ├── provisioner "shell" {          ← Configuration post-installation
│   │   scripts = ["update.sh", "hardening.sh"]
│   │   }
│   ├── provisioner "ansible" {
│   │   playbook = "configure.yml"
│   │   }
│   │
│   ├── post-processor "vagrant" {     ← Empaquetage en box Vagrant
│   │   output = "debian13.box"
│   │   }
│   └── post-processor "compress" {    ← Compression de l'image
│       }
│   }
```

### Le cycle de construction Packer

```
packer init .           Télécharge les plugins nécessaires

packer validate .       Valide la syntaxe du template

packer build .          Lance la construction complète :
                        1. Crée une VM temporaire
                        2. Démarre l'installation depuis l'ISO
                        3. Répond automatiquement aux questions (preseed/kickstart)
                        4. Attend la fin de l'installation
                        5. Se connecte en SSH à la VM
                        6. Exécute les provisioners
                        7. Arrête la VM
                        8. Exporte l'image
                        9. Applique les post-processors
                        10. Supprime la VM temporaire
```

Le résultat est une image disque prête à l'emploi, construite de manière 100 % automatisée et reproductible.

---

## Complémentarité Vagrant et Packer

Vagrant et Packer ne sont pas des alternatives — ils traitent des étapes différentes du cycle de vie d'un environnement virtualisé :

| Aspect | Packer | Vagrant |
|---|---|---|
| **Objectif** | Construire des images de base | Instancier et gérer des environnements |
| **Entrée** | ISO + template de construction | Box (image pré-fabriquée) + Vagrantfile |
| **Sortie** | Image machine (box, AMI, qcow2...) | VM opérationnelle et configurée |
| **Fréquence d'utilisation** | Ponctuellement (nouvelle version d'image) | Quotidiennement (par les développeurs) |
| **Exécution** | Pipeline CI/CD ou poste admin | Poste développeur |
| **Durée d'exécution** | 15-60 minutes (installation complète) | 1-5 minutes (instanciation d'une box) |
| **Persistance du résultat** | Image stockée et distribuée | VM locale, jetable et recréable |

Le workflow typique est le suivant. L'équipe infrastructure utilise Packer pour construire une box Debian de référence : OS installé, mis à jour, sécurisé, avec les outils de base. Cette box est publiée sur un registre interne. Les développeurs référencent cette box dans leur Vagrantfile et y ajoutent la configuration spécifique à leur projet (paquets applicatifs, bases de données de développement, configuration réseau). Chaque `vagrant up` instancie la box et applique le provisioning projet en quelques minutes.

Si Packer n'est pas utilisé, Vagrant consomme des boxes publiques depuis Vagrant Cloud. Si Vagrant n'est pas utilisé, Packer produit des images utilisables directement dans KVM (qcow2), VirtualBox (OVA) ou le cloud (AMI).

---

## Ce que couvre cette section

Cette section 9.3 est structurée en trois sous-sections progressives :

**9.3.1 — Vagrant : environnements de développement reproductibles.** Couvre l'installation de Vagrant sur Debian, la syntaxe du Vagrantfile, les providers (VirtualBox et libvirt), les provisioners, la gestion multi-machines, la configuration réseau et le partage de fichiers.

**9.3.2 — Packer : création d'images Debian personnalisées.** Couvre l'installation de Packer, la syntaxe des templates HCL2, la construction d'images pour QEMU/KVM et VirtualBox, l'installation automatisée de Debian via preseed, les provisioners, et les post-processors pour la production de boxes Vagrant et d'images cloud.

**9.3.3 — Intégration avec les différents hyperviseurs.** Explore les spécificités d'utilisation de Vagrant et Packer avec VirtualBox et KVM/libvirt, les stratégies de portabilité multi-provider, et l'intégration dans les workflows d'équipe et les pipelines CI/CD.

⏭️ [Vagrant : environnements de développement reproductibles](/module-09-virtualisation/03.1-vagrant.md)
