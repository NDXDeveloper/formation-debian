🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe C.1 — Guide diagnostic système Debian

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Ce guide couvre le diagnostic et la résolution des problèmes les plus fréquents au niveau du système d'exploitation Debian. Il s'adresse à tout administrateur confronté à un dysfonctionnement sur une machine Debian, qu'il s'agisse d'un poste de travail, d'un serveur web ou d'un nœud d'infrastructure.

Chaque problème est présenté selon un format uniforme : symptômes observés, commandes de diagnostic, causes probables et pistes de résolution.

---

## 1. Problèmes de démarrage

### 1.1 Le système ne démarre pas — Écran GRUB ou absence de GRUB

**Symptômes** — L'écran reste noir, affiche un message « No bootable device » ou « error: unknown filesystem », ou le menu GRUB apparaît mais aucune entrée ne fonctionne.

**Diagnostic** — Démarrer depuis un support d'installation Debian (USB ou réseau) en mode rescue. Monter la partition racine et vérifier l'état du chargeur de démarrage.

```bash
# Depuis le mode rescue ou un live USB
lsblk -f                                # Identifier les partitions  
mount /dev/sda2 /mnt                     # Monter la racine (adapter le device)  
mount /dev/sda1 /mnt/boot/efi            # Partition EFI si applicable  
mount --bind /dev /mnt/dev  
mount --bind /proc /mnt/proc  
mount --bind /sys /mnt/sys  
chroot /mnt  

# Dans le chroot, vérifier et réinstaller GRUB
grub-install /dev/sda                    # BIOS/MBR  
grub-install --target=x86_64-efi --efi-directory=/boot/efi    # UEFI  
                                          # (--efi-directory pointe vers la
                                          # partition EFI montée, généralement
                                          # /boot/efi sous Debian)
update-grub                              # Régénérer grub.cfg
                                          # Sur Debian récent, équivalent à
                                          # grub-mkconfig -o /boot/grub/grub.cfg
```

**Causes probables** — Une mise à jour du noyau qui a échoué partiellement, une table de partitions corrompue, un changement de disque qui a décalé les identifiants de périphérique (raison pour laquelle les UUID dans `/etc/fstab` sont préférables aux chemins `/dev/sdX`), ou une partition EFI pleine.

**Résolution complémentaire** — Si la partition EFI est pleine, nettoyer les anciens noyaux avec `apt autoremove --purge` depuis le chroot. Si la table de partitions est corrompue, `gdisk` ou `fdisk` peuvent tenter une récupération. En dernier recours, `testdisk` peut reconstruire une table de partitions endommagée.

### 1.2 Le système démarre mais reste bloqué pendant l'initialisation

**Symptômes** — Le noyau se charge mais le système se fige sur un service, sur l'écran Plymouth ou sur un écran noir avant le prompt de connexion. Un message du type « A start job is running for... » peut rester affiché indéfiniment.

**Diagnostic** — Accéder aux messages de démarrage en retirant temporairement le paramètre `quiet` de la ligne de commande du noyau dans GRUB. Appuyer sur `e` dans le menu GRUB pour éditer l'entrée, supprimer `quiet splash` de la ligne `linux`, puis appuyer sur `Ctrl+X` pour démarrer.

Si le système finit par démarrer après un long délai, analyser les temps de démarrage.

```bash
systemd-analyze                          # Temps total  
systemd-analyze blame                    # Classement par temps  
systemd-analyze critical-chain           # Chaîne critique  
systemctl list-units --failed            # Services en échec  
journalctl -b -p err                     # Erreurs du démarrage courant  
```

**Causes probables** — Un montage réseau (`nfs`, `cifs`) configuré dans `/etc/fstab` sans l'option `nofail` ou `_netdev` alors que le réseau n'est pas encore disponible. Un service qui attend une ressource réseau inexistante (base de données distante, serveur LDAP). Un volume chiffré LUKS qui attend une passphrase sans interface pour la saisir. Un service défaillant dont la configuration systemd impose un timeout élevé.

**Résolution** — Si le système est bloqué sur un montage, démarrer en mode rescue (ajouter `systemd.unit=rescue.target` dans les paramètres du noyau GRUB) puis corriger `/etc/fstab` en ajoutant `nofail` et `_netdev` aux montages réseau. Si un service bloque le démarrage, le désactiver temporairement avec `systemctl disable <service>` depuis le mode rescue, puis diagnostiquer après un démarrage complet.

### 1.3 Kernel panic au démarrage

**Symptômes** — Le message « Kernel panic - not syncing » s'affiche, suivi d'un texte technique. Le système est totalement figé.

**Diagnostic** — Le message de panic contient la cause. Les deux situations les plus fréquentes sont « VFS: Unable to mount root fs » (le noyau ne trouve pas la partition racine) et « Attempted to kill init! » (le processus init / systemd a crashé).

