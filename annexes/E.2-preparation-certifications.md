🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe E.2 — Préparation certifications (CKA, CKS, Terraform Associate)

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section fournit un guide de préparation pour les trois certifications professionnelles visées par la formation. Pour chaque certification, elle détaille le format de l'examen, les domaines couverts, la correspondance avec les modules de la formation, les stratégies de passage et les points de vigilance identifiés par les candidats expérimentés.

> **Important** — Les informations ci-dessous (pondération, durée, score de passage, version de Kubernetes) reflètent l'état au moment de la rédaction (édition 2026). Les éditeurs font évoluer régulièrement le contenu de leurs examens. Consulter les sites officiels pour les informations les plus récentes avant de planifier un passage.

> **Certifications « Associate » CNCF préparatoires (KCNA, KCSA)** — Les certifications **KCNA** (Kubernetes and Cloud Native Associate) et **KCSA** (Kubernetes and Cloud Native Security Associate) sont des examens théoriques (multi-choice, 1h30, ~60 questions) sans prérequis, plus accessibles que les CKA/CKS pratiques. Elles servent à valider les fondamentaux et constituent une excellente première étape pour les apprenants qui veulent un jalon intermédiaire avant d'attaquer les examens pratiques. Voir l'annexe D.1 pour les liens officiels et le programme **Kubestronaut** (statut CNCF accordé aux détenteurs des 5 certifications K8s : KCNA + KCSA + CKA + CKAD + CKS).

---

## 1. CKA — Certified Kubernetes Administrator

### Présentation

La CKA est la certification de référence pour les administrateurs Kubernetes. Elle est délivrée par la Linux Foundation et la CNCF. C'est un examen **pratique** : le candidat travaille sur un ou plusieurs clusters Kubernetes réels via un terminal dans le navigateur et doit résoudre entre 15 et 20 tâches dans un temps limité.

### Informations clés

| Élément | Détail |
|---------|--------|
| Éditeur | Linux Foundation / CNCF |
| Format | Examen pratique en ligne, terminal dans le navigateur |
| Durée | 2 heures |
| Score de passage | 66% |
| Nombre de tentatives | 2 incluses dans le prix |
| Validité | 2 ans |
| Prérequis | Aucun (mais expérience opérationnelle fortement recommandée) |
| Ressources autorisées | Documentation officielle kubernetes.io (onglet navigateur dédié) |
| Version Kubernetes | Annoncée sur le site avant l'examen (généralement version N-1 ou N-2) |

### Domaines et pondération

| Domaine | Poids | Modules formation |
|---------|:-----:|:-----------------:|
| Cluster Architecture, Installation and Configuration | 25% | 11 (11.1, 11.2), 12 (12.1) |
| Workloads and Scheduling | 15% | 11 (11.3), 12 (12.4) |
| Services and Networking | 20% | 11 (11.4), 12 (12.2, 12.3) |
| Storage | 10% | 11 (11.5) |
| Troubleshooting | 30% | 11, 12, annexe C.2 |

### Correspondance détaillée avec la formation

**Cluster Architecture, Installation and Configuration (25%)** — Ce domaine couvre l'installation de clusters avec kubeadm, la gestion des certificats, la configuration etcd (sauvegarde/restauration), les upgrades de cluster et la gestion des nœuds. Il correspond directement aux sections 11.1, 11.2, 12.1 et 12.5 de la formation. La restauration d'etcd (annexe C.4, procédure 4) est un sujet récurrent.

**Workloads and Scheduling (15%)** — Ce domaine couvre les Deployments, les ReplicaSets, les DaemonSets, les CronJobs, les ConfigMaps, les Secrets, la gestion des ressources (requests/limits), les taints/tolerations, l'affinité de nœuds et le scaling. Il correspond aux sections 11.3, 12.4 et en partie 12.3 (Kustomize, Helm) de la formation.

