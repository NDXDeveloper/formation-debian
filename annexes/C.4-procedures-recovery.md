🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe C.4 — Procédures recovery

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette section fournit des **procédures pas à pas** pour les situations de recovery les plus critiques. Chaque procédure est conçue pour être suivie en situation d'urgence, sous pression, avec un minimum de prérequis. Les étapes sont numérotées, les commandes sont prêtes à exécuter et les points de vérification sont explicites.

**Règle absolue avant toute opération de recovery** — Ne jamais agir sur la seule copie des données. Si un disque, un volume ou un snapshot est encore accessible, en faire une copie ou un clone avant de tenter une réparation. Une tentative de recovery mal conduite peut transformer une situation récupérable en perte de données définitive.

---

## Procédure 1 — Restauration d'un système Debian qui ne démarre plus

### Prérequis

Un support d'installation Debian (USB ou réseau), de la même version majeure que le système installé.

### Étapes

**Étape 1 — Démarrer sur le support d'installation.**

Configurer le BIOS/UEFI pour démarrer sur le support USB. Choisir « Advanced options » puis « Rescue mode » dans le menu de l'installeur Debian. L'installeur propose de détecter et monter le système existant.

**Étape 2 — Monter le système manuellement si le mode rescue échoue.**

```bash
# Identifier les partitions
lsblk -f
# Repérer la partition racine (type ext4/xfs, label ou UUID connu)

# Monter la racine
mount /dev/sda2 /mnt

# Monter les autres partitions
mount /dev/sda1 /mnt/boot                # /boot séparé si applicable  
mount /dev/sda1 /mnt/boot/efi            # Partition EFI si UEFI  

# Monter les systèmes de fichiers virtuels
mount --bind /dev /mnt/dev  
mount --bind /dev/pts /mnt/dev/pts  
mount --bind /proc /mnt/proc  
mount --bind /sys /mnt/sys  
mount --bind /run /mnt/run  

# Entrer dans le chroot
chroot /mnt /bin/bash  
export PATH=/usr/sbin:/usr/bin:/sbin:/bin  
```

**Étape 3 — Diagnostiquer et réparer selon le problème.**

Pour un **GRUB absent ou corrompu** :

```bash
# BIOS/MBR
grub-install /dev/sda  
update-grub  

# UEFI
grub-install --target=x86_64-efi --efi-directory=/boot/efi  
update-grub  
```

Pour un **noyau défaillant** :

```bash
# Lister les noyaux installés
dpkg -l 'linux-image-*' | grep ^ii

# Réinstaller le noyau actuel
apt install --reinstall linux-image-$(uname -r)

# Régénérer l'initramfs
update-initramfs -u -k all

# Si le noyau est trop récent et pose problème, installer un noyau plus ancien
apt install linux-image-amd64            # Méta-paquet qui installe le plus récent
# ou revenir à une version spécifique depuis le menu GRUB Advanced
```

Pour un **/etc/fstab corrompu** :

```bash
# Vérifier la syntaxe
cat /etc/fstab
# Corriger les entrées problématiques
# Commenter les montages défaillants en ajoutant # en début de ligne
# Vérifier les UUID avec blkid
blkid
```

Pour des **paquets cassés** :

```bash
dpkg --configure -a  
apt --fix-broken install  
```

**Étape 4 — Quitter le chroot et redémarrer.**

```bash
exit                                     # Quitter le chroot  
umount -R /mnt                           # Démonter récursivement  
reboot  
```

**Point de vérification** — Le système démarre normalement. Vérifier `systemctl --failed` et `journalctl -b -p err` après le redémarrage.

---

## Procédure 2 — Restauration de fichiers depuis une sauvegarde borgbackup

### Prérequis

Accès au dépôt borg (local ou distant). Passphrase du dépôt si chiffré.

### Étapes

**Étape 1 — Vérifier l'accès au dépôt.**

```bash
# Dépôt local
export BORG_REPO=/backup/borg-repo

# Dépôt distant
export BORG_REPO=ssh://backup@serveur-backup:22/backup/borg-repo

# Vérifier l'intégrité du dépôt
borg check $BORG_REPO

# Lister les archives disponibles
borg list $BORG_REPO
# Exemple de sortie :
# srv-web01-2026-04-11    Thu, 2026-04-11 03:00:02
# srv-web01-2026-04-12    Fri, 2026-04-12 03:00:01
```

