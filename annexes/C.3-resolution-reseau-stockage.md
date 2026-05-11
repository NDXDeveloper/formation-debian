🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe C.3 — Résolution réseau et stockage

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Ce guide traite des problèmes **transversaux** de réseau et de stockage qui traversent plusieurs couches de l'infrastructure. Là où C.1 couvre le système Debian et C.2 les composants Kubernetes, cette section aborde les problématiques qui ne se limitent pas à un seul composant : un problème DNS peut affecter à la fois le système hôte, les conteneurs et les pods Kubernetes ; une panne de stockage peut impacter simultanément les bases de données, les volumes Docker et les PersistentVolumes.

Le guide suit une approche par couche, du plus bas niveau (physique) au plus haut (applicatif).

---

## Partie 1 — Diagnostic réseau

### 1.1 Méthodologie de diagnostic réseau par couche

Face à un problème réseau, la tentation est de tester immédiatement la connectivité applicative (`curl`, accès web). Cette approche est inefficace car elle ne permet pas de distinguer un problème de routage d'un problème DNS, un problème de pare-feu d'un problème TLS. La méthode recommandée est de remonter les couches du modèle réseau de bas en haut, en validant chaque couche avant de passer à la suivante.

**Couche 1-2 — Lien physique et liaison** :

```bash
# L'interface est-elle physiquement connectée ?
ip link show
# Vérifier que l'état est UP et que "state UP" est affiché.
# "NO-CARRIER" indique un câble débranché ou un lien défaillant.

ethtool <interface>                      # Détails du lien physique
# Link detected: yes/no
# Speed: 1000Mb/s
# Duplex: Full

# Statistiques d'interface (erreurs, collisions, drops)
ip -s link show <interface>
# Des compteurs TX/RX errors ou drops élevés indiquent
# un problème matériel ou de configuration du lien.

# Pour les VLAN
ip -d link show | grep vlan

# Pour les bonds (agrégation de liens)
cat /proc/net/bonding/bond0              # État de chaque interface esclave
```

**Couche 3 — Réseau (IP et routage)** :

```bash
# Adresse IP assignée ?
ip -4 addr show <interface>  
ip -6 addr show <interface>  

# Route par défaut présente ?
ip route show  
ip -6 route show  

# La passerelle est-elle joignable ?
ping -c 3 <passerelle>

# Le routage vers la destination est-il correct ?
ip route get <ip_destination>
# Affiche l'interface de sortie et la passerelle utilisées.

# Tracer le chemin réseau
traceroute -n <destination>              # UDP par défaut  
traceroute -T -p <port> <destination>    # TCP (passe mieux les pare-feu)  
mtr -n --report <destination>            # Rapport combiné ping+traceroute  

# Vérifier les tables ARP/voisinage
ip neigh show
# Des entrées en état FAILED indiquent un problème de résolution L2.
```

**Couche 4 — Transport (TCP/UDP)** :

```bash
# Le port est-il ouvert localement ?
ss -tlnp | grep <port>                  # TCP  
ss -ulnp | grep <port>                  # UDP  

# Le port est-il joignable depuis l'extérieur ?
nc -zv <hôte> <port>                    # Test TCP  
nc -zuv <hôte> <port>                   # Test UDP  

# Analyse du trafic
tcpdump -i <interface> -nn port <port>
# Observer :
# - Des SYN sans SYN-ACK → le serveur ne répond pas ou un pare-feu bloque
# - Des RST → le port est fermé ou le serveur refuse la connexion
# - Des retransmissions → perte de paquets ou congestion

# Nombre de connexions par état
ss -s  
ss -t state established | wc -l  
ss -t state time-wait | wc -l  
# Un nombre élevé de TIME_WAIT peut indiquer un problème
# de réutilisation de ports ou un proxy mal configuré.
```

**Couche 7 — Application** :

```bash
# Test HTTP complet
curl -v http://<hôte>:<port>/  
curl -vk https://<hôte>:<port>/          # -k pour ignorer les erreurs TLS  

# Test avec résolution DNS explicite
curl --resolve <domaine>:<port>:<ip> https://<domaine>/

# Test avec en-têtes spécifiques (utile pour les virtual hosts)
curl -H "Host: app.example.com" http://<ip>/

# Mesurer les temps de réponse
curl -w "\nDNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n" \
     -o /dev/null -s https://<url>
```

