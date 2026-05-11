🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 8.3 Serveur mail

*Module 8 — Services réseau avancés, sauvegarde et HA · Niveau : Avancé*

---

## Introduction

Le courrier électronique est sans doute le plus ancien des services Internet encore massivement utilisés. Son protocole historique, SMTP, a été spécifié en 1982 (RFC 821, puis RFC 2821 en 2001, actuellement RFC 5321) ; il fonctionne en production depuis plus de quarante ans avec des extensions successives mais un cœur remarquablement stable. En 2026, malgré l'essor des messageries instantanées, des outils collaboratifs et des notifications push, le mail reste un service d'infrastructure critique pour toute organisation : il supporte la communication formelle, transporte les notifications système, sert de vecteur d'authentification (liens de confirmation, codes de réinitialisation), et conserve ses qualités d'archivage et d'interopérabilité qu'aucune plateforme propriétaire n'a réellement remplacées.

Pour un administrateur système Debian, construire et exploiter une infrastructure mail est à la fois une compétence classique et un défi en évolution permanente. Classique, parce que les composants sont stables et bien documentés : Postfix pour le transport SMTP, Dovecot pour l'accès IMAP/POP3, Rspamd ou SpamAssassin pour le filtrage, les outils d'authentification de domaine (SPF, DKIM, DMARC) comme garde-fous. En évolution, parce que les exigences du reste d'Internet montent chaque année : TLS obligatoire, authentification cryptographique des expéditeurs, politiques de rejet strictes, scoring de réputation, résistance aux attaques et au spam. Héberger sérieusement son mail en 2026 demande plus de rigueur qu'il y a dix ans, et impose une maîtrise des composants qui vont au-delà du simple « installer Postfix ».

Cette section traite l'ensemble de la pile mail sur Debian, depuis le transport jusqu'au client final, en intégrant les aspects sécurité et anti-spam. Elle s'appuie fortement sur les sections précédentes : le DNS (8.1) est partout — enregistrements MX, politiques SPF/DKIM/DMARC, PTR pour la réputation — et les exigences de disponibilité (8.4, 8.5) s'appliquent au mail comme à tout service d'infrastructure.

## Rappels architecturaux

Avant d'entrer dans les configurations, il est utile de rappeler le vocabulaire et les composants d'une architecture mail.

### Les acteurs d'un échange

Le trajet d'un courriel met en scène plusieurs rôles, chacun correspondant à un logiciel spécifique.

**MUA** (*Mail User Agent*) : le client final qui compose, envoie et consulte les messages. Thunderbird, Outlook, Apple Mail, Roundcube côté webmail, `mutt` ou `mailx` en console.

**MSA** (*Mail Submission Agent*) : le serveur qui accepte un message soumis par un MUA. Il parle SMTP, typiquement sur le port 587 (*Submission*, RFC 6409) avec authentification et chiffrement TLS obligatoires. En pratique, sur un serveur mail Debian, le MSA est généralement Postfix configuré avec un listener sur le port 587 et une politique d'authentification SASL.

**MTA** (*Mail Transfer Agent*) : le serveur qui transporte un message entre domaines. Il parle SMTP sur le port 25 et négocie STARTTLS avec ses pairs. C'est le cœur du système de mail. Les MTA populaires sur Debian sont Postfix (le plus répandu, couvert en 8.3.1), Exim (distribution par défaut de Debian historiquement, toujours disponible), et OpenSMTPD (plus récent, orienté simplicité de configuration).

**MDA** (*Mail Delivery Agent*) : le composant qui dépose un message dans la boîte aux lettres finale du destinataire. Sur Debian, c'est souvent Dovecot via son protocole LMTP (*Local Mail Transfer Protocol*, RFC 2033), qui applique au passage des règles de tri Sieve.

**MRA** (*Mail Retrieval Agent*) : côté lecture, le serveur IMAP ou POP3 qui sert les messages aux clients. Dovecot (couvert en 8.3.2) assure ce rôle sur la quasi-totalité des déploiements Debian modernes.

