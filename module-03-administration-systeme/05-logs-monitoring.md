🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 3.5 Logs et monitoring de base

## Introduction

Un système Linux sans logs est un système aveugle. Les logs sont la **boîte noire** du serveur : ils enregistrent chaque connexion SSH, chaque erreur d'application, chaque redémarrage de service, chaque alerte du noyau, chaque tentative d'intrusion. Sans eux, un administrateur ne peut ni diagnostiquer une panne passée, ni comprendre l'état actuel du système, ni anticiper les problèmes à venir.

Le **monitoring** prolonge cette capacité dans le temps réel. Là où les logs permettent de comprendre *ce qui s'est passé*, le monitoring permet de voir *ce qui se passe maintenant* et de déclencher des alertes *avant* que la situation ne devienne critique. Un disque qui se remplit progressivement, un service dont le temps de réponse augmente, une charge CPU qui dépasse les seuils habituels — autant de signaux d'alerte que seul un monitoring proactif peut capturer.

Cette section couvre les deux systèmes de journalisation de Debian (rsyslog et journald), les techniques d'analyse de logs en ligne de commande, l'introduction aux outils de monitoring, et les stratégies d'alerting.

## Le paysage de la journalisation sous Debian

### Deux systèmes complémentaires

Un système Debian peut disposer de **deux systèmes de journalisation** qui coexistent et collaborent :

**journald** (`systemd-journald`) — Le journal structuré binaire de systemd, couvert en détail dans la section 3.4.4. Il capture l'intégralité des logs du système dans un format indexé et interrogeable via `journalctl`. C'est le point d'entrée primaire pour tous les messages de log et le **seul système installé par défaut sur Debian Trixie**.

**rsyslog** — Le démon syslog traditionnel qui reçoit les messages de journald et les écrit dans des **fichiers texte** organisés dans `/var/log/`. C'est le système historique, encore indispensable pour de nombreux cas d'usage : outils d'analyse textuelle, exigences d'audit, centralisation vers des serveurs de logs distants, et compatibilité avec les applications et scripts existants.

> **Note Trixie** : depuis Debian 12 (Bookworm), **rsyslog n'est plus installé par défaut**. Sur une installation Trixie minimale, journald est seul en charge de la journalisation, et les fichiers texte décrits ci-dessous (`/var/log/syslog`, `/var/log/auth.log`, etc.) **n'existent pas**. Pour les obtenir, installer explicitement rsyslog : `sudo apt install rsyslog`. Cette section présente les deux systèmes pour couvrir les déploiements hybrides et les serveurs où rsyslog reste utilisé pour des raisons de compatibilité ou d'audit.

```
          ┌─────────────────────────────────────────────┐
          │              Sources de logs                │
          │                                             │
          │  Services    Noyau    Applications  Audit   │
          │  (stdout)  (/dev/kmsg) (syslog())  (audit) │
          └──────────────────┬──────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │    journald     │
                    │ (stockage       │
                    │  binaire        │
                    │  structuré)     │
                    │                 │
                    │ → journalctl    │
                    └────────┬────────┘
                             │
                    forward via socket
                             │
                    ┌────────▼────────┐
                    │    rsyslog      │
                    │ (fichiers       │
                    │  texte dans     │     ┌──────────────────┐
                    │  /var/log/)     │────▶│ Serveur de logs  │
                    │                 │     │ distant (ELK,    │
                    │ → grep, awk,   │     │ Graylog, Loki)   │
                    │   tail, less   │     └──────────────────┘
                    └─────────────────┘
```

### Les fichiers de log traditionnels

Même avec journald, rsyslog continue de produire les fichiers texte historiques dans `/var/log/`. Un administrateur Debian doit connaître les principaux :

| Fichier | Contenu | Qui l'écrit |
|---|---|---|
| `/var/log/syslog` | Messages système généraux (tous les services, noyau) | rsyslog |
| `/var/log/auth.log` | Authentification : SSH, sudo, PAM, login | rsyslog |
| `/var/log/kern.log` | Messages du noyau (équivalent de `dmesg` persistant) | rsyslog |
| `/var/log/daemon.log` | Messages des démons système | rsyslog |
| `/var/log/mail.log` | Messages du sous-système de messagerie (Postfix, Dovecot) | rsyslog |
| `/var/log/cron.log` | Messages liés aux tâches cron (si configuré) | rsyslog |
| `/var/log/user.log` | Messages de priorité « user » | rsyslog |
| `/var/log/debug` | Messages de débogage (si configuré) | rsyslog |
| `/var/log/dpkg.log` | Opérations du gestionnaire de paquets dpkg | dpkg |
| `/var/log/apt/history.log` | Historique des commandes APT | apt |
| `/var/log/apt/term.log` | Sortie terminal des opérations APT | apt |
| `/var/log/faillog` | Échecs de connexion (format binaire, lu par `faillog`) | PAM |
| `/var/log/wtmp` | Historique des sessions (format binaire, lu par `last`) | login/systemd |
| `/var/log/btmp` | Tentatives de connexion échouées (binaire, lu par `lastb`) | login/PAM |
| `/var/log/lastlog` | Dernière connexion par utilisateur (binaire, lu par `lastlog`) | login |

