🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 10.5 Sécurité des conteneurs

## Prérequis

- Maîtrise des fondamentaux des conteneurs : namespaces, cgroups v2, OverlayFS (section 10.1)
- Connaissance pratique de Docker et/ou Podman (sections 10.2, 10.3)
- Familiarité avec les conteneurs système Incus (section 10.4)
- Notions de sécurité Linux : utilisateurs, permissions, pare-feu (Module 6)
- Compréhension de la construction d'images (section 10.2.2)

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Appliquer le principe du moindre privilège à chaque couche de l'architecture conteneur
- Configurer les mécanismes de sécurité du noyau (seccomp, AppArmor, capabilities) pour les conteneurs
- Comprendre les avantages et limites des conteneurs rootless
- Mettre en place le scanning d'images pour détecter les vulnérabilités avant le déploiement
- Intégrer la sécurité dans le cycle de vie complet des conteneurs, de la construction au runtime

## Introduction

Les conteneurs sont souvent perçus comme intrinsèquement sûrs parce qu'ils sont « isolés ». Cette perception est dangereusement inexacte. Comme détaillé en section 10.1.1, les conteneurs partagent le noyau de l'hôte et reposent sur des mécanismes d'isolation **logique** (namespaces) plutôt que **matérielle** (hyperviseur). Un conteneur mal configuré peut compromettre l'hôte, accéder aux données d'autres conteneurs ou servir de point d'entrée pour un attaquant.

La sécurité des conteneurs n'est pas un problème unique résolu par un outil unique. C'est une discipline transversale qui touche chaque étape du cycle de vie : la construction de l'image, la configuration du runtime, le réseau, le stockage, la chaîne d'approvisionnement logicielle et la surveillance en production.

### Le modèle de menaces

Pour structurer l'approche de sécurité, il est utile d'identifier les principaux vecteurs de menace spécifiques aux conteneurs :

**Évasion du conteneur (container escape)** — Un attaquant exploite une vulnérabilité du noyau ou une mauvaise configuration pour sortir des namespaces du conteneur et accéder à l'hôte. C'est la menace la plus grave. Les vulnérabilités comme CVE-2019-5736 (runc, écrasement du binaire runc depuis le conteneur), CVE-2020-15257 (containerd-shim, sockets Unix abstraits exposés) et plus récemment **CVE-2024-21626 (« Leaky Vessels » sur runc, janvier 2024, fuite de file descriptors via le working directory)** ont démontré que ces évasions ne sont pas théoriques mais exploitées dans la nature. La leçon : maintenir l'hôte à jour est aussi critique pour la sécurité des conteneurs que pour celle du système hôte lui-même.

**Image compromise** — L'image contient du code malveillant (malware, backdoor, cryptominer), des vulnérabilités connues dans ses dépendances (CVE non corrigées), ou des secrets intégrés par erreur (clés API, tokens, mots de passe). Le problème est amplifié par la chaîne de confiance : une image de base compromise affecte toutes les images dérivées.

**Élévation de privilèges** — Un processus dans le conteneur acquiert des privilèges supérieurs à ceux prévus : passage de non-root à root, acquisition de capabilities Linux, exploitation de binaires setuid, ou accès au socket Docker qui confère un accès root effectif sur l'hôte.

**Mouvement latéral** — Un conteneur compromis est utilisé pour atteindre d'autres conteneurs ou services sur le même réseau. L'absence de segmentation réseau et les configurations par défaut permissives (tous les conteneurs sur le même bridge) facilitent ce vecteur.

**Déni de service** — Un conteneur monopolise les ressources de l'hôte (CPU, mémoire, disque, réseau, PIDs) en l'absence de limites configurées, rendant les autres conteneurs et l'hôte lui-même indisponibles.

**Exposition de données sensibles** — Secrets stockés en variables d'environnement (visibles via `docker inspect`), fichiers de configuration montés sans restriction, volumes partagés avec des permissions trop larges, ou logs contenant des informations sensibles.

### La défense en profondeur

La sécurité des conteneurs repose sur le principe de la **défense en profondeur** : superposer plusieurs couches de protection de sorte que la compromission d'une couche ne suffise pas à compromettre le système entier.

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Couche 7 : Chaîne d'approvisionnement                     │
│   Signatures d'images, SBOM, provenance, registre privé     │
│                                                             │
│   Couche 6 : Image                                          │
│   Scanning CVE, image minimale, pas de secrets, non-root    │
│                                                             │
│   Couche 5 : Orchestration                                  │
│   Network Policies, Pod Security Standards, RBAC            │
│                                                             │
│   Couche 4 : Runtime                                        │
│   Rootless, read-only rootfs, no-new-privileges             │
│                                                             │
│   Couche 3 : Noyau — Contrôle d'accès mandataire            │
│   AppArmor, SELinux, seccomp                                │
│                                                             │
│   Couche 2 : Noyau — Isolation                              │
│   Namespaces, cgroups v2, capabilities                      │
│                                                             │
│   Couche 1 : Hôte                                           │
│   Noyau à jour, hardening système, mises à jour, audit      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Chaque couche réduit le risque résiduel laissé par la couche précédente. Un conteneur sécurisé combine : un hôte durci (couche 1), une isolation noyau correcte (couche 2), des filtres seccomp et des profils AppArmor (couche 3), un runtime rootless avec rootfs en lecture seule (couche 4), une orchestration avec des politiques réseau (couche 5), une image minimale et scannée (couche 6), et une chaîne d'approvisionnement vérifiable (couche 7).