### Le trajet d'un message

Pour bien fixer l'architecture, suivons un message de bout en bout.

Alice, qui utilise l'adresse `alice@example.fr`, compose un message destiné à `bob@example.org` depuis son client Thunderbird. Thunderbird se connecte sur le port 587 (*Submission*) du serveur `smtp.example.fr`, s'authentifie via SASL, chiffre la session en TLS, et envoie le message à Postfix jouant le rôle de MSA. Postfix valide le message, le place dans sa file d'attente, et lance la résolution MX pour `example.org`. Il interroge le DNS, obtient `mx.example.org`, se connecte sur le port 25 de ce serveur, négocie STARTTLS, et livre le message. Côté `example.org`, le Postfix récepteur applique les politiques SPF, DKIM, DMARC pour décider si le message est légitime. S'il l'accepte, il le passe à Rspamd pour scoring anti-spam, puis à Dovecot via LMTP, qui l'applique dans la boîte aux lettres de `bob` (avec éventuellement du tri Sieve). Quand Bob ouvre son webmail ou Thunderbird, le client se connecte à `imap.example.org` sur le port 993 (IMAPS), s'authentifie auprès de Dovecot et télécharge le message.

Ce scénario fait intervenir : DNS (MX, A/AAAA, PTR, SPF, DKIM, DMARC, MTA-STS), TLS (les deux segments MUA→MSA et MTA→MTA doivent être chiffrés), authentification utilisateur (SASL), anti-spam (Rspamd), stockage (Maildir ou dbox côté Dovecot), et protocoles applicatifs distincts à chaque étape. C'est une mécanique complexe où chaque composant a son rôle, et où une configuration correcte nécessite de comprendre l'ensemble.

## Enjeux de l'hébergement mail en 2026

Il y a vingt ans, héberger son mail était une compétence d'administrateur standard. Aujourd'hui, c'est devenu une spécialité à part entière, pour plusieurs raisons.

### La bataille de la réputation

Gmail, Outlook et quelques autres grands fournisseurs détiennent une part prépondérante du trafic mail mondial. Leurs systèmes anti-spam examinent chaque message entrant avec un scoring sophistiqué qui combine réputation de l'IP émettrice, conformité aux politiques d'authentification, qualité du contenu, comportement historique de l'expéditeur. Un nouveau serveur mail sur une IP jamais utilisée pour du mail part avec une réputation neutre ou légèrement négative et doit la bâtir progressivement. Une erreur de configuration (SPF manquant, PTR absent, DKIM cassé) et les messages tombent en spam voire sont rejetés.

Cette réalité a deux conséquences. D'abord, elle impose une configuration **irréprochable** dès le premier jour : pas de compromis sur les politiques d'authentification. Ensuite, elle rend délicat l'hébergement sur des plages IP « résidentielles » ou sur certains hébergeurs à mauvaise réputation — il faut choisir son hébergeur avec soin et parfois demander explicitement une IP « propre » pour le mail.

### Les obligations techniques

Plusieurs exigences qui étaient optionnelles il y a quelques années sont désormais quasi-obligatoires.

**TLS partout.** Un serveur qui refuse STARTTLS côté MTA voit son trafic rejeté ou déclassé. Un serveur qui expose IMAP/POP3 en clair (ports 143/110) au lieu des versions TLS (993/995) est simplement inacceptable en 2026.

**SPF, DKIM, DMARC publiés et cohérents.** Sans SPF, beaucoup de destinataires appliquent d'office un soft reject. Sans DKIM, les politiques DMARC strictes s'enclenchent. Sans DMARC, l'expéditeur ne reçoit pas de retour sur les tentatives d'usurpation de son domaine. Ces trois mécanismes, détaillés en 8.3.5, sont la base de la légitimation d'un expéditeur moderne.

