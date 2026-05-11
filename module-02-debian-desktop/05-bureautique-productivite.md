🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 2.5 Bureautique et productivité

## Introduction

Un poste de travail desktop n'atteint son plein potentiel que lorsqu'il est équipé des outils de productivité adaptés aux tâches quotidiennes de son utilisateur. Qu'il s'agisse de rédiger des documents, de gérer des feuilles de calcul, de naviguer sur le web, de communiquer par e-mail ou de développer du code, Debian offre un écosystème d'applications matures et performantes qui couvrent l'intégralité des besoins bureautiques et professionnels.

L'un des constats les plus fréquents des utilisateurs qui migrent vers Linux est la richesse de l'offre logicielle libre en matière de productivité. LibreOffice rivalise avec Microsoft Office pour la grande majorité des usages. Firefox et Chromium offrent une expérience de navigation complète. Thunderbird et Evolution sont des clients de messagerie à part entière. Et l'outillage de développement sous Linux est souvent considéré comme supérieur à celui des autres plateformes, les systèmes Unix étant historiquement le terreau naturel des outils de développement logiciel.

Ce chapitre présente les outils de bureautique et de productivité essentiels sous Debian, avec un focus sur leur configuration, leur intégration au système et les bonnes pratiques pour un usage quotidien efficace.

---

## Le paysage de la productivité sous Debian

### Catégories d'outils

Les outils de productivité desktop se répartissent en quatre grandes catégories, chacune traitée dans une sous-section dédiée :

**Suite bureautique (section 2.5.1)** : LibreOffice est la suite bureautique par défaut de Debian. Elle comprend un traitement de texte (Writer), un tableur (Calc), un outil de présentation (Impress), un outil de dessin (Draw), un gestionnaire de bases de données (Base) et un éditeur de formules (Math). Cette section couvre son installation complète, sa configuration avancée, la compatibilité avec les formats Microsoft Office et les astuces pour une utilisation quotidienne productive.

**Navigateurs web (section 2.5.2)** : le navigateur web est devenu l'application la plus utilisée sur un poste de travail, servant de point d'accès à la messagerie en ligne, aux outils collaboratifs, aux applications SaaS, au streaming et à la recherche d'information. Firefox ESR est installé par défaut, mais d'autres navigateurs sont disponibles. Cette section aborde la configuration avancée, les extensions essentielles, la gestion des profils et les considérations de vie privée.

**Clients de messagerie (section 2.5.3)** : malgré la popularité des webmails, un client de messagerie local offre des avantages significatifs en termes de productivité, de fonctionnalités de recherche, de gestion multi-comptes et de travail hors-ligne. Thunderbird, Evolution et KMail sont les trois principales options sous Debian.

**Outils de développement (section 2.5.4)** : un poste Debian est un environnement de développement naturel. Des éditeurs de texte légers aux IDE complets, des outils de versionnement aux environnements d'exécution, cette section couvre l'outillage nécessaire pour transformer un bureau Debian en station de développement productive.

### Logiciels libres et alternatives propriétaires

Le tableau suivant offre une vue d'ensemble des équivalences entre les outils propriétaires couramment utilisés sur d'autres plateformes et les alternatives disponibles sous Debian :

| Besoin | Outil propriétaire courant | Alternative libre (Debian) | Alternative propriétaire (Linux) |
|--------|---------------------------|---------------------------|----------------------------------|
| Traitement de texte | Microsoft Word | LibreOffice Writer | OnlyOffice, Google Docs (web) |
| Tableur | Microsoft Excel | LibreOffice Calc | OnlyOffice, Google Sheets (web) |
| Présentations | Microsoft PowerPoint | LibreOffice Impress | OnlyOffice, Google Slides (web) |
| Navigateur web | Google Chrome, Safari, Edge | Firefox ESR, Chromium | Google Chrome, Brave, Vivaldi |
| Client e-mail | Microsoft Outlook | Thunderbird, Evolution | — |
| Éditeur de code | Sublime Text | Kate, Geany, Vim, Neovim, Emacs | Visual Studio Code |
| IDE | JetBrains (IntelliJ, PyCharm) | Eclipse, GNOME Builder | JetBrains (versions Linux) |
| Notes | Microsoft OneNote, Notion | Joplin, GNOME Notes, Obsidian | Obsidian |
| PDF | Adobe Acrobat | Evince, Okular, Xournal++ | — |
| Gestion de projet | MS Project | Planner, GanttProject | — |

### Applications web vs applications locales

La frontière entre applications locales et applications web s'est considérablement estompée. De nombreux outils de productivité sont désormais accessibles via le navigateur : Google Workspace (Docs, Sheets, Slides), Microsoft 365, Notion, Figma, Trello, Slack, etc. Cette tendance a un impact direct sur l'expérience Linux : les applications web fonctionnent de manière identique quel que soit le système d'exploitation, éliminant la question de la compatibilité.

Cependant, les applications locales conservent des avantages significatifs :

**Performances** : une application locale est généralement plus réactive qu'une application web, particulièrement pour les tâches intensives (tableurs volumineux, documents complexes, édition d'images).