### Sécurité transversale : Docker, Podman et Incus

Cette section est **transversale** : les principes et mécanismes de sécurité s'appliquent aux conteneurs applicatifs (Docker, Podman) comme aux conteneurs système (Incus), bien que les configurations spécifiques diffèrent.

| Mécanisme de sécurité | Docker | Podman | Incus |
|---|---|---|---|
| User namespaces | Optionnel (rootless) | Par défaut (rootless) | Systématique (non-privilégié) |
| Seccomp | Profil par défaut | Profil par défaut | Profil par défaut |
| AppArmor | Profil par défaut | Profil par défaut | Profil strict par défaut |
| Capabilities | Ensemble restreint par défaut | Ensemble restreint par défaut | Ensemble minimal |
| Rootless | Supporté (ajout tardif) | Natif (par conception) | Conteneurs non-privilégiés par défaut |
| Read-only rootfs | `--read-only` | `--read-only` | Configurable |
| Cgroups v2 limits | `--memory`, `--cpus` | `--memory`, `--cpus` | `limits.memory`, `limits.cpu` |
| Scanning d'images | Docker Scout, Trivy, Grype | Trivy, Grype | `trivy fs` sur rootfs, debsecan, OpenSCAP |
| Réseau isolé | Réseaux user-defined | Réseaux user-defined | Bridges dédiés, `internal` |
| Signatures d'images | Cosign/Sigstore (DCT obsolète) | Cosign, Sigstore (`podman pull --signature-policy`) | Fingerprints SHA256 + index simplestreams signés GPG |

Podman offre l'architecture la plus sûre par défaut (pas de daemon root, rootless natif), mais les trois outils peuvent être configurés pour atteindre un niveau de sécurité élevé.

### Ce que nous allons couvrir

Cette section se décompose en quatre sous-sections qui traitent la sécurité à chaque étape du cycle de vie :

- **10.5.1 — Principes de sécurité (least privilege, immutabilité)** : les principes fondamentaux de sécurité appliqués aux conteneurs — moindre privilège, surface d'attaque minimale, immutabilité, défense en profondeur — avec des recommandations concrètes à chaque niveau (image, runtime, réseau, stockage).

- **10.5.2 — Conteneurs rootless et capabilities** : fonctionnement détaillé du mode rootless (Docker et Podman), mappage des user namespaces, capabilities Linux (le système de décomposition des privilèges root) et configuration du jeu de capabilities minimal pour chaque conteneur.

- **10.5.3 — Seccomp et AppArmor pour conteneurs** : filtrage des appels système avec seccomp (profils par défaut, profils personnalisés), contrôle d'accès mandataire avec AppArmor sur Debian (profils de confinement, personnalisation), et interaction entre les deux mécanismes.

- **10.5.4 — Scanning d'images (Trivy, Grype)** : détection des vulnérabilités dans les images de conteneurs, analyse des dépendances (CVE), intégration dans les pipelines CI/CD, stratégies de remédiation et politique de gestion des vulnérabilités.

### Positionnement dans la formation

La sécurité des conteneurs est abordée ici au niveau des mécanismes fondamentaux. Le Module 16 (Sécurité avancée et cloud-native) approfondira ces sujets dans le contexte de Kubernetes et des pipelines DevSecOps : RBAC Kubernetes, Pod Security Standards, OPA Gatekeeper, Falco (runtime security), supply chain security (SBOM, Cosign, SLSA), et compliance automation.

```
Module 10.5 — Sécurité des conteneurs
  │
  │  Fondamentaux : principes, rootless, seccomp,
  │  AppArmor, capabilities, scanning d'images
  │
  ▼
Module 16 — Sécurité avancée et cloud-native
  │
  │  Approfondissement : hardening Debian, sécurité K8s,
  │  Policy as Code, runtime security (Falco),
  │  supply chain (SBOM, Cosign), DevSecOps
  │
  ▼
Module 19 — Architectures de référence
     Mise en pratique intégrée : sécurité de bout en bout
```

La sécurité n'est pas une destination mais un processus continu. Les mécanismes présentés dans cette section constituent le socle sur lequel les protections plus avancées des modules suivants seront construites.

---

> **Navigation**  
>  
> Section précédente : [10.4.4 Intégration réseau](/module-10-conteneurs/04.4-integration-reseau.md)  
>  
> Section suivante : [10.5.1 Principes de sécurité (least privilege, immutabilité)](/module-10-conteneurs/05.1-principes-securite.md)

⏭️ [Principes de sécurité (least privilege, immutabilité)](/module-10-conteneurs/05.1-principes-securite.md)