**Services and Networking (20%)** — Ce domaine couvre les Services (ClusterIP, NodePort, LoadBalancer), les Ingress, les Network Policies, CoreDNS et le modèle réseau Kubernetes. Il correspond aux sections 11.4, 12.2 et 12.3 de la formation.

**Storage (10%)** — Ce domaine couvre les PersistentVolumes, les PersistentVolumeClaims, les StorageClasses et le provisionnement dynamique. Il correspond à la section 11.5 de la formation.

**Troubleshooting (30%)** — C'est le domaine le plus important en termes de pondération. Il couvre le diagnostic des pods en erreur, des nœuds défaillants, des problèmes réseau et des composants du control plane. Il correspond à l'ensemble des modules 11 et 12 et à l'annexe C.2 (Problèmes courants Kubernetes).

### Compétences clés à maîtriser

Les tâches qui reviennent le plus fréquemment dans l'examen et que le candidat doit savoir réaliser rapidement sont les suivantes.

Installer un cluster avec kubeadm et y ajouter un nœud worker. Réaliser un upgrade de cluster (kubeadm upgrade). Sauvegarder et restaurer etcd. Créer des Deployments, Services, Ingress et Network Policies à partir de spécifications. Configurer RBAC (Role, ClusterRole, RoleBinding, ClusterRoleBinding). Diagnostiquer un pod en CrashLoopBackOff ou ImagePullBackOff et le corriger. Diagnostiquer un nœud NotReady et le remettre en service. Créer des PersistentVolumeClaims et les monter dans des pods. Configurer des ConfigMaps et des Secrets et les injecter dans des pods (volumes et variables d'environnement). Configurer un sidecar container dans un pod (les **native sidecars** sont GA depuis K8s 1.29 et apparaissent à l'examen).

> **Nouveautés 2025-2026** — La révision de scope CKA de février 2025 introduit le **Kubernetes Gateway API** comme alternative à Ingress (HTTPRoute, GatewayClass, Gateway). Maîtriser à la fois les anciennes ressources Ingress et les nouvelles ressources Gateway API. L'examen est aligné sur Kubernetes 1.34/1.35 en mai 2026.

### Stratégie de passage

**Gestion du temps** — Avec 15 à 20 tâches en 2 heures, le temps moyen par tâche est de 6 à 8 minutes. Certaines tâches sont simples (2-3 minutes), d'autres complexes (10-15 minutes). La stratégie recommandée est de faire un premier passage en traitant toutes les tâches faciles et moyennes, puis de revenir sur les tâches difficiles. Chaque tâche est pondérée : vérifier le pourcentage affiché et prioriser les tâches à fort poids.

**Utilisation de la documentation** — La documentation kubernetes.io est autorisée pendant l'examen. L'habitude de naviguer efficacement dans cette documentation est un avantage significatif. Préparer des signets (bookmarks) vers les pages les plus utiles avant l'examen : référence des manifestes YAML (Deployment, Service, Ingress, PV/PVC, NetworkPolicy, RBAC), guide kubeadm, procédure de sauvegarde etcd.

**Maîtrise de kubectl** — La rapidité d'exécution dépend largement de la capacité à générer des manifestes avec kubectl plutôt que de les écrire de zéro.

```bash
# Générer un squelette de manifeste sans le créer
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml  
kubectl create deployment web --image=nginx --replicas=3 --dry-run=client -o yaml > deploy.yaml  
kubectl create service clusterip web --tcp=80:80 --dry-run=client -o yaml > svc.yaml  
kubectl create configmap app-config --from-literal=key=value --dry-run=client -o yaml > cm.yaml  
kubectl create secret generic db-creds --from-literal=password=secret --dry-run=client -o yaml > secret.yaml  
kubectl create role pod-reader --verb=get,list,watch --resource=pods --dry-run=client -o yaml > role.yaml  
kubectl create rolebinding reader --role=pod-reader --user=alice --dry-run=client -o yaml > rb.yaml  
kubectl create ingress web --rule="app.example.com/=web:80" --dry-run=client -o yaml > ingress.yaml  
```

