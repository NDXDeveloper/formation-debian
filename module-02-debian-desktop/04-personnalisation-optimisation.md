🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 2.4 Personnalisation et optimisation

## Introduction

Un poste de travail n'est réellement productif que lorsqu'il est adapté aux habitudes, aux préférences et aux besoins de son utilisateur. Sous Linux, la personnalisation n'est pas un luxe cosmétique : c'est un levier d'efficacité. Un raccourci clavier bien choisi économise des milliers de manipulations à la souris sur une année. Un thème sombre réduit la fatigue visuelle lors des longues sessions de travail. Un système optimisé en termes de performances offre une réactivité qui transforme l'expérience quotidienne.

Debian et ses environnements de bureau offrent une latitude de personnalisation considérable, bien au-delà de ce que proposent la plupart des systèmes d'exploitation commerciaux. Cette capacité de personnalisation est l'un des attraits majeurs de Linux en tant que système desktop : chaque aspect de l'interface, du comportement et des performances peut être ajusté.

Ce chapitre couvre quatre axes de personnalisation et d'optimisation : l'apparence visuelle (thèmes, icônes, polices, couleurs), les raccourcis clavier et les automatisations gestuelles, l'optimisation des performances du bureau et du système, et enfin l'accessibilité pour les utilisateurs ayant des besoins spécifiques.

---

## Les niveaux de personnalisation

La personnalisation d'un bureau Linux s'articule autour de plusieurs niveaux, du plus visible au plus profond :

### Niveau 1 : l'apparence visuelle

C'est le niveau le plus immédiat et le plus accessible. Il concerne tout ce que l'utilisateur voit : les couleurs de l'interface, le style des fenêtres, les icônes, les polices de caractères, le fond d'écran, les curseurs, les animations. Chaque environnement de bureau propose ses propres mécanismes de thèmes (thèmes GTK pour GNOME et XFCE, thèmes Qt/Plasma pour KDE, etc.), et des milliers de thèmes communautaires sont disponibles.

La personnalisation visuelle n'est pas seulement esthétique. Le choix entre un thème clair et un thème sombre a un impact mesurable sur la fatigue visuelle. La taille et le type de police influencent la lisibilité. Les couleurs d'accentuation permettent de distinguer rapidement les éléments interactifs. Un environnement visuellement cohérent réduit la charge cognitive.

### Niveau 2 : le comportement et les interactions

Ce niveau concerne la manière dont l'utilisateur interagit avec le système : les raccourcis clavier, les gestes sur le pavé tactile, les actions associées aux coins et bords de l'écran, le comportement des fenêtres (focus, placement, ancrage), les espaces de travail et la navigation entre applications. Une configuration bien pensée de ce niveau peut transformer radicalement la productivité.

Les raccourcis clavier sont l'investissement le plus rentable en termes de personnalisation : une fois appris, ils éliminent des milliers d'interruptions quotidiennes liées au passage entre le clavier et la souris.

### Niveau 3 : les performances système

L'optimisation des performances concerne le fonctionnement sous-jacent du système : la réactivité de l'interface, la gestion de la mémoire, la vitesse de démarrage, la consommation des ressources par les services d'arrière-plan, les réglages du noyau et du système de fichiers. Sur les machines récentes, ces optimisations sont souvent superflues. Sur les machines plus anciennes ou avec des ressources limitées, elles peuvent faire la différence entre un système utilisable et un système frustrant.

### Niveau 4 : l'accessibilité

L'accessibilité est une forme de personnalisation essentielle qui permet aux utilisateurs ayant des besoins visuels, auditifs, moteurs ou cognitifs spécifiques d'utiliser le système de manière autonome. Linux, et GNOME en particulier, offrent un support d'accessibilité parmi les plus complets des systèmes d'exploitation desktop.

---

## Portabilité et sauvegarde de la personnalisation

### Fichiers dotfiles

L'essentiel de la personnalisation sous Linux est stocké dans des fichiers de configuration situés dans le répertoire personnel de l'utilisateur, généralement dans `~/.config/` ou sous forme de fichiers cachés (dotfiles) directement dans `~/`. Cette approche a un avantage fondamental : la personnalisation est portative. Sauvegarder ces fichiers permet de retrouver son environnement à l'identique sur une nouvelle machine ou après une réinstallation.

