🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 8.2 Serveur DHCP

*Module 8 — Services réseau avancés, sauvegarde et HA · Niveau : Avancé*

---

## Introduction

Après le DNS, le DHCP est le second service d'infrastructure qui conditionne le fonctionnement quasi total d'un réseau moderne. Sans lui, chaque machine devrait être configurée manuellement avec son adresse IP, son masque, sa passerelle, ses serveurs DNS, son domaine de recherche, éventuellement son serveur de temps, de boot PXE, de configuration VoIP… La combinatoire est ingérable à plus d'une dizaine de postes et absolument impensable sur un réseau d'entreprise, un campus, un datacenter ou un environnement IoT comptant des milliers de nœuds. DHCP (*Dynamic Host Configuration Protocol*, RFC 2131 pour IPv4, RFC 8415 pour IPv6) résout ce problème en automatisant la distribution des paramètres réseau à chaque machine qui en fait la demande.

Cette section du Module 8 traite du déploiement d'un serveur DHCP de production sur Debian. Elle arrive naturellement après la section consacrée au DNS car les deux services sont intimement liés : dans une infrastructure moderne, le serveur DHCP ne se contente pas de distribuer des adresses, il **publie également dans le DNS** le nom des machines qu'il configure, via les mises à jour dynamiques vues en section 8.1.3. Cette intégration DNS-DHCP est l'un des enjeux centraux de la section.

## Rappels fondamentaux

Avant d'entrer dans les aspects opérationnels, il est utile de rappeler les concepts que nous manipulerons.

### Le cycle DORA

Le protocole DHCPv4 s'articule autour d'un échange en quatre messages, couramment désigné par l'acronyme **DORA** : *Discover*, *Offer*, *Request*, *Acknowledge*. Le client qui démarre et n'a pas encore d'adresse émet un DHCPDISCOVER en broadcast (le serveur n'est pas encore connu). Un ou plusieurs serveurs répondent par un DHCPOFFER proposant une adresse et un ensemble de paramètres. Le client choisit l'une des offres et émet un DHCPREQUEST, toujours en broadcast, pour signaler son choix aux autres serveurs. Le serveur retenu confirme par un DHCPACK ; les autres retirent leur offre. L'ensemble prend typiquement quelques centaines de millisecondes.

Quatre autres messages complètent le protocole : **DHCPDECLINE** quand le client détecte que l'adresse proposée est déjà utilisée (via ARP probe), **DHCPNAK** quand le serveur refuse un REQUEST (adresse obsolète par exemple), **DHCPRELEASE** pour libérer volontairement un bail, **DHCPINFORM** pour obtenir des paramètres sans demander d'adresse.

### Le bail (*lease*)

L'allocation d'une adresse IP par DHCP est une **location à durée déterminée**, appelée *bail*. À l'approche de son expiration, le client tente un **renouvellement** (REQUEST unicast au serveur d'origine), puis, en cas d'échec, une **rebind** (REQUEST broadcast à n'importe quel serveur). Si rien n'a réussi à l'expiration, le client abandonne l'adresse et relance un DISCOVER complet.

La durée du bail est un paramètre clé. Un bail court (quelques minutes, quelques heures) permet de recycler rapidement les adresses dans des environnements à fort roulement (Wi-Fi invités, DHCP cloud), au prix d'un trafic protocolaire accru. Un bail long (plusieurs jours) réduit ce trafic mais immobilise les adresses sur des machines éteintes. Les valeurs courantes oscillent entre 1 heure (invités) et 1 semaine (postes fixes).

### Options DHCP

Au-delà de l'adresse IP, DHCP transmet un ensemble d'**options** identifiées par un numéro et une sémantique documentée par l'IANA. Quelques options courantes :

- option 1 : masque de sous-réseau
- option 3 : passerelle par défaut (*router*)
- option 6 : serveurs DNS
- option 12 : nom d'hôte
- option 15 : nom de domaine
- option 42 : serveurs NTP
- option 43 : options spécifiques vendeur
- option 66 / 67 : serveur et fichier de boot (PXE)
- option 119 : liste de domaines de recherche DNS
- option 121 : routes classless statiques
- option 150 : serveur TFTP pour téléphonie VoIP

