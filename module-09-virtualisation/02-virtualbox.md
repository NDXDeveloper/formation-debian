🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 9.2 VirtualBox

## Parcours 2 — Ingénieur Infrastructure & Conteneurs

**Module 9 : Virtualisation · Niveau : Avancé**

---

## Introduction

La section précédente (9.1) a couvert en profondeur KVM/QEMU/libvirt, la pile de virtualisation de référence pour les serveurs de production sous Debian. KVM est un hyperviseur intégré au noyau Linux, optimisé pour la performance et l'intégration système, piloté en ligne de commande ou via des API programmatiques.

**VirtualBox** occupe une niche différente. Développé à l'origine par Innotek, puis acquis par Sun Microsystems (2008) et enfin par Oracle (2010), VirtualBox est un hyperviseur de type 2 multiplateforme conçu avant tout pour la **simplicité d'utilisation sur le poste de travail**. Son interface graphique intuitive, sa portabilité entre systèmes d'exploitation hôtes (Linux, Windows, macOS) et son installation sans prérequis matériel complexe en font l'outil de choix pour le développement, la formation et les tests rapides.

Dans l'écosystème Debian, VirtualBox n'est pas un concurrent de KVM mais un **complément**. Là où KVM excelle en production serveur, VirtualBox brille sur le poste de travail : un développeur qui doit tester une application sur plusieurs OS, un étudiant qui découvre l'administration système, un formateur qui distribue des environnements pré-configurés à ses stagiaires.

---

## Positionnement dans le paysage de la virtualisation

### Un hyperviseur de type 2 multiplateforme

VirtualBox s'installe comme une application classique au-dessus du système d'exploitation hôte. Contrairement à KVM qui est un module noyau natif de Linux, VirtualBox fournit ses propres modules noyau (`vboxdrv`, `vboxnetflt`, `vboxnetadp`) qui sont compilés et chargés séparément. Cette architecture lui confère sa portabilité — le même VirtualBox fonctionne sur Linux, Windows et macOS — mais introduit une couche supplémentaire entre les VM et le matériel.

```
┌────────────────────────────────────────────────┐
│                    KVM                         │
│             (hyperviseur noyau)                │
│                                                │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │  Guest 1 │   │  Guest 2 │   │  Guest 3 │    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       └──────────────┼──────────────┘          │
│                      │                         │
│        ┌─────────────┴─────────────┐           │
│        │  Noyau Linux + KVM        │           │
│        │  (module noyau intégré)   │           │
│        └─────────────┬─────────────┘           │
│                      │                         │
│              Matériel (VT-x/AMD-V)             │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│                 VirtualBox                     │
│         (hyperviseur type 2 hébergé)           │
│                                                │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │  Guest 1 │   │  Guest 2 │   │  Guest 3 │    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       └──────────────┼──────────────┘          │
│                      │                         │
│        ┌─────────────┴─────────────┐           │
│        │  VirtualBox (application) │           │
│        │  + modules noyau vbox*    │           │
│        └─────────────┬─────────────┘           │
│                      │                         │
│        ┌─────────────┴─────────────┐           │
│        │    Système d'exploitation │           │
│        │    hôte (Debian, Win, mac)│           │
│        └─────────────┬─────────────┘           │
│                      │                         │
│              Matériel (VT-x/AMD-V)             │
└────────────────────────────────────────────────┘
```

VirtualBox utilise les extensions de virtualisation matérielle (VT-x/AMD-V) lorsqu'elles sont disponibles, ce qui lui permet d'atteindre des performances CPU respectables. Cependant, la couche d'émulation des périphériques et la gestion des I/O passent par l'application VirtualBox en espace utilisateur puis par l'OS hôte, ce qui introduit un overhead supérieur à celui de KVM pour les opérations d'entrée/sortie.

### Modèle de licence

VirtualBox est distribué sous un modèle dual :

**VirtualBox Base Package** (édition OSE — Open Source Edition, puis renommée). Le cœur de VirtualBox est distribué sous licence **GPLv3**. Il est librement utilisable, y compris en entreprise, et inclut l'ensemble des fonctionnalités de virtualisation de base : création et gestion de VM, snapshots, réseaux virtuels, partage de dossiers, interface graphique et ligne de commande.