### 1.2 Problèmes DNS

#### La résolution DNS ne fonctionne plus

**Symptômes** — Les connexions par nom échouent (« Could not resolve host ») mais les connexions par IP fonctionnent.

**Diagnostic séquentiel** :

```bash
# 1. Quel résolveur est configuré ?
cat /etc/resolv.conf
# Attention : ce fichier est souvent un lien symbolique.
ls -la /etc/resolv.conf
# Géré par systemd-resolved → pointe vers /run/systemd/resolve/stub-resolv.conf
# Géré par NetworkManager → pointe vers /run/NetworkManager/resolv.conf
# Géré manuellement → fichier réel

# 2. Le résolveur local répond-il ?
dig @127.0.0.53 google.com              # systemd-resolved  
dig @127.0.0.1 google.com               # Résolveur local (BIND, Unbound)  

# 3. Un résolveur externe répond-il ?
dig @8.8.8.8 google.com  
dig @1.1.1.1 google.com  

# 4. Si systemd-resolved est utilisé
resolvectl status  
resolvectl query google.com  
resolvectl statistics                    # Compteurs de cache et de requêtes  

# 5. Si le résolveur local est BIND9
rndc status  
named-checkconf  
journalctl -u named --since "10 minutes ago"  
```

**Cas particuliers** :

**Résolution lente (délai de plusieurs secondes)** — Souvent causée par une tentative de résolution IPv6 (AAAA) qui échoue avant de retomber sur IPv4. Vérifier `/etc/gai.conf` et s'assurer que la ligne `precedence ::ffff:0:0/96 100` est décommentée pour privilégier IPv4 si IPv6 n'est pas disponible.

**Résolution incohérente entre les machines** — Un serveur DNS cache des enregistrements obsolètes. Vérifier le TTL et forcer un flush du cache.

```bash
# Flush du cache systemd-resolved
resolvectl flush-caches

# Flush du cache BIND9
rndc flush

# Vérifier le TTL d'un enregistrement
dig +nocmd +noall +answer +ttlid <domaine>
```

**Résolution qui fonctionne avec dig mais pas avec les applications** — L'ordre de résolution dans `/etc/nsswitch.conf` (ligne `hosts:`) peut être incorrect. Si `files` est avant `dns`, une entrée obsolète dans `/etc/hosts` peut prendre le dessus.

#### Serveur DNS BIND9 qui ne résout pas les requêtes

**Symptômes** — BIND9 est actif mais les clients reçoivent des réponses SERVFAIL ou REFUSED.

**Diagnostic** :

```bash
# Vérifier la configuration
named-checkconf  
named-checkzone <domaine> /etc/bind/db.<domaine>  

# Logs détaillés
journalctl -u named --since "5 minutes ago"  
rndc status  

# Tester une requête directement vers BIND
dig @localhost <domaine>

# Vérifier les ACL et allow-query
grep -E "allow-query|allow-recursion" /etc/bind/named.conf.options
```

**Causes courantes** — BIND refuse les requêtes récursives des clients non autorisés (ACL `allow-recursion`). Le forwarder configuré est inaccessible. Les fichiers de zone contiennent des erreurs de syntaxe (point final manquant sur un FQDN, numéro de série non incrémenté).

### 1.3 Problèmes TLS/SSL

#### Certificat expiré ou invalide

**Symptômes** — Les navigateurs ou clients affichent des erreurs « certificate has expired », « certificate is not yet valid » ou « unable to verify the first certificate ».

**Diagnostic** :

```bash
# Vérifier le certificat exposé par un serveur
openssl s_client -connect <hôte>:<port> -servername <domaine> </dev/null 2>/dev/null | \
    openssl x509 -noout -dates -subject -issuer

# Détails complets
echo | openssl s_client -connect <hôte>:<port> -servername <domaine> 2>/dev/null

# Vérifier la chaîne de certificats complète
echo | openssl s_client -connect <hôte>:<port> -servername <domaine> -showcerts 2>/dev/null

# Vérifier un fichier de certificat local
openssl x509 -in /etc/letsencrypt/live/<domaine>/fullchain.pem -noout -dates -subject

# Vérifier que la clé correspond au certificat
openssl x509 -noout -modulus -in cert.pem | openssl md5  
openssl rsa -noout -modulus -in key.pem | openssl md5  
# Les deux empreintes doivent être identiques.

# Vérifier les certificats Let's Encrypt
certbot certificates
```