```bash
# Démarrer avec un ancien noyau via le menu GRUB (Advanced options)
# Puis analyser le problème du noyau récent

uname -r                                # Version du noyau actuel  
dpkg -l 'linux-image-*'                 # Noyaux installés  
dmesg | grep -i error                   # Erreurs matérielles  
```

**Causes probables** — Un initramfs corrompu ou manquant, un pilote manquant dans le nouveau noyau (notamment pour les contrôleurs de stockage), un paramètre noyau incorrect ou une incompatibilité matérielle avec la nouvelle version du noyau.

**Résolution** — Démarrer sur l'ancien noyau (menu GRUB → Advanced options), puis régénérer l'initramfs du noyau défaillant avec `update-initramfs -u -k <version>`. Si le problème persiste, désinstaller le noyau problématique avec `apt remove linux-image-<version>`.

---

## 2. Services systemd

### 2.1 Un service ne démarre pas

**Symptômes** — `systemctl start <service>` retourne une erreur. `systemctl status <service>` affiche un état `failed` ou `inactive (dead)` avec un code de sortie non nul.

**Diagnostic séquentiel** — Suivre ces étapes dans l'ordre.

```bash
# Étape 1 : Lire le statut détaillé
systemctl status <service>
# Regarder : le code de sortie (exit-code), le signal (si tué),
# et les dernières lignes de log affichées.

# Étape 2 : Lire les logs complets
journalctl -u <service> --no-pager -n 50
# Chercher les lignes contenant "error", "fatal", "failed", "denied".

# Étape 3 : Vérifier la configuration du service
systemctl cat <service>
# Vérifier les chemins (ExecStart, WorkingDirectory, EnvironmentFile)
# Vérifier que les fichiers existent et sont accessibles.

# Étape 4 : Vérifier les dépendances
systemctl list-dependencies <service>
# Un service dépendant qui a échoué peut bloquer le démarrage.

# Étape 5 : Tenter un démarrage en mode debug
# Pour les services qui le supportent, lancer le binaire manuellement
# avec les mêmes arguments que dans ExecStart.
```

**Causes les plus fréquentes et résolutions** :

Le **fichier de configuration du service invalide** est la cause numéro un. Une erreur de syntaxe dans le fichier de configuration de l'application (pas du fichier d'unité systemd) empêche le démarrage. Lancer la commande de validation du service (`nginx -t`, `apache2ctl -t`, `named-checkconf`, `sshd -t`, etc.) pour identifier l'erreur exacte.

Les **permissions insuffisantes** se manifestent par des messages « Permission denied » dans les logs. Vérifier que l'utilisateur spécifié dans le fichier d'unité (`User=`) a les droits de lecture sur les fichiers de configuration, d'écriture sur les répertoires de données et de logs, et d'écoute sur le port demandé (les ports inférieurs à 1024 nécessitent `CAP_NET_BIND_SERVICE` ou un utilisateur root).

```bash
# Vérifier les permissions
ls -la /etc/<service>/  
ls -la /var/lib/<service>/  
ls -la /var/log/<service>/  
namei -l /var/lib/<service>/data         # Vérifie chaque composant du chemin  
```

Un **port déjà occupé** par un autre service empêche le binding. Le message typique est « Address already in use ».

```bash
ss -tlnp | grep :<port>                 # Identifier le processus qui occupe le port
```

Un **fichier d'unité modifié sans daemon-reload** est une source d'erreurs fréquente. Après modification d'un fichier `.service`, systemd continue d'utiliser la version en mémoire tant que `systemctl daemon-reload` n'a pas été exécuté. Le message d'avertissement « Warning: unit file changed on disk » signale cette situation.

### 2.2 Un service redémarre en boucle

**Symptômes** — Le service passe alternativement entre les états `activating`, `active` et `failed`. Les logs montrent des démarrages répétés. Le message « Start request repeated too quickly, refusing to start » peut apparaître.

**Diagnostic** :

```bash
systemctl status <service>
# Observer le compteur de redémarrages et l'uptime.

journalctl -u <service> --since "5 minutes ago"
# Identifier le pattern : le service démarre, tourne quelques secondes,
# puis se termine avec une erreur.

# Vérifier les limites de redémarrage
systemctl show <service> -p Restart,RestartSec,StartLimitBurst,StartLimitIntervalSec
```

**Causes probables** — L'application démarre correctement mais crash peu après en raison d'une erreur d'exécution (connexion à une base de données impossible, fichier de données corrompu, mémoire insuffisante). La directive `Restart=on-failure` dans le fichier d'unité provoque le redémarrage automatique, et `StartLimitBurst`/`StartLimitIntervalSec` finissent par bloquer les tentatives.