**VirtualBox Extension Pack.** Un module complémentaire distribué sous la licence **PUEL** (*Personal Use and Evaluation License*) d'Oracle. Il ajoute des fonctionnalités avancées : support USB 2.0/3.0 (EHCI/xHCI), chiffrement des disques virtuels (AES-256), démarrage PXE avec carte Intel E1000, et Remote Desktop Protocol (VRDP) pour l'accès distant aux consoles VM. L'Extension Pack est gratuit pour un usage personnel et éducatif mais requiert une licence commerciale pour un usage en entreprise.

Cette distinction est importante pour un administrateur Debian : le paquet de base dans les dépôts est entièrement libre et suffisant pour la plupart des usages. L'Extension Pack n'est nécessaire que pour des fonctionnalités spécifiques.

---

## Fonctionnalités distinctives

VirtualBox se distingue de KVM/libvirt par plusieurs fonctionnalités orientées vers l'expérience utilisateur sur le poste de travail.

**Interface graphique native et unifiée.** VirtualBox fournit une interface graphique complète (VirtualBox Manager) intégrée à l'application, sans dépendance à un composant tiers. Contrairement à virt-manager (qui est un client graphique séparé se connectant au démon libvirt), l'interface VirtualBox et le moteur de virtualisation forment un tout cohérent. La création, la configuration et le lancement d'une VM se font en quelques clics.

**Guest Additions.** Un ensemble de pilotes et d'utilitaires installés dans le guest qui améliorent significativement l'intégration hôte-guest : redimensionnement automatique de l'écran du guest, accélération graphique 2D/3D, dossiers partagés entre l'hôte et le guest, copier-coller bidirectionnel, glisser-déposer de fichiers, synchronisation de l'horloge. Les Guest Additions jouent un rôle analogue aux pilotes virtio et au SPICE agent dans l'écosystème KVM, mais sous une forme plus intégrée et transparente pour l'utilisateur final.

**Portabilité des VM.** VirtualBox utilise le format OVF/OVA (*Open Virtualization Format*) pour l'export et l'import de VM. Un fichier `.ova` contient l'intégralité de la VM (définition matérielle + images disque) dans une archive unique, facilement transférable et importable sur n'importe quelle installation VirtualBox, quel que soit l'OS hôte. Cette portabilité est précieuse pour distribuer des environnements pré-configurés dans un contexte de formation ou de développement.

**Modes réseau variés avec configuration graphique.** NAT, bridge, réseau interne, réseau hôte uniquement (host-only), NAT Network — tous configurables via l'interface graphique sans toucher à la configuration réseau de l'hôte.

**Snapshots arborescents.** VirtualBox supporte nativement les snapshots avec une interface visuelle sous forme d'arbre, facilitant la gestion de multiples branches d'état.

**Ligne de commande complète (VBoxManage).** Malgré son orientation graphique, VirtualBox offre l'outil `VBoxManage` qui expose l'intégralité des fonctionnalités en ligne de commande, permettant l'automatisation et le scripting. C'est cet outil que Vagrant utilise pour piloter VirtualBox de manière programmatique (cf. section 9.3).

---

## Limites par rapport à KVM

Il est tout aussi important de comprendre les limites de VirtualBox pour éviter de l'utiliser dans des contextes où KVM est plus adapté.

**Performances I/O.** L'architecture de type 2 et l'absence de pilotes paravirtualisés aussi matures que virtio entraînent des performances d'entrée/sortie (disque et réseau) inférieures à celles de KVM. Les Guest Additions améliorent les performances graphiques et l'intégration, mais n'atteignent pas le niveau de virtio pour les I/O brutes.

**Scalabilité.** VirtualBox n'est pas conçu pour gérer des dizaines de VM simultanées en production. Il n'offre ni API de gestion centralisée de type libvirt, ni intégration avec des orchestrateurs cloud (OpenStack, Proxmox), ni migration à chaud entre hôtes.

**Sécurité et isolation.** Les modules noyau VirtualBox (`vboxdrv`) constituent une surface d'attaque supplémentaire et ne bénéficient pas du même niveau d'audit et de hardening que le module KVM intégré au noyau Linux mainline. Les profils AppArmor/SELinux pour VirtualBox sont moins matures que ceux de libvirt.

