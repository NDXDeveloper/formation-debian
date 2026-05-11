🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 6.2 Pare-feu et sécurité

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre l'architecture de filtrage réseau du noyau Linux (Netfilter)
- Choisir entre nftables, iptables et ufw selon le contexte
- Concevoir et implémenter une politique de filtrage adaptée (serveur, poste de travail, routeur)
- Mettre en place des protections automatisées contre les intrusions avec fail2ban
- Appliquer les principes de défense en profondeur à l'infrastructure réseau Debian

## Prérequis

- Section 6.1 : Configuration réseau avancée (interfaces, routage, VLAN, diagnostic)
- Module 3, section 3.4 : systemd (services, journald)
- Notions TCP/IP : protocoles (TCP, UDP, ICMP), ports, flags, three-way handshake
- Connaissance du modèle client/serveur et des services réseau courants (SSH, HTTP, DNS)

---

## Introduction

Un pare-feu (firewall) est un composant fondamental de la sécurité de toute machine connectée à un réseau. Son rôle est de contrôler le trafic réseau entrant et sortant en appliquant un ensemble de règles qui autorisent ou rejettent les paquets selon des critères définis : adresses source et destination, ports, protocoles, état de la connexion, interface réseau, et bien d'autres.

Sur un système Debian, le filtrage réseau est assuré par **Netfilter**, un framework intégré au noyau Linux. Netfilter n'est pas un pare-feu en lui-même — c'est l'infrastructure sous-jacente sur laquelle tous les outils de filtrage s'appuient. La distinction entre Netfilter et les outils qui le pilotent est essentielle pour comprendre l'écosystème.

## L'architecture Netfilter

### Le framework du noyau

