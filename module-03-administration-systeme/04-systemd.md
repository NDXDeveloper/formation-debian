🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 3.4 systemd en profondeur

## Introduction

systemd est le **système d'initialisation** (init system) et le **gestionnaire de services** de Debian depuis Debian 8 (Jessie), sorti en 2015. Il remplace l'ancien système SysVinit et constitue aujourd'hui le composant central qui orchestre l'intégralité du cycle de vie d'un système Debian : du démarrage à l'arrêt, en passant par la gestion des services, la journalisation, la résolution DNS, la synchronisation de l'horloge, le montage des systèmes de fichiers, la gestion des sessions utilisateur et le contrôle des ressources.

systemd est bien plus qu'un remplaçant de l'ancien `init`. C'est un ensemble intégré de composants qui couvre des fonctions autrefois assurées par une dizaine d'outils séparés. Cette ampleur est à la fois sa force — une administration cohérente et unifiée — et la source de controverses dans la communauté Linux. Quelle que soit l'opinion que l'on porte sur ses choix de conception, sa maîtrise est incontournable pour tout administrateur Debian : c'est le socle sur lequel reposent tous les services et tous les modules suivants de cette formation.

## Pourquoi systemd

### Les limites de SysVinit

L'ancien système d'initialisation SysVinit (utilisé par Debian de sa création jusqu'à Debian 7) était basé sur des **scripts shell séquentiels** stockés dans `/etc/init.d/`. Chaque service possédait un script de démarrage/arrêt, et ces scripts étaient exécutés dans un ordre numéroté via des liens symboliques dans `/etc/rc*.d/`.

Ce modèle, bien que simple et transparent, souffrait de plusieurs limitations devenues critiques sur les systèmes modernes :

**Démarrage séquentiel** — Les scripts s'exécutaient l'un après l'autre, dans un ordre figé. Sur un serveur avec de nombreux services, le démarrage pouvait durer plusieurs minutes. Aucune parallélisation n'était possible sans des modifications complexes.

**Gestion des dépendances manuelle** — L'ordre de démarrage était défini par des numéros (S01, S02, S20...) dans les liens symboliques. Les dépendances entre services n'étaient pas formalisées : si un service avait besoin du réseau, l'administrateur devait s'assurer manuellement que le script réseau s'exécutait avant.

**Supervision inexistante** — SysVinit lançait un service et l'oubliait. Si un démon crashait, personne ne le redémarrait automatiquement. Des outils tiers (monit, supervisord, daemontools) étaient nécessaires pour la supervision.

**PID files fragiles** — La détection de l'état d'un service reposait sur des fichiers PID (`/var/run/service.pid`), susceptibles de devenir obsolètes (stale PID files) en cas de crash, menant à des diagnostics erronés.

**Pas de contrôle des ressources** — Aucun mécanisme intégré pour limiter la consommation CPU, mémoire ou I/O d'un service.

**Environnement shell complet** — Chaque script init pouvait exécuter du code arbitraire, rendant le comportement difficile à prédire, à auditer et à paralléliser.

### Ce que systemd apporte

systemd résout ces limitations par une approche fondamentalement différente :

**Démarrage parallèle** — systemd analyse le graphe de dépendances entre les unités et lance en parallèle tout ce qui peut l'être. Le démarrage d'un serveur Debian moderne prend typiquement quelques secondes.

**Dépendances déclaratives** — Les dépendances entre services sont déclarées explicitement dans les fichiers d'unité (`Requires=`, `After=`, `Wants=`). systemd construit un graphe et résout automatiquement l'ordre de démarrage.

**Supervision native** — systemd surveille les processus qu'il lance. Si un service crashe, systemd le détecte immédiatement et peut le redémarrer automatiquement (`Restart=on-failure`).

**Tracking par cgroups** — Chaque service est placé dans son propre cgroup (section 3.3.4). systemd sait exactement quels processus appartiennent à quel service, même si le service fork plusieurs fois. Plus besoin de fichiers PID.

**Contrôle des ressources intégré** — Les limites de CPU, mémoire, I/O et nombre de processus sont configurables directement dans les fichiers d'unité via les directives cgroups v2.

**Configuration déclarative** — Les fichiers d'unité utilisent un format INI simple et déclaratif, plus facile à lire, à auditer et à générer que des scripts shell.

**Journalisation structurée** — Le composant journald capture les logs de tous les services dans un format binaire structuré, interrogeable avec des filtres précis via `journalctl`.

## Périmètre de systemd

systemd n'est pas un programme unique mais un **écosystème de composants** partageant une architecture commune. Voici les principaux composants que l'on rencontre sur un système Debian :

| Composant | Rôle | Binaire |
|---|---|---|
| **systemd** (PID 1) | Init système, gestionnaire de services, orchestrateur | `/lib/systemd/systemd` |
| **systemctl** | Outil CLI de contrôle des services et du système | `/usr/bin/systemctl` |
| **journald** | Démon de journalisation structurée | `systemd-journald` |
| **journalctl** | Outil CLI de consultation des logs | `/usr/bin/journalctl` |
| **networkd** | Gestion réseau (alternative à NetworkManager) | `systemd-networkd` |
| **resolved** | Résolution DNS locale avec cache | `systemd-resolved` |
| **timesyncd** | Synchronisation NTP simplifiée | `systemd-timesyncd` |
| **logind** | Gestion des sessions utilisateur, des sièges et des inhibiteurs | `systemd-logind` |
| **udevd** | Gestionnaire de périphériques (détection hotplug, règles) | `systemd-udevd` |
| **tmpfiles** | Création et nettoyage de fichiers/répertoires temporaires | `systemd-tmpfiles` |
| **sysusers** | Création automatique d'utilisateurs système | `systemd-sysusers` |
| **hostnamed** | Gestion du nom d'hôte | `systemd-hostnamed` |
| **timedated** | Gestion du fuseau horaire et de l'horloge | `systemd-timedated` |
| **localed** | Gestion des locales et du clavier | `systemd-localed` |
| **machinectl** | Gestion de conteneurs légers (systemd-nspawn) | `/usr/bin/machinectl` |
| **coredumpctl** | Gestion des core dumps | `/usr/bin/coredumpctl` |
| **systemd-cgtop** | Surveillance des cgroups | `/usr/bin/systemd-cgtop` |
| **systemd-analyze** | Analyse du démarrage et des performances | `/usr/bin/systemd-analyze` |

Sur une installation standard de Debian 13, la majorité de ces composants sont actifs. Certains sont optionnels (networkd, resolved) et remplaçables par des alternatives (NetworkManager, dnsmasq, chrony).

## Le concept central : les unités

Le concept fondamental de systemd est l'**unité** (unit). Une unité est une ressource que systemd sait gérer : un service, un point de montage, un socket, un timer, un périphérique, etc. Chaque unité est décrite par un **fichier d'unité** (unit file) au format INI.

systemd reconnaît onze types d'unités, identifiables par leur suffixe :

| Type | Suffixe | Rôle |
|---|---|---|
| **Service** | `.service` | Processus ou démon à gérer (le type le plus courant) |
| **Socket** | `.socket` | Socket d'écoute (activation par socket) |
| **Timer** | `.timer` | Planification de tâches (alternative à cron) |
| **Mount** | `.mount` | Point de montage (généré depuis fstab ou déclaré manuellement) |
| **Automount** | `.automount` | Montage automatique à la demande |
| **Target** | `.target` | Groupe logique d'unités (point de synchronisation) |
| **Device** | `.device` | Périphérique détecté par udev |
| **Swap** | `.swap` | Espace de swap |
| **Path** | `.path` | Surveillance de chemin (activation quand un fichier apparaît/change) |
| **Slice** | `.slice` | Groupe de cgroups pour le contrôle des ressources |
| **Scope** | `.scope` | Groupe de processus externes (non lancés par systemd) |

Les sections suivantes de ce chapitre couvrent en détail les services, les timers, les targets et les interactions avec le réseau et la journalisation. Les unités mount et automount ont été abordées en section 3.1.4.

## Emplacements des fichiers d'unité

Les fichiers d'unité sont répartis dans trois emplacements, par ordre de priorité croissante :

| Emplacement | Priorité | Rôle |
|---|---|---|
| `/usr/lib/systemd/system/` | Basse | Fichiers fournis par les paquets Debian. Ne jamais les modifier directement. |
| `/etc/systemd/system/` | Haute | Fichiers de l'administrateur et overrides. Prioritaires sur `/usr/lib`. |
| `/run/systemd/system/` | Intermédiaire | Fichiers transitoires (générés à l'exécution, perdus au redémarrage). |

> **Note Trixie** : depuis l'usrmerge (Debian 12+), `/lib/systemd/system/` est un lien symbolique vers `/usr/lib/systemd/system/`. Les deux chemins fonctionnent et désignent la même chose. Les sorties de commandes peuvent afficher l'un ou l'autre selon les versions des paquets.

Quand un fichier d'unité existe au même nom dans `/etc/systemd/system/` et `/lib/systemd/system/`, c'est celui de `/etc` qui est utilisé. Ce mécanisme permet à l'administrateur de personnaliser n'importe quel service sans toucher aux fichiers livrés par les paquets — les modifications survivent aux mises à jour du paquet.

Les fichiers de l'utilisateur (services au niveau utilisateur, gérés par l'instance `systemd --user`) se trouvent dans `~/.config/systemd/user/`.

```bash
# Trouver le fichier d'unité d'un service
$ systemctl show -p FragmentPath nginx.service
FragmentPath=/lib/systemd/system/nginx.service

# Lister les fichiers d'unité modifiés par l'administrateur
$ systemd-delta --type=overridden,extended,masked
```

## Interaction quotidienne avec `systemctl`

`systemctl` est la commande d'interface avec systemd. C'est l'outil que l'administrateur utilise le plus fréquemment. Voici un aperçu des opérations quotidiennes avant d'entrer dans le détail des sous-sections :

```bash
# Gestion d'un service
$ sudo systemctl start nginx           # Démarrer
$ sudo systemctl stop nginx            # Arrêter
$ sudo systemctl restart nginx         # Redémarrer
$ sudo systemctl reload nginx          # Recharger la configuration
$ sudo systemctl status nginx          # État détaillé
$ sudo systemctl enable nginx          # Activer au démarrage
$ sudo systemctl disable nginx         # Désactiver au démarrage
$ sudo systemctl enable --now nginx    # Activer ET démarrer immédiatement

# Consultation
$ systemctl list-units --type=service            # Services actifs
$ systemctl list-units --type=service --all      # Tous les services
$ systemctl list-unit-files --type=service       # État d'activation
$ systemctl is-active nginx                      # Vérification rapide
$ systemctl is-enabled nginx                     # Activé au démarrage ?
$ systemctl is-failed nginx                      # En échec ?

# Système
$ sudo systemctl reboot                # Redémarrer la machine
$ sudo systemctl poweroff              # Arrêter la machine
$ systemctl list-dependencies nginx    # Arbre de dépendances
```

## Concepts clés abordés

Cette section est organisée en six sous-sections qui couvrent progressivement l'ensemble des compétences systemd nécessaires à un administrateur Debian.

**Architecture de systemd et concepts fondamentaux** — Le processus de démarrage de Debian (du BIOS/UEFI au multi-user.target), le graphe de dépendances, les types d'unités, le format des fichiers d'unité, et les commandes `systemctl` fondamentales. L'outil `systemd-analyze` pour comprendre et optimiser le boot.

**Unités, targets et dépendances** — Les targets comme points de synchronisation (équivalent des runlevels SysVinit), les mécanismes de dépendances (`Requires`, `Wants`, `After`, `Before`, `Conflicts`), la résolution du graphe, et les dépendances implicites.

**Création et gestion de services personnalisés** — La rédaction de fichiers `.service` pour des applications personnalisées, les types de services (`simple`, `forking`, `oneshot`, `notify`), les options de sécurité et de sandboxing, le mécanisme d'override avec `systemctl edit`, et le rechargement avec `daemon-reload`.

**journald : configuration et exploitation des logs** — L'architecture de la journalisation structurée, la commande `journalctl` avec ses filtres puissants, la persistance des logs, la rotation, le forwarding vers rsyslog, et les stratégies de journalisation en production.

**systemd-networkd, systemd-resolved, systemd-timesyncd** — Les composants réseau de systemd : la gestion des interfaces avec networkd, la résolution DNS avec resolved, et la synchronisation de l'horloge avec timesyncd. Leur place dans l'écosystème Debian par rapport aux alternatives (NetworkManager, chrony, unbound).

**Timers systemd (alternative à cron)** — Les unités `.timer` comme alternative moderne à cron, avec les timers monotones et calendaires, la syntaxe `OnCalendar`, la gestion des exécutions manquées, et la comparaison avec cron.

## Prérequis

Pour aborder cette section, les connaissances suivantes sont attendues :

- Gestion des processus (section 3.3) : PID, signaux, états des processus, cgroups.
- Gestion des utilisateurs (section 3.2) : comptes système, groupes, sudo.
- Système de fichiers (section 3.1) : montage, fstab, permissions, liens symboliques.
- Aisance avec l'édition de fichiers de configuration en ligne de commande.

## Outils principaux utilisés

| Commande / Outil | Rôle |
|---|---|
| `systemctl` | Contrôle des unités et du système |
| `journalctl` | Consultation et filtrage des logs |
| `systemd-analyze` | Analyse du démarrage et des dépendances |
| `systemd-cgtop` | Surveillance des cgroups par service |
| `systemd-cgls` | Arbre des cgroups |
| `systemd-delta` | Différences entre fichiers d'unité système et overrides |
| `systemd-cat` | Envoyer la sortie d'une commande dans journald |
| `systemd-run` | Lancer un processus comme unité transitoire |
| `systemd-tmpfiles` | Gestion des fichiers temporaires |
| `networkctl` | Contrôle de systemd-networkd |
| `resolvectl` | Contrôle de systemd-resolved |
| `timedatectl` | Contrôle de l'horloge et du fuseau horaire |
| `hostnamectl` | Contrôle du nom d'hôte |
| `loginctl` | Contrôle des sessions utilisateur |
| `busctl` | Introspection du bus D-Bus système |

---

> **Navigation**  
>  
> Section suivante : [3.4.1 Architecture de systemd et concepts fondamentaux](/module-03-administration-systeme/04.1-architecture-systemd.md)  
>  
> Retour au module : [Module 3 — Administration système de base](/module-03-administration-systeme.md)

⏭️ [Architecture de systemd et concepts fondamentaux](/module-03-administration-systeme/04.1-architecture-systemd.md)
