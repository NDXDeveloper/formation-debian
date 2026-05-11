🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe A.2 — Options courantes et exemples

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette sous-annexe détaille les **options les plus utilisées** des commandes fondamentales de la formation. Là où l'annexe A.1 fournit une vue d'ensemble par catégorie fonctionnelle, cette section approfondit chaque commande clé en expliquant la logique de ses options, leurs combinaisons courantes et leur comportement dans des situations concrètes.

Les commandes sont regroupées par domaine technique. Seules les options réellement utiles au quotidien sont documentées : pour les cas d'usage rares ou avancés, la page `man` de chaque commande reste la référence.

---

## Conventions

- Les options courtes (`-v`) et longues (`--verbose`) sont présentées ensemble quand elles existent.
- Le symbole `↦` introduit un exemple de sortie ou un résultat attendu.
- Les commentaires après `#` expliquent le rôle de chaque élément.

---

## 1. Administration système

### systemctl

La commande `systemctl` pilote l'ensemble du système d'initialisation systemd. Ses sous-commandes se répartissent en trois familles : contrôle des unités, inspection de l'état et gestion du système global.

**Sous-commandes de contrôle des unités :**

```bash
# systemctl start nginx.service
# Démarre le service immédiatement. Le suffixe .service est facultatif
# quand il n'y a pas d'ambiguïté avec un autre type d'unité.

# systemctl stop nginx
# Arrête le service. Les processus reçoivent d'abord SIGTERM,
# puis SIGKILL après le timeout configuré (90s par défaut).

# systemctl restart nginx
# Arrêt puis redémarrage. Provoque une interruption de service.

# systemctl reload nginx
# Recharge la configuration sans interrompre le service.
# Tous les services ne supportent pas cette opération.

# systemctl reload-or-restart nginx
# Tente un reload, effectue un restart si le reload n'est pas supporté.
# C'est souvent la forme la plus sûre dans les scripts.

# systemctl enable nginx
# Crée les liens symboliques pour le démarrage automatique.
# N'a aucun effet sur l'état actuel du service.

# systemctl enable --now nginx
# Active ET démarre le service en une seule opération.

# systemctl disable --now nginx
# Désactive ET arrête le service.

# systemctl mask nginx
# Empêche totalement le démarrage du service (même manuellement).
# Crée un lien vers /dev/null.

# systemctl unmask nginx
# Annule un mask précédent.
```

**Sous-commandes d'inspection :**

```bash
$ systemctl status nginx
# Affiche : état actif/inactif, PID, mémoire utilisée,
# les dernières lignes de logs et l'arbre des processus.

$ systemctl is-active nginx
# Retourne "active" ou "inactive". Code retour 0 si actif.
# Utile dans les scripts : if systemctl is-active --quiet nginx; then ...

$ systemctl is-enabled nginx
# Retourne "enabled", "disabled", "masked" ou "static".

$ systemctl is-failed nginx
# Retourne "failed" si le service a échoué.

$ systemctl show nginx --property=MainPID,ActiveState,SubState
# Affiche des propriétés spécifiques au format clé=valeur.
# Idéal pour l'extraction de données dans les scripts.

$ systemctl list-dependencies nginx
# Affiche l'arbre des dépendances du service.

$ systemctl cat nginx
# Affiche le contenu du fichier d'unité et ses overrides.
```

**Sous-commandes de listage :**

```bash
$ systemctl list-units --type=service --state=running
# --type=   : filtre par type (service, timer, socket, mount, target...)
# --state=  : filtre par état (running, failed, active, inactive, enabled...)

$ systemctl list-units --failed
# Raccourci pour --state=failed. Premier réflexe après un problème.

$ systemctl list-unit-files --type=service
# Liste les fichiers d'unité installés avec leur état d'activation.

$ systemctl list-timers --all
# Affiche tous les timers avec leur prochain déclenchement.
```

### journalctl

L'exploitation des logs avec `journalctl` repose sur la combinaison de filtres. Ces filtres sont cumulatifs : chaque option ajoutée affine la sélection.

**Filtres par source :**

```bash
$ journalctl -u nginx.service
# -u, --unit=    : filtre par unité systemd.
# Accepte les motifs glob : -u "nginx*"

$ journalctl -u nginx -u php-fpm
# Plusieurs unités simultanément. Les entrées sont entrelacées
# chronologiquement.

$ journalctl _COMM=sshd
# Filtre par nom de commande (champ du journal).

$ journalctl _UID=1000
# Filtre par UID de l'utilisateur ayant généré le message.

$ journalctl -t sudo
# -t, --identifier= : filtre par identifiant syslog.
```

**Filtres temporels :**

```bash
$ journalctl --since "2026-04-12 08:00"
$ journalctl --since "2 hours ago"
$ journalctl --since "yesterday" --until "today"
$ journalctl --since "2026-04-01" --until "2026-04-07"
# Les formats acceptés sont nombreux : dates ISO, "today", "yesterday",
# "X hours/minutes/days ago", etc.

$ journalctl -b
# Messages du démarrage actuel uniquement.

$ journalctl -b -1
# Messages du démarrage précédent. Utile après un crash.

$ journalctl --list-boots
# Liste tous les démarrages enregistrés avec leurs identifiants.
```

**Filtres par priorité :**

```bash
$ journalctl -p err
# -p, --priority= : filtre par niveau de sévérité.
# Niveaux : emerg (0), alert (1), crit (2), err (3),
#           warning (4), notice (5), info (6), debug (7)
# Le filtre inclut le niveau spécifié et tous les niveaux supérieurs.

$ journalctl -p warning..err
# Plage de priorités : de warning à err inclus.
```

**Options de sortie :**

```bash
$ journalctl -f
# -f, --follow : suivi en temps réel (équivalent de tail -f).

$ journalctl -n 50
# -n, --lines= : nombre de lignes affichées (défaut : 10 avec -e).

$ journalctl -e
# -e, --pager-end : positionne l'affichage à la fin du journal.

$ journalctl --no-pager
# Sortie directe sans pagination. Indispensable dans les scripts
# et les pipes.

$ journalctl -o json-pretty
# -o, --output= : format de sortie.
# Formats : short (défaut), short-iso, verbose, json, json-pretty, cat
# "cat" affiche uniquement le message sans métadonnées.

$ journalctl -o json -u nginx --no-pager | jq '.MESSAGE'
# Combinaison avec jq pour l'extraction de données.

$ journalctl --disk-usage
# Espace disque occupé par les journaux.

# journalctl --vacuum-time=30d
# Supprime les journaux de plus de 30 jours.

# journalctl --vacuum-size=500M
# Réduit les journaux à 500 Mo maximum.
```

