🔝 Retour au [Sommaire](/SOMMAIRE.md) · [Module 3](/module-03-administration-systeme.md)

# Scripts du Module 3 — Administration système

Ce dossier rassemble les **scripts shell, configurations systemd, configs PAM/sudoers/rsyslog/monit** présentés dans le module 3, prêts à être téléchargés et adaptés.

Chaque fichier est extrait du `.md` qui le présente dans son contexte pédagogique. Le `.md` reste la **source narrative** ; les fichiers de ce dossier en sont les **livrables exécutables**.

---

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

- `XX.Y` correspond exactement au numéro de **sous-section** dans la formation (ex. `04.6` = section 3.4.6).
- `nom-court-kebab` est descriptif, en minuscules avec tirets.
- `<ext>` est `.sh`, `.service`, `.timer`, `.path`, `.network`, `.netdev`, `.conf`, ou un nom de fichier (sudoers, monit, msmtprc).

Cette convention garantit que `ls` reflète l'ordre du cours, et que la section d'origine se lit immédiatement.

---

## Organisation

```
scripts/
├── README.md                 ← ce fichier
├── 01-systeme-fichiers/      ← Section 3.1 (vide pour le module 03)
├── 02-utilisateurs/          ← Section 3.2 — PAM, sudoers, SSSD, scripts utilisateurs
├── 03-processus/             ← Section 3.3 — patterns trap/signaux
├── 04-systemd/               ← Section 3.4 — services, timers, networkd, journald
└── 05-logs-monitoring/       ← Section 3.5 — rsyslog, alertes, notifications
```

Chaque fichier commence par un **en-tête normalisé** :

```
# Nom         : <fichier>
# Module      : 3 — Administration système
# Section     : <numéro-section> — <titre-section>
# Source      : module-03-administration-systeme/<fichier-source>.md
# Description : <description courte>
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
```

---

## Utilisation générale

### Préparation

```bash
git clone https://github.com/NDXDeveloper/formation-debian.git  
cd formation-debian/module-03-administration-systeme/scripts  

# Lire avant d'exécuter
less 03-processus/03.2-graceful-kill.sh
```

### Déploiement type d'un service systemd

```bash
# Copier l'unit dans /etc/systemd/system/
sudo cp 04-systemd/04.6-healthcheck.service /etc/systemd/system/  
sudo cp 04-systemd/04.6-healthcheck.timer /etc/systemd/system/  

# Recharger systemd, valider, activer
sudo systemctl daemon-reload  
sudo systemd-analyze verify /etc/systemd/system/04.6-healthcheck.service  
sudo systemctl enable --now 04.6-healthcheck.timer  
sudo systemctl list-timers  
```

### Validation locale

```bash
# Bash
bash -n 03-processus/03.2-graceful-kill.sh  
shellcheck 03-processus/03.2-graceful-kill.sh  

# systemd units
systemd-analyze verify 04-systemd/04.6-backup-donnees.service

# sudoers (jamais directement sur /etc/sudoers !)
sudo visudo -cf 02-utilisateurs/02.4-sudoers-deploiement

# rsyslog
sudo rsyslogd -N1 -f 05-logs-monitoring/05.1-rsyslog-mon-application.conf
```

---

## Index des fichiers

### 02-utilisateurs/ — Utilisateurs, PAM, sudoers, SSSD

| Fichier | Section | Description |
|---|---|---|
| `02.1-create-users-csv.sh` | 3.2.1 | Création d'utilisateurs en lot depuis un CSV (`login,nom,groupes`) |
| `02.3-pam-limits.conf` | 3.2.3 | Limites système PAM (processus, fichiers ouverts, mémoire) |
| `02.3-pam-access.conf` | 3.2.3 | Restrictions d'accès PAM par utilisateur/groupe/terminal |
| `02.3-pam-time.conf` | 3.2.3 | Restrictions horaires d'accès aux comptes |
| `02.4-sudoers-admins` | 3.2.4 | Profil sudo administrateurs |
| `02.4-sudoers-deploiement` | 3.2.4 | Profil sudo CI/CD (commandes scoped) |
| `02.4-sudoers-monitoring` | 3.2.4 | Profil sudo monitoring (lecture seule) |
| `02.4-sudoers-dba` | 3.2.4 | Profil sudo DBA (PostgreSQL/MySQL + logs) |
| `02.4-sudoers-restreint` | 3.2.4 | Exemple restrictif (un seul outil, NOPASSWD strict) |
| `02.5-sssd.conf` | 3.2.5 | Configuration SSSD complète (LDAP/FreeIPA/AD + cache) |

### 03-processus/ — Signaux, trap, contrôle de processus

