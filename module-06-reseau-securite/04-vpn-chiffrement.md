🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 6.4 VPN et chiffrement

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre les principes, les protocoles et les architectures VPN
- Choisir entre WireGuard et OpenVPN selon le contexte
- Configurer des tunnels VPN site-à-site et client-à-site sous Debian
- Gérer une infrastructure de certificats (PKI) pour l'authentification VPN
- Mettre en œuvre le chiffrement des données au repos avec LUKS et dm-crypt
- Intégrer les VPN dans une architecture réseau sécurisée existante

## Prérequis

- Section 6.1 : Configuration réseau avancée (routage, interfaces virtuelles)
- Section 6.2 : Pare-feu et sécurité (nftables, NAT, forwarding)
- Section 6.3 : SSH et accès distant (tunneling, cryptographie)
- Notions de cryptographie : chiffrement symétrique/asymétrique, certificats, PKI

---

## Introduction

### Qu'est-ce qu'un VPN ?

Un VPN (Virtual Private Network) est un tunnel chiffré qui étend un réseau privé à travers un réseau non sécurisé — typiquement Internet. Le trafic qui circule dans le tunnel est chiffré, authentifié et encapsulé, le rendant opaque aux intermédiaires réseau. Pour les machines connectées au VPN, tout se passe comme si elles étaient sur le même réseau local, même si elles sont physiquement séparées par des milliers de kilomètres.

Le VPN répond à trois besoins fondamentaux :

**Confidentialité.** Le chiffrement empêche quiconque (FAI, attaquant sur le réseau, État) de lire le contenu du trafic qui circule dans le tunnel. Même intercepté, le trafic est inexploitable sans les clés de chiffrement.

**Authentification.** Les extrémités du tunnel s'authentifient mutuellement avant d'établir la connexion. Cela garantit que le trafic est échangé avec le bon correspondant et non avec un imposteur (protection contre le MITM).

**Intégrité.** Des codes d'authentification de messages (MAC/AEAD) garantissent que le trafic n'a pas été modifié en transit. Toute altération est détectée et le paquet est rejeté.

### VPN vs SSH tunneling

La section 6.3.3 a montré que SSH peut créer des tunnels pour accéder à des services distants. Les VPN et le tunneling SSH répondent à des besoins qui se chevauchent mais ne sont pas interchangeables :

| Critère | VPN (WireGuard/OpenVPN) | Tunnel SSH |
|---------|------------------------|------------|
| **Couche réseau** | Couche 3 (IP) — tunnel réseau complet | Couche 4-7 (TCP) — forwarding de ports individuels |
| **Trafic supporté** | Tout trafic IP (TCP, UDP, ICMP) | TCP uniquement (sauf tunnel TUN/TAP) |
| **Routage** | Routes réseau complètes, accès à des sous-réseaux entiers | Port par port, ou proxy SOCKS |
| **Performance** | Optimisé pour le trafic réseau soutenu | Overhead TCP-over-TCP pour les longs transferts |
| **Clients simultanés** | Conçu pour des dizaines à des centaines de clients | Un tunnel par connexion SSH |
| **Persistance** | Conçu pour être permanent | Connexion à rétablir manuellement (ou autossh) |
| **Complexité** | Infrastructure dédiée (serveur VPN, PKI, clients) | Rien à installer au-delà d'OpenSSH |
| **Cas d'usage** | Accès réseau permanent, site-à-site, nomades | Accès ponctuel à un service, dépannage |

En résumé : le tunnel SSH est un outil de dépannage et d'accès ponctuel. Le VPN est une infrastructure réseau permanente.

### Topologies VPN

Les VPN se déploient selon trois topologies principales, chacune répondant à un besoin distinct :

**Client-à-site (remote access VPN)**

Le cas d'usage le plus courant : des utilisateurs nomades (télétravail, déplacements) se connectent au réseau de l'entreprise depuis Internet. Chaque client établit un tunnel individuel vers un serveur VPN qui lui donne accès au réseau interne.

```text
┌───────────┐                        ┌──────────────┐
│ Client A  │──── tunnel VPN ───────>│              │
│ (nomade)  │      Internet          │ Serveur VPN  │       Réseau
└───────────┘                        │              │──────interne
                                     │              │    10.0.0.0/24
┌───────────┐                        │              │
│ Client B  │──── tunnel VPN ───────>│              │
│ (nomade)  │      Internet          │              │
└───────────┘                        └──────────────┘
```

**Site-à-site**

Deux réseaux distants sont connectés de manière permanente via un tunnel VPN entre leurs routeurs/passerelles. Les machines des deux sites communiquent de manière transparente, sans client VPN individuel.