**Étape 2 — Identifier le contenu de l'archive à restaurer.**

```bash
# Lister les fichiers d'une archive
borg list $BORG_REPO::srv-web01-2026-04-12

# Chercher un fichier spécifique
borg list $BORG_REPO::srv-web01-2026-04-12 | grep nginx.conf

# Afficher les informations de l'archive
borg info $BORG_REPO::srv-web01-2026-04-12
```

**Étape 3 — Restaurer.**

```bash
# Restauration complète dans un répertoire temporaire
mkdir /tmp/restore  
cd /tmp/restore  
borg extract $BORG_REPO::srv-web01-2026-04-12  

# Restauration d'un fichier ou répertoire spécifique
borg extract $BORG_REPO::srv-web01-2026-04-12 etc/nginx/  
borg extract $BORG_REPO::srv-web01-2026-04-12 var/lib/postgresql/  

# Restauration directe à l'emplacement d'origine (avec précaution)
cd /  
borg extract $BORG_REPO::srv-web01-2026-04-12 etc/nginx/nginx.conf  
```

**Étape 4 — Vérifier et appliquer.**

```bash
# Comparer les fichiers restaurés avec l'état actuel
diff /tmp/restore/etc/nginx/nginx.conf /etc/nginx/nginx.conf

# Copier les fichiers restaurés à leur emplacement définitif
cp -a /tmp/restore/etc/nginx/ /etc/nginx/

# Valider la configuration et recharger le service
nginx -t && systemctl reload nginx

# Nettoyer
rm -rf /tmp/restore
```

La procédure est similaire pour **restic** :

```bash
export RESTIC_REPOSITORY=/backup/restic-repo  
export RESTIC_PASSWORD_FILE=/root/.restic-password  

restic snapshots                         # Lister les snapshots  
restic ls <snapshot-id>                  # Contenu d'un snapshot  
restic restore <snapshot-id> --target /tmp/restore  
restic restore <snapshot-id> --target /tmp/restore --include /etc/nginx/  
```

---

## Procédure 3 — Restauration d'une base de données PostgreSQL

### Prérequis

Un dump de sauvegarde (format SQL, custom ou directory). Un serveur PostgreSQL fonctionnel.

### Étapes

**Étape 1 — Identifier la sauvegarde disponible.**

```bash
# Localiser les fichiers de sauvegarde
ls -lh /backup/postgresql/

# Identifier le format
# .sql ou .sql.gz     → dump texte (pg_dump)
# .dump ou .custom    → format custom (pg_dump -Fc)
# répertoire avec toc.dat → format directory (pg_dump -Fd)
```

**Étape 2 — Préparer la base de destination.**

```bash
# Se connecter en tant que superuser PostgreSQL
sudo -u postgres psql

# Option A : restaurer dans une nouvelle base
CREATE DATABASE appdb_restored OWNER appuser;
\q

# Option B : supprimer et recréer la base existante
# ATTENTION : perte définitive des données actuelles
# S'assurer qu'aucune connexion n'est active
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'appdb';  
DROP DATABASE appdb;  
CREATE DATABASE appdb OWNER appuser;  
\q
```

**Étape 3 — Restaurer les données.**

```bash
# Depuis un dump texte SQL
sudo -u postgres psql appdb < /backup/postgresql/appdb-2026-04-12.sql

# Depuis un dump texte compressé
gunzip -c /backup/postgresql/appdb-2026-04-12.sql.gz | sudo -u postgres psql appdb

# Depuis un dump format custom (recommandé — restauration sélective possible)
sudo -u postgres pg_restore -d appdb -v /backup/postgresql/appdb-2026-04-12.dump

# Depuis un dump format custom avec parallélisme (accélère la restauration)
sudo -u postgres pg_restore -d appdb -v -j 4 /backup/postgresql/appdb-2026-04-12.dump

# Restauration d'une seule table depuis un dump custom
sudo -u postgres pg_restore -d appdb -t ma_table /backup/postgresql/appdb-2026-04-12.dump
```

**Étape 4 — Vérifier la restauration.**

