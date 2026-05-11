🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 8.1 Serveur DNS

*Module 8 — Services réseau avancés, sauvegarde et HA · Niveau : Avancé*

---

## Introduction

Le DNS (*Domain Name System*) est l'un des services d'infrastructure les plus critiques d'Internet et de tout réseau d'entreprise. Sans lui, aucune application moderne ne fonctionnerait de manière utilisable : chaque connexion, qu'elle soit initiée par un humain ou par un service automatisé, commence presque toujours par une résolution de nom. Pour un administrateur système, maîtriser le DNS signifie à la fois comprendre un protocole conçu en 1983 (RFC 882/883, puis RFC 1034/1035) et exploiter des implémentations modernes capables de gérer des millions de requêtes par seconde, de signer cryptographiquement leurs réponses et de s'intégrer à des architectures cloud-native.

Cette section du Module 8 est consacrée à la mise en œuvre d'un service DNS de production sur Debian. Debian est historiquement une plateforme de référence pour l'hébergement DNS : elle fournit dans ses dépôts officiels les implémentations de référence (BIND9, Unbound, Knot, NSD, dnsmasq) avec un cycle de maintenance de sécurité rigoureux, ce qui est essentiel pour un service aussi exposé.

## Rappels fondamentaux

Avant d'entrer dans la configuration opérationnelle, il est utile de rappeler les concepts que l'on manipulera tout au long de cette section.

### Résolution et hiérarchie

Le DNS est un système distribué et hiérarchique. La hiérarchie part de la racine (notée `.`) et se décline en TLD (*Top-Level Domains* : `.fr`, `.com`, `.org`…), puis en domaines de second niveau (`debian.org`, `example.fr`), puis en sous-domaines. Chaque niveau est autoritaire pour sa zone et délègue aux niveaux inférieurs via des enregistrements `NS`.

Une résolution classique implique quatre acteurs : le **stub resolver** (la bibliothèque cliente, typiquement la glibc sur Debian), le **resolver récursif** (qui interroge la hiérarchie pour le compte du client), les **serveurs autoritaires** (qui détiennent la vérité pour leur zone) et éventuellement des **forwarders** intermédiaires. Cette distinction entre serveur **autoritaire** et serveur **récursif** est fondamentale : ce sont deux rôles différents, qui peuvent être assurés par le même logiciel mais qui ne devraient jamais, en production, être exposés sur la même instance.

### Les principaux types d'enregistrements

Une zone DNS est composée d'enregistrements de ressources (*Resource Records*, RR). Les plus courants sont `A` (IPv4), `AAAA` (IPv6), `CNAME` (alias), `MX` (mail), `TXT` (texte arbitraire, utilisé notamment pour SPF, DKIM, DMARC, vérifications de domaine), `NS` (serveurs de noms faisant autorité), `SOA` (*Start of Authority*, métadonnées de la zone), `PTR` (résolution inverse), `SRV` (localisation de services) et `CAA` (autorisation d'émission de certificats). Les déploiements DNSSEC ajoutent `DNSKEY`, `DS`, `RRSIG` et `NSEC`/`NSEC3`.

### Les ports et protocoles

Le DNS utilise historiquement le port 53 en UDP pour les requêtes courtes et en TCP pour les transferts de zone et les réponses volumineuses. Les déploiements modernes ajoutent DoT (*DNS over TLS*, port 853) et DoH (*DNS over HTTPS*, port 443) pour la confidentialité, ainsi que DNS over QUIC (DoQ). Ces protocoles seront abordés dans la sous-section consacrée à la sécurité.

## Enjeux dans une infrastructure moderne

Le rôle du DNS dépasse largement la simple résolution de noms d'hôtes. Dans une infrastructure Debian/Kubernetes typique, il intervient à plusieurs niveaux.

Au niveau du **système d'exploitation**, il est sollicité par `systemd-resolved` ou par la glibc via `/etc/nsswitch.conf` et `/etc/resolv.conf`. Au niveau **applicatif**, il pilote la découverte de services (pensez aux enregistrements `SRV` utilisés par Kerberos, LDAP ou par les stacks de messagerie). Au niveau **infrastructure**, il sert de brique de base aux certificats TLS (challenges ACME DNS-01 de Let's Encrypt, enregistrements CAA), aux politiques email (SPF, DKIM, DMARC — voir la section 8.3), à la haute disponibilité (round-robin, GeoDNS, health-checked records) et à l'intégration annuaire (Active Directory publie massivement dans le DNS). Dans un cluster **Kubernetes**, CoreDNS assure la résolution interne des Services et des Pods, mais il doit lui-même pouvoir interroger un DNS amont fiable : la santé du DNS d'infrastructure conditionne donc directement la santé du cluster.