**Alias et raccourcis** — Configurer des alias en début d'examen pour gagner du temps.

```bash
alias k=kubectl  
alias kn='kubectl config set-context --current --namespace'  
export do="--dry-run=client -o yaml"  
# Usage : k run nginx --image=nginx $do > pod.yaml
```

**Habitude du terminal** — L'examen se déroule dans un terminal web. S'entraîner à tout faire en ligne de commande sans interface graphique : édition avec vim ou nano, navigation avec kubectl, copier-coller dans le terminal.

### Points de vigilance

Toujours vérifier le **contexte kubectl** au début de chaque tâche. L'examen utilise plusieurs clusters et la tâche indique quel contexte utiliser. Oublier de changer de contexte est une erreur fréquente qui fait perdre des points sur une tâche correctement réalisée mais sur le mauvais cluster.

Toujours vérifier le **namespace** spécifié dans la tâche. De nombreux candidats perdent des points en créant des ressources dans le namespace `default` alors que la tâche demandait un namespace spécifique.

Ne pas passer plus de **10 minutes sur une seule tâche** lors du premier passage. Marquer la tâche et y revenir ensuite. Le score de passage est de 66%, ce qui signifie qu'il est possible de rater un tiers des tâches et de réussir quand même.

---

## 2. CKS — Certified Kubernetes Security Specialist

### Présentation

La CKS est la certification avancée de sécurité Kubernetes. Elle est construite sur les acquis de la CKA et ajoute une couche de compétences en sécurité du cluster, des workloads et de la supply chain. Le format est identique à la CKA : examen pratique sur des clusters réels.

### Informations clés

| Élément | Détail |
|---------|--------|
| Éditeur | Linux Foundation / CNCF |
| Format | Examen pratique en ligne, terminal dans le navigateur |
| Durée | 2 heures |
| Score de passage | 67% |
| Nombre de tentatives | 2 incluses dans le prix |
| Validité | 2 ans |
| Prérequis | CKA valide (obligatoire) |
| Ressources autorisées | Documentation kubernetes.io et outils spécifiques autorisés |

### Domaines et pondération

> **Note** — Pondération révisée le 15 octobre 2024 et toujours en vigueur pour le blueprint v1.34 (2026) : Cluster Setup passe de 10% à **15%**, System Hardening passe de 15% à **10%**.

| Domaine | Poids | Modules formation |
|---------|:-----:|:-----------------:|
| Cluster Setup | 15% | 12 (12.1, 12.2), 16 (16.2) |
| Cluster Hardening | 15% | 12 (12.2), 16 (16.1, 16.2) |
| System Hardening | 10% | 16 (16.1), 6 (6.2, 6.3) |
| Minimize Microservice Vulnerabilities | 20% | 10 (10.5), 16 (16.2, 16.3) |
| Supply Chain Security | 20% | 16 (16.4), 10 (10.5) |
| Monitoring, Logging and Runtime Security | 20% | 15 (15.1, 15.3), 16 (16.2, 16.4) |

### Correspondance détaillée avec la formation

**Cluster Setup (15%)** — Configuration sécurisée de l'API server, utilisation de Network Policies pour isoler les namespaces, configuration des Ingress avec TLS, vérification des binaires Kubernetes (sha256 et signatures). Correspond aux modules 12.1, 12.2 et 16.2.

**Cluster Hardening (15%)** — RBAC avancé (least privilege, audit des permissions), restriction des ServiceAccounts, mise à jour du cluster, protection de l'API server (audit logging, admission controllers). Correspond aux modules 12.2 et 16.2.

**System Hardening (10%)** — Durcissement du système d'exploitation hôte (les nœuds Debian), AppArmor, Seccomp, réduction de la surface d'attaque (services inutiles, ports ouverts), gestion des utilisateurs. Correspond directement au module 16.1 et aux sections réseau/sécurité du module 6.