---

## 2. Gestion des paquets

### apt

Les options d'`apt` modifient le comportement de l'installation et de la mise à jour des paquets.

**Options d'installation :**

```bash
# apt install -y nginx
# -y, --yes : répond oui automatiquement à toutes les confirmations.
# Indispensable dans les scripts d'automatisation.

# apt install --no-install-recommends nginx
# N'installe pas les paquets recommandés, uniquement les dépendances
# strictes. Réduit considérablement l'empreinte sur les serveurs.

# apt install --no-install-suggests nginx
# N'installe pas les paquets suggérés (comportement par défaut,
# mais explicite dans les Dockerfiles).

# apt install -d nginx
# -d, --download-only : télécharge sans installer.
# Utile pour préparer une mise à jour hors-ligne.

# apt install --reinstall nginx
# Force la réinstallation d'un paquet déjà présent.

# apt install -s nginx
# -s, --simulate : simulation sans action réelle.
# Affiche ce qui serait installé, supprimé ou mis à jour.

# apt install nginx=1.26.3-3+deb13u2
# Installation d'une version spécifique (utiliser le numéro exact retourné
# par `apt policy <paquet>`).

# apt install nginx/trixie-backports
# Installation depuis un dépôt spécifique. Le suffixe `-backports`
# fournit des versions plus récentes que celles de la stable, sans casser
# la cohérence du système. Adapter selon la version cible : trixie-backports
# pour Debian 13, bookworm-backports pour Debian 12.
```

**Options de recherche et d'information :**

```bash
$ apt search --names-only nginx
# Limite la recherche aux noms de paquets (exclut les descriptions).

$ apt show nginx
# Affiche : version, taille, dépendances, description, mainteneur.

$ apt policy nginx
# Affiche les versions disponibles dans chaque dépôt
# et les priorités de pinning applicables.
# ↦ nginx:
# ↦   Installed: 1.26.3-3+deb13u2
# ↦   Candidate: 1.26.3-3+deb13u2
# ↦   Version table:
# ↦      1.28.0-1~bpo13+1 100
# ↦         100 http://deb.debian.org/debian trixie-backports/main
# ↦   *** 1.26.3-3+deb13u2 500
# ↦         500 http://deb.debian.org/debian trixie/main

$ apt list --installed | grep -i nginx
# Recherche parmi les paquets installés.

$ apt list --upgradable
# Liste les paquets pour lesquels une mise à jour est disponible.
```

**Options de nettoyage :**

```bash
# apt autoremove
# Supprime les dépendances devenues orphelines après une désinstallation.

# apt autoremove --purge
# Idem, en supprimant aussi les fichiers de configuration.

# apt clean
# Vide le cache local des paquets téléchargés (/var/cache/apt/archives/).

# apt autoclean
# Supprime uniquement les paquets qui ne sont plus disponibles
# dans les dépôts (versions obsolètes).
```

### dpkg

Les options de `dpkg` sont orientées vers l'inspection bas niveau des paquets.

```bash
$ dpkg -l 'nginx*'
# -l, --list : liste les paquets correspondant au motif.
# La première colonne indique l'état :
#   ii = installé correctement
#   rc = supprimé mais config conservée
#   un = inconnu / non installé

$ dpkg -L nginx
# -L, --listfiles : tous les fichiers installés par le paquet.
# Utile pour localiser les fichiers de configuration.

$ dpkg -S /usr/sbin/nginx
# -S, --search : identifie le paquet propriétaire d'un fichier.
# Accepte les motifs glob.

$ dpkg -s nginx
# -s, --status : informations détaillées sur le paquet installé.

$ dpkg -I package.deb
# -I, --info : informations sur un fichier .deb avant installation.

$ dpkg -c package.deb
# -c, --contents : liste le contenu d'un fichier .deb.

$ dpkg --compare-versions 1.26.3-3 gt 1.24.0-2 && echo "plus récent"
# Comparaison de numéros de version selon la logique Debian
# (utile dans les scripts de mise à jour conditionnelle).

# dpkg --configure -a
# Reprend la configuration de tous les paquets en attente.
# Premier réflexe quand apt signale des paquets cassés.
```

---

## 3. Réseau

### ip

La commande `ip` est modulaire : chaque sous-commande (`addr`, `link`, `route`, `neigh`) possède ses propres options.

**ip addr — gestion des adresses :**

```bash
$ ip addr show
# Forme abrégée : ip a

$ ip -4 addr show
# -4 : uniquement les adresses IPv4.
# -6 : uniquement les adresses IPv6.

$ ip addr show dev eth0
# Filtrage par interface.

$ ip addr show scope global
# scope global : adresses routables uniquement (exclut link-local).

# ip addr add 192.168.1.100/24 dev eth0
# ip addr add 192.168.1.101/24 dev eth0 label eth0:1
# label : crée un alias d'interface (compatibilité avec les anciens outils).

# ip addr del 192.168.1.100/24 dev eth0
# ip addr flush dev eth0
# flush : supprime toutes les adresses de l'interface.
```

**ip link — gestion des interfaces :**

```bash
$ ip link show
# Forme abrégée : ip l

$ ip -s link show eth0
# -s, --stats : affiche les statistiques (octets, paquets, erreurs).
# Double -s (-s -s) pour les statistiques détaillées.

# ip link set eth0 up
# ip link set eth0 down
# ip link set eth0 mtu 9000
# ip link set eth0 promisc on

# ip link add br0 type bridge
# ip link set eth0 master br0
# Création et configuration d'un bridge réseau.

# ip link add bond0 type bond mode 802.3ad
# Création d'une interface de bonding (agrégation de liens).
```

**ip route — gestion des routes :**

```bash
$ ip route show
# Forme abrégée : ip r

$ ip route get 8.8.8.8
# Affiche la route qui serait utilisée pour atteindre cette destination.
# Inclut l'interface de sortie et la passerelle.

# ip route add 10.0.0.0/8 via 192.168.1.1
# ip route add default via 192.168.1.1 dev eth0
# ip route del 10.0.0.0/8
# ip route replace default via 192.168.1.254
# replace : ajoute ou modifie la route (idempotent, adapté aux scripts).
```

**Options globales de ip :**

