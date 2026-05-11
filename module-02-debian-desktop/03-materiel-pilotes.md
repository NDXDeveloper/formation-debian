🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 2.3 Matériel et pilotes

## Introduction

Le support matériel est un sujet central pour tout système d'exploitation desktop. Un environnement de bureau n'a de valeur que s'il peut exploiter correctement le matériel de la machine : carte graphique, carte réseau WiFi, Bluetooth, écran tactile, lecteur d'empreintes digitales, webcam, imprimante, périphériques USB, etc. Sous Linux, ce support repose sur une combinaison de pilotes intégrés au noyau, de firmware chargé dynamiquement et, dans certains cas, de pilotes propriétaires fournis par les fabricants.

Debian aborde le support matériel avec une position de principe : le système de base ne contient que des logiciels libres. Les firmwares et pilotes propriétaires sont disponibles dans des dépôts séparés (`non-free` et `non-free-firmware`), laissant à l'utilisateur le choix de les installer ou non. Cette approche respecte les libertés de l'utilisateur mais peut créer de la confusion lors de l'installation initiale, lorsque du matériel courant (cartes WiFi, cartes graphiques NVIDIA) ne fonctionne pas sans composants non-libres.

Ce chapitre couvre l'ensemble de la gestion matérielle sur un poste Debian : la détection et l'identification du matériel, le fonctionnement des pilotes et des firmwares, l'installation des pilotes propriétaires, la gestion de l'alimentation, la configuration multi-écrans, et la prise en charge des périphériques Bluetooth et autres.

---

## Fonctionnement des pilotes sous Linux

### Le rôle du noyau

Le noyau Linux est le composant qui communique directement avec le matériel. Chaque catégorie de périphérique est gérée par un **pilote** (driver), un module logiciel qui « traduit » les requêtes du système en instructions compréhensibles par le matériel, et inversement.

```
┌───────────────────────────────────────────────────┐
│               Espace utilisateur                  │
│  (applications, environnement de bureau)          │
├───────────────────────────────────────────────────┤
│             Bibliothèques système                 │
│  (Mesa/OpenGL, ALSA, libinput, libevdev, etc.)    │
├───────────────────────────────────────────────────┤
│               Noyau Linux                         │
│  ┌─────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │ Pilotes │ │ Pilotes  │ │ Pilotes réseau    │   │
│  │ GPU     │ │ son      │ │ (WiFi, Ethernet)  │   │
│  │(i915,   │ │(snd_hda) │ │(iwlwifi,          │   │
│  │ amdgpu, │ │          │ │ ath11k, etc.)     │   │
│  │ nouveau)│ │          │ │                   │   │
│  └────┬────┘ └────┬─────┘ └────────┬──────────┘   │
│       │           │                │              │
│  ┌────▼───────────▼────────────────▼───────────┐  │
│  │              Firmware                       │  │
│  │  (microcode chargé dans le périphérique)    │  │
│  └─────────────────────────────────────────────┘  │
├───────────────────────────────────────────────────┤
│                 Matériel physique                 │
│  (GPU, carte son, carte WiFi, contrôleurs USB)    │
└───────────────────────────────────────────────────┘
```

### Modules du noyau

Les pilotes Linux sont implémentés sous forme de **modules du noyau** (kernel modules), des fragments de code qui peuvent être chargés et déchargés dynamiquement sans redémarrer le système. La grande majorité des pilotes matériels sont intégrés directement dans le noyau Linux officiel, ce qui signifie qu'ils sont disponibles dès l'installation de Debian.

```bash
# Lister les modules actuellement chargés
lsmod

# Afficher les informations d'un module spécifique
modinfo i915                # Pilote graphique Intel  
modinfo iwlwifi             # Pilote WiFi Intel  
modinfo amdgpu              # Pilote graphique AMD  
modinfo snd_hda_intel       # Pilote audio Intel HDA  

# Charger un module manuellement
sudo modprobe nom_du_module

# Décharger un module
sudo modprobe -r nom_du_module

# Voir les messages du noyau liés au chargement d'un module
dmesg | grep -i "nom_du_module"

# Lister les modules disponibles (pas seulement ceux chargés)
find /lib/modules/$(uname -r) -name "*.ko*" | wc -l
# Résultat typique : plusieurs milliers de modules disponibles
```