**Travail hors-ligne** : une application locale fonctionne sans connexion internet. C'est un atout critique pour les déplacements, les environnements avec une connectivité limitée ou les postes de travail dans des réseaux isolés.

**Intégration système** : une application locale s'intègre aux mécanismes du système d'exploitation : glisser-déposer, associations de fichiers, notifications, raccourcis clavier globaux, presse-papiers enrichi, impression, gestion de fichiers locale.

**Confidentialité** : les données traitées par une application locale restent sur la machine de l'utilisateur. Il n'y a pas de transmission à des serveurs tiers, ce qui est un critère déterminant dans certains contextes professionnels, juridiques ou de recherche.

**Fonctionnalités avancées** : les versions locales des suites bureautiques offrent des fonctionnalités absentes des versions web : macros, publipostage, gestion avancée des styles, formatage conditionnel complexe, gestion des révisions, etc.

La recommandation générale est d'utiliser des applications locales pour les tâches intensives ou nécessitant un travail hors-ligne, et de compléter avec les applications web pour la collaboration en temps réel et les outils qui n'ont pas d'équivalent local satisfaisant.

---

## Interopérabilité et formats de fichiers

L'interopérabilité avec les environnements Windows et macOS est une préoccupation constante dans un contexte professionnel. Les échanges de documents bureautiques, les pièces jointes par e-mail, les fichiers partagés en réseau — tous ces scénarios impliquent la manipulation de formats de fichiers qui doivent être rendus correctement sur les deux plateformes.

### Le défi de la compatibilité

La compatibilité des documents bureautiques entre LibreOffice et Microsoft Office est bonne pour les documents simples (texte formaté, tableaux basiques, présentations avec texte et images) et peut devenir problématique pour les documents complexes (mises en page élaborées, macros VBA, graphiques SmartArt, polices spécifiques, effets visuels avancés de PowerPoint).

Les principaux facteurs d'incompatibilité sont :

- **Les polices** : les polices Microsoft (Calibri, Cambria, Segoe UI) ne sont pas installées par défaut sous Linux. Leur absence provoque des substitutions qui modifient la mise en page. L'installation des polices de compatibilité (voir section 2.2.3) résout la majorité de ces problèmes.
- **Les macros VBA** : LibreOffice implémente un support partiel de VBA. Les macros simples fonctionnent, mais les macros complexes utilisant des API Windows ou des contrôles ActiveX ne sont pas supportées.
- **Les effets visuels** : les animations PowerPoint, les transitions 3D, les effets SmartArt et certains objets graphiques n'ont pas d'équivalent exact dans LibreOffice.
- **La mise en page** : les différences subtiles de rendu des polices et des espacements entre les deux suites peuvent décaler la mise en page sur les documents longs, modifiant la pagination.

### Stratégies de compatibilité

Selon le contexte, plusieurs stratégies peuvent être adoptées :

**Travailler en formats natifs et exporter** : travailler au quotidien en formats OpenDocument (ODF) et exporter en formats Microsoft Office uniquement lorsqu'un échange est nécessaire. Cette approche offre la meilleure expérience dans LibreOffice tout en restant compatible avec l'extérieur.

**Travailler directement en formats Microsoft** : configurer LibreOffice pour enregistrer par défaut en formats DOCX/XLSX/PPTX. Cette approche maximise la compatibilité avec les collaborateurs sous Windows mais peut introduire des pertes subtiles de formatage à chaque sauvegarde.

**Utiliser un format intermédiaire** : pour les documents finaux (rapports, présentations officielles), exporter en PDF élimine tout problème de compatibilité visuelle. Le PDF garantit un rendu identique sur toutes les plateformes.

**Utiliser Microsoft 365 en ligne** : pour les documents critiques nécessitant une fidélité parfaite au rendu Microsoft, les applications web Microsoft 365 sont accessibles depuis Firefox ou Chromium sous Linux.

---

## Outils de productivité transversaux

Certains outils de productivité ne rentrent pas dans les catégories des sous-sections suivantes mais méritent d'être mentionnés.

### Prise de notes

```bash
# GNOME Notes (Bijiben) — notes simples intégrées à GNOME
# Le nom du paquet binaire dans Debian est `bijiben`
# (le projet est en maintenance, plus de releases majeures depuis 2020)
sudo apt install bijiben

# Joplin — prise de notes avancée avec support Markdown, synchronisation,
# chiffrement, tags et carnets
flatpak install flathub net.cozic.joplin_desktop

# Obsidian — base de connaissances en Markdown avec liens bidirectionnels
flatpak install flathub md.obsidian.Obsidian

# Logseq — outil de pensée structurée et prise de notes en mode outline
flatpak install flathub com.logseq.Logseq

# Zim — wiki personnel en mode desktop (stockage en fichiers texte)
sudo apt install zim
```

### Gestion du temps et tâches