```bash
# Principaux répertoires de configuration par environnement
~/.config/                          # Répertoire standard XDG pour la configuration
~/.local/share/                     # Données d'application (thèmes, icônes, extensions)
~/.local/share/fonts/               # Polices installées par l'utilisateur

# GNOME
~/.config/dconf/                    # Base de données de configuration GNOME
~/.config/gnome-shell/              # Extensions GNOME Shell
~/.local/share/gnome-shell/extensions/  # Extensions installées par l'utilisateur

# KDE Plasma
~/.config/plasma*                   # Panneaux, widgets, thèmes
~/.config/kwinrc                    # Gestionnaire de fenêtres
~/.config/kdeglobals                # Paramètres globaux (thème, polices, couleurs)
~/.local/share/plasma/              # Thèmes, widgets installés par l'utilisateur

# XFCE
~/.config/xfce4/                    # Toute la configuration XFCE

# Shell et terminal
~/.bashrc                           # Configuration du shell Bash
~/.profile                          # Variables d'environnement
~/.vimrc                            # Configuration de Vim
~/.config/Code/User/settings.json   # Configuration VS Code
```

### Gestion des dotfiles avec Git

Une pratique courante parmi les utilisateurs Linux avancés consiste à versionner leurs fichiers de configuration avec Git. Cela permet de suivre l'historique des modifications, de synchroniser la configuration entre plusieurs machines et de la restaurer facilement :

```bash
# Méthode du bare repository (élégante, sans lien symbolique)
git init --bare ~/.dotfiles

# Créer un alias pour travailler avec ce dépôt
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Rendre l'alias permanent
echo "alias dotfiles='git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'" >> ~/.bashrc

# Ignorer les fichiers non suivis par défaut (évite le bruit)
dotfiles config --local status.showUntrackedFiles no

# Ajouter des fichiers de configuration
dotfiles add ~/.bashrc  
dotfiles add ~/.config/Code/User/settings.json  
dotfiles commit -m "Ajout de la configuration initiale"  

# Pousser vers un dépôt distant (GitHub, GitLab)
dotfiles remote add origin git@github.com:utilisateur/dotfiles.git  
dotfiles push -u origin main  
```

### Sauvegarde et restauration de la configuration GNOME

GNOME stocke sa configuration dans la base de données dconf, qui peut être exportée et importée intégralement :

```bash
# Exporter toute la configuration GNOME
dconf dump / > gnome-config-backup.txt

# Restaurer la configuration
dconf load / < gnome-config-backup.txt

# Exporter uniquement une section (par exemple les raccourcis)
dconf dump /org/gnome/desktop/wm/keybindings/ > raccourcis-backup.txt  
dconf dump /org/gnome/shell/extensions/ > extensions-backup.txt  
```

### Sauvegarde de la configuration KDE

```bash
# La configuration KDE étant basée sur des fichiers texte, 
# une simple copie suffit
tar czf kde-config-backup.tar.gz \
  ~/.config/plasma* \
  ~/.config/kwinrc \
  ~/.config/kdeglobals \
  ~/.config/kglobalshortcutsrc \
  ~/.local/share/plasma/

# Restaurer
tar xzf kde-config-backup.tar.gz -C ~/
```

---

## Outils de personnalisation transversaux

Certains outils de personnalisation fonctionnent indépendamment de l'environnement de bureau et méritent d'être mentionnés en introduction.

### dconf-editor (GNOME/GTK)

**dconf-editor** est un éditeur graphique qui donne accès à l'intégralité de la base de données de configuration GNOME. Il expose des centaines de paramètres qui ne sont pas accessibles via l'interface des Paramètres système, et constitue l'outil de personnalisation le plus complet pour les environnements basés sur GTK :

```bash
sudo apt install dconf-editor  
dconf-editor &  
```

### qt6ct / qt5ct (applications Qt hors KDE)

Lorsque des applications Qt sont utilisées dans un environnement non-KDE (GNOME, XFCE, LXQt en mode minimal), leur apparence peut être incohérente avec le reste de l'interface. Les outils `qt5ct` et `qt6ct` permettent de configurer l'apparence des applications Qt indépendamment de l'environnement :

