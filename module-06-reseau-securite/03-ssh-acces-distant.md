🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 6.3 SSH et accès distant

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre le protocole SSH, son architecture et ses mécanismes cryptographiques
- Installer, configurer et sécuriser un serveur OpenSSH sous Debian
- Maîtriser l'authentification par clés et la gestion des agents SSH
- Exploiter les fonctionnalités avancées (tunneling, port forwarding, jump hosts)
- Appliquer les bonnes pratiques de sécurisation SSH en production

## Prérequis

- Section 6.1 : Configuration réseau (interfaces, routage, diagnostic)
- Section 6.2 : Pare-feu et sécurité (nftables, fail2ban)
- Module 3, section 3.4 : systemd (gestion des services)
- Notions de base en cryptographie (chiffrement symétrique/asymétrique, hachage)

---

## Introduction

SSH (Secure Shell) est le protocole d'accès distant standard pour l'administration des systèmes Linux et Unix. Il fournit un canal de communication chiffré et authentifié sur un réseau non sécurisé, remplaçant les protocoles historiques non chiffrés (Telnet, rsh, rlogin) dont le trafic — mots de passe inclus — circulait en clair.

Au-delà du simple shell distant, SSH est devenu un couteau suisse de l'administration système : transfert de fichiers sécurisé (SCP, SFTP), tunneling de ports, proxy SOCKS, rebond entre machines (jump hosts), exécution de commandes à distance, et même montage de systèmes de fichiers distants (SSHFS). C'est le fondement de l'accès distant sécurisé dans pratiquement tout environnement professionnel.

**OpenSSH** est l'implémentation SSH de référence, développée par le projet OpenBSD. C'est l'implémentation installée par défaut sur Debian et sur la quasi-totalité des distributions Linux. Elle comprend le serveur (`sshd`), le client (`ssh`), et une suite d'outils associés (`ssh-keygen`, `ssh-agent`, `ssh-copy-id`, `scp`, `sftp`).

## Le protocole SSH

### Architecture du protocole

SSH est un protocole en couches, défini principalement par les RFC 4251 à 4254. Il se compose de trois sous-protocoles qui s'empilent :

```text
┌──────────────────────────────────────────────────┐
│       Couche connexion (SSH-CONNECT)             │
│  Multiplexage de canaux : shell, transfert de    │
│  fichiers, port forwarding, agent forwarding     │
├──────────────────────────────────────────────────┤
│    Couche authentification (SSH-USERAUTH)        │
│  Authentification du client auprès du serveur :  │
│  mot de passe, clé publique, GSSAPI, certificat  │
├──────────────────────────────────────────────────┤
│       Couche transport (SSH-TRANS)               │
│  Négociation des algorithmes, échange de clés,   │
│  chiffrement, intégrité, compression             │
├──────────────────────────────────────────────────┤
│              TCP (port 22)                       │
└──────────────────────────────────────────────────┘
```

**La couche transport** est la fondation. Elle établit le canal chiffré entre le client et le serveur. Lors de la connexion, client et serveur négocient les algorithmes cryptographiques (échange de clés, chiffrement symétrique, MAC, compression) et effectuent un échange de clés Diffie-Hellman (ou sa variante sur courbes elliptiques) pour établir un secret partagé. C'est aussi à cette étape que le client vérifie l'identité du serveur via sa clé d'hôte (host key).

**La couche authentification** vérifie l'identité du client. Le serveur propose un ou plusieurs mécanismes d'authentification (mot de passe, clé publique, certificat, GSSAPI/Kerberos), et le client choisit celui qu'il utilise. L'authentification par clé publique est la méthode recommandée.

**La couche connexion** multiplexe le canal chiffré unique en plusieurs canaux logiques indépendants. Chaque session de shell interactif, chaque transfert de fichier, chaque tunnel de port forwarding est un canal distinct, tous transportés dans la même connexion TCP.

### Établissement d'une connexion SSH

Le processus complet d'une connexion SSH suit une séquence précise :

```text
    Client                                          Serveur
      │                                                │
      │─── 1. Connexion TCP (port 22) ────────────────>│
      │                                                │
      │<── 2. Échange de bannières de version ────────>│
      │    "SSH-2.0-OpenSSH_10.0"                       │
      │                                                │
      │<── 3. Négociation des algorithmes ────────────>│
      │    (KEX, chiffrement, MAC, compression)        │
      │                                                │
      │<── 4. Échange de clés (Diffie-Hellman) ───────>│
      │    → Secret partagé établi                     │
      │    → Le client vérifie la clé d'hôte           │
      │      du serveur (known_hosts)                  │
      │                                                │
      │════ Canal chiffré établi ══════════════════════│
      │                                                │
      │─── 5. Authentification du client ─────────────>│
      │    (clé publique, mot de passe, etc.)          │
      │                                                │
      │<── 6. Authentification acceptée ───────────────│
      │                                                │
      │─── 7. Ouverture de canal ─────────────────────>│
      │    (session shell, exec, subsystem)            │
      │                                                │
      │<── 8. Session interactive ────────────────────>│
      │                                                │
```

