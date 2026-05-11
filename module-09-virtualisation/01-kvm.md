🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 9.1 Virtualisation système avec KVM

## Parcours 2 — Ingénieur Infrastructure & Conteneurs

**Module 9 : Virtualisation · Niveau : Avancé**

*Prérequis : Parcours 1 acquis ou expérience équivalente en administration Debian (modules 1 à 8)*

---

## Introduction

La virtualisation est une technologie fondamentale de l'infrastructure moderne. Elle permet d'exécuter plusieurs systèmes d'exploitation isolés sur une même machine physique, en partageant les ressources matérielles de manière contrôlée. Avant l'avènement des conteneurs et de Kubernetes — que nous aborderons dans les modules suivants — la virtualisation constituait déjà la pierre angulaire de la consolidation des serveurs, de l'isolation des environnements et de la flexibilité opérationnelle.

Sur Debian, la solution de virtualisation de référence est **KVM** (*Kernel-based Virtual Machine*). Intégré directement au noyau Linux depuis la version 2.6.20 (2007), KVM transforme le système hôte en un hyperviseur de type 1 capable de tirer parti des extensions matérielles de virtualisation des processeurs modernes (Intel VT-x et AMD-V). Couplé à **QEMU** pour l'émulation des périphériques et à **libvirt** pour l'orchestration et la gestion, KVM forme un écosystème complet, performant et entièrement libre.

---

## Pourquoi KVM sur Debian ?

Debian occupe une place particulière dans l'écosystème KVM pour plusieurs raisons :

**Intégration native et stabilité.** KVM est un module du noyau Linux. Sur Debian Stable, le noyau livré inclut nativement le support KVM, sans nécessiter de composant tiers ni de licence propriétaire. L'ensemble de la pile — KVM, QEMU, libvirt, virt-manager — est disponible dans les dépôts officiels `main`, ce qui garantit un suivi en termes de mises à jour de sécurité tout au long du cycle de vie de la distribution.

