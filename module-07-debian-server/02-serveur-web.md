🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 7.2 Serveur web

## Introduction

Le serveur web est l'un des rôles les plus courants attribués à un serveur Debian. Qu'il serve des pages HTML statiques, exécute des applications dynamiques (PHP, Python, Node.js), expose des API REST ou agisse comme reverse proxy devant un cluster de microservices, le serveur web est souvent le premier point de contact entre les utilisateurs et l'infrastructure.

Le choix du serveur web, sa configuration et son optimisation ont un impact direct sur la performance, la sécurité et la fiabilité des services exposés. Un serveur web mal configuré peut être lent, vulnérable aux attaques ou incapable de supporter la montée en charge. À l'inverse, un serveur web correctement dimensionné et durci constitue une fondation solide pour l'ensemble des services applicatifs.

Ce chapitre présente les trois serveurs web les plus pertinents dans l'écosystème Debian en 2026 : **Apache**, le vétéran extensible ; **Nginx**, le performant événementiel ; et **Caddy**, le moderne avec HTTPS automatique. Chacun est couvert en détail dans une sous-section dédiée, depuis l'installation jusqu'à l'optimisation. Les sections transversales couvrent ensuite les virtual hosts, le reverse proxy, TLS/HTTPS avec Let's Encrypt et le tuning de performance.

---

## Panorama des serveurs web sous Debian

### Apache HTTP Server

Apache est le serveur web le plus ancien et le plus déployé historiquement. Né en 1995 au sein de l'Apache Software Foundation, il a longtemps dominé le marché du web. Son architecture modulaire lui permet de s'adapter à presque tous les cas d'usage : serveur de fichiers statiques, exécution PHP via `mod_php`, reverse proxy, authentification complexe, réécriture d'URL avancée, WebDAV, et bien d'autres.

Debian intègre Apache dans ses dépôts officiels sous le nom de paquet `apache2`. Il bénéficie d'un support de sécurité long et d'une intégration poussée avec l'écosystème Debian (outils `a2ensite`, `a2enmod`, structure de configuration spécifique à Debian).

Apache fonctionne selon un modèle de traitement des requêtes configurable via des MPM (Multi-Processing Modules). Le MPM activé par défaut sur Debian (Trixie incluse) est `event`, qui offre un bon compromis entre compatibilité et performance. À noter : l'installation du paquet `libapache2-mod-php` bascule automatiquement vers le MPM `prefork`, car `mod_php` n'est pas thread-safe et n'est pas compatible avec `event`/`worker`. Pour conserver `event`, on utilise PHP-FPM via `mod_proxy_fcgi` (combinaison recommandée pour les performances).

### Nginx

Nginx (prononcé « engine-x ») a été créé en 2004 par Igor Sysoev pour répondre aux limites de performance d'Apache face à un grand nombre de connexions simultanées — le fameux problème C10K (gérer 10 000 connexions concurrentes). Son architecture événementielle non bloquante lui permet de servir un très grand nombre de requêtes avec une empreinte mémoire réduite.

Initialement positionné comme un serveur de fichiers statiques et un reverse proxy ultra-performant, Nginx est devenu un serveur web complet capable d'exécuter des applications dynamiques via FastCGI (PHP-FPM, Python WSGI) et de remplir des rôles de load balancer, de cache HTTP et de terminaison TLS.

Nginx est disponible dans les dépôts Debian officiels. Sa configuration repose sur une syntaxe propre, différente de celle d'Apache, organisée en blocs imbriqués (contextes `http`, `server`, `location`).

### Caddy

Caddy est le plus récent des trois, avec une première version stable en 2020. Son positionnement est celui de la simplicité et de la sécurité par défaut. Sa caractéristique la plus distinctive est l'**obtention et le renouvellement automatiques des certificats TLS** via le protocole ACME (Let's Encrypt, ZeroSSL) sans aucune configuration supplémentaire. Là où Apache et Nginx nécessitent l'installation et la configuration de Certbot ou d'un client ACME équivalent, Caddy gère l'intégralité du cycle de vie des certificats nativement.

