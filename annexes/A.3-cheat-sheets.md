🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe A.3 — Cheat sheets par technologie

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Cette sous-annexe propose des **fiches de référence rapide** (cheat sheets) pour les technologies clés de la formation. Chaque fiche tient sur une à deux pages et regroupe les commandes essentielles dans un format compact, conçu pour être imprimé ou gardé à portée de main pendant le travail quotidien.

Les fiches ne détaillent pas les options (voir A.2 pour cela) : elles fournissent un accès instantané à la bonne commande au bon moment.

---

## Fiche 1 — Debian : administration système

### Paquets

```
apt update                          Mettre à jour l'index  
apt upgrade                         Mettre à jour les paquets  
apt full-upgrade                    Mise à jour avec changements de deps  
apt install <pkg>                   Installer  
apt remove <pkg>                    Désinstaller (garde la config)  
apt purge <pkg>                     Désinstaller (supprime la config)  
apt autoremove                      Nettoyer les orphelins  
apt search <terme>                  Rechercher un paquet  
apt show <pkg>                      Informations détaillées  
apt policy <pkg>                    Versions et priorités par dépôt  
apt list --installed                Paquets installés  
apt list --upgradable               Mises à jour disponibles  
dpkg -l                             Liste complète des paquets  
dpkg -L <pkg>                       Fichiers installés par un paquet  
dpkg -S <fichier>                   Quel paquet possède ce fichier ?  
dpkg -i <fichier.deb>               Installer un .deb local  
dpkg-reconfigure <pkg>              Reconfigurer un paquet  
```

### Services (systemd)

```
systemctl start|stop|restart <svc>  Contrôle du service  
systemctl reload <svc>              Recharger la config sans arrêt  
systemctl enable --now <svc>        Activer + démarrer  
systemctl disable --now <svc>       Désactiver + arrêter  
systemctl status <svc>              État détaillé  
systemctl is-active <svc>           Vérifier si actif  
systemctl is-enabled <svc>          Vérifier si activé au boot  
systemctl list-units --failed       Services en échec  
systemctl list-timers               Timers planifiés  
systemctl daemon-reload             Recharger les fichiers d'unité  
systemctl mask|unmask <svc>         Bloquer/débloquer un service  
systemctl cat <svc>                 Afficher le fichier d'unité  
```

### Logs (journald)

```
journalctl -u <svc>                 Logs d'un service  
journalctl -u <svc> -f              Suivi temps réel  
journalctl -b                       Démarrage courant  
journalctl -b -1                    Démarrage précédent  
journalctl -p err                   Erreurs et au-dessus  
journalctl --since "1 hour ago"     Filtrage temporel  
journalctl -o json-pretty           Sortie JSON  
journalctl --disk-usage             Espace utilisé  
journalctl --vacuum-time=30d        Purger les vieux logs  
```

### Utilisateurs et droits

```
adduser <user>                      Créer un utilisateur  
deluser --remove-home <user>        Supprimer avec son home  
usermod -aG <group> <user>          Ajouter à un groupe  
passwd <user>                       Changer le mot de passe  
chage -l <user>                     Politique de mot de passe  
id <user>                           UID, GID, groupes  
groups <user>                       Groupes d'un utilisateur  
chmod 750 <fichier>                 Permissions octales  
chmod u+x <fichier>                 Permission symbolique  
chown user:group <fichier>          Changer propriétaire  
setfacl -m u:<user>:rwx <fichier>   ACL étendue  
getfacl <fichier>                   Afficher les ACL  
visudo                              Éditer sudo en sécurité  
```

### Réseau

```
ip addr show                        Adresses IP  
ip -br -c addr                      Vue compacte colorée  
ip link set <if> up|down            Activer/désactiver interface  
ip route show                       Table de routage  
ip route get <ip>                   Route vers une destination  
ip neigh show                       Table ARP  
ss -tlnp                            Ports TCP en écoute + processus  
ss -ulnp                            Ports UDP en écoute  
ss -s                               Résumé statistique  
ping -c 4 <hôte>                    Test de connectivité  
traceroute <hôte>                   Trace du chemin réseau  
mtr <hôte>                          Traceroute interactif  
dig <domaine>                       Requête DNS  
dig +short <domaine>                Réponse DNS concise  
dig -x <ip>                         Reverse DNS  
tcpdump -i <if> port <port>         Capture réseau  
curl -v <url>                       Requête HTTP détaillée  
```

### Pare-feu

```
nft list ruleset                    Afficher les règles nftables  
ufw enable                          Activer le pare-feu  
ufw status verbose                  État et règles  
ufw allow <port>/tcp                Autoriser un port  
ufw deny <port>                     Bloquer un port  
ufw delete allow <port>             Supprimer une règle  
fail2ban-client status              État des jails  
fail2ban-client status sshd         Détails jail SSH  
```

### SSH

```
ssh user@host                       Connexion  
ssh -p <port> user@host             Port non standard  
ssh -J bastion user@cible           Via jump host  
ssh -L local:cible:distant user@h   Tunnel local  
ssh -R distant:cible:local user@h   Tunnel distant  
ssh-keygen -t ed25519               Générer une clé  
ssh-copy-id user@host               Déployer la clé publique  
```

### Disques et stockage

```
lsblk                               Arborescence des blocs  
lsblk -f                            Avec systèmes de fichiers  
blkid                                UUID et types  
fdisk -l                             Table de partitions  
df -h                                Espace disque par partition  
du -sh <dir>                         Taille d'un répertoire  
mount <dev> <point>                  Monter  
umount <point>                       Démonter  
findmnt                              Points de montage actifs  
```

### LVM — Aide-mémoire