### Firmware : le logiciel embarqué

Le **firmware** est un logiciel binaire chargé dans le périphérique lui-même (carte WiFi, GPU, contrôleur Bluetooth, etc.) lors de l'initialisation. Contrairement aux pilotes qui s'exécutent dans le noyau Linux, le firmware s'exécute directement sur le processeur embarqué du périphérique.

De nombreux périphériques modernes nécessitent un firmware pour fonctionner. Sans ce firmware, le pilote noyau détecte le matériel mais ne peut pas l'initialiser, et le périphérique reste inutilisable. C'est la cause la plus fréquente de matériel non fonctionnel sur une installation Debian fraîche.

```bash
# Emplacement des firmwares sur le système
/lib/firmware/

# Vérifier les demandes de firmware échouées au démarrage
dmesg | grep -i "firmware"
# Les lignes contenant "failed to load firmware" indiquent un firmware manquant

# Exemple de message typique :
# iwlwifi 0000:00:14.3: Direct firmware load for iwlwifi-cc-a0-77.ucode failed
# → Le firmware pour la carte WiFi Intel n'est pas installé

# Voir quels firmwares sont installés
dpkg -l | grep firmware
```

### Distinction entre pilotes libres et propriétaires

| Aspect | Pilote libre (open source) | Pilote propriétaire |
|--------|--------------------------|---------------------|
| **Code source** | Disponible, auditable, modifiable | Fermé, binaire uniquement |
| **Maintenance** | Par la communauté et les développeurs noyau | Par le fabricant uniquement |
| **Intégration noyau** | Intégré à l'arbre des sources Linux | Module externe, compilé séparément |
| **Mises à jour** | Suivent les mises à jour du noyau Debian | Nécessitent une recompilation à chaque mise à jour noyau (via DKMS) |
| **Stabilité** | Excellente (testé avec le noyau) | Variable (peut casser lors des mises à jour noyau) |
| **Performances** | Bonnes à excellentes (Intel, AMD) | Parfois supérieures pour les cas spécifiques (NVIDIA pour le gaming, CUDA) |
| **Exemples** | `i915` (Intel), `amdgpu` (AMD), `nouveau` (NVIDIA libre) | `nvidia` (NVIDIA propriétaire) |

---

## Détection et identification du matériel

Avant de pouvoir résoudre un problème de pilote ou installer un composant manquant, il faut savoir identifier précisément le matériel présent dans la machine. Linux dispose de plusieurs outils pour cela.

### lspci : périphériques PCI/PCIe

La commande `lspci` liste tous les périphériques connectés au bus PCI et PCIe : carte graphique, carte réseau, contrôleur USB, contrôleur SATA, carte son, etc.

```bash
# Liste compacte de tous les périphériques PCI
lspci

# Liste détaillée avec les identifiants vendeur/produit
lspci -nn

# Informations très détaillées sur un périphérique spécifique
lspci -v -s 00:02.0     # Détails du périphérique à l'adresse 00:02.0

# Afficher le pilote utilisé par chaque périphérique
lspci -k
# Résultat pour chaque périphérique :
# Kernel driver in use: i915          ← pilote noyau chargé
# Kernel modules: i915                ← modules disponibles

# Filtrer par type de périphérique
lspci | grep -i vga          # Carte(s) graphique(s)  
lspci | grep -i network      # Carte(s) réseau  
lspci | grep -i audio        # Carte(s) son  
lspci | grep -i usb          # Contrôleur(s) USB  

# Installer la base de données des identifiants PCI (pour des noms plus lisibles)
sudo apt install pciutils  
sudo update-pciids  
```

### lsusb : périphériques USB

```bash
# Liste compacte des périphériques USB connectés
lsusb

# Liste détaillée
lsusb -v

# Afficher l'arborescence USB (hubs et périphériques)
lsusb -t

# Exemple de résultat :
# Bus 001 Device 003: ID 046d:c52b Logitech, Inc. Unifying Receiver
# Bus 001 Device 005: ID 8087:0029 Intel Corp. AX200 Bluetooth
```

### lshw : inventaire matériel complet

