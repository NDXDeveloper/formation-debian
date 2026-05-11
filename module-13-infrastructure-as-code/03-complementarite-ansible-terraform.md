🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 13.3 Complémentarité Ansible + Terraform

## Introduction

Les sections 13.1 et 13.2 ont couvert Ansible et Terraform en profondeur, chacun dans son domaine d'excellence. Tout au long de ces sections, une ligne de partage est apparue de manière récurrente : Terraform crée l'infrastructure, Ansible la configure. Les provisioners Terraform ont été déconseillés au profit d'Ansible. Les playbooks Ansible de la section 13.1.6 s'appuyaient sur des nœuds Debian « déjà existants ». Les outputs Terraform de la section 13.2.5 généraient des inventaires « pour Ansible ».

Cette section formalise cette complémentarité. Elle ne présente pas de nouveaux outils mais décrit les **patterns d'intégration** qui font fonctionner Ansible et Terraform ensemble de manière cohérente, automatisée et fiable en production. C'est la synthèse opérationnelle du Module 13 : comment ces deux outils s'articulent dans un workflow IaC unifié pour gérer le cycle de vie complet d'une infrastructure Debian, de la création des premières ressources à la maintenance quotidienne.

---

## Pourquoi deux outils

La question revient régulièrement : pourquoi utiliser deux outils alors que chacun peut, dans une certaine mesure, faire le travail de l'autre ? Ansible peut créer des VMs (via des modules cloud), et Terraform peut configurer des serveurs (via des provisioners). La réponse tient en trois points.

### Spécialisation et qualité du résultat

Terraform est construit autour du concept de state et de graphe de dépendances. Son modèle purement déclaratif, sa capacité à calculer un plan d'exécution avant toute modification, et sa gestion native des dépendances entre ressources en font l'outil optimal pour le provisionnement. Créer un réseau, puis un sous-réseau qui le référence, puis une VM attachée à ce sous-réseau, puis un enregistrement DNS pointant vers l'IP de cette VM — cette chaîne de dépendances est ce que Terraform gère le mieux.

Ansible est construit autour de l'exécution de tâches sur des machines existantes via SSH. Son écosystème de modules système (apt, systemd, template, user, file), son moteur de templates Jinja2, ses handlers et ses rôles en font l'outil optimal pour la configuration. Installer des paquets, déployer des fichiers de configuration, gérer des services, orchestrer des redémarrages séquentiels — cette logique de configuration est ce qu'Ansible gère le mieux.

Utiliser chaque outil dans son domaine d'excellence produit un résultat de meilleure qualité que de forcer l'un à faire le travail de l'autre.

### Maintenabilité et clarté

Un projet qui utilise Terraform pour le provisionnement et Ansible pour la configuration maintient une séparation des préoccupations claire. Un nouveau membre de l'équipe sait immédiatement où chercher : les fichiers `.tf` décrivent **ce qui existe**, les playbooks YAML décrivent **comment c'est configuré**. Cette clarté architecturale est un atout majeur à long terme.

À l'inverse, un projet qui mélange les responsabilités — des provisioners Terraform contenant de longues commandes shell, ou des playbooks Ansible créant des VMs via des modules cloud tout en les configurant dans le même play — produit du code difficile à comprendre, à tester et à maintenir.

### Cycles de vie différents

L'infrastructure et la configuration ont des rythmes de changement différents. Les VMs, les réseaux et les volumes de stockage sont créés une fois et vivent longtemps (jours, semaines, mois). La configuration des services, les mises à jour de sécurité et les déploiements applicatifs changent fréquemment (heures, jours).

Séparer les outils permet de séparer les cycles de vie. On peut exécuter un playbook Ansible pour mettre à jour Nginx sans toucher à l'infrastructure Terraform. On peut modifier la taille d'une VM avec Terraform sans re-jouer toute la configuration Ansible. Cette indépendance réduit le blast radius de chaque opération.

---

## Le flux IaC unifié

Le workflow standard d'une infrastructure gérée par Terraform et Ansible suit un flux en quatre phases.

**Phase 1 — Provisionnement (Terraform).** Terraform crée les ressources d'infrastructure : machines virtuelles Debian (libvirt, cloud), réseaux (VPC, sous-réseaux, VLAN), stockage (volumes, buckets), services réseau (load balancers, DNS), et sécurité réseau (firewall, security groups). Le state Terraform enregistre l'état de ces ressources. Les outputs exposent les informations nécessaires à la suite du workflow : adresses IP, noms DNS, identifiants de ressources.

**Phase 2 — Transition (inventaire dynamique).** Les informations produites par Terraform (adresses IP, rôles, groupes) sont transmises à Ansible sous forme d'inventaire. Cette transition peut être un fichier d'inventaire généré par Terraform, un inventaire dynamique Ansible qui interroge le state Terraform, ou un script d'inventaire personnalisé qui interroge l'API du cloud provider. C'est le pont entre les deux outils, et sa fiabilité conditionne la robustesse de l'ensemble.

**Phase 3 — Configuration (Ansible).** Ansible se connecte aux machines créées par Terraform via SSH et applique la configuration : installation des paquets, déploiement des fichiers de configuration, création des utilisateurs, activation des services, durcissement de la sécurité. Les rôles et playbooks décrits dans la section 13.1 prennent le relais. Le rôle baseline, les rôles applicatifs (nginx, postgresql), et les rôles de sécurité sont exécutés dans l'ordre approprié.