```bash
sudo -u postgres psql appdb

# Vérifier les tables
\dt

# Compter les lignes des tables principales
SELECT schemaname, relname, n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

# Tester une requête applicative
SELECT count(*) FROM users;

# Réindexer si nécessaire (après une restauration volumineuse)
REINDEX DATABASE appdb;

# Mettre à jour les statistiques
ANALYZE;

\q
```

La procédure pour **MariaDB** suit la même logique :

```bash
# Restauration depuis un dump SQL
mariadb -u root -p appdb < /backup/mysql/appdb-2026-04-12.sql

# Depuis un dump compressé
gunzip -c /backup/mysql/appdb-2026-04-12.sql.gz | mariadb -u root -p appdb

# Vérification
mariadb -u root -p -e "SELECT COUNT(*) FROM appdb.users;"
```

---

## Procédure 4 — Restauration d'un cluster etcd Kubernetes

### Prérequis

Un snapshot etcd valide. Accès root à au moins un nœud control plane. Certificats etcd intacts dans `/etc/kubernetes/pki/etcd/`.

### Contexte

Cette procédure restaure un cluster Kubernetes complet à partir d'un snapshot etcd. Elle est nécessaire en cas de corruption de la base etcd, de perte de quorum (majorité des membres indisponibles) ou de suppression accidentelle de ressources critiques.

**La restauration d'etcd ramène l'intégralité du cluster à l'état capturé par le snapshot.** Toutes les modifications effectuées après le snapshot sont perdues : pods créés, ConfigMaps modifiés, Secrets ajoutés. Cette procédure est un dernier recours.

### Étapes — Cluster single control plane

**Étape 1 — Arrêter les composants du control plane.**

```bash
# Déplacer les manifestes des pods statiques pour les arrêter
mkdir -p /tmp/k8s-backup  
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/k8s-backup/  
mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/k8s-backup/  
mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/k8s-backup/  
mv /etc/kubernetes/manifests/etcd.yaml /tmp/k8s-backup/  

# Attendre que les conteneurs s'arrêtent
crictl ps | grep -E "(apiserver|controller|scheduler|etcd)"
# Répéter jusqu'à ce que la liste soit vide (10-30 secondes).
```

**Étape 2 — Sauvegarder l'état actuel d'etcd (même corrompu, par précaution).**

```bash
cp -a /var/lib/etcd /var/lib/etcd.broken.$(date +%Y%m%d%H%M)
```

**Étape 3 — Restaurer le snapshot.**

```bash
# Supprimer l'ancien répertoire de données
rm -rf /var/lib/etcd

# Restaurer depuis le snapshot — utiliser etcdutl (etcdctl snapshot restore
# a été supprimé dans etcd 3.6, sortie le 15 mai 2025 ; il était déprécié
# depuis etcd 3.5). etcdutl opère directement sur les fichiers,
# sans connexion réseau.
etcdutl snapshot restore /backup/etcd-snapshot.db \
    --data-dir=/var/lib/etcd \
    --name=<nom-du-membre> \
    --initial-cluster=<nom>=https://<ip>:2380 \
    --initial-advertise-peer-urls=https://<ip>:2380

# Pour un cluster kubeadm single node, les valeurs typiques sont :
# --name=$(hostname)
# --initial-cluster=$(hostname)=https://127.0.0.1:2380
# --initial-advertise-peer-urls=https://127.0.0.1:2380

# Si seul etcdctl est disponible (anciennes versions), la syntaxe équivalente est :
# ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
#     --data-dir=/var/lib/etcd --name=... --initial-cluster=... \
#     --initial-advertise-peer-urls=...

# Rétablir les permissions
chown -R root:root /var/lib/etcd
```

**Étape 4 — Remettre en place les manifestes du control plane.**

```bash
mv /tmp/k8s-backup/*.yaml /etc/kubernetes/manifests/
```

**Étape 5 — Attendre le redémarrage et vérifier.**

```bash
# Attendre que les pods statiques redémarrent (30-60 secondes)
sleep 60

# Vérifier la connectivité
kubectl get nodes  
kubectl get pods -A  

# Vérifier la santé d'etcd
ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint health
```

**Étape 6 — Nettoyer les pods obsolètes.**

Après la restauration, certains pods peuvent référencer des ressources qui n'existent plus ou être dans un état incohérent. Les contrôleurs Kubernetes (Deployment, StatefulSet, DaemonSet) recréeront les pods nécessaires.