### Vérification de la clé d'hôte

Lors de la première connexion à un serveur, le client SSH affiche l'empreinte (fingerprint) de la clé d'hôte du serveur et demande confirmation :

```
The authenticity of host 'serveur.exemple.lan (192.168.1.50)' can't be established.  
ED25519 key fingerprint is SHA256:xB3p2kGT5r4N1vqP8dJm6sK9hL7wE2yU0tR4oA8fXc.  
Are you sure you want to continue connecting (yes/no/[fingerprint])?  
```

Ce mécanisme protège contre les attaques man-in-the-middle (MITM). Si un attaquant se place entre le client et le serveur, il ne pourra pas présenter la bonne clé d'hôte. Le client affichera un avertissement si la clé diffère de celle mémorisée :

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Ce message ne doit jamais être ignoré sans vérification. Il peut indiquer un changement légitime (réinstallation du serveur, changement de clé) ou une attaque active.

Les clés d'hôte connues sont stockées dans `~/.ssh/known_hosts` (par utilisateur) et `/etc/ssh/ssh_known_hosts` (global). Chaque entrée associe un nom d'hôte ou une adresse IP à l'empreinte de sa clé publique.

### Algorithmes cryptographiques

SSH utilise plusieurs familles d'algorithmes à différentes étapes de la connexion :

**Échange de clés (KEX)** — Établit le secret partagé entre client et serveur sans le transmettre sur le réseau. Les algorithmes modernes recommandés sont `curve25519-sha256` (courbe elliptique Curve25519, rapide et considéré comme très sûr) et `diffie-hellman-group16-sha512` (DH classique avec un groupe de 4096 bits). Les anciens algorithmes comme `diffie-hellman-group1-sha1` et `diffie-hellman-group14-sha1` sont obsolètes.