```text
┌──────────────┐                          ┌──────────────┐
│  Site A      │                          │  Site B      │
│ 10.1.0.0/24  │                          │ 10.2.0.0/24  │
│              │                          │              │
│  Passerelle  │──── tunnel VPN ─────────>│  Passerelle  │
│  VPN         │      Internet            │  VPN         │
└──────────────┘                          └──────────────┘

Les machines de 10.1.0.0/24 accèdent à 10.2.0.0/24  
comme si les deux réseaux étaient directement connectés.  
```

**Maillé (mesh)**

Chaque nœud établit un tunnel direct vers chaque autre nœud, formant un réseau maillé. Cette topologie élimine le point de passage central (serveur VPN) et offre la latence la plus faible entre les nœuds. WireGuard est particulièrement adapté à cette topologie grâce à sa simplicité de configuration pair-à-pair. Des outils comme Tailscale, Netmaker ou Headscale automatisent la gestion des topologies maillées basées sur WireGuard.

```text
┌────────┐         ┌────────┐
│Nœud A  │◄───────>│Nœud B  │
│        │╲        │        │
└────────┘ ╲       └────────┘
            ╲         ▲
             ╲        │
              ╲       │
               ▼      │
            ┌────────┐
            │Nœud C  │
            │        │
            └────────┘
```

## Protocoles VPN : vue d'ensemble

Le paysage des protocoles VPN a considérablement évolué. Voici les protocoles pertinents en 2026 :

### WireGuard

WireGuard est un protocole VPN moderne, intégré au noyau Linux depuis la version 5.6 (2020). Conçu par Jason A. Donenfeld, il se distingue par une base de code extrêmement réduite (~4 000 lignes de code noyau, contre ~100 000 pour OpenVPN), une cryptographie moderne sans négociation (Noise protocol framework, Curve25519, ChaCha20-Poly1305, BLAKE2s), et des performances nettement supérieures à OpenVPN.