**Résolution** — Analyser les logs pour identifier la cause du crash. Une fois la cause corrigée, réinitialiser le compteur d'échecs avec `systemctl reset-failed <service>` avant de relancer le service.

### 2.3 Un service est actif mais ne fonctionne pas correctement

**Symptômes** — `systemctl status` indique `active (running)` mais le service ne répond pas aux requêtes ou se comporte de manière anormale.

**Diagnostic** :

```bash
# Le service écoute-t-il sur le bon port ?
ss -tlnp | grep <service>

# Le processus consomme-t-il des ressources anormales ?
ps aux | grep <service>  
top -p $(pgrep <service>)  

# La configuration est-elle celle attendue ?
# Pour Nginx :
nginx -T                                 # Affiche la config complète effective
# Pour Postfix :
postconf -n                              # Paramètres modifiés

# Tester la connectivité de bout en bout
curl -v http://localhost:<port>/
```

**Causes probables** — Le service écoute sur `127.0.0.1` au lieu de `0.0.0.0` (ou vice versa). Le pare-feu bloque le trafic. Un reverse proxy en amont ne transmet pas correctement les requêtes. Le service a chargé une ancienne configuration (un `reload` a été oublié après modification). Les limites de ressources du service sont atteintes (`LimitNOFILE` trop bas, mémoire insuffisante).

---

## 3. Gestion des paquets

### 3.1 APT échoue avec des erreurs de dépendances

**Symptômes** — `apt install` ou `apt upgrade` affiche des messages « unmet dependencies », « broken packages » ou « held broken packages ».

**Diagnostic et résolution séquentiels** :

```bash
# Étape 1 : Tenter une réparation automatique
apt --fix-broken install

# Étape 2 : Si l'étape 1 échoue, forcer la configuration des paquets en attente
dpkg --configure -a

# Étape 3 : Vérifier les paquets retenus
apt-mark showhold
# Si des paquets sont retenus, ils peuvent bloquer les mises à jour
apt-mark unhold <paquet>

# Étape 4 : Identifier les paquets cassés
dpkg -l | grep -E "^(iU|iF|iH)"
# i = installé, U = unpacked, F = failed, H = half-installed

# Étape 5 : En dernier recours, forcer la suppression du paquet problématique
dpkg --remove --force-remove-reinstreq <paquet>  
apt --fix-broken install  
```

**Causes probables** — Un mélange de dépôts incompatibles (par exemple stable et testing), une installation interrompue (`dpkg` a été tué ou le système a redémarré pendant une installation), ou un dépôt tiers fournissant un paquet qui entre en conflit avec les paquets officiels.

**Prévention** — Ne jamais mélanger les branches Debian (stable/testing/unstable) sans maîtriser le pinning APT. Toujours laisser les opérations APT et dpkg se terminer complètement.

### 3.2 APT ne peut pas télécharger les paquets

**Symptômes** — `apt update` échoue avec des erreurs « Failed to fetch », « Could not resolve », « Connection timed out » ou « NO_PUBKEY ».

**Diagnostic** :

```bash
# Tester la connectivité réseau de base
ping -c 2 deb.debian.org

# Tester la résolution DNS
dig deb.debian.org

# Tester l'accès HTTP/HTTPS (adapter le suite : trixie pour Debian 13 stable,
# bookworm pour Debian 12 oldstable, sid pour unstable)
curl -v https://deb.debian.org/debian/dists/trixie/Release

# Vérifier la configuration du proxy (si applicable)
env | grep -i proxy  
cat /etc/apt/apt.conf.d/*proxy*  

# Vérifier les fichiers sources
cat /etc/apt/sources.list  
ls -la /etc/apt/sources.list.d/  
```

**Résolutions selon la cause** :

Pour les erreurs de clé GPG (« NO_PUBKEY »), récupérer la clé manquante.

```bash
# Méthode recommandée (Debian 12+) : clé isolée dans /etc/apt/keyrings/
# associée explicitement à la source via Signed-By dans le fichier .sources
install -d -m 0755 /etc/apt/keyrings  
curl -fsSL https://<url-de-la-cle> | gpg --dearmor -o /etc/apt/keyrings/<nom>.gpg  
chmod 0644 /etc/apt/keyrings/<nom>.gpg  

# Référencer la clé dans le fichier source DEB822 (/etc/apt/sources.list.d/<nom>.sources)
# Types: deb
# URIs: https://<dépôt>
# Suites: trixie
# Components: main
# Signed-By: /etc/apt/keyrings/<nom>.gpg

# Méthode legacy (toujours fonctionnelle mais à éviter pour les nouveaux dépôts) :
# clé déposée dans /etc/apt/trusted.gpg.d/ — fait confiance à toute source qui s'en sert
# curl -fsSL https://<url-de-la-cle> | gpg --dearmor -o /etc/apt/trusted.gpg.d/<nom>.gpg

# Vérifier les clés installées
ls -la /etc/apt/keyrings/ /etc/apt/trusted.gpg.d/
# apt-key : déprécié depuis Debian 11 Bullseye (apt 2.2) avec un avertissement
# à chaque exécution, retiré en Debian 13 Trixie (apt 3.0 — le binaire
# /usr/bin/apt-key n'existe plus). Sur Trixie, utiliser directement gpg
# pour inspecter les clés : gpg --show-keys /etc/apt/keyrings/<nom>.gpg
# (le paquet `gnupg` doit être installé : sudo apt install gnupg).
```