```
pvcreate /dev/sdX                    Volume physique  
vgcreate vg0 /dev/sdX /dev/sdY      Groupe de volumes  
lvcreate -L 50G -n lv0 vg0          Volume logique  
lvextend -L +10G /dev/vg0/lv0       Agrandir  
resize2fs /dev/vg0/lv0              Étendre le FS (ext4)  
xfs_growfs /mnt/point               Étendre le FS (XFS)  
pvs / vgs / lvs                     Résumés rapides  
```

### RAID logiciel

```
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]1  
mdadm --detail /dev/md0              État du RAID  
cat /proc/mdstat                     Vue temps réel  
mdadm --manage /dev/md0 --add ...    Ajouter un disque  
mdadm --manage /dev/md0 --fail ...   Déclarer une panne  
```

### Processus

```
ps aux                               Tous les processus  
ps aux --sort=-%cpu | head           Top CPU  
top / htop                           Supervision temps réel  
kill <PID>                           Arrêt propre (SIGTERM)  
kill -9 <PID>                        Arrêt forcé (SIGKILL)  
kill -HUP <PID>                      Rechargement config  
killall <nom>                        Par nom de processus  
nice -n 10 <cmd>                     Priorité réduite  
renice -n -5 -p <PID>               Modifier la priorité  
```

### Sauvegarde

```
rsync -avz --delete src/ dst/        Miroir incrémental  
rsync -avzn src/ dst/                Simulation (dry-run)  
borg init --encryption=repokey repo  Initialiser borg  
borg create repo::archive /data      Sauvegarder  
borg list repo                       Lister les archives  
borg extract repo::archive           Restaurer  
borg prune --keep-daily=7 repo       Rotation  
restic -r repo init                  Initialiser restic  
restic -r repo backup /data          Sauvegarder  
restic -r repo snapshots             Lister les snapshots  
restic -r repo restore <id> -t /dst  Restaurer  
```

### Recherche de fichiers

```
find / -name "*.conf"                Par nom  
find / -type f -size +100M           Fichiers > 100 Mo  
find / -mtime -7                     Modifiés < 7 jours  
find / -user root -perm -4000        SetUID root  
find /tmp -mtime +30 -delete         Nettoyer les vieux fichiers  
find /etc -name "*.conf" -exec grep -l "motif" {} +  
```

### Traitement de texte — Essentiel

```
grep -rn "motif" /dir               Recherche récursive + n° ligne  
grep -v "^#" f | grep -v "^$"       Supprimer commentaires/vides  
sed 's/old/new/g' fichier           Substitution  
sed -i.bak 's/old/new/g' fichier    Substitution in-place + backup  
awk -F: '{print $1}' /etc/passwd    Extraire un champ  
awk '{sum+=$1} END {print sum}' f   Somme d'une colonne  
jq '.' fichier.json                 Formater du JSON  
jq -r '.key' fichier.json           Extraire une valeur  
sort fichier | uniq -c | sort -rn   Top des occurrences  
wc -l fichier                       Compter les lignes  
cut -d: -f1,3 /etc/passwd           Extraire des champs  
```

---

## Fiche 2 — Docker

### Images

```
docker build -t img:tag .            Construire une image  
docker build --no-cache -t img .     Sans cache  
docker build --target stage -t img . Multi-stage ciblé  
docker pull img:tag                  Télécharger  
docker push img:tag                  Publier  
docker tag src:tag dst:tag           Renommer / retagger  
docker image ls                      Lister les images  
docker image inspect img             Détails d'une image  
docker image prune                   Supprimer les inutilisées  
docker image prune -a                Supprimer toutes les non-utilisées  
docker history img:tag               Historique des couches  
```

### Conteneurs — Cycle de vie

```
docker run -d --name c -p 80:80 img  Lancer en arrière-plan  
docker run -it --rm img /bin/bash     Shell interactif temporaire  
docker run -v vol:/data img           Avec volume  
docker run -e VAR=val img             Avec variable d'env  
docker run --env-file .env img        Variables depuis fichier  
docker run --restart=unless-stopped   Politique de redémarrage  
docker run --memory=512m --cpus=1.5   Limites de ressources  
docker ps                             Conteneurs actifs  
docker ps -a                          Tous les conteneurs  
docker stop|start|restart <c>         Contrôle  
docker rm <c>                         Supprimer  
docker rm -f <c>                      Forcer la suppression  
docker rename <old> <new>             Renommer  
```

### Inspection et débogage

```
docker logs <c>                      Logs du conteneur  
docker logs -f --tail 100 <c>        Suivi temps réel  
docker exec -it <c> /bin/bash        Shell dans un conteneur  
docker inspect <c>                   Détails JSON complets  
docker stats                         Ressources temps réel  
docker top <c>                       Processus du conteneur  
docker diff <c>                      Fichiers modifiés  
docker cp <c>:/path ./local          Copier depuis le conteneur  
docker cp ./local <c>:/path          Copier vers le conteneur  
```

### Volumes

```
docker volume create <vol>           Créer  
docker volume ls                     Lister  
docker volume inspect <vol>          Détails  
docker volume rm <vol>               Supprimer  
docker volume prune                  Nettoyer les orphelins  
```

### Réseaux

```
docker network create <net>          Créer  
docker network ls                    Lister  
docker network inspect <net>         Détails  
docker network connect <net> <c>     Rattacher un conteneur  
docker network disconnect <net> <c>  Détacher un conteneur  
docker network prune                 Nettoyer  
```

### Docker Compose