| Fichier | Section | Description |
|---|---|---|
| `03.2-graceful-kill.sh` | 3.3.2 | Terminaison propre : SIGTERM puis SIGKILL après timeout |
| `03.2-cleanup-trap-pattern.sh` | 3.3.2 | Pattern complet : nettoyage TMPFILE + libération lockfile |
| `03.2-sighup-reload.sh` | 3.3.2 | Démon qui recharge sa config sur SIGHUP |
| `03.2-mktemp-trap-exit.sh` | 3.3.2 | Pattern minimal `mktemp -d` + `trap EXIT` |

### 04-systemd/ — Services, timers, network, journald

| Fichier | Section | Description |
|---|---|---|
| `04.2-surveillance-uploads.path` | 3.4.2 | Path unit qui surveille un répertoire |
| `04.2-surveillance-uploads.service` | 3.4.2 | Service appelé par la path unit |
| `04.3-mon-app-minimal.service` | 3.4.3 | Service systemd minimal (Type=simple) |
| `04.3-mon-app-complet.service` | 3.4.3 | Service complet et durci (sandboxing exhaustif) |
| `04.3-mon-app-wrapper.sh` | 3.4.3 | Wrapper Type=forking (exec en arrière-plan) |
| `04.3-watchdog-wrapper.sh` | 3.4.3 | Wrapper Type=notify avec systemd-notify et watchdog |
| `04.3-webapp@.service` | 3.4.3 | Service template (instanciable : `webapp@instance1.service`) |
| `04.4-journald.conf` | 3.4.4 | Config globale de systemd-journald |
| `04.4-journald-storage.conf` | 3.4.4 | Drop-in pour stockage persistant + rotation |
| `04.4-journal-maintenance.sh` | 3.4.4 | Maintenance journald (vérif intégrité + alerte) |
| `04.5-ethernet-dhcp.network` | 3.4.5 | Interface Ethernet DHCP |
| `04.5-ethernet-static.network` | 3.4.5 | Interface Ethernet IP statique + gateway + DNS |
| `04.5-ethernet-multi-ip.network` | 3.4.5 | Interface avec plusieurs IPs (alias) |
| `04.5-bridge-br0.netdev` | 3.4.5 | Définition d'un bridge réseau (br0) |
| `04.5-bridge-br0-bind.network` | 3.4.5 | Attachement d'une interface au bridge |
| `04.5-bridge-br0-ip.network` | 3.4.5 | IP du bridge br0 |
| `04.5-vlan100.netdev` | 3.4.5 | VLAN tagué (ID=100) |
| `04.5-vlans-parent.network` | 3.4.5 | Interface parente déclarant les VLANs enfants |
| `04.5-vlan100-ip.network` | 3.4.5 | IP statique sur le VLAN 100 |
| `04.5-bond0.netdev` | 3.4.5 | Bonding LACP entre plusieurs interfaces |
| `04.5-bond0-members.network` | 3.4.5 | Attachement des interfaces physiques au bonding |
| `04.5-bond0-ip.network` | 3.4.5 | IP du bonding bond0 |
| `04.5-resolved-custom.conf` | 3.4.5 | Personnalisation systemd-resolved (DNS, DNSSEC, fallback) |
| `04.5-vpn-routes.network` | 3.4.5 | Routes statiques pour interface VPN |
| `04.5-timesyncd-custom.conf` | 3.4.5 | Configuration des serveurs NTP |
| `04.5-migration-to-networkd.sh` | 3.4.5 | Migration ifupdown/NetworkManager → systemd-networkd |
| `04.6-healthcheck.timer` | 3.4.6 | Timer toutes les 5 min (paire avec healthcheck.service) |
| `04.6-healthcheck.service` | 3.4.6 | Service de vérification de santé |
| `04.6-backup-nocturne.timer` | 3.4.6 | Timer nocturne avec randomisation |
| `04.6-backup-donnees.service` | 3.4.6 | Service de sauvegarde de données |
| `04.6-backup-donnees.timer` | 3.4.6 | Timer associé (Persistent=true pour rattrapage) |
| `04.6-cleanup-tmp.service` | 3.4.6 | Nettoyage périodique de /tmp (oneshot) |
| `04.6-cleanup-tmp.timer` | 3.4.6 | Timer associé (hebdomadaire) |
| `04.6-rapport-mensuel.timer` | 3.4.6 | Timer mensuel (1er du mois à 8h) |
| `04.6-monitoring-rapport.timer` | 3.4.6 | Timer monotone (relatif au boot) |

### 05-logs-monitoring/ — rsyslog, alertes, notifications