```bash
# Endeavour — gestionnaire de tâches GNOME (anciennement « GNOME To Do »,
# renommé « Endeavour » en amont en 2023). Le paquet Debian a suivi.
sudo apt install endeavour

# Planner (Planify) — gestionnaire de tâches avec support Todoist
flatpak install flathub io.github.alainm23.planify

# GNOME Calendar — calendrier avec intégration des comptes en ligne
sudo apt install gnome-calendar

# KOrganizer — calendrier et gestionnaire de tâches KDE
sudo apt install korganizer

# Pomodoro — minuteur de productivité (technique Pomodoro)
# Extension GNOME Shell : Pomodoro
# ou en Flatpak :
flatpak install flathub org.gnome.Solanum
```

### Gestion du presse-papiers

Un gestionnaire de presse-papiers conserve l'historique des copies et permet de retrouver et réutiliser des éléments copiés précédemment :

```bash
# GNOME : extension Clipboard Indicator
# Installable via extensions.gnome.org ou Extension Manager

# KDE : Klipper est intégré nativement dans Plasma
# Accessible depuis la zone de notification
# Raccourci : Ctrl+Alt+V pour afficher l'historique

# XFCE : clipman
sudo apt install xfce4-clipman-plugin
# Ajouter le plugin au panneau

# Indépendant du DE : CopyQ (avancé, multiformat, scriptable)
sudo apt install copyq  
copyq &  
```

### Outils de capture et d'annotation

```bash
# Flameshot — capture d'écran avec annotations en temps réel
sudo apt install flameshot
# Raccourci recommandé : lier flameshot gui à Impr. écran

# Xournal++ — annotation de PDF et prise de notes manuscrites
sudo apt install xournalpp

# Drawing — éditeur d'images simple pour GNOME (annotations, flèches, texte)
sudo apt install drawing
```

### Calculatrices et convertisseurs

```bash
# GNOME Calculator — calculatrice avec modes basique, avancé, financier, programmation
sudo apt install gnome-calculator

# KCalc — calculatrice scientifique KDE
sudo apt install kcalc

# Qalculate! — calculatrice puissante avec conversion d'unités,
# résolution d'équations, variables et fonctions
sudo apt install qalculate-gtk

# En ligne de commande
# bc : calculatrice en précision arbitraire
echo "scale=4; 355/113" | bc
# 3.1415

# units : conversion d'unités
sudo apt install units  
units "100 km/h" "m/s"  
# 100 km/h = 27.777778 m/s
```

---

## Intégration des comptes en ligne

Les environnements de bureau modernes proposent une intégration centralisée des comptes en ligne (Google, Microsoft, Nextcloud), qui alimente automatiquement les applications de productivité en données de calendrier, contacts, fichiers et e-mails.

### GNOME Online Accounts

```bash
# Paramètres → Comptes en ligne
# Fournisseurs supportés : Google, Microsoft 365, Nextcloud,
# IMAP/SMTP, CalDAV/CardDAV, Kerberos, Enterprise Login (SAML)

# L'ajout d'un compte Google, par exemple, synchronise automatiquement :
# - Calendrier → GNOME Calendar et Evolution
# - Contacts → GNOME Contacts et Evolution
# - Fichiers → Nautilus (accès Google Drive dans le panneau latéral)
# - E-mail → Evolution (si configuré)
```

### KDE Accounts

```bash
# Paramètres système → Comptes en ligne
# KDE supporte : Google, Nextcloud, et les comptes via KAccounts

# L'intégration alimente :
# - KOrganizer (calendrier)
# - KAddressBook (contacts)
# - Dolphin (accès aux fichiers distants via KIO)
# - KMail (e-mail)
```

### Nextcloud : l'alternative autohébergée

Pour les utilisateurs ou les organisations qui souhaitent conserver le contrôle de leurs données, Nextcloud offre une alternative autohébergée à Google Workspace et Microsoft 365 :

```bash
# Client de synchronisation Nextcloud
sudo apt install nextcloud-desktop

# Le client synchronise les fichiers localement (comme Dropbox)
# et s'intègre aux comptes en ligne GNOME/KDE pour le calendrier et les contacts

# L'intégration CalDAV/CardDAV permet de synchroniser les calendriers
# et contacts Nextcloud avec GNOME Calendar, Evolution, KOrganizer, Thunderbird
```

---

## Résumé

L'écosystème de productivité sous Debian est complet et mature. LibreOffice couvre les besoins bureautiques, Firefox et Chromium assurent la navigation web, Thunderbird et Evolution gèrent la messagerie, et l'outillage de développement sous Linux est parmi les plus riches disponibles. L'intégration des comptes en ligne (Google, Microsoft, Nextcloud) permet de connecter le bureau local aux services cloud de manière transparente.

Les défis principaux restent la compatibilité des formats Microsoft Office pour les documents complexes et l'absence native de certaines applications propriétaires (Microsoft Teams en version desktop, Adobe Creative Suite). Ces limitations sont en grande partie compensées par les applications web et par des alternatives libres de qualité.

Les sections suivantes détaillent chaque catégorie d'outils : la suite LibreOffice (section 2.5.1), les navigateurs web (section 2.5.2), les clients de messagerie (section 2.5.3) et les outils de développement (section 2.5.4).

⏭️ [Suite LibreOffice](/module-02-debian-desktop/05.1-libreoffice.md)