```bash
$ ip -c addr show
# -c, --color : sortie colorée pour faciliter la lecture.

$ ip -br addr show
# -br, --brief : format compact sur une seule ligne par interface.
# ↦ lo       UNKNOWN  127.0.0.1/8 ::1/128
# ↦ eth0     UP       192.168.1.50/24 fe80::1/64

$ ip -j route show | jq .
# -j, --json : sortie JSON, idéale pour le traitement automatisé.

$ ip -o addr show
# -o, --oneline : une entrée par ligne, facilite le parsing avec awk/grep.
```

### ss

Les options de `ss` se combinent pour cibler précisément les connexions recherchées.

```bash
$ ss -t
# -t, --tcp : connexions TCP uniquement.

$ ss -u
# -u, --udp : connexions UDP uniquement.

$ ss -l
# -l, --listening : sockets en écoute uniquement.

$ ss -n
# -n, --numeric : ne résout pas les noms (ports et adresses numériques).
# Accélère considérablement l'affichage.

$ ss -p
# -p, --processes : affiche le processus associé à chaque socket.
# Nécessite les privilèges root pour voir tous les processus.

$ ss -tlnp
# Combinaison classique : TCP + listening + numeric + processes.
# C'est la commande de diagnostic réseau la plus fréquemment utilisée.
# ↦ State  Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
# ↦ LISTEN 0       511     0.0.0.0:80           0.0.0.0:*         users:(("nginx",pid=1234,...))

$ ss -s
# -s, --summary : résumé statistique (nombre de sockets par état).

$ ss -t state established
# Filtrage par état TCP : established, syn-sent, syn-recv,
# fin-wait-1, fin-wait-2, time-wait, close-wait, last-ack, closing, closed.

$ ss -t dst 10.0.0.1
# Filtrage par adresse de destination.

$ ss -t sport = :443
# Filtrage par port source.

$ ss -t dport = :5432
# Filtrage par port de destination.

$ ss -tlnp '( sport = :80 or sport = :443 )'
# Filtre combiné avec expression.
```

### tcpdump

Les filtres de `tcpdump` utilisent la syntaxe BPF (Berkeley Packet Filter).

```bash
# tcpdump -i eth0
# -i, --interface : spécifie l'interface de capture.
# -i any : capture sur toutes les interfaces.

# tcpdump -n
# -n : ne résout pas les noms d'hôtes.
# -nn : ne résout ni les noms d'hôtes, ni les noms de ports.

# tcpdump -c 100
# -c : arrête la capture après N paquets.

# tcpdump -v
# -v : sortie détaillée. -vv et -vvv augmentent le niveau de détail.

# tcpdump -w capture.pcap
# -w : écrit la capture dans un fichier (format pcap).
# Analysable ensuite avec Wireshark ou tcpdump -r.

# tcpdump -r capture.pcap
# -r : lit et affiche une capture existante.

# tcpdump -A
# -A : affiche le contenu des paquets en ASCII.
# Utile pour inspecter le trafic HTTP non chiffré.

# tcpdump -X
# -X : affiche en hexadécimal et ASCII simultanément.

# Exemples de filtres BPF :
# tcpdump -i eth0 host 192.168.1.100
# tcpdump -i eth0 src 192.168.1.100
# tcpdump -i eth0 dst 192.168.1.100
# tcpdump -i eth0 port 443
# tcpdump -i eth0 src port 5432
# tcpdump -i eth0 portrange 8000-8100
# tcpdump -i eth0 net 10.0.0.0/8

# Combinaison de filtres :
# tcpdump -i eth0 host 192.168.1.100 and port 443
# tcpdump -i eth0 '(port 80 or port 443) and host 10.0.0.1'
# tcpdump -i eth0 tcp and not port 22
# Les parenthèses doivent être protégées du shell avec des quotes.
```

### dig

L'outil `dig` est le plus complet pour le diagnostic DNS.

```bash
$ dig example.com
# Requête DNS standard (type A par défaut).

$ dig example.com AAAA
# Enregistrement IPv6.

$ dig example.com MX
# Enregistrements de messagerie.

$ dig example.com NS
# Serveurs de noms faisant autorité.

$ dig example.com ANY
# Tous les types d'enregistrements disponibles.

$ dig @8.8.8.8 example.com
# @ : interroge un serveur DNS spécifique au lieu du résolveur système.

$ dig +short example.com
# +short : réponse minimale (uniquement la valeur).
# ↦ 93.184.216.34

$ dig +trace example.com
# +trace : suit la chaîne de résolution depuis les serveurs racine.
# Indispensable pour diagnostiquer les problèmes de délégation.

$ dig +norecurse example.com
# +norecurse : requête non récursive.
# Teste si le serveur fait autorité pour la zone.

$ dig -x 93.184.216.34
# -x : reverse DNS (PTR lookup).

$ dig +dnssec example.com
# +dnssec : demande les enregistrements DNSSEC.

$ dig +tcp example.com
# +tcp : force l'utilisation de TCP au lieu d'UDP.

$ dig example.com +noall +answer
# +noall +answer : n'affiche que la section réponse (sans l'en-tête,
# la question et les sections additionnelles).
# Très utile pour un affichage épuré dans les scripts.
```

---

## 4. Gestion des fichiers et permissions

### chmod

Les permissions peuvent être spécifiées en notation symbolique ou octale.

```bash
# Notation symbolique
# chmod u+x script.sh              # Ajoute l'exécution pour le propriétaire
# chmod g-w fichier.txt             # Retire l'écriture pour le groupe
# chmod o= fichier.txt              # Supprime toutes les permissions pour others
# chmod a+r fichier.txt             # Ajoute la lecture pour tout le monde
# chmod u=rwx,g=rx,o= fichier.txt  # Définition complète

# u = user (propriétaire)
# g = group
# o = others
# a = all (u+g+o)
# + = ajouter, - = retirer, = = définir exactement

# Notation octale
# chmod 755 script.sh               # rwxr-xr-x
# chmod 644 fichier.txt             # rw-r--r--
# chmod 600 clé_privée              # rw-------
# chmod 750 répertoire/             # rwxr-x---
# chmod 700 .ssh/                   # rwx------

# Correspondance octale :
# 4 = lecture (r), 2 = écriture (w), 1 = exécution (x)
# Premier chiffre = user, deuxième = group, troisième = others

# Options
# chmod -R 755 répertoire/          # -R, --recursive : application récursive
# chmod --reference=source cible    # Copie les permissions d'un fichier source
# chmod -v 644 *.conf               # -v, --verbose : affiche chaque modification

# Bits spéciaux
# chmod u+s programme               # SetUID : exécution avec les droits du propriétaire
# chmod g+s répertoire/             # SetGID : les fichiers créés héritent du groupe
# chmod +t /tmp/                    # Sticky bit : seul le propriétaire peut supprimer
# chmod 4755 programme              # SetUID en octal (4xxx)
# chmod 2755 répertoire/            # SetGID en octal (2xxx)
# chmod 1777 /tmp/                  # Sticky en octal (1xxx)
```