Les services applicatifs créent souvent leurs propres fichiers de log dans `/var/log/` : `/var/log/nginx/`, `/var/log/postgresql/`, `/var/log/mysql/`, etc.

```bash
# Vue d'ensemble de /var/log/
$ ls -lhS /var/log/*.log | head -10
-rw-r----- 1 syslog adm    52M avr 14 11:50 /var/log/syslog
-rw-r----- 1 syslog adm   8.5M avr 14 11:50 /var/log/auth.log
-rw-r----- 1 syslog adm   3.2M avr 14 11:49 /var/log/kern.log
-rw-r----- 1 syslog adm   1.8M avr 14 11:50 /var/log/daemon.log
-rw-r--r-- 1 root   root  420K avr 14 11:30 /var/log/dpkg.log

# Espace total occupé par les logs
$ sudo du -sh /var/log/
256M    /var/log/

# Fichiers de log ouverts par les processus
$ sudo lsof +D /var/log/ 2>/dev/null | head -10
```

## Le protocole syslog

### Concepts fondamentaux

Le protocole **syslog** est le standard de journalisation Unix depuis les années 1980 (formalisé dans les RFC 3164 puis 5424). Même si journald est le collecteur principal sous Debian, le vocabulaire et les concepts syslog restent omniprésents. Chaque message syslog est caractérisé par trois attributs :

**Facility (facilité)** — La catégorie de la source qui a émis le message :

| Code | Nom | Description |
|---|---|---|
| 0 | `kern` | Messages du noyau |
| 1 | `user` | Programmes utilisateur (défaut) |
| 2 | `mail` | Sous-système de messagerie |
| 3 | `daemon` | Démons système |
| 4 | `auth` | Authentification et sécurité |
| 5 | `syslog` | Messages internes de syslog |
| 6 | `lpr` | Impression |
| 7 | `news` | News réseau |
| 9 | `cron` | Tâches planifiées |
| 10 | `authpriv` | Authentification privée (messages sensibles) |
| 16–23 | `local0`–`local7` | Usage local personnalisé |

Les facilities `local0` à `local7` sont librement utilisables par l'administrateur pour catégoriser les applications personnalisées.

**Priority (priorité/severity)** — Le niveau de gravité du message, de 0 (le plus grave) à 7 (le moins grave) :

| Code | Nom | Description | Usage |
|---|---|---|---|
| 0 | `emerg` | Système inutilisable | Panic noyau |
| 1 | `alert` | Action immédiate requise | Base de données corrompue |
| 2 | `crit` | Condition critique | Défaillance matérielle |
| 3 | `err` | Erreur | Erreur de service, échec d'opération |
| 4 | `warning` | Avertissement | Disque presque plein, certificat qui expire |
| 5 | `notice` | Normal mais significatif | Démarrage/arrêt de service |
| 6 | `info` | Information | Connexion réussie, traitement terminé |
| 7 | `debug` | Débogage | Traces détaillées de fonctionnement |

La combinaison facility.priority forme le **sélecteur** syslog, utilisé par rsyslog pour router les messages vers les fichiers appropriés. Par exemple, `auth.warning` sélectionne les messages d'authentification de niveau warning ou plus grave.

**Message** — Le texte du message lui-même, généralement précédé d'un horodatage et du nom d'hôte.

### Format d'un message syslog

Le format traditionnel (RFC 3164) d'une ligne dans `/var/log/syslog` :

```
Apr 14 11:50:30 srv01 sshd[600]: Accepted publickey for alice from 192.168.1.50 port 54321 ssh2
│               │     │     │    │
│               │     │     │    └── Message
│               │     │     └─── PID du processus
│               │     └──── Programme source (tag)
│               └──── Hostname
└──── Horodatage (sans année, sans fuseau horaire — limitation historique)
```

Le format moderne (RFC 5424) ajoute l'année, le fuseau horaire, la priorité structurée et des données structurées optionnelles. journald capture toutes ces informations en natif.

## Pourquoi cette section est essentielle

La maîtrise des logs et du monitoring est sollicitée dans pratiquement tous les scénarios d'administration :

**Dépannage quotidien** — Un service qui ne démarre pas, une connexion SSH refusée, un site web qui retourne des erreurs 500 : le premier réflexe de l'administrateur est de consulter les logs. Savoir où chercher, quoi filtrer et comment interpréter les messages est la compétence de base du diagnostic.

