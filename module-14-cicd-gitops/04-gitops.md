🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 14.4 GitOps

## Introduction

Les sections précédentes ont traité du CI/CD selon un modèle **push** : un pipeline détecte un changement dans le code source, construit un artefact, puis **pousse** cet artefact vers l'environnement cible via des commandes impératives — `kubectl apply`, `helm upgrade`, `ansible-playbook`. Le pipeline est l'acteur : c'est lui qui se connecte au cluster Kubernetes, s'authentifie, et applique les modifications.

Ce modèle fonctionne, mais il présente des faiblesses structurelles qui deviennent visibles à mesure que l'infrastructure grandit :

- **Dérive de configuration.** Un administrateur exécute un `kubectl edit` ou un `helm upgrade` directement sur le cluster pour corriger un incident urgent. Ce changement n'est reflété nulle part dans Git. Le cluster et le dépôt divergent silencieusement — et au prochain déploiement, le pipeline écrase la correction manuelle ou la perpétue sans trace.
- **Opacité de l'état.** Quel est l'état actuel du cluster ? La réponse se trouve dans le cluster lui-même (`kubectl get`), pas dans un système de versioning. Deux clusters censés être identiques finissent par diverger sans que personne ne s'en aperçoive.
- **Credentials de déploiement dans le pipeline.** Le pipeline doit disposer d'un kubeconfig ou d'un token avec les permissions de créer, modifier et supprimer des ressources Kubernetes. Ce secret, stocké dans les variables CI, est un vecteur d'attaque : un pipeline compromis obtient un accès direct au cluster.
- **Absence de boucle de réconciliation.** Si quelqu'un modifie manuellement une ressource sur le cluster, le pipeline ne le sait pas. La modification persiste jusqu'au prochain déploiement — si celui-ci couvre la ressource modifiée.

Le **GitOps** résout ces problèmes en renversant le modèle. Au lieu que le pipeline pousse les changements vers le cluster, un **opérateur** déployé dans le cluster **tire** continuellement l'état souhaité depuis Git et le réconcilie avec l'état réel du cluster. Git devient la **seule source de vérité** pour l'état de l'infrastructure et des applications.

---

## Du CI/CD classique au GitOps

### Le modèle push (CI/CD classique)

```
Développeur                Pipeline CI/CD               Cluster K8s
    │                           │                            │
    │  git push                 │                            │
    ├──────────────────────────▸│                            │
    │                           │  kubectl apply / helm      │
    │                           ├───────────────────────────▸│
    │                           │  (credentials dans le      │
    │                           │   pipeline)                │
    │                           │                            │
    │                    Le pipeline pousse                  │
    │                    les changements                     │
```

Le pipeline est l'acteur central. Il détient les credentials et exécute les commandes de déploiement. Si le pipeline ne s'exécute pas, rien ne se passe — même si Git contient des changements non déployés.

### Le modèle pull (GitOps)

```
Développeur           Dépôt Git                Opérateur GitOps       Cluster K8s
    │                     │                    (ArgoCD / Flux)           │
    │  git push           │                         │                    │
    ├────────────────────▸│                         │                    │
    │                     │   Surveille en continu  │                    │
    │                     │◀────────────────────────┤                    │
    │                     │                         │                    │
    │                     │   Détecte un écart      │                    │
    │                     │   (diff Git vs cluster) │                    │
    │                     │                         │  Réconcilie        │
    │                     │                         ├───────────────────▸│
    │                     │                         │  (credentials      │
    │                     │                         │   dans le cluster) │
    │                     │                         │                    │
    │               L'opérateur tire                                     │
    │               les changements                                      │
```

L'opérateur GitOps est un composant déployé **dans** le cluster Kubernetes. Il surveille un dépôt Git, compare en permanence l'état souhaité (Git) avec l'état réel (cluster), et réconcilie automatiquement les écarts. Les credentials ne quittent jamais le cluster — le pipeline CI n'a plus besoin d'accès au cluster.

---

## Positionnement du GitOps dans le Module 14

Le GitOps n'est pas un remplacement du CI/CD : c'est son **prolongement naturel** pour la partie déploiement. Le pipeline CI reste responsable du build, des tests et de la publication de l'artefact. Le GitOps prend le relais pour le déploiement.

```
┌──────────────────────────────────────────────────────────────────┐
│                     CI (inchangé)                                │
│                                                                  │
│  git push ──▸ build ──▸ test ──▸ scan ──▸ publish image          │
│                                              │                   │
└──────────────────────────────────────────────┼───────────────────┘
                                               │
                                               ▼
                                    Mise à jour du tag image
                                    dans le dépôt de config Git
                                               │
┌──────────────────────────────────────────────┼───────────────────┐
│                     CD via GitOps            │                   │
│                                              ▼                   │
│  Opérateur GitOps détecte le changement dans Git                 │
│  Compare l'état souhaité (Git) avec l'état réel (cluster)        │
│  Applique les manifestes mis à jour                              │
│  Surveille le rollout, reporte le statut                         │
└──────────────────────────────────────────────────────────────────┘
```

