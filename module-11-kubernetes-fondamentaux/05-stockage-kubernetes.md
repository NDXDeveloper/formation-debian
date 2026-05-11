🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 11.5 Stockage Kubernetes

## Introduction

Les sections précédentes ont couvert le déploiement des applications (11.3) et leur mise en réseau (11.4). Cette dernière section du Module 11 traite le troisième pilier fondamental : le **stockage**.

Les conteneurs sont par nature **éphémères** : le système de fichiers d'un conteneur est détruit lorsque le conteneur s'arrête, et toutes les données qu'il contenait disparaissent. Pour un serveur web sans état qui sert des fichiers statiques embarqués dans l'image, ce comportement est parfaitement adapté. Mais pour une base de données, un système de fichiers partagé, un cache sur disque ou un répertoire d'upload utilisateur, la persistance des données au-delà du cycle de vie du conteneur — et même du Pod — est indispensable.

Kubernetes aborde le stockage avec le même modèle déclaratif que le reste de la plateforme : l'opérateur déclare un besoin de stockage (volume, taille, mode d'accès) et Kubernetes se charge de le satisfaire en provisionnant, attachant et montant les volumes nécessaires.

---

## Le problème : données éphémères dans un monde dynamique

Le cycle de vie des données dans Kubernetes présente des défis spécifiques :

**Éphémérité des conteneurs** — Le système de fichiers d'un conteneur (couche lecture-écriture de l'overlay FS) est détruit à chaque redémarrage. Un conteneur qui crashe et est redémarré par le kubelet perd toutes les données écrites dans son filesystem. C'est le comportement intentionnel des conteneurs — l'immuabilité garantit la reproductibilité — mais c'est incompatible avec les workloads stateful.

**Mobilité des Pods** — Un Pod peut être replanifié sur un nœud différent à tout moment (éviction, rolling update, panne de nœud). Les données stockées sur le disque local du nœud original ne sont pas accessibles depuis le nouveau nœud. Le stockage doit être **découplé** du nœud pour survivre aux replanifications.

**Partage de données** — Certaines architectures nécessitent que plusieurs Pods accèdent simultanément aux mêmes données (lecture seule ou lecture-écriture). Le stockage doit supporter des modes d'accès concurrents.

**Diversité des backends** — Les besoins de stockage varient considérablement : disques locaux haute performance pour les bases de données, stockage réseau partagé pour les fichiers, stockage objet pour les archives, systèmes de fichiers distribués pour les workloads big data. Kubernetes doit abstraire cette diversité derrière une interface uniforme.

---

## Types de volumes dans Kubernetes

Kubernetes distingue deux grandes catégories de volumes :

### Volumes éphémères

Les volumes éphémères ont le même cycle de vie que le Pod : ils sont créés à la création du Pod et détruits à sa suppression. Ils ne survivent pas au rescheduling.

**`emptyDir`** — Un répertoire vide créé sur le nœud lors de la création du Pod. Son contenu est préservé entre les redémarrages de conteneurs au sein du même Pod (un crash de conteneur ne détruit pas le volume), mais il est supprimé lorsque le Pod est supprimé ou replanifié. C'est le type de volume le plus simple, utilisé principalement pour le partage de données temporaires entre conteneurs d'un même Pod (pattern sidecar) ou comme espace de travail temporaire.

```yaml
volumes:
  - name: temp-storage
    emptyDir:
      sizeLimit: 1Gi          # Limite optionnelle
  - name: cache
    emptyDir:
      medium: Memory           # Stocké en RAM (tmpfs) pour la performance
```

**`configMap`** et **`secret`** — Volumes qui projettent le contenu d'un ConfigMap ou d'un Secret comme des fichiers dans le conteneur. Détaillés dans le sous-chapitre 11.3.3.

**`downwardAPI`** — Volume qui expose les métadonnées du Pod (labels, annotations, ressources) comme des fichiers.

**`projected`** — Volume qui combine plusieurs sources (ConfigMaps, Secrets, Downward API, ServiceAccount tokens) dans un seul point de montage.

### Volumes persistants

Les volumes persistants ont un cycle de vie **indépendant du Pod**. Ils survivent à la suppression du Pod, au rescheduling et même à la suppression du Deployment. Ils sont gérés via le mécanisme **PersistentVolume / PersistentVolumeClaim** (PV/PVC), qui sépare la provision du stockage de son utilisation.

C'est cette catégorie qui est au cœur de cette section et qui sera développée dans les sous-chapitres suivants.

---

## Le modèle PV / PVC / StorageClass