Certaines options sont universelles, d'autres sont spécifiques à des constructeurs (téléphones VoIP, imprimantes, bornes Wi-Fi managées). Un serveur DHCP de production doit pouvoir distribuer ces options de manière ciblée, selon la classe du client, sa MAC address, ou son appartenance à un sous-réseau.

### Réservations

Une **réservation** (ou *host reservation*, parfois *static mapping*) associe une adresse MAC (ou un identifiant client) à une adresse IP fixe, tout en conservant le mécanisme DHCP standard. L'avantage par rapport à une configuration manuelle sur le client est triple : les paramètres sont centralisés côté serveur, la machine reste gérée de manière homogène, et l'adresse est documentée dans le même inventaire que les baux dynamiques. Les réservations sont essentielles pour les serveurs, les imprimantes, les équipements réseau, et toute machine où l'adresse doit être prédictible sans être configurée sur la machine elle-même.

### Relais DHCP

DHCP repose sur des broadcasts de niveau 2 pour la découverte, ce qui confine naturellement le service à un seul segment L2. Dans une architecture typique où un même serveur DHCP dessert plusieurs VLANs, on utilise un **relais DHCP** (*DHCP relay*, RFC 3046) : sur chaque réseau, un équipement (routeur, switch L3, firewall, ou même un simple démon Linux) capte les broadcasts DHCP des clients et les relaie en unicast vers le serveur central. Le relais insère dans le message l'**option 82** (*Relay Agent Information*) qui permet au serveur d'identifier le sous-réseau d'origine et de choisir la bonne configuration.

Cette architecture relais est la norme dans les entreprises de toute taille : un (ou deux) serveurs DHCP centraux qui servent l'ensemble des VLANs via des relais configurés sur les équipements réseau.

### DHCPv6 et la relation avec SLAAC

Le paysage IPv6 est plus complexe. IPv6 propose deux mécanismes d'auto-configuration : **SLAAC** (*StateLess Address AutoConfiguration*, RFC 4862), où la machine forge elle-même son adresse à partir du préfixe annoncé par le routeur, et **DHCPv6** (RFC 8415), qui reprend un modèle serveur-client analogue à DHCPv4 mais avec une signalisation différente (Solicit, Advertise, Request, Reply).

Les deux ne sont pas exclusifs. En fonction des flags annoncés par le routeur via les *Router Advertisements* (bit M pour *Managed configuration*, bit O pour *Other configuration*), une machine peut utiliser SLAAC seul, SLAAC + DHCPv6 pour les options non adresse (modèle *stateless DHCPv6*), ou DHCPv6 complet (modèle *stateful*). Le choix dépend de la politique de l'infrastructure : le monde entreprise tend vers DHCPv6 stateful pour conserver le contrôle et la traçabilité, tandis que les réseaux grand public et mobiles privilégient souvent SLAAC.

La **délégation de préfixe** (DHCPv6-PD, RFC 8415) est un cas d'usage spécifiquement IPv6 : un serveur DHCPv6 attribue non pas une adresse unique mais un **préfixe entier** (typiquement un /56 ou /64) à un routeur client, qui le sous-redistribue à son propre LAN. C'est le mécanisme utilisé par les FAI pour déléguer à chaque abonné un préfixe IPv6 que sa box utilise ensuite localement.

## Enjeux dans une infrastructure moderne

Le rôle du DHCP dans une infrastructure va bien au-delà de la distribution d'adresses IP dans un LAN bureautique.

