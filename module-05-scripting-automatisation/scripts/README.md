🔝 Retour au [Sommaire](/SOMMAIRE.md) · [Module 5](/module-05-scripting-automatisation.md)

# Scripts du Module 5 — Scripting et automatisation

Ce dossier rassemble les **scripts complets** présentés dans le module 5 de la formation, prêts à être téléchargés, lus, modifiés et exécutés sur un système Debian 13.

Chaque script est extrait du fichier Markdown qui le présente dans son contexte pédagogique. Le `.md` reste la **source narrative** (explications, théorie, alternatives) ; le script de ce dossier en est le **livrable exécutable**.

---

## Convention de nommage

```
<XX.Y>-<nom-court-kebab>.<ext>
```

- `XX.Y` correspond exactement au numéro de **sous-section** dans la formation (ex. `01.4` = section 5.1.4).
- `nom-court-kebab` est descriptif, en minuscules avec tirets.
- `<ext>` est `.sh` (Bash), `.py` (Python), `.service`/`.timer` (units systemd), `.toml`/`.yaml`/`.json` (configs).

Cette convention garantit que `ls` dans un sous-dossier reflète l'ordre du cours, et qu'on retrouve immédiatement la section d'origine d'un script.

---

## Organisation

```
scripts/
├── README.md                 ← ce fichier
├── 01-bash/                  ← Section 5.1 : Bash avancé
├── 02-automatisation/        ← Section 5.2 : Automatisation système
└── 03-python/                ← Section 5.3 : Python pour l'administration
```

Chaque script commence par un **en-tête normalisé** :

```bash
#!/usr/bin/env bash
#
# Nom         : <nom-du-fichier>
# Module      : 5 — Scripting et automatisation
# Section     : <numéro-section> — <titre-section>
# Source      : module-05-scripting-automatisation/<fichier-source>.md
# Description : <description courte multi-lignes>
# Testé sur   : Debian 13 (Trixie)
# Licence     : CC BY 4.0 — Formation Debian (Nicolas DEOUX)
#
```

---

## Utilisation générale

### Préparation

```bash
# Cloner le dépôt
git clone https://github.com/NDXDeveloper/formation-debian.git  
cd formation-debian/module-05-scripting-automatisation/scripts  

# Vérifier les permissions (les fichiers du dépôt sont déjà chmod +x)
ls -l 01-bash/

# Avant exécution, lire systématiquement le script et ses commentaires
less 01-bash/01.4-trap-cleanup-basic.sh
```

### Exécution

```bash
# Bash
./01-bash/01.4-trap-cleanup-basic.sh

# Python (avec un venv recommandé pour éviter PEP 668)
python3 -m venv ~/.venvs/admin  
source ~/.venvs/admin/bin/activate  
pip install psutil requests  
./03-python/03.2-system-inventory.py
```

### Validation locale (optionnelle mais recommandée)

```bash
# Vérifier la syntaxe sans exécuter
bash -n 02-automatisation/02.1-system-cleanup.sh

# Audit qualité avec ShellCheck (paquet `shellcheck` dans Debian)
shellcheck 02-automatisation/02.1-system-cleanup.sh

# Pour Python, utiliser pyflakes/ruff/mypy
python3 -m py_compile 03-python/03.2-check-disk-space.py
```

---

## Index des scripts

### 01-bash/ — Bash avancé

| Fichier | Section | Description courte |
|---|---|---|
| `01.1-check-services.sh` | 5.1.1 | Vérifie l'état d'une liste de services et génère un rapport (tableaux associatifs, `[[ ]]`, `case`) |
| `01.2-utils-template.sh` | 5.1.2 | Squelette type d'un script bien structuré (en-tête, options, fonctions, log, cleanup) |
| `01.4-trap-cleanup-basic.sh` | 5.1.4 | Pattern minimal `trap` + `cleanup` pour libérer des ressources |
| `01.4-trap-cleanup-tmpfile.sh` | 5.1.4 | Création sécurisée de fichier temporaire (`mktemp`) avec garantie de suppression |
| `01.4-lockfile-pattern.sh` | 5.1.4 | Empêche l'exécution concurrente du même script via lockfile |
| `01.4-deploy-rollback.sh` | 5.1.4 | Déploiement multiphase avec rollback automatique en cas d'erreur |
| `01.4-cleanup-children.sh` | 5.1.4 | Nettoyage de processus enfants encore actifs au moment de l'arrêt |
| `01.4-on-error-context.sh` | 5.1.4 | Capture du contexte complet d'erreur via `trap ERR` + `LINENO` |
| `01.4-error-logger.sh` | 5.1.4 | Logging structuré multi-niveau (DEBUG/INFO/WARN/ERROR) |
| `01.4-collect-errors.sh` | 5.1.4 | Collecte d'erreurs sans interrompre le script (alternative à `set -e`) |
| `01.5-backup-postgresql.sh` | 5.1.5 | Sauvegarde quotidienne PostgreSQL avec rotation et notification |