```
docker compose up -d                 Démarrer la stack  
docker compose down                  Arrêter et supprimer  
docker compose down -v               Idem + supprimer les volumes  
docker compose ps                    État des services  
docker compose logs -f <svc>         Logs d'un service  
docker compose exec <svc> bash       Shell dans un service  
docker compose build                 Reconstruire les images  
docker compose pull                  Mettre à jour les images  
docker compose config                Valider la configuration  
docker compose top                   Processus de tous les services  
docker compose restart <svc>         Redémarrer un service  
```

### Nettoyage

```
docker system df                     Utilisation de l'espace  
docker system prune                  Nettoyer (conteneurs, images, réseaux)  
docker system prune -a --volumes     Nettoyage complet  
docker container prune               Conteneurs arrêtés  
docker image prune -a                Images non utilisées  
docker volume prune                  Volumes orphelins  
docker network prune                 Réseaux inutilisés  
```

### Dockerfile — Instructions principales

```
FROM debian:trixie-slim              Image de base (Debian 13, stable depuis août 2025)  
WORKDIR /app                         Répertoire de travail  
COPY . .                             Copier des fichiers  
COPY --from=builder /app/bin .       Copier depuis un autre stage  
RUN apt-get update && \  
    apt-get install -y --no-install-recommends pkg && \
    rm -rf /var/lib/apt/lists/*      Installer + nettoyer en 1 couche
ENV APP_PORT=8080                    Variable d'environnement  
ARG VERSION=1.0                      Argument de build  
EXPOSE 8080                          Port documenté  
USER 1000:1000                       Utilisateur non-root  
ENTRYPOINT ["./app"]                 Point d'entrée fixe  
CMD ["--config", "/etc/app.yaml"]    Arguments par défaut  
HEALTHCHECK --interval=30s \  
    CMD curl -f http://localhost:8080/health || exit 1
```

### Podman — Équivalences

```
podman run / build / ps / logs       Syntaxe identique à Docker  
podman pod create --name <pod>       Créer un pod  
podman pod ps                        Lister les pods  
podman system migrate                Migrer depuis Docker  
podman unshare                       Shell dans le user namespace  

# Intégration systemd : préférer Quadlet (déclaratif) à podman generate systemd
# (déprécié, plus de nouvelles fonctionnalités)
/etc/containers/systemd/             Quadlet système (*.container, *.kube...)
~/.config/containers/systemd/        Quadlet utilisateur (rootless)
systemctl daemon-reload              Régénère les unités après édition d'un Quadlet
```

---

## Fiche 3 — Kubernetes (kubectl)

### Commandes fondamentales

```
kubectl get <type>                   Lister des ressources  
kubectl get <type> -o wide           Vue étendue  
kubectl get <type> -o yaml           Manifeste YAML  
kubectl get all -n <ns>              Toutes les ressources  
kubectl get all -A                   Tous les namespaces  
kubectl describe <type> <nom>        Détails et événements  
kubectl explain <type>               Documentation du type  
kubectl explain <type>.spec.field    Documentation d'un champ  
kubectl api-resources                Types disponibles  
```

### Types de ressources courants

```
pods         po      Unité d'exécution de base  
services     svc     Exposition réseau  
deployments  deploy  Gestion déclarative des pods  
replicasets  rs      Maintien du nombre de réplicas  
statefulsets sts     Pods avec identité stable  
daemonsets   ds      Un pod par nœud  
configmaps   cm      Configuration non sensible  
secrets                Configuration sensible  
ingresses    ing     Routage HTTP externe  
persistentvolumeclaims pvc  Demande de stockage  
namespaces   ns      Isolation logique  
nodes        no      Nœuds du cluster  
jobs                   Tâche ponctuelle  
cronjobs     cj      Tâche planifiée  
```

### Création et modification

```
kubectl apply -f manifest.yaml       Créer / mettre à jour  
kubectl apply -f dir/                Appliquer un répertoire  
kubectl apply -k overlays/prod/      Via Kustomize  
kubectl create ns <ns>               Créer un namespace  
kubectl edit <type> <nom>            Éditer en live  
kubectl patch <type> <nom> -p 'json' Modification partielle  
kubectl scale deploy <nom> --replicas=5  
kubectl set image deploy/<nom> ctr=img:tag  
kubectl rollout status deploy/<nom>  Suivi du déploiement  
kubectl rollout undo deploy/<nom>    Rollback  
kubectl rollout history deploy/<nom> Historique  
kubectl annotate <type> <nom> k=v    Ajouter une annotation  
kubectl label <type> <nom> k=v       Ajouter un label  
```

### Suppression

```
kubectl delete -f manifest.yaml      Par manifeste  
kubectl delete <type> <nom>          Par nom  
kubectl delete <type> --all -n <ns>  Tout dans un namespace  
kubectl delete <type> -l app=X       Par label  
```

### Débogage

```
kubectl logs <pod>                   Logs du pod  
kubectl logs -f <pod>                Suivi temps réel  
kubectl logs --previous <pod>        Logs du crash précédent  
kubectl logs -l app=X --prefix       Multi-pods avec préfixe  
kubectl logs <pod> -c <ctr>          Conteneur spécifique  
kubectl exec -it <pod> -- /bin/sh    Shell dans le pod  
kubectl debug <pod> --image=busybox  Conteneur éphémère  
kubectl port-forward <pod> 8080:80   Redirection de port  
kubectl port-forward svc/<s> 8080:80 Via un service  
kubectl get events --sort-by=.metadata.creationTimestamp  
kubectl top pods                     Consommation CPU/mém  
kubectl top nodes                    Ressources par nœud  
kubectl describe pod <pod>           Détails + événements  
```

### Gestion des nœuds