Cette séparation entre CI et CD est un principe fondamental du GitOps. Le pipeline CI produit l'artefact et met à jour le dépôt de configuration ; l'opérateur GitOps déploie. Les deux systèmes communiquent exclusivement via Git — un protocole que les deux comprennent, qui offre un historique complet et qui est protégeable par les mécanismes standards (branches protégées, merge requests, signatures de commits).

---

## Lien avec les modules précédents

Le GitOps s'appuie sur des concepts et des compétences introduits tout au long de cette formation :

| Concept | Module source | Application dans le GitOps |
|---------|---------------|---------------------------|
| Modèle déclaratif Kubernetes | Module 11 (§ 11.1.4) | L'état souhaité est décrit dans des manifestes YAML ; l'opérateur réconcilie |
| Helm et Kustomize | Module 12 (§ 12.3) | Les manifestes déployés par l'opérateur sont des charts Helm ou des overlays Kustomize |
| Infrastructure as Code | Module 13 | Le GitOps étend le principe IaC au déploiement continu |
| Pipelines CI/CD | Sections 14.1-14.3 | Le pipeline CI produit les artefacts consommés par le GitOps |
| Gestion des secrets | Module 16 (§ 16.3) | Les secrets dans un dépôt Git doivent être chiffrés (Sealed Secrets, SOPS) |

Le lien avec le Module 11 est particulièrement étroit. La **boucle de réconciliation** de Kubernetes — un contrôleur surveille l'état souhaité (la spec d'un Deployment) et ajuste en permanence l'état réel (les pods) — est exactement le modèle que le GitOps applique à un niveau supérieur : l'opérateur GitOps surveille l'état souhaité (le dépôt Git) et ajuste en permanence l'état réel (le cluster entier).

---

## Les deux opérateurs majeurs

L'écosystème GitOps est dominé par deux projets open source, tous deux incubés ou diplômés au sein de la Cloud Native Computing Foundation (CNCF) :

### ArgoCD (section 14.4.2)

ArgoCD est l'opérateur GitOps le plus répandu. Il fournit une **interface web riche** de visualisation de l'état des applications, un CLI puissant, et un modèle d'Application Kubernetes qui décrit la correspondance entre un dépôt Git et un namespace cible. ArgoCD excelle dans la visibilité : son dashboard affiche en temps réel l'arbre des ressources Kubernetes, les écarts détectés, l'historique des synchronisations et le statut de santé de chaque composant.

### Flux (section 14.4.3)

Flux, initialement créé par Weaveworks puis devenu projet CNCF diplômé (la maintenance est désormais portée par la communauté Flux après la fermeture de Weaveworks en février 2024), adopte une philosophie différente : pas d'interface web centrale, mais un ensemble de **contrôleurs Kubernetes spécialisés** (source-controller, kustomize-controller, helm-controller, notification-controller) qui fonctionnent de manière composable. Flux est plus léger qu'ArgoCD, plus « Kubernetes-native » dans son approche, et s'intègre naturellement dans un workflow entièrement piloté par `kubectl` et des manifestes YAML.

Le choix entre ArgoCD et Flux sera détaillé dans les sections dédiées et synthétisé dans la comparaison de la section 14.4.4.

---

## Le défi des secrets

Le GitOps repose sur un principe simple : tout l'état souhaité du cluster est dans Git. Mais ce principe se heurte à un obstacle majeur : les **secrets** (mots de passe, tokens, clés d'API) ne doivent **jamais** être stockés en clair dans un dépôt Git, même privé.

Ce défi est suffisamment important pour justifier une section dédiée (14.4.5) qui couvrira les deux approches dominantes :

- **Sealed Secrets** — Les secrets sont chiffrés côté client avec une clé publique ; seul le contrôleur dans le cluster peut les déchiffrer avec la clé privée. Le secret chiffré (SealedSecret) peut être commité dans Git en toute sécurité.
- **SOPS (Secrets OPerationS)** — Un outil initialement développé par Mozilla et transféré à la CNCF en mai 2023 (organisation `getsops` sur GitHub) qui chiffre les valeurs sensibles dans les fichiers YAML/JSON tout en laissant les clés en clair. Compatible avec les clés GPG, AWS KMS, GCP KMS et Azure Key Vault. Intégré nativement dans Flux via le kustomize-controller.

---

## Plan de la section

- **14.4.1** — Principes GitOps et avantages
- **14.4.2** — ArgoCD : architecture et configuration
- **14.4.3** — Flux : architecture et configuration
- **14.4.4** — Déploiement automatisé multi-environnement
- **14.4.5** — Gestion des secrets dans un workflow GitOps (Sealed Secrets, SOPS)

---

*La section suivante (14.4.1) formalisera les quatre principes fondamentaux du GitOps tels que définis par l'OpenGitOps Working Group, détaillera les bénéfices concrets en termes de fiabilité, de sécurité et d'auditabilité, et clarifiera les prérequis organisationnels nécessaires à une adoption réussie.*

⏭️ [Principes GitOps et avantages](/module-14-cicd-gitops/04.1-principes-gitops.md)