```bash
# Installer lshw
sudo apt install lshw

# Inventaire matériel complet (nécessite root pour les détails)
sudo lshw

# Version résumée
sudo lshw -short

# Filtrer par classe de matériel
sudo lshw -class network      # Périphériques réseau  
sudo lshw -class display      # Périphériques graphiques  
sudo lshw -class multimedia   # Périphériques multimédia  
sudo lshw -class disk         # Disques et stockage  
sudo lshw -class memory       # Mémoire  

# Exporter en HTML pour une consultation agréable
sudo lshw -html > inventaire_materiel.html

# Version graphique de lshw
sudo apt install lshw-gtk  
sudo lshw-gtk &  
```

### inxi : résumé système lisible

```bash
# Installer inxi
sudo apt install inxi

# Résumé complet du système (matériel, OS, noyau, etc.)
inxi -Fxz

# Informations graphiques détaillées
inxi -G

# Informations audio
inxi -A

# Informations réseau
inxi -N

# Informations sur les capteurs (température, ventilateurs)
inxi -s

# Informations batterie
inxi -B
```

### Autres outils de détection

```bash
# Informations sur le processeur
lscpu  
cat /proc/cpuinfo  

# Informations sur la mémoire
free -h  
sudo dmidecode -t memory     # Détails des barrettes (taille, type, fréquence)  

# Informations sur les disques
lsblk                         # Arborescence des blocs de stockage  
sudo hdparm -I /dev/sda       # Informations détaillées d'un disque  
sudo smartctl -a /dev/sda     # État SMART d'un disque (nécessite smartmontools)  

# Informations sur les périphériques d'entrée (clavier, souris, touchpad)
sudo libinput list-devices

# Informations sur les capteurs matériels (température, voltage, ventilateurs)
sudo apt install lm-sensors  
sudo sensors-detect            # Détecter les capteurs disponibles (répondre YES aux questions)  
sensors                        # Afficher les valeurs des capteurs  
```

---

## Le système udev

### Rôle de udev