```bash
# Supprimer les pods en erreur
kubectl get pods -A | grep -vE "Running|Completed" | awk 'NR>1{print $1, $2}' | \
    xargs -r -n2 kubectl delete pod -n

# Vérifier que les Deployments convergent
kubectl get deployments -A
```

### Étapes — Cluster multi control plane (HA)

La restauration en HA est plus complexe car chaque membre etcd doit être restauré individuellement. La procédure complète est la suivante.

**Étape 1** — Arrêter etcd et les composants du control plane sur **tous** les nœuds control plane (même procédure que ci-dessus, répétée sur chaque nœud).

**Étape 2** — Sauvegarder et supprimer `/var/lib/etcd` sur **tous** les nœuds.

**Étape 3** — Restaurer le snapshot sur **chaque** nœud avec le `--name` et les `--initial-cluster` correspondant à la topologie complète du cluster.

```bash
# Sur le nœud cp1
etcdutl snapshot restore /backup/etcd-snapshot.db \
    --data-dir=/var/lib/etcd \
    --name=cp1 \
    --initial-cluster=cp1=https://10.0.0.1:2380,cp2=https://10.0.0.2:2380,cp3=https://10.0.0.3:2380 \
    --initial-advertise-peer-urls=https://10.0.0.1:2380

# Sur le nœud cp2
etcdutl snapshot restore /backup/etcd-snapshot.db \
    --data-dir=/var/lib/etcd \
    --name=cp2 \
    --initial-cluster=cp1=https://10.0.0.1:2380,cp2=https://10.0.0.2:2380,cp3=https://10.0.0.3:2380 \
    --initial-advertise-peer-urls=https://10.0.0.2:2380

# Sur le nœud cp3 (identique avec name=cp3 et son IP)
```

**Étape 4** — Remettre les manifestes et attendre la convergence sur **tous** les nœuds.

---

## Procédure 5 — Restauration d'un cluster Kubernetes avec Velero

### Prérequis

Velero installé. Accès au backend de stockage des sauvegardes (S3, GCS, MinIO). Un cluster Kubernetes fonctionnel (même vide).

### Contexte

Velero opère au niveau des ressources Kubernetes (manifestes YAML) et des volumes persistants. Il est complémentaire de la sauvegarde etcd : etcd sauvegarde l'état brut du cluster, Velero sauvegarde de manière sélective et permet une restauration granulaire par namespace, par type de ressource ou par label.

### Étapes

**Étape 1 — Vérifier les sauvegardes disponibles.**

```bash
velero backup get
# Vérifier le statut : Completed = sauvegarde utilisable

velero backup describe <nom-backup>
# Vérifier les namespaces inclus, les erreurs éventuelles

velero backup logs <nom-backup>
# Logs détaillés de la sauvegarde
```

**Étape 2 — Restaurer.**

```bash
# Restauration complète
velero restore create --from-backup <nom-backup>

# Restauration d'un namespace spécifique
velero restore create --from-backup <nom-backup> \
    --include-namespaces production

# Restauration de types de ressources spécifiques
velero restore create --from-backup <nom-backup> \
    --include-resources deployments,services,configmaps \
    --include-namespaces production

# Restauration avec remplacement des ressources existantes
velero restore create --from-backup <nom-backup> \
    --existing-resource-policy update
```

**Étape 3 — Suivre la restauration.**

```bash
velero restore get  
velero restore describe <nom-restore>  
velero restore logs <nom-restore>  

# Vérifier les ressources restaurées
kubectl get all -n <namespace>  
kubectl get pvc -n <namespace>  
```

**Étape 4 — Vérifier les volumes persistants.**

Si la sauvegarde inclut des snapshots de volumes (via un CSI plugin ou le provider Velero approprié), les PV sont recréés automatiquement. Vérifier que les PVC sont en état `Bound` et que les données sont accessibles.

```bash
kubectl get pvc -A  
kubectl get pv  
```

---

## Procédure 6 — Reconstruction d'un RAID dégradé

### Prérequis

Un disque de remplacement de capacité identique ou supérieure. Accès physique ou IPMI/iDRAC au serveur.

### Étapes

**Étape 1 — Identifier l'état du RAID et le disque défaillant.**

```bash
cat /proc/mdstat  
mdadm --detail /dev/md0  

# Identifier le disque en panne
mdadm --detail /dev/md0 | grep -E "(faulty|removed|spare)"  
smartctl -H /dev/sdb                     # Confirmer la défaillance  
```

