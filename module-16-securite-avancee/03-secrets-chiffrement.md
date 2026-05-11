🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 16.3 Secrets et chiffrement

## Prérequis

- Maîtrise du hardening système Debian (section 16.1), en particulier le chiffrement des données avec LUKS/dm-crypt (module 6.4.4) et la sécurisation de la chaîne de démarrage (section 16.1.4)
- Connaissance approfondie de l'architecture Kubernetes et du RBAC (sections 16.2.1 et 16.2.2)
- Familiarité avec les concepts de certificats X.509, PKI et TLS (module 6.4.3 et 7.2.5)
- Expérience avec les déploiements applicatifs sur Kubernetes (ConfigMaps, Secrets, Deployments)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre le cycle de vie complet des secrets dans un environnement Debian/Kubernetes et les risques associés à chaque étape
- Déployer, configurer et opérer HashiCorp Vault sur Debian pour la gestion centralisée des secrets, avec intégration native Kubernetes
- Maîtriser les mécanismes natifs de Kubernetes Secrets et les étendre avec l'External Secrets Operator pour fédérer des sources de secrets externes
- Automatiser la gestion du cycle de vie des certificats TLS avec cert-manager dans un cluster Kubernetes
- Implémenter le chiffrement des données au repos (*at-rest*) et en transit (*in-transit*) à chaque couche de l'infrastructure

---

## Introduction

Les sections précédentes ont sécurisé l'accès au cluster (RBAC), contrôlé ce qui peut y être déployé (PSA, Gatekeeper), détecté les comportements anormaux (Falco) et segmenté le réseau (Cilium). Mais toutes ces protections deviennent caduques si les **secrets** — mots de passe, clés API, tokens d'accès, certificats TLS, clés de chiffrement — sont exposés. Un mot de passe de base de données en clair dans un ConfigMap, un token d'API committé dans un dépôt Git, ou une clé privée TLS stockée sans chiffrement dans etcd annulent l'ensemble de la posture de sécurité.

