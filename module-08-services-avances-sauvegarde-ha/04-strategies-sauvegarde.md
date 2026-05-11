🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 8.4 Stratégies de sauvegarde

*Module 8 — Services réseau avancés, sauvegarde et HA · Niveau : Avancé*

---

## Introduction

La sauvegarde est, avec la surveillance, l'une des deux disciplines opérationnelles dont personne ne conteste l'importance et que pourtant tout le monde néglige par moments. C'est l'assurance dont on se passe sans dommage pendant des années, jusqu'au jour où son absence transforme un incident ordinaire en catastrophe. Panne disque, corruption de base, suppression accidentelle, fausse manipulation, attaque par rançongiciel, incendie, vol de matériel — chacune de ces situations peut rendre irrécupérables des données représentant des mois ou des années de travail, si aucune sauvegarde cohérente n'est disponible.

Les administrateurs expérimentés partagent tous, à un moment ou un autre de leur carrière, cette conviction particulière : **une sauvegarde que l'on n'a jamais restaurée n'existe pas**. Les cimetières opérationnels sont remplis de scripts de sauvegarde qui tournaient fidèlement pendant des années sans que personne ne vérifie leur sortie, et qui se sont révélés le jour J produire des archives tronquées, vides, corrompues, ou chiffrées avec une clé perdue. La sauvegarde n'est pas un processus à mettre en place une fois pour toutes : c'est une pratique à entretenir activement, avec des tests de restauration réguliers, une documentation vivante, et une veille sur les évolutions techniques et réglementaires.

Cette section du Module 8 traite la sauvegarde sous l'angle opérationnel : choix des outils, stratégies de rotation, stockage distant, chiffrement, automatisation, calcul de tolérance aux pertes, validation des restaurations. Elle s'adresse à un contexte Debian classique (serveurs physiques ou VMs) mais les concepts s'appliquent tout autant aux infrastructures conteneurisées ou cloud traitées dans les parcours 2 et 3.

## Rappels fondamentaux

Avant d'entrer dans les outils et les stratégies, il est utile de fixer quelques concepts qui structurent tout ce qui suit.

### Ce qu'on sauvegarde, ce qu'on ne sauvegarde pas

Un système Debian comporte plusieurs catégories de données, qui ne méritent pas toutes le même traitement.

**Les données de l'utilisateur et de l'organisation** — fichiers, bases de données, messages, configurations personnalisées — sont la catégorie principale. Leur perte n'est pas récupérable autrement que par restauration. C'est l'objet premier de la sauvegarde.

