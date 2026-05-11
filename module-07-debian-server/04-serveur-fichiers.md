🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 7.4 Serveur de fichiers

## Introduction

Le partage de fichiers en réseau reste un besoin fondamental dans toute infrastructure, des petites équipes aux grands parcs d'entreprise. Qu'il s'agisse de centraliser les documents de travail, de fournir un espace de stockage commun à des applications, de distribuer des fichiers de configuration sur un parc de serveurs ou de permettre le transfert sécurisé de fichiers avec des partenaires extérieurs, un serveur Debian peut remplir chacun de ces rôles avec les outils appropriés.

Le choix du protocole de partage dépend de l'environnement cible : les postes Windows et les environnements mixtes s'appuient sur **SMB/CIFS** (implémenté par Samba), les infrastructures purement Linux utilisent **NFS** (Network File System), et les transferts sécurisés de fichiers entre organisations ou via Internet reposent sur **SFTP** (SSH File Transfer Protocol). Ces trois protocoles ne sont pas concurrents — ils répondent à des besoins différents et coexistent fréquemment sur un même serveur.

---

## Panorama des protocoles de partage

### SMB/CIFS (Samba)

SMB (Server Message Block) est le protocole de partage de fichiers natif de Windows. Son implémentation libre, **Samba**, permet à un serveur Debian de s'intégrer dans un environnement Windows comme s'il était un serveur de fichiers Microsoft : les postes Windows accèdent aux partages de manière transparente via l'Explorateur de fichiers, les imprimantes peuvent être partagées et le serveur peut même rejoindre ou émuler un contrôleur de domaine Active Directory.

SMB a considérablement évolué au fil des versions. La version SMB1 (aussi appelée CIFS), historique et notoirement peu sûre, est désormais désactivée par défaut sur les systèmes Windows récents. SMB2 et SMB3, utilisés en production aujourd'hui, apportent des améliorations majeures : chiffrement du transport, signatures cryptographiques, multiplexage des requêtes, support des liens symboliques et des opérations de fichiers plus efficaces. SMB3 est le standard minimal pour tout nouveau déploiement.

Samba est le choix obligatoire dès qu'un ou plusieurs clients Windows doivent accéder aux fichiers partagés. Il est également pertinent dans les environnements mixtes Linux/macOS/Windows car macOS supporte nativement SMB.

### NFS (Network File System)

NFS est le protocole de partage de fichiers natif du monde Unix/Linux. Développé initialement par Sun Microsystems en 1984, il est aujourd'hui un standard ouvert (RFC 7530 pour NFSv4). NFS permet de monter un répertoire distant comme s'il était local — le processus est transparent pour les applications, qui accèdent aux fichiers distants avec les mêmes appels système que pour des fichiers locaux.

La version actuelle, **NFSv4**, corrige les principales faiblesses des versions précédentes : elle unifie le protocole en un seul port TCP (2049), supporte l'authentification forte via Kerberos, gère les ACL de manière standardisée et fonctionne correctement à travers les pare-feu et le NAT. NFSv4.2 (RFC 7862) ajoute le server-side copy, les sparse files et les labels de sécurité ; il est supporté par le noyau Linux depuis la version 4.13 (2017), donc disponible nativement sur Trixie.

NFS est le choix naturel dans les environnements purement Linux : partage de répertoires home entre serveurs, stockage partagé pour des clusters d'applications, distribution de fichiers de configuration et de données entre serveurs. Sa simplicité de configuration et son intégration native dans le noyau Linux en font le protocole le plus performant pour les échanges entre machines Linux.

### SFTP (SSH File Transfer Protocol)

SFTP est un protocole de transfert de fichiers qui fonctionne au-dessus d'une connexion SSH chiffrée. Contrairement à FTP (non chiffré) et FTPS (FTP sur TLS, complexe à configurer), SFTP utilise un seul port (22, le même que SSH), chiffre intégralement les données et l'authentification, et ne nécessite pas d'ouverture de ports supplémentaires dans le pare-feu.