### find

La commande `find` est l'un des outils les plus polyvalents du système. Ses critères se combinent librement.

```bash
$ find <chemin> [critères] [actions]

# Critères par nom
$ find /etc -name "*.conf"
# -name     : recherche par nom (sensible à la casse)
# -iname    : insensible à la casse
# Le motif utilise les caractères globbing du shell (*, ?, [])

# Critères par type
$ find /var -type f                    # f = fichier régulier
$ find /var -type d                    # d = répertoire
$ find /var -type l                    # l = lien symbolique

# Critères par taille
$ find /var/log -size +100M            # Fichiers de plus de 100 Mo
$ find /tmp -size -1k                  # Fichiers de moins de 1 Ko
# Unités : c (octets), k (Ko), M (Mo), G (Go)

# Critères par date
$ find /var/log -mtime -7              # Modifiés dans les 7 derniers jours
$ find /tmp -atime +30                 # Accédés il y a plus de 30 jours
$ find /etc -mmin -60                  # Modifiés dans les 60 dernières minutes
$ find /etc -newer /etc/reference      # Plus récents qu'un fichier de référence
# -mtime = date de modification, -atime = date d'accès, -ctime = date de changement

# Critères par permissions et propriété
$ find /home -user www-data
$ find /srv -group developers
$ find / -perm -4000 -type f           # Fichiers avec le bit SetUID
$ find / -perm /o+w -type f            # Fichiers accessibles en écriture par others
$ find /var -nouser                    # Fichiers sans propriétaire valide

# Combinaison de critères
$ find /var/log -name "*.log" -size +50M -mtime +30
# ET implicite entre les critères

$ find /etc \( -name "*.conf" -o -name "*.cfg" \)
# -o : OU logique. Les parenthèses groupent les conditions.

$ find /var -not -name "*.gz"
# -not ou ! : négation.

# Actions
$ find /tmp -type f -mtime +7 -delete
# -delete : supprime les fichiers trouvés. ATTENTION : irréversible.

$ find /etc -name "*.conf" -exec grep -l "listen" {} \;
# -exec : exécute une commande pour chaque résultat.
# {} est remplacé par le chemin du fichier. \; termine la commande.

$ find /var/log -name "*.log" -exec gzip {} +
# {} + : passe plusieurs fichiers à la fois à la commande (plus efficace).

$ find /home -type f -name "*.bak" -print0 | xargs -0 rm
# -print0 + xargs -0 : gère correctement les noms de fichiers
# contenant des espaces ou caractères spéciaux.

# Options de profondeur
$ find /var -maxdepth 2 -name "*.log"
# -maxdepth : limite la profondeur de recherche.
$ find /var -mindepth 1 -maxdepth 1 -type d
# Liste uniquement les sous-répertoires directs de /var.
```

### rsync

Les options de `rsync` déterminent le comportement précis de la synchronisation.

```bash
$ rsync [options] <source> <destination>

# Options fondamentales
$ rsync -a source/ destination/
# -a, --archive : mode archive.
# Équivaut à -rlptgoD (récursif, liens, permissions, timestamps,
# groupe, propriétaire, devices).
# C'est le point de départ de quasiment toute commande rsync.

$ rsync -av source/ destination/
# -v, --verbose : affiche les fichiers transférés.

$ rsync -avz source/ user@host:/backup/
# -z, --compress : compresse les données pendant le transfert.
# Utile uniquement sur les liens réseau lents.

$ rsync -avzh source/ destination/
# -h, --human-readable : tailles en Ko/Mo/Go au lieu d'octets.

# ATTENTION au slash final sur la source :
$ rsync -av source/ destination/
# source/  → copie le CONTENU de source dans destination
$ rsync -av source destination/
# source   → copie le RÉPERTOIRE source dans destination
# (crée destination/source/)

# Options de suppression
$ rsync -av --delete source/ destination/
# --delete : supprime dans la destination les fichiers absents de la source.
# Crée un miroir exact. À utiliser avec précaution.

$ rsync -av --delete-after source/ destination/
# Supprime après le transfert (par défaut, --delete supprime avant).

# Options d'exclusion
$ rsync -av --exclude='*.log' source/ destination/
# --exclude : exclut les fichiers correspondant au motif.

$ rsync -av --exclude-from=exclude.txt source/ destination/
# Liste d'exclusions dans un fichier (un motif par ligne).

$ rsync -av --include='*.conf' --exclude='*' source/ destination/
# Combinaison include/exclude : ne copie que les fichiers .conf.

# Options de sécurité et vérification
$ rsync -avn source/ destination/
# -n, --dry-run : simulation. Affiche ce qui serait fait sans rien modifier.
# TOUJOURS utiliser avant un rsync --delete sur des données importantes.

$ rsync -avc source/ destination/
# -c, --checksum : compare par somme de contrôle au lieu de la date
# et de la taille. Plus lent mais plus fiable.

$ rsync -av --backup --backup-dir=/backup/old source/ destination/
# --backup : conserve les fichiers écrasés dans un répertoire séparé.

# Options de transport
$ rsync -avz -e "ssh -p 2222 -i ~/.ssh/id_ed25519" source/ user@host:/dest/
# -e : spécifie la commande de transport (shell distant).

$ rsync -av --progress source/ destination/
# --progress : affiche la progression de chaque fichier.

$ rsync -av --partial --progress source/ destination/
# --partial : conserve les fichiers partiellement transférés.
# Permet de reprendre un transfert interrompu.
# Raccourci : -P équivaut à --partial --progress.

$ rsync -av --bwlimit=5000 source/ destination/
# --bwlimit : limite la bande passante en Ko/s.
```

---

## 5. Conteneurs — Docker

### docker run

La commande `docker run` combine la création et le démarrage d'un conteneur. Ses options sont très nombreuses et se classent en plusieurs familles.