```
kubectl get nodes                    Lister les nœuds  
kubectl describe node <n>            Détails d'un nœud  
kubectl cordon <n>                   Empêcher le scheduling  
kubectl uncordon <n>                 Autoriser le scheduling  
kubectl drain <n> --ignore-daemonsets --delete-emptydir-data  
kubectl taint nodes <n> k=v:effet    Ajouter un taint  
kubectl taint nodes <n> k:effet-     Supprimer un taint  
```

### Contexte et configuration

```
kubectl config get-contexts          Lister les contextes  
kubectl config current-context       Contexte actif  
kubectl config use-context <ctx>     Changer de contexte  
kubectl config set-context --current --namespace=<ns>  
kubectl cluster-info                 Informations du cluster  
kubectl version                      Version client + serveur  
```

### RBAC

```
kubectl auth can-i <verb> <res>      Vérifier une permission  
kubectl auth can-i --list             Toutes les permissions  
kubectl auth can-i create pods --as=user --namespace=ns  
kubectl create role <nom> --verb=get,list --resource=pods  
kubectl create rolebinding <nom> --role=<role> --user=<user>  
kubectl create clusterrole ...       Rôle global  
kubectl create clusterrolebinding ...  
```

### Filtrage et sélection

```
-n <ns>                              Namespace spécifique
-A                                   Tous les namespaces
-l app=nginx                         Par label
-l 'env in (prod,staging)'           Label avec opérateur
--field-selector status.phase=Running  Par champ
--sort-by=.metadata.creationTimestamp  Tri
-o jsonpath='{.items[*].metadata.name}'
-o custom-columns=NOM:.metadata.name,STATUS:.status.phase
```

### kubeadm

```
kubeadm init --pod-network-cidr=...  Initialiser le cluster  
kubeadm join <ip>:<port> --token ... Rejoindre le cluster  
kubeadm token create --print-join-command  
kubeadm upgrade plan                 Vérifier les mises à jour  
kubeadm upgrade apply <version>      Appliquer la mise à jour  
kubeadm reset                        Réinitialiser un nœud  
kubeadm certs check-expiration       État des certificats  
kubeadm certs renew all              Renouveler tous les certificats  
```

### crictl (runtime CRI)

```
crictl ps [-a]                       Conteneurs (-a inclut les arrêtés)  
crictl pods                          Pods gérés par le runtime  
crictl images                        Images locales  
crictl logs [-f] <container-id>      Logs d'un conteneur  
crictl exec -it <id> /bin/sh         Shell dans un conteneur  
crictl inspect <id>                  Détails JSON  
crictl pull <image>                  Tester l'accès registry  
crictl rmi --prune                   Nettoyer les images orphelines  
crictl info                          État du runtime  
```

### Outils productivité kubectl

```
k9s                                  TUI de navigation/diagnostic du cluster  
k9s -n <ns>                          Démarrer dans un namespace  
stern <regex>                        Logs multi-pods en temps réel  
stern -l app=nginx                   Par sélecteur de labels  
kubectx [<contexte>]                 Lister / basculer entre contextes  
kubens [<namespace>]                 Lister / basculer entre namespaces  
kubectl krew install <plugin>        Installer un plugin krew  
kubectl tree <type>/<nom>            (plugin) Arbre de dépendances  
kubectl neat -                       (plugin) Manifeste sans champs auto-générés  
```

### Helm (3 et 4)

