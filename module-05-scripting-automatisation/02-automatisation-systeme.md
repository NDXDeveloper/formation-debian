🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 5.2 Automatisation système

## Introduction

La section précédente (5.1) a posé les fondations techniques du scripting Bash avancé : structures de données, fonctions, traitement de texte, gestion des erreurs et bonnes pratiques. Ces compétences constituent une boîte à outils. La présente section s'attache à les mettre en œuvre dans leur contexte naturel : l'automatisation des tâches récurrentes d'administration système sur un serveur Debian.

L'automatisation n'est pas un luxe réservé aux grandes infrastructures. Dès qu'une tâche est exécutée manuellement plus de deux ou trois fois — rotation de logs, nettoyage d'espace disque, vérification de l'état de services, sauvegarde, provisionnement d'un serveur — elle est candidate à l'automatisation. Les bénéfices sont multiples : élimination des erreurs humaines, reproductibilité garantie, traçabilité des opérations et libération du temps de l'administrateur pour des tâches à plus forte valeur ajoutée.

---

## De la commande ponctuelle au script de production

L'automatisation suit généralement un cheminement progressif que tout administrateur reconnaîtra :

**Étape 1 — La commande ad hoc.** L'administrateur tape une commande dans le terminal pour résoudre un problème immédiat. Par exemple, trouver et supprimer les fichiers de plus de 30 jours dans `/var/log` :

```bash
find /var/log -name "*.log.gz" -mtime +30 -delete
```

**Étape 2 — La commande sauvegardée.** La même commande revient une semaine plus tard. L'administrateur la retrouve dans son historique, l'améliore et la note dans un fichier pour la prochaine fois.

**Étape 3 — Le script.** La commande acquiert des paramètres, une gestion d'erreurs, une journalisation. Elle devient un script autonome, versionné dans un dépôt Git.

**Étape 4 — Le script planifié.** Le script est enregistré dans une tâche cron ou un timer systemd pour s'exécuter automatiquement à intervalles réguliers, sans intervention humaine.

**Étape 5 — Le script intégré.** Le script s'intègre dans un écosystème plus large : il envoie des notifications en cas d'erreur, expose des métriques pour le monitoring, interagit avec des APIs REST pour orchestrer des opérations cross-services.

Cette section couvre les étapes 3 à 5, en fournissant les patterns, les outils et les méthodologies nécessaires pour transformer des commandes ponctuelles en automatisations robustes et durables.

---

## Positionnement dans le parcours

La section 5.2 fait le lien entre les compétences de scripting acquises en 5.1 et les besoins concrets rencontrés dans les modules précédents et suivants :

| Section | Apport | Relation avec 5.2 |
|---------|--------|-------------------|
| **5.1 — Bash avancé** | Syntaxe, structures, bonnes pratiques | Fondations techniques utilisées ici |
| **3.4 — systemd** | Services, journald, timers | Planification et intégration des scripts |
| **3.5 — Logs et monitoring** | Analyse de logs, alerting | Scripts de surveillance automatisée |
| **5.3 — Python pour l'administration** | Scripting de haut niveau | Alternative pour les cas complexes |
| **7.x — Services serveur** | Web, BDD, fichiers | Cibles typiques de l'automatisation |
| **13.x — Infrastructure as Code** | Ansible, Terraform | Évolution vers l'IaC à grande échelle |

La section 5.2 est pragmatique et orientée résultats : chaque sous-partie produit des scripts directement utilisables, illustrant les patterns d'automatisation les plus courants en environnement Debian.

---

## Ce que couvre cette section

La section 5.2 est organisée en quatre sous-parties qui couvrent les grands domaines de l'automatisation système :

**5.2.1 — Scripts d'administration courants (rotation de logs, nettoyage, provisioning).** Les tâches de maintenance récurrentes que tout administrateur Debian doit automatiser : gestion de l'espace disque, rotation et archivage de logs applicatifs, nettoyage de fichiers temporaires, provisionnement initial d'un serveur et mise en conformité de sa configuration. Ces scripts forment le socle de la maintenance préventive.

**5.2.2 — Planification avec cron et timers systemd.** Les deux mécanismes de planification disponibles sur Debian : le classique cron (crontab, fichiers `/etc/cron.d/`, répertoires `cron.daily/weekly/monthly`) et les timers systemd, plus modernes et mieux intégrés avec le reste de l'écosystème systemd (journalisation, dépendances, monitoring). La sous-partie couvre les critères de choix entre les deux approches, leur configuration avancée et les pièges courants (variables d'environnement, PATH, permissions).