**Minimize Microservice Vulnerabilities (20%)** — Pod Security Standards, SecurityContext, gestion des secrets (Vault, external-secrets), isolation des conteneurs (capabilities, readOnlyRootFilesystem), OPA Gatekeeper ou Kyverno. Correspond aux modules 10.5, 16.2 et 16.3.

**Supply Chain Security (20%)** — Scanning d'images (Trivy), signature d'images (Cosign), analyse des Dockerfiles, vérification de l'intégrité des images, registries privés, SBOM. Correspond aux modules 16.4 et 10.5.

**Monitoring, Logging and Runtime Security (20%)** — Audit logs Kubernetes, Falco pour la détection runtime, analyse comportementale, investigation d'incidents dans un cluster. Correspond aux modules 15 et 16.4.

### Compétences clés à maîtriser

Les tâches typiques de la CKS incluent les suivantes.

Configurer les Pod Security Standards sur un namespace (labels pod-security.kubernetes.io). Écrire et appliquer une Network Policy pour isoler un namespace. Configurer un SecurityContext restrictif (runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities). Créer un profil AppArmor et l'appliquer à un pod. Configurer l'audit logging de l'API server. Scanner une image avec Trivy et identifier les vulnérabilités critiques. Corriger un Dockerfile pour éliminer les mauvaises pratiques de sécurité (utilisateur root, secrets en dur, base image vulnérable). Configurer RBAC pour appliquer le principle of least privilege. Identifier une activité suspecte dans les audit logs ou les alertes Falco. Créer une règle d'admission avec OPA Gatekeeper.

### Stratégie spécifique CKS

**Prérequis CKA solide** — La CKS exige une CKA valide et suppose une maîtrise complète des compétences CKA. Les tâches CKS ne reviennent pas sur les fondamentaux : elles ajoutent la dimension sécurité. Un candidat qui n'est pas à l'aise avec kubectl, les manifestes YAML et le diagnostic de pods perdra trop de temps sur les manipulations de base.

**Connaître les emplacements des fichiers sur les nœuds** — Plusieurs tâches CKS nécessitent de modifier des fichiers sur les nœuds du cluster via SSH : manifestes des pods statiques (`/etc/kubernetes/manifests/`), configuration du kubelet (`/var/lib/kubelet/config.yaml`), configuration de l'API server, profils AppArmor (`/etc/apparmor.d/`). La connaissance de ces chemins (documentée dans l'annexe B.1) fait gagner un temps précieux.

**Pratiquer les Network Policies** — Les Network Policies sont un sujet récurrent et source d'erreurs. S'entraîner à écrire des policies d'ingress et d'egress avec des sélecteurs de pods et de namespaces, et à vérifier leur effet.

**Documentation autorisée** — En plus de kubernetes.io, les documentations de certains outils sont autorisées (Falco, Trivy, AppArmor). La liste exacte est indiquée dans les instructions de l'examen. Préparer des signets vers les pages les plus utiles de chaque documentation autorisée.

### Points de vigilance

Les tâches CKS demandent souvent de **modifier la configuration de l'API server** via son manifeste statique. Après modification, l'API server redémarre automatiquement (le kubelet détecte le changement). Attendre 30 à 60 secondes que le pod statique redémarre avant de continuer. Si l'API server ne revient pas, l'erreur est dans le manifeste : vérifier les logs avec `crictl logs`.

La CKS teste la capacité à **identifier les problèmes de sécurité** autant qu'à les corriger. Certaines tâches demandent d'auditer une configuration existante et de lister les non-conformités, pas seulement d'appliquer un correctif.

---

## 3. Terraform Associate

### Présentation

La certification Terraform Associate valide les compétences fondamentales sur Terraform : concepts d'Infrastructure as Code, syntaxe HCL, workflow Terraform, gestion de l'état et utilisation des modules. Contrairement à la CKA et la CKS, c'est un examen **théorique à choix multiples**.