Caddy est écrit en Go, ce qui se traduit par un binaire unique sans dépendances et un déploiement simplifié. Sa configuration utilise un format propre appelé **Caddyfile**, dont la syntaxe minimaliste contraste avec la verbosité d'Apache ou la densité de Nginx.

Caddy est disponible dans les dépôts officiels Debian Trixie (paquet `caddy`, version 2.6.2), ce qui garantit le support de sécurité par l'équipe Debian Security. Pour disposer d'une version plus récente avec les dernières fonctionnalités et corrections, l'équipe Caddy maintient également un dépôt APT officiel. Sa base d'utilisateurs croît rapidement, en particulier dans les environnements cloud-native et les projets où la simplicité de configuration est prioritaire.

---

## Critères de choix

Le choix entre ces trois serveurs web ne se fait pas dans l'absolu — il dépend du contexte technique, des compétences de l'équipe et des contraintes du projet. Voici les critères principaux à considérer.

### Performance et modèle de concurrence

**Apache** utilise un modèle de processus/threads. Chaque requête est traitée par un processus ou un thread dédié (selon le MPM). Le MPM `event` améliore la gestion des connexions keep-alive, mais Apache reste plus gourmand en mémoire que Nginx sous forte charge. Pour un serveur hébergeant quelques sites à trafic modéré, cette différence est négligeable. Elle devient significative au-delà de plusieurs milliers de connexions simultanées.

**Nginx** utilise un modèle événementiel asynchrone. Un petit nombre de processus workers gère un grand nombre de connexions simultanées via des boucles d'événements (epoll sous Linux). Ce modèle est intrinsèquement plus efficace en mémoire et en CPU pour servir des fichiers statiques et proxifier des requêtes. Il excelle comme reverse proxy et terminaison TLS devant des applications backend.

**Caddy** utilise le modèle de concurrence de Go (goroutines), qui est également événementiel et performant. Ses performances brutes sont proches de celles de Nginx pour la plupart des cas d'usage courants. L'écart se manifeste essentiellement sur des benchmarks synthétiques à très haute charge, rarement représentatifs d'un usage réel.

### Facilité de configuration

**Apache** a la courbe d'apprentissage la plus longue. Sa configuration est riche mais verbeuse, avec de nombreuses directives et une structure de fichiers propre à Debian (`sites-available`, `sites-enabled`, `mods-available`, `mods-enabled`). Les outils `a2ensite`, `a2enmod` et `a2dissite` simplifient la gestion, mais la quantité de documentation et d'options disponibles peut être déroutante pour un débutant.

**Nginx** propose une syntaxe plus concise et structurée. La hiérarchie des blocs (`http` → `server` → `location`) reflète logiquement l'architecture d'un serveur web. La courbe d'apprentissage est modérée, et la cohérence syntaxique facilite la lecture des configurations complexes.

**Caddy** est le plus simple à configurer. Un Caddyfile de quelques lignes suffit pour servir un site en HTTPS avec reverse proxy. La contrepartie est une moindre granularité : les configurations très avancées nécessitent parfois de recourir au format JSON de Caddy, nettement plus verbeux.

### Écosystème et extensibilité

**Apache** dispose de l'écosystème le plus riche. Des centaines de modules couvrent tous les cas d'usage imaginables : authentification LDAP, WebDAV, réécriture d'URL (mod_rewrite), compression (mod_deflate), cache, sécurité (mod_security), exécution PHP intégrée (mod_php). Certains modules n'ont pas d'équivalent dans les autres serveurs.

**Nginx** possède un système de modules compilés dans le binaire (modules statiques) ou chargeables dynamiquement. L'écosystème est large mais moins étendu que celui d'Apache. Certaines fonctionnalités avancées (inspection du corps des requêtes, filtrage WAF) nécessitent des modules tiers comme **ModSecurity v3** (via `libnginx-mod-http-modsecurity`/`ModSecurity-nginx`), **Coraza** (WAF en Go), ou l'édition commerciale Nginx Plus.

**Caddy** est extensible via des plugins écrits en Go. L'écosystème est plus jeune et plus restreint, mais les plugins les plus courants (cache, rate limiting, authentification) sont disponibles. L'ajout d'un plugin nécessite de recompiler le binaire Caddy avec l'outil `xcaddy`, ce qui est un processus simple mais différent de l'activation d'un module Apache ou Nginx.