WireGuard opère au niveau de la couche 3 (IP) et crée une interface réseau virtuelle (`wg0`) à travers laquelle le trafic est routé. Son modèle de configuration est pair-à-pair : chaque pair est identifié par sa clé publique Curve25519, sans concept de « serveur » ou de « client » au niveau du protocole (bien qu'en pratique, un pair fasse souvent office de concentrateur).

### OpenVPN

OpenVPN est un VPN en espace utilisateur, mature et éprouvé depuis plus de vingt ans. Il utilise la bibliothèque OpenSSL (ou mbed TLS) pour le chiffrement et supporte une grande variété de configurations : tunnel TUN (couche 3) ou TAP (couche 2), transport TCP ou UDP, authentification par certificats X.509, par clé pré-partagée, ou par identifiants via plugin PAM.

Sa flexibilité est son principal atout : il fonctionne sur pratiquement toute plateforme, traverse les pare-feux et proxies restrictifs (en mode TCP/443), et offre un contrôle granulaire sur chaque aspect de la connexion. Son principal inconvénient est sa complexité de configuration et ses performances inférieures à WireGuard (traitement en espace utilisateur, overhead du protocole TLS).

### IPsec (IKEv2/strongSwan)

IPsec est le protocole VPN standardisé de l'IETF, opérant directement dans la pile réseau du noyau. La version moderne IKEv2 (Internet Key Exchange version 2), implémentée par strongSwan sous Linux, offre une reconnexion rapide (MOBIKE), une authentification flexible (certificats, EAP), et une interopérabilité avec les équipements réseau professionnels (Cisco, Juniper, Fortinet, pare-feux cloud AWS/Azure/GCP).

IPsec est le choix naturel pour l'interopérabilité avec des équipements tiers et les VPN cloud managés. Sa complexité de configuration et de diagnostic est cependant significativement supérieure à WireGuard et OpenVPN.

### Protocoles obsolètes

**PPTP** (Point-to-Point Tunneling Protocol) est cryptographiquement cassé depuis des années et ne doit plus être utilisé. **L2TP/IPsec** est fonctionnel mais supplanté par IKEv2 en termes de fonctionnalités et de performance. Ces protocoles ne seront pas traités dans cette formation.

### Tableau comparatif

| Critère | WireGuard | OpenVPN | IPsec (IKEv2) |
|---------|-----------|---------|---------------|
| **Intégration noyau** | Oui (module natif) | Non (espace utilisateur) | Oui (XFRM) |
| **Performance** | Excellente | Bonne | Excellente |
| **Latence** | Très faible | Modérée | Faible |
| **Base de code** | ~4 000 lignes | ~100 000 lignes | ~400 000 lignes (strongSwan) |
| **Cryptographie** | Fixe (Noise, Curve25519, ChaCha20) | Négociable (TLS, OpenSSL) | Négociable (IKEv2) |
| **Transport** | UDP uniquement | UDP ou TCP | UDP (ports 500, 4500) |
| **Traverse les proxies** | Non (UDP) | Oui (TCP/443) | Partiel (NAT-T) |
| **Authentification** | Clés Curve25519 | Certificats X.509, PSK, MFA | Certificats, EAP, PSK |
| **Gestion des clients** | Manuelle ou outil tiers | Serveur centralisé | Serveur centralisé |
| **Interopérabilité** | Linux, Windows, macOS, iOS, Android | Universelle | Équipements réseau, cloud |
| **Complexité** | Faible | Moyenne à élevée | Élevée |
| **Maturité** | Récent (noyau depuis 2020) | Très mature (~20 ans) | Standard IETF (~25 ans) |

## Choix du protocole

Le choix entre WireGuard et OpenVPN dépend du contexte :

**Choisir WireGuard quand :** la performance est prioritaire, l'infrastructure est homogène (Linux, clients modernes), la topologie est simple ou maillée, la simplicité de configuration et de maintenance est recherchée, ou le VPN est site-à-site entre serveurs Debian.

**Choisir OpenVPN quand :** le VPN doit traverser des pare-feux restrictifs qui n'autorisent que TCP/443, une infrastructure PKI avec certificats X.509 est déjà en place, la compatibilité avec des clients très variés ou anciens est nécessaire, ou un contrôle fin des paramètres TLS est requis.

**Choisir IPsec (strongSwan) quand :** l'interopérabilité avec des équipements réseau tiers (Cisco, Fortinet) est nécessaire, le VPN s'intègre avec un VPN cloud managé (AWS VPN Gateway, Azure VPN Gateway), ou la conformité à des standards industriels l'exige.

Dans la majorité des cas sur une infrastructure Debian, **WireGuard est le choix recommandé** pour sa simplicité, ses performances et sa sécurité. OpenVPN reste indispensable dans les environnements hétérogènes ou restrictifs.

## Concepts de chiffrement des données

Au-delà du chiffrement en transit (VPN, SSH, TLS), la protection des données inclut le **chiffrement au repos** — le chiffrement des données stockées sur les disques. Si un disque est volé, perdu ou accédé physiquement par un attaquant, le chiffrement au repos empêche la lecture des données.

Sous Debian, le chiffrement au repos est assuré par **LUKS** (Linux Unified Key Setup) et **dm-crypt**, qui forment le standard de chiffrement de disque sous Linux. LUKS fournit la couche de gestion des clés (multiples passphrases, en-tête de volume standardisé, support de tokens matériels) tandis que dm-crypt (un module du device mapper du noyau) assure le chiffrement/déchiffrement bloc par bloc de manière transparente.

Le chiffrement au repos et le chiffrement en transit sont complémentaires et non substituables : un VPN protège les données pendant leur transfert réseau, LUKS les protège sur le disque. Les deux sont nécessaires pour une protection complète du cycle de vie des données.

## Vue d'ensemble des sous-sections

Cette section est organisée en quatre sous-sections couvrant les VPN et le chiffrement des données :

**6.4.1 — WireGuard et OpenVPN** compare en profondeur les deux solutions VPN majeures, avec des guides de déploiement complets pour chacune sous Debian : installation, génération des clés, configuration serveur et client, routage et intégration pare-feu.

**6.4.2 — Configuration client/serveur** détaille les configurations avancées : topologies multi-clients, attribution d'adresses, split tunneling vs full tunneling, persistance des connexions, intégration avec systemd-networkd et NetworkManager, et diagnostic des tunnels.

**6.4.3 — Certificats et PKI** couvre la mise en place d'une infrastructure de clés publiques pour l'authentification VPN : création d'une autorité de certification, émission et révocation de certificats, gestion du cycle de vie, et intégration avec OpenVPN et IPsec.

**6.4.4 — Chiffrement des données (LUKS, dm-crypt)** traite du chiffrement des disques et des partitions : LUKS2, gestion des clés et des passphrases, chiffrement complet du système, chiffrement de partitions de données, et considérations de performance.

---

> **Note :** les VPN sont un composant fondamental des architectures réseau modernes. Les compétences acquises dans cette section sont directement réutilisées dans les Modules 9 (virtualisation), 13 (Infrastructure as Code — déploiement de tunnels WireGuard via Ansible), et 19 (architectures de référence — interconnexion de sites).

---



⏭️ [WireGuard et OpenVPN](/module-06-reseau-securite/04.1-wireguard-openvpn.md)
