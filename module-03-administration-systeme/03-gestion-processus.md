🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 3.3 Gestion des processus

## Introduction

Un système Linux en fonctionnement est un ensemble de **processus** — des programmes en cours d'exécution. Chaque commande tapée dans un terminal, chaque service qui écoute sur le réseau, chaque tâche planifiée, le gestionnaire de bureau graphique, le noyau lui-même via ses threads internes : tout prend la forme d'un ou plusieurs processus. Sur un serveur Debian en production, il n'est pas rare de trouver plusieurs centaines de processus actifs simultanément.

L'administrateur système doit savoir observer ces processus pour comprendre l'état du système, les manipuler pour résoudre des problèmes (un service qui ne répond plus, une tâche qui consomme toutes les ressources), et contrôler leur priorité pour garantir que les charges de travail critiques disposent des ressources nécessaires. La gestion des processus est une compétence transversale, mobilisée quotidiennement dans le diagnostic, le dépannage et l'optimisation.

## Qu'est-ce qu'un processus

### Définition

Un **processus** est une instance d'un programme en cours d'exécution. Un programme est un fichier statique sur le disque (un binaire, un script) ; un processus est ce programme chargé en mémoire, avec son propre espace d'adressage, ses descripteurs de fichiers ouverts, ses variables d'environnement et son état d'exécution.

Un même programme peut engendrer plusieurs processus indépendants. Par exemple, si trois utilisateurs lancent simultanément `/usr/bin/vim`, le système crée trois processus distincts, chacun avec sa propre zone mémoire et son propre état, mais tous exécutant le même code binaire.

### Identifiants d'un processus

Chaque processus est caractérisé par plusieurs identifiants :

| Identifiant | Description |
|---|---|
| **PID** (Process ID) | Numéro unique attribué séquentiellement par le noyau. Le premier processus (init/systemd) porte le PID 1. |
| **PPID** (Parent PID) | PID du processus qui a créé ce processus (son parent). |
| **UID / EUID** | Identifiant de l'utilisateur réel / effectif sous lequel le processus s'exécute. |
| **GID / EGID** | Identifiant du groupe réel / effectif. |
| **SID** (Session ID) | Identifiant de la session (groupe de processus lié à un terminal). |
| **PGID** (Process Group ID) | Identifiant du groupe de processus (utilisé pour les pipelines). |
| **TID** (Thread ID) | Identifiant de thread (pour les processus multi-threadés). |

```bash
# Afficher les identifiants du shell courant
$ echo "PID: $$, PPID: $PPID"
PID: 1234, PPID: 1100

# Vue complète via /proc
$ cat /proc/self/status | head -10
Name:   cat  
Umask:  0022  
State:  R (running)  
Tgid:   5678  
Ngid:   0  
Pid:    5678  
PPid:   1234  
TracerPid:      0  
Uid:    1001    1001    1001    1001  
Gid:    1001    1001    1001    1001  
```

### Le modèle parent-enfant

Linux organise les processus en une **hiérarchie arborescente**. Chaque processus (sauf le premier) est créé par un processus parent via l'appel système `fork()`. Le processus enfant est une copie du parent, qui exécute ensuite un nouveau programme via `exec()`.

Au sommet de l'arbre se trouve **systemd** (PID 1), le premier processus lancé par le noyau. Tous les autres processus en descendent directement ou indirectement :

```bash
# Visualiser l'arbre des processus
$ pstree -p | head -20
systemd(1)─┬─accounts-daemon(456)─┬─{accounts-daemon}(457)
            │                     └─{accounts-daemon}(458)
            ├─agetty(789)
            ├─cron(512)
            ├─dbus-daemon(490)
            ├─networkd-dispat(520)
            ├─sshd(600)───sshd(1100)───bash(1234)───pstree(5679)
            ├─systemd-journal(210)─┬─{systemd-journal}(211)
            │                      └─{systemd-journal}(212)
            ├─systemd-logind(495)
            ├─systemd-resolve(380)
            └─systemd-timesyn(381)
```

