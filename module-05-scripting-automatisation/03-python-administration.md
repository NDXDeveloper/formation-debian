🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 5.3 Introduction à Python pour l'administration

## Introduction

Les sections 5.1 et 5.2 ont démontré la puissance de Bash pour l'automatisation système : gestion des processus, manipulation de fichiers, interaction avec les commandes système, planification de tâches. Bash excelle dans ces domaines parce qu'il est le langage natif du système d'exploitation — chaque commande Unix est immédiatement accessible, les pipes et les redirections sont des citoyens de première classe, et aucune dépendance supplémentaire n'est requise.

Cependant, à mesure que les scripts grandissent en complexité, les limites de Bash apparaissent. La manipulation de structures de données imbriquées devient laborieuse. La gestion des erreurs reste rudimentaire comparée aux exceptions des langages de haut niveau. Le traitement de formats comme le YAML, le XML ou les bases de données nécessite des outils externes. Et surtout, la maintenabilité d'un script Bash de plus de quelques centaines de lignes se dégrade rapidement.

C'est ici que Python entre en jeu. Python n'est pas un remplacement de Bash — c'est un complément. Il occupe la niche située entre le script shell ponctuel et l'application de gestion d'infrastructure complète, offrant un langage expressif, une bibliothèque standard riche et un écosystème de paquets qui couvre pratiquement tous les besoins de l'administration système.

---

## Pourquoi Python pour l'administration système ?

### Un langage présent par défaut sur Debian

Python est installé de base sur toute installation Debian standard. L'écosystème Debian s'en sert massivement : si le cœur d'`apt` est écrit en C++ (libapt-pkg), de nombreux outils périphériques officiels sont en Python — `apt-listchanges`, `apt-listbugs`, `unattended-upgrades`, `command-not-found`, `reportbug`, ainsi que la bibliothèque `python-apt` (bindings Python de libapt-pkg). Au-delà du système, les gestionnaires de configuration comme Ansible en font leur langage de base. Cette omniprésence garantit que Python est disponible sur les serveurs sans installation supplémentaire.

```bash
# Python est déjà là sur Debian Trixie
python3 --version
# Python 3.13.x
```

### Les forces de Python pour l'administration

**Structures de données natives.** Dictionnaires, listes, ensembles et tuples sont intégrés au langage et s'imbriquent naturellement. Là où Bash atteint ses limites avec les tableaux associatifs simples, Python gère des structures arbitrairement complexes :

```python
# En Python : naturel et lisible
serveurs = {
    "web01": {"ip": "10.0.1.1", "roles": ["nginx", "php"], "dc": "paris"},
    "db01":  {"ip": "10.0.2.1", "roles": ["postgresql"], "dc": "paris"},
}
serveurs_paris = [s for s, info in serveurs.items() if info["dc"] == "paris"]
```

```bash
# En Bash : faisable mais laborieux et fragile
declare -A serveur_ip=([web01]="10.0.1.1" [db01]="10.0.2.1")  
declare -A serveur_dc=([web01]="paris" [db01]="paris")  
# Pas de moyen simple de stocker des listes dans un tableau associatif
```

**Gestion des erreurs par exceptions.** Le mécanisme `try/except/finally` de Python offre une gestion d'erreurs structurée et granulaire, là où Bash repose sur les codes de retour et `set -e` :

```python
try:
    with open("/etc/monapp/config.yaml") as f:
        config = yaml.safe_load(f)
except FileNotFoundError:
    print("Fichier de configuration introuvable", file=sys.stderr)
    sys.exit(1)
except yaml.YAMLError as e:
    print(f"Erreur de syntaxe YAML : {e}", file=sys.stderr)
    sys.exit(2)
```

**Bibliothèque standard étendue.** Sans installer le moindre paquet supplémentaire, Python fournit des modules pour manipuler les fichiers et répertoires (`pathlib`, `shutil`), le réseau (`socket`, `http`, `urllib`), les processus (`subprocess`), les formats de données (`json`, `csv`, `configparser`, `xml`), les expressions régulières (`re`), la journalisation (`logging`), l'archivage (`tarfile`, `zipfile`), les bases de données (`sqlite3`) et bien plus.

**Écosystème de bibliothèques tierces.** Pour les besoins qui dépassent la bibliothèque standard, l'écosystème PyPI offre des bibliothèques matures et bien maintenues : `requests` pour les appels HTTP, `paramiko` pour le SSH, `psycopg2` pour PostgreSQL, `boto3` pour AWS, `pyyaml` pour le YAML, `jinja2` pour les templates, et des dizaines d'autres.

**Testabilité et maintenabilité.** Python offre un écosystème de test mature (`pytest`, `unittest`, `mock`) et des outils d'analyse de code (`mypy`, `ruff`, `black`). Un script Python de 500 lignes est significativement plus facile à comprendre, déboguer et faire évoluer qu'un script Bash de taille équivalente.