```bash
# Pour les deux versions de Qt (la plupart des applis Qt cohabitent)
sudo apt install qt5ct qt6ct

# Définir la variable d'environnement de plateforme
# Qt 6 lit `QT_QPA_PLATFORMTHEME` ; même variable pour Qt 5
echo 'export QT_QPA_PLATFORMTHEME=qt6ct' >> ~/.profile
# Note : avec `qt6ct` comme valeur, les applis Qt5 utilisent automatiquement
# `qt5ct` si celui-ci est installé (mécanisme de fallback intégré).

# Se déconnecter/reconnecter, puis lancer
qt6ct &       # Configuration des applis Qt 6  
qt5ct &       # Configuration des applis Qt 5 (interface équivalente)  
# Configurer le thème, les polices, les icônes pour les applications Qt
```

> ⚠️ Sous KDE Plasma, **ne pas définir** `QT_QPA_PLATFORMTHEME` : Plasma utilise son propre mécanisme `KDEPlatformTheme`, et écraser cette variable casse l'intégration des dialogues KDE.

### xdg-user-dirs : répertoires utilisateur standard

Les répertoires standard de l'utilisateur (Bureau, Documents, Images, Musique, Téléchargements, Vidéos, etc.) sont définis par la spécification XDG et peuvent être personnalisés :

```bash
# Afficher la configuration actuelle
xdg-user-dir DESKTOP  
xdg-user-dir DOCUMENTS  
xdg-user-dir DOWNLOAD  

# Modifier un répertoire
xdg-user-dirs-update --set DOWNLOAD ~/mes-telechargements

# Le fichier de configuration
cat ~/.config/user-dirs.dirs
# XDG_DESKTOP_DIR="$HOME/Bureau"
# XDG_DOWNLOAD_DIR="$HOME/Téléchargements"
# XDG_DOCUMENTS_DIR="$HOME/Documents"
# XDG_MUSIC_DIR="$HOME/Musique"
# XDG_PICTURES_DIR="$HOME/Images"
# XDG_VIDEOS_DIR="$HOME/Vidéos"
```

---

## Philosophie de la personnalisation

La personnalisation d'un poste de travail est un processus itératif. Il est recommandé de procéder par étapes plutôt que de tout modifier d'un coup :

**Commencer par les paramètres par défaut.** Les environnements de bureau sont conçus pour offrir une bonne expérience dès l'installation. Utiliser le système tel quel pendant quelques jours permet d'identifier les vrais points de friction, plutôt que de modifier des paramètres par anticipation.

**Prioriser les gains fonctionnels.** Les raccourcis clavier et les automatisations ont un impact bien supérieur à l'esthétique pure. Un raccourci qui économise 3 secondes et que l'on utilise 50 fois par jour représente 2,5 minutes par jour, soit plus de 10 heures par an.

**Documenter ses modifications.** Chaque changement non standard devrait être noté ou versionné. Six mois plus tard, il est difficile de se souvenir pourquoi un paramètre a été modifié, et lors d'une réinstallation, la liste des modifications permet de retrouver son environnement rapidement.

**Éviter la sur-personnalisation.** Un environnement très personnalisé peut devenir un obstacle lorsqu'on doit travailler sur une machine différente (serveur, machine d'un collègue). Conserver une familiarité avec les paramètres par défaut est un atout pour un administrateur système.

---

## Résumé

La personnalisation et l'optimisation d'un bureau Debian s'articulent autour de quatre axes : l'apparence visuelle, le comportement et les raccourcis, les performances système et l'accessibilité. La configuration est stockée dans des fichiers texte ou des bases de données locales dans le répertoire personnel de l'utilisateur, ce qui la rend facilement sauvegardable, portable et versionnable.

Les sections suivantes détaillent chacun de ces axes : les thèmes et l'apparence (section 2.4.1), les raccourcis clavier (section 2.4.2), l'optimisation des performances (section 2.4.3) et l'accessibilité (section 2.4.4).

⏭️ [Thèmes et apparence](/module-02-debian-desktop/04.1-themes-apparence.md)