**Clés d'hôte et clés utilisateur** — Algorithmes de signature pour l'authentification. Les types recommandés par ordre de préférence sont `ssh-ed25519` (courbe elliptique Edwards, clés compactes, très performant, considéré comme le meilleur choix actuel), `ecdsa-sha2-nistp256` (courbe NIST P-256, largement supporté), et `rsa-sha2-512` (RSA avec hash SHA-512, pour la compatibilité — nécessite des clés d'au moins 3072 bits). Le type `ssh-rsa` (RSA avec SHA-1) est désactivé par défaut depuis OpenSSH 8.8 en raison de la faiblesse de SHA-1.

**Chiffrement symétrique** — Protège le contenu de la communication une fois le secret partagé établi. Les algorithmes modernes sont `chacha20-poly1305@openssh.com` (ChaCha20 avec authentification Poly1305, conçu par djb, très performant sur les processeurs sans accélération AES) et `aes256-gcm@openssh.com` (AES-256 en mode GCM avec authentification intégrée, performant sur les processeurs avec AES-NI). Les modes CBC (`aes256-cbc`, etc.) sont obsolètes et vulnérables à certaines attaques.

**MAC (Message Authentication Code)** — Garantit l'intégrité des données transmises. Les modes GCM et ChaCha20-Poly1305 intègrent leur propre authentification (AEAD), rendant un MAC séparé inutile. Pour les chiffrements non-AEAD, les MAC recommandés sont `hmac-sha2-256-etm@openssh.com` et `hmac-sha2-512-etm@openssh.com` (le suffixe `etm` signifie Encrypt-then-MAC, plus sûr que MAC-then-Encrypt).

### Méthodes d'authentification

SSH supporte plusieurs méthodes d'authentification, listées ici de la plus sûre à la moins sûre :

**Certificats SSH** — Les clés utilisateur et d'hôte sont signées par une autorité de certification (CA) SSH. Le serveur fait confiance à la CA et accepte toute clé signée par elle, sans avoir besoin de distribuer les clés publiques individuellement. C'est la méthode la plus scalable pour les grandes infrastructures.

**Clé publique** — Le client prouve qu'il possède la clé privée correspondant à une clé publique enregistrée sur le serveur (dans `~/.ssh/authorized_keys`). C'est la méthode recommandée pour l'usage courant. Elle est résistante aux attaques par force brute (pas de mot de passe à deviner) et peut être protégée par une passphrase sur la clé privée.

**GSSAPI / Kerberos** — Authentification via un ticket Kerberos, utilisée dans les environnements Active Directory ou les infrastructures avec un KDC. Pas de mot de passe échangé, authentification centralisée.

**Mot de passe** — Le client envoie un mot de passe au serveur via le canal chiffré. Simple à mettre en place mais vulnérable aux attaques par force brute et au credential stuffing. Le mot de passe peut être capturé si le serveur est compromis. C'est la méthode à désactiver en production dès que l'authentification par clé est en place.

**Keyboard-interactive** — Méthode flexible qui permet au serveur de poser une série de questions au client (utilisée par PAM pour l'authentification multi-facteurs, les OTP, etc.).

## Composants d'OpenSSH sur Debian

L'écosystème OpenSSH sur Debian comprend deux paquets principaux et une suite d'outils :

**Côté serveur — paquet `openssh-server` :**

- `sshd` : le démon SSH qui écoute les connexions entrantes
- `/etc/ssh/sshd_config` : fichier de configuration principal du serveur
- `/etc/ssh/sshd_config.d/` : répertoire d'includes pour la configuration modulaire
- `/etc/ssh/ssh_host_*_key` : clés d'hôte du serveur (une paire par algorithme)

**Côté client — paquet `openssh-client` (installé par défaut) :**

- `ssh` : le client de connexion
- `scp` : copie de fichiers (protocole legacy, SFTP préféré)
- `sftp` : transfert de fichiers sécurisé (subsystem SSH)
- `ssh-keygen` : génération et gestion de paires de clés
- `ssh-copy-id` : installation d'une clé publique sur un serveur distant
- `ssh-agent` : agent de gestion des clés en mémoire
- `ssh-add` : ajout de clés à l'agent
- `ssh-keyscan` : récupération des clés d'hôte d'un serveur
- `/etc/ssh/ssh_config` : configuration globale du client
- `~/.ssh/config` : configuration personnelle du client
- `~/.ssh/known_hosts` : base des clés d'hôte connues
- `~/.ssh/authorized_keys` : clés publiques autorisées (côté serveur, dans le home de l'utilisateur)

## Le répertoire ~/.ssh

Le répertoire `~/.ssh` est le centre névralgique de la configuration SSH côté utilisateur. Ses fichiers et leurs permissions sont critiques pour la sécurité :

| Fichier | Rôle | Permissions |
|---------|------|-------------|
| `~/.ssh/` | Répertoire principal | `700` (drwx------) |
| `~/.ssh/config` | Configuration personnelle du client | `600` (-rw-------) |
| `~/.ssh/known_hosts` | Clés d'hôte des serveurs connus | `644` (-rw-r--r--) |
| `~/.ssh/authorized_keys` | Clés publiques autorisées pour se connecter | `600` (-rw-------) |
| `~/.ssh/id_ed25519` | Clé privée (ED25519) | `600` (-rw-------) |
| `~/.ssh/id_ed25519.pub` | Clé publique (ED25519) | `644` (-rw-r--r--) |
| `~/.ssh/id_rsa` | Clé privée (RSA) | `600` (-rw-------) |
| `~/.ssh/id_rsa.pub` | Clé publique (RSA) | `644` (-rw-r--r--) |

OpenSSH vérifie strictement les permissions de ces fichiers. Si `~/.ssh` est accessible en écriture par d'autres utilisateurs, ou si une clé privée est lisible par d'autres, SSH refusera de l'utiliser et affichera un avertissement :

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!  @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/home/user/.ssh/id_ed25519' are too open.
```

## Vue d'ensemble des sous-sections

Cette section est organisée en quatre sous-sections qui couvrent progressivement l'installation, la sécurisation et l'exploitation avancée de SSH :

**6.3.1 — Installation et configuration d'OpenSSH** couvre l'installation du serveur et du client, la configuration de base de `sshd_config`, les options de sécurité essentielles, et la gestion du service via systemd.

**6.3.2 — Authentification par clés (ed25519, gestion de ssh-agent)** détaille la génération de paires de clés, le déploiement des clés publiques, la configuration de l'agent SSH pour éviter la saisie répétée de passphrases, et la désactivation de l'authentification par mot de passe.

**6.3.3 — Tunneling et port forwarding** explore les trois types de tunnels SSH (local, distant, dynamique/SOCKS), les cas d'usage concrets, et la configuration du fichier `~/.ssh/config` pour simplifier les connexions.

**6.3.4 — Sécurisation d'SSH (fail2ban, port knocking, bastions)** rassemble les techniques de durcissement avancé : intégration avec fail2ban (cf. section 6.2.4), port knocking, architecture de bastion (jump host), et audit de configuration.

---

> **Note :** SSH est un composant transversal de l'infrastructure. Sa maîtrise est indispensable non seulement pour l'administration système (cette section), mais aussi pour le déploiement automatisé (Ansible, Module 13), le Git (GitLab/GitHub), le transfert de fichiers sécurisé (SFTP, section 7.4.3), et le tunneling de services en environnement conteneurisé. Les compétences acquises dans cette section sont directement réutilisées tout au long de la formation.

---


⏭️ [Installation et configuration d'OpenSSH](/module-06-reseau-securite/03.1-installation-openssh.md)