**Résolutions** :

**Certificat expiré** — Renouveler immédiatement.

```bash
# Let's Encrypt
certbot renew
# Si le renouvellement échoue :
certbot renew --dry-run                  # Diagnostiquer  
certbot certonly --standalone -d <domaine>  # Renouvellement manuel  
systemctl reload nginx                   # Recharger après renouvellement  
```

**Chaîne de certificats incomplète** — Le serveur n'envoie pas les certificats intermédiaires. Le fichier utilisé doit être le `fullchain.pem` (certificat + intermédiaires) et non le `cert.pem` (certificat seul).

**Erreur de nom de domaine (CN/SAN mismatch)** — Le certificat ne couvre pas le domaine demandé. Vérifier les champs Subject et Subject Alternative Names.

```bash
openssl x509 -in cert.pem -noout -text | grep -A 1 "Subject Alternative Name"
```

**Renouvellement automatique défaillant** — Vérifier que le timer certbot est actif et que le hook de rechargement du serveur web est configuré.

```bash
systemctl list-timers | grep certbot  
cat /etc/letsencrypt/renewal/<domaine>.conf | grep -E "(deploy|renew)_hook"  
```

#### Négociation TLS qui échoue

**Symptômes** — « SSL: TLSV1_ALERT_PROTOCOL_VERSION », « no protocols available » ou « handshake failure ».

**Diagnostic** :

```bash
# Tester un protocole spécifique
openssl s_client -connect <hôte>:443 -tls1_2  
openssl s_client -connect <hôte>:443 -tls1_3  

# Lister les ciphers supportés par le serveur
nmap --script ssl-enum-ciphers -p 443 <hôte>
```

**Cause** — Le client et le serveur n'ont pas de protocole TLS ou de cipher suite en commun. Souvent causé par la désactivation de TLSv1.0/1.1 côté serveur alors que le client est ancien, ou par une configuration trop restrictive des cipher suites.

### 1.4 Problèmes de pare-feu

#### Trafic bloqué de manière inattendue

**Symptômes** — Un service écoute sur le bon port (`ss -tlnp` le confirme) mais les connexions externes échouent. `tcpdump` montre les paquets SYN entrants mais aucun SYN-ACK en retour.

**Diagnostic** :

```bash
# Afficher toutes les règles de filtrage
nft list ruleset
# ou
iptables -L -n -v                        # Si iptables est utilisé  
ufw status verbose  

# Vérifier les compteurs des règles de drop/reject
nft list ruleset | grep -E "(drop|reject)"  
iptables -L -n -v | grep -E "(DROP|REJECT)"  

# Tracer les paquets bloqués (nftables)
# Ajouter temporairement une règle de log :
nft add rule inet filter input tcp dport <port> log prefix \"debug: \" counter  
journalctl -k | grep "debug:"  

# Vérifier le suivi de connexions (conntrack)
conntrack -L | grep <ip>  
conntrack -C                             # Nombre d'entrées (vérifier la saturation)  
cat /proc/sys/net/netfilter/nf_conntrack_max  
cat /proc/sys/net/netfilter/nf_conntrack_count  
# Si count ≈ max, la table conntrack est saturée et de nouvelles connexions
# sont silencieusement rejetées.
```

**Causes courantes** :

**Politique par défaut DROP sans règle pour le trafic établi** — La règle `ct state established,related accept` est manquante, ce qui bloque les réponses aux connexions sortantes.

**Table conntrack saturée** — Sur les serveurs à fort trafic, la table conntrack peut se remplir. Les nouvelles connexions sont alors silencieusement rejetées. Augmenter `nf_conntrack_max` dans `/etc/sysctl.d/`.

```bash
# Augmenter temporairement
sysctl -w net.netfilter.nf_conntrack_max=262144

# Persister
echo "net.netfilter.nf_conntrack_max = 262144" > /etc/sysctl.d/50-conntrack.conf
```

**Règles UFW ou nftables en conflit avec Docker** — Docker manipule directement iptables/nftables pour le NAT des conteneurs. Les règles UFW peuvent être contournées par les règles Docker insérées dans la chaîne FORWARD.