**Étape 2 — Marquer le disque comme défaillant et le retirer (si non automatique).**

```bash
mdadm --manage /dev/md0 --fail /dev/sdb1  
mdadm --manage /dev/md0 --remove /dev/sdb1  

# Si plusieurs partitions RAID sur le même disque
mdadm --manage /dev/md1 --fail /dev/sdb2  
mdadm --manage /dev/md1 --remove /dev/sdb2  
```

**Étape 3 — Remplacer le disque physiquement.**

Éteindre le serveur si le hot-swap n'est pas supporté. Remplacer le disque. Redémarrer.

**Étape 4 — Préparer le nouveau disque.**

```bash
# Copier la table de partitions depuis le disque sain
sfdisk -d /dev/sda | sfdisk /dev/sdb

# Vérifier
fdisk -l /dev/sdb
```

**Étape 5 — Ajouter le nouveau disque au RAID.**

```bash
mdadm --manage /dev/md0 --add /dev/sdb1

# Si plusieurs partitions RAID
mdadm --manage /dev/md1 --add /dev/sdb2
```

**Étape 6 — Suivre la reconstruction.**

```bash
watch -n 5 cat /proc/mdstat
# Exemple :
# md0 : active raid1 sdb1[2] sda1[0]
#       1000000 blocks [2/1] [U_]
#       [=>...................]  recovery = 8.2% (82000/1000000) finish=12.3min speed=1234K/sec

# La reconstruction peut durer de quelques minutes à plusieurs heures.
# Le système reste fonctionnel mais avec des performances I/O réduites.
```

**Étape 7 — Finaliser.**

```bash
# Vérifier que le RAID est reconstruit
mdadm --detail /dev/md0
# State doit être "clean" ou "active", pas "degraded".

# Mettre à jour la configuration
mdadm --detail --scan > /etc/mdadm/mdadm.conf  
update-initramfs -u  

# Si le disque remplacé contenait un boot loader
grub-install /dev/sdb                    # Installer GRUB sur le nouveau disque
```

**Point de vérification** — `cat /proc/mdstat` montre `[UU]` pour tous les RAID. `mdadm --detail /dev/mdX` indique « State : clean » pour chaque grappe.

---

## Procédure 7 — Recovery après perte d'un nœud worker Kubernetes

### Contexte

Un nœud worker est définitivement perdu (panne matérielle, VM supprimée). Les pods qui y étaient hébergés doivent être re-schedulés.

### Étapes

**Étape 1 — Évaluer l'impact.**

```bash
# Identifier les pods sur le nœud perdu
kubectl get pods -A --field-selector=spec.nodeName=<nœud-perdu>

# Vérifier si des PV étaient attachés à ce nœud
kubectl get volumeattachment | grep <nœud-perdu>
```

**Étape 2 — Attendre ou forcer l'éviction.**

Par défaut, Kubernetes attend 5 minutes avant de re-scheduler les pods d'un nœud `NotReady`. Ce délai est désormais piloté par les tolerations injectées automatiquement par l'admission controller `DefaultTolerationSeconds` (`tolerationSeconds: 300` sur les taints `node.kubernetes.io/not-ready` et `node.kubernetes.io/unreachable`) — l'ancien flag `--pod-eviction-timeout` du controller-manager est déprécié depuis Kubernetes 1.13 et n'est plus pris en compte. Pour accélérer le processus :

```bash
# Supprimer le nœud du cluster
kubectl delete node <nœud-perdu>

# Les pods gérés par des contrôleurs (Deployment, StatefulSet, DaemonSet)
# sont automatiquement recréés sur d'autres nœuds.

# Les pods standalone (sans contrôleur) sont perdus et doivent être
# recréés manuellement.
```

**Étape 3 — Gérer les volumes persistants bloqués.**

```bash
# Si des PV étaient en mode RWO et attachés au nœud perdu
kubectl get volumeattachment
# Supprimer les attachements orphelins
kubectl delete volumeattachment <nom>

# Si des PVC sont en état Lost
kubectl get pv | grep Released
# Supprimer le claim ref pour permettre un nouveau binding
kubectl patch pv <nom> -p '{"spec":{"claimRef":null}}'
```