Pour les erreurs de certificat HTTPS, vérifier que le paquet `ca-certificates` est installé et à jour. Pour les problèmes de proxy, configurer APT dans `/etc/apt/apt.conf.d/90proxy`.

### 3.3 Espace disque insuffisant pour les mises à jour

**Symptômes** — `apt upgrade` échoue avec « No space left on device » ou « You don't have enough free space in /var/cache/apt/archives/ ».

**Diagnostic et résolution** :

```bash
# Identifier la partition saturée
df -h

# Si /boot est plein (très fréquent)
dpkg -l 'linux-image-*' | grep ^ii      # Noyaux installés  
uname -r                                 # Noyau en cours d'utilisation  
apt autoremove --purge                   # Supprime les anciens noyaux  

# Si /var est plein
du -h --max-depth=1 /var | sort -rh | head -20
# Souvent les logs : /var/log
journalctl --vacuum-size=200M            # Réduire les journaux systemd  
find /var/log -name "*.gz" -mtime +30 -delete  # Vieux logs compressés  

# Si le cache APT est volumineux
apt clean                                # Vide /var/cache/apt/archives/  
du -sh /var/cache/apt/archives/          # Vérifier l'espace libéré  
```

### 3.4 Vérification de l'intégrité des paquets

Après un crash système ou une corruption de disque, il peut être nécessaire de vérifier l'intégrité des fichiers installés par les paquets.

```bash
# Installer l'outil de vérification
apt install debsums

# Vérifier tous les paquets installés
debsums -s                               # Silencieux : n'affiche que les erreurs

# Vérifier un paquet spécifique
debsums <paquet>

# Réinstaller les paquets dont les fichiers sont corrompus
apt install --reinstall <paquet>
```

---

## 4. Performances et ressources

### 4.1 Saturation de l'espace disque

**Symptômes** — Les applications retournent des erreurs « No space left on device ». Les services refusent d'écrire des logs ou des données. Le système peut devenir instable si la partition racine est pleine à 100%.

**Diagnostic** :

```bash
# Vue d'ensemble
df -h                                    # Espace par partition  
df -i                                    # Utilisation des inodes (cause parfois invisible)  

# Identifier les plus gros consommateurs
du -h --max-depth=1 / 2>/dev/null | sort -rh | head -20

# Chercher les fichiers volumineux
find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Fichiers supprimés mais encore ouverts (espace non libéré)
lsof +L1
# Un fichier supprimé mais encore ouvert par un processus continue
# d'occuper de l'espace jusqu'au redémarrage du processus.
```

**Résolutions courantes** :

```bash
# Nettoyer les journaux systemd
journalctl --vacuum-size=500M

# Nettoyer le cache APT
apt clean

# Supprimer les anciens noyaux
apt autoremove --purge

# Nettoyer les vieux logs
find /var/log -name "*.gz" -mtime +30 -delete  
find /var/log -name "*.old" -delete  

# Nettoyer les fichiers temporaires
find /tmp -type f -atime +7 -delete  
find /var/tmp -type f -atime +30 -delete  

# Si des fichiers supprimés occupent encore de l'espace
# Identifier le processus avec lsof +L1, puis le redémarrer
systemctl restart <service>

# Nettoyer Docker (si installé)
docker system prune -a --volumes
```

Le cas particulier de la saturation d'inodes (`df -i` montre 100% alors que `df -h` montre de l'espace libre) est généralement causé par un répertoire contenant des millions de petits fichiers. `find / -xdev -type d -exec sh -c 'echo "$(find "$1" -maxdepth 1 | wc -l) $1"' _ {} \; | sort -rn | head -20` identifie les répertoires contenant le plus de fichiers.

### 4.2 Saturation mémoire et OOM Killer

**Symptômes** — Le système devient très lent, les applications sont tuées aléatoirement. `dmesg` affiche « Out of memory: Killed process ». Le fichier `/var/log/kern.log` contient des messages OOM.

**Diagnostic** :