Kubernetes utilise un modèle à trois niveaux pour la gestion du stockage persistant :

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ADMINISTRATEUR CLUSTER                   DÉVELOPPEUR            │
│                                                                  │
│  ┌──────────────────────┐                                        │
│  │   StorageClass       │  "Quels types de stockage sont         │
│  │                      │   disponibles dans ce cluster ?"       │
│  │  - provisioner       │                                        │
│  │  - parameters        │  Ex: ssd-fast, hdd-standard,           │
│  │  - reclaimPolicy     │      nfs-shared                        │
│  └──────────┬───────────┘                                        │
│             │ provisionne                                        │
│             ▼                                                    │
│  ┌──────────────────────┐    ┌──────────────────────┐            │
│  │  PersistentVolume    │◄───│ PersistentVolumeClaim│            │
│  │  (PV)                │    │ (PVC)                │            │
│  │                      │    │                      │            │
│  │  "Voici un volume    │    │ "J'ai besoin de      │            │
│  │   de stockage réel   │    │  10 Gi en ReadWrite  │            │
│  │   avec ses specs"    │    │  avec la classe      │            │
│  │                      │    │  ssd-fast"           │            │
│  │  - capacity: 10Gi    │    │                      │            │
│  │  - accessModes: RWO  │    │  - requests: 10Gi    │            │
│  │  - storageClassName  │    │  - accessModes: RWO  │            │
│  │  - nfs/iscsi/ceph/...│    │  - storageClassName  │            │
│  └──────────┬───────────┘    └──────────┬───────────┘            │
│             │                           │                        │
│             │         binding           │                        │
│             └───────────┬───────────────┘                        │
│                         │                                        │
│                         ▼                                        │
│             ┌──────────────────────┐                             │
│             │   Pod                │                             │
│             │                      │                             │
│             │  volumeMounts:       │                             │
│             │    - mountPath: /data│                             │
│             │      name: storage   │                             │
│             │  volumes:            │                             │
│             │    - name: storage   │                             │
│             │      pvc:            │                             │
│             │        claimName: .. │                             │
│             └──────────────────────┘                             │
└──────────────────────────────────────────────────────────────────┘
```

**StorageClass** — Définie par l'administrateur du cluster. Elle décrit un **type de stockage** disponible (SSD rapide, HDD standard, NFS partagé) et le mécanisme de provisionnement associé. C'est une ressource cluster-wide. Un cluster peut avoir plusieurs StorageClasses, chacune correspondant à un backend de stockage différent.

**PersistentVolume (PV)** — Représente un **volume de stockage réel** dans l'infrastructure (un disque attaché, un export NFS, un volume Ceph, un EBS AWS). Le PV est une ressource cluster-wide qui décrit la capacité, les modes d'accès et les paramètres techniques du volume. Il peut être provisionné **statiquement** (créé manuellement par l'administrateur) ou **dynamiquement** (créé automatiquement par un provisioner en réponse à un PVC).

**PersistentVolumeClaim (PVC)** — Une **demande de stockage** émise par un utilisateur ou un Deployment. Le PVC est une ressource namespacée qui spécifie la taille souhaitée, les modes d'accès et la StorageClass. Kubernetes cherche un PV qui satisfait le PVC et les lie ensemble (*binding*). Le Pod référence ensuite le PVC comme volume.

Ce modèle à trois niveaux sépare les responsabilités :

- L'**administrateur du cluster** configure les StorageClasses et éventuellement provisionne les PV statiques.
- Le **développeur** crée des PVC pour déclarer ses besoins de stockage, sans se soucier des détails d'implémentation.
- Le **Pod** monte le PVC comme un volume, sans connaître le backend de stockage.

---

## Modes d'accès

Les volumes persistants supportent trois modes d'accès, qui déterminent combien de nœuds peuvent monter le volume simultanément :

| Mode | Abréviation | Description |
|------|-------------|-------------|
| ReadWriteOnce | RWO | Le volume peut être monté en lecture-écriture par **un seul nœud** |
| ReadOnlyMany | ROX | Le volume peut être monté en lecture seule par **plusieurs nœuds** |
| ReadWriteMany | RWX | Le volume peut être monté en lecture-écriture par **plusieurs nœuds** |
| ReadWriteOncePod | RWOP | Le volume peut être monté en lecture-écriture par **un seul Pod** (K8s 1.29+) |

La disponibilité de chaque mode dépend du backend de stockage :

| Backend | RWO | ROX | RWX | RWOP |
|---------|-----|-----|-----|------|
| Disques locaux (hostPath, local) | ✓ | ✗ | ✗ | ✓ |
| Disques cloud (EBS, GCE PD, Azure Disk) | ✓ | ✗ | ✗ | ✓ |
| NFS | ✓ | ✓ | ✓ | ✗ |
| CephFS | ✓ | ✓ | ✓ | ✓ |
| Ceph RBD | ✓ | ✓ | ✗ | ✓ |
| Longhorn | ✓ | ✓ | ✓ | ✓ |

Le mode **RWO** est le plus courant et suffit pour la plupart des bases de données (un seul Pod écrit à la fois). Le mode **RWX** est nécessaire lorsque plusieurs Pods doivent écrire sur le même volume (par exemple, un répertoire d'upload partagé entre plusieurs réplicas d'une application web). Le mode RWX est plus complexe à implémenter et nécessite un système de fichiers réseau (NFS, CephFS, GlusterFS).

---

## Stockage sur Debian on-premise

Dans un cluster Kubernetes déployé sur des serveurs Debian physiques ou virtuels (sans cloud provider), les options de stockage sont différentes de celles d'un cluster cloud :

**Stockage local** — Les disques des serveurs Debian eux-mêmes. Le type `hostPath` (déconseillé en production) ou le type `local` (avec affinité de nœud) permettent d'utiliser le stockage local. La solution **local-path-provisioner** (incluse dans K3s) automatise le provisionnement de volumes locaux.

**NFS** — Un serveur NFS Debian (configuré selon le Module 7, section 7.4.2) peut servir de backend de stockage partagé. Le driver CSI NFS permet le provisionnement dynamique de volumes NFS.

**Stockage distribué** — Les solutions comme **Ceph** (via Rook), **Longhorn** (SUSE/Rancher) ou **OpenEBS** fournissent un stockage distribué résilient en utilisant les disques locaux de chaque nœud. Ces solutions sont traitées dans le Module 17 (section 17.3).

**iSCSI** — Les baies de stockage accessibles via iSCSI peuvent être utilisées comme backends PV.

---

## Provisionnement statique vs dynamique

Deux modèles de provisionnement coexistent :

**Provisionnement statique** — L'administrateur crée manuellement les PV (par exemple, un volume NFS de 100 Go). Lorsqu'un PVC est créé, Kubernetes cherche un PV existant qui satisfait la demande (taille suffisante, mode d'accès compatible, StorageClass correspondante) et les lie. Si aucun PV ne correspond, le PVC reste en état `Pending`.

**Provisionnement dynamique** — Lorsqu'un PVC référence une StorageClass avec un provisioner configuré, Kubernetes crée automatiquement le PV correspondant. Le provisioner (un driver CSI ou un contrôleur intégré) interagit avec le backend de stockage pour créer le volume réel (disque cloud, export NFS, volume Ceph). C'est l'approche recommandée en production car elle élimine l'intervention manuelle et s'adapte à la demande.

Le provisionnement dynamique est ce qui rend le modèle PV/PVC véritablement déclaratif : le développeur déclare « j'ai besoin de 10 Gi de stockage SSD » et Kubernetes se charge de le provisionner, de l'attacher et de le monter, sans intervention humaine.

---

## Ce que vous allez apprendre

Cette section 11.5 est découpée en trois sous-chapitres :

**11.5.1 — Persistent Volumes et Persistent Volume Claims** : le mécanisme central du stockage persistant dans Kubernetes. Création de PV statiques, création de PVC, binding, cycle de vie (provisionnement → binding → utilisation → réclamation), politiques de réclamation (Retain, Delete, Recycle), montage dans les Pods.

**11.5.2 — StorageClasses et provisionnement dynamique** : la couche d'abstraction qui permet le provisionnement automatique de volumes. Définition de StorageClasses, provisioners, paramètres de configuration, StorageClass par défaut, expansion de volumes. Ce sous-chapitre couvre les provisioners courants sur Debian (local-path, NFS CSI).

**11.5.3 — CSI drivers sur Debian** : l'interface standardisée entre Kubernetes et les backends de stockage. Architecture CSI, installation de drivers CSI sur Debian (NFS, local-path, Longhorn), snapshots de volumes, et considérations pour le stockage on-premise.

---

## Prérequis pour cette section

- **Système de fichiers Linux** (Module 3) : montage, fstab, ext4, XFS, LVM.
- **Serveur de fichiers** (Module 7) : NFS, Samba, configuration et sécurisation.
- **Volumes Docker** (Module 10) : concepts de volumes, bind mounts, stockage éphémère.
- **Pods et Deployments** (Section 11.3) : volumeMounts, volumes dans la spec de Pod.

---

*Dans le sous-chapitre suivant (11.5.1), nous examinerons en détail le mécanisme PersistentVolume / PersistentVolumeClaim — le cœur du stockage persistant dans Kubernetes.*

⏭️ [Persistent Volumes et Persistent Volume Claims](/module-11-kubernetes-fondamentaux/05.1-pv-pvc.md)