La gestion des secrets est un défi transversal qui touche chaque couche de l'infrastructure : le système d'exploitation Debian (mots de passe, clés SSH, certificats de services), la plateforme Kubernetes (Secrets API, tokens de service accounts, certificats du control plane) et les applications (identifiants de bases de données, clés d'API tierces, secrets de session). À chaque couche, les secrets doivent être protégés tout au long de leur cycle de vie — de leur création à leur révocation — et à chaque état — au repos sur disque, en transit sur le réseau, et en mémoire dans les processus.

## Le problème fondamental des secrets

### Le cycle de vie d'un secret

Un secret traverse plusieurs étapes au cours de sa vie, et chaque étape présente des risques spécifiques :

```
┌───────────────┐
│   CRÉATION    │  Comment le secret est-il généré ?
│               │  Entropie suffisante ? Générateur sécurisé ?
└───────┬───────┘
        │
        ▼
┌───────────────┐
│   STOCKAGE    │  Où le secret est-il persisté ?
│               │  Chiffré au repos ? Contrôle d'accès ?
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ DISTRIBUTION  │  Comment le secret arrive-t-il à l'application ?
│               │  Canal chiffré ? Exposition minimale ?
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  UTILISATION  │  Comment l'application accède-t-elle au secret ?
│               │  En mémoire uniquement ? Pas de log ?
└───────┬───────┘
        │
        ▼
┌───────────────┐
│   ROTATION    │  Le secret est-il changé régulièrement ?
│               │  Sans interruption de service ?
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  RÉVOCATION   │  Le secret peut-il être invalidé immédiatement ?
│               │  En cas de compromission, quel est le délai ?
└───────────────┘
```

Une solution de gestion des secrets complète doit adresser **chaque** étape de ce cycle. Les approches naïves (fichiers en clair, variables d'environnement, secrets dans le code) échouent systématiquement sur au moins une de ces étapes.

### Les anti-patterns courants

Les erreurs de gestion des secrets les plus fréquentes dans les environnements Debian et Kubernetes illustrent les risques à chaque étape du cycle :

**Secrets dans le code source.** Le pattern le plus dangereux : un mot de passe ou une clé API codé en dur dans un fichier de configuration, un script Bash ou un Dockerfile, puis poussé dans un dépôt Git. Une fois committé, le secret est dans l'historique Git, potentiellement répliqué sur les postes de tous les développeurs, les serveurs CI/CD et les sauvegardes. La suppression du fichier n'efface pas l'historique. Les scanners publics (comme les bots qui scrutent GitHub) détectent ces secrets en quelques minutes.

**Kubernetes Secrets en base64.** Un malentendu courant est de considérer l'encodage base64 des Kubernetes Secrets comme du chiffrement. Base64 est un encodage réversible, pas un mécanisme de sécurité. Sans chiffrement at-rest activé sur etcd, un accès en lecture à etcd expose tous les secrets du cluster en clair. Un simple `echo "cGFzc3dvcmQ=" | base64 -d` révèle le contenu.

**Variables d'environnement.** Injecter les secrets via des variables d'environnement (`env` dans le manifeste Kubernetes) est une pratique courante mais problématique. Les variables d'environnement sont visibles dans `/proc/<pid>/environ`, dans les logs de crash dump, dans les outputs de `kubectl describe pod`, et peuvent être capturées par des outils de debugging ou de monitoring. Elles ne sont jamais rotées sans redémarrage du pod.

**Secrets partagés entre environnements.** Utiliser les mêmes identifiants en développement, staging et production est une invitation au désastre. La compromission d'un environnement de développement (souvent moins protégé) compromet directement la production.

**Absence de rotation.** Un secret qui n'a jamais été changé depuis sa création accumule le risque. Plus un secret est vieux, plus la probabilité qu'il ait été exposé (dans un log, un dump, un backup non chiffré, un poste de développeur compromis) augmente.

### Les dimensions du chiffrement

La protection des secrets s'articule autour de deux dimensions fondamentales de chiffrement, souvent confondues :

**Chiffrement at-rest** (*au repos*) — protège les données stockées sur un support persistant : disques durs, SSD, sauvegardes, exports de base de données. Si un disque est volé ou un backup compromis, les données chiffrées at-rest restent illisibles sans la clé de déchiffrement. Sur Debian, LUKS/dm-crypt assure le chiffrement au niveau du bloc (section 6.4.4). Dans Kubernetes, le chiffrement at-rest d'etcd protège les Secrets stockés dans la base du cluster.

**Chiffrement in-transit** (*en transit*) — protège les données pendant leur transmission sur le réseau. TLS est le standard pour le chiffrement in-transit, qu'il s'agisse des communications entre les composants Kubernetes (API Server ↔ etcd, kubelet ↔ API Server), du trafic applicatif (HTTPS), ou des connexions aux bases de données (PostgreSQL avec `sslmode=verify-full`). Le mTLS (mutual TLS, couvert dans le module 17.2 sur les Service Meshes) étend ce modèle en authentifiant les deux parties de chaque connexion.

```
                    Cycle de vie d'un secret
                    et dimensions de chiffrement

  Création ──► Stockage ──► Distribution ──► Utilisation
                  │               │
           Chiffrement       Chiffrement
             at-rest          in-transit
                  │               │
           LUKS (disque)     TLS (réseau)
           etcd encryption   mTLS (service mesh)
           Vault backend     Vault transit engine
           KMS (cloud)       Network Policies (L7)
```

## Les secrets dans l'écosystème Debian/Kubernetes

### Couche système Debian

Au niveau du système d'exploitation Debian, les secrets prennent plusieurs formes :

- **Mots de passe système** : stockés hashés dans `/etc/shadow` (protégé par les permissions 640 et audité par `auditd`, cf. section 16.1.3)
- **Clés SSH** : clés privées dans `~/.ssh/` ou `/etc/ssh/` (protégées par les permissions 600, potentiellement stockées dans un agent SSH ou un module hardware)
- **Certificats TLS des services** : clés privées des serveurs web, des bases de données, des services mail (protégées par les permissions, AppArmor, et idéalement générées/rotées par un outil automatisé)
- **Clés de chiffrement LUKS** : la clé maîtresse du chiffrement disque (protégée par un passphrase et/ou un TPM, cf. section 16.1.4)
- **Tokens et clés API** : stockés dans des fichiers de configuration de services (doivent être protégés par les permissions et idéalement externalisés vers un gestionnaire de secrets)

### Couche Kubernetes

Dans un cluster Kubernetes, les secrets circulent à travers plusieurs composants :

```
┌─────────────────────────────────────────────────────────────┐
│                    Secrets dans Kubernetes                  │
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │ API Server  │───▶│    etcd      │    │  Volumes     │    │
│  │             │    │              │    │  projetés    │    │
│  │ Reçoit les  │    │ Stocke les   │    │  dans les    │    │
│  │ Secrets via │    │ Secrets      │    │  pods        │    │
│  │ l'API       │    │ (at-rest)    │    │              │    │
│  └──────┬──────┘    └──────────────┘    └──────┬───────┘    │
│         │                                      │            │
│         │ RBAC contrôle                        │ Le pod     │
│         │ qui peut lire/écrire                 │ lit le     │
│         │ les Secrets                          │ secret     │
│         │                                      │ depuis     │
│         ▼                                      │ un volume  │
│  ┌─────────────┐    ┌──────────────┐           │ ou une     │
│  │  kubelet    │───▶│ Container    │◀──────────┘ variable   │
│  │             │    │ runtime      │  d'env                 │
│  │ Transmet le │    │              │                        │
│  │ secret au   │    │ Monte le     │                        │
│  │ pod via le  │    │ volume tmpfs │                        │
│  │ runtime     │    │ dans le pod  │                        │
│  └─────────────┘    └──────────────┘                        │ 
│                                                             │
│  Points de risque :                                         │
│  ① etcd non chiffré → secrets lisibles            
│  ② RBAC trop permissif → lecture non autorisée    
│  ③ Variables d'env → exposition dans les logs     
│  ④ Image avec secrets embarqués → fuite via       
│     le registry                                   
│  ⑤ Backup etcd non chiffré → fuite offline       
└─────────────────────────────────────────────────────────────┘
```

Les Kubernetes Secrets natifs offrent un mécanisme de base — stockage dans etcd, distribution via volumes montés ou variables d'environnement, contrôle d'accès via RBAC — mais présentent des lacunes que les outils couverts dans les sous-sections suivantes comblent.

### Couche applicative

Les applications elles-mêmes manipulent des secrets pour se connecter aux services dont elles dépendent : chaînes de connexion aux bases de données, clés d'API pour les services tiers (paiement, notification, stockage cloud), secrets de session pour l'authentification des utilisateurs, clés de chiffrement applicatives pour les données sensibles. La responsabilité de la gestion de ces secrets est partagée entre l'équipe plateforme (qui fournit les mécanismes de distribution sécurisée) et les équipes de développement (qui consomment les secrets de manière sûre sans les exposer dans les logs ou les réponses API).

## Les solutions de gestion des secrets

### Cartographie des outils

L'écosystème des outils de gestion des secrets couvre un spectre allant du stockage sécurisé centralisé à l'automatisation du cycle de vie des certificats :

```
Complexité croissante ──────────────────────────────────────►

┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐
│  Kubernetes  │  │   External   │  │   HashiCorp Vault    │
│  Secrets     │  │   Secrets    │  │                      │
│  natifs      │  │   Operator   │  │  Gestion centralisée │
│              │  │              │  │  Rotation dynamique  │
│  + Encryption│  │  Fédération  │  │  Audit trail         │
│    at-rest   │  │  multi-source│  │  Politiques d'accès  │
│              │  │  (Vault, AWS,│  │  Transit encryption  │
│  Base        │  │   GCP, etc.) │  │  PKI intégrée        │
└──────────────┘  └──────────────┘  └──────────────────────┘
        │                │                     │
        └────────────────┴─────────────────────┘
                         │
                   ┌─────┴──────┐
                   │cert-manager│
                   │            │
                   │ Cycle de   │
                   │ vie des    │
                   │ certificats│
                   │ TLS        │
                   └────────────┘
```

**HashiCorp Vault** (section 16.3.1) est la solution la plus complète pour la gestion centralisée des secrets. Il fournit un stockage sécurisé, la rotation dynamique des identifiants (génération à la demande d'identifiants de base de données éphémères), le chiffrement en tant que service (transit engine), une PKI intégrée, et un audit log détaillé de chaque accès à un secret.

**Kubernetes Secrets + External Secrets Operator** (section 16.3.2) offrent un modèle pragmatique pour les organisations qui ne souhaitent pas opérer un Vault dédié. Les Kubernetes Secrets natifs, correctement configurés avec le chiffrement at-rest, fournissent la base. L'External Secrets Operator les étend en synchronisant automatiquement les secrets depuis des sources externes (Vault, AWS Secrets Manager, Google Secret Manager, Azure Key Vault) vers des Kubernetes Secrets, sans que les applications aient besoin de connaître la source réelle.

**cert-manager** (section 16.3.3) automatise spécifiquement le cycle de vie des certificats TLS dans Kubernetes. Il gère l'émission, le renouvellement et la distribution des certificats depuis des autorités de certification variées (Let's Encrypt, Vault PKI, CA interne), éliminant la gestion manuelle des certificats qui est une source récurrente d'incidents (certificats expirés, rotation oubliée).

**Le chiffrement at-rest et in-transit** (section 16.3.4) couvre les mécanismes transversaux de protection des données à chaque couche : chiffrement d'etcd, chiffrement des disques des nœuds, TLS entre les composants Kubernetes, TLS pour les connexions applicatives, et mTLS pour l'authentification mutuelle.

### Choisir la bonne approche

Le choix entre ces solutions dépend de la taille de l'organisation, des exigences réglementaires et de la maturité opérationnelle :

| Contexte | Approche recommandée |
|---|---|
| **Petit cluster, équipe réduite** | Kubernetes Secrets + chiffrement at-rest etcd + cert-manager |
| **Organisation moyenne, multi-clusters** | External Secrets Operator + Vault (ou cloud KMS) + cert-manager |
| **Grande organisation, conformité réglementaire** | Vault en HA + ESO + cert-manager + audit complet + rotation dynamique |
| **Environnement cloud managé (EKS, GKE, AKS)** | Cloud KMS + ESO + cert-manager |

Ces approches ne sont pas mutuellement exclusives. Un déploiement mature combine typiquement Vault pour le stockage et la rotation, ESO pour la distribution vers Kubernetes, cert-manager pour les certificats TLS, et le chiffrement at-rest/in-transit comme couche transversale.

## Plan de la section

Cette section est organisée en quatre sous-parties, chacune couvrant un aspect de la gestion des secrets et du chiffrement :

**16.3.1 — HashiCorp Vault** : installation et configuration sur Debian, architecture HA, intégration avec Kubernetes (auth method, sidecar injector, CSI provider), rotation dynamique des secrets de bases de données, transit engine pour le chiffrement applicatif.

**16.3.2 — Kubernetes Secrets et External Secrets Operator** : fonctionnement interne des Kubernetes Secrets, bonnes pratiques de distribution (volumes vs variables d'environnement), chiffrement at-rest d'etcd, déploiement et configuration de l'External Secrets Operator pour fédérer des sources externes.

**16.3.3 — cert-manager et gestion des certificats** : architecture de cert-manager, Issuers et ClusterIssuers (Let's Encrypt, Vault PKI, CA interne), émission et renouvellement automatique de certificats, intégration avec les Ingress Controllers et les Service Meshes.

**16.3.4 — Chiffrement at-rest et in-transit** : chiffrement des volumes de données avec LUKS sur les nœuds Debian, chiffrement at-rest d'etcd avec les EncryptionConfiguration Kubernetes, TLS entre les composants du cluster, TLS pour les connexions applicatives, mTLS et WireGuard pour le chiffrement inter-nœuds.

---

## Résumé

> La gestion des secrets et le chiffrement constituent la couche de protection des données sensibles dans un environnement Debian/Kubernetes. Les secrets — mots de passe, clés API, tokens, certificats — doivent être protégés à chaque étape de leur cycle de vie (création, stockage, distribution, utilisation, rotation, révocation) et dans chaque état (au repos sur disque, en transit sur le réseau, en mémoire). Les anti-patterns courants — secrets dans le code source, base64 confondu avec du chiffrement, variables d'environnement exposées, absence de rotation — compromettent l'ensemble de la posture de sécurité indépendamment de la qualité des autres mécanismes de défense. Les solutions s'organisent en un spectre de complexité croissante : les **Kubernetes Secrets** natifs avec chiffrement at-rest pour la base, l'**External Secrets Operator** pour la fédération de sources externes, **HashiCorp Vault** pour la gestion centralisée avec rotation dynamique et audit complet, **cert-manager** pour l'automatisation du cycle de vie des certificats TLS, et le **chiffrement at-rest/in-transit** comme couche transversale protégeant les données à chaque niveau de l'infrastructure. Les quatre sous-sections suivantes détaillent la mise en œuvre de chaque composant.

⏭️ [HashiCorp Vault (installation sur Debian, intégration K8s)](/module-16-securite-avancee/03.1-hashicorp-vault.md)