**Phase 4 — Maintenance continue.** Une fois l'infrastructure provisionnée et configurée, les deux outils continuent de vivre indépendamment. Terraform est ré-exécuté pour les modifications d'infrastructure (ajout de serveurs, changement de dimensionnement, modification réseau). Ansible est ré-exécuté pour les mises à jour de configuration, les déploiements applicatifs, les correctifs de sécurité et la détection de drift. Les deux peuvent être déclenchés manuellement, par des pipelines CI/CD (Module 14), ou par des outils d'orchestration (AWX, section 13.1.7).

---

## Points de friction et solutions

L'intégration de deux outils distincts introduit des défis que cette section adresse.

**Le délai de disponibilité.** Après qu'un `terraform apply` ait créé une VM, celle-ci n'est pas immédiatement accessible en SSH. Le système d'exploitation doit démarrer, cloud-init doit s'exécuter, le service SSH doit être prêt. Si Ansible est déclenché trop tôt, la connexion échoue. Les patterns d'attente et de synchronisation sont couverts en section 13.3.1.

**La cohérence de l'inventaire.** L'inventaire Ansible doit refléter fidèlement l'état de l'infrastructure Terraform. Si Terraform détruit une VM mais que l'inventaire Ansible n'est pas mis à jour, Ansible tente de se connecter à une machine inexistante. Les mécanismes d'inventaire dynamique et de régénération automatique sont couverts en section 13.3.2.

**La gestion des secrets.** Terraform stocke certains secrets dans son state (mots de passe de base de données, tokens). Ansible gère ses propres secrets via Vault. La coordination des secrets entre les deux outils — éviter la duplication, garantir la cohérence, centraliser la source de vérité — est un sujet transversal abordé en section 13.3.2.

**L'idempotence globale.** Terraform et Ansible sont individuellement idempotents, mais leur exécution combinée doit l'être aussi. Ré-exécuter le flux complet (Terraform puis Ansible) ne doit produire aucun changement si l'infrastructure est déjà dans l'état souhaité. Les patterns qui garantissent cette propriété globale sont couverts en section 13.3.3.

---

## Ce que couvre cette section

La section 13.3 est structurée en trois sous-sections qui explorent chaque aspect de l'intégration.

La sous-section **13.3.1 — Terraform pour le provisionnement, Ansible pour la configuration** formalise la séparation des responsabilités, présente les patterns de déclenchement (Terraform qui appelle Ansible, pipeline CI/CD qui orchestre les deux, exécution manuelle séquentielle), et détaille les mécanismes d'attente et de synchronisation entre les deux phases.

La sous-section **13.3.2 — Patterns d'intégration et workflows combinés** couvre les mécanismes concrets d'intégration : inventaires dynamiques basés sur le state Terraform, génération de fichiers d'inventaire, passage de variables entre les deux outils, gestion coordonnée des secrets, et workflows complets de bout en bout (provisionnement initial, ajout de capacité, mise à jour, destruction).

La sous-section **13.3.3 — Gestion de l'état et idempotence** traite de la cohérence globale du système : comment garantir que l'état combiné Terraform + Ansible converge vers l'état souhaité, comment détecter et corriger les dérives, comment gérer les situations où l'un des outils a modifié l'infrastructure sans l'autre, et les stratégies de réconciliation.

---

## Prérequis

Cette section synthétise les acquis des deux sections précédentes. Les concepts et compétences suivants sont mobilisés :

- Ansible : inventaires statiques et dynamiques (13.1.2), playbooks et rôles (13.1.3, 13.1.4), provisionnement de nœuds Debian (13.1.5), intégration Kubernetes (13.1.6).
- Terraform : providers, ressources et data sources (13.2.1), déploiements avec libvirt et cloud (13.2.2, 13.2.5), gestion du state et backends (13.2.3), modules et structuration de projet (13.2.4).
- SSH et réseau Debian (Module 6) : les deux outils reposent sur SSH pour la communication avec les nœuds gérés.
- Git (prérequis général) : le code Terraform et Ansible est versionné ensemble ou dans des dépôts coordonnés.

---

## Conventions

Les exemples de cette section utilisent une structure de projet unifiée dans laquelle le code Terraform et le code Ansible cohabitent dans un même dépôt Git, organisé par responsabilité :

```
infrastructure/
├── terraform/                    # Code Terraform
│   ├── environments/
│   │   ├── production/
│   │   └── staging/
│   └── modules/
│       └── debian-vm/
├── ansible/                      # Code Ansible
│   ├── inventory/
│   │   ├── production/
│   │   └── staging/
│   ├── playbooks/
│   │   └── site.yml
│   └── roles/
│       ├── baseline/
│       ├── nginx/
│       └── postgresql/
├── scripts/                      # Scripts d'orchestration
│   └── deploy.sh
├── Makefile                      # Point d'entrée unifié
└── README.md
```

Cette colocation n'est pas obligatoire — certaines organisations préfèrent des dépôts séparés — mais elle simplifie la coordination et garantit que les modifications d'infrastructure et de configuration sont revues ensemble dans les merge requests. Les avantages et inconvénients des deux approches sont discutés en section 13.3.2.

⏭️ [Terraform pour le provisionnement, Ansible pour la configuration](/module-13-infrastructure-as-code/03.1-provisioning-vs-configuration.md)