**udev** est le gestionnaire de périphériques de l'espace utilisateur sous Linux. Il est responsable de la détection dynamique des périphériques et de la création des fichiers spéciaux dans `/dev/`. Lorsqu'un périphérique est connecté (branchement USB, détection d'une carte PCI au démarrage), le noyau émet un événement. udev capte cet événement et exécute les actions appropriées : création du fichier `/dev/`, chargement du module noyau, application des permissions, déclenchement de notifications au bureau.

```bash
# Surveiller les événements udev en temps réel
# (brancher/débrancher un périphérique USB pour voir les événements)
sudo udevadm monitor

# Afficher les attributs udev d'un périphérique
udevadm info --query=all --name=/dev/sda  
udevadm info --query=all --path=/sys/class/net/wlan0  

# Recharger les règles udev après modification
sudo udevadm control --reload-rules  
sudo udevadm trigger  
```

### Règles udev personnalisées

Les règles udev permettent d'automatiser des actions lorsqu'un périphérique est connecté ou déconnecté. Elles sont stockées dans `/etc/udev/rules.d/` (règles locales) et `/lib/udev/rules.d/` (règles système, ne pas modifier).

```bash
# Exemple : donner accès à un Arduino à un utilisateur non-root
# Créer le fichier /etc/udev/rules.d/99-arduino.rules
SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="0043", \
  MODE="0666", GROUP="dialout", SYMLINK+="arduino"

# Exemple : lancer un script à l'insertion d'une clé USB spécifique
SUBSYSTEM=="block", ATTRS{idVendor}=="0781", ACTION=="add", \
  RUN+="/usr/local/bin/sauvegarde_auto.sh"

# Appliquer les nouvelles règles
sudo udevadm control --reload-rules
```

---

## DKMS : compilation automatique de modules tiers

**DKMS** (Dynamic Kernel Module Support) est un framework qui automatise la recompilation des modules noyau tiers lors de chaque mise à jour du noyau. Sans DKMS, un pilote propriétaire compilé pour un noyau spécifique cesserait de fonctionner dès qu'un nouveau noyau est installé.

DKMS est utilisé par les pilotes NVIDIA propriétaires, VirtualBox, certains pilotes WiFi tiers et d'autres modules hors de l'arbre des sources Linux.

```bash
# Installer DKMS
sudo apt install dkms

# Lister les modules DKMS enregistrés
dkms status

# Résultat typique sur Debian 13 Trixie (noyau 6.12 LTS) :
# nvidia-current/550.163.01, 6.12.0-N-amd64, x86_64: installed
# virtualbox/7.1.x, 6.12.0-N-amd64, x86_64: installed
# Note : Debian Trixie fournit deux séries NVIDIA dans le dépôt standard,
# la 550.x (défaut, paquet `nvidia-driver`) et la 535.x (legacy via les
# paquets nvidia-tesla-535-* pour les GPU plus anciens). Les versions
# 575+ ne sont disponibles qu'via experimental ou trixie-backports
# (cf. §2.3.1 pour les détails).

# Recompiler manuellement un module DKMS (rarement nécessaire)
sudo dkms autoinstall

# Vérifier les logs DKMS en cas d'échec de compilation
cat /var/lib/dkms/nom_module/version/build/make.log
```

Lorsqu'un nouveau noyau est installé via `apt upgrade`, les scripts de post-installation du noyau déclenchent automatiquement DKMS qui recompile tous les modules enregistrés pour le nouveau noyau.

---

## Outils graphiques de gestion du matériel

Les environnements de bureau fournissent des outils graphiques pour la gestion courante du matériel, accessibles sans connaissances techniques approfondies :

| Outil | Environnement | Fonction |
|-------|---------------|----------|
| **Paramètres système** (gnome-control-center) | GNOME | Écrans, son, Bluetooth, réseau, alimentation, clavier, souris |
| **Paramètres système** (systemsettings) | KDE Plasma | Écrans, son, Bluetooth, réseau, alimentation, entrées, informations système |
| **Paramètres** (xfce4-settings) | XFCE | Écrans, son, clavier, souris, alimentation |
| **GNOME Disks** (gnome-disk-utility) | Tous | Gestion des disques, partitionnement, montage, tests de performance, images disque |
| **Imprimantes** (system-config-printer) | Tous | Configuration des imprimantes et scanners |

---

## Diagnostic matériel : méthodologie

Face à un périphérique qui ne fonctionne pas, la démarche de diagnostic suit un cheminement logique :

```
1. Le matériel est-il détecté ?
   └─ lspci -nn / lsusb / dmesg | tail -30
   └─ Si non → problème physique ou matériel non compatible

2. Le pilote est-il chargé ?
   └─ lspci -k (colonne "Kernel driver in use")
   └─ Si non → module manquant ou firmware manquant

3. Le firmware est-il présent ?
   └─ dmesg | grep -i firmware
   └─ Si "failed to load" → installer le paquet firmware correspondant

4. Le périphérique est-il fonctionnel ?
   └─ Tests spécifiques au type de périphérique
   └─ ip link show (réseau), aplay -l (audio), xrandr (écran), etc.

5. La configuration est-elle correcte ?
   └─ Paramètres système, fichiers de configuration, logs
   └─ journalctl -b | grep -i "erreur ou nom_du_périphérique"
```

```bash
# Commande universelle de premier diagnostic
# Affiche les derniers messages du noyau (souvent révélateurs)
dmesg | tail -50

# Messages de démarrage liés au matériel
journalctl -b -p err     # Uniquement les erreurs depuis le dernier démarrage  
journalctl -b -p warning  # Erreurs et avertissements  
```

---

## Résumé

La gestion matérielle sous Debian repose sur une architecture modulaire : le noyau Linux fournit les pilotes, les firmwares sont chargés depuis `/lib/firmware/`, et le système udev assure la détection dynamique des périphériques. Les outils de diagnostic (`lspci`, `lsusb`, `lshw`, `inxi`, `dmesg`) permettent d'identifier précisément le matériel et l'état de ses pilotes. DKMS automatise la gestion des modules tiers lors des mises à jour du noyau.

Les sections suivantes détaillent les cas pratiques les plus courants : l'installation des firmwares non-libres et des pilotes propriétaires, notamment NVIDIA et WiFi (section 2.3.1), la gestion de l'alimentation et les modes de veille (section 2.3.2), la configuration multi-écrans (section 2.3.3), et la prise en charge du Bluetooth et des périphériques (section 2.3.4).

⏭️ [Firmware non-libre et pilotes propriétaires (NVIDIA, WiFi)](/module-02-debian-desktop/03.1-firmware-pilotes-proprietaires.md)