Dans cet exemple, on voit clairement la chaîne : `systemd(1)` → `sshd(600)` → `sshd(1100)` → `bash(1234)` → `pstree(5679)`. Le processus `pstree` a été lancé depuis un shell `bash`, lui-même issu d'une connexion SSH.

### Processus orphelins et reparentage

Quand un processus parent se termine avant ses enfants, ces derniers deviennent **orphelins**. Le noyau les rattache automatiquement à systemd (PID 1) ou au sous-récoleur (subreaper) le plus proche, qui prend en charge la collecte de leur statut de sortie. Ce mécanisme garantit qu'aucun processus ne reste indéfiniment dans un état intermédiaire.

### Processus zombies

Un processus **zombie** est un processus qui a terminé son exécution mais dont le statut de sortie n'a pas encore été collecté par son parent (via l'appel système `wait()`). Le zombie n'occupe plus de mémoire ni de CPU — il ne conserve qu'une entrée dans la table des processus. En temps normal, les zombies sont rapidement éliminés par le parent. Un nombre croissant de zombies indique un bug dans le processus parent (qui ne collecte pas ses enfants).

```bash
# Repérer les processus zombies
$ ps aux | awk '$8 ~ /Z/ {print}'
# La colonne STAT contient "Z" pour les zombies
```

Les zombies ne peuvent pas être tués par `kill` (ils sont déjà morts). La seule solution est de tuer leur processus parent, ce qui provoque le reparentage vers systemd, qui collecte immédiatement leur statut.

## États d'un processus

Le noyau Linux maintient chaque processus dans l'un des états suivants :