SFTP n'est pas un protocole de partage de fichiers en réseau au sens de SMB ou NFS — les fichiers ne sont pas montés en local. C'est un protocole de **transfert** : les fichiers sont téléchargés ou téléversés explicitement par le client. Il est adapté aux cas d'usage suivants : dépôt de fichiers par des partenaires extérieurs, transferts automatisés entre serveurs (scripts de synchronisation, échanges applicatifs), mise à disposition de fichiers pour des utilisateurs qui ne nécessitent pas un accès permanent.

L'avantage majeur de SFTP est qu'il est intégré à OpenSSH, déjà installé sur tout serveur Debian. Aucun logiciel supplémentaire n'est nécessaire côté serveur — la configuration se fait dans `/etc/ssh/sshd_config`.

---

## Critères de choix

| Critère | Samba (SMB) | NFS | SFTP |
|---------|-------------|-----|------|
| **Clients cibles** | Windows, macOS, Linux | Linux, Unix | Tous (via client SSH) |
| **Mode d'accès** | Montage réseau | Montage réseau | Transfert de fichiers |
| **Authentification** | Utilisateur/mot de passe, AD/Kerberos | IP, Kerberos (v4) | Clés SSH, mot de passe |
| **Chiffrement** | SMB3 (natif) | Kerberos + krb5p | Toujours (SSH) |
| **Port(s)** | 445 (SMB3) | 2049 (NFSv4) | 22 (SSH) |
| **Performance** | Bonne | Excellente (Linux→Linux) | Modérée |
| **Complexité** | Modérée à élevée | Faible à modérée | Faible |
| **Intégration Active Directory** | Excellente | Possible (Kerberos) | Limitée |
| **Adapté à Internet** | Non (VPN requis) | Non (VPN requis) | Oui |
| **Cas d'usage principal** | Bureautique, environnements mixtes | Infrastructure Linux | Transferts sécurisés |

### Quand choisir quoi

**Samba** est incontournable quand des postes Windows doivent accéder aux fichiers. C'est aussi le choix pour l'intégration avec Active Directory, le remplacement de serveurs de fichiers Windows et les environnements de bureautique multi-plateformes.

**NFS** est privilégié quand tous les clients sont des machines Linux ou Unix. Il offre les meilleures performances pour le partage de fichiers entre serveurs (stockage applicatif, répertoires home centralisés, partage de données entre nœuds d'un cluster).

**SFTP** est la solution pour les transferts de fichiers sécurisés, en particulier quand les clients sont sur Internet ou dans des réseaux non maîtrisés. Il est aussi utilisé pour les échanges automatisés entre serveurs quand un partage permanent n'est pas nécessaire.

Les trois protocoles coexistent fréquemment sur un même serveur Debian. Un serveur de fichiers d'entreprise peut exposer le même répertoire de données via Samba (pour les postes bureautiques Windows), via NFS (pour les serveurs d'application Linux) et via SFTP (pour les partenaires extérieurs), avec des contrôles d'accès adaptés à chaque protocole.

---

## Considérations d'architecture

### Emplacement du stockage

Le choix du système de fichiers sous-jacent et de l'organisation du stockage a un impact direct sur la fiabilité et la performance du serveur de fichiers.

**Système de fichiers** — Pour un serveur de fichiers, **ext4** reste le choix le plus éprouvé et le plus simple. **XFS** est préféré pour les volumes très volumineux (dizaines de téraoctets) ou les workloads avec de nombreux fichiers de grande taille grâce à sa gestion efficace de l'espace et de l'allocation. **Btrfs** apporte les snapshots natifs et la détection de corruption, intéressants pour un serveur de fichiers critique mais avec une maturité moindre en production.

**LVM** — L'utilisation de LVM (détaillé au Module 8.5) pour le volume de données est fortement recommandée. Elle permet de redimensionner le stockage à chaud, de créer des snapshots avant une opération risquée et d'ajouter des disques physiques sans modifier le schéma de partitionnement.

