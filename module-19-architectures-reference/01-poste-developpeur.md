🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 19.1 Architecture poste développeur cloud-native

## Parcours 1-2 — Du poste bureautique au cockpit cloud-native

---

## Objectifs de la section

À l'issue de cette section, vous serez en mesure de :

- Concevoir l'architecture logicielle et matérielle d'un poste développeur Debian orienté cloud-native.
- Comprendre les interactions entre les couches système, conteneurs, orchestration locale et outillage DevOps.
- Identifier les composants essentiels et leurs rôles dans le workflow quotidien d'un développeur ou d'un SRE.
- Articuler les choix techniques en fonction des contraintes de projet, de performance et de sécurité.

---

## Pourquoi une architecture de référence ?

Dans un contexte professionnel DevOps/SRE, le poste de travail n'est plus un simple terminal bureautique : il devient le **cockpit opérationnel** depuis lequel le développeur ou l'ingénieur infrastructure interagit avec l'ensemble de la chaîne de valeur logicielle. Conteneurs locaux, clusters Kubernetes de développement, pipelines CI/CD, outils d'Infrastructure as Code — tout converge vers une station de travail qui doit être à la fois puissante, reproductible et sécurisée.

Pourtant, la mise en place d'un tel environnement est souvent laissée à l'initiative individuelle, ce qui engendre des problèmes récurrents :

- **Hétérogénéité des environnements** : « Ça marche sur ma machine » reste le symptôme le plus courant d'un manque de standardisation. Quand chaque développeur configure son poste différemment, les écarts entre environnements de développement, de staging et de production se multiplient.
- **Dérive de configuration** : au fil des mois, les installations manuelles, les dépôts ajoutés ponctuellement et les configurations modifiées sans documentation créent un poste fragile, difficile à reproduire en cas de panne ou de changement de matériel.
- **Failles de sécurité silencieuses** : des clés SSH sans passphrase, des tokens en clair dans le shell history, des conteneurs exécutés en root — autant de pratiques qui passent inaperçues sur un poste non standardisé.
- **Perte de productivité** : le temps passé à résoudre des conflits de dépendances, à reconfigurer un outil ou à chercher « comment installer X sur Debian » est du temps soustrait au développement et à l'exploitation.

L'objectif d'une architecture de référence est de répondre à ces problèmes en fournissant un **blueprint documenté, reproductible et évolutif** du poste développeur cloud-native sous Debian.

---

## Positionnement dans la formation

Cette section constitue une **synthèse transversale** qui mobilise les compétences acquises tout au long des Parcours 1 et 2. Elle ne se contente pas de lister des outils : elle les articule dans une architecture cohérente, en expliquant pourquoi chaque composant est présent et comment il s'intègre aux autres.

Le tableau ci-dessous illustre les liens avec les modules précédents :

| Couche de l'architecture | Modules mobilisés | Compétences clés |
|---|---|---|
| Système de base Debian | Modules 1, 3, 4 | Installation, administration, gestion des paquets |
| Bureau et productivité | Module 2 | Environnement graphique, éditeurs, navigateurs |
| Scripting et automatisation | Module 5 | Bash, Python, automatisation du poste |
| Réseau et sécurité | Module 6 | SSH, VPN, pare-feu local, chiffrement |
| Services locaux | Module 7 | Serveur web local, bases de données de dev |
| Virtualisation | Module 9 | KVM, Vagrant, environnements reproductibles |
| Conteneurs | Module 10 | Docker, Podman, images Debian optimisées |
| Kubernetes local | Module 11 | Kind, K3s, MicroK8s pour le développement |
| Infrastructure as Code | Module 13 | Ansible pour le provisionnement du poste |

---

## Vue d'ensemble de l'architecture

L'architecture du poste développeur cloud-native s'organise en **cinq couches fonctionnelles** superposées, chacune apportant un niveau d'abstraction supplémentaire :

```
┌─────────────────────────────────────────────────────────┐
│              5. OUTILLAGE CLOUD & GITOPS                │
│  kubectl · helm · kustomize · argocd-cli · terraform    │
│  ansible · cloud CLIs (aws, gcloud, az)                 │
├─────────────────────────────────────────────────────────┤
│           4. ORCHESTRATION LOCALE (K8S DEV)             │
│  Kind · K3s · MicroK8s · Skaffold · Tilt · Telepresence │
├─────────────────────────────────────────────────────────┤
│              3. CONTENEURS & IMAGES                     │
│  Docker / Podman · Docker Compose · Buildah             │
│  Registry local · Images Debian slim                    │
├─────────────────────────────────────────────────────────┤
│         2. ENVIRONNEMENT DE DÉVELOPPEMENT               │
│  VS Code / IDE · Git · Shell (zsh/bash) · tmux          │
│  Langages & runtimes · Virtualenvs · direnv             │
├─────────────────────────────────────────────────────────┤
│            1. SYSTÈME DE BASE DEBIAN                    │
│  Debian Stable · Firmware · Réseau · Sécurité           │
│  systemd · Wayland/Xorg · PipeWire                      │
└─────────────────────────────────────────────────────────┘
         Matériel : CPU multi-cœurs · 32 Go+ RAM
              SSD NVMe · GPU (optionnel)
```