> Helm 4 (sortie nov. 2025) introduit le **Server-Side Apply** : la même CLI ci-dessous,  
> avec une exécution déléguée à l'API server K8s plutôt qu'un three-way merge côté client.  
> Helm 3 entre en EOL fin 2026 (corrections de sécurité jusqu'au 11 novembre 2026).

```
helm repo add <nom> <url>            Ajouter un dépôt  
helm repo update                     Mettre à jour l'index  
helm search repo <terme>             Rechercher  
helm install <rel> <chart>           Installer  
helm install <rel> <chart> -f val.yaml  Avec valeurs custom  
helm upgrade <rel> <chart>           Mettre à jour  
helm upgrade --install <rel> <chart> Installer ou mettre à jour  
helm rollback <rel> <rev>            Retour arrière  
helm list [-A]                       Lister les releases  
helm uninstall <rel>                 Supprimer  
helm template <chart> -f val.yaml    Rendu local (sans apply)  
helm show values <chart>             Valeurs par défaut  
helm get values <rel>                Valeurs d'une release  
helm history <rel>                   Historique des révisions  
helm lint ./chart                    Vérifier un chart  
helm version                         Numéro de version installé (3.x ou 4.x)  
```

### etcdctl / etcdutl

```
etcdctl member list                  Membres du cluster  
etcdctl endpoint health              Santé des endpoints  
etcdctl endpoint status -w table     État détaillé  
etcdctl snapshot save snap.db        Sauvegarde (réseau)  
etcdutl snapshot restore snap.db     Restauration (hors ligne)  
                                     etcdctl snapshot restore : déprécié 3.5,
                                     supprimé en 3.6 (sortie 15 mai 2025).
                                     Idem pour snapshot status.
```

### Velero

```
velero backup create <nom>           Sauvegarder (snapshots CSI par défaut)  
velero backup create <nom> --default-volumes-to-fs-backup  
                                     + sauvegarde fichier (Kopia ou Restic)
velero backup create <nom> --selector app=<label>  
velero backup describe <nom>         Détails  
velero backup logs <nom>             Logs de la sauvegarde  
velero restore create --from-backup <nom>  
velero restore create --from-backup <nom> --existing-resource-policy update  
velero schedule create <nom> --schedule="@daily" --ttl 168h0m0s  
velero schedule pause|unpause <nom>  Suspendre/reprendre une planif  
velero backup-location get           Emplacements configurés  
```

---

## Fiche 4 — Terraform / OpenTofu

> Toutes les commandes ci-dessous sont identiques en remplaçant `terraform` par `tofu`  
> (OpenTofu, fork open source MPL 2.0 maintenu par la Linux Foundation depuis le passage  
> de Terraform sous BSL en août 2023 — drop-in replacement de Terraform 1.5.x).

### Workflow principal

```
terraform init                       Initialiser le répertoire  
terraform init -upgrade              Mettre à jour les providers  
terraform validate                   Vérifier la syntaxe  
terraform fmt -recursive             Formater le code  
terraform plan                       Prévisualiser les changements  
terraform plan -out=plan.tfplan      Enregistrer le plan  
terraform apply plan.tfplan          Appliquer le plan enregistré  
terraform apply -auto-approve        Appliquer sans confirmation  
terraform destroy                    Détruire l'infrastructure  
terraform destroy -target=res.nom    Détruire une ressource  
```

### État (state)

```
terraform state list                 Lister les ressources  
terraform state show <res>           Détails d'une ressource  
terraform state mv <old> <new>       Renommer dans l'état  
terraform state rm <res>             Retirer de l'état  
terraform state pull                 Télécharger l'état  
terraform state push                 Envoyer l'état  
terraform import <res> <id>          Importer une ressource  
terraform refresh                    Rafraîchir l'état  
```

### Variables et sorties

```
terraform plan -var="key=value"      Variable en ligne  
terraform plan -var-file=prod.tfvars Fichier de variables  
terraform output                     Toutes les sorties  
terraform output -json               Sorties en JSON  
terraform output <nom>               Une sortie spécifique  
terraform console                    Console interactive  
```

### Workspaces

```
terraform workspace list             Lister les workspaces  
terraform workspace new <nom>        Créer  
terraform workspace select <nom>     Activer  
terraform workspace show             Workspace actif  
terraform workspace delete <nom>     Supprimer  
```

### Débogage et outils

```
terraform graph | dot -Tpng > g.png  Graphe de dépendances  
terraform providers                  Providers utilisés  
terraform version                    Version installée  
TF_LOG=DEBUG terraform plan          Activer le debug  
TF_LOG_PATH=tf.log terraform plan    Logs dans un fichier  
```

### Blocs HCL — Aide-mémoire syntaxique

```hcl
# Provider
provider "aws" {
  region = "eu-west-3"
}

# Ressource
resource "aws_instance" "web" {
  ami           = "ami-xxxx"
  instance_type = var.instance_type
  tags = { Name = "web-${terraform.workspace}" }
}

# Variable
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Type d'instance EC2"
  validation {
    condition     = contains(["t3.micro","t3.small"], var.instance_type)
    error_message = "Type non autorisé."
  }
}

# Output
output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "IP publique du serveur"
}

# Data source
data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]   # Trixie ; "debian-12-amd64-*" pour Bookworm
  }
  owners = ["136693071363"]          # ID du compte Debian officiel
}

# Locals
locals {
  env_prefix = "${var.project}-${terraform.workspace}"
}

# Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  cidr    = "10.0.0.0/16"
}

# Backend
terraform {
  backend "s3" {
    bucket       = "tf-state"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-3"
    encrypt      = true
    use_lockfile = true                # Lock natif S3 (TF 1.10+ / OpenTofu 1.8+)
  }                                     # remplace dynamodb_table déprécié en TF 1.11
}

# Boucles et conditions
count         = var.enabled ? 1 : 0  
for_each      = toset(var.instances)  
dynamic "tag" { ... }  
```

### Fonctions courantes

```
length(var.list)                     Longueur  
lookup(map, key, default)            Recherche dans une map  
merge(map1, map2)                    Fusionner des maps  
concat(list1, list2)                 Concaténer des listes  
join(",", var.list)                  Joindre en chaîne  
split(",", var.string)               Découper une chaîne  
format("prefix-%s", var.name)        Formatage  
file("${path.module}/script.sh")     Lire un fichier  
templatefile("tpl.sh", {v = val})    Template avec variables  
cidrsubnet("10.0.0.0/16", 8, 1)     Calcul de sous-réseau  
toset / tolist / tomap               Conversions de types  
try(expr, default)                   Valeur par défaut si erreur  
coalesce(val1, val2)                 Premier non-null  
flatten([[1,2],[3]])                 Aplatir des listes  
keys(map) / values(map)              Clés / valeurs d'une map  
```

---

## Fiche 5 — Ansible

### Commandes principales

```
ansible <group> -m ping              Tester la connectivité  
ansible <group> -m shell -a "cmd"    Exécuter une commande  
ansible <group> -m setup             Collecter les facts  
ansible <group> -m copy -a "src=... dest=..."  
ansible-playbook playbook.yaml       Exécuter un playbook  
ansible-playbook pb.yaml --check     Simulation (dry-run)  
ansible-playbook pb.yaml --diff      Afficher les différences  
ansible-playbook pb.yaml --check --diff  Combo classique  
ansible-playbook pb.yaml -l host1    Limiter à un hôte  
ansible-playbook pb.yaml --tags cfg  Par tag  
ansible-playbook pb.yaml --skip-tags test  
ansible-playbook pb.yaml -e "k=v"   Variables supplémentaires  
ansible-playbook pb.yaml -e @vars.yaml  
ansible-playbook pb.yaml -v/-vvv    Verbosité  
ansible-playbook pb.yaml --list-tasks  Lister les tâches  
ansible-playbook pb.yaml --list-hosts  Lister les hôtes ciblés  
ansible-playbook pb.yaml --step      Pas à pas interactif  
ansible-playbook pb.yaml --start-at-task="Nom"  
ansible-playbook pb.yaml --forks=20  Parallélisme  
```

### Inventaire

```
ansible-inventory --list             Afficher l'inventaire  
ansible-inventory --graph            Vue arborescente  
ansible-inventory --host <host>      Variables d'un hôte  
```

### Vault (chiffrement)

```
ansible-vault create fichier.yaml    Créer un fichier chiffré  
ansible-vault encrypt fichier.yaml   Chiffrer un fichier existant  
ansible-vault decrypt fichier.yaml   Déchiffrer  
ansible-vault edit fichier.yaml      Éditer en place  
ansible-vault rekey fichier.yaml     Changer le mot de passe  
ansible-vault view fichier.yaml      Afficher sans déchiffrer  
ansible-playbook pb.yaml --ask-vault-pass  
ansible-playbook pb.yaml --vault-password-file=.vault_pass  
```

### Galaxy (rôles et collections)

```
ansible-galaxy install <role>        Installer un rôle  
ansible-galaxy install -r requirements.yaml  
ansible-galaxy collection install <coll>  
ansible-galaxy list                  Rôles installés  
ansible-galaxy init <role>           Créer un squelette de rôle  
```

### Playbook — Aide-mémoire syntaxique

```yaml
---
# Structure d'un playbook
- name: Configurer les serveurs web
  hosts: webservers
  become: true                          # Élévation de privilèges
  vars:
    http_port: 80
    app_version: "1.5.0"
  vars_files:
    - vars/secrets.yaml

  pre_tasks:
    - name: Mettre à jour le cache apt
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

  roles:
    - common
    - role: nginx
      vars:
        listen_port: "{{ http_port }}"

  tasks:
    - name: Installer les paquets
      ansible.builtin.apt:
        name: "{{ item }}"
        state: present
      loop:
        - nginx
        - certbot

    - name: Copier la configuration
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: Recharger nginx

    - name: Vérifier que le service tourne
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true

    - name: Tâche conditionnelle
      ansible.builtin.command: /usr/local/bin/setup.sh
      when: app_version is version('1.5', '>=')
      register: setup_result
      changed_when: "'configured' in setup_result.stdout"
      failed_when: setup_result.rc > 1

    - name: Boucle sur dictionnaire
      ansible.builtin.user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
      loop:
        - { name: alice, groups: developers }
        - { name: bob, groups: ops }

    - name: Bloquer avec rescue
      block:
        - name: Tâche risquée
          ansible.builtin.command: /opt/migrate.sh
      rescue:
        - name: En cas d'échec
          ansible.builtin.command: /opt/rollback.sh
      always:
        - name: Toujours exécuté
          ansible.builtin.debug:
            msg: "Migration terminée"

  handlers:
    - name: Recharger nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
```

### Modules les plus utilisés

```
ansible.builtin.apt                  Gestion des paquets Debian  
ansible.builtin.service              Contrôle des services  
ansible.builtin.systemd              Contrôle systemd  
ansible.builtin.copy                 Copie de fichiers  
ansible.builtin.template             Templates Jinja2  
ansible.builtin.file                 Fichiers et répertoires  
ansible.builtin.lineinfile           Modifier une ligne  
ansible.builtin.blockinfile          Insérer un bloc  
ansible.builtin.user                 Gestion des utilisateurs  
ansible.builtin.group                Gestion des groupes  
ansible.builtin.command              Exécuter une commande  
ansible.builtin.shell                Commande via shell  
ansible.builtin.script               Exécuter un script local  
ansible.builtin.cron                 Tâches planifiées  
ansible.builtin.get_url              Téléchargement HTTP  
ansible.builtin.uri                  Requêtes HTTP/API  
ansible.builtin.unarchive            Extraction d'archives  
ansible.builtin.git                  Opérations Git  
ansible.builtin.debug                Afficher un message/variable  
ansible.builtin.assert               Vérifier une condition  
ansible.builtin.wait_for             Attendre un état  
ansible.builtin.stat                 Informations sur un fichier  
ansible.builtin.set_fact             Définir des variables  
ansible.builtin.include_tasks        Inclure des tâches  
ansible.builtin.import_role          Importer un rôle  
ansible.posix.firewalld              Pare-feu firewalld  
community.general.ufw                Pare-feu UFW  
community.docker.docker_container    Conteneurs Docker  
kubernetes.core.k8s                  Ressources Kubernetes  
```

### Jinja2 — Filtres et syntaxes courants

```
{{ variable }}                       Interpolation
{{ variable | default("val") }}      Valeur par défaut
{{ list | join(",") }}               Joindre une liste
{{ string | upper / lower }}         Casse
{{ string | replace("a","b") }}      Remplacement
{{ string | regex_replace(p,r) }}    Regex
{{ path | basename / dirname }}      Chemin
{{ dict | to_json / to_yaml }}       Sérialisation
{{ list | length }}                   Longueur
{{ list | first / last }}            Premier / dernier
{{ list | map(attribute='name') }}   Extraction
{{ list | selectattr('k','eq','v') }}  Filtrage
{{ number | int / float }}           Conversion

{% if condition %}...{% endif %}      Condition
{% for item in list %}...{% endfor %} Boucle
{% if loop.first %}...{% endif %}    Premier tour
{# commentaire #}                    Commentaire
```

---

## Fiche 6 — CI/CD et GitOps

### ArgoCD

```
argocd login <server>                Connexion  
argocd app create <app> \  
  --repo <url> --path <dir> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace <ns>              Créer une application
argocd app list                      Lister les applications  
argocd app get <app>                 État détaillé  
argocd app sync <app>                Synchroniser  
argocd app diff <app>                Voir les écarts  
argocd app history <app>             Historique  
argocd app rollback <app> <rev>      Retour arrière  
argocd app delete <app>              Supprimer  
argocd repo add <url>                Ajouter un dépôt  
argocd proj list                     Lister les projets  
```

### Flux

```
flux bootstrap github \
  --owner=<org> --repository=<repo> \
  --path=clusters/prod               Installation
flux get kustomizations              État des kustomizations  
flux get helmreleases                État des Helm releases  
flux get sources git                 État des sources Git  
flux reconcile kustomization <nom>   Forcer la synchro  
flux reconcile source git <nom>      Rafraîchir la source  
flux suspend kustomization <nom>     Suspendre  
flux resume kustomization <nom>      Reprendre  
flux logs --level=error              Logs filtrés  
flux uninstall                       Désinstaller  
```

### Tekton

```
tkn pipeline list                    Lister les pipelines  
tkn pipeline start <nom>             Lancer un pipeline  
tkn pipelinerun list                 Exécutions  
tkn pipelinerun logs <nom>           Logs d'une exécution  
tkn pipelinerun cancel <nom>         Annuler  
tkn task list                        Lister les tâches  
tkn task start <nom>                 Lancer une tâche  
tkn taskrun list                     Exécutions de tâches  
tkn hub search <terme>               Rechercher sur le Hub  
```

### Gestion des secrets GitOps

```
kubeseal --format yaml \
  < secret.yaml > sealed.yaml        Chiffrer avec Sealed Secrets
kubeseal --fetch-cert > cert.pem     Récupérer le certificat

sops --encrypt -i secret.yaml        Chiffrer avec SOPS  
sops --decrypt secret.yaml           Déchiffrer  
sops secret.yaml                     Éditer en place  
```

---

## Fiche 7 — Observabilité

### Prometheus

```
promtool check config prometheus.yml Valider la configuration  
promtool check rules rules/*.yml     Valider les règles  
promtool tsdb analyze /data          Analyser la TSDB  
```

### PromQL — Requêtes essentielles

```
# Valeur instantanée
node_cpu_seconds_total

# Sélection par labels
node_cpu_seconds_total{mode="idle",instance="srv01:9100"}

# Taux de variation sur 5 minutes
rate(http_requests_total[5m])

# Somme par label
sum by (instance) (rate(http_requests_total[5m]))

# Moyenne
avg without (cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))

# Top 5 par utilisation CPU
topk(5, sum by (instance) (rate(node_cpu_seconds_total{mode!="idle"}[5m])))

# Pourcentile 95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Alerting : utilisation disque > 80%
(node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 20

# Taux d'erreur
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m])) * 100

# Prédiction linéaire (espace disque dans 24h)
predict_linear(node_filesystem_avail_bytes[6h], 24*3600)
```

### AlertManager

```
amtool check-config alertmanager.yml Valider la configuration  
amtool alert query                   Alertes actives  
amtool silence add matcher           Créer un silence  
amtool silence query                 Silences actifs  
amtool silence expire <id>           Supprimer un silence  
```

### Loki / LogQL

```
{job="nginx"}                        Sélection de flux
{namespace="prod"} |= "error"        Filtrage par contenu
{app="api"} |~ "status=[45].."       Regex
{app="api"} | json | status >= 400   Parsing JSON + filtre
count_over_time({job="syslog"}[1h])  Comptage sur 1 heure  
rate({job="nginx"}[5m])              Taux de logs par seconde  
sum by (level) (count_over_time(  
  {app="api"} | logfmt [5m]))        Agrégation par niveau
```

---

## Fiche 8 — Sécurité

### AppArmor

```
aa-status                            État des profils  
aa-enforce /etc/apparmor.d/<profil>  Mode enforce  
aa-complain /etc/apparmor.d/<profil> Mode complain (log only)  
aa-disable /etc/apparmor.d/<profil>  Désactiver  
apparmor_parser -r <profil>          Recharger un profil  
aa-genprof <programme>               Générer un profil  
aa-logprof                           Mettre à jour depuis les logs  
```

### Audit et hardening

```
lynis audit system                   Audit CIS complet  
lynis show details <test-id>         Détails d'un test  
sysctl -a                            Tous les paramètres noyau  
sysctl -w param=value                Modifier à chaud  
sysctl -p /etc/sysctl.d/99-custom.conf  Appliquer un fichier  
```

### Vault / OpenBao

> Toutes les commandes ci-dessous sont identiques avec la CLI `bao` (OpenBao 2.5+, fork  
> open source MPL 2.0 de Vault, Linux Foundation, drop-in pour Vault 1.14.x — créé après  
> le passage de HashiCorp sous BSL en août 2023).

```
vault operator init                  Initialisation  
vault operator unseal                Déverrouillage  
vault status                         État  
vault kv put secret/app key=val      Écrire un secret  
vault kv get secret/app              Lire un secret  
vault kv get -field=key secret/app   Lire un champ  
vault kv list secret/                Lister les chemins  
vault kv delete secret/app           Supprimer  
vault token create -policy=<pol>     Créer un token  
vault token lookup                   Info du token courant  
vault auth enable kubernetes         Activer auth K8s  
vault policy write <nom> policy.hcl  Créer une policy  
```

### Scanning et signatures

```
trivy image <img>                    Scanner une image  
trivy image --severity CRITICAL <img>  
trivy image --ignore-unfixed <img>   CVE corrigées uniquement  
trivy fs .                           Scanner le filesystem  
trivy repo <git-url>                 Scanner un dépôt distant  
trivy config terraform/              Scanner IaC (misconfigurations)  
trivy k8s --report summary cluster   Scanner un cluster  
trivy fs --scanners secret .         Détecter des secrets en clair  
trivy image --format cyclonedx -o sbom.json <img>  
                                     Générer un SBOM CycloneDX
grype <img>                          Scanner (alternatif)  
grype <img> --only-fixed             Avec correctifs dispo  
grype sbom:./sbom.spdx.json          Scanner depuis un SBOM  

cosign generate-key-pair             Générer clés (mode classique)  
cosign sign --key cosign.key <img>@<digest>  
cosign verify --key cosign.pub <img> Vérifier  
# Mode keyless (recommandé depuis Cosign 2.x, par défaut en 3.x)
cosign sign <img>@<digest>           Signature OIDC (Fulcio + Rekor)  
cosign verify --certificate-identity <email> \  
  --certificate-oidc-issuer <issuer> <img>
# Cosign 3.x : --bundle <fichier.json> obligatoire pour le nouveau
# format Sigstore Bundle (matériel de vérification consolidé).
cosign attest --predicate sbom.json --type spdx <img>
                                     Attestation SLSA / SBOM
```

### Kubernetes — Sécurité

```
# Pod Security Standards (les trois labels peuvent coexister, niveaux possibles :
# privileged, baseline, restricted ; PodSecurityPolicy est supprimée depuis K8s 1.25)
kubectl label ns <ns> \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

# Network Policies
kubectl get networkpolicy -n <ns>  
kubectl describe networkpolicy <nom> -n <ns>  

# RBAC vérification rapide
kubectl auth can-i create pods --as=system:serviceaccount:<ns>:<sa>  
kubectl auth can-i '*' '*' --as=admin  # Test admin  
```

---

## Fiche 9 — Cloud CLI

### AWS CLI

```
aws configure                        Configuration initiale  
aws sts get-caller-identity          Qui suis-je ?  
aws ec2 describe-instances           Lister les instances  
aws ec2 run-instances --image-id ... Lancer une instance  
aws s3 ls                            Lister les buckets  
aws s3 cp file s3://bucket/          Upload  
aws s3 sync dir/ s3://bucket/dir/    Synchroniser  
aws eks list-clusters                Clusters EKS  
aws eks update-kubeconfig --name <c> Configurer kubectl  
aws iam list-users                   Utilisateurs IAM  
aws logs tail /aws/lambda/<fn> -f    Logs CloudWatch  
```

### Google Cloud (gcloud)

```
gcloud init                          Configuration initiale  
gcloud auth login                    Authentification  
gcloud config set project <id>       Sélectionner un projet  
gcloud compute instances list        Lister les instances  
gcloud compute instances create ...  Créer une instance  
gcloud container clusters list       Clusters GKE  
gcloud container clusters get-credentials <c>  
gcloud storage ls                    Lister les buckets  
gcloud storage cp file gs://bucket/  Upload  
gcloud iam service-accounts list     Comptes de service  
gcloud logging read "severity>=ERROR" --limit=50  
```

### Azure CLI

```
az login                             Authentification  
az account list                      Abonnements  
az account set -s <sub>              Sélectionner  
az vm list -o table                  Lister les VM  
az vm create --resource-group ...    Créer une VM  
az aks list -o table                 Clusters AKS  
az aks get-credentials -g <rg> -n <c>  
az storage blob list -c <container>  Lister les blobs  
az storage blob upload -c <c> -f <f> -n <nom>  
az ad user list                      Utilisateurs Azure AD  
az monitor log-analytics query ...   Requêtes de logs  
```

---

## Fiche 10 — Service Mesh

### Istio

```
istioctl install --set profile=demo  Installation  
istioctl install --set profile=minimal  Production  
istioctl verify-install              Vérifier l'installation  
istioctl analyze                     Analyser la configuration  
istioctl analyze -n <ns>             Analyser un namespace  
istioctl proxy-status                État de tous les sidecars  
istioctl proxy-config routes <pod>   Config de routage  
istioctl proxy-config clusters <pod> Clusters Envoy  
istioctl proxy-config listeners <pod>  
istioctl dashboard kiali             Ouvrir Kiali  
istioctl dashboard grafana           Ouvrir Grafana  
kubectl label ns <ns> istio-injection=enabled  
```

### Linkerd

```
linkerd install | kubectl apply -f - Installation  
linkerd check                        Vérification complète  
linkerd check --pre                  Pré-requis  
linkerd viz install | kubectl apply -f -  
linkerd viz dashboard                Dashboard  
linkerd viz stat deploy -n <ns>      Métriques par deployment  
linkerd viz top deploy/<nom>         Requêtes temps réel  
linkerd viz edges deploy -n <ns>     Graphe de trafic  
linkerd inject deploy.yaml | kubectl apply -f -  
linkerd diagnostics proxy-metrics <pod>  
```

---

## Utilisation de ces fiches

Ces cheat sheets sont conçues pour trois usages complémentaires. Elles servent de **référence quotidienne** à garder à portée de main, sur papier ou dans un onglet de navigateur, pour retrouver instantanément une commande. Elles constituent également un **support de révision** avant un examen ou une certification (CKA, CKS, Terraform Associate), en permettant de vérifier rapidement la maîtrise des commandes essentielles. Enfin, elles peuvent être utilisées comme **point de départ** vers les annexes A.1 et A.2 pour les cas où des options détaillées ou un contexte plus complet sont nécessaires.

⏭️ [Fichiers de configuration Debian](/annexes/B-fichiers-configuration.md)