```bash
# Mode d'exécution
$ docker run -d nginx
# -d, --detach : exécution en arrière-plan. Retourne l'ID du conteneur.

$ docker run -it ubuntu /bin/bash
# -i, --interactive : garde stdin ouvert.
# -t, --tty : alloue un pseudo-terminal.
# La combinaison -it est nécessaire pour une session shell interactive.

$ docker run --rm alpine echo "test"
# --rm : supprime automatiquement le conteneur à son arrêt.
# Indispensable pour les exécutions ponctuelles.

# Nommage et réseau
$ docker run -d --name mon-nginx -p 8080:80 nginx
# --name   : attribue un nom au conteneur (sinon nom aléatoire).
# -p, --publish : mappage de ports hôte:conteneur.

$ docker run -d -p 127.0.0.1:8080:80 nginx
# Bind sur localhost uniquement (n'expose pas sur le réseau).

$ docker run -d -P nginx
# -P, --publish-all : publie tous les ports EXPOSE sur des ports aléatoires.

$ docker run -d --network mon-reseau nginx
# --network : connecte le conteneur à un réseau Docker spécifique.

$ docker run -d --hostname app01 nginx
# --hostname : définit le hostname du conteneur.

# Volumes et montages
$ docker run -d -v mon-volume:/usr/share/nginx/html nginx
# -v, --volume : monte un volume nommé dans le conteneur.

$ docker run -d -v /host/path:/container/path nginx
# Bind mount : monte un répertoire de l'hôte dans le conteneur.

$ docker run -d -v /host/path:/container/path:ro nginx
# :ro : montage en lecture seule.

$ docker run -d --tmpfs /tmp:size=100m nginx
# --tmpfs : monte un système de fichiers temporaire en mémoire.

# Environnement et configuration
$ docker run -d -e MYSQL_ROOT_PASSWORD=secret mariadb
# -e, --env : définit une variable d'environnement.

$ docker run -d --env-file ./app.env nginx
# --env-file : charge les variables depuis un fichier.

$ docker run -d -w /app node npm start
# -w, --workdir : répertoire de travail dans le conteneur.

# Ressources
$ docker run -d --memory=512m --cpus=1.5 nginx
# --memory : limite la mémoire (suffixes : b, k, m, g).
# --cpus : nombre de CPUs alloués (décimal autorisé).

$ docker run -d --memory=512m --memory-swap=1g nginx
# --memory-swap : mémoire totale incluant le swap.

$ docker run -d --restart=unless-stopped nginx
# --restart : politique de redémarrage.
# Valeurs : no (défaut), on-failure[:max], always, unless-stopped.

# Sécurité
$ docker run -d --read-only nginx
# --read-only : système de fichiers racine en lecture seule.

$ docker run -d --user 1000:1000 nginx
# --user : UID:GID d'exécution.

$ docker run -d --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
# --cap-drop / --cap-add : gestion fine des capabilities Linux.

$ docker run -d --security-opt=no-new-privileges nginx
# Empêche l'élévation de privilèges dans le conteneur.
```

### docker build

```bash
$ docker build -t mon-image:1.0 .
# -t, --tag : nom et tag de l'image résultante.
# Le point final désigne le contexte de build (répertoire courant).

$ docker build -t mon-image:1.0 -f docker/Dockerfile.prod .
# -f, --file : chemin vers un Dockerfile non standard.

$ docker build --no-cache -t mon-image:1.0 .
# --no-cache : reconstruit toutes les couches sans utiliser le cache.

$ docker build --target builder -t mon-image:build .
# --target : arrête le build multi-stage à un stage spécifique.

$ docker build --build-arg VERSION=1.24 -t mon-image:1.0 .
# --build-arg : passe un argument de build (déclaré avec ARG dans le Dockerfile).

$ docker build --platform linux/amd64,linux/arm64 -t mon-image:1.0 .
# --platform : construction multi-architecture (nécessite buildx).
```

---

## 6. Kubernetes — kubectl

### Options globales

Certaines options sont applicables à presque toutes les sous-commandes de `kubectl`.

```bash
$ kubectl get pods -n kube-system
# -n, --namespace : spécifie le namespace. Sans cette option,
# kubectl utilise le namespace du contexte courant (souvent "default").

$ kubectl get pods --all-namespaces
# -A, --all-namespaces : tous les namespaces simultanément.

$ kubectl get pods -o wide
# -o, --output : format de sortie.
# wide     : colonnes supplémentaires (nœud, IP du pod...).
# yaml     : manifeste YAML complet.
# json     : manifeste JSON complet.
# name     : uniquement le type/nom (utile dans les scripts).
# jsonpath : extraction ciblée.
# custom-columns : colonnes personnalisées.

$ kubectl get pods -o jsonpath='{.items[*].metadata.name}'
# Extraction de champs spécifiques avec JSONPath.

$ kubectl get pods -o custom-columns=NOM:.metadata.name,STATUS:.status.phase,IP:.status.podIP
# Colonnes personnalisées pour un affichage sur mesure.

$ kubectl get pods -l app=nginx
# -l, --selector : filtre par label.
# Supporte les opérateurs : =, ==, !=, in, notin, exists.
# Exemples : -l 'app in (nginx,apache)' / -l 'env!=production'

$ kubectl get pods --field-selector=status.phase=Running
# --field-selector : filtre par champ de la ressource.

$ kubectl get pods --sort-by=.metadata.creationTimestamp
# --sort-by : tri par un champ spécifique.

$ kubectl get pods -w
# -w, --watch : suivi en temps réel des modifications.

$ kubectl --kubeconfig=/path/to/config get pods
# --kubeconfig : fichier de configuration du cluster.
# Alternative : variable d'environnement KUBECONFIG.

$ kubectl --context=production get pods
# --context : sélectionne un contexte spécifique sans changer le défaut.

$ kubectl get pods --v=6
# --v : niveau de verbosité (0 à 9). Utile pour le débogage :
# 6 = affiche les requêtes HTTP, 8 = affiche les corps de requête/réponse.
```

### kubectl apply vs create