Dans un **datacenter** ou un **cloud privé**, le DHCP sert au bootstrapping des serveurs physiques (PXE + DHCP pour l'installation automatisée via preseed, voir section 7.1.1) et au provisioning des machines virtuelles et conteneurs système. Les mécanismes d'IPAM (*IP Address Management*) s'appuient directement sur les bases DHCP pour leur vue d'ensemble.

Dans un **environnement industriel ou IoT**, le DHCP doit être fiable, rapide, et capable de fournir des configurations différentes selon le type d'équipement détecté (via l'option 60 *Vendor Class Identifier* ou l'option 77 *User Class*). Une panne DHCP sur une chaîne de production entraîne l'impossibilité de redémarrer les équipements — l'exigence de disponibilité est donc élevée.

Dans un réseau **Wi-Fi d'entreprise ou de campus**, le DHCP doit gérer des milliers de baux concurrents avec un roulement important (associations/dissociations des clients mobiles). Les performances du serveur et la qualité de l'intégration avec les contrôleurs Wi-Fi deviennent critiques.

Dans une infrastructure **Kubernetes** on-premise, le DHCP gère l'attribution d'adresses aux nœuds du cluster (pour le réseau « infra »), tandis que le réseau interne des pods est géré par le CNI (Calico, Cilium…) sans DHCP. La frontière est nette : DHCP pour les machines, CNI pour les workloads.

Dans tous ces scénarios, deux exigences sont transverses. Première exigence : la **haute disponibilité**. Comme le DNS, le DHCP est un service dont la panne paralyse l'ensemble. Une architecture à deux serveurs en redondance (actif/passif ou actif/actif selon l'implémentation) est la norme. Seconde exigence : l'**intégration avec le DNS**. Chaque machine qui reçoit un bail DHCP devrait voir son nom publié automatiquement dans le DNS, à la fois en direct (A/AAAA) et en inverse (PTR). Cette intégration DNS-DHCP est gérée par les deux protocoles RFC 2136 (mises à jour dynamiques) et TSIG (authentification), vus en section 8.1.3 et repris en détail dans la section 8.2.4.

## Implémentations disponibles sur Debian

Debian propose plusieurs logiciels DHCP, chacun avec un cas d'usage privilégié.

**ISC Kea** (paquets `kea-dhcp4-server`, `kea-dhcp6-server`, `kea-ctrl-agent`, `kea-admin`) est le serveur DHCP moderne développé par l'ISC (*Internet Systems Consortium*, les mêmes que pour BIND). Il est conçu pour la production à grande échelle, avec une architecture modulaire, une API REST de contrôle, le support des bases de données externes (MySQL, PostgreSQL, Cassandra) pour la persistance des baux, et une haute disponibilité intégrée. C'est l'implémentation étudiée en section 8.2.1.

**ISC DHCP Server** (paquet `isc-dhcp-server` — qui couvre à la fois IPv4 et IPv6 via le binaire `dhcpd6 -6`, sans paquet séparé) est l'implémentation historique de l'ISC, longtemps l'outil standard de l'industrie. Elle a été officiellement **déclarée en fin de vie (EOL) par l'ISC fin 2022**. Sur Trixie, le paquet est encore livré (version 4.4.3-P1-8) mais **explicitement marqué comme déprécié et sans support sécurité Debian**. **Tout nouveau déploiement doit utiliser Kea**, pas ISC DHCP. Les migrations existantes vers Kea doivent être planifiées dans un calendrier raisonnable. Nous n'étudierons ISC DHCP Server qu'en tant que point de comparaison et de référence pour les migrations.

**dnsmasq** (paquet `dnsmasq`) combine un petit serveur DHCP et un DNS forwarder dans un seul binaire. Il est parfait pour les passerelles, les routeurs Debian, les équipements embarqués, les labs, les environnements de développement. Il est inadapté aux déploiements d'entreprise de grande taille, mais il règne sur un immense parc d'équipements de bord (box Internet, routeurs Wi-Fi OpenWrt, Raspberry Pi passerelles).

**systemd-networkd** dispose d'un serveur DHCPv4 minimaliste (`DHCPServer=yes` dans un `.network`) qui suffit pour des configurations très simples mais ne couvre pas les besoins de production. Il est surtout utile pour des cas embarqués où on veut éviter d'ajouter une dépendance supplémentaire.

**dhcpcd** (paquet `dhcpcd`, côté client) n'est pas un serveur mais il mérite mention comme client DHCP alternatif à `systemd-networkd` et `NetworkManager`, avec un support IPv6 particulièrement propre.

Pour complétude, signalons que de nombreux équipements réseau dédiés (routeurs professionnels, firewalls comme pfSense/OPNsense, contrôleurs Wi-Fi, équipements Mikrotik/Cisco) intègrent leur propre serveur DHCP. Le choix entre un DHCP sur équipement réseau et un DHCP sur serveur Debian dépend du périmètre, des compétences de l'équipe et de l'intégration souhaitée avec le reste du SI.