### TLS et HTTPS

**Apache et Nginx** nécessitent une configuration TLS explicite : génération ou obtention d'un certificat, configuration des paramètres TLS (protocoles, suites cryptographiques, OCSP stapling, HSTS). L'automatisation via Let's Encrypt est possible avec Certbot, mais c'est un composant externe à installer et à maintenir.

**Caddy** gère nativement l'intégralité du cycle de vie TLS : obtention du certificat lors du premier démarrage, renouvellement automatique avant expiration, configuration des paramètres TLS avec des valeurs par défaut sécurisées (TLS 1.2+ uniquement, suites modernes, OCSP stapling activé). C'est un avantage considérable pour les déploiements où chaque site doit être en HTTPS sans effort d'administration supplémentaire.

### Intégration Debian

**Apache** bénéficie de la meilleure intégration avec Debian. La structure de configuration (`/etc/apache2/`), les outils de gestion (`a2ensite`, `a2enmod`), l'intégration avec les scripts de maintenance Debian et le support de sécurité via l'équipe Debian Security en font un citoyen de première classe de l'écosystème.

**Nginx** est bien intégré dans Debian avec une structure de configuration similaire (`/etc/nginx/sites-available`, `sites-enabled`) et un support de sécurité officiel.

**Caddy** est disponible dans les dépôts officiels Debian Trixie (version 2.6.2, supportée par l'équipe Debian Security). Si l'on opte pour une version plus récente via le dépôt tiers de l'équipe Caddy, le support de sécurité dépend alors de l'éditeur. C'est un point à arbitrer selon les exigences de conformité du contexte.

---

## Tableau comparatif synthétique

| Critère | Apache | Nginx | Caddy |
|---------|--------|-------|-------|
| **Première version** | 1995 | 2004 | 2020 |
| **Langage** | C | C | Go |
| **Modèle de concurrence** | Processus/Threads (MPM) | Événementiel (epoll) | Goroutines |
| **Dépôt Debian** | Officiel | Officiel | Officiel (2.6.2) ou tiers (caddy) pour versions récentes |
| **Paquet Debian** | `apache2` | `nginx` | `caddy` |
| **Configuration** | Directives + balises (`<Directory>`, `<VirtualHost>`) | Blocs imbriqués | Caddyfile / JSON |
| **HTTPS automatique** | Non (Certbot externe) | Non (Certbot externe) | Oui (natif ACME) |
| **Exécution PHP** | mod_php (uniquement avec MPM prefork) ou PHP-FPM | PHP-FPM uniquement | PHP-FPM uniquement |
| **Reverse proxy** | mod_proxy | proxy_pass | reverse_proxy |
| **Rechargement sans coupure** | `apachectl graceful` | `nginx -s reload` | `caddy reload` |
| **Empreinte mémoire** | Modérée à élevée | Faible | Faible à modérée |
| **Fichiers statiques** | Bon | Excellent | Très bon |
| **Modules/Plugins** | Très nombreux | Nombreux | Écosystème jeune |
| **Documentation** | Très abondante | Abondante | Bonne, en croissance |
| **Part de marché** | En déclin progressif | Dominante | En croissance rapide |

---

## Architecture de déploiement typique

Avant de détailler chaque serveur web individuellement, il est utile de comprendre les architectures de déploiement les plus courantes sur un serveur Debian.

### Serveur web autonome

Le cas le plus simple : un seul serveur web sert directement les requêtes des clients. Cette architecture convient aux petits sites, aux applications internes et aux environnements de développement.

```
Client → [Serveur web Debian] → Fichiers statiques / Application
```

Le serveur web écoute sur les ports 80 (HTTP) et 443 (HTTPS), traite les requêtes et renvoie les réponses. L'application peut être exécutée directement par le serveur web (mod_php pour Apache) ou via un processus séparé (PHP-FPM, Gunicorn pour Python, Puma pour Ruby).

### Reverse proxy devant une application

Le serveur web agit comme intermédiaire entre les clients et un ou plusieurs serveurs applicatifs. Cette architecture est la plus courante en production car elle sépare les responsabilités : le reverse proxy gère la terminaison TLS, la compression, la mise en cache des ressources statiques et la distribution du trafic, tandis que le serveur applicatif se concentre sur le traitement métier.

```
Client → [Reverse proxy (Nginx/Caddy)] → [Application backend (port 8080)]
```

Le reverse proxy écoute sur les ports 80/443 et transfère les requêtes à l'application backend qui écoute sur un port local (8080, 3000, etc.) non exposé directement sur le réseau. Cette séparation apporte plusieurs bénéfices : le backend n'a pas besoin de gérer TLS, le reverse proxy peut distribuer la charge entre plusieurs instances du backend, et les ressources statiques (images, CSS, JavaScript) peuvent être servies directement par le proxy sans solliciter le backend.

### Serveur multi-sites (virtual hosts)

Un seul serveur Debian héberge plusieurs sites web distincts, chacun avec son propre nom de domaine. Le serveur web utilise le mécanisme de **virtual hosts** (Apache, Nginx) ou de **sites** (Caddy) pour router les requêtes vers le bon site en fonction du nom de domaine présent dans l'en-tête HTTP `Host`.

```
site-a.example.com → [Serveur web] → /var/www/site-a/  
site-b.example.com → [Serveur web] → /var/www/site-b/  
api.example.com    → [Serveur web] → proxy → localhost:8080  
```

Les trois serveurs web supportent nativement cette architecture. Chaque virtual host dispose de sa propre configuration (racine documentaire, certificat TLS, règles de réécriture, logs séparés).

---

## Prérequis

Les sous-sections de ce chapitre s'appuient sur les connaissances et les configurations établies dans les sections précédentes :

- Un serveur Debian installé et durci conformément aux sections 7.1.1 à 7.1.3, avec un pare-feu nftables actif et configuré en politique *deny by default*.
- Une configuration réseau fonctionnelle avec résolution DNS opérationnelle (section 7.1.2).
- Une maîtrise de l'édition de fichiers de configuration en ligne de commande et de la gestion des services systemd (Module 3).
- Pour les sections TLS/HTTPS : un nom de domaine pointant vers l'adresse IP du serveur (enregistrement DNS de type A et/ou AAAA), nécessaire pour l'obtention de certificats Let's Encrypt.

Avant d'installer un serveur web, les ports HTTP (80) et HTTPS (443) doivent être ouverts dans le pare-feu :

```bash
# Ajout dans la chaîne input de /etc/nftables.conf

# Serveur web HTTP et HTTPS
tcp dport { 80, 443 } accept
```

```bash
$ sudo nft -f /etc/nftables.conf
```

---

## Organisation des sous-sections

Chaque serveur web est traité dans sa propre sous-section avec une structure homogène : installation, configuration de base, premiers tests. Les sections transversales qui suivent abordent des sujets communs aux trois serveurs :

**7.2.1 Apache : installation et configuration** — Installation du paquet `apache2`, compréhension de la structure Debian (`a2ensite`, `a2enmod`), configuration de base, MPM et modules essentiels.

**7.2.2 Nginx : installation et configuration** — Installation, structure des fichiers de configuration, syntaxe des blocs, directives fondamentales, gestion de PHP-FPM.

**7.2.3 Caddy : HTTPS automatique et configuration simplifiée** — Installation via le dépôt officiel, syntaxe du Caddyfile, fonctionnement de l'HTTPS automatique, API d'administration.

**7.2.4 Virtual hosts et reverse proxy** — Configuration multi-sites et reverse proxy pour les trois serveurs, avec des exemples comparatifs pour faciliter les transpositions.

**7.2.5 SSL/TLS et certificats (Let's Encrypt, ACME)** — Obtention et renouvellement automatique des certificats, configuration TLS durcie, HSTS, OCSP stapling — pour Apache et Nginx (Caddy gérant cela nativement).

**7.2.6 Performance tuning et comparaison** — Optimisation des paramètres de performance, mise en cache, compression, benchmarking et comparaison des trois serveurs en conditions réelles.

⏭️ [Apache : installation et configuration](/module-07-debian-server/02.1-apache.md)