> **Note sur OpenTofu** — Il n'existe pas (pour l'instant) de certification équivalente pour OpenTofu, le fork open source de Terraform sous Linux Foundation. La certification Terraform Associate reste donc la référence pour valider les compétences IaC. Comme OpenTofu est un drop-in replacement de Terraform 1.5.x avec la même syntaxe HCL et le même workflow CLI, les compétences acquises lors de la préparation s'appliquent intégralement aux deux outils. Le seul domaine **HCP Terraform** (10 % de l'examen) n'a pas d'équivalent OpenTofu et reste spécifique à HashiCorp.

### Informations clés

| Élément | Détail |
|---------|--------|
| Éditeur | HashiCorp |
| Version courante | **004** (depuis le 8 janvier 2026, remplace la 003) |
| Format | QCM en ligne (choix multiples, vrai/faux, multi-select) |
| Durée | 1 heure (~60 questions) |
| Score de passage | 70% |
| Nombre de tentatives | 1 incluse, retake payant |
| Validité | 2 ans |
| Prérequis | Aucun |
| Ressources autorisées | Aucune (examen surveillé, aucun document) |
| Version Terraform de référence | 1.12 (vs 1.3 pour la 003) |

### Domaines et pondération

| Domaine | Poids | Modules formation |
|---------|:-----:|:-----------------:|
| Understand Infrastructure as Code concepts | 10-15% | 13 (13.1, 13.2, 13.3) |
| Understand the purpose of Terraform | 10-15% | 13 (13.2) |
| Understand Terraform basics | 15-20% | 13 (13.2) |
| Use Terraform CLI | 15-20% | 13 (13.2) |
| Interact with Terraform modules | 10-15% | 13 (13.2) |
| Use the core Terraform workflow | 15-20% | 13 (13.2, 13.3) |
| Implement and maintain state | 10-15% | 13 (13.2) |
| Read, generate, and modify configuration | 10-15% | 13 (13.2) |
| Understand HCP Terraform capabilities | 5-10% | — |

### Correspondance détaillée avec la formation

Le module 13 couvre la très grande majorité du périmètre de l'examen. Les sections 13.2.1 à 13.2.5 correspondent directement aux domaines Terraform basics, CLI, modules, workflow et state. La section 13.3 sur la complémentarité Ansible/Terraform apporte la perspective IaC globale demandée dans le premier domaine.

Le domaine sur HCP Terraform (anciennement Terraform Cloud/Enterprise) n'est pas explicitement couvert par la formation. Il porte sur les fonctionnalités de la plateforme SaaS de HashiCorp : workspaces distants, exécution distante des plans, gestion des variables et intégration VCS. La documentation officielle de HCP Terraform suffit pour couvrir ce domaine qui représente un poids faible dans l'examen.

### Compétences clés à maîtriser

**Concepts IaC** — Expliquer les avantages de l'Infrastructure as Code (reproductibilité, versionning, collaboration, automatisation). Distinguer les approches déclaratives et impératives. Comprendre l'idempotence.

**Workflow Terraform** — Maîtriser le cycle `init` → `plan` → `apply` et comprendre ce que fait chaque commande. Savoir quand utiliser `destroy`, `import`, `taint` (déprécié, remplacé par `-replace`), `refresh`.

**Syntaxe HCL** — Écrire des blocs `resource`, `variable`, `output`, `data`, `locals`, `provider` et `terraform`. Comprendre les types (string, number, bool, list, map, object). Utiliser les fonctions courantes (`length`, `lookup`, `merge`, `join`, `file`, `templatefile`). Maîtriser `count`, `for_each` et les expressions conditionnelles.

**Gestion de l'état** — Expliquer le rôle du fichier d'état et ses risques. Configurer un backend distant (S3, Consul, etc.). Comprendre le locking de l'état. Savoir utiliser `state list`, `state show`, `state mv`, `state rm`.

