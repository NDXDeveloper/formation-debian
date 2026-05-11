🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 6.1 Configuration réseau avancée

## Objectifs pédagogiques

À l'issue de cette section, vous serez capable de :

- Comprendre l'architecture réseau de Debian et les différentes couches logicielles impliquées
- Configurer des interfaces réseau avancées (bonding, VLAN, bridges)
- Choisir et mettre en œuvre la solution de gestion réseau adaptée à votre contexte (NetworkManager, systemd-networkd, ifupdown)
- Configurer une connectivité IPv6 en dual-stack
- Diagnostiquer efficacement les problèmes réseau avec les outils natifs de Debian

## Prérequis

- Module 1 : Fondamentaux de Debian (installation, post-installation, configuration réseau de base)
- Module 3 : Administration système de base (systemd, gestion des services, logs)
- Notions fondamentales TCP/IP : adressage, sous-réseaux, routage, DNS
- Connaissances de base en ligne de commande et édition de fichiers de configuration

---

## Introduction

La configuration réseau est l'un des piliers de l'administration système. Si le Module 1 a posé les bases en permettant de connecter une machine Debian au réseau lors de l'installation, la réalité des environnements de production exige des compétences bien plus étendues. Serveurs multi-homed, agrégation de liens pour la haute disponibilité, segmentation par VLAN, adressage IPv6 : les besoins réseau d'une infrastructure professionnelle dépassent largement la simple attribution d'une adresse IP via DHCP.

Debian se distingue par la coexistence de plusieurs outils de gestion réseau, héritage de son évolution historique et de sa polyvalence. Cette richesse est un atout, mais elle peut aussi être source de confusion. Comprendre quand et pourquoi utiliser chaque outil est une compétence essentielle pour tout administrateur système Debian.

## La pile réseau sous Debian

### Le noyau Linux au cœur du réseau

Toute configuration réseau sous Debian repose ultimement sur le noyau Linux. C'est lui qui gère les interfaces réseau, les tables de routage, le filtrage de paquets (via Netfilter/nftables), et les fonctionnalités avancées comme le bonding, les VLAN ou les namespaces réseau.

L'espace utilisateur communique avec le noyau via l'interface Netlink, un mécanisme de socket permettant de configurer et d'interroger la pile réseau du noyau. L'outil `ip` (du paquet `iproute2`) est l'interface en ligne de commande moderne pour interagir avec Netlink. Il a remplacé les anciens outils `ifconfig`, `route` et `arp` du paquet `net-tools`, qui sont aujourd'hui considérés comme obsolètes bien qu'encore présents sur de nombreux systèmes.

```text
┌───────────────────────────────────────────────────────────┐
│                   Espace utilisateur                      │
│                                                           │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │ NetworkManager│  │systemd-networkd│  │  ifupdown    │  │
│  └──────┬────────┘  └──────┬─────────┘  └──────┬───────┘  │
│         │                  │                   │          │
│         ▼                  ▼                   ▼          │
│  ┌─────────────────────────────────────────────────┐      │
│  │          iproute2 (ip) / Netlink                │      │
│  └─────────────────────┬───────────────────────────┘      │
├────────────────────────┼──────────────────────────────────┤
│                        ▼         Espace noyau             │
│  ┌──────────────────────────────────────────────────┐     │
│  │              Pile réseau du noyau Linux          │     │
│  │  (interfaces, routage, bonding, VLAN, bridges)   │     │
│  └──────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────┘
```

### Les trois gestionnaires réseau de Debian

Debian propose trois approches principales pour la gestion réseau, chacune adaptée à des contextes d'utilisation différents.

**ifupdown (`/etc/network/interfaces`)** est le système historique de Debian. Simple, prévisible et sans dépendance lourde, il reste très utilisé sur les serveurs. Sa configuration est purement déclarative et statique : les interfaces sont décrites dans un fichier texte, activées au démarrage par le service `networking`, et ne sont pas surveillées dynamiquement. C'est l'outil de choix lorsqu'on recherche la stabilité et la transparence totale de la configuration.

**systemd-networkd** est le gestionnaire réseau intégré à systemd. Il offre une approche déclarative via des fichiers `.network`, `.netdev` et `.link` dans `/etc/systemd/network/`. Il gère nativement le bonding, les VLAN, les bridges et les tunnels, le tout sans dépendance supplémentaire puisqu'il fait partie de systemd, présent par défaut sur toute installation Debian moderne. Il est particulièrement adapté aux serveurs, aux conteneurs et aux environnements automatisés.

**NetworkManager** est le gestionnaire réseau orienté desktop. Conçu pour gérer dynamiquement les connexions (WiFi, VPN, Ethernet), il s'intègre aux environnements de bureau via une applet graphique et propose l'outil en ligne de commande `nmcli`. Il gère les profils de connexion, les portails captifs et le basculement automatique entre réseaux. C'est le choix par défaut sur les installations Debian avec environnement graphique.