**RAID** — Un serveur de fichiers de production doit impérativement utiliser un RAID (logiciel avec `mdadm` ou matériel) pour protéger les données contre la défaillance d'un disque. RAID 1 (miroir) offre la meilleure protection pour deux disques, RAID 5/6 offre un bon compromis capacité/protection pour trois disques et plus. Le RAID ne remplace pas les sauvegardes — il protège contre les pannes matérielles, pas contre les suppressions accidentelles, les corruptions logiques ou les ransomwares.

### Permissions et propriété

La gestion des permissions est l'un des aspects les plus complexes d'un serveur de fichiers multi-protocoles. Chaque protocole a son propre modèle de permissions :

- **Samba** gère ses propres ACL qui doivent être synchronisées avec les permissions POSIX du système de fichiers (ou avec les ACL étendues si activées).
- **NFS** s'appuie directement sur les UID/GID Unix, ce qui nécessite une correspondance cohérente des identifiants entre le serveur et les clients (via LDAP, **SSSD** — l'option moderne — ou idmapd avec NFSv4 ; NIS est obsolète et ne doit plus être utilisé sur les nouvelles infrastructures).
- **SFTP** utilise les permissions POSIX standard du système de fichiers.

Quand un même répertoire est partagé via plusieurs protocoles, les permissions POSIX sous-jacentes doivent satisfaire les contraintes de tous les protocoles. Les ACL POSIX (`setfacl`/`getfacl`) offrent la granularité nécessaire pour gérer des accès complexes sur un même répertoire.

### Sécurité réseau

Les ports de chaque protocole doivent être ouverts dans le pare-feu nftables uniquement pour les réseaux clients autorisés :

```bash
# /etc/nftables.conf (extrait)

# Samba (SMB) — réseau bureautique uniquement
tcp dport 445 ip saddr 192.0.2.0/24 accept

# NFS v4 — réseau serveurs uniquement
tcp dport 2049 ip saddr 198.51.100.0/24 accept

# SFTP — déjà couvert par la règle SSH (port 22)
```

Aucun de ces protocoles de partage de fichiers ne doit être exposé directement sur Internet sans VPN, à l'exception de SFTP qui est chiffré de bout en bout et peut être exposé avec les précautions appropriées (authentification par clé, chroot, quotas).

---

## Prérequis

Les sous-sections de ce chapitre s'appuient sur :

- Un serveur Debian installé et sécurisé conformément aux sections 7.1.1 à 7.1.3.
- Un pare-feu nftables actif avec les ports appropriés ouverts pour les protocoles choisis.
- Une compréhension des permissions POSIX (Module 3.1) : propriétaire, groupe, permissions rwx, bits spéciaux (SUID, SGID, sticky bit).
- Un stockage dimensionné pour le volume de données prévu, idéalement sur LVM avec RAID.
- Pour Samba dans un environnement Active Directory : une compréhension de base des concepts AD (domaine, contrôleur, comptes machine).

---

## Organisation des sous-sections

**7.4.1 Samba (partage Windows)** — Installation, configuration des partages, intégration avec les comptes système et Active Directory, gestion des permissions, corbeille réseau et audit.

**7.4.2 NFS (partage Linux)** — Configuration du serveur NFSv4, exports, montage côté client, options de performance et de sécurité, automontage avec autofs ou systemd.

**7.4.3 SFTP sécurisé** — Configuration d'un environnement SFTP chrooté avec OpenSSH, gestion des utilisateurs SFTP dédiés, restrictions et quotas.

**7.4.4 Configuration et sécurisation** — Aspects transversaux : quotas de disque, ACL POSIX, journalisation des accès, sauvegarde des partages, surveillance de l'espace disque et intégration dans la stratégie de monitoring.

⏭️ [Samba (partage Windows)](/module-07-debian-server/04.1-samba.md)