```bash
# Vérifier les chaînes Docker
iptables -L DOCKER -n -v  
iptables -L DOCKER-USER -n -v  
# Les règles de restriction doivent être placées dans DOCKER-USER
# pour ne pas être écrasées par Docker au redémarrage.
```

#### NAT et port forwarding qui ne fonctionnent pas

**Symptômes** — Le port forwarding configuré ne redirige pas le trafic. Les connexions sont rejetées ou ne reçoivent pas de réponse.

**Diagnostic** :

```bash
# Vérifier que le forwarding IP est activé
sysctl net.ipv4.ip_forward
# Doit retourner 1.

# Vérifier les règles NAT
nft list table nat
# ou
iptables -t nat -L -n -v

# Tracer le trafic à chaque étape
tcpdump -i <interface_externe> port <port>  
tcpdump -i <interface_interne> port <port>  
# Observer si les paquets arrivent sur l'interface externe
# et s'ils sont retransmis sur l'interface interne.
```

### 1.5 Réseau des conteneurs

#### Conteneur Docker sans connectivité externe

**Symptômes** — Un conteneur ne peut pas joindre Internet ou les services externes. `docker exec <c> ping 8.8.8.8` échoue.

**Diagnostic** :

```bash
# Vérifier le réseau du conteneur
docker inspect <conteneur> | jq '.[0].NetworkSettings'

# Vérifier les réseaux Docker
docker network ls  
docker network inspect <réseau>  

# Vérifier le forwarding IP
sysctl net.ipv4.ip_forward

# Vérifier les règles NAT de Docker
iptables -t nat -L POSTROUTING -n -v
# Une règle MASQUERADE pour le sous-réseau Docker doit exister.

# Vérifier le DNS dans le conteneur
docker exec <conteneur> cat /etc/resolv.conf  
docker exec <conteneur> nslookup google.com  
```

**Causes courantes** — Le forwarding IP est désactivé. Les règles iptables de Docker ont été supprimées par un rechargement du pare-feu (`systemctl restart nftables` efface les règles Docker). Le daemon Docker a été démarré avec `--iptables=false`. Le réseau Docker bridge a un conflit d'adressage avec le réseau hôte.

```bash
# Conflit d'adressage
ip route show  
docker network inspect bridge | jq '.[0].IPAM.Config'  
# Si le sous-réseau Docker (172.17.0.0/16 par défaut) chevauche
# un réseau de l'infrastructure, les paquets sont mal routés.
# Reconfigurer dans /etc/docker/daemon.json avec "default-address-pools".
```

#### Communication inter-conteneurs impossible

**Symptômes** — Deux conteneurs sur le même réseau Docker ne peuvent pas communiquer par nom.

**Diagnostic** :

```bash
# Les conteneurs sont-ils sur le même réseau ?
docker inspect <c1> | jq '.[0].NetworkSettings.Networks'  
docker inspect <c2> | jq '.[0].NetworkSettings.Networks'  

# Le réseau par défaut "bridge" ne fournit PAS de résolution DNS
# entre conteneurs. Seuls les réseaux personnalisés (user-defined)
# offrent cette fonctionnalité.

# Tester par IP
docker exec <c1> ping <ip_c2>

# Tester par nom (uniquement sur un réseau personnalisé)
docker exec <c1> ping <nom_c2>
```

**Résolution** — Créer un réseau personnalisé et y connecter les deux conteneurs. Le réseau `bridge` par défaut ne fournit pas de résolution DNS par nom de conteneur.

```bash
docker network create app-net  
docker network connect app-net <c1>  
docker network connect app-net <c2>  
```

### 1.6 Performances réseau

#### Latence élevée ou perte de paquets

**Symptômes** — Les temps de réponse sont anormalement élevés. Des timeouts intermittents se produisent.

**Diagnostic** :

```bash
# Mesurer la latence et la perte de paquets
ping -c 100 <destination>
# Observer : temps min/avg/max et pourcentage de perte.

# Analyse détaillée du chemin
mtr -n --report-cycles 100 <destination>
# Identifier le saut où la latence augmente brutalement
# ou où des pertes apparaissent.

# Bande passante disponible
iperf3 -c <serveur>                      # Test TCP  
iperf3 -c <serveur> -u -b 100M          # Test UDP à 100 Mbps  

# Saturation des interfaces réseau
ip -s link show <interface>
# Comparer TX/RX bytes sur deux mesures espacées.
sar -n DEV 1 10                          # Si sysstat est installé

# Saturation du buffer réseau
cat /proc/net/softnet_stat
# Troisième colonne : drops en softirq. Des valeurs non nulles
# indiquent une saturation du traitement réseau.
ss -m                                    # Tailles des buffers par socket
```