**MTA-STS et DANE.** Deux standards plus récents qui imposent respectivement que les MTA distants se connectent en TLS strict (MTA-STS, RFC 8461) et qui lient la clé TLS du serveur à DNSSEC (DANE, RFC 7672). Leur adoption progresse et leur absence commence à peser sur la délivrabilité vers les destinataires exigeants.

**IPv6.** Toujours optionnel mais désormais quasi-standard, l'IPv6 avec PTR cohérent est un indicateur de sérieux.

### L'alternative du relais

Face à cette complexité, une stratégie devenue courante est le **relais** par un service spécialisé. Au lieu d'envoyer directement les messages sortants depuis ses propres serveurs, on les route via un relais commercial (Amazon SES, Mailgun, Postmark, Sendgrid, Mailjet, Brevo, SMTP2Go…) qui gère la réputation IP, les boucles de rétroaction avec les grands fournisseurs, la conformité DKIM, et garantit une délivrabilité élevée. Le serveur local n'héberge plus que la réception et éventuellement le stockage, sans avoir à gérer les subtilités de l'envoi.

Cette approche hybride — Postfix + Dovecot en local pour la réception, relais externe pour l'envoi — est aujourd'hui fréquente et souvent plus pragmatique que l'auto-hébergement complet. Elle sera évoquée dans la section 8.3.1 au travers de la configuration du `relayhost` Postfix.

### Quand s'auto-héberger, quand déléguer

La question n'est plus « peut-on héberger son mail » — techniquement, oui — mais « **faut-il** l'héberger » au regard du temps à y consacrer et des alternatives disponibles. Quelques critères :

Pour une petite structure avec quelques boîtes et peu de compétence interne mail, externaliser complètement à Google Workspace, Microsoft 365, Infomaniak, OVH, Zoho, ou une offre dédiée est souvent plus rentable que de maintenir une infrastructure locale.

Pour une organisation soucieuse de souveraineté, de confidentialité, ou disposant des compétences internes, l'auto-hébergement reste pertinent. Il prend typiquement la forme d'un Postfix + Dovecot + Rspamd sur Debian, éventuellement avec Roundcube pour le webmail, et un relais externe pour l'envoi vers les grands fournisseurs si la délivrabilité est critique.

Pour une infrastructure importante ou régulée (santé, défense, finance), l'auto-hébergement complet est souvent imposé par la réglementation, avec des exigences de traçabilité, d'archivage et d'isolation.

Cette section traite l'auto-hébergement complet en Debian. Les principes et les outils restent applicables dans une architecture hybride — c'est le périmètre fonctionnel qui change, pas la technologie.

## Composants d'une pile mail Debian

Debian fournit dans ses dépôts l'ensemble des briques nécessaires à une pile mail complète. Les composants les plus courants :

**Postfix** est le MTA dominant. Développé par Wietse Venema, il est reconnu pour sa simplicité de configuration, sa sécurité (architecture modulaire avec chroot et privilèges séparés), et sa performance. C'est le MTA retenu dans cette section comme fil conducteur (8.3.1).

**Exim** est le MTA historique de Debian, avec une configuration flexible mais souvent complexe. Il reste pertinent dans certains cas mais cède la place à Postfix dans la majorité des déploiements récents.

**OpenSMTPD**, développé par l'équipe OpenBSD, privilégie une syntaxe de configuration particulièrement concise. Encore minoritaire, il séduit les administrateurs qui apprécient sa philosophie.

**Dovecot** est le serveur IMAP/POP3 de référence en 2026. Performant, modulaire, avec un excellent support de Sieve, des quotas, de la réplication, du SSO. Sujet de la section 8.3.2.

**Rspamd** est le moteur anti-spam moderne, écrit en C, plus performant et plus riche fonctionnellement que l'ancien SpamAssassin. Il gère à la fois le filtrage entrant et sortant, la signature DKIM, le greylisting, l'apprentissage bayésien. Il est au cœur de la section 8.3.3.

**SpamAssassin** est l'alternative classique, écrite en Perl, plus ancienne mais toujours maintenue. Moins performante que Rspamd mais mieux documentée dans certains manuels anciens. Présente à titre comparatif en 8.3.3.

