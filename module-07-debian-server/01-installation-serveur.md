🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 7.1 Installation serveur

## Introduction

Le passage d'un système Debian desktop à un environnement serveur de production représente un changement fondamental de philosophie. Un serveur n'a pas vocation à offrir une interface graphique confortable : il doit être léger, stable, sécurisé et administrable à distance. Chaque paquet installé, chaque service actif et chaque port ouvert constitue une surface d'attaque potentielle. L'installation d'un serveur Debian se pense donc en termes de minimalisme et de maîtrise.

Ce chapitre couvre l'ensemble du processus qui transforme une machine — physique ou virtuelle — en un serveur Debian prêt pour la production. De l'installation minimale à la sécurisation initiale, en passant par la configuration réseau et les outils d'administration à distance, chaque étape vise un objectif commun : disposer d'une base saine, reproductible et durcie sur laquelle déployer des services.

---

## Pourquoi une installation serveur diffère-t-elle d'une installation desktop ?

Sur un poste de travail, on privilégie l'expérience utilisateur : environnement graphique, codecs multimédia, suite bureautique, navigateur. Sur un serveur, les priorités sont radicalement différentes.

**Minimalisme** — Un serveur de production ne devrait embarquer que les paquets strictement nécessaires à son rôle. Moins il y a de logiciels installés, moins il y a de mises à jour à gérer, de vulnérabilités potentielles et de ressources consommées inutilement. L'installeur Debian permet d'atteindre ce minimalisme grâce à l'option *netinst* combinée à la désélection de tous les groupes de paquets proposés par `tasksel`, ne conservant que le système de base et le serveur SSH.

**Stabilité** — Un serveur est conçu pour fonctionner sans interruption pendant des mois, voire des années. Le choix de la branche **Stable** de Debian prend ici tout son sens : les paquets sont éprouvés, les mises à jour de sécurité sont rigoureusement testées et les changements de comportement entre deux mises à jour mineures sont quasi inexistants.

**Sécurité dès l'installation** — La sécurisation n'est pas une étape que l'on ajoute après coup. Elle commence dès le partitionnement des disques (séparation de `/tmp`, `/var`, `/home` avec des options de montage restrictives), se poursuit avec la configuration du pare-feu et la désactivation de l'accès root par SSH, et s'inscrit dans une démarche continue tout au long de la vie du serveur.

**Reproductibilité** — Dans un environnement professionnel, il est courant de devoir déployer des dizaines de serveurs identiques. L'installation manuelle devient alors un goulet d'étranglement et une source d'erreurs. Debian propose le mécanisme **preseed** qui permet d'automatiser intégralement le processus d'installation à partir d'un fichier de réponses prédéfini.

**Administration à distance** — Un serveur ne dispose généralement pas d'écran ni de clavier en fonctionnement normal. Toute l'administration se fait via SSH ou, dans certains cas, via des interfaces web dédiées. La configuration de ces accès distants fait partie intégrante de la mise en service.

---

## Schéma de partitionnement recommandé pour un serveur

Le partitionnement d'un serveur mérite une attention particulière. Contrairement à un desktop où un schéma simple (une partition racine et un swap) suffit généralement, un serveur bénéficie d'une séparation fine des points de montage. Cette approche offre plusieurs avantages : isolation des données utilisateur, protection contre le remplissage de la partition racine par les logs, possibilité d'appliquer des options de montage restrictives par partition et facilité de redimensionnement via LVM.

Voici un schéma type pour un serveur généraliste :

| Point de montage | Taille indicative | Rôle | Options de montage recommandées |
|---|---|---|---|
| `/boot` | 512 Mo – 1 Go | Noyaux et fichiers de démarrage | `nodev,nosuid` |
| `/` | 10 – 20 Go | Système de base | `defaults` |
| `/tmp` | 2 – 5 Go | Fichiers temporaires | `nodev,nosuid,noexec` |
| `/var` | 10 – 50 Go | Logs, spools, données variables | `nodev,nosuid` |
| `/var/log` | 5 – 20 Go | Logs système et applicatifs | `nodev,nosuid,noexec` |
| `/home` | Variable | Données utilisateur | `nodev,nosuid` |
| `swap` | 1× à 2× RAM | Mémoire virtuelle | — |