**Causes courantes** — Un lien réseau saturé (vérifier la bande passante avec `iperf3`). Des buffers réseau sous-dimensionnés (`net.core.rmem_max`, `net.core.wmem_max`). Un problème de duplex mismatch (vérifié avec `ethtool`). Une saturation du suivi de connexions conntrack. Sur les machines virtuelles, un pilote réseau non-virtio provoquant une surcharge.

#### MTU incorrect provoquant des erreurs silencieuses

**Symptômes** — Les petits paquets passent (ping fonctionne) mais les transferts volumineux échouent ou sont très lents. Les connexions TLS échouent. Les téléchargements s'interrompent.

**Diagnostic** :

```bash
# Tester la taille maximale de paquet
ping -c 3 -M do -s 1472 <destination>    # MTU 1500 standard (1472 + 28 headers)  
ping -c 3 -M do -s 1400 <destination>    # Réduire si le précédent échoue  
# Le flag -M do interdit la fragmentation.
# Si le ping échoue à 1472 mais fonctionne à 1400,
# le MTU du chemin est inférieur à 1500.

# Vérifier le MTU configuré
ip link show <interface> | grep mtu

# MTU communs :
# 1500 : Ethernet standard
# 1450 : VXLAN (overlay réseau, fréquent en Docker/Kubernetes)
# 1400 : WireGuard, certains VPN
# 9000 : Jumbo frames (réseau local haute performance)
```

**Résolution** — Ajuster le MTU de l'interface pour correspondre au chemin réseau. En environnement overlay (Docker, Kubernetes avec Flannel/Calico en mode VXLAN), le MTU des conteneurs doit être inférieur au MTU de l'hôte pour laisser la place aux en-têtes d'encapsulation. Configurer le MTU dans le daemon Docker (`/etc/docker/daemon.json` avec `"mtu": 1450`) ou dans la configuration du CNI Kubernetes.

---

## Partie 2 — Diagnostic stockage

### 2.1 Systèmes de fichiers

#### Système de fichiers corrompu

**Symptômes** — Erreurs « Input/output error » lors de l'accès aux fichiers. Messages « EXT4-fs error » ou « XFS: Internal error » dans `dmesg`. Le système de fichiers est remonté en lecture seule automatiquement.

**Diagnostic** :

```bash
# Messages du noyau
dmesg | grep -iE "(ext4|xfs|btrfs|error|corrupt|readonly)"

# État du montage
mount | grep <point_de_montage>
# "ro" dans les options indique un remontage en lecture seule.

# Forcer une vérification (le FS doit être démonté)
umount <point_de_montage>

# ext4
e2fsck -f /dev/<partition>
# -f : force la vérification même si le FS semble propre
# -y : répond oui à toutes les questions (pour les scripts)

# XFS
xfs_repair /dev/<partition>
# -n : mode lecture seule (diagnostic sans modification)

# Btrfs
btrfs check /dev/<partition>
# btrfs scrub start <point_de_montage>   # Vérification en ligne (FS monté)
```

**Prévention** — Activer les vérifications périodiques du système de fichiers. Pour ext4, `tune2fs -c 30 /dev/<partition>` déclenche un fsck tous les 30 montages. Surveiller les erreurs SMART des disques (voir C.1 section 7.1) car la corruption du système de fichiers est souvent un symptôme de défaillance matérielle.

#### Système de fichiers plein — Cas avancés

Au-delà du nettoyage basique (couvert en C.1), certains cas de saturation nécessitent une approche spécifique.

**Fichiers supprimés mais espace non libéré** — Un processus maintient un descripteur ouvert sur un fichier supprimé. Le fichier est invisible dans `ls` mais occupe toujours de l'espace.

```bash
# Identifier les fichiers supprimés encore ouverts
lsof +L1
# La colonne SIZE montre l'espace occupé.
# La colonne COMMAND identifie le processus responsable.

# Libérer l'espace sans redémarrer le processus
# Tronquer le fichier via le descripteur du processus
> /proc/<PID>/fd/<FD>
# Ou redémarrer le service.
```