**5.2.3 — Interaction avec les APIs REST (curl, jq).** L'automatisation moderne ne se limite plus aux commandes locales. Les scripts d'administration interagissent de plus en plus avec des services distants via des APIs REST : plateformes de monitoring (Prometheus, Grafana), gestionnaires de conteneurs (Docker API), services cloud (AWS, GCP), outils de collaboration (Slack, Mattermost) et systèmes de ticketing (GitLab, Jira). Cette sous-partie couvre l'utilisation de `curl` et `jq` pour interroger, créer et modifier des ressources distantes depuis un script Bash.

**5.2.4 — Génération de rapports et notifications.** La finalité de nombreux scripts d'automatisation est de produire une information exploitable : rapport d'état quotidien, inventaire du parc, bilan des sauvegardes, alerte en cas d'anomalie. Cette sous-partie couvre la génération de rapports en différents formats (texte, HTML, CSV, JSON) et l'envoi de notifications par différents canaux (email, Slack/Mattermost webhooks, journald).

---

## Principes directeurs

Quatre principes guident l'écriture de scripts d'automatisation de qualité :

**L'idempotence.** Un script d'automatisation doit pouvoir être exécuté plusieurs fois consécutivement sans produire d'effets indésirables. La deuxième exécution doit constater que le travail a déjà été fait et ne rien modifier. Ce principe, central dans les outils d'Infrastructure as Code comme Ansible, s'applique tout autant aux scripts Bash. Un script qui ajoute une ligne à un fichier de configuration doit d'abord vérifier que la ligne n'y figure pas déjà. Un script qui crée un utilisateur doit d'abord vérifier qu'il n'existe pas.

**L'observabilité.** Un script qui s'exécute sans supervision — à 3h du matin via un timer systemd — doit laisser suffisamment de traces pour permettre le diagnostic en cas de problème. Cela implique une journalisation structurée, des codes de retour significatifs, et des notifications en cas d'anomalie. Un script silencieux qui échoue est pire qu'un script qui n'existe pas, car il donne une fausse impression de sécurité.

**La défense en profondeur.** Un script robuste ne suppose jamais que l'environnement est dans l'état attendu. Il vérifie ses prérequis, valide ses entrées, gère les erreurs de chaque commande critique et nettoie ses ressources même en cas d'interruption. Les techniques de `trap`, de validation et de gestion d'erreurs vues en section 5.1 trouvent ici leur application directe.

**La séparation des responsabilités.** Un script devrait faire une seule chose et la faire bien, conformément à la philosophie Unix. Un script de sauvegarde sauvegarde. Un script de nettoyage nettoie. Un script de rapport rapporte. Si une automatisation complexe nécessite plusieurs étapes, elle est orchestrée par un script maître qui appelle des scripts spécialisés, chacun testable et maintenable indépendamment.

---

## Prérequis

Cette section s'appuie directement sur les compétences acquises dans les modules et sections précédents :

- **Section 5.1 (Bash avancé)** : toutes les techniques de scripting — tableaux, fonctions, `trap`, `set -euo pipefail`, ShellCheck, `sed`/`awk`/`jq` — sont considérées comme acquises et seront utilisées sans explication détaillée.
- **Module 3.4 (systemd)** : la compréhension des unités systemd, de journald et des timers est nécessaire pour la sous-partie 5.2.2.
- **Module 3.5 (Logs et monitoring)** : les concepts de journalisation et de surveillance sont mobilisés tout au long de cette section.
- **Module 6.3 (SSH)** : les notions de connexion SSH par clé et d'exécution distante sont utilisées dans certains scripts.

---

## Conventions

Les scripts présentés dans cette section suivent les conventions établies en 5.1.5 :

- En-tête `#!/usr/bin/env bash` suivi de `set -euo pipefail`.
- Organisation en fonctions avec point d'entrée `main "$@"`.
- Journalisation via des fonctions `log_info`, `log_warn`, `log_error` écrivant sur stderr.
- Données fonctionnelles sur stdout, diagnostic sur stderr.
- Nettoyage des ressources temporaires via `trap ... EXIT`.
- Passage par ShellCheck sans avertissement.

Les exemples utilisent des chemins et des noms de services typiques d'un serveur Debian 13 (Trixie), mais les patterns sont applicables à toute version de Debian supportée.

⏭️ [Scripts d'administration courants (rotation de logs, nettoyage, provisioning)](/module-05-scripting-automatisation/02.1-scripts-administration.md)