| Code | État | Description |
|---|---|---|
| **R** | Running / Runnable | En cours d'exécution sur un CPU, ou prêt à s'exécuter (dans la file d'attente du scheduler). |
| **S** | Sleeping (interruptible) | En attente d'un événement (lecture disque, entrée réseau, signal). Peut être réveillé par un signal. |
| **D** | Disk sleep (uninterruptible) | En attente d'une opération d'E/S (typiquement disque ou NFS). **Ne peut pas être interrompu ni tué.** |
| **T** | Stopped | Arrêté par un signal (`SIGSTOP`, `SIGTSTP` — Ctrl+Z). Peut être repris par `SIGCONT`. |
| **t** | Tracing stop | Arrêté par un débogueur (ptrace). |
| **Z** | Zombie | Terminé mais en attente de la collecte de son statut par le parent. |
| **I** | Idle | Thread noyau inactif (depuis le noyau 4.14). |

L'état **D** (uninterruptible sleep) mérite une attention particulière. Un processus dans cet état ne peut pas être tué, même avec `kill -9`. C'est une protection du noyau : le processus est au milieu d'une opération d'E/S critique qui ne peut pas être interrompue sans risquer de corrompre des données. Un grand nombre de processus en état D est le signe d'un problème de stockage (disque défaillant, montage NFS qui ne répond plus, contrôleur saturé).

```bash
# Trouver les processus en état D (uninterruptible sleep)
$ ps aux | awk '$8 ~ /D/ {print}'
```

## Processus, threads et fork

### Processus vs threads

Un **processus** possède son propre espace d'adressage mémoire, isolé des autres processus. Un **thread** (ou lightweight process) partage l'espace d'adressage de son processus parent avec les autres threads du même processus.

Le noyau Linux traite les threads comme des processus légers : chaque thread a son propre PID (visible comme TID), mais les threads d'un même processus partagent le même TGID (Thread Group ID), qui correspond au PID du processus principal. Dans la sortie de `ps`, les threads sont souvent masqués par défaut.

```bash
# Afficher les threads d'un processus (exemple : systemd-journald)
$ ps -T -p $(pgrep -f systemd-journald)
    PID    SPID TTY          TIME CMD
    210     210 ?        00:00:01 systemd-journal
    210     211 ?        00:00:00 systemd-journal
    210     212 ?        00:00:00 systemd-journal
# 3 threads dans le processus systemd-journald (PID 210)
```

### Le mécanisme fork/exec

La création d'un processus sous Linux suit un schéma en deux étapes :

1. **`fork()`** — Le processus parent se duplique. Le noyau crée un processus enfant qui est une copie quasi identique du parent (même code, mêmes données, mêmes descripteurs de fichiers). Grâce au mécanisme de **Copy-on-Write** (CoW), les pages mémoire ne sont réellement dupliquées que lorsqu'elles sont modifiées — le fork est donc une opération légère.

2. **`exec()`** — Le processus enfant remplace son code par celui d'un nouveau programme. L'espace mémoire est rechargé avec le binaire du programme à exécuter.

Quand un shell exécute une commande, il appelle `fork()` pour créer un enfant, puis l'enfant appelle `exec()` pour charger le programme demandé. Le shell (parent) attend la fin de l'enfant via `wait()`.

## Les ressources d'un processus

Chaque processus consomme un ensemble de ressources système que l'administrateur doit surveiller :

**Mémoire** — La mémoire virtuelle allouée au processus (VSZ — Virtual Size) inclut tout l'espace d'adressage, y compris les bibliothèques partagées et les pages non encore chargées. La mémoire résidente (RSS — Resident Set Size) est la mémoire physiquement utilisée en RAM. La distinction est importante : un processus peut avoir un VSZ de 2 Go mais un RSS de 50 Mo si la majeure partie de son espace d'adressage n'est pas chargée en mémoire physique.

**CPU** — Le temps CPU consommé par un processus, en mode utilisateur (user) et en mode noyau (system). Le pourcentage CPU indique la proportion de temps CPU sur un intervalle récent. Sur un système multi-cœurs, un processus peut afficher plus de 100 % s'il utilise plusieurs cœurs.

**Descripteurs de fichiers** — Chaque fichier ouvert, chaque socket réseau, chaque pipe consomme un descripteur de fichier. Le nombre maximum par processus est limité (configurable via `ulimit` et `pam_limits`).

**Entrées/sorties** — Les opérations de lecture et d'écriture vers les disques et le réseau. Un processus qui effectue beaucoup d'I/O peut saturer le système de stockage et impacter tous les autres processus.

## Le pseudo-système de fichiers `/proc`

Le répertoire `/proc` (vu en section 3.1.1) expose les informations de chaque processus via un répertoire numéroté par PID :

```bash
$ ls /proc/1234/
attr/       cmdline   environ  io        mem        oom_score      root      stat     task/  
cgroup      comm      exe      limits    mountinfo  oom_score_adj  sched     statm    timers  
clear_refs  coredump  fd/      loginuid  mounts     pagemap        schedstat status   wchan  
...

# Commande complète ayant lancé le processus
$ cat /proc/1234/cmdline | tr '\0' ' '
/usr/bin/python3 /srv/app/main.py --port=8080

# Variables d'environnement du processus
$ cat /proc/1234/environ | tr '\0' '\n' | head

# Descripteurs de fichiers ouverts
$ ls -l /proc/1234/fd/
lrwx------ 1 alice alice 0 avr 14 10:00 0 -> /dev/pts/0  
lrwx------ 1 alice alice 0 avr 14 10:00 1 -> /dev/pts/0  
lrwx------ 1 alice alice 0 avr 14 10:00 2 -> /dev/pts/0  
lr-x------ 1 alice alice 0 avr 14 10:00 3 -> /srv/app/config.yml  
lrwx------ 1 alice alice 0 avr 14 10:00 4 -> socket:[45678]  

# Limites de ressources du processus
$ cat /proc/1234/limits
Limit                     Soft Limit  Hard Limit  Units  
Max open files            4096        65536       files  
Max processes             1024        4096        processes  
Max address space         unlimited   unlimited   bytes  

# Utilisation mémoire
$ cat /proc/1234/status | grep -E "^(Vm|Rss|Threads)"
VmPeak:   256000 kB  
VmSize:   248000 kB  
VmRSS:     52000 kB  
RssAnon:   38000 kB  
RssFile:   14000 kB  
Threads:        4  
```

Ce répertoire est une mine d'informations pour le diagnostic avancé. Les outils comme `ps`, `top` et `htop` lisent ces fichiers pour produire leur affichage.

## Pourquoi cette section est essentielle

La gestion des processus est sollicitée dans de nombreux contextes d'administration Debian :

**Diagnostic de performance** — Un serveur qui ralentit nécessite d'identifier quel processus consomme le CPU, la mémoire ou les I/O. Les commandes `top`, `htop`, `iotop` et les informations de `/proc` permettent ce diagnostic.

**Gestion des services** — Comprendre le cycle de vie des processus est le prérequis pour la section 3.4 sur systemd. Un service qui « crashe » est un processus qui se termine de manière inattendue. Un service qui « ne répond plus » est un processus bloqué (état D ou boucle infinie).

**Contrôle des ressources** — Sur un serveur partagé, les cgroups v2 (abordés dans cette section) et les limites de processus permettent d'isoler les charges de travail et de prévenir qu'un processus accapare toutes les ressources.

**Sécurité** — Un processus inconnu qui consomme du CPU peut être le signe d'une compromission (cryptominer, backdoor). Savoir lister, identifier et analyser les processus est une compétence de base en réponse aux incidents.

## Concepts clés abordés

Cette section est organisée en quatre sous-sections progressives.

**Commandes ps, top, htop** — Les outils fondamentaux d'observation des processus. `ps` pour les instantanés statiques et les analyses scriptables, `top` pour la surveillance interactive en temps réel, et `htop` pour une vue améliorée avec navigation et filtrage. La lecture et l'interprétation des colonnes (PID, USER, %CPU, %MEM, VSZ, RSS, STAT, TIME, COMMAND) sont détaillées.

**Signaux et kill** — Le mécanisme de communication inter-processus par signaux. Les signaux courants (`SIGTERM`, `SIGKILL`, `SIGHUP`, `SIGUSR1`), les commandes `kill`, `killall` et `pkill`, et les stratégies de terminaison propre d'un processus récalcitrant.

**Jobs et processus en arrière-plan** — Le contrôle des tâches dans le shell : exécution en arrière-plan (`&`), `Ctrl+Z`, `bg`, `fg`, `jobs`, et les mécanismes pour détacher un processus du terminal (`nohup`, `disown`, `screen`, `tmux`).

**Priorités et ordonnancement (nice, ionice, cgroups v2)** — Le contrôle de la répartition des ressources entre processus. Les priorités CPU avec `nice` et `renice`, les priorités d'I/O avec `ionice`, et le mécanisme moderne des cgroups v2 pour le contrôle granulaire des ressources (CPU, mémoire, I/O) par groupes de processus.

## Outils principaux utilisés

| Commande / Outil | Rôle |
|---|---|
| `ps` | Instantané des processus (scriptable) |
| `top` | Surveillance interactive en temps réel |
| `htop` | Surveillance interactive améliorée |
| `pstree` | Arbre des processus |
| `kill`, `killall`, `pkill` | Envoi de signaux aux processus |
| `nice`, `renice` | Gestion des priorités CPU |
| `ionice` | Gestion des priorités d'E/S |
| `jobs`, `bg`, `fg` | Contrôle des tâches du shell |
| `nohup`, `disown` | Détacher un processus du terminal |
| `lsof` | Lister les fichiers ouverts par les processus |
| `strace` | Tracer les appels système d'un processus |
| `/proc/PID/` | Informations détaillées par processus |
| `systemd-cgtop` | Surveillance des cgroups en temps réel |

## Prérequis

Pour aborder cette section, les connaissances suivantes sont attendues :

- Maîtrise du shell Bash et du terminal (section 3.1, modules 1 et 2).
- Compréhension du modèle utilisateur/groupe (section 3.2) : les processus s'exécutent sous une identité.
- Connaissance de `/proc` comme système de fichiers virtuel (section 3.1.1).
- Accès à un système Debian avec des processus actifs (serveur avec services, ou poste de travail).

---

> **Navigation**  
>  
> Section suivante : [3.3.1 Commandes ps, top, htop](/module-03-administration-systeme/03.1-ps-top-htop.md)  
>  
> Retour au module : [Module 3 — Administration système de base](/module-03-administration-systeme.md)

⏭️ [Commandes ps, top, htop](/module-03-administration-systeme/03.1-ps-top-htop.md)