**Saturation d'inodes** — `df -h` montre de l'espace libre mais `df -i` montre 100% d'utilisation des inodes.

```bash
# Trouver les répertoires avec le plus de fichiers
find / -xdev -type d -exec sh -c 'echo "$(find "$1" -maxdepth 1 -type f | wc -l) $1"' _ {} \; 2>/dev/null | sort -rn | head -20

# Causes typiques :
# - Sessions PHP qui créent des millions de fichiers dans /tmp
# - Cache de paquets ou de builds non nettoyé
# - Système de mail avec des milliers de fichiers dans une queue
```

### 2.2 RAID logiciel (mdadm)

#### RAID dégradé

**Symptômes** — `cat /proc/mdstat` montre un RAID avec un disque manquant (marqué `[U_]` au lieu de `[UU]`). Des alertes SMART ou des erreurs I/O apparaissent dans les logs.

**Diagnostic** :

```bash
# État rapide
cat /proc/mdstat
# Exemple de sortie dégradée :
# md0 : active raid1 sda1[0]
#       1000000 blocks [2/1] [U_]
# [2/1] signifie 2 disques attendus, 1 actif. [U_] = premier OK, second absent.

# Détails complets
mdadm --detail /dev/md0
# Vérifier : State (clean, degraded, rebuilding), Active Devices, Failed Devices

# Identifier le disque défaillant
mdadm --detail /dev/md0 | grep -E "(faulty|removed)"  
dmesg | grep -iE "(sd[a-z]|error|fault)"  
smartctl -H /dev/<disque_suspect>  
```

**Résolution** :

```bash
# 1. Retirer le disque défaillant (si pas déjà fait automatiquement)
mdadm --manage /dev/md0 --fail /dev/sdb1  
mdadm --manage /dev/md0 --remove /dev/sdb1  

# 2. Remplacer physiquement le disque

# 3. Partitionner le nouveau disque identiquement à l'ancien
sfdisk -d /dev/sda | sfdisk /dev/sdb     # Copier la table de partitions

# 4. Ajouter le nouveau disque au RAID
mdadm --manage /dev/md0 --add /dev/sdb1

# 5. Suivre la reconstruction
watch cat /proc/mdstat
# La reconstruction peut prendre des heures selon la taille du RAID.
# Les performances I/O sont dégradées pendant cette période.

# 6. Mettre à jour la configuration
mdadm --detail --scan > /etc/mdadm/mdadm.conf  
update-initramfs -u  
```

**Point critique** — Un RAID1 ou RAID5 dégradé n'a plus de redondance. Une seconde panne de disque pendant la reconstruction entraîne une perte de données. Sur les RAID5 de grande capacité, le risque de défaillance d'un second disque pendant la reconstruction est significatif, raison pour laquelle le RAID6 est recommandé pour les volumes importants.

#### RAID qui ne s'assemble plus au démarrage

**Symptômes** — Après un redémarrage, le RAID n'est pas assemblé. Les volumes `/dev/mdX` n'existent pas.

**Diagnostic et résolution** :

```bash
# Scanner les disques pour détecter les RAID
mdadm --examine /dev/sda1  
mdadm --examine /dev/sdb1  

# Assembler manuellement
mdadm --assemble --scan

# Si l'assemblage échoue, forcer avec les disques connus
mdadm --assemble /dev/md0 /dev/sda1 /dev/sdb1 --force

# Régénérer la configuration
mdadm --detail --scan >> /etc/mdadm/mdadm.conf  
update-initramfs -u  
```

### 2.3 LVM

#### Volume logique plein

**Symptômes** — Une partition LVM est pleine. Les applications retournent « No space left on device ».

**Diagnostic et extension** :

```bash
# État actuel
lvs                                      # Volumes logiques  
vgs                                      # Groupes de volumes  
pvs                                      # Volumes physiques  

# Espace libre dans le groupe de volumes
vgs -o +vg_free

# Si de l'espace est disponible dans le VG, étendre le LV
lvextend -L +10G /dev/vg0/lv_data
# ou utiliser tout l'espace restant
lvextend -l +100%FREE /dev/vg0/lv_data

# Étendre le système de fichiers
resize2fs /dev/vg0/lv_data              # ext4 (en ligne)  
xfs_growfs /mnt/data                     # XFS (en ligne, par point de montage)  
```