---

## Positionnement dans le parcours

Cette section ne vise pas à enseigner le langage Python de manière exhaustive — il existe d'excellentes ressources dédiées pour cela. L'objectif est de fournir à l'administrateur système Debian les compétences nécessaires pour utiliser Python efficacement dans un contexte d'administration, en complément de Bash.

| Section | Contenu | Objectif |
|---------|---------|----------|
| **5.3.1** | Python sur Debian, venv, pip | Disposer d'un environnement de développement Python propre |
| **5.3.2** | Scripts d'administration en Python | Reproduire et dépasser les capacités de Bash pour les tâches courantes |
| **5.3.3** | Bibliothèques utiles | Maîtriser `os`, `subprocess`, `paramiko`, `requests` et les autres outils de l'administrateur |
| **5.3.4** | Bash vs Python : quand choisir quoi | Critères de décision pour chaque situation |

Le fil conducteur est pragmatique : chaque concept est illustré par un cas d'usage réel en administration système Debian, souvent en comparaison directe avec l'approche Bash vue dans les sections précédentes.

---

## Ce que couvre cette section

**5.3.1 — Python sur Debian : installation et gestion des environnements virtuels.** Python est préinstallé sur Debian, mais son utilisation pour le scripting d'administration nécessite de comprendre la politique Debian de gestion de Python (PEP 668, externally-managed-environment), la création d'environnements virtuels avec `venv`, et l'installation de bibliothèques avec `pip` sans interférer avec les paquets système. Cette sous-partie pose les bases d'un environnement de développement Python propre et maintenable.

**5.3.2 — Scripts d'administration système en Python.** Les patterns fondamentaux du scripting d'administration en Python : parsing d'arguments avec `argparse`, manipulation du système de fichiers avec `pathlib`, exécution de commandes système avec `subprocess`, journalisation structurée avec `logging`, et gestion des fichiers de configuration. Chaque pattern est illustré par un script concret, directement comparable aux scripts Bash vus en section 5.2.

**5.3.3 — Bibliothèques utiles (os, subprocess, paramiko, requests).** Les bibliothèques que tout administrateur système doit connaître pour automatiser efficacement : `os` et `pathlib` pour le système de fichiers, `subprocess` pour l'exécution de commandes, `paramiko` pour le SSH programmatique, `requests` pour les interactions HTTP/API, `psutil` pour les métriques système, et `jinja2` pour la génération de configurations à partir de templates.

**5.3.4 — Quand utiliser Bash vs Python.** Un guide de décision structuré pour choisir le bon outil selon le contexte : complexité de la tâche, structures de données impliquées, besoin de portabilité, contraintes de déploiement, compétences de l'équipe. Cette sous-partie synthétise l'expérience acquise au cours des trois sections du module 5 pour fournir des règles de choix claires et applicables.

---

## Prérequis

Cette section est accessible à un administrateur système qui possède les compétences suivantes :

- **Bash avancé (sections 5.1 et 5.2)** : les scripts Python seront souvent comparés à leur équivalent Bash, ce qui suppose une bonne maîtrise du scripting shell.
- **Notions de programmation** : une familiarité de base avec les concepts de programmation (variables, boucles, conditions, fonctions) est attendue. Une expérience préalable de Python est un plus mais n'est pas strictement nécessaire — la section s'adresse aux administrateurs système qui souhaitent ajouter Python à leur boîte à outils, pas aux développeurs Python confirmés.
- **Administration Debian (modules 1 à 4)** : les exemples exploitent les concepts d'administration système vus dans les modules précédents (services, paquets, réseau, logs).

---

## Conventions

Les scripts Python présentés dans cette section suivent les conventions suivantes :

- **Python 3.13** (version fournie par Debian 13 Trixie). Aucune compatibilité Python 2 n'est maintenue — Python 2 est en fin de vie depuis janvier 2020.
- **Shebang `#!/usr/bin/env python3`** pour la portabilité.
- **Style PEP 8** : la convention de style officielle de Python (noms en `snake_case`, indentation de 4 espaces, lignes de 79 caractères maximum selon PEP 8 ; les outils modernes `black` et `ruff` adoptent un défaut de 88 caractères, qui est la limite retenue dans cette section).
- **Type hints** : les annotations de type sont utilisées quand elles améliorent la lisibilité, sans rechercher une couverture exhaustive.
- **f-strings** pour le formatage des chaînes (syntaxe `f"Bonjour {nom}"`), préférées à `%` et `.format()`.
- **`pathlib.Path`** plutôt que les fonctions `os.path.*` pour la manipulation des chemins, sauf quand une bibliothèque tierce l'exige.
- Les exemples sont exécutables directement et testés sur Debian 13 (Trixie).

⏭️ [Python sur Debian : installation et gestion des environnements virtuels](/module-05-scripting-automatisation/03.1-python-debian-venv.md)