L'utilisation de **LVM** (Logical Volume Manager) est fortement conseillée sur un serveur. Elle permet de redimensionner les volumes logiques à chaud, de créer des snapshots avant une opération risquée et de gérer l'ajout de disques physiques sans modifier le schéma de partitionnement existant. Sur les serveurs manipulant des données sensibles, le chiffrement via **LUKS** peut être superposé à LVM.

---

## Les étapes clés de la mise en service

La mise en service d'un serveur Debian suit un enchaînement logique en quatre grandes phases, chacune détaillée dans une sous-section dédiée :

**1. Installation minimale et automatisation (7.1.1)** — Cette première phase consiste à installer un système Debian aussi léger que possible, en ne sélectionnant que les composants essentiels. On y aborde l'installation interactive via *netinst* pour comprendre chaque étape, puis le mécanisme *preseed* qui permet d'automatiser cette même installation pour des déploiements à grande échelle. La maîtrise de preseed est une compétence précieuse pour tout administrateur gérant un parc de serveurs.

**2. Configuration réseau serveur (7.1.2)** — Un serveur a besoin d'une configuration réseau fiable et prévisible. On y traite l'adressage statique (indispensable pour les services réseau), la configuration DNS, le choix entre `/etc/network/interfaces` et `systemd-networkd`, ainsi que les particularités réseau propres à un environnement serveur comme le bonding d'interfaces ou les VLAN.

**3. Sécurisation initiale (7.1.3)** — Avant de déployer le moindre service applicatif, le serveur doit être durci. Cette phase couvre la configuration du pare-feu avec `nftables`, la politique de mots de passe, la restriction des services actifs, les mises à jour automatiques de sécurité avec `unattended-upgrades` et les premiers contrôles d'intégrité. Ce hardening de base constitue le socle sur lequel reposera toute la sécurité du serveur.

**4. Outils d'administration à distance (7.1.4)** — Enfin, on met en place les outils qui permettront d'administrer le serveur au quotidien. Au-delà d'SSH (déjà couvert au Module 6), cette section présente des interfaces web d'administration comme **Cockpit** et **Webmin**, qui offrent un complément visuel à la ligne de commande pour certaines tâches de supervision et de configuration.

---

## Prérequis

Avant d'aborder ce chapitre, les connaissances suivantes sont attendues :

- Administration système de base sous Debian (Module 3), en particulier la gestion des services avec systemd et la manipulation des fichiers de configuration.
- Gestion des paquets avec APT (Module 4), notamment la configuration des dépôts et l'installation de paquets.
- Notions de réseau et de sécurité (Module 6) : configuration d'interfaces, pare-feu avec nftables, SSH et authentification par clés.
- Maîtrise du shell Bash et capacité à éditer des fichiers de configuration en ligne de commande (vi/vim ou nano).

---

## Conventions utilisées dans ce chapitre

Tout au long de ce chapitre, les commandes exécutées en tant que `root` sont préfixées par `#`, tandis que celles exécutées par un utilisateur standard sont préfixées par `$`. Lorsqu'une commande nécessite une élévation de privilèges ponctuelle, `sudo` est explicitement utilisé.

Les fichiers de configuration sont présentés avec leur chemin absolu et les modifications apportées sont commentées pour en expliquer la finalité. Les valeurs spécifiques à l'environnement (adresses IP, noms d'hôte, noms de domaine) sont remplacées par des valeurs d'exemple clairement identifiables issues des plages réservées à la documentation (RFC 5737 pour les adresses IPv4, `example.com` pour les noms de domaine).

⏭️ [Installation minimale et preseed (installation automatisée)](/module-07-debian-server/01.1-installation-minimale-preseed.md)