**Si le VG n'a plus d'espace libre** :

```bash
# Ajouter un nouveau disque physique au VG
pvcreate /dev/sdc  
vgextend vg0 /dev/sdc  
# Puis étendre le LV comme ci-dessus.
```

#### Snapshot LVM qui sature

**Symptômes** — Un snapshot LVM se remplit et devient invalide. Les écritures sur le volume d'origine sont bloquées ou le snapshot est automatiquement supprimé.

**Diagnostic** :

```bash
lvs -o +snap_percent
# La colonne Snap% indique le pourcentage de remplissage du snapshot.
# À 100%, le snapshot est invalide.
```

**Résolution** — Étendre le snapshot s'il est encore valide (`lvextend -L +5G /dev/vg0/snap`). Si le snapshot est invalide, le supprimer (`lvremove /dev/vg0/snap`). Dimensionner les snapshots en fonction du taux de modification des données : un snapshot de 10-20% de la taille du volume original est souvent suffisant pour des opérations courtes (sauvegardes), mais insuffisant pour une utilisation prolongée.

### 2.4 NFS

#### Montage NFS qui échoue

**Symptômes** — `mount -t nfs` retourne « access denied », « Connection timed out » ou « No route to host ».

**Diagnostic** :

```bash
# Côté client : tester la connectivité
ping <serveur_nfs>  
rpcinfo -p <serveur_nfs>                 # Vérifier les services RPC  
showmount -e <serveur_nfs>               # Lister les exports  

# Côté serveur : vérifier les exports
cat /etc/exports  
exportfs -v                              # Exports actifs avec options  

# Côté serveur : vérifier les services
systemctl status nfs-server  
systemctl status rpcbind  

# Vérifier le pare-feu (NFS utilise plusieurs ports)
# NFSv4 : uniquement le port TCP 2049
# NFSv3 : ports 111 (rpcbind), 2049 (nfs), et des ports dynamiques
ss -tlnp | grep -E "(2049|111)"
```

**Causes courantes** — Le client n'est pas autorisé dans `/etc/exports` (vérifier le sous-réseau et les options). Le pare-feu bloque les ports NFS. Le service `rpcbind` n'est pas démarré. Pour NFSv3, les ports dynamiques ne sont pas ouverts (configurer des ports fixes dans `/etc/default/nfs-kernel-server` pour simplifier le filtrage pare-feu).

#### Montage NFS en état « stale » ou bloqué

**Symptômes** — Les accès au point de montage NFS se figent. `ls /mnt/nfs` ne répond pas. `df` se bloque. Le message « Stale file handle » apparaît.

**Diagnostic** :

```bash
# Vérifier si le montage est bloqué
mount | grep nfs  
stat /mnt/nfs                            # Se bloque si le montage est stale  

# Depuis un autre terminal
cat /proc/mounts | grep nfs
```

**Résolution** :

```bash
# Tenter un démontage paresseux (libère immédiatement le point de montage)
umount -l /mnt/nfs

# Si le démontage est impossible, forcer
umount -f /mnt/nfs

# Remonter
mount /mnt/nfs

# Prévention : utiliser les options de montage adaptées
# Dans /etc/fstab :
# serveur:/export /mnt/nfs nfs4 defaults,_netdev,nofail,soft,timeo=30,retrans=3 0 0
# soft    : retourne une erreur au lieu de bloquer indéfiniment
# timeo   : timeout en dixièmes de secondes
# retrans : nombre de tentatives
# nofail  : ne bloque pas le boot si le serveur est absent
# _netdev : attend que le réseau soit disponible avant de monter
```

### 2.5 Stockage des conteneurs

#### Docker : espace disque saturé par les images et volumes

**Symptômes** — `/var/lib/docker` occupe un espace considérable. Les builds et pulls échouent par manque d'espace.

**Diagnostic** :

```bash
docker system df                         # Vue d'ensemble  
docker system df -v                      # Détail par image/conteneur/volume  

# Taille du répertoire Docker
du -sh /var/lib/docker/  
du -h --max-depth=1 /var/lib/docker/  

# Images sans tag (dangling)
docker images -f dangling=true

# Volumes orphelins (non utilisés par un conteneur)
docker volume ls -f dangling=true
```

**Résolution** :