**Modules** — Comprendre la structure d'un module (inputs, outputs, ressources). Savoir utiliser des modules depuis le registre Terraform et depuis des sources locales ou Git. Comprendre le versionning des modules.

**Provisioners** — Comprendre que les provisioners (local-exec, remote-exec) sont un dernier recours et connaître les alternatives recommandées (user_data, Ansible, cloud-init).

### Stratégie de passage

**C'est un examen de connaissances, pas de pratique** — Contrairement à la CKA, il n'y a pas de cluster ni de terminal. Les questions testent la compréhension des concepts, la connaissance de la syntaxe et la capacité à lire et interpréter du code HCL. Un candidat qui a une bonne pratique de Terraform mais qui n'a pas révisé les détails théoriques peut être surpris par des questions sur les nuances des backends, les méta-arguments ou les fonctions moins courantes.

**Étudier la documentation officielle** — HashiCorp publie un guide de révision structuré par domaine. Le parcourir systématiquement en vérifiant la compréhension de chaque concept. La page « Study Guide — Terraform Associate » sur le site de HashiCorp fournit les liens vers les sections de documentation pertinentes pour chaque objectif.

**Pratiquer la lecture de code** — Plusieurs questions présentent un extrait de code HCL et demandent de prédire son comportement : quelle ressource sera créée, quelle valeur aura une variable, que se passera-t-il si on exécute `terraform apply`. S'entraîner à lire du code Terraform sans l'exécuter.

**Points spécifiques à réviser** — Les différences entre `variable`, `local` et `output`. Le comportement de `count` vs `for_each`. Les types de backends et leurs caractéristiques. Les méta-arguments (`depends_on`, `lifecycle`, `provider`). La différence entre `terraform plan` et `terraform apply` en termes de locking. Les workspaces et leur impact sur l'état.