```bash
$ kubectl apply -f deployment.yaml
# apply : mode déclaratif. Crée la ressource si elle n'existe pas,
# la met à jour si elle existe. Conserve l'historique des modifications
# dans l'annotation kubectl.kubernetes.io/last-applied-configuration.
# C'est la méthode recommandée pour la gestion déclarative.

$ kubectl apply -f manifests/
# Applique tous les fichiers YAML/JSON d'un répertoire.

$ kubectl apply -k overlays/production/
# -k : applique via Kustomize (lit le fichier kustomization.yaml).

$ kubectl apply -f deployment.yaml --dry-run=client -o yaml
# --dry-run=client : simule l'opération côté client.
# --dry-run=server : simule côté serveur (plus précis, valide l'admission).
# Combiné avec -o yaml, affiche le manifeste qui serait appliqué.

$ kubectl create deployment nginx --image=nginx:1.24 --replicas=3
# create : mode impératif. Échoue si la ressource existe déjà.
# Pratique pour les actions ponctuelles et l'exploration,
# mais déconseillé pour la gestion en production.

$ kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deploy.yaml
# Génération rapide d'un manifeste de base à personnaliser ensuite.
```

### kubectl logs

```bash
$ kubectl logs <pod>
# Logs du conteneur principal (ou unique) du pod.

$ kubectl logs <pod> -c <conteneur>
# -c, --container : cible un conteneur spécifique dans un pod multi-conteneurs.

$ kubectl logs <pod> --all-containers
# Logs de tous les conteneurs du pod.

$ kubectl logs -f <pod>
# -f, --follow : suivi en temps réel (tail -f).

$ kubectl logs --tail=100 <pod>
# --tail : nombre de lignes affichées depuis la fin.

$ kubectl logs --since=1h <pod>
# --since : durée relative (s, m, h).

$ kubectl logs --since-time="2026-04-12T08:00:00Z" <pod>
# --since-time : date absolue au format RFC3339.

$ kubectl logs --previous <pod>
# --previous : logs du conteneur précédent (après un redémarrage/crash).
# Indispensable pour diagnostiquer les CrashLoopBackOff.

$ kubectl logs -l app=nginx --all-containers
# -l : logs de tous les pods correspondant au sélecteur de labels.
# Combiné avec --all-containers pour une vision complète.

$ kubectl logs deployment/nginx
# Logs d'un pod quelconque du deployment (pratique mais non déterministe).

$ kubectl logs --prefix -l app=nginx
# --prefix : ajoute le nom du pod et du conteneur devant chaque ligne.
# Essentiel quand on consulte les logs de plusieurs pods à la fois.
```

---

## 7. Traitement de texte

### grep

```bash
$ grep "motif" fichier
# Recherche basique. Affiche les lignes contenant le motif.

$ grep -i "error" /var/log/syslog
# -i, --ignore-case : insensible à la casse.

$ grep -r "TODO" /home/user/project/
# -r, --recursive : recherche dans les sous-répertoires.
# -R : idem mais suit les liens symboliques.

$ grep -l "password" /etc/*.conf
# -l, --files-with-matches : affiche uniquement les noms de fichiers.

$ grep -L "password" /etc/*.conf
# -L, --files-without-match : fichiers ne contenant PAS le motif.

$ grep -n "error" application.log
# -n, --line-number : préfixe chaque ligne par son numéro.

$ grep -c "error" application.log
# -c, --count : nombre de lignes correspondantes.

$ grep -v "^#" /etc/nftables.conf
# -v, --invert-match : lignes ne correspondant PAS au motif.
# Très utilisé pour filtrer les commentaires et lignes vides :
# grep -v "^#" fichier | grep -v "^$"

$ grep -w "error" application.log
# -w, --word-regexp : le motif doit correspondre à un mot entier.
# "error" match, "errors" ne match pas.

$ grep -E "(error|warning|critical)" application.log
# -E, --extended-regexp : expressions régulières étendues (ERE).
# Équivalent de egrep.

$ grep -P "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" access.log
# -P, --perl-regexp : expressions régulières Perl (PCRE).
# Plus puissantes que ERE (lookahead, lookbehind, \d, \w...).

$ grep -A 3 "error" application.log
# -A num, --after-context : affiche N lignes après la correspondance.

$ grep -B 2 "error" application.log
# -B num, --before-context : affiche N lignes avant.

$ grep -C 5 "error" application.log
# -C num, --context : affiche N lignes avant ET après.

$ grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" access.log
# -o, --only-matching : affiche uniquement la partie correspondante,
# pas la ligne entière. Utile pour extraire des données.

$ grep --color=auto "error" application.log
# --color : met en surbrillance les correspondances.
# Souvent activé par défaut via un alias.

$ grep -q "error" application.log && echo "Erreurs trouvées"
# -q, --quiet : aucune sortie. Retourne uniquement le code de retour.
# 0 = trouvé, 1 = non trouvé. Idéal dans les scripts.
```

### awk

```bash
$ awk '{print $1}' fichier
# Affiche le premier champ de chaque ligne.
# Les champs sont séparés par des espaces/tabulations par défaut.

$ awk -F: '{print $1, $3}' /etc/passwd
# -F : spécifie le séparateur de champs.
# Ici le deux-points pour /etc/passwd.

$ awk '$3 > 1000 {print $1, $3}' /etc/passwd
# Condition avant l'action : n'affiche que les lignes où
# le troisième champ est supérieur à 1000.

$ awk '/error/ {print $0}' application.log
# /motif/ : filtre les lignes correspondant à l'expression régulière.

$ awk 'NR >= 10 && NR <= 20' fichier
# NR : numéro de la ligne courante. Affiche les lignes 10 à 20.

$ awk '{sum += $5} END {print "Total:", sum}' données.txt
# Bloc BEGIN{} : exécuté avant la lecture.
# Bloc END{} : exécuté après la dernière ligne.
# Variables accumulatrices pour les calculs agrégés.

$ awk 'BEGIN{OFS=","} {print $1, $2, $3}' fichier
# OFS : séparateur de champs en sortie.

$ awk '{count[$1]++} END {for (ip in count) print ip, count[ip]}' access.log | sort -rnk2
# Tableaux associatifs : comptage d'occurrences par clé.
# Ici, nombre de requêtes par adresse IP.

$ ss -tlnp | awk '/LISTEN/ {print $4, $6}'
# Combinaison avec d'autres commandes via pipe.
# Extrait l'adresse d'écoute et le processus.
```

### sed