### 02-automatisation/ — Automatisation système

| Fichier | Section | Description courte |
|---|---|---|
| `02.1-rotate-app-logs.sh` | 5.2.1 | Rotation/archivage des logs applicatifs sans `logrotate` |
| `02.1-check-log-growth.sh` | 5.2.1 | Détection de croissance anormale des logs (delta > seuil sur 24 h) |
| `02.1-disk-diagnostic.sh` | 5.2.1 | Diagnostic complet de l'utilisation disque (top dossiers/fichiers, inodes) |
| `02.1-system-cleanup.sh` | 5.2.1 | Nettoyage hebdomadaire (cache APT, journaux, /tmp, anciens noyaux) |
| `02.1-check-disk-space.sh` | 5.2.1 | Surveillance espace disque avec alerte mail si seuil dépassé |
| `02.1-provision-debian.sh` | 5.2.1 | Provisionnement initial complet d'un serveur Debian fraîchement installé |
| `02.2-notify-failure.sh` | 5.2.2 | Script déclenché par `OnFailure=` d'un service systemd |
| `02.3-check-api-health.sh` | 5.2.3 | Vérification santé d'endpoints HTTP/HTTPS avec retry et timeout |
| `02.3-notify-webhook.sh` | 5.2.3 | Notifications via webhook (Slack/Mattermost) avec niveau de criticité |
| `02.3-gitlab-ops.sh` | 5.2.3 | Opérations courantes via l'API GitLab (lister projets, issue, pipeline) |
| `02.4-report-system.sh` | 5.2.4 | Rapport système quotidien au format texte |
| `02.4-report-html.sh` | 5.2.4 | Rapport système au format HTML, prêt pour envoi par mail |
| `02.4-lib-notify.sh` | 5.2.4 | Bibliothèque de notification unifiée (journal/email/Slack/Mattermost) |
| `02.4-daily-report.sh` | 5.2.4 | Rapport quotidien avec notification conditionnelle |

### 03-python/ — Python pour l'administration

| Fichier | Section | Description courte |
|---|---|---|
| `03.1-setup-venv.sh` | 5.3.1 | Création/maj idempotente du venv d'administration (PEP 668-compliant) |
| `03.1-check-venv.sh` | 5.3.1 | Vérification d'environnement Python (version, venv, paquets) |
| `03.2-check-disk-space.py` | 5.3.2 | Vérification d'espace disque avec alertes Prometheus exporter |
| `03.2-system-inventory.py` | 5.3.2 | Inventaire système au format JSON (OS, CPU, RAM, disques, services, réseau) |

---

## Dépendances

### Paquets Debian recommandés (à installer une fois pour l'ensemble des scripts)

```bash
sudo apt install \
    bash bash-completion \
    coreutils util-linux procps \
    jq curl wget \
    python3 python3-venv python3-pip \
    python3-yaml python3-requests python3-psutil \
    bsd-mailx msmtp msmtp-mta \
    shellcheck bats
```

### Pour les scripts faisant appel à des APIs

- `02.3-check-api-health.sh`, `02.3-notify-webhook.sh`, `02.3-gitlab-ops.sh` : `curl`, `jq`
- `03.2-system-inventory.py` : `python3-psutil`

### Pour les notifications par email

- `02.1-check-disk-space.sh`, `02.4-daily-report.sh` : un MTA configuré (`msmtp` ou Postfix)

---

## Notes importantes

> **Avertissement** : ces scripts sont des **exemples pédagogiques**. Ils sont valides syntaxiquement et illustrent des bonnes pratiques, mais **doivent être adaptés** à votre contexte avant un usage en production : chemins absolus, comptes systèmes, secrets, périmètre d'exécution, gestion des erreurs spécifique à votre infrastructure.

> **PEP 668 (Debian 12+)** : sur Debian Trixie, `pip install` hors d'un venv est **bloqué par défaut**. Tous les scripts Python de ce dossier supposent l'usage d'un venv (créé par `03.1-setup-venv.sh`) ou de `pipx`.

> **Permissions root** : la majorité des scripts d'administration (`02.1-system-cleanup.sh`, `02.1-provision-debian.sh`, `01.5-backup-postgresql.sh`, etc.) nécessitent des privilèges root. Ils sont prévus pour être exécutés via `sudo` ou par un utilisateur système dédié.

---

## Licence

Tous les scripts sont distribués sous **Creative Commons Attribution 4.0 International (CC BY 4.0)**, identique à la formation. Voir [LICENSE](/LICENSE) à la racine du dépôt.

---

*Module 5 — Scripting et automatisation · 29 scripts · Testés sur Debian 13 « Trixie »*