**Nouveautés introduites par la version 004 (alignée Terraform 1.12)** — Les **lifecycle rules** avancées (`replace_triggered_by`, `precondition`, `postcondition`). Les **custom validation rules** sur les variables (validation d'entrée avec `condition`/`error_message`). Les **ephemeral values** et **write-only arguments** (gestion sécurisée des données transitoires comme les mots de passe en mémoire seulement). L'organisation **HCP Terraform Workspaces et Projects** pour structurer les environnements multi-équipes.

### Points de vigilance

L'examen inclut des questions sur **HCP Terraform** (anciennement Terraform Cloud) qui ne sont pas couvertes par la pratique locale de Terraform. Consacrer du temps à la documentation de HCP Terraform, même sans y avoir accès en pratique.

Certaines questions portent sur des **commandes moins courantes** : `terraform console`, `terraform graph`, `terraform force-unlock`, `terraform workspace`. Les avoir utilisées au moins une fois facilite la réponse.

Les questions de type **« texte à compléter »** demandent de connaître la syntaxe exacte (nom des blocs, des méta-arguments, des fonctions). La pratique régulière de l'écriture de code Terraform est le meilleur moyen de les préparer.

---

## 4. Plan de préparation type

Le plan suivant est adaptable selon le niveau de départ et la certification visée. Il suppose que l'apprenant a suivi les modules correspondants de la formation et dispose d'une base pratique.

### CKA — Plan sur 6 à 8 semaines

**Semaines 1-2 : Révision des fondamentaux.** Revoir les modules 11 et 12. S'assurer que toutes les compétences listées en E.1 pour ces modules sont au niveau O. Reprendre les commandes kubectl de l'annexe A.3.

**Semaines 3-4 : Pratique intensive.** Monter un cluster kubeadm sur des VM Debian (ou utiliser un environnement cloud). Réaliser chaque tâche de la liste des compétences clés CKA au moins trois fois sans documentation. Chronométrer les opérations pour atteindre les temps cibles.

**Semaines 5-6 : Examens blancs.** Utiliser les simulateurs d'examen disponibles en ligne (killer.sh, fourni avec l'inscription à l'examen, offre deux sessions de pratique). Travailler en conditions réelles : 2 heures, terminal uniquement, documentation kubernetes.io uniquement. Identifier les faiblesses et les combler.

**Semaines 7-8 : Consolidation.** Revoir les domaines faibles identifiés. Pratiquer les tâches de troubleshooting (annexe C.2). Passer un dernier examen blanc 2-3 jours avant la date de l'examen réel.

### CKS — Plan sur 4 à 6 semaines (après CKA)

**Semaines 1-2 : Modules sécurité.** Revoir le module 16 en profondeur. Pratiquer les Network Policies, les SecurityContext, AppArmor et les Pod Security Standards.

**Semaines 3-4 : Outils spécifiques.** Pratiquer Trivy (scanning d'images), OPA Gatekeeper (contraintes), l'audit logging de l'API server et Falco. Maîtriser la modification des manifestes du control plane.

**Semaines 5-6 : Examens blancs et consolidation.** Utiliser killer.sh (inclus dans l'inscription CKS). Travailler en conditions réelles. Consolider les faiblesses.

### Terraform Associate — Plan sur 3 à 4 semaines

**Semaine 1 : Révision du module 13.** Revoir les concepts, la syntaxe HCL, le workflow et la gestion de l'état. Lire le guide d'étude officiel de HashiCorp.

**Semaine 2 : Approfondissement.** Étudier les domaines moins pratiqués : fonctions HCL avancées, workspaces, provisioners, HCP Terraform. Lire la documentation officielle section par section.

**Semaine 3 : Entraînement QCM.** Utiliser les questions d'entraînement disponibles en ligne. Se concentrer sur la lecture de code HCL et la prédiction du comportement.

**Semaine 4 : Révision finale.** Revoir les points faibles identifiés. Relire le guide d'étude une dernière fois. Passer l'examen.

---

## 5. Ressources de préparation

### CKA et CKS

**killer.sh** — Simulateur d'examen officiel, inclus dans le prix de l'inscription (2 sessions). L'environnement et le format sont identiques à l'examen réel. C'est la ressource de préparation la plus fidèle. La difficulté est volontairement supérieure à celle de l'examen réel pour que le candidat se sente à l'aise le jour J.

**Documentation Kubernetes** — `https://kubernetes.io/docs/` — La documentation autorisée pendant l'examen. S'entraîner à y naviguer rapidement est une compétence en soi. Les pages les plus consultées pendant l'examen sont les références des ressources (Deployment, Service, Ingress, NetworkPolicy, PV/PVC, RBAC), le guide kubeadm et la procédure de sauvegarde etcd.

**kubectl explain** — La commande `kubectl explain <ressource>.spec.<champ>` est disponible pendant l'examen et fournit la documentation de chaque champ sans quitter le terminal.

**Kubernetes the Hard Way** — Guide de Kelsey Hightower (`https://github.com/kelseyhightower/kubernetes-the-hard-way`) pour installer Kubernetes composant par composant. Non requis pour la CKA mais excellente ressource pour comprendre l'architecture en profondeur.

### Terraform Associate

**Guide d'étude HashiCorp** — `https://developer.hashicorp.com/terraform/tutorials/certification-004` — Guide officiel structuré par objectif d'examen avec des liens vers la documentation pertinente. C'est le point de départ de la préparation. **Important : la version 004 a remplacé la 003 le 8 janvier 2026** ; la 003 n'est plus disponible. La 004 est alignée sur Terraform 1.12 et introduit de nouveaux thèmes (lifecycle rules avancées, custom validation rules, ephemeral values et write-only arguments, projets HCP Terraform).

**Documentation Terraform** — `https://developer.hashicorp.com/terraform/docs` — La documentation officielle est la source principale pour la préparation. La lire systématiquement, section par section, en parallèle de la pratique.

**Terraform Tutorials** — `https://developer.hashicorp.com/terraform/tutorials` — Tutoriels guidés couvrant les concepts fondamentaux. Utiles pour valider la compréhension pratique de chaque fonctionnalité.

---

## 6. Le jour de l'examen

### CKA et CKS — Examens pratiques

**Avant l'examen** — Vérifier les prérequis techniques (navigateur compatible, webcam, micro, connexion internet stable). L'examen est surveillé à distance (proctoring) : préparer une pièce calme, un bureau dégagé et une pièce d'identité. Se connecter 15 minutes avant l'heure prévue pour la vérification d'identité.

**Pendant l'examen** — Lire l'énoncé de chaque tâche intégralement avant de commencer. Vérifier le contexte kubectl et le namespace demandés. Utiliser le notepad intégré pour copier les noms de ressources complexes. Ne pas hésiter à marquer une tâche et à y revenir plus tard. Garder 10 à 15 minutes à la fin pour relire les tâches traitées.

**Gestion du stress** — L'environnement de l'examen peut être plus lent que l'environnement d'entraînement (latence réseau du terminal distant). Prévoir une marge dans la gestion du temps. Si une tâche semble impossible, passer à la suivante : le score de passage (66-67%) permet de rater plusieurs tâches.

### Terraform Associate — Examen QCM

**Avant l'examen** — Mêmes prérequis techniques que pour les examens Linux Foundation. L'examen est surveillé à distance.

**Pendant l'examen** — Lire chaque question attentivement, y compris les réponses « distrayantes » qui semblent correctes mais comportent une nuance. Pour les questions de code, vérifier mentalement chaque ligne. Utiliser la fonction de marquage pour les questions incertaines et y revenir en fin d'examen.

---

## 7. Après la certification

L'obtention de la certification n'est pas une fin mais un jalon. Les certifications **CKA, CKAD et CKS sont valides 2 ans** depuis le changement de politique du 1er avril 2024 (les certifications obtenues avant cette date conservent leur validité originale de 3 ans). Le renouvellement consiste à repasser et réussir l'examen avant l'expiration ; la nouvelle validité est de 2 ans à partir de la date de réussite.

> **Nouveau — CNCF CARE Program (2026)** — Le **Certification Advancement & Recertification Experience** annoncé en mars 2026 (effectif depuis le 1er janvier 2026, implémentation complète en juin 2026) simplifie la maintenance des certifications. Une certification de niveau supérieur **renouvelle automatiquement** la certification fondationnelle correspondante :  
> - Réussir/recertifier **CKA** ou **CKAD** → renouvelle automatiquement **KCNA**  
> - Réussir/recertifier **CKS** → renouvelle automatiquement **KCSA**  
>  
> Les candidats qui obtiennent ou recertifient une certification éligible entre le 1er janvier 2026 et la date d'implémentation complète sont **grandfathered** dans la nouvelle structure de renouvellement. L'objectif est d'éviter aux praticiens expérimentés de devoir maintenir manuellement les certifications d'entrée déjà démontrées.

Pour maintenir et approfondir les compétences certifiées, la pratique régulière est indispensable. Administrer des clusters en production, contribuer à des projets open source, participer aux communautés (Slack Kubernetes, forums HashiCorp) et suivre les évolutions des outils (nouvelles versions, fonctionnalités dépréciées, changements d'API) sont les meilleurs moyens de progresser au-delà du périmètre de la certification.

La combinaison **CKA + CKS + Terraform Associate** constitue un profil de compétences reconnu et recherché sur le marché DevOps/SRE. Elle atteste d'une maîtrise à la fois de l'administration Kubernetes, de la sécurité cloud-native et de l'Infrastructure as Code, couvrant les trois piliers de l'ingénierie d'infrastructure moderne.

⏭️ [Cas d'usage métier et architectures sectorielles](/annexes/E.3-cas-usage-metier.md)