**Sécurité** — Les logs d'authentification révèlent les tentatives d'intrusion (force brute SSH, escalade de privilèges). Le monitoring détecte les comportements anormaux (pic de trafic, processus inconnu, port ouvert inattendu). L'absence de logs ou leur altération est un signal de compromission.

**Conformité et audit** — De nombreuses réglementations (PCI DSS, RGPD, ISO 27001) imposent la conservation des logs sur une durée définie, la surveillance des accès aux données sensibles, et la capacité à produire des traces d'audit sur demande.

**Anticipation** — Le monitoring proactif permet de détecter les tendances avant qu'elles ne deviennent des incidents : un disque qui se remplit à un rythme inhabituel, une augmentation progressive des temps de réponse, ou une mémoire qui ne se libère plus correctement.

**Modules suivants** — Le module 7 (Services) repose sur la capacité à diagnostiquer les services via leurs logs. Le module 15 (Observabilité) approfondit considérablement les concepts introduits ici avec Prometheus, Grafana et les outils d'observabilité cloud-native.

## Concepts clés abordés

Cette section est organisée en quatre sous-sections progressives.

**Système de logs (rsyslog vs journald)** — La comparaison approfondie des deux systèmes de journalisation, leur configuration respective, leurs forces et leurs faiblesses, et les stratégies de coexistence. La configuration de rsyslog (fichier `/etc/rsyslog.conf`, sélecteurs, actions, templates), la rotation des logs avec `logrotate`, et les bonnes pratiques de rétention.

**Analyse des logs (grep, awk, sed)** — Les techniques d'analyse de fichiers texte de log en ligne de commande. L'utilisation de `grep` pour la recherche de motifs, `awk` pour l'extraction et l'agrégation de champs, `sed` pour la transformation de texte, et les combinaisons de ces outils dans des pipelines d'analyse. Les commandes complémentaires (`tail -f`, `less`, `cut`, `sort`, `uniq`, `wc`) et la construction de one-liners pour répondre aux questions courantes de diagnostic.

**Introduction aux outils de monitoring (Nagios, Zabbix)** — Les concepts fondamentaux du monitoring système : les métriques à surveiller (CPU, mémoire, disque, réseau, services), les architectures de monitoring (agent vs agentless, pull vs push), et une introduction aux outils classiques (Nagios/Icinga, Zabbix) qui seront approfondis dans le module 15 avec les outils cloud-native (Prometheus, Grafana).

**Alertes et notifications** — Les mécanismes d'alerte : définition des seuils, canaux de notification (email, SMS, webhook), gestion des faux positifs, et bonnes pratiques pour un alerting efficace qui informe sans submerger.

## Outils principaux utilisés

| Commande / Outil | Rôle |
|---|---|
| `journalctl` | Consultation du journal structuré (couvert en 3.4.4) |
| `rsyslogd` | Démon syslog — routage et stockage des logs texte |
| `logrotate` | Rotation et compression des fichiers de log |
| `grep`, `egrep` | Recherche de motifs dans les fichiers de log |
| `awk` | Extraction, filtrage et agrégation de champs |
| `sed` | Transformation de texte |
| `tail`, `head`, `less` | Navigation dans les fichiers de log |
| `cut`, `sort`, `uniq`, `wc` | Outils de pipeline pour l'analyse |
| `logger` | Envoi de messages syslog depuis le shell |
| `last`, `lastb`, `lastlog` | Historique des connexions |
| `dmesg` | Messages du noyau (ring buffer) |
| `fail2ban` | Protection contre les attaques par force brute (via analyse des logs) |
| Nagios / Icinga | Monitoring d'infrastructure (checks actifs) |
| Zabbix | Monitoring d'infrastructure (agent + server) |

## Prérequis

Pour aborder cette section, les connaissances suivantes sont attendues :

- Maîtrise de `journalctl` et de la journalisation systemd (section 3.4.4).
- Gestion des processus (section 3.3) : savoir identifier les services et leurs PID.
- Gestion des utilisateurs (section 3.2) : comprendre les logs d'authentification.
- Aisance avec le shell Bash et les redirections (pipes, `>`, `>>`, `|`).
- Notions de base des expressions régulières (approfondies dans le module 5).

---

> **Navigation**  
>  
> Section suivante : [3.5.1 Système de logs (rsyslog vs journald)](/module-03-administration-systeme/05.1-rsyslog-vs-journald.md)  
>  
> Retour au module : [Module 3 — Administration système de base](/module-03-administration-systeme.md)

⏭️ [Système de logs (rsyslog vs journald)](/module-03-administration-systeme/05.1-rsyslog-vs-journald.md)
