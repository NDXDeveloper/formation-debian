🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 5.1 Bash avancé

## Introduction

Bash (Bourne Again SHell) est le shell par défaut sur Debian depuis ses premières versions. Si la plupart des administrateurs système l'utilisent quotidiennement pour des tâches interactives — naviguer dans l'arborescence, manipuler des fichiers, interroger des services — peu exploitent réellement toute la puissance du langage de scripting qu'il embarque. Or, la maîtrise avancée de Bash constitue une compétence fondamentale pour tout administrateur système souhaitant automatiser efficacement son infrastructure.

Cette section dépasse les bases du scripting (variables simples, boucles `for`, conditions `if`) pour aborder les mécanismes avancés du langage : structures de données complexes, manipulation fine des flux d'exécution, traitement de texte à grande échelle et écriture de scripts robustes prêts pour la production.

---

## Pourquoi approfondir Bash ?

Bash occupe une place unique dans l'écosystème d'administration système pour plusieurs raisons.

**L'omniprésence.** Bash est disponible sur la quasi-totalité des systèmes Unix/Linux, y compris les conteneurs minimalistes, les environnements de secours (rescue mode) et les systèmes embarqués. Un script Bash fonctionnera sur un serveur Debian Stable, un conteneur Docker basé sur `debian:trixie-slim`, un poste de développement ou une instance cloud, sans aucune dépendance supplémentaire à installer.

**L'accès direct au système.** Contrairement à des langages de plus haut niveau, Bash est le langage natif du système d'exploitation. Il interagit directement avec les processus, les descripteurs de fichiers, les signaux, les pipes et les codes de retour sans couche d'abstraction intermédiaire. Cette proximité avec le système en fait l'outil idéal pour l'orchestration de commandes, la gestion de processus et l'automatisation des tâches d'administration.

**L'intégration avec l'écosystème Unix.** Bash tire parti de la philosophie Unix — « faire une seule chose et la faire bien » — en permettant de combiner des outils spécialisés (`grep`, `sed`, `awk`, `jq`, `curl`, `find`, `xargs`…) au travers de pipelines. La puissance d'un script Bash réside souvent moins dans le langage lui-même que dans sa capacité à orchestrer ces utilitaires de manière élégante et efficace.

**Le coût d'entrée minimal.** Pour des tâches d'administration courantes — rotation de logs, vérification de services, parsing de fichiers de configuration, appels à des APIs REST — Bash permet d'obtenir un résultat fonctionnel en quelques lignes, là où un langage comme Python nécessiterait la mise en place d'un environnement virtuel, l'import de bibliothèques et une structure de code plus formelle.

---

## Positionnement dans le parcours

Cette section s'inscrit dans le **Module 5 — Scripting et automatisation**, qui couvre trois axes complémentaires :

| Section | Contenu | Cas d'usage principal |
|---------|---------|----------------------|
| **5.1 — Bash avancé** | Maîtrise approfondie du langage Bash | Scripts système, glue code, pipelines |
| **5.2 — Automatisation système** | Application pratique à l'administration | Tâches planifiées, rapports, APIs |
| **5.3 — Python pour l'administration** | Scripting de haut niveau | Logique complexe, bibliothèques riches |

Bash avancé constitue le socle : les compétences acquises ici seront directement mobilisées dans la section 5.2 pour écrire des scripts d'administration concrets, et serviront de point de comparaison avec Python dans la section 5.3 pour savoir choisir le bon outil selon le contexte.

---

## Ce que couvre cette section

La section 5.1 est organisée en cinq sous-parties progressives qui couvrent l'ensemble des compétences nécessaires à l'écriture de scripts Bash de qualité professionnelle :

**5.1.1 — Variables, tableaux et structures de contrôle.** Les fondations du langage avancé : tableaux indexés et associatifs, expansion de paramètres, structures conditionnelles (`case`, tests avancés avec `[[ ]]`) et boucles avancées (`while read`, itération sur des tableaux). Cette sous-partie pose les bases indispensables pour tout ce qui suit.

**5.1.2 — Fonctions, sous-shells et substitution de processus.** L'organisation du code : écriture de fonctions réutilisables avec gestion de la portée des variables, compréhension des sous-shells et de leurs implications sur l'état du script, et utilisation de la substitution de processus (`<()`, `>()`) pour des traitements avancés de flux.

**5.1.3 — Expressions régulières et traitement de texte (sed, awk, jq).** Le cœur du traitement de données en ligne de commande : expressions régulières POSIX et étendues, maîtrise de `sed` pour les transformations de texte, `awk` pour le traitement structuré de données tabulaires, et `jq` pour la manipulation de JSON, format omniprésent dans les APIs modernes et les outils cloud-native.

**5.1.4 — Gestion des erreurs, codes de retour et signaux (trap).** La robustesse : exploitation des codes de retour, gestion des erreurs avec les mécanismes de trap, nettoyage des ressources temporaires et écriture de scripts capables de gérer les situations imprévues (interruptions, erreurs de commande, signaux système).

**5.1.5 — Bonnes pratiques (shellcheck, set -euo pipefail, logging).** La qualité professionnelle : utilisation de ShellCheck pour l'analyse statique, options de sécurité du shell (`set -euo pipefail`), structuration du code, journalisation, et conventions qui distinguent un script amateur d'un script maintenable en production.