| Fichier | Section | Description |
|---|---|---|
| `05.1-rsyslog-mon-application.conf` | 3.5.1 | Redirection des logs d'une app vers un fichier dédié |
| `05.1-rsyslog-filtre-avance.conf` | 3.5.1 | Filtres avancés (RainerScript, regex) |
| `05.1-rsyslog-templates.conf` | 3.5.1 | Templates personnalisés (JSON, format avancé) |
| `05.1-rsyslog-remote-client.conf` | 3.5.1 | Client : envoi des logs vers serveur distant (TLS/RELP) |
| `05.1-rsyslog-reception-server.conf` | 3.5.1 | Serveur : réception centralisée des logs |
| `05.1-rsyslog-central.conf` | 3.5.1 | Variante centralisée avec dispatch par hôte source |
| `05.1-logrotate-mon-application` | 3.5.1 | Configuration logrotate (rotation journalière + compression) |
| `05.2-ssh-failed-attempts-alert.sh` | 3.5.2 | Alerte si N tentatives SSH échouées en 10 min |
| `05.2-rapport-quotidien-logs.sh` | 3.5.2 | Rapport quotidien (events critiques, services fail, auth) |
| `05.3-nagios-check-journal-errors.sh` | 3.5.3 | Plugin Nagios : erreurs journald sur 10 min |
| `05.4-msmtprc` | 3.5.4 | Configuration msmtp (relais SMTP authentifié) |
| `05.4-aliases` | 3.5.4 | Aliases mail système (root → admin) |
| `05.4-alert-disk.service` | 3.5.4 | Service oneshot vérification disque |
| `05.4-alert-disk.timer` | 3.5.4 | Timer associé (toutes les heures) |
| `05.4-cron-monitoring-alerts` | 3.5.4 | Entrées cron de monitoring |
| `05.4-alert-disk.sh` | 3.5.4 | Surveillance espace disque + mail |
| `05.4-alert-memory.sh` | 3.5.4 | Alerte mémoire avec hystérésis |
| `05.4-alert-services.sh` | 3.5.4 | Vérification de services critiques + alerte |
| `05.4-notify-webhook.sh` | 3.5.4 | Fonction réutilisable d'envoi webhook |
| `05.4-notify-slack.sh` | 3.5.4 | Notification Slack avec niveau de criticité |
| `05.4-notify-dispatcher.sh` | 3.5.4 | Dispatcher multi-canal (mail/Slack/Webhook) |
| `05.4-check-and-alert.sh` | 3.5.4 | Vérification + notification autonome |
| `05.4-predict-disk-full.sh` | 3.5.4 | Prédiction remplissage disque (extrapolation linéaire) |
| `05.4-monit-nginx` | 3.5.4 | Règle Monit pour surveiller nginx |
| `05.4-monit-disk` | 3.5.4 | Règle Monit pour l'espace disque |
| `05.4-monit-memory` | 3.5.4 | Règle Monit pour la mémoire |

---

## Dépendances Debian

```bash
sudo apt install \
    bash python3 \
    systemd systemd-resolved \
    rsyslog logrotate \
    sudo libpam-pwquality libpam-modules \
    sssd sssd-tools libnss-sss libpam-sss \
    msmtp msmtp-mta bsd-mailx \
    monit \
    sysstat \
    shellcheck
```

---

## Notes importantes

> **Avertissement** : ces fichiers sont des **exemples pédagogiques**. Ils sont valides syntaxiquement et illustrent des bonnes pratiques, mais **doivent être adaptés** à votre contexte avant un usage en production : chemins absolus, comptes systèmes, secrets, périmètre d'exécution, gestion des erreurs spécifique à votre infrastructure.

> **Services systemd avec ExecStart inexistant** : `systemd-analyze verify` affiche un warning « Command ... is not executable » lorsque le binaire référencé (ex. `/srv/mon-app/bin/server`) n'existe pas sur le système. C'est attendu pour les fichiers d'exemple — adaptez le chemin avant de copier dans `/etc/systemd/system/`.

> **`StartLimitIntervalSec` / `StartLimitBurst`** : depuis systemd 230 (2016), ces clés doivent être dans la section `[Unit]` (et non `[Service]` comme dans certaines anciennes documentations). Le fichier `04.3-mon-app-complet.service` les place correctement.

> **Profils sudoers** : la convention veut que les fichiers `/etc/sudoers.d/*` aient des permissions `0440` (lecture seule pour root). Adaptez avec `chmod 0440` après copie.

> **Configurations systemd-networkd** : prévues pour `systemd-networkd` activé. Sur un système avec NetworkManager, les fichiers `.network` ne seront pas pris en compte. Voir `04.5-migration-to-networkd.sh` pour migrer.

---

## Licence

Tous les fichiers sont distribués sous **Creative Commons Attribution 4.0 International (CC BY 4.0)**, identique à la formation. Voir [LICENSE](/LICENSE) à la racine du dépôt.

---

*Module 3 — Administration système · 75 fichiers · Testés sur Debian 13 « Trixie »*