**Philosophie du logiciel libre.** Contrairement à des solutions comme VMware vSphere (propriétaire) ou Hyper-V (lié à l'écosystème Microsoft), la pile KVM/QEMU/libvirt est entièrement open source. Cela s'inscrit parfaitement dans la philosophie Debian et permet un contrôle total sur l'infrastructure, sans dépendance à un éditeur ni coût de licence.

**Performance proche du bare metal.** Grâce à l'accélération matérielle (VT-x/AMD-V) et aux pilotes paravirtualisés **virtio**, les machines virtuelles KVM atteignent des niveaux de performance très proches de l'exécution native, tant pour le calcul que pour les E/S réseau et disque.

**Écosystème riche et standardisé.** KVM s'appuie sur des standards ouverts et s'intègre avec un large éventail d'outils : libvirt offre une API unifiée utilisée aussi bien par des outils en ligne de commande (`virsh`) que par des interfaces graphiques (`virt-manager`) ou des plateformes d'orchestration cloud (OpenStack, Proxmox VE). Terraform et Ansible disposent également de providers et modules pour piloter des environnements KVM.

---

## Architecture de la pile KVM/QEMU/libvirt

La virtualisation avec KVM repose sur trois couches logicielles complémentaires qui fonctionnent en synergie :

```
┌──────────────────────────────────────────────────────┐
│                   Applications de gestion            │
│         virt-manager · virsh · cockpit-machines      │
├──────────────────────────────────────────────────────┤
│                        libvirt                       │
│          API de gestion · démon libvirtd             │
│     (réseau virtuel, stockage, cycle de vie VM)      │
├──────────────────────────────────────────────────────┤
│                         QEMU                         │
│     Émulation des périphériques · pilotes virtio     │
│          (disque, réseau, console, USB…)             │
├──────────────────────────────────────────────────────┤
│                     KVM (noyau Linux)                │
│        Module noyau · accélération matérielle        │
│              (VT-x / AMD-V · /dev/kvm)               │
├──────────────────────────────────────────────────────┤
│                   Matériel (CPU, RAM, I/O)           │
│          Extensions de virtualisation activées       │
└──────────────────────────────────────────────────────┘
```

**KVM** est le composant le plus bas de la pile. C'est un module du noyau Linux (`kvm`, `kvm_intel` ou `kvm_amd`) qui exploite les extensions de virtualisation matérielle du processeur. Il expose le device `/dev/kvm` et gère l'exécution des instructions CPU des machines virtuelles directement sur le processeur physique, sans traduction logicielle. KVM prend en charge la gestion de la mémoire virtuelle des guests via les technologies EPT (Intel) ou NPT (AMD), ce qui élimine le coût des *shadow page tables*.

**QEMU** (*Quick Emulator*) fonctionne en espace utilisateur et complète KVM en émulant les périphériques matériels dont chaque machine virtuelle a besoin : contrôleurs de disque, cartes réseau, contrôleurs USB, carte graphique, etc. Sans KVM, QEMU peut fonctionner en émulation logicielle pure (beaucoup plus lente). Combiné à KVM, QEMU délègue l'exécution des instructions CPU au matériel via `/dev/kvm` et ne conserve que le rôle d'émulation des périphériques. Les pilotes **virtio** permettent aux guests d'interagir avec QEMU via une interface paravirtualisée optimisée, bien plus performante que l'émulation de matériel réel.

**libvirt** est la couche de gestion et d'abstraction. Le démon `libvirtd` (ou `virtqemud` dans les versions récentes avec le modèle de démons modulaires) expose une API stable permettant de créer, démarrer, arrêter, migrer et superviser des machines virtuelles. libvirt gère également les ressources associées : réseaux virtuels (bridges, NAT), pools de stockage (répertoires, LVM, NFS, iSCSI) et interfaces réseau. Les machines virtuelles sont définies sous forme de fichiers XML déclaratifs, ce qui facilite leur versionnement et leur automatisation.

---

## Cas d'usage de KVM sur Debian

La virtualisation KVM sur Debian couvre un spectre large de besoins, tant en entreprise que dans un cadre personnel ou éducatif :

**Consolidation de serveurs.** Exécuter plusieurs serveurs virtuels sur un même serveur physique permet de mutualiser les ressources matérielles, de réduire les coûts d'exploitation et de simplifier la gestion du parc. Un serveur Debian avec KVM peut héberger simultanément des VM de production (serveurs web, bases de données), des VM d'infrastructure (DNS, DHCP, monitoring) et des VM de test.

**Environnements de développement et de test.** KVM permet de créer rapidement des environnements jetables reproduisant des configurations de production. Combiné aux snapshots, il offre la possibilité de revenir à un état antérieur en quelques secondes après un test destructif.

**Isolation de services.** Même si les conteneurs remplissent de plus en plus ce rôle, la virtualisation reste pertinente lorsqu'une isolation forte est requise — notamment pour des raisons de sécurité ou de conformité réglementaire. Chaque VM dispose de son propre noyau, ce qui crée une frontière de sécurité plus robuste qu'un conteneur partageant le noyau de l'hôte.

**Cloud privé et infrastructure programmable.** KVM est l'hyperviseur utilisé par OpenStack, Proxmox VE et de nombreuses plateformes cloud privées. Maîtriser KVM sur Debian constitue un prérequis pour construire ou opérer ces plateformes.

**Transition vers les conteneurs.** Dans le cadre de cette formation, la maîtrise de KVM est un jalon important avant d'aborder les conteneurs (module 10) et Kubernetes (modules 11-12). Comprendre la virtualisation système permet de mieux appréhender les différences architecturales avec les conteneurs et de faire des choix éclairés entre les deux approches.

---

## Prérequis matériels

Avant de mettre en œuvre KVM, il est essentiel de vérifier que le matériel supporte la virtualisation accélérée :

**Processeur avec extensions de virtualisation.** Intel VT-x ou AMD-V doivent être présents et activés dans le BIOS/UEFI. La commande suivante permet de vérifier leur disponibilité :

```bash
# Vérification du support matériel
grep -Ec '(vmx|svm)' /proc/cpuinfo
```

Un résultat supérieur à zéro indique que les extensions sont disponibles. `vmx` correspond à Intel VT-x et `svm` à AMD-V. Si le résultat est 0, il faut vérifier que la virtualisation est bien activée dans les paramètres du firmware (BIOS/UEFI).

**Mémoire vive suffisante.** Chaque machine virtuelle consomme la RAM qui lui est allouée. Pour un usage confortable avec plusieurs VM, un minimum de 8 Go de RAM est recommandé sur l'hôte, sachant que le système Debian hôte lui-même en consomme entre 500 Mo et 1 Go.

**Stockage.** Les images disque des VM peuvent être volumineuses. Un stockage SSD est fortement recommandé pour les performances d'E/S. Le format d'image **qcow2** (QEMU Copy-On-Write) permet l'allocation dynamique et ne consomme sur disque que l'espace réellement écrit par la VM.

**IOMMU (optionnel).** Pour le passthrough de périphériques PCI (GPU, carte réseau, contrôleur USB), Intel VT-d ou AMD-Vi doivent être activés. Ce sujet sera abordé dans la section consacrée à l'optimisation des performances (9.1.6).

---

## Ce que couvre cette section

Cette section 9.1 détaille l'ensemble des connaissances et compétences nécessaires pour déployer et exploiter KVM sur Debian. Elle est structurée en six sous-sections progressives :

**9.1.1 — Concepts de virtualisation.** Pose les bases théoriques en distinguant les hyperviseurs de type 1 et de type 2, la virtualisation complète et la paravirtualisation, ainsi que les mécanismes matériels sous-jacents.

**9.1.2 — KVM et QEMU sur Debian.** Couvre l'installation de la pile KVM/QEMU sur Debian, la vérification des prérequis, le chargement des modules noyau et la création d'une première machine virtuelle en ligne de commande.

**9.1.3 — libvirt et virt-manager.** Présente la couche de gestion libvirt, son démon, la commande `virsh`, ainsi que l'interface graphique `virt-manager` pour l'administration visuelle des VM.

**9.1.4 — Gestion des machines virtuelles.** Approfondit les opérations courantes : création, clonage, snapshots, migration à chaud et à froid, import/export de VM.

**9.1.5 — Réseaux virtuels et bridges avancés.** Explore la configuration réseau des VM : réseau NAT par défaut, bridges pour l'accès direct au réseau physique, VLANs virtuels et topologies avancées.

**9.1.6 — Optimisation des performances.** Traite des techniques d'optimisation : pilotes virtio, hugepages, CPU pinning, I/O tuning, passthrough PCI/GPU et bonnes pratiques de dimensionnement.

---

## Positionnement dans le parcours

Cette section s'inscrit dans le **Parcours 2 — Ingénieur Infrastructure & Conteneurs**. Elle fait le lien entre les compétences d'administration système acquises dans le Parcours 1 et les technologies de conteneurisation qui suivront :

```
Parcours 1 (Modules 1-8)           Parcours 2 (Modules 9-13)  
Administration système Debian       Infrastructure & Conteneurs  
          │                                   │
          ▼                                   │
   ┌───────────────┐                          │
   │  Module 9     │◄─────── Vous êtes ici    │
   │ Virtualisation│                          │
   │   (KVM)       │                          │
   └──────┬────────┘                          │
          │                                   │
          ▼                                   │
   ┌───────────────┐                          │
   │  Module 10    │                          │
   │ Conteneurs    │                          │
   │(Docker/Podman)│                          │
   └──────┬────────┘                          │
          │                                   │
          ▼                                   │
   ┌───────────────┐                          │
   │  Module 11    │                          │
   │  Kubernetes   │                          │
   │ Fondamentaux  │                          │
   └───────────────┘                          │
```

La compréhension de la virtualisation système est essentielle pour appréhender ce qui distingue une machine virtuelle d'un conteneur, pour évaluer quand l'une ou l'autre approche est la plus adaptée, et pour concevoir des architectures hybrides combinant VM et conteneurs — un scénario très courant en production.

⏭️ [Concepts de virtualisation (type 1, type 2, paravirtualisation)](/module-09-virtualisation/01.1-concepts-virtualisation.md)
