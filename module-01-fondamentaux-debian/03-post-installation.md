🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 1.3 Post-installation

## Présentation générale

L'installation est terminée, le système redémarre pour la première fois : Debian est opérationnel, mais pas encore prêt pour la production. La phase de **post-installation** couvre l'ensemble des opérations de vérification, de configuration et de renforcement qui transforment un système fraîchement installé en un environnement fiable, sécurisé et adapté à son rôle.

Cette phase est souvent sous-estimée, en particulier par les administrateurs débutants qui considèrent l'installation comme terminée dès le premier écran de connexion. En réalité, plusieurs actions sont indispensables avant de mettre une machine en service : vérifier que le système démarre correctement et que les services essentiels fonctionnent, ajuster la localisation (langue, fuseau horaire, disposition du clavier) si les choix effectués pendant l'installation doivent être affinés, appliquer les mises à jour de sécurité accumulées depuis la publication de l'image d'installation, et configurer correctement les comptes utilisateurs et les mécanismes d'élévation de privilèges.

Sur un serveur de production, cette phase inclut également des opérations de durcissement (*hardening*) qui seront approfondies dans les modules ultérieurs mais dont les premières briques sont posées ici.

## Le contexte du premier démarrage

### Ce qui a changé depuis l'installateur

Le premier démarrage marque une transition importante : l'environnement n'est plus celui du debian-installer mais celui du système installé sur le disque. Le noyau chargé est celui installé par le d-i sur la partition `/boot`, et non plus celui de l'initramfs du d-i. Le système d'initialisation est **systemd**, qui prend le rôle de PID 1 et orchestre le démarrage de l'ensemble des services. Le réseau est géré par l'outil configuré pendant l'installation (ifupdown, NetworkManager ou systemd-networkd) avec les paramètres définis à l'étape 1.2.4. Le gestionnaire de paquets APT est configuré avec les sources définies lors du choix du miroir.

L'administrateur se retrouve face à un système fonctionnel mais à l'état brut : la configuration par défaut de Debian est pensée pour être raisonnablement sûre et universelle, mais elle n'est optimisée pour aucun cas d'usage spécifique. La post-installation est le moment d'adapter ce socle générique au contexte réel de la machine.

### Différences selon le profil d'installation

L'expérience du premier démarrage diffère significativement selon le profil sélectionné via tasksel.

Pour un **serveur** (tâches SSH server + standard utilities, sans environnement de bureau), le premier démarrage aboutit à une **console texte** affichant un prompt de connexion. L'administrateur se connecte avec le compte root ou le compte utilisateur créé pendant l'installation. L'ensemble de la configuration post-installation se fait en ligne de commande.

Pour un **poste de travail** (avec un environnement de bureau GNOME, KDE, XFCE, etc.), le premier démarrage aboutit à un **gestionnaire de connexion graphique** (*display manager*) dont le choix par défaut dépend de l'environnement installé : `gdm3` pour GNOME, `sddm` pour KDE Plasma, `lightdm` pour XFCE, LXQt, LXDE et MATE (avec un *greeter* spécifique selon le DE — par exemple Arctica greeter pour MATE). L'utilisateur se connecte avec son compte et accède à l'environnement de bureau. Certaines opérations de post-installation peuvent être effectuées graphiquement, mais la ligne de commande reste l'outil le plus efficace et le plus universel pour l'administration.

## Objectifs de la post-installation

Les opérations de post-installation poursuivent quatre objectifs complémentaires.

**La validation fonctionnelle** consiste à vérifier que le système installé fonctionne correctement : démarrage sans erreur, services essentiels actifs, réseau opérationnel, matériel correctement détecté. C'est un contrôle qualité qui permet de détecter les problèmes au plus tôt, avant que la machine n'entre en service.

**L'ajustement de la localisation** assure que le système est configuré pour la langue, le fuseau horaire et la disposition de clavier appropriés. Le debian-installer configure ces paramètres pendant l'installation, mais des ajustements sont parfois nécessaires — par exemple, un serveur installé en anglais (recommandé pour la cohérence des messages d'erreur et la compatibilité avec les outils d'automatisation) mais dont l'administrateur souhaite un fuseau horaire local.

**La mise à jour de sécurité** est une étape critique, en particulier pour les installations réalisées depuis un DVD ou une image netinst datant de plusieurs semaines. Entre la publication de l'image et l'installation, des vulnérabilités ont pu être découvertes et corrigées. Appliquer les mises à jour avant toute mise en service est une exigence de sécurité non négociable.

**La configuration des accès** — création des comptes utilisateurs, configuration de sudo, durcissement de l'accès root — pose les fondations de la politique de sécurité de la machine. Un système dont le seul compte est root avec un mot de passe faible est un système vulnérable, quelle que soit la qualité du reste de sa configuration.

## Sous-sections

Les sous-sections qui suivent détaillent chacune de ces opérations :

- **1.3.1 — Premier démarrage et configuration initiale** : vérification du démarrage, contrôle des services, validation du matériel et de la connectivité réseau, premières commandes de diagnostic.
- **1.3.2 — Configuration des locales, fuseaux horaires et clavier** : gestion des locales (langues et encodages), configuration du fuseau horaire, disposition du clavier en console et en environnement graphique.
- **1.3.3 — Mise à jour du système** : application des correctifs de sécurité, fonctionnement d'APT pour les mises à jour, configuration des mises à jour automatiques.
- **1.3.4 — Création du premier utilisateur et configuration de sudo** : politique de gestion des comptes, configuration de sudo, sécurisation de l'accès root.

---

> **Navigation**  
>  
> Section précédente : [1.2.5 Sélection des paquets de base (tasksel)](/module-01-fondamentaux-debian/02.5-selection-paquets.md)  
>  
> Section suivante : [1.3.1 Premier démarrage et configuration initiale](/module-01-fondamentaux-debian/03.1-premier-demarrage.md)  
>  
> Retour au sommaire du module : [Module 1 — Fondamentaux de Debian](/module-01-fondamentaux-debian.md)

⏭️ [Premier démarrage et configuration initiale](/module-01-fondamentaux-debian/03.1-premier-demarrage.md)