**Étape 4 — Provisionner un nouveau nœud si nécessaire.**

```bash
# Sur le nouveau nœud Debian
# Installer les prérequis (containerd, kubelet, kubeadm)
# Puis joindre le cluster
kubeadm token create --print-join-command  # Sur le control plane  
kubeadm join <ip>:6443 --token ... --discovery-token-ca-cert-hash ...  # Sur le nouveau nœud  
```

**Étape 5 — Vérifier la convergence.**

```bash
kubectl get nodes                        # Le nouveau nœud est Ready  
kubectl get pods -A | grep -vE "Running|Completed"  # Tous les pods convergent  
```

---

## Procédure 8 — Recovery après suppression accidentelle de ressources Kubernetes

### Contexte

Un `kubectl delete` a supprimé des ressources critiques (namespace entier, Deployment, Secret). Les données sont perdues dans etcd.

### Étapes selon la situation

**Cas 1 — GitOps en place (ArgoCD / Flux)**

La réconciliation automatique recrée les ressources supprimées dans les minutes qui suivent. Vérifier :

```bash
# ArgoCD
argocd app get <application>  
argocd app sync <application>  

# Flux
flux reconcile kustomization <nom>  
flux get kustomizations  
```

**Cas 2 — Sauvegarde Velero disponible**

Suivre la procédure 5 avec une restauration ciblée sur les ressources supprimées.

**Cas 3 — Aucun GitOps ni Velero, mais snapshot etcd récent**

Restaurer etcd (procédure 4). L'ensemble du cluster revient à l'état du snapshot, ce qui peut avoir des effets de bord sur d'autres ressources modifiées depuis.

**Cas 4 — Aucune sauvegarde**

Si les Deployments ont été supprimés mais que les PVC sont intacts, les données sont encore sur les volumes. Recréer les manifestes Kubernetes et pointer les PVC existants. Pour les Secrets, s'ils ne sont pas versionnés et qu'aucune sauvegarde n'existe, ils sont définitivement perdus et doivent être recréés (rotation des clés, nouveaux certificats, etc.).

**Prévention** — Mettre en place un workflow GitOps pour que toute la configuration soit versionnée dans Git. Configurer des sauvegardes Velero planifiées. Utiliser des `ResourceQuotas` et RBAC pour limiter les risques de suppression accidentelle. Le `--dry-run=client` avant tout `kubectl delete` à large portée est un réflexe essentiel.

---

## Procédure 9 — Réinstallation complète d'un serveur Debian

### Contexte

Le système est irrécupérable (disque système détruit, corruption totale). Les sauvegardes sont disponibles sur un support externe ou distant.

### Étapes

**Étape 1 — Installer un système Debian minimal.**