```bash
# Nettoyage progressif (du moins au plus agressif)

# Supprimer les conteneurs arrêtés, réseaux inutilisés et images dangling
docker system prune

# Idem + toutes les images non utilisées par un conteneur actif
docker system prune -a

# Idem + les volumes orphelins
docker system prune -a --volumes

# Nettoyage ciblé du cache de build
docker builder prune  
docker builder prune -a                  # Tout le cache  
```

**Prévention** — Configurer la rotation des logs dans `/etc/docker/daemon.json` avec `log-opts` (`max-size` et `max-file`). Mettre en place un cron de nettoyage régulier. Envisager de déplacer `/var/lib/docker` sur un volume dédié et de taille suffisante en configurant `data-root` dans `daemon.json`.

#### Kubernetes : PV inaccessible après redéploiement

**Symptômes** — Un pod redéployé sur un nœud différent ne peut pas monter le PV. Le message « Multi-Attach error for volume » apparaît.

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>  
kubectl describe pv <pv>  
# Vérifier le champ accessModes et le nœud sur lequel le PV est attaché.
```

**Cause** — Le volume utilise le mode `ReadWriteOnce` (RWO), qui ne permet le montage que sur un seul nœud à la fois. Si l'ancien pod n'est pas terminé (ou si le détachement du volume du nœud précédent est lent), le nouveau pod ne peut pas monter le volume.

**Résolution** — Attendre que l'ancien pod soit complètement terminé et le volume détaché. Si le problème persiste, forcer le détachement en supprimant l'objet `VolumeAttachment` correspondant. Pour les applications nécessitant un accès multi-nœud, utiliser des volumes `ReadWriteMany` (RWX) via NFS, CephFS ou un autre système de fichiers distribué.

```bash
# Lister les attachements de volumes
kubectl get volumeattachment

# Supprimer un attachement bloqué (avec précaution)
kubectl delete volumeattachment <nom>
```

---

## Arbre de décision réseau et stockage

**Impossible de joindre un service distant** → Section 1.1. Remonter couche par couche : lien → IP → route → port → application.

**Résolution DNS défaillante** → Section 1.2. Tester avec `dig @8.8.8.8`, vérifier `resolv.conf`, systemd-resolved et nsswitch.

**Erreur de certificat TLS** → Section 1.3. Vérifier dates, chaîne, correspondance clé/cert avec `openssl`.

**Trafic bloqué malgré un service actif** → Section 1.4. Vérifier nftables/ufw, conntrack, Docker iptables.

**Conteneur sans réseau** → Section 1.5. Vérifier ip_forward, NAT Docker, conflit d'adressage.

**Performances réseau dégradées** → Section 1.6. Mesurer avec `mtr`, `iperf3`, vérifier MTU.

**Erreurs I/O ou FS en lecture seule** → Section 2.1. Vérifier SMART, lancer fsck hors ligne.

**RAID dégradé** → Section 2.2. Identifier le disque en panne, remplacer, reconstruire.

**Partition LVM pleine** → Section 2.3. Étendre LV si espace libre dans le VG.

**Montage NFS bloqué** → Section 2.4. Démontage lazy, vérifier connectivité serveur, options `soft`.

**Espace Docker saturé** → Section 2.5. `docker system prune`, rotation des logs.

---

## Commandes de diagnostic — Récapitulatif

```bash
# Réseau — Vue rapide
ip -br -c addr                           # Interfaces et adresses  
ip route show                            # Routes  
ss -tlnp                                 # Ports en écoute  
ping -c 3 <passerelle>                   # Connectivité  
dig <domaine>                            # DNS  
curl -v <url>                            # Applicatif  
tcpdump -i <if> -nn port <port> -c 20   # Capture  

# Stockage — Vue rapide
df -h                                    # Espace par partition  
df -i                                    # Inodes  
lsblk -f                                # Périphériques et FS  
cat /proc/mdstat                         # RAID  
lvs && vgs && pvs                        # LVM  
smartctl -H /dev/sda                     # Santé disque  
iostat -xz 1 3                           # Performances I/O  
lsof +L1                                # Fichiers supprimés ouverts  
mount | column -t                        # Montages actifs  
docker system df                         # Stockage Docker  
kubectl get pv,pvc -A                    # Stockage Kubernetes  
```

⏭️ [Procédures recovery](/annexes/C.4-procedures-recovery.md)