## Le passage d'ISC DHCP Server à Kea

Le choix de Kea comme sujet principal de cette section n'est pas un choix esthétique : il reflète la réalité de l'écosystème. ISC a annoncé la fin de support d'ISC DHCP Server en 2022, concluant un cycle entamé en 2014 avec le début du développement de Kea comme successeur. Les deux produits ne partagent ni la base de code, ni le format de configuration, ni le modèle d'exploitation.

Kea apporte plusieurs évolutions structurelles. Sa configuration est en **JSON** et non plus dans un format propriétaire ; elle est donc directement manipulable par des outils d'automatisation. Son architecture est **modulaire** : on active uniquement les composants dont on a besoin (DHCPv4, DHCPv6, DDNS, contrôle API, hooks). Il expose une **API REST** pour l'administration et l'intégration avec des outils d'IPAM. Il supporte nativement la **persistance en base de données** pour les baux, rendant la haute disponibilité et la scalabilité beaucoup plus simples. Les **hooks** (bibliothèques chargées dynamiquement) permettent d'étendre le comportement sans patcher le serveur : hook de haute disponibilité, hook de commandement à chaud, hook de limitation de classe, etc.

La contrepartie est une courbe d'apprentissage plus raide pour qui vient d'ISC DHCP Server. La configuration `dhcpd.conf` des années 2000, avec sa syntaxe quasi-Perl, doit être traduite en JSON ; l'organisation en sous-réseaux, pools, réservations, options reste conceptuellement identique mais s'exprime différemment. La section 8.2.1 couvrira cette configuration en détail.

## Ce que couvre cette section

La section 8.2 est organisée en quatre sous-parties.

La sous-section **8.2.1 — ISC Kea** installe et configure Kea comme serveur DHCPv4 et DHCPv6. Elle couvre l'architecture du logiciel, l'organisation des fichiers de configuration JSON, le choix entre stockage mémoire et stockage base de données pour les baux, la configuration des sous-réseaux et des pools, la gestion des options, le contrôle via l'agent REST.

La sous-section **8.2.2 — Plages et haute disponibilité** traite le dimensionnement des plages d'adresses et la mise en haute disponibilité de Kea via son hook HA. Elle présente les deux modes principaux (*load-balancing* et *hot-standby*), la synchronisation des baux entre pairs, la détection et la récupération après panne.

La sous-section **8.2.3 — Réservations statiques** détaille la gestion des réservations : par MAC, par DUID (IPv6), par identifiant circuit (option 82), avec paramètres globaux ou par sous-réseau, en configuration fichier ou en base de données pour du self-service. Elle couvre aussi les classes clients pour distribuer des options différenciées.

La sous-section **8.2.4 — Intégration DNS-DHCP** ferme la boucle entamée en 8.1.3 : comment faire en sorte que chaque bail émis par Kea soit automatiquement publié dans le DNS via des mises à jour dynamiques authentifiées TSIG, avec publication directe (A/AAAA) et inverse (PTR), cohérence des deux et gestion des cas particuliers (noms dupliqués, machines mobiles, révocations).

## Objectifs pédagogiques

À l'issue de cette section, vous serez en mesure de déployer un service DHCP d'infrastructure de niveau entreprise sur Debian : installer et configurer ISC Kea en IPv4 et IPv6, dimensionner des plages adaptées, établir une redondance active entre deux instances, gérer des réservations statiques à grande échelle, et intégrer le tout avec votre DNS pour maintenir automatiquement la cohérence nom-adresse. Vous aurez aussi les éléments pour juger si une migration depuis ISC DHCP Server vers Kea est nécessaire dans votre infrastructure existante, et comment la mener.

Cette section s'articule étroitement avec la 8.1 (DNS, intégration DDNS) et prépare la section 8.3 (mail) qui consomme à son tour des enregistrements DNS publiés partiellement par DHCP (notamment les noms de machines dans les zones internes).

---


⏭️ [ISC Kea (successeur d'ISC DHCP Server)](/module-08-services-avances-sauvegarde-ha/02.1-isc-kea.md)
