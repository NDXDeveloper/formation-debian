🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 2.2 Gestion des applications desktop

## Introduction

Une fois l'environnement de bureau installé et configuré, l'étape suivante consiste à le rendre productif en installant et en gérant les applications nécessaires au quotidien. Sous Debian, cette tâche est à la fois simple et riche en options : le système propose plusieurs méthodes d'installation, plusieurs formats de paquets et plusieurs sources de logiciels, chacun avec ses avantages et ses compromis.

Ce chapitre couvre l'ensemble du cycle de vie des applications desktop sous Debian : comment les découvrir, les installer, les mettre à jour, les configurer et les désinstaller. Il aborde également les questions pratiques que rencontre tout utilisateur de Debian sur le bureau : comment installer un logiciel qui n'est pas dans les dépôts officiels, comment gérer les codecs multimédia, comment ouvrir les formats de fichiers courants et comment naviguer dans l'écosystème des logiciels libres et propriétaires.

---

## Le paysage de l'installation logicielle sous Debian

### Les différentes méthodes d'installation

Contrairement aux systèmes d'exploitation qui proposent une source unique d'applications (App Store d'Apple, Microsoft Store), Debian offre plusieurs voies pour installer des logiciels. Ces méthodes coexistent et sont complémentaires :

**Les dépôts officiels Debian (paquets .deb)** constituent la source principale et la plus fiable. Les paquets sont compilés, testés et maintenus par les développeurs Debian. Ils bénéficient des mises à jour de sécurité de l'équipe Debian Security et s'intègrent parfaitement au système de gestion de dépendances APT. La contrepartie est que les versions disponibles dans Debian Stable sont souvent plus anciennes que les dernières versions publiées par les développeurs upstream, car Debian privilégie la stabilité sur la nouveauté.

**Flatpak** est un système de distribution d'applications sandboxées, indépendant de la distribution. Les applications Flatpak embarquent leurs propres dépendances et s'exécutent dans un environnement isolé du système. Le dépôt principal est Flathub, qui propose des milliers d'applications souvent dans leur version la plus récente. Flatpak est la méthode recommandée pour obtenir des versions récentes de logiciels desktop sans compromettre la stabilité du système de base.

**Les paquets .deb tiers** sont des paquets au format Debian fournis directement par les éditeurs de logiciels (Google Chrome, Visual Studio Code, Spotify, etc.). Ils s'installent comme des paquets Debian classiques mais proviennent de dépôts externes. Ils offrent généralement des versions plus récentes que les dépôts Debian, mais leur maintenance et leur qualité dépendent entièrement de l'éditeur.

**Snap** est le système de paquets universels développé par Canonical (Ubuntu). Il est disponible sous Debian mais moins courant que Flatpak dans l'écosystème Debian. Les Snaps fonctionnent de manière similaire aux Flatpak, avec leurs propres mécanismes de sandboxing et de mise à jour.

**AppImage** est un format de distribution portable : un fichier unique téléchargeable qui contient l'application et toutes ses dépendances. Il ne nécessite aucune installation — il suffit de rendre le fichier exécutable et de le lancer. Ce format est pratique pour tester une application mais n'offre ni intégration système, ni mises à jour automatiques, ni sandboxing.

**La compilation depuis les sources** reste une option pour les logiciels qui ne sont disponibles dans aucun format précompilé, ou lorsqu'une configuration de compilation spécifique est nécessaire. Cette méthode est réservée aux utilisateurs avancés car elle nécessite la gestion manuelle des dépendances de compilation et ne bénéficie pas du système de mises à jour automatiques.

### Quelle méthode privilégier ?

Le choix de la méthode d'installation suit une logique de priorité qui équilibre stabilité, sécurité et fraîcheur des versions :

```
1. Dépôts officiels Debian (apt)
   └─ Première source à consulter. Paquet intégré au système,
      mises à jour de sécurité garanties, dépendances gérées.

2. Flatpak (Flathub)
   └─ Si la version Debian est trop ancienne ou si l'application
      n'est pas dans les dépôts. Version récente, sandboxée.

3. Dépôts tiers de l'éditeur (.deb)
   └─ Si l'éditeur fournit un dépôt officiel (Google, Microsoft,
      etc.). Intégration système complète, version à jour.

4. AppImage / binaire téléchargeable
   └─ Si aucune autre option n'est disponible. Pas d'intégration
      système, pas de mises à jour automatiques.

5. Compilation depuis les sources
   └─ Dernier recours. Nécessite des compétences techniques et
      une gestion manuelle des mises à jour.
```

Cette hiérarchie est une recommandation générale. Selon le contexte (poste de développement, station multimédia, machine d'entreprise), les priorités peuvent varier. Un poste de développement privilégiera souvent les versions les plus récentes via Flatpak ou les dépôts tiers, tandis qu'un poste d'entreprise standardisé se limitera aux dépôts officiels pour des raisons de support et de reproductibilité.

---

## Concepts fondamentaux

### Le fichier .desktop et l'intégration aux menus

Sous Linux, les applications graphiques s'intègrent aux menus et aux lanceurs via des fichiers `.desktop`, un standard défini par la spécification freedesktop.org. Chaque fichier `.desktop` décrit une application : son nom, son icône, la commande de lancement, ses catégories, ses types MIME supportés, et dans quels environnements de bureau elle doit apparaître.

```ini
# Exemple : /usr/share/applications/org.gnome.TextEditor.desktop
[Desktop Entry]
Name=Text Editor  
Name[fr]=Éditeur de texte  
Comment=Edit text files  
Comment[fr]=Modifier des fichiers texte  
Exec=gnome-text-editor %U  
Icon=org.gnome.TextEditor  
Terminal=false  
Type=Application  
Categories=GNOME;GTK;Utility;TextEditor;  
MimeType=text/plain;text/x-log;  
StartupNotify=true  
```

Les fichiers `.desktop` sont recherchés dans deux emplacements :

```bash
# Applications système (installées par les paquets)
/usr/share/applications/

# Applications utilisateur (personnalisations, ajouts manuels, overrides)
~/.local/share/applications/

# Lister toutes les applications détectées par le système
ls /usr/share/applications/*.desktop | wc -l  
ls ~/.local/share/applications/*.desktop 2>/dev/null | wc -l  
```

Une copie locale dans `~/.local/share/applications/` prend le pas sur la version système, ce qui permet de personnaliser le comportement ou l'apparence d'une application dans les menus sans modifier les fichiers système.

### Associations de types de fichiers (types MIME)

Le système d'association fichier-application sous Linux repose sur les types MIME. Lorsqu'un utilisateur double-clique sur un fichier, le système identifie son type MIME et lance l'application associée par défaut.

```bash
# Identifier le type MIME d'un fichier
xdg-mime query filetype document.pdf
# Résultat : application/pdf

# Connaître l'application par défaut pour un type MIME
xdg-mime query default application/pdf
# Résultat typique sur GNOME Trixie : org.gnome.Evince.desktop
# (Note 2026 : Papers — fork moderne d'Evince en GTK4/libadwaita/Rust —
# est packagé dans Trixie et devrait remplacer Evince comme défaut à
# partir de GNOME 49. Sur les installations Trixie récentes ou mises
# à jour, le défaut peut donc être `org.gnome.Papers.desktop`.)

# Modifier l'application par défaut pour un type
xdg-mime default org.kde.okular.desktop application/pdf

# Ouvrir un fichier avec l'application par défaut
xdg-open document.pdf  
xdg-open https://www.debian.org  
xdg-open photo.jpg  
```

Les associations par défaut sont stockées dans :

```bash
# Associations par défaut de l'utilisateur
~/.config/mimeapps.list

# Associations système (fallback)
/usr/share/applications/mimeapps.list

# Le fichier utilisateur est prioritaire
# Format du fichier :
# [Default Applications]
# application/pdf=org.gnome.Evince.desktop
# text/html=firefox-esr.desktop
# image/jpeg=org.gnome.Loupe.desktop

# [Added Associations]
# application/pdf=org.gnome.Evince.desktop;org.kde.okular.desktop;
```

Les environnements de bureau (GNOME, KDE, XFCE) proposent également des interfaces graphiques pour configurer les applications par défaut dans leurs paramètres respectifs.

### Applications graphiques vs ligne de commande

Les applications desktop sous Linux sont des programmes graphiques qui s'appuient sur un toolkit graphique (GTK, Qt, Electron, etc.) pour leur interface utilisateur. Elles se distinguent des outils en ligne de commande par leur mode d'interaction, mais les deux mondes communiquent :

```bash
# Lancer une application graphique depuis le terminal
firefox &                    # Le & libère le terminal  
nautilus /home/utilisateur & # Ouvrir le gestionnaire de fichiers dans un dossier spécifique  
code ~/projets/mon-projet &  # Ouvrir VS Code sur un projet  

# Lancer une application graphique détachée du terminal
nohup firefox &              # Continue de fonctionner si le terminal est fermé  
setsid firefox               # Lance dans une nouvelle session  

# Ouvrir un fichier avec l'application par défaut du système
xdg-open fichier.pdf  
xdg-open image.png  
xdg-open https://example.com  
```

---

## Composants partagés de l'écosystème desktop

Indépendamment de l'environnement de bureau choisi, un bureau Debian repose sur plusieurs composants partagés qui assurent l'interopérabilité des applications et la cohérence de l'expérience utilisateur.

### D-Bus : le bus de communication

D-Bus est le système de communication inter-processus (IPC) utilisé par toutes les applications desktop modernes. Il permet aux applications d'échanger des messages, d'exposer des services et de réagir à des événements système. Par exemple, lorsqu'une clé USB est insérée, D-Bus transmet l'événement au gestionnaire de fichiers qui propose de l'ouvrir.

```bash
# Lister les services D-Bus de session (utilisateur)
dbus-send --session --dest=org.freedesktop.DBus --type=method_call \
  --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames

# Outil graphique pour explorer D-Bus
sudo apt install d-feet
```

### PipeWire : audio et vidéo unifiés

PipeWire est le serveur multimédia qui gère les flux audio et vidéo sur les systèmes Debian modernes. Il remplace PulseAudio pour l'audio et fournit l'infrastructure vidéo nécessaire au partage d'écran et à la capture webcam sous Wayland. Toutes les applications audio et vidéo du bureau interagissent avec PipeWire.

### Portails XDG

Les portails XDG, présentés dans la section 2.1.5, fournissent des interfaces standardisées pour les opérations système communes (ouverture de fichiers, impression, capture d'écran, notifications). Ils sont particulièrement importants pour les applications Flatpak qui s'exécutent dans un sandbox et qui ont besoin de ces portails pour interagir avec le système.

### Polkit : gestion des privilèges

Polkit (anciennement PolicyKit) est le framework qui gère les demandes d'élévation de privilèges dans les applications graphiques. Lorsqu'une application a besoin de droits administrateur (installer un paquet, monter un disque, modifier la configuration réseau), Polkit affiche un dialogue d'authentification. Chaque environnement de bureau fournit son propre agent Polkit pour l'intégration visuelle.

### Notifications freedesktop

Le système de notifications est standardisé par la spécification freedesktop.org. Toutes les applications peuvent envoyer des notifications via D-Bus, et le démon de notifications de l'environnement de bureau (gnome-shell, xfce4-notifyd, lxqt-notificationd) les affiche de manière cohérente.

```bash
# Envoyer une notification depuis la ligne de commande
notify-send "Titre" "Ceci est une notification de test"  
notify-send -i dialog-warning "Attention" "Espace disque faible"  

# Nécessite le paquet libnotify-bin
sudo apt install libnotify-bin
```

---

## Gestion des mises à jour des applications

### Mises à jour des paquets .deb

Les applications installées via APT sont mises à jour avec le système :

```bash
# Mettre à jour la liste des paquets et installer les mises à jour
sudo apt update && sudo apt upgrade

# Les environnements de bureau proposent également des interfaces graphiques
# GNOME : Logiciels (gnome-software) → Mises à jour
# KDE : Discover → Mises à jour
# XFCE : pas d'outil graphique dédié, utiliser apt en terminal
```

### Mises à jour Flatpak

```bash
# Mettre à jour toutes les applications Flatpak
flatpak update

# Les mises à jour Flatpak sont également proposées par
# GNOME Logiciels et KDE Discover s'ils sont configurés avec Flatpak
```

### Mises à jour automatiques

Debian propose le paquet `unattended-upgrades` pour les mises à jour de sécurité automatiques. Pour les applications desktop, les environnements de bureau peuvent être configurés pour notifier l'utilisateur ou appliquer automatiquement les mises à jour disponibles.

---

## Résumé

La gestion des applications desktop sous Debian repose sur un écosystème riche et mature. Les dépôts officiels offrent une base solide et fiable, complétée par Flatpak pour les versions récentes et par les dépôts tiers des éditeurs pour les logiciels propriétaires. La compréhension des fichiers `.desktop`, des types MIME et des composants partagés (D-Bus, PipeWire, portails XDG) permet de maîtriser le fonctionnement des applications dans n'importe quel environnement de bureau.

Les sections suivantes détaillent chaque aspect : les logithèques et centres d'applications graphiques (section 2.2.1), l'installation des logiciels courants par catégorie d'usage (section 2.2.2), la gestion des formats de fichiers (section 2.2.3) et la configuration multimédia avec codecs et PipeWire (section 2.2.4).

⏭️ [Logithèque et centres d'applications](/module-02-debian-desktop/02.1-logitheque.md)