### Couche 1 — Système de base Debian

Le socle de toute l'architecture repose sur une installation Debian Stable maîtrisée. Le choix de la branche Stable garantit la fiabilité et la prévisibilité du système, tandis que les Backports permettent d'accéder à des versions plus récentes de certains outils critiques (noyau, firmware, pilotes) sans compromettre la stabilité globale.

Cette couche inclut la configuration du noyau (modules nécessaires à la virtualisation et aux conteneurs), la gestion du réseau (NetworkManager pour le desktop, WireGuard pour le VPN d'entreprise), le chiffrement du disque via LUKS, et le durcissement de base du système (pare-feu nftables/ufw, configuration SSH, sudo granulaire).

### Couche 2 — Environnement de développement

C'est la couche avec laquelle le développeur interagit le plus directement. Elle comprend l'environnement de bureau (GNOME ou un tiling window manager selon les préférences), un terminal moderne et un shell correctement configuré (complétion, prompt informatif, alias productifs), un éditeur ou IDE adapté au workflow cloud-native (VS Code avec les extensions Kubernetes, Docker, Remote Containers, ou un éditeur comme Neovim avec une configuration équivalente), ainsi que les runtimes et gestionnaires de versions nécessaires aux projets (Go, Node.js, Python via pyenv/venv, Rust, Java via SDKMAN).

Un point souvent négligé est la gestion de l'isolation des environnements de développement. L'utilisation de `direnv` pour charger automatiquement des variables d'environnement par projet, combinée aux environnements virtuels Python et aux gestionnaires de versions, évite les conflits entre projets et rapproche l'environnement local de celui de production.

### Couche 3 — Conteneurs et images

Le runtime de conteneurs (Docker CE ou Podman en mode rootless) constitue le pivot entre le développement local et le déploiement. Cette couche permet de construire, tester et exécuter des images de conteneurs localement, en reproduisant au plus près les conditions de production.

Docker Compose (ou `podman-compose`) offre la possibilité de décrire et d'orchestrer des stacks multi-conteneurs pour le développement local — par exemple, une application avec sa base de données, son cache Redis et son reverse proxy, le tout défini dans un fichier déclaratif versionné.

L'accent est mis sur les bonnes pratiques de construction d'images : utilisation d'images Debian slim comme base, builds multi-stage pour minimiser la taille finale, scanning de vulnérabilités avec Trivy ou Grype avant tout push vers un registry.

### Couche 4 — Orchestration locale Kubernetes

Pour les projets déployés sur Kubernetes en production, il est indispensable de disposer d'un cluster local de développement. Kind (Kubernetes IN Docker) est la solution la plus légère : elle crée des clusters Kubernetes éphémères dans des conteneurs Docker, idéale pour les tests rapides et l'intégration dans les pipelines CI locaux. K3s offre une alternative plus proche d'un vrai cluster, avec une empreinte mémoire réduite. MicroK8s, quant à lui, fournit un cluster single-node complet avec des add-ons activables à la demande.

Au-delà du cluster lui-même, des outils comme Skaffold et Tilt automatisent la boucle de développement : modification du code → build de l'image → déploiement sur le cluster local → rechargement de l'application. Ce cycle, qui peut prendre plusieurs minutes manuellement, se réduit à quelques secondes.

### Couche 5 — Outillage cloud et GitOps

La couche supérieure regroupe les outils en ligne de commande qui permettent d'interagir avec l'infrastructure distante : `kubectl` pour Kubernetes, `helm` et `kustomize` pour le packaging et la personnalisation des déploiements, les CLI des cloud providers (AWS CLI, gcloud, az), `terraform` pour l'Infrastructure as Code, et `ansible` pour la gestion de configuration.

La gestion des identités et des accès est particulièrement critique à ce niveau : configuration de `kubeconfig` multi-contextes pour naviguer entre clusters de dev, staging et production, authentification MFA vers les cloud providers, stockage sécurisé des credentials (gestionnaire de secrets, pas de tokens en clair dans `.bashrc`).

---

## Considérations matérielles

L'exécution simultanée de conteneurs, d'un cluster Kubernetes local et d'un IDE impose des exigences matérielles significatives. Voici les recommandations par profil d'usage :

| Composant | Usage léger (conteneurs seuls) | Usage standard (K8s local) | Usage intensif (multi-clusters, builds lourds) |
|---|---|---|---|
| CPU | 4 cœurs | 8 cœurs | 12+ cœurs |
| RAM | 16 Go | 32 Go | 64 Go |
| Stockage | 256 Go SSD SATA | 512 Go SSD NVMe | 1 To+ SSD NVMe |
| GPU | Non requis | Optionnel | Recommandé (ML/GPU passthrough) |

La RAM est le facteur le plus critique : un cluster Kind à 3 nœuds consomme facilement 6 à 8 Go, auxquels s'ajoutent l'IDE (1 à 2 Go), le navigateur, les conteneurs applicatifs et le système lui-même. Descendre en dessous de 32 Go pour un usage Kubernetes local conduit rapidement à du swap intensif et à une dégradation notable des performances.

Le SSD NVMe est fortement recommandé car les opérations de build d'images et les I/O des clusters etcd locaux sont très sensibles à la latence disque.

---

## Principes directeurs

L'architecture de référence repose sur plusieurs principes qui guident les choix techniques détaillés dans les sous-sections :

**Reproductibilité avant tout.** Chaque composant du poste doit pouvoir être réinstallé de manière automatisée. Cela passe par un script d'installation versionné (Ansible de préférence, ou un script Bash structuré au minimum), des dotfiles versionnés dans un dépôt Git, et une documentation à jour des choix effectués. L'objectif : pouvoir reconstruire un poste fonctionnel en moins d'une heure à partir d'une installation Debian fraîche.

**Parité dev/prod.** L'environnement local doit reproduire au maximum les conditions de production. Si la production tourne sur Kubernetes avec Nginx Ingress et PostgreSQL, le poste de dev doit disposer d'un cluster local avec les mêmes composants, pas d'un assemblage ad hoc de services lancés directement sur le host. Les conteneurs et les manifestes Kubernetes sont les mêmes du laptop à la production, seules les valeurs de configuration changent.

**Sécurité par défaut.** Le poste développeur a souvent accès à des ressources sensibles : clusters de production, credentials cloud, tokens d'API, clés de signature. La sécurité n'est pas une couche optionnelle mais un aspect intégré à chaque niveau : chiffrement disque, clés SSH ed25519 avec passphrase, agent SSH avec timeout, credentials cloud à durée de vie limitée, conteneurs rootless quand c'est possible.

**Évolutivité modulaire.** Un développeur front-end n'a pas les mêmes besoins qu'un SRE. L'architecture est conçue de manière modulaire : le socle (couches 1 et 2) est commun, les couches supérieures s'activent selon le profil. Un script de provisionnement bien conçu permet de sélectionner les composants à installer via des variables ou des rôles Ansible.

---

## Flux de travail typique

Pour comprendre comment les couches interagissent au quotidien, voici le flux de travail type d'un développeur cloud-native sur ce poste :

1. **Ouverture de session** — Le développeur se connecte sur son bureau Debian. Le VPN d'entreprise (WireGuard) se connecte automatiquement via un service systemd. L'agent SSH charge les clés nécessaires.

2. **Début du travail sur un projet** — Le développeur ouvre un terminal, navigue vers le répertoire du projet. `direnv` charge automatiquement les variables d'environnement du projet (contexte Kubernetes, registry cible, variables applicatives). Le prompt du shell affiche le contexte K8s actif et la branche Git courante.

3. **Développement local** — Le code est modifié dans l'IDE. Skaffold ou Tilt détecte le changement, rebuild l'image du conteneur modifié et le redéploie sur le cluster Kind local. Le développeur vérifie le résultat en quelques secondes via un port-forward ou un ingress local.

4. **Tests et validation** — Les tests unitaires tournent dans un conteneur identique à celui de la CI. Les tests d'intégration s'exécutent contre les services déployés sur le cluster local. Le développeur peut inspecter les logs avec `kubectl logs`, vérifier les métriques avec un Prometheus local, ou debugger un pod directement.

5. **Commit et push** — Le code est poussé sur le dépôt Git. La CI distante (GitLab CI, GitHub Actions) prend le relais pour les étapes de build, test et déploiement sur les environnements partagés. Le développeur suit l'avancement depuis son terminal ou son navigateur.

6. **Opérations infrastructure** — Si le développeur est aussi SRE, il peut basculer de contexte Kubernetes (`kubectx`) vers un cluster de staging ou production, lancer un plan Terraform pour provisionner de nouvelles ressources, ou exécuter un playbook Ansible pour mettre à jour une configuration.

---

## Plan de la section

Cette section se décompose en trois sous-parties qui détaillent chaque aspect de l'architecture :

- **19.1.1 — Configuration complète poste développeur Debian** : installation du système, choix du bureau, configuration du shell, gestion des paquets et des dépôts, sécurisation du poste, automatisation de l'installation.

- **19.1.2 — Environnement de développement K8s local (Kind, Skaffold, Tilt)** : mise en place d'un cluster Kubernetes local, workflow de développement inner-loop, debugging et tests sur cluster local, gestion multi-projets.

- **19.1.3 — Outillage et personnalisation avancée** : CLI cloud, gestion des credentials, dotfiles versionnés, extensions IDE, productivité shell, intégration de l'ensemble dans un workflow GitOps.

---

*Prérequis : Modules 1 à 4 (système Debian), Module 10 (conteneurs), Module 11 (Kubernetes fondamentaux). Les modules 5, 6, 9 et 13 sont recommandés pour une compréhension complète.*

⏭️ [Configuration complète poste développeur Debian](/module-19-architectures-reference/01.1-configuration-poste-debian.md)