```bash
# État actuel de la mémoire
free -h
# Colonnes clés : "available" = mémoire réellement disponible
# (incluant le cache libérable). Ne pas se fier uniquement à "free".

# Détail fin
cat /proc/meminfo | head -20

# Processus classés par consommation mémoire
ps aux --sort=-%mem | head -20

# Historique des événements OOM
dmesg | grep -i "out of memory"  
journalctl -k | grep -i oom  

# Pression mémoire (disponible sur les noyaux récents)
cat /proc/pressure/memory

# Swap : est-elle utilisée de manière intensive ?
vmstat 1 5
# Colonnes si/so : swap in/out. Des valeurs élevées indiquent
# un système en détresse mémoire.
swapon --show                            # Partitions/fichiers swap actifs
```

**Résolution** :

Pour un problème immédiat, identifier et redémarrer le processus consommant trop de mémoire, ou le limiter via les cgroups systemd (`MemoryMax=` dans le fichier d'unité). Si le swap est absent ou insuffisant, un fichier swap temporaire peut soulager la pression.

```bash
# Créer un fichier swap temporaire de 2 Go
fallocate -l 2G /swapfile  
chmod 600 /swapfile  
mkswap /swapfile  
swapon /swapfile  
# Ajouter dans /etc/fstab pour la persistance :
# /swapfile none swap sw 0 0
```

Pour un problème récurrent, ajuster `vm.swappiness` dans `/etc/sysctl.d/` (valeur basse = le système préfère libérer le cache plutôt que swapper), ajouter de la RAM ou optimiser les applications.

### 4.3 Charge CPU élevée

**Symptômes** — Le système est lent à répondre. La commande `uptime` affiche une charge (load average) supérieure au nombre de cœurs CPU. Les opérations habituellement rapides prennent un temps anormal.

**Diagnostic** :

```bash
# Charge système
uptime
# Load average : 1min 5min 15min
# Un load average > nombre de cœurs CPU = saturation
nproc                                    # Nombre de cœurs

# Identifier les processus consommateurs
top -bn1 | head -30                      # Snapshot
# En mode interactif : touche 'P' pour trier par CPU

# Distinguer CPU user vs system vs iowait
mpstat -P ALL 1 5
# %usr    = calcul applicatif
# %sys    = appels système (noyau)
# %iowait = attente d'E/S disque
# Un iowait élevé indique un problème de disque, pas de CPU.

# Si iowait est élevé, identifier les processus en attente d'I/O
iotop -o                                 # Processus effectuant des I/O  
iostat -xz 1 5                           # Statistiques par disque  

# Profiler un processus spécifique
strace -c -p <PID>                       # Comptage des appels système
# Ctrl+C pour afficher le résumé
```

**Causes probables** — Un processus applicatif en boucle infinie ou consommant plus que prévu (bug, charge inhabituelle). Une saturation d'I/O disque (la charge augmente même si le CPU n'est pas à 100% car les processus en attente d'I/O contribuent au load average). Un logiciel malveillant (vérifier les processus inconnus). Un nombre excessif de processus (fork bomb).

### 4.4 Performances disque dégradées

**Symptômes** — Les opérations d'écriture et de lecture sont lentes. Le `iowait` affiché par `top` ou `mpstat` est élevé. Les applications qui dépendent du disque (bases de données, logs) sont ralenties.

**Diagnostic** :

```bash
# Statistiques d'I/O par disque
iostat -xz 2 5
# Colonnes clés :
# %util   = pourcentage d'utilisation du disque (>80% = goulot d'étranglement)
# await   = temps moyen d'attente par I/O (en ms)
# r/s,w/s = opérations de lecture/écriture par seconde

# Processus responsables des I/O
iotop -oP

# Santé du disque
smartctl -H /dev/sda                     # État global SMART  
smartctl -a /dev/sda | grep -E "(Reallocated|Current_Pending|Offline_Uncorrectable)"  
# Des secteurs réalloués ou en attente indiquent un disque en fin de vie.

# État du RAID si applicable
cat /proc/mdstat  
mdadm --detail /dev/md0  

# Vérification du système de fichiers (nécessite un démontage)
# En mode rescue ou sur une partition non montée :
e2fsck -f /dev/sda1                      # ext4  
xfs_repair /dev/sda2                     # XFS  
```

**Résolution** — Si le disque montre des erreurs SMART, planifier un remplacement en urgence et vérifier que les sauvegardes sont à jour. Si les I/O sont saturées par un processus identifié, utiliser `ionice` pour réduire sa priorité. Si le problème est structurel, envisager le passage à un SSD, l'ajout de RAM (pour augmenter le cache disque) ou la migration vers un système de fichiers plus performant.

---

## 5. Réseau système

### 5.1 Pas de connectivité réseau

**Symptômes** — `ping` vers toute destination échoue. Les services réseau sont inaccessibles.

**Diagnostic méthodique** — Procéder couche par couche, du plus bas au plus haut.

```bash
# 1. L'interface est-elle active ?
ip link show
# Vérifier que l'état est UP. Si DOWN :
ip link set <interface> up

# 2. Une adresse IP est-elle assignée ?
ip addr show <interface>
# Si pas d'adresse : problème DHCP ou configuration statique manquante

# 3. La passerelle par défaut est-elle configurée ?
ip route show
# Vérifier la présence d'une route "default via <ip>"

# 4. La passerelle est-elle joignable ?
ping -c 2 <passerelle>

# 5. La résolution DNS fonctionne-t-elle ?
ping -c 2 8.8.8.8                        # Test sans DNS  
dig google.com                           # Test avec DNS  
# Si le ping par IP fonctionne mais pas le DNS :
cat /etc/resolv.conf                     # Vérifier les nameservers  
resolvectl status                        # Si systemd-resolved est utilisé  

# 6. Le trafic est-il bloqué par le pare-feu ?
nft list ruleset                         # ou ufw status
```

**Causes fréquentes sur un serveur Debian** — L'interface a été renommée après une mise à jour du noyau (passage de `eth0` à `ens3` par exemple). Le fichier `/etc/network/interfaces` ou la configuration NetworkManager fait référence à l'ancien nom. Le service de configuration réseau (`networking`, `NetworkManager` ou `systemd-networkd`) n'est pas démarré ou a échoué.

### 5.2 Résolution DNS défaillante

**Symptômes** — Les connexions par nom de domaine échouent (« Could not resolve host ») mais les connexions par adresse IP fonctionnent.

**Diagnostic** :

```bash
# Vérifier le résolveur configuré
cat /etc/resolv.conf
# Ce fichier est souvent un lien symbolique géré par systemd-resolved
# ou NetworkManager. Ne pas le modifier directement.

ls -la /etc/resolv.conf                  # Identifier qui le gère

# Tester la résolution
dig google.com                           # Via le résolveur système  
dig @8.8.8.8 google.com                  # Via un résolveur externe  
# Si le résolveur externe fonctionne mais pas le local : problème de config

# Si systemd-resolved est utilisé
resolvectl status                        # État complet  
resolvectl query google.com              # Test via resolved  

# Vérifier l'ordre de résolution
grep hosts /etc/nsswitch.conf
# Valeur typique : hosts: files dns
# "files" = /etc/hosts, "dns" = résolveur
```

**Résolution** — Si `resolv.conf` pointe vers `127.0.0.53` (systemd-resolved) et que la résolution échoue, vérifier que le service est actif (`systemctl status systemd-resolved`) et correctement configuré (`/etc/systemd/resolved.conf`). Si le problème persiste, configurer temporairement un résolveur externe en modifiant `/etc/systemd/resolved.conf` avec `DNS=8.8.8.8` puis `systemctl restart systemd-resolved`. En cas de réponses obsolètes après la mise à jour d'un enregistrement DNS, `resolvectl flush-caches` purge le cache de systemd-resolved sans redémarrer le service.

### 5.3 Un service réseau n'est pas accessible de l'extérieur

**Symptômes** — Le service fonctionne localement (`curl localhost:<port>` répond) mais les connexions depuis d'autres machines échouent.

**Diagnostic** :

```bash
# Le service écoute-t-il sur la bonne interface ?
ss -tlnp | grep <port>
# Si l'adresse est 127.0.0.1:<port>, le service n'écoute que localement.
# Il doit écouter sur 0.0.0.0:<port> ou sur l'IP spécifique.

# Le pare-feu autorise-t-il le trafic ?
nft list ruleset | grep <port>  
ufw status | grep <port>  

# Depuis la machine distante, le port est-il joignable ?
# (sur la machine distante)
nc -zv <ip_serveur> <port>              # Ou telnet, ou nmap  
curl -v http://<ip_serveur>:<port>/  

# Y a-t-il un filtrage en amont (routeur, cloud security group) ?
traceroute -T -p <port> <ip_serveur>    # Traceroute TCP
```

**Résolution** — Modifier la configuration du service pour écouter sur `0.0.0.0` ou sur l'adresse IP de l'interface concernée. Ajouter la règle de pare-feu appropriée. Vérifier les security groups (cloud) ou le routage réseau en amont.

---

## 6. Authentification et permissions

### 6.1 Impossible de se connecter en SSH

**Symptômes** — `ssh user@host` retourne « Permission denied », « Connection refused » ou « Connection timed out ».

**Diagnostic par message d'erreur** :

« Connection refused » signifie que le service SSH n'écoute pas sur le port ciblé. Vérifier que le service est actif (`systemctl status ssh`), qu'il écoute sur le bon port (`ss -tlnp | grep sshd`) et que le pare-feu l'autorise.

« Connection timed out » indique un problème réseau ou de pare-feu. Le paquet n'atteint pas le serveur. Vérifier la connectivité (`ping`), le routage et le pare-feu (local et en amont).

« Permission denied (publickey) » signifie que l'authentification par clé a échoué. Vérifier côté client que la bonne clé est utilisée (`ssh -vvv user@host` montre les clés tentées) et côté serveur que le fichier `authorized_keys` contient la bonne clé publique avec les bonnes permissions.

```bash
# Côté serveur : vérification des permissions SSH
ls -la ~/.ssh/
# Le répertoire ~/.ssh doit être en 700
# Le fichier authorized_keys doit être en 600
# Le répertoire home ne doit pas être accessible en écriture par group/others

chmod 700 ~/.ssh  
chmod 600 ~/.ssh/authorized_keys  
chmod 755 /home/<user>                   # Pas de write pour group/others  

# Côté serveur : vérifier la configuration sshd
sshd -T | grep -i "passwordauthentication\|pubkeyauthentication\|permitrootlogin\|allowusers"

# Côté serveur : logs détaillés
journalctl -u ssh --since "5 minutes ago"
```

### 6.2 sudo ne fonctionne pas

**Symptômes** — « user is not in the sudoers file. This incident will be reported » ou « user is not allowed to run sudo ».

**Diagnostic** :

```bash
# L'utilisateur est-il dans le groupe sudo ?
groups <utilisateur>  
id <utilisateur>  

# Si non, l'ajouter (en tant que root ou via un autre sudoer)
usermod -aG sudo <utilisateur>
# L'utilisateur doit se déconnecter et se reconnecter pour que
# l'appartenance au groupe prenne effet.

# Vérifier la configuration sudo
visudo -c                                # Valider la syntaxe  
cat /etc/sudoers | grep -v "^#" | grep -v "^$"  
ls -la /etc/sudoers.d/  
```

**Piège courant** — Sur une installation Debian sans environnement de bureau, le groupe `sudo` n'est pas toujours configuré dans `/etc/sudoers`. Vérifier que la ligne `%sudo ALL=(ALL:ALL) ALL` est présente et non commentée.

### 6.3 Problèmes de permissions sur les fichiers

**Symptômes** — « Permission denied » lors de l'accès à un fichier ou répertoire, alors que l'utilisateur semble avoir les droits appropriés.

**Diagnostic** :

```bash
# Vérifier les permissions classiques
ls -la <fichier>  
ls -la <répertoire>/  

# Vérifier chaque composant du chemin
namei -l /chemin/complet/vers/le/fichier
# Un répertoire parent sans le bit d'exécution (x) empêche
# la traversée, même si le fichier final est accessible.

# Vérifier les ACL
getfacl <fichier>

# Vérifier les attributs étendus
lsattr <fichier>
# L'attribut 'i' (immutable) empêche toute modification, même par root.
# Retirer avec : chattr -i <fichier>

# Vérifier AppArmor
aa-status  
journalctl -k | grep apparmor | tail -20  
# Un profil AppArmor peut bloquer l'accès indépendamment des permissions Unix.

# Vérifier les contextes SELinux (si activé)
ls -Z <fichier>
```

---

## 7. Matériel

### 7.1 Disque défaillant

**Symptômes** — Erreurs d'I/O dans les logs (`dmesg`, `journalctl -k`), performances disque dégradées, bruits inhabituels (disques mécaniques), fichiers corrompus.

**Diagnostic** :

```bash
# Messages du noyau liés au disque
dmesg | grep -iE "(error|fault|bad|fail|i/o)" | tail -30  
journalctl -k | grep -iE "(sd[a-z]|ata|scsi|i/o error)"  

# État SMART
smartctl -H /dev/sda                     # Verdict global  
smartctl -A /dev/sda                     # Attributs détaillés  
# Attributs critiques à surveiller :
# 5   Reallocated_Sector_Ct  — Secteurs réalloués (doit rester à 0)
# 187 Reported_Uncorrect     — Erreurs non corrigibles
# 197 Current_Pending_Sector — Secteurs en attente de réallocation
# 198 Offline_Uncorrectable  — Secteurs irrécupérables

# Lancer un test SMART
smartctl -t short /dev/sda               # Test court (~2 min)  
smartctl -t long /dev/sda                # Test long (~heures)  
# Consulter le résultat après le délai indiqué
smartctl -l selftest /dev/sda

# Si RAID : vérifier l'état de la grappe
cat /proc/mdstat  
mdadm --detail /dev/md0  
```

**Résolution** — Si SMART signale des secteurs réalloués ou des erreurs non corrigibles, le disque doit être remplacé. En RAID, retirer le disque défaillant (`mdadm --manage /dev/md0 --fail /dev/sda1`), le remplacer physiquement, puis reconstruire le RAID (`mdadm --manage /dev/md0 --add /dev/sda1`). Hors RAID, sauvegarder immédiatement les données avant le remplacement.

### 7.2 Problèmes de pilotes (firmware)

**Symptômes** — Un périphérique matériel n'est pas détecté ou ne fonctionne pas (carte réseau WiFi, carte graphique, contrôleur RAID). `dmesg` affiche des messages « firmware not found » ou « direct firmware load failed ».

**Diagnostic** :

```bash
# Identifier le matériel
lspci -nn                                # Périphériques PCI  
lsusb                                    # Périphériques USB  

# Chercher les messages de firmware manquant
dmesg | grep -i firmware

# Vérifier les firmwares installés
dpkg -l 'firmware-*'  
dpkg -l '*-firmware'  

# Identifier le firmware nécessaire
# Le message dmesg indique généralement le nom du fichier attendu
# Exemple : "firmware: failed to load iwlwifi-ty-a0-gf-a0-77.ucode"
apt search <nom_du_firmware>
```

**Résolution** — Installer le paquet de firmware approprié. Depuis Debian 12, les dépôts `non-free-firmware` sont inclus par défaut dans l'installeur. Si ce n'est pas le cas, ajouter les composants `non-free-firmware` et `non-free` dans `/etc/apt/sources.list`.

```bash
# Exemple pour le WiFi Intel
apt install firmware-iwlwifi

# Exemple pour les cartes graphiques NVIDIA
apt install nvidia-driver firmware-misc-nonfree

# Recharger le module noyau après installation du firmware
modprobe -r <module> && modprobe <module>
# Ou redémarrer le système
```

### 7.3 Problèmes de mémoire physique

**Symptômes** — Crashes aléatoires, kernel panics inexpliqués, corruptions de données sans cause logicielle apparente, erreurs « Machine Check Exception » dans les logs noyau.

**Diagnostic** :

```bash
# Vérifier les erreurs MCE (Machine Check Exception)
journalctl -k | grep -i "machine check\|mce\|hardware error"

# Compteurs d'erreurs mémoire ECC (si supporté par le matériel)
edac-util -s                             # Nécessite le paquet edac-utils
# ou
cat /sys/devices/system/edac/mc/mc0/ce_count   # Erreurs corrigées  
cat /sys/devices/system/edac/mc/mc0/ue_count   # Erreurs non corrigées  
```

Pour un test approfondi de la mémoire, utiliser `memtest86+` accessible depuis le menu GRUB (paquet `memtest86+`). Ce test doit être exécuté pendant plusieurs heures, idéalement une nuit complète, pour être fiable. Toute erreur détectée indique un module mémoire défectueux à remplacer.

---

## 8. Arbre de décision rapide

Face à un problème sur un système Debian, cet arbre de décision oriente vers la bonne section.

**Le système ne démarre pas du tout** → Section 1 (Problèmes de démarrage). Démarrer en mode rescue via le support d'installation.

**Le système démarre mais un service ne fonctionne pas** → Section 2 (Services systemd). Commencer par `systemctl status` et `journalctl -u`.

**apt ou dpkg retourne des erreurs** → Section 3 (Gestion des paquets). Commencer par `apt --fix-broken install` et `dpkg --configure -a`.

**Le système est lent ou ne répond plus** → Section 4 (Performances). Vérifier dans l'ordre : disque plein (`df -h`), mémoire (`free -h`), CPU (`uptime`), I/O disque (`iostat`).

**Pas de connectivité réseau** → Section 5 (Réseau). Remonter couche par couche : interface → IP → route → DNS → pare-feu.

**Impossible de se connecter ou « Permission denied »** → Section 6 (Authentification). Vérifier les permissions, le groupe sudo, les clés SSH et les logs d'authentification.

**Erreurs matérielles dans les logs** → Section 7 (Matériel). Vérifier SMART pour les disques, `dmesg` pour le firmware et memtest86+ pour la mémoire.

---

## Commandes de diagnostic essentielles — Récapitulatif

```bash
# Vue d'ensemble rapide du système (à exécuter en premier)
uptime                                   # Charge et durée depuis le démarrage  
free -h                                  # Mémoire et swap  
df -h                                    # Espace disque  
systemctl --failed                       # Services en échec  
journalctl -p err --since "1 hour ago"   # Erreurs récentes  
dmesg --level=err,warn | tail -20        # Messages noyau récents  
ss -tlnp                                 # Ports en écoute  
ip addr show                             # Adresses réseau  
ps aux --sort=-%cpu | head -10           # Top processus CPU  
ps aux --sort=-%mem | head -10           # Top processus mémoire  
```

Ce bloc de commandes, exécuté en séquence, fournit en moins d'une minute une photographie complète de l'état du système et permet d'orienter le diagnostic dans la bonne direction.

⏭️ [Problèmes courants Kubernetes](/annexes/C.2-problemes-kubernetes.md)