```bash
$ sed 's/ancien/nouveau/' fichier
# Substitution de la première occurrence par ligne.

$ sed 's/ancien/nouveau/g' fichier
# g : substitution de toutes les occurrences par ligne.

$ sed -i 's/ancien/nouveau/g' fichier
# -i, --in-place : modification directe du fichier.
# -i.bak : crée une sauvegarde avant modification.

$ sed -n '10,20p' fichier
# -n : supprime l'affichage par défaut.
# p : affiche uniquement les lignes sélectionnées (10 à 20).

$ sed '/^#/d' fichier
# d : supprime les lignes correspondant au motif.
# Ici, les lignes commençant par #.

$ sed '/^$/d' fichier
# Supprime les lignes vides.

$ sed -e 's/foo/bar/g' -e 's/baz/qux/g' fichier
# -e : enchaîne plusieurs commandes sed.

$ sed '5i\Nouvelle ligne' fichier
# i\ : insère une ligne AVANT la ligne spécifiée.

$ sed '5a\Nouvelle ligne' fichier
# a\ : insère une ligne APRÈS la ligne spécifiée.

$ sed -E 's/([0-9]+)\.([0-9]+)/\2.\1/g' fichier
# -E : expressions régulières étendues.
# \1, \2 : références aux groupes de capture.
```

### jq

```bash
$ jq '.' fichier.json
# Formatage et coloration JSON (identity filter).

$ jq '.key' fichier.json
# Extraction d'une clé de premier niveau.

$ jq '.parent.child' fichier.json
# Navigation dans les objets imbriqués.

$ jq '.items[0]' fichier.json
# Accès par index dans un tableau.

$ jq '.items[]' fichier.json
# Itération sur tous les éléments d'un tableau.

$ jq '.items[] | .name' fichier.json
# Pipe interne : extraction d'un champ de chaque élément.

$ jq '.items[] | select(.status == "active")' fichier.json
# select() : filtrage conditionnel.

$ jq '.items | length' fichier.json
# length : nombre d'éléments dans un tableau.

$ jq -r '.name' fichier.json
# -r, --raw-output : sortie sans guillemets.
# Indispensable quand la valeur est utilisée dans un script shell.

$ jq -c '.' fichier.json
# -c, --compact-output : sortie sur une seule ligne.

$ jq --arg nom "valeur" '.items[] | select(.name == $nom)' fichier.json
# --arg : injection d'une variable shell dans l'expression jq.

$ kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'
# Construction d'objets personnalisés à partir de données complexes.
```

---

## 8. Infrastructure as Code

### ansible-playbook

```bash
$ ansible-playbook playbook.yaml -i inventaire.ini
# -i, --inventory : fichier ou répertoire d'inventaire.

$ ansible-playbook playbook.yaml --check
# --check, -C : mode simulation (dry-run). Aucune modification appliquée.

$ ansible-playbook playbook.yaml --diff
# --diff, -D : affiche les différences pour les fichiers modifiés.
# Souvent combiné avec --check : --check --diff

$ ansible-playbook playbook.yaml --limit web01
# --limit, -l : restreint l'exécution à un sous-ensemble d'hôtes.
# Accepte les motifs : --limit 'web*' ou --limit '!db01'

$ ansible-playbook playbook.yaml --tags deploy
# --tags, -t : exécute uniquement les tâches ayant ce tag.

$ ansible-playbook playbook.yaml --skip-tags tests
# --skip-tags : exclut les tâches ayant ce tag.

$ ansible-playbook playbook.yaml -e "version=1.5 env=production"
# -e, --extra-vars : variables supplémentaires (priorité maximale).
# Accepte aussi un fichier : -e @vars.yaml

$ ansible-playbook playbook.yaml --ask-vault-pass
# --ask-vault-pass : demande le mot de passe de déchiffrement.
# --vault-password-file : lit le mot de passe depuis un fichier.

$ ansible-playbook playbook.yaml -v
# -v : verbosité. Jusqu'à -vvvv pour le débogage maximal.
# -v    : résultat des tâches
# -vv   : entrées des tâches
# -vvv  : détails des connexions
# -vvvv : scripts de connexion complets

$ ansible-playbook playbook.yaml --step
# --step : confirmation interactive avant chaque tâche.

$ ansible-playbook playbook.yaml --start-at-task="Deploy application"
# --start-at-task : reprend l'exécution à partir d'une tâche donnée.

$ ansible-playbook playbook.yaml --list-tasks
# --list-tasks : affiche la liste des tâches sans les exécuter.

$ ansible-playbook playbook.yaml --list-hosts
# --list-hosts : affiche les hôtes ciblés sans exécuter le playbook.

$ ansible-playbook playbook.yaml --forks=20
# --forks, -f : nombre d'hôtes traités en parallèle (défaut : 5).
```

### terraform

> **Note OpenTofu** — Toutes les options ci-dessous fonctionnent à l'identique avec la CLI `tofu` (version stable courante en mai 2026 : **OpenTofu 1.11.6**, sortie le 8 avril 2026 ; fork open source MPL 2.0 maintenu par la Linux Foundation depuis le passage de Terraform sous BSL en août 2023). OpenTofu est un drop-in replacement de Terraform 1.5.x. La politique de support OpenTofu (alignée sur Terraform) couvre les trois dernières releases majeures (1.9, 1.10, 1.11 actuellement).

```bash
$ terraform init
# Initialise le répertoire de travail : télécharge les providers,
# les modules et configure le backend. À relancer après toute
# modification du bloc terraform{} ou des sources de modules.

$ terraform init -upgrade
# -upgrade : met à jour les providers vers la dernière version compatible.

$ terraform init -backend-config="key=value"
# Configuration partielle du backend (clés sensibles).

$ terraform plan
# Affiche les changements prévus sans les appliquer.

$ terraform plan -out=plan.tfplan
# -out : enregistre le plan dans un fichier.
# Garantit que l'apply exécutera exactement ce qui a été planifié.

$ terraform plan -target=module.web
# -target : limite le plan à une ressource ou un module spécifique.
# Usage exceptionnel : peut créer des incohérences.

$ terraform plan -var="instance_type=t3.large"
# -var : surcharge une variable.

$ terraform plan -var-file="production.tfvars"
# -var-file : fichier de variables.
# Les fichiers *.auto.tfvars sont chargés automatiquement.

$ terraform apply plan.tfplan
# Applique un plan préalablement enregistré.

$ terraform apply -auto-approve
# -auto-approve : supprime la confirmation interactive.
# Utilisé dans les pipelines CI/CD.

$ terraform destroy
# Supprime toutes les ressources gérées.

$ terraform destroy -target=aws_instance.web
# Supprime une ressource spécifique.

$ terraform state list
# Liste toutes les ressources dans l'état.

$ terraform state show aws_instance.web
# Détails d'une ressource dans l'état.

$ terraform state mv aws_instance.old aws_instance.new
# Renomme une ressource dans l'état (après refactoring du code).

$ terraform state rm aws_instance.web
# Retire une ressource de l'état sans la supprimer réellement.
# La ressource devient "non gérée" par Terraform.

$ terraform import aws_instance.web i-1234567890abcdef0
# Importe une ressource existante dans l'état Terraform.

$ terraform output
# Affiche toutes les valeurs de sortie.

$ terraform output -json
# Sortie JSON, utilisable dans les scripts et les pipelines.

$ terraform fmt -recursive
# Formate tous les fichiers .tf récursivement.

$ terraform validate
# Vérifie la syntaxe et la cohérence interne (sans contacter les APIs).

$ terraform workspace list
$ terraform workspace new staging
$ terraform workspace select staging
# Gestion des workspaces pour les environnements multiples.

$ terraform graph | dot -Tpng > graph.png
# Génère un graphe des dépendances au format DOT.

$ terraform console
# Console interactive pour tester des expressions HCL.
```