Installer Debian depuis le support d'installation en mode serveur (pas d'environnement de bureau). Configurer le partitionnement de manière identique au système original (consulter les runbooks ou la documentation d'architecture). Configurer le réseau et SSH pour l'accès à distance.

**Étape 2 — Restaurer la configuration système.**

```bash
# Si etckeeper était en place et le dépôt sauvegardé
cd /etc  
git init  
git remote add origin <url-du-depot-etckeeper>  
git fetch origin  
git checkout -f main                     # ou master selon la branche  

# Ou restaurer depuis borg/restic
borg extract $BORG_REPO::derniere-archive etc/
```

**Étape 3 — Réinstaller les paquets.**

Approche moderne recommandée — uniquement les paquets installés manuellement (les dépendances seront retirées automatiquement par APT) :

```bash
# Génération préventive sur un système sain
apt-mark showmanual > /backup/manual-packages.txt

# Restauration
xargs -a /backup/manual-packages.txt apt-get install -y
```

Approche legacy (dpkg/dselect) — restaure tout l'état exact des sélections, y compris les dépendances marquées explicitement :

```bash
# Génération préventive sur un système sain
dpkg --get-selections > /backup/package-selections.txt

# Restauration
dpkg --set-selections < /backup/package-selections.txt  
apt-get dselect-upgrade  
# Note : dselect-upgrade nécessite que l'« available database » soit à jour
# (`dpkg --update-avail` après un `apt-get update`).
```

L'approche `apt-mark showmanual` est plus concise et reflète l'intention de l'administrateur (paquets choisis explicitement), tandis que `dpkg --get-selections` capture l'état brut, plus lourd à reproduire si l'origine des paquets diffère.

**Étape 4 — Restaurer les données.**

Suivre les procédures 2 (borgbackup/restic) et 3 (bases de données) pour restaurer les données applicatives.

**Étape 5 — Restaurer les services.**

```bash
# Recharger la configuration systemd
systemctl daemon-reload

# Activer et démarrer les services
systemctl enable --now nginx postgresql ssh

# Vérifier chaque service
systemctl status nginx postgresql ssh
```

**Étape 6 — Validation complète.**

```bash
# Système
systemctl --failed  
journalctl -b -p err  

# Réseau
ss -tlnp                                # Ports en écoute  
curl -v https://localhost/               # Services web  

# Données
sudo -u postgres psql -c "SELECT count(*) FROM users;" appdb

# Sauvegardes
borg list $BORG_REPO                     # La sauvegarde est-elle configurée ?  
systemctl list-timers | grep backup      # Le timer est-il actif ?  
```

---

## Checklist post-recovery

Après toute opération de recovery, vérifier systématiquement les points suivants avant de considérer l'incident comme résolu.

**Intégrité des données** — Les données restaurées sont-elles complètes et cohérentes ? Les comptages de lignes en base de données correspondent-ils aux attentes ? Les fichiers critiques sont-ils présents et lisibles ?

**Services opérationnels** — Tous les services sont-ils actifs et fonctionnels ? Les health checks passent-ils ? Les utilisateurs ou applications clientes peuvent-ils accéder au service normalement ?

**Sauvegardes opérationnelles** — La chaîne de sauvegarde fonctionne-t-elle après la restauration ? Un nouveau backup a-t-il été lancé et s'est-il terminé avec succès ? C'est un point souvent oublié : une restauration peut modifier les chemins ou les permissions de manière à casser la sauvegarde automatique.

**Monitoring et alertes** — Le monitoring détecte-t-il le système restauré ? Les alertes qui ont été silenciées pendant l'incident sont-elles réactivées ? Les dashboards affichent-ils des métriques normales ?

**Redondance rétablie** — Si un RAID a été reconstruit, la resynchronisation est-elle terminée ? Si un nœud Kubernetes a été remplacé, les réplicas sont-ils distribués correctement ? Le système a-t-il retrouvé sa capacité à tolérer une nouvelle panne ?

**Documentation** — L'incident est-il documenté (symptômes, cause racine, actions, durée) ? Les runbooks doivent-ils être mis à jour ? Des actions préventives sont-elles identifiées ?

---

## Sauvegardes préventives — Ce qu'il faut avoir avant l'incident

Cette section récapitule les éléments qui doivent être sauvegardés **avant** qu'un incident ne survienne. Sans ces éléments, les procédures de recovery ci-dessus ne sont pas utilisables.

| Élément | Commande de sauvegarde | Fréquence recommandée |
|---------|----------------------|----------------------|
| Snapshot etcd | `etcdctl snapshot save /backup/etcd-$(date +%Y%m%d).db` | Quotidienne |
| Sauvegardes Velero | `velero schedule create daily --schedule="0 2 * * *"` | Quotidienne |
| Dump PostgreSQL | `pg_dump -Fc appdb > /backup/pg-$(date +%Y%m%d).dump` | Quotidienne |
| Dump MariaDB | `mysqldump --all-databases > /backup/mysql-$(date +%Y%m%d).sql` | Quotidienne |
| Configuration /etc | `etckeeper commit "backup"` ou `borg create` | Quotidienne |
| Liste des paquets | `dpkg --get-selections > /backup/packages.txt` | Hebdomadaire |
| Certificats TLS | Inclure `/etc/letsencrypt/` dans les sauvegardes borg/restic | Quotidienne |
| Secrets Kubernetes | `kubectl get secrets -A -o yaml > /backup/k8s-secrets.yaml` (chiffré) | Quotidienne |
| Clés SSH serveur | Inclure `/etc/ssh/ssh_host_*` dans les sauvegardes | Quotidienne |

Chaque sauvegarde doit être **testée régulièrement** par une restauration effective dans un environnement de test. Une sauvegarde qui n'a jamais été restaurée n'est pas une sauvegarde fiable : c'est un espoir.

⏭️ [Ressources et documentation](/annexes/D-ressources-documentation.md)