**ClamAV** est l'anti-virus open-source standard, intégrable dans la chaîne de traitement mail. Son efficacité réelle est débattue à l'ère des attaques ciblées, mais sa présence reste une exigence de conformité dans beaucoup d'environnements.

**Roundcube**, **SOGo**, **RainLoop** sont des webmails courants, permettant aux utilisateurs un accès navigateur sans client lourd. Couverts en 8.3.4.

**OpenDKIM** et **OpenDMARC** sont les implémentations traditionnelles pour la signature DKIM et la validation DMARC. À noter que Rspamd sait faire les deux nativement, ce qui rend les services dédiés moins nécessaires dans les architectures modernes — la section 8.3.5 détaillera les choix.

Au-delà de ces composants de base, il existe des **suites intégrées** qui préconfigurent l'ensemble : **Modoboa** (panneau web d'administration avec Postfix/Dovecot/Amavis/Rspamd), **Mailu** (pile mail conteneurisée), **iRedMail** (installeur automatisé), **Mail-in-a-Box** (distribution dédiée, pas strictement Debian). Ces suites accélèrent le déploiement au prix d'une opacité sur les composants. Elles sont mentionnées comme alternatives mais la section privilégie la configuration directe pour que les mécanismes soient compris.

## Ce que couvre cette section

La section 8.3 est organisée en cinq sous-parties progressives.

La sous-section **8.3.1 — Postfix configuration complète** pose le MTA : installation, architecture interne (master/smtpd/cleanup/qmgr), organisation des fichiers `main.cf` et `master.cf`, tables de lookup, restrictions SMTP, TLS, authentification SASL, gestion des files d'attente, intégration avec un relais externe.

La sous-section **8.3.2 — Dovecot (IMAP/POP3)** déploie le serveur de réception : installation, formats de stockage (Maildir, mdbox, sdbox), protocoles IMAP/POP3/LMTP, authentification (PAM, bases SQL, LDAP), quotas, Sieve pour le tri côté serveur, réplication entre instances.

La sous-section **8.3.3 — Filtrage anti-spam (Rspamd, SpamAssassin)** traite la défense contre le spam : architecture Rspamd, intégration à Postfix via milter, règles et scoring, greylisting, apprentissage bayésien, interface web Rspamd, comparaison avec SpamAssassin et quand l'une ou l'autre solution est préférable.

La sous-section **8.3.4 — Webmail et clients** couvre l'accès utilisateur : Roundcube comme webmail classique, SOGo pour l'intégration groupware, configuration côté MUA (Thunderbird, Outlook, mobile), autodiscover/autoconfig, protocoles de soumission et de lecture.

La sous-section **8.3.5 — DKIM, SPF, DMARC** boucle sur les mécanismes d'authentification de domaine déjà effleurés en 8.1 : publication des enregistrements DNS, signature et validation, politiques DMARC et remontées d'alerte, BIMI, MTA-STS, DANE, et plus généralement la construction d'une réputation d'expéditeur.

## Objectifs pédagogiques

À l'issue de cette section, vous serez en mesure de déployer une pile mail Debian complète et conforme aux standards 2026 : transport sécurisé via Postfix, réception et accès via Dovecot, filtrage par Rspamd, accès webmail via Roundcube, et publication cohérente des politiques d'authentification de domaine. Vous comprendrez les compromis entre auto-hébergement complet et architecture hybride avec relais externe, et vous aurez les éléments pour juger lequel convient à votre contexte.

Cette section conclut le triptyque des services d'infrastructure réseau du module 8 (DNS, DHCP, mail) et prépare la section 8.4 sur les stratégies de sauvegarde, dont le mail est un cas d'usage particulièrement délicat — les volumes, les contraintes légales d'archivage, et les exigences de restauration rapide en font un sujet à part entière.

---


⏭️ [Postfix configuration complète](/module-08-services-avances-sauvegarde-ha/03.1-postfix.md)