**La configuration du système** (`/etc`, scripts d'administration, règles de firewall) est en théorie reproductible par réinstallation, mais cette reproduction prend du temps et comporte des risques d'oubli. La sauvegarder évite des heures de reconstruction en cas d'incident.

**Les logs** (`/var/log`) représentent un volume important et une valeur opérationnelle réelle (forensique, conformité). Leur sauvegarde se justifie dans les environnements régulés, mais souvent séparément du reste (vers un SIEM, voir section 16.4.4).

**Les binaires et les bibliothèques système** (`/usr`, `/bin`, `/lib`) sont en revanche reproductibles à l'identique par une simple réinstallation. Les sauvegarder n'apporte rien et gaspille de l'espace. La pratique moderne, à plus forte raison dans les environnements cloud-native, est de les considérer comme jetables.

**Les caches et les états transitoires** (`/var/cache`, `/tmp`) sont à exclure systématiquement. Sauvegarder un cache, c'est en sauvegarder la version obsolète à chaque exécution, sans aucun bénéfice.

Un plan de sauvegarde discipliné définit explicitement ce qui entre dans chaque catégorie et ce qui est exclu — la discipline d'exclusion est souvent plus importante que celle d'inclusion, parce qu'elle préserve les performances et la lisibilité des archives.

### Sauvegarde, réplication, archivage : ne pas confondre

Trois notions sont fréquemment amalgamées alors qu'elles répondent à des besoins différents.

**La sauvegarde** (*backup*) vise à récupérer un état antérieur en cas d'incident. Son essence est la **conservation historique** : les versions d'hier, de la semaine dernière, du mois précédent. Une suppression accidentelle, une corruption discrète, une attaque par rançongiciel nécessitent de revenir en arrière dans le temps — la sauvegarde seule le permet.

**La réplication** (ou la haute disponibilité) copie les données en temps réel sur un second support, pour supporter une panne sans interruption de service. Mais une suppression ou une corruption se propage instantanément à la copie. La réplication protège contre la panne matérielle, **pas contre l'erreur logique**.

**L'archivage** conserve des données à long terme pour des raisons légales, historiques ou de conformité, sans intention de restauration active. Ses contraintes sont différentes : durée de conservation très longue (dix ans, vingt ans, parfois plus), support adapté (stockage froid, bande), indexation pour retrouver des éléments précis sans restaurer l'ensemble.

Un même outil peut parfois couvrir plusieurs de ces fonctions, mais les confondre dans le raisonnement conduit à des architectures fragiles. Une infrastructure qui a de la réplication mais pas de sauvegarde est ruinée par la première `rm -rf` ; une qui a de la sauvegarde mais pas de réplication vit avec des fenêtres d'indisponibilité longues. Les deux sont nécessaires et complémentaires.

### Les menaces auxquelles la sauvegarde répond

Une bonne stratégie de sauvegarde commence par identifier les scénarios de perte contre lesquels elle protège.

**Défaillance matérielle.** Un disque dur tombe en panne, une baie de stockage brûle, un SSD se corrompt. Le scénario historique qui a motivé l'invention de la sauvegarde. La réplication et le RAID (vu en 8.5.1) atténuent, la sauvegarde restaure complètement.

**Erreur humaine.** `rm -rf` hors du bon répertoire, `DROP TABLE` sans `WHERE`, suppression massive par erreur dans un panneau d'administration. C'est statistiquement la cause numéro un de perte de données en entreprise — bien avant les pannes matérielles ou les attaques. Seule la sauvegarde historique protège.

**Corruption logique.** Un bug applicatif, une mise à jour ratée, un défaut dans un système de fichiers peut corrompre des données silencieusement. La corruption se propage à la réplication ; elle remonte à la sauvegarde pendant un certain temps avant d'être détectée et de se propager aussi aux sauvegardes si elles ne sont pas assez nombreuses ou pas assez anciennes. La **profondeur** de l'historique compte : garder plusieurs semaines ou mois de versions offre une fenêtre de détection.

**Attaque par rançongiciel.** Un attaquant chiffre les fichiers et demande une rançon pour la clé. Les rançongiciels modernes ciblent explicitement les sauvegardes accessibles depuis le serveur compromis, pour empêcher la restauration sans paiement. La parade : des sauvegardes **hors ligne** ou **immuables**, inaccessibles depuis le serveur source.

**Catastrophe physique.** Incendie, inondation, vol, séisme — le site entier est perdu. La sauvegarde locale ne sert à rien si elle brûle avec le serveur. La règle du 3-2-1 (voir 8.4.5) impose une copie **hors site**.

**Compromission de compte d'administration.** Un attaquant obtient les credentials, accède à l'infrastructure, peut détruire aussi bien les données de production que les sauvegardes en ligne. Les sauvegardes doivent avoir des credentials **distincts** et idéalement un modèle de sécurité indépendant.

**Évolution réglementaire.** Une obligation nouvelle (RGPD, DORA, réglementations sectorielles) impose de retrouver des données dans un état antérieur pour répondre à un audit ou à une injonction. Les sauvegardes existantes doivent supporter cette demande.

Chacun de ces scénarios oriente différemment les choix : type de média, localisation, fréquence, durée de rétention, chiffrement, automatisation des tests. Un plan de sauvegarde complet les adresse tous, pas seulement le plus visible (la panne matérielle).

## Les spécificités des services vus dans le module 8

Les trois services d'infrastructure vus jusqu'ici — DNS (8.1), DHCP (8.2), mail (8.3) — posent chacun des contraintes particulières pour la sauvegarde.

**Le DNS** est relativement simple à sauvegarder : ses fichiers de zones et sa configuration sont du texte, de petit volume. Les particularités viennent des **zones signées DNSSEC** dont les clés privées doivent être sauvegardées (séparément et de manière très sécurisée — leur compromission permettrait à un attaquant de forger des réponses valides pendant la durée de vie des signatures publiées), et des **zones dynamiques DDNS** où le fichier `.jnl` doit être capturé de manière cohérente avec le fichier de zone principal (d'où l'importance du `rndc freeze`/`thaw` vu en 8.1.3).

**Le DHCP** sauvegarde sa configuration (simple) et sa **base de baux**. Cette base contient l'association nom-adresse courante et les réservations. Sans elle, après restauration, tous les clients se verraient attribuer de nouvelles adresses et la cohérence avec le DNS serait temporairement perdue. Pour Kea (8.2.1), la sauvegarde peut être un simple `cp` du fichier memfile, ou un `mysqldump`/`pg_dump` selon le backend, mais doit être coordonnée avec un éventuel moyeu HA.

**Le mail** est le cas le plus délicat. Plusieurs composantes à sauvegarder simultanément pour une cohérence globale :

- Les **configurations** (Postfix, Dovecot, Rspamd) — petit volume, classique.
- Les **files d'attente Postfix** (`/var/spool/postfix/`) — en transit, peut contenir des messages pas encore délivrés.
- Les **boîtes Dovecot** — potentiellement énorme, croissant avec les utilisateurs et leur usage. Index Dovecot qui peuvent se régénérer si perdus.
- La **base des utilisateurs** (SQL ou LDAP) — avec mots de passe, quotas, alias.
- Les **clés DKIM** et certificats TLS — critiques cryptographiquement.
- Les **règles Rspamd** et le **classifieur bayésien Redis** — représentant des mois d'apprentissage.

Le volume des boîtes dans une organisation de 100 utilisateurs se chiffre facilement en centaines de gigaoctets. La sauvegarde complète quotidienne devient vite impraticable en temps et en bande passante : c'est typiquement le cas d'usage qui **force** le recours à des sauvegardes **incrémentales** ou à des outils dédupliqués comme BorgBackup ou Restic (voir 8.4.2).

## Les piliers d'une stratégie de sauvegarde

Une stratégie complète couvre plusieurs dimensions qui doivent être explicitées et cohérentes entre elles.

**Le périmètre.** Quelles données sauvegarder, sur quels serveurs, avec quelle fréquence. Le plan doit être documenté, tenu à jour, et revu périodiquement (idéalement au moins une fois par an) pour refléter l'évolution réelle de l'infrastructure.

**La stratégie de rotation.** Combien de versions garder, sur quelle durée. Un schéma classique conserve les sauvegardes quotidiennes sur une semaine, hebdomadaires sur un mois, mensuelles sur un an, annuelles sur dix ans. Les choix dépendent du volume, du budget, des obligations légales.

**Le stockage.** Local (rapide, pratique mais vulnérable), LAN (intermédiaire), WAN ou cloud (distant, plus cher), offline ou immuable (ultime défense contre le rançongiciel). La règle **3-2-1** (trois copies, deux supports différents, une hors site) est le standard minimal. Certains règlements exigent davantage.

**L'intégrité et la sécurité.** Chiffrement au repos et en transit, authentification forte des accès, isolation des credentials de sauvegarde, protection contre la modification ou la suppression (immutabilité via *object lock* S3, par exemple).

**L'automatisation et la supervision.** Sans automatisation, la sauvegarde est oubliée. Sans supervision, l'automatisation tourne à vide. Chaque exécution doit produire une trace visible, chaque échec doit déclencher une alerte.

**La validation.** Restauration réelle testée périodiquement. Sans ce test, on ne sait pas si le plan fonctionne. C'est la règle la plus violée et la plus importante.

**La documentation.** Procédure de restauration écrite, à jour, testée, accessible même en cas d'incident majeur (pas seulement sur le serveur qui a planté). Les clés et credentials stockés séparément, avec des copies de secours.

**La conformité réglementaire.** RGPD pour les données personnelles (droit à l'effacement qui impose de pouvoir supprimer une personne de toutes les sauvegardes), obligations sectorielles (santé, finance, énergie) qui imposent des durées minimales ou des architectures spécifiques.

Chacun de ces piliers fait l'objet de décisions explicites. Une stratégie improvisée ou héritée du « on a toujours fait comme ça » finit par accumuler des incohérences.

## Ce que couvre cette section

La section 8.4 est organisée en six sous-parties progressives.

La sous-section **8.4.1 — Types de sauvegardes** pose les fondamentaux théoriques : différence entre sauvegarde **complète**, **incrémentale** et **différentielle**, compromis entre espace, temps et simplicité de restauration, notions de chaîne de dépendance entre sauvegardes, pratique moderne des sauvegardes synthétiques et dédupliquées.

La sous-section **8.4.2 — Outils Debian** passe en revue les principaux outils disponibles : `rsync` pour la copie incrémentale classique, `tar` pour l'archivage, **BorgBackup** pour la sauvegarde dédupliquée chiffrée moderne, **Restic** comme alternative orientée stockage cloud, et des mentions d'outils plus spécialisés (Duplicity, Bacula, Amanda). Comparaison et critères de choix.

La sous-section **8.4.3 — Automatisation avec cron et timers systemd** traite l'industrialisation : comment planifier les sauvegardes, reprendre les principes vus en 3.4.6 et 5.2.2 pour le cas spécifique de la sauvegarde, gestion des verrous (empêcher deux sauvegardes simultanées), envoi des notifications en cas de succès et d'échec.

La sous-section **8.4.4 — Sauvegarde distante et chiffrement** aborde le stockage hors site : sauvegarde sur NFS/SMB, sur serveur SSH distant, sur stockage objet S3 ou compatible, chiffrement des données au repos et en transit, gestion des clés de chiffrement (GPG, age, mot de passe BorgBackup), considérations de bande passante.

La sous-section **8.4.5 — Calcul RTO/RPO et stratégie 3-2-1** formalise les paramètres métier : **RTO** (temps maximal acceptable pour restaurer le service après un incident), **RPO** (quantité maximale de données que l'on peut se permettre de perdre), la **règle du 3-2-1** et ses évolutions modernes (3-2-1-1-0, 4-3-2), et comment dimensionner sa stratégie en fonction de ces paramètres.

La sous-section **8.4.6 — Tests de restauration et validation** traite le sujet crucial et souvent négligé : comment tester régulièrement que les sauvegardes sont effectivement restaurables, comment valider la cohérence des données restaurées, comment documenter les procédures pour qu'elles soient exécutables par quelqu'un d'autre que leur auteur, comment intégrer les tests dans le cycle opérationnel.

## Objectifs pédagogiques

À l'issue de cette section, vous serez en mesure de concevoir, déployer et exploiter une stratégie de sauvegarde pour une infrastructure Debian : choisir les outils adaptés à votre contexte, définir un plan de rotation cohérent avec vos contraintes métier (RTO/RPO), mettre en place un stockage distant chiffré, automatiser les sauvegardes avec supervision et alerting, et surtout vérifier périodiquement que la restauration fonctionne. Vous aurez également les éléments pour évaluer les besoins réglementaires qui s'appliquent à votre contexte et pour justifier les décisions auprès de la hiérarchie ou des auditeurs.

Cette section prépare la **section 8.5** qui clôt le module 8 par les mécanismes de **haute disponibilité** — complémentaires à la sauvegarde mais répondant à des besoins différents, et qui ensemble forment les deux piliers de la résilience d'une infrastructure.

---


⏭️ [Types de sauvegardes (complète, incrémentale, différentielle)](/module-08-services-avances-sauvegarde-ha/04.1-types-sauvegardes.md)