Netfilter est un ensemble de hooks (points d'ancrage) dans la pile réseau du noyau Linux. Quand un paquet traverse la pile réseau, il passe par une série de hooks où des modules peuvent l'inspecter, le modifier, l'accepter ou le rejeter. Ces hooks sont positionnés à des points stratégiques du cheminement des paquets :

```text
                          Paquet entrant
                               │
                               ▼
                        ┌──────────────┐
                        │  PREROUTING  │ ← Hook 1 : avant la décision de routage
                        └──────┬───────┘
                               │
                        Décision de routage
                       ┌───────┴───────┐
                       │               │
                Pour cette        Pour une autre
                 machine           destination
                       │               │
                       ▼               ▼
                ┌────────────┐  ┌─────────────┐
                │   INPUT    │  │  FORWARD    │ ← Hook 3 : transit (routeur)
                └─────┬──────┘  └──────┬──────┘
                      │                │
                      ▼                │
              Processus local          │
              (application)            │
                      │                │
                      ▼                ▼
                ┌────────────┐  ┌──────────────┐
                │   OUTPUT   │  │ POSTROUTING  │ ← Hook 5 : après routage
                └─────┬──────┘  └──────┬───────┘
                      │                │
                      └────────┬───────┘
                               ▼
                        Paquet sortant
```

Les cinq hooks Netfilter :

- **PREROUTING** : le paquet vient d'arriver sur une interface, avant que le noyau ne décide s'il est destiné à la machine locale ou s'il doit être routé. C'est ici qu'intervient le DNAT (Destination NAT, redirection de port).
- **INPUT** : le paquet est destiné à un processus local. C'est le hook principal pour protéger les services de la machine.
- **FORWARD** : le paquet n'est pas destiné à la machine locale et doit être routé vers une autre interface. Ce hook n'est actif que si le forwarding IP est activé (machine routeur ou passerelle).
- **OUTPUT** : le paquet est généré par un processus local et va quitter la machine.
- **POSTROUTING** : le paquet est sur le point de quitter la machine via une interface réseau. C'est ici qu'intervient le SNAT (Source NAT, masquerading).

### La notion d'état : le connection tracking

L'un des mécanismes les plus puissants de Netfilter est le **connection tracking** (conntrack), qui maintient une table des connexions réseau actives. Chaque flux réseau (identifié par le quintuplet : protocole, IP source, port source, IP destination, port destination) est suivi et classé dans un état :

| État | Signification |
|------|--------------|
| `NEW` | Premier paquet d'une connexion qui n'est pas encore dans la table conntrack (typiquement un SYN TCP ou le premier paquet UDP) |
| `ESTABLISHED` | Le paquet fait partie d'une connexion déjà établie (un échange bidirectionnel a été observé) |
| `RELATED` | Le paquet initie une nouvelle connexion, mais celle-ci est liée à une connexion existante (par exemple, les connexions de données FTP, les messages ICMP d'erreur en réponse à un flux existant) |
| `INVALID` | Le paquet ne peut pas être identifié ou ne correspond à aucune connexion connue (paquets malformés, désynchronisés, ou tentatives de scan) |
| `UNTRACKED` | Le paquet a été explicitement exclu du suivi de connexion |

Le connection tracking permet d'écrire des règles **stateful** : au lieu de devoir autoriser explicitement le trafic retour pour chaque service (par exemple, autoriser les paquets entrants en réponse à une requête HTTP sortante), il suffit d'autoriser les paquets dans l'état `ESTABLISHED` et `RELATED`. C'est la base de toute politique de filtrage moderne.

```bash
# Consulter la table conntrack
conntrack -L

# Nombre de connexions suivies
conntrack -C

# Taille maximale de la table
sysctl net.netfilter.nf_conntrack_max
```

### Netfilter, nftables et iptables : qui fait quoi ?

La terminologie peut prêter à confusion, car plusieurs outils coexistent pour piloter Netfilter. Voici la hiérarchie :

```text
┌─────────────────────────────────────────────────────┐
│                 Espace utilisateur                  │
│                                                     │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐        │
│  │  nft      │  │ iptables  │  │   ufw     │        │
│  │ (nftables)│  │(legacy ou │  │(frontend) │        │
│  │           │  │ nft-compat│  │           │        │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘        │
│        │              │              │              │
│        │         ┌────┴────┐         │              │
│        │         │iptables │         │              │
│        │         │  -nft   │         │              │
│        │         │(couche  │         │              │
│        │         │compat)  │         │              │
│        │         └────┬────┘         │              │
│        │              │              │              │
│        ▼              ▼              ▼              │
│  ┌─────────────────────────────────────────────┐    │
│  │           API nf_tables (noyau)             │    │
│  └──────────────────┬──────────────────────────┘    │
├─────────────────────┼───────────────────────────────┤
│                     ▼          Espace noyau         │
│  ┌─────────────────────────────────────────────┐    │
│  │            Netfilter (hooks)                │    │
│  │         Connection tracking (conntrack)     │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

**Netfilter** est le framework de hooks dans le noyau. Il ne change pas — c'est l'infrastructure permanente.

**nf_tables** est le sous-système du noyau (depuis Linux 3.13, 2014) qui remplace l'ancien sous-système `xtables` d'iptables. Il offre une machine virtuelle de classification de paquets plus flexible et plus performante.

**nftables** (commande `nft`) est l'outil en espace utilisateur pour configurer `nf_tables`. C'est le successeur officiel d'iptables et l'outil recommandé depuis Debian 10 (Buster). Il offre une syntaxe unifiée pour IPv4, IPv6 et le filtrage de bridges dans un même jeu de règles.

**iptables** existe en deux variantes sur Debian moderne. Le binaire `iptables-nft` (installé par défaut via le mécanisme d'alternatives Debian) traduit les commandes iptables classiques en règles nf_tables — c'est une couche de compatibilité qui permet aux scripts et outils existants de fonctionner sans modification. Le binaire `iptables-legacy` utilise l'ancien sous-système xtables du noyau et n'est plus recommandé.

**ufw** (Uncomplicated Firewall) est un frontend simplifié qui génère des règles iptables (et donc, in fine, des règles nf_tables via la couche de compatibilité). Il ne remplace ni nftables ni iptables — il les utilise.

**fail2ban** n'est pas un pare-feu mais un outil de protection active qui surveille les logs et ajoute dynamiquement des règles de blocage (via nftables ou iptables) en réaction à des comportements suspects (tentatives de brute-force, scans, etc.).

### L'état de la transition iptables → nftables sous Debian

La transition est un processus progressif :

| Version Debian | État de la transition |
|---|---|
| Debian 9 (Stretch) | nftables disponible, iptables (legacy) par défaut |
| Debian 10 (Buster) | **nftables recommandé**, iptables-nft par défaut via alternatives |
| Debian 11 (Bullseye) | nftables par défaut, iptables-nft comme couche de compatibilité |
| Debian 12 (Bookworm) | nftables pleinement intégré, iptables-legacy déprécié |
| Debian 13 (Trixie) | nftables natif, iptables-nft en compatibilité, iptables-legacy toujours fourni mais déconseillé |

> **Note sur `iptables-legacy` dans Trixie** : le binaire `iptables-legacy` (et son équivalent IPv6 `ip6tables-legacy`) est toujours présent dans le paquet `iptables` de Trixie, mais il n'est plus l'alternative par défaut et ne reçoit plus de développement actif. Son usage doit être réservé aux cas exceptionnels d'incompatibilité avec un outil tiers — pour tout nouveau déploiement, utiliser `nft` directement ou `iptables-nft` via la couche de compatibilité.

Sur une installation Debian 12 ou ultérieure, `iptables` est en réalité `iptables-nft` :

```bash
# Vérifier quelle variante est active
update-alternatives --display iptables
```

```
iptables - auto mode
  link best version is /usr/sbin/iptables-nft
```

La conséquence pratique est importante : les règles écrites avec la syntaxe `iptables` et celles écrites avec la syntaxe `nft` coexistent dans le même sous-système nf_tables du noyau. Il est techniquement possible de les mélanger, mais c'est une source de confusion et de conflits — en production, il faut choisir un seul outil et s'y tenir.

## Principes de conception d'une politique de filtrage

### Politique par défaut : deny all vs allow all

Il existe deux philosophies de politique par défaut, et le choix entre les deux est déterminant :

**Default deny (liste blanche)** : tout ce qui n'est pas explicitement autorisé est interdit. C'est l'approche recommandée pour la sécurité. On commence avec un pare-feu qui bloque tout, puis on ouvre uniquement les flux nécessaires. Si un nouveau service est déployé sans que la règle correspondante soit ajoutée, il sera inaccessible — ce qui est préférable à un service exposé par inadvertance.

**Default allow (liste noire)** : tout est autorisé sauf ce qui est explicitement interdit. Cette approche est plus permissive et plus risquée. Elle est parfois utilisée en phase de migration (pour ne pas casser les flux existants) mais ne devrait jamais être la politique permanente d'un serveur de production.

La politique recommandée pour un serveur Debian est :

- **INPUT** : `drop` par défaut (bloquer tout le trafic entrant non sollicité)
- **FORWARD** : `drop` par défaut (sauf si la machine est un routeur)
- **OUTPUT** : `accept` par défaut (autoriser le trafic sortant — peut être restreint pour les environnements à haute sécurité)

### Règles de base communes

Indépendamment de l'outil utilisé (nftables, iptables, ufw), toute politique de filtrage commence par un socle de règles fondamentales :

**Autoriser le trafic loopback.** L'interface loopback (`lo`) est utilisée par les processus locaux pour communiquer entre eux (connexions à `127.0.0.1` ou `::1`). Bloquer le loopback casse de nombreux services (bases de données, caches, résolveur DNS local).

**Autoriser les connexions établies et associées.** Les paquets dans l'état `ESTABLISHED` (réponses aux connexions initiées depuis la machine) et `RELATED` (connexions liées, comme les erreurs ICMP) doivent être autorisés. C'est le fondement du filtrage stateful.

**Rejeter les paquets invalides.** Les paquets dans l'état `INVALID` (malformés, désynchronisés) doivent être supprimés. Ils ne correspondent à aucune connexion légitime et sont souvent le signe de scans ou d'attaques.

**Autoriser les services nécessaires.** Ouvrir uniquement les ports des services effectivement en écoute sur la machine : SSH (22), HTTP (80), HTTPS (443), etc.

**Autoriser l'ICMP essentiel.** Bloquer tout l'ICMP est une erreur courante. Certains types ICMP sont nécessaires au bon fonctionnement du réseau : echo-request/echo-reply (ping), destination-unreachable (Path MTU Discovery), time-exceeded (traceroute). En IPv6, ICMPv6 est encore plus critique car il porte le protocole NDP (Neighbor Discovery), indispensable à la résolution d'adresses et à l'auto-configuration.

### Ordre des règles

Les règles de filtrage sont évaluées séquentiellement, de la première à la dernière. L'ordre est donc crucial. La structure recommandée est la suivante :

1. Autoriser le loopback
2. Rejeter les paquets INVALID
3. Autoriser ESTABLISHED et RELATED
4. Autoriser les services spécifiques (SSH, HTTP, etc.)
5. Autoriser l'ICMP nécessaire
6. Politique par défaut : drop (rejeter tout le reste)

Cette structure est optimale en termes de performances : les paquets des connexions établies (qui constituent la grande majorité du trafic) sont acceptés dès l'étape 3, sans parcourir les règles suivantes.

## Vue d'ensemble des sous-sections

Cette section est organisée en quatre sous-sections qui couvrent l'ensemble des outils de filtrage et de protection disponibles sous Debian :

**6.2.1 — nftables (et héritage iptables)** présente en détail le framework nftables : sa syntaxe, ses concepts (tables, chaînes, règles, sets, maps), la configuration de jeux de règles complets pour différents profils (serveur, routeur), la persistance, et la coexistence avec l'héritage iptables. C'est la sous-section la plus dense, nftables étant l'outil de référence.

**6.2.2 — ufw (Uncomplicated Firewall)** couvre le frontend simplifié pour les administrateurs qui recherchent une mise en place rapide sans maîtriser la syntaxe nftables. Vous y verrez l'installation, la configuration, les profils d'application, et les limites de l'outil.

**6.2.3 — Configuration de base et règles avancées** rassemble les scénarios de filtrage avancés qui vont au-delà des règles de base : NAT (masquerading, port forwarding), rate limiting, filtrage par géolocalisation, logging sélectif, et intégration avec les VLAN et les bridges.

**6.2.4 — fail2ban et protection contre les intrusions** traite de la protection automatisée contre les attaques par force brute et les scans. Vous y apprendrez à configurer fail2ban pour SSH et d'autres services, à créer des jails personnalisées, et à intégrer fail2ban avec nftables.

---

> **Note :** le pare-feu est un élément essentiel de la sécurité, mais il n'est pas suffisant à lui seul. La sécurisation d'un système Debian repose sur la défense en profondeur : pare-feu réseau, sécurisation des services (configuration minimale, authentification forte, chiffrement — traités en sections 6.3 et 6.4), mises à jour régulières, surveillance des logs, et principe du moindre privilège. Le pare-feu est la première ligne de défense, pas la seule.

---


⏭️ [nftables (et héritage iptables)](/module-06-reseau-securite/02.1-nftables-iptables.md)