Ces trois outils **ne doivent pas être utilisés simultanément sur les mêmes interfaces**, sous peine de conflits de configuration imprévisibles. La section 6.1.5 détaillera les critères de choix et les bonnes pratiques de coexistence.

### Correspondance entre outils historiques et modernes

L'administration réseau sous Debian a évolué significativement avec l'adoption du paquet `iproute2`. Voici la correspondance entre les commandes historiques (paquet `net-tools`) et leurs équivalents modernes :

| Outil historique (`net-tools`) | Équivalent moderne (`iproute2`) | Fonction |
|---|---|---|
| `ifconfig` | `ip addr`, `ip link` | Affichage et configuration des interfaces |
| `route` | `ip route` | Gestion des tables de routage |
| `arp` | `ip neigh` | Table ARP / voisinage |
| `netstat` | `ss` | Sockets et connexions actives |
| `brctl` | `ip link` + `bridge` | Gestion des bridges |
| `vconfig` | `ip link add link ... type vlan` | Gestion des VLAN |

L'utilisation systématique des outils `iproute2` est recommandée. Les commandes `net-tools` ne sont plus installées par défaut sur Debian depuis Debian 10 (Buster) et ne reçoivent plus de développement actif. Toutes les sections de ce module s'appuient exclusivement sur `iproute2`.

## Les fichiers et répertoires clés

Indépendamment du gestionnaire réseau utilisé, un certain nombre de fichiers système participent à la configuration réseau de Debian :

**/etc/hostname** contient le nom d'hôte court de la machine. Il est lu au démarrage par `systemd-hostnamed` et peut être modifié dynamiquement avec la commande `hostnamectl`.

**/etc/hosts** fournit la résolution de noms locale, consultée avant le DNS (sauf configuration contraire de `/etc/nsswitch.conf`). Il est essentiel d'y maintenir la correspondance entre le nom d'hôte, le FQDN et l'adresse IP de la machine, en particulier sur les serveurs.

**/etc/resolv.conf** définit les serveurs DNS utilisés pour la résolution de noms. Attention : ce fichier est souvent géré automatiquement par `systemd-resolved`, NetworkManager ou le client DHCP. Toute modification manuelle risque d'être écrasée si un de ces services est actif. La bonne pratique est de configurer les DNS via le gestionnaire réseau en place.

**/etc/nsswitch.conf** détermine l'ordre de résolution des noms (fichier `/etc/hosts`, DNS, LDAP, mDNS...). La ligne `hosts:` contrôle notamment si le fichier `/etc/hosts` est consulté avant ou après le DNS.

Les fichiers de configuration spécifiques à chaque gestionnaire réseau seront détaillés dans les sous-sections correspondantes.

## Vue d'ensemble des sous-sections

Cette section est organisée en six sous-sections progressives qui couvrent l'ensemble des compétences nécessaires à la maîtrise de la configuration réseau avancée sous Debian :

**6.1.1 — Interfaces réseau et bonding/teaming** aborde la configuration des interfaces physiques et l'agrégation de liens pour la redondance et l'augmentation de bande passante. Vous y apprendrez à configurer le bonding (mode active-backup, 802.3ad LACP) et à comprendre les différences avec le teaming.

**6.1.2 — Configuration statique et DHCP** détaille la mise en place d'adresses fixes et la configuration du client DHCP, avec les particularités de chaque gestionnaire réseau. Vous y verrez également la configuration du routage statique et la gestion de plusieurs passerelles.

**6.1.3 — IPv6 et dual-stack** vous prépare au déploiement d'IPv6 en parallèle d'IPv4, couvrant l'auto-configuration (SLAAC), DHCPv6, et les bonnes pratiques de transition.

**6.1.4 — VLAN et réseaux virtuels** traite de la segmentation réseau avec les VLAN 802.1Q et de la création de bridges virtuels, fondements indispensables pour la virtualisation et les conteneurs.

**6.1.5 — NetworkManager vs systemd-networkd vs /etc/network/interfaces** compare en profondeur les trois gestionnaires réseau, avec des critères de choix clairs et des scénarios d'utilisation recommandés pour chacun.

**6.1.6 — Diagnostic réseau** présente la boîte à outils complète de l'administrateur pour le dépannage réseau : `ip`, `ss`, `tcpdump`, `traceroute`, `mtr`, et les méthodologies de diagnostic structuré.

---

> **Remarque :** La configuration réseau est étroitement liée à la sécurité. Le filtrage réseau (nftables, ufw) et la protection des accès (fail2ban) sont traités dans la section 6.2, tandis que les accès distants (SSH) sont couverts en section 6.3. La maîtrise de la configuration réseau de cette section est un prérequis direct pour ces sujets.

---


⏭️ [Interfaces réseau et bonding/teaming](/module-06-reseau-securite/01.1-interfaces-bonding.md)