---

## Prérequis

Pour aborder cette section dans de bonnes conditions, les connaissances suivantes sont attendues :

- **Shell de base** : navigation dans le système de fichiers, utilisation courante de la ligne de commande, redirections simples (`>`, `>>`, `<`, `|`), variables d'environnement (`$PATH`, `$HOME`).
- **Scripting élémentaire** : écriture de scripts simples avec des variables, des boucles `for` et des conditions `if/then/else`, exécution de scripts (`chmod +x`, shebang `#!/bin/bash`).
- **Administration Debian** : les concepts vus dans les modules 1 à 4 (système de fichiers, gestion des processus, services systemd, gestion des paquets) fournissent le contexte dans lequel les scripts seront utilisés.

---

## Conventions utilisées

Tout au long de cette section, les conventions suivantes sont appliquées :

- Les blocs de code utilisent le shebang `#!/usr/bin/env bash` pour la portabilité, sauf mention contraire.
- Le prompt `$` indique une commande exécutée en tant qu'utilisateur standard, `#` en tant que root.
- Les exemples sont testés sur **Debian 13 (Trixie)** avec Bash 5.2. Les différences de comportement avec des versions antérieures sont signalées lorsqu'elles existent.
- Les noms de variables d'environnement et de fichiers système sont présentés en `code inline`.
- Les sorties de commandes sont présentées telles quelles, sans modification.

---

## Version de Bash sur Debian

Debian Stable (Trixie, version 13) fournit **Bash 5.2**, une version qui apporte plusieurs améliorations significatives par rapport aux versions antérieures. Il est important de connaître sa version de Bash, car certaines fonctionnalités avancées abordées dans cette section dépendent de la version installée.

Pour vérifier la version installée :

```bash
$ bash --version
GNU bash, version 5.2.37(1)-release (x86_64-pc-linux-gnu)
```

Parmi les apports des versions récentes de Bash qui seront exploités dans cette section :

- **Bash 4.0** : tableaux associatifs (`declare -A`), coprocessus (`coproc`).
- **Bash 4.3** : références nommées (`declare -n`), complétion améliorée.
- **Bash 4.4** : `${parameter@operator}` pour la transformation de variables, `mapfile` amélioré.
- **Bash 5.0** : variable `$EPOCHSECONDS`, `BASH_ARGV0` assignable, `wait -n` avec identificateur.
- **Bash 5.1** : `SRANDOM` (générateur aléatoire non linéaire), `${assoc_array[@]@k}` pour itérer clés/valeurs.
- **Bash 5.2** : améliorations mineures de compatibilité et corrections de comportement.

> **Note Debian** : Si vous travaillez sur Debian Oldstable (Bookworm, version 12), vous disposez également de Bash 5.2 (en version 5.2.15) — l'intégralité du contenu de cette section reste applicable. Sur Debian Oldoldstable (Bullseye, version 11), Bash est en 5.1 : la quasi-totalité des exemples fonctionne, à l'exception de quelques fonctionnalités spécifiques à 5.2. Sur des systèmes encore plus anciens (Buster avec Bash 5.0), certains exemples pourront nécessiter des adaptations.

---

## Bash face aux alternatives

Bash n'est pas le seul shell disponible sur Debian. Il est utile de comprendre son positionnement par rapport aux alternatives pour faire des choix éclairés :

- **`/bin/sh` (dash sur Debian)** : Shell POSIX minimal, utilisé par défaut pour les scripts système (`/bin/sh` pointe vers `dash` sur Debian). Il est plus rapide que Bash mais ne dispose pas de ses extensions (tableaux, `[[ ]]`, substitution de processus…). Les scripts de démarrage et les scripts de maintenance système Debian utilisent généralement `sh` pour des raisons de performance et de portabilité.

- **Zsh** : Shell interactif très riche, apprécié des développeurs pour ses capacités de complétion et de personnalisation. Il offre des fonctionnalités de scripting supérieures à Bash (tableaux plus puissants, globbing étendu), mais sa présence n'est pas garantie sur tous les systèmes, contrairement à Bash.

- **Fish** : Shell moderne orienté utilisateur avec une syntaxe volontairement incompatible avec POSIX. Excellent pour l'usage interactif mais inadapté aux scripts d'administration système.

Le choix de Bash pour cette formation repose sur un compromis pragmatique : il est suffisamment puissant pour couvrir la grande majorité des besoins en scripting système, tout en étant disponible par défaut sur Debian et sur la quasi-totalité des distributions Linux. Les scripts écrits en Bash ont une durée de vie longue et une portabilité élevée dans l'écosystème Linux.

> **Règle d'or** : utilisez `#!/usr/bin/env bash` quand vous avez besoin de fonctionnalités spécifiques à Bash (tableaux, `[[ ]]`, substitution de processus…), et `#!/bin/sh` lorsque le script n'utilise que des constructions POSIX standard — il sera alors exécuté par `dash`, plus léger et plus rapide.

⏭️ [Variables, tableaux et structures de contrôle](/module-05-scripting-automatisation/01.1-variables-tableaux-structures.md)