---

## 9. Helm

> **Note 2026 sur Bitnami** — Le catalogue communautaire Bitnami (`docker.io/bitnami`, `https://charts.bitnami.com/bitnami`) a été déprécié par Broadcom le 28 août 2025 puis la plupart des images supprimées le 29 septembre 2025. Les charts existants restent accessibles en mode legacy mais ne reçoivent plus de mises à jour ni de correctifs de sécurité (`docker.io/bitnamilegacy/`). Pour de nouveaux déploiements, préférer les **charts upstream officiels** (ingress-nginx, cert-manager, prometheus-community, grafana, postgres-operator, etc.) ou des distributions comme **Chainguard Charts** (forks durcis Apache 2.0). Les exemples ci-dessous restent illustratifs syntaxiquement — adapter le dépôt et le nom du chart au catalogue retenu.

```bash
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# Exemple avec un dépôt upstream officiel.
# Ancienne forme historique avec Bitnami :
# $ helm repo add bitnami https://charts.bitnami.com/bitnami

$ helm repo update
# Met à jour l'index de tous les dépôts configurés.

$ helm search repo nginx
# Recherche dans les dépôts locaux.

$ helm search hub nginx
# Recherche sur Artifact Hub (dépôts publics).

$ helm install mon-nginx bitnami/nginx -n web
# Installe un chart. Format : helm install <release> <chart> [-n namespace]

$ helm install mon-nginx bitnami/nginx -f custom-values.yaml
# -f, --values : fichier de valeurs personnalisées.
# Plusieurs fichiers possibles : -f base.yaml -f production.yaml
# Les fichiers suivants écrasent les valeurs des précédents.

$ helm install mon-nginx bitnami/nginx --set replicaCount=3
# --set : surcharge une valeur spécifique en ligne de commande.
# --set-string : force l'interprétation comme chaîne de caractères.

$ helm install mon-nginx bitnami/nginx --version 15.1.0
# --version : installe une version spécifique du chart.

$ helm install mon-nginx bitnami/nginx --dry-run --debug
# --dry-run : simule l'installation et affiche les manifestes générés.
# --debug : ajoute des informations de débogage.

$ helm install mon-nginx bitnami/nginx --wait --timeout 5m
# --wait : attend que toutes les ressources soient prêtes.
# --timeout : durée maximale d'attente.

$ helm upgrade mon-nginx bitnami/nginx -f custom-values.yaml
# Met à jour une release avec de nouvelles valeurs ou version.

$ helm upgrade --install mon-nginx bitnami/nginx -f values.yaml
# --install : installe si la release n'existe pas (idempotent).
# C'est la forme recommandée dans les pipelines CI/CD.

$ helm rollback mon-nginx 2
# Retour à la révision 2 de la release.

$ helm history mon-nginx
# Historique des révisions de la release.

$ helm list -n web
# Liste les releases dans un namespace.

$ helm list --all-namespaces
# Liste toutes les releases du cluster.

$ helm uninstall mon-nginx -n web
# Supprime la release et toutes ses ressources Kubernetes.

$ helm template mon-nginx bitnami/nginx -f values.yaml
# Rend les manifestes localement sans communication avec le cluster.
# Utile pour la revue de code et le débogage.

$ helm show values bitnami/nginx
# Affiche toutes les valeurs par défaut du chart.

$ helm show chart bitnami/nginx
# Métadonnées du chart (version, description, dépendances).

$ helm get values mon-nginx -n web
# Valeurs actuellement appliquées à une release.

$ helm get manifest mon-nginx -n web
# Manifestes YAML déployés par une release.

$ helm dependency update ./mon-chart
# Télécharge les dépendances déclarées dans Chart.yaml.

$ helm package ./mon-chart
# Crée une archive .tgz du chart pour publication.

$ helm lint ./mon-chart
# Vérifie la structure et la syntaxe du chart.
```

---

## Synthèse des options les plus utilisées

Quelques combinaisons d'options à retenir en priorité, classées par fréquence d'utilisation dans le travail quotidien.

| Commande | Combinaison clé | Usage |
|----------|-----------------|-------|
| `journalctl` | `-u <service> -f` | Suivi temps réel d'un service |
| `journalctl` | `-p err -b` | Erreurs du démarrage courant |
| `apt` | `install --no-install-recommends -y` | Installation minimale en script |
| `ss` | `-tlnp` | Ports TCP en écoute avec processus |
| `ip` | `-br -c addr` | Vue compacte colorée des interfaces |
| `rsync` | `-avz --delete -n` | Simulation de miroir distant |
| `find` | `-type f -name "*.log" -mtime +30 -delete` | Nettoyage de vieux logs |
| `grep` | `-rn --color` | Recherche récursive avec contexte |
| `docker run` | `-d --name -p --restart` | Conteneur de production |
| `kubectl get` | `-o wide -n <ns>` | Vue étendue dans un namespace |
| `kubectl logs` | `-f --tail=100 --prefix -l app=X` | Suivi multi-pods |
| `kubectl apply` | `--dry-run=server -o yaml` | Validation avant déploiement |
| `ansible-playbook` | `--check --diff -l <hôte>` | Simulation ciblée |
| `terraform` | `plan -out=plan.tfplan` | Plan enregistré pour apply sûr |
| `helm` | `upgrade --install -f values.yaml --wait` | Déploiement CI/CD idempotent |

⏭️ [Cheat sheets par technologie (Debian, Docker, K8s, Terraform, Ansible)](/annexes/A.3-cheat-sheets.md)