Cela explique pourquoi le DNS est systématiquement déployé en haute disponibilité, surveillé de près, et pourquoi toute panne DNS se traduit par une panne générale perçue comme « Internet est cassé ».

## Choix d'implémentation sur Debian

Debian propose plusieurs serveurs DNS dans ses dépôts, chacun ciblant un usage différent. Il est important de choisir le bon outil pour le bon rôle.

**BIND9** (paquet `bind9`) est l'implémentation historique de référence, maintenue par l'ISC. Elle sait tout faire : autoritaire, récursif, master, slave, DNSSEC, vues, TSIG, RPZ, DDNS. C'est le couteau suisse du DNS et l'implémentation que l'on rencontre le plus fréquemment en entreprise. Elle fait l'objet de la section 8.1.1.

**Unbound** (paquet `unbound`) est un resolver récursif validant DNSSEC, conçu par NLnet Labs pour la performance et la sécurité. Il ne fait pas autoritaire (ou marginalement) : c'est un choix délibéré de séparation des rôles. Il sera étudié dans la section 8.1.4 comme alternative moderne à BIND9 pour la partie récursive.

**NSD** (*Name Server Daemon*, paquet `nsd`), également de NLnet Labs, est à l'inverse un serveur strictement autoritaire, optimisé pour servir rapidement des zones signées. Il est fréquemment associé à Unbound dans une architecture où chaque rôle est assuré par un logiciel spécialisé.

**Knot DNS** (paquet `knot`), développé par CZ.NIC (le registre `.cz`), est un autre serveur autoritaire haute performance, avec une gestion DNSSEC automatisée particulièrement soignée. Il est utilisé par plusieurs TLD en production.

**dnsmasq** (paquet `dnsmasq`) est un petit serveur combinant DNS forwarder et DHCP, idéal pour les réseaux locaux, les environnements embarqués ou les labs. Il est moins adapté à la production lourde mais excellent pour les passerelles et les routeurs Debian.

**systemd-resolved** enfin, déjà présent sur la plupart des installations Debian modernes, joue le rôle de stub resolver local avec cache. Il n'est pas un serveur DNS au sens où on l'entend dans cette section, mais il interagit directement avec eux et sa configuration impacte le comportement du système (voir section 3.4.5).

Dans ce qui suit, BIND9 sera utilisé comme fil conducteur parce qu'il reste la référence pédagogique et qu'il couvre tous les scénarios. Les alternatives seront introduites chaque fois qu'elles représentent un meilleur choix opérationnel.

## Ce que couvre cette section

La section 8.1 est organisée en quatre sous-parties progressives.

La sous-section **8.1.1 — BIND9 configuration avancée** pose les bases opérationnelles : architecture interne de `named`, organisation des fichiers de configuration sur Debian (`/etc/bind/`), options globales, journalisation, vues, ACL, intégration avec AppArmor, et bonnes pratiques de déploiement.

La sous-section **8.1.2 — Zones et enregistrements** descend au niveau du contenu : syntaxe des fichiers de zone, SOA et sérialisation, résolution directe et inverse (`in-addr.arpa`, `ip6.arpa`), délégations, zones esclaves, transferts de zone (AXFR/IXFR) authentifiés par TSIG.

La sous-section **8.1.3 — DNS dynamique et DNSSEC** aborde deux sujets plus avancés : le DDNS (mises à jour dynamiques signées, intégration avec le DHCP pour publier automatiquement les baux — voir aussi 8.2.4), et la signature cryptographique des zones (DNSSEC) avec gestion des clés KSK/ZSK, rollover, et publication des enregistrements `DS` auprès du registrar.

La sous-section **8.1.4 — Sécurité DNS et alternatives (Unbound)** clôt la section en traitant les attaques spécifiques au DNS (empoisonnement de cache, amplification, exfiltration via DNS tunneling), les contre-mesures (rate limiting, RPZ, DoT/DoH), et présente Unbound comme resolver récursif validant DNSSEC, avec une architecture recommandée de type « autoritaire séparé du récursif ».

## Objectifs pédagogiques

À l'issue de cette section, vous serez en mesure de concevoir et d'exploiter une infrastructure DNS interne pour un réseau d'entreprise ou une plateforme hébergée : choisir la bonne implémentation Debian selon le rôle, déployer une architecture autoritaire/récursive séparée, écrire et maintenir des fichiers de zone propres, signer une zone en DNSSEC, et sécuriser l'ensemble contre les attaques courantes. Vous comprendrez également comment ce service s'articule avec les autres briques du module (DHCP en 8.2, mail en 8.3) et avec les environnements conteneurisés et Kubernetes (introduits en Parcours 2 — Modules 11-12, approfondis en Parcours 3).

---


⏭️ [BIND9 configuration avancée](/module-08-services-avances-sauvegarde-ha/01.1-bind9-configuration.md)