**Maintenance des modules noyau.** À chaque mise à jour du noyau Debian, les modules VirtualBox doivent être recompilés (via DKMS). Cette opération échoue parfois, notamment lors de changements majeurs dans les API internes du noyau, laissant temporairement VirtualBox non fonctionnel jusqu'à la publication d'une version compatible.

**Incompatibilité avec KVM.** Historiquement, VirtualBox et KVM ne peuvent pas fonctionner simultanément car ils entrent en conflit pour le contrôle des extensions de virtualisation matérielle (VT-x/AMD-V). Si le module `kvm` est chargé, VirtualBox 7.x échoue avec `VERR_VMX_IN_VMX_ROOT_MODE`, et il faut décharger les modules de l'un pour utiliser l'autre. Oracle développe depuis 2024 un backend KVM expérimental pour VirtualBox (compilé manuellement avec `--with-kvm --disable-kmods`) qui permettra à VirtualBox de fonctionner par-dessus KVM plutôt qu'en parallèle, et un patch noyau de fin 2025 ouvre la voie à une coexistence officielle. Mais sur les builds standards livrés par Oracle ou par Debian, le conflit reste d'actualité.

> **À noter sur Debian 13** : le paquet `virtualbox` lui-même n'est plus dans les dépôts Debian (ni `main`, ni `contrib`). Seuls subsistent `boinc-virtualbox` (dans `contrib`, métapaquet pour les projets BOINC qui s'appuient sur VirtualBox) et `virtualbox-guest-additions-iso` (dans `non-free`, ISO des Guest Additions à monter dans un guest). Pour installer VirtualBox sur Trixie, il faut désormais passer par le dépôt officiel Oracle (`download.virtualbox.org/virtualbox/debian`). Cette évolution sera détaillée en 9.2.1.

---

## Cas d'usage légitimes de VirtualBox sur Debian

Malgré ces limites, VirtualBox conserve des cas d'usage où il reste le choix le plus pertinent, même sur un système Debian.

**Développement multiplateforme.** Un développeur sous Debian qui doit tester son application sur Windows, macOS (dans les limites de la licence Apple) ou d'autres distributions Linux bénéficie de l'interface graphique simple de VirtualBox et de l'intégration hôte-guest (dossiers partagés, copier-coller).

**Formation et apprentissage.** La courbe d'apprentissage de VirtualBox est bien plus douce que celle de KVM/libvirt. Un étudiant peut créer sa première VM en quelques minutes sans connaissances préalables de la ligne de commande Linux.

**Environnements Vagrant.** VirtualBox est le provider par défaut de Vagrant (section 9.3). De nombreuses *Vagrant boxes* sont distribuées exclusivement au format VirtualBox. Bien que Vagrant supporte également libvirt, l'écosystème VirtualBox reste le plus large.

**Distribution d'environnements pré-configurés.** Le format OVA et la disponibilité de VirtualBox sur tous les OS en font le format de choix pour distribuer des VM préconfigurées à des équipes hétérogènes (certains sous Linux, d'autres sous Windows ou macOS).

**Situations où KVM n'est pas disponible.** Dans des environnements où le noyau Linux n'est pas l'hôte (poste de travail Windows ou macOS d'un administrateur qui gère des serveurs Debian), VirtualBox est la solution la plus directe pour exécuter des VM Debian localement.

---

## Ce que couvre cette section

Cette section 9.2 est volontairement plus concise que la section 9.1 consacrée à KVM. VirtualBox n'est pas l'outil de production de cette formation, mais un outil complémentaire dont la maîtrise reste utile. Les trois sous-sections couvrent :

**9.2.1 — Installation sur Debian et cas d'usage.** Détaille l'installation de VirtualBox sur Debian (depuis les dépôts Debian, depuis le dépôt Oracle, et compilation via DKMS), la gestion des modules noyau, l'installation de l'Extension Pack, et la création d'une première VM.

**9.2.2 — Configuration et intégration desktop.** Couvre l'installation des Guest Additions, les dossiers partagés, les modes d'affichage, la configuration réseau, les snapshots, et l'utilisation de VBoxManage en ligne de commande.

**9.2.3 — VirtualBox vs KVM : critères de choix.** Propose une grille de décision objective pour choisir entre VirtualBox et KVM selon le contexte, et décrit les scénarios de migration d'une solution vers l'autre.

⏭️ [Installation sur Debian et cas d'usage](/module-09-virtualisation/02.1-installation-cas-usage.md)
