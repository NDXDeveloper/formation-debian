🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 14.1 Principes de CI/CD

## Introduction

Le CI/CD — Continuous Integration / Continuous Delivery (ou Deployment) — constitue l'épine dorsale de toute démarche DevOps moderne. Derrière cet acronyme se cache un ensemble de pratiques, de principes culturels et d'outillage technique dont l'objectif est simple mais ambitieux : **réduire le délai entre l'écriture d'une ligne de code et sa mise en production**, tout en garantissant un niveau de qualité élevé et reproductible.

Dans le contexte de cette formation, le CI/CD prend une dimension particulière. Après avoir acquis la maîtrise de l'administration Debian (Parcours 1), puis celle de la conteneurisation et de l'Infrastructure as Code (Parcours 2), il s'agit désormais d'**automatiser le cycle de vie complet des applications et de l'infrastructure**, depuis le commit initial jusqu'au déploiement en production sur des clusters Kubernetes hébergés sur Debian.

---

## Pourquoi le CI/CD est-il essentiel ?

### Le problème historique

Pendant longtemps, le cycle de vie logiciel a fonctionné selon un modèle séquentiel : les développeurs écrivaient du code pendant des semaines ou des mois, puis le transmettaient aux équipes d'exploitation qui se chargeaient de l'intégrer, de le tester et de le déployer — souvent manuellement. Ce modèle, hérité du cycle en V ou du waterfall, engendrait des problèmes récurrents :

- **L'« integration hell »** : plus le code divergeait entre les branches de développement, plus la fusion devenait douloureuse et source de régressions.
- **Des déploiements risqués** : chaque mise en production mobilisait des équipes entières sur des créneaux nocturnes ou des week-ends, avec des procédures manuelles sujettes aux erreurs humaines.
- **Un feedback tardif** : les bugs n'étaient découverts qu'en fin de cycle, quand leur coût de correction était maximal.
- **Un manque de traçabilité** : il était difficile de savoir précisément quel changement avait introduit quel comportement.

### La réponse CI/CD

Le CI/CD renverse cette approche en posant un principe fondateur : **chaque modification du code doit être intégrée, testée et potentiellement déployée de manière automatique et continue**. Ce changement de paradigme repose sur trois piliers :

1. **L'intégration continue (CI)** — Les développeurs fusionnent fréquemment leur code dans une branche partagée. Chaque fusion déclenche automatiquement une chaîne de build et de tests qui valide la modification en quelques minutes.

2. **La livraison continue (CD — Continuous Delivery)** — Le code validé par la CI est automatiquement préparé pour un déploiement en production. L'artefact produit (image Docker, paquet Debian, chart Helm…) est prêt à être déployé à tout moment, mais le déclenchement effectif reste une décision humaine.

3. **Le déploiement continu (CD — Continuous Deployment)** — Extension de la livraison continue : chaque changement qui passe l'ensemble des validations automatisées est **déployé automatiquement en production**, sans intervention humaine. C'est le niveau de maturité le plus élevé.

---

## Le CI/CD dans l'écosystème Debian et Kubernetes

Ce module aborde le CI/CD sous deux angles complémentaires, qui reflètent les réalités opérationnelles rencontrées en entreprise :

### CI/CD sur serveur Debian (section 14.2)

Dans de nombreuses organisations, les runners CI/CD s'exécutent sur des serveurs Debian dédiés, gérés comme n'importe quel autre service d'infrastructure. Cette approche offre un contrôle total sur l'environnement d'exécution et s'intègre naturellement dans une infrastructure administrée avec les compétences du Parcours 1. On y retrouvera notamment :

- L'installation et la gestion de **GitLab Runner** comme service systemd sur Debian.
- La configuration de **GitHub Actions self-hosted runners** sur Debian.
- Les pratiques de sécurisation et de maintenance de ces runners.

### CI/CD sur Kubernetes (section 14.3)

Avec la montée en puissance de Kubernetes, de nombreuses organisations déplacent leur infrastructure CI/CD directement dans le cluster. Les runners deviennent des pods éphémères, créés à la demande pour chaque pipeline, puis détruits. Cette approche offre une élasticité et une isolation supérieures. Seront abordés :

- **Jenkins** déployé sur Kubernetes avec des agents dynamiques.
- **Tekton Pipelines**, solution cloud-native conçue nativement pour Kubernetes.
- **GitLab CI** avec des runners orchestrés par Kubernetes.

### GitOps : le CI/CD déclaratif (section 14.4)

Le GitOps représente l'évolution naturelle du CI/CD dans un monde cloud-native. Il repose sur un principe simple : **Git est la seule source de vérité pour l'état souhaité de l'infrastructure et des applications**. Un opérateur (ArgoCD, Flux) surveille en permanence le dépôt Git et réconcilie automatiquement l'état réel du cluster avec l'état déclaré. Cette approche fusionne les pratiques d'Infrastructure as Code vues au Module 13 avec les pipelines CI/CD.

---

## Concepts transversaux du module

Tout au long de ce module, plusieurs concepts transversaux seront mobilisés et approfondis :

- **L'idempotence** : un pipeline exécuté deux fois avec les mêmes entrées doit produire le même résultat, principe déjà rencontré avec Ansible et Terraform au Module 13.
- **L'immutabilité des artefacts** : une image Docker construite et validée ne doit jamais être modifiée. Ce qui est testé est ce qui est déployé — pas une reconstruction à partir des mêmes sources.
- **La séparation build / deploy** : la phase de construction d'un artefact et sa phase de déploiement sont deux étapes distinctes, potentiellement exécutées par des outils et des équipes différents.
- **Le shift-left** : déplacer les contrôles de qualité et de sécurité le plus tôt possible dans le cycle de développement (tests unitaires, analyse statique, scan de vulnérabilités dès le commit).
- **La traçabilité de bout en bout** : chaque artefact déployé en production doit pouvoir être relié au commit Git qui l'a engendré, aux tests qui l'ont validé et à l'approbation qui a autorisé son déploiement.

---

## Prérequis pour ce module

Ce module s'appuie sur les compétences acquises dans les modules précédents :

| Module | Compétences mobilisées |
|--------|----------------------|
| **Module 5** — Scripting | Bash avancé, interaction avec les APIs REST, automatisation |
| **Module 7** — Services de base | Serveurs web (Nginx, Apache), bases de données, SSL/TLS |
| **Module 10** — Conteneurs | Docker, construction d'images, Docker Compose, registries |
| **Module 11** — Kubernetes fondamentaux | Deployments, Services, ConfigMaps, Secrets, Ingress |
| **Module 12** — Kubernetes production | Helm, Kustomize, RBAC, stratégies de déploiement |
| **Module 13** — IaC | Ansible, Terraform, principes d'idempotence et de déclarativité |

Une familiarité avec **Git** (branches, merge requests / pull requests, tags) est également indispensable. Bien que Git ne fasse pas l'objet d'un module dédié dans cette formation, les stratégies de branching seront couvertes dans la section 14.1.3.

---

## Plan de la section

- **14.1.1** — Concepts fondamentaux (intégration continue, déploiement continu)
- **14.1.2** — Pipelines : conception et bonnes pratiques
- **14.1.3** — Stratégies de branching et workflows Git

---

*La section suivante (14.1.1) détaillera les concepts fondamentaux du CI/CD : définitions précises de l'intégration continue, de la livraison continue et du déploiement continu, accompagnées d'une mise en perspective historique et des bénéfices mesurables de ces pratiques.*

⏭️ [Concepts fondamentaux (intégration continue, déploiement continu)](/module-14-cicd-gitops/01.1-concepts-fondamentaux.md)
