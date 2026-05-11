🔝 Retour au [Sommaire](/SOMMAIRE.md)

# Annexe C.2 — Problèmes courants Kubernetes

## Formation Debian : du Desktop au Cloud-Native

---

## Objectif

Ce guide couvre le diagnostic et la résolution des problèmes les plus fréquemment rencontrés dans un cluster Kubernetes, depuis les états anormaux des pods jusqu'aux défaillances du control plane. Il s'applique aux clusters installés sur des nœuds Debian via kubeadm, K3s ou MicroK8s, ainsi qu'aux clusters managés (EKS, GKE, AKS) pour les aspects applicatifs.

Chaque problème est présenté selon le format : symptômes, diagnostic, causes probables, résolution.

---

## Réflexes de diagnostic Kubernetes

Avant d'aborder les problèmes spécifiques, voici la séquence de commandes à exécuter en premier face à tout incident sur un cluster Kubernetes.

```bash
# 1. État général du cluster
kubectl get nodes                        # Tous les nœuds sont-ils Ready ?  
kubectl get pods -A | grep -v Running    # Pods en état anormal  
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -30  

# 2. Détails sur la ressource en cause
kubectl describe <type> <nom> -n <ns>    # Événements et conditions

# 3. Logs de l'application
kubectl logs <pod> -n <ns>               # Logs du conteneur principal  
kubectl logs <pod> -n <ns> --previous    # Logs du crash précédent  
kubectl logs <pod> -n <ns> -c <conteneur> # Conteneur spécifique  

# 4. État du nœud hébergeant le pod problématique
kubectl describe node <nœud>             # Conditions, pression, capacité
```

La section `Events` en bas de la sortie de `kubectl describe` est la source d'information la plus précieuse. Elle liste chronologiquement les actions entreprises par Kubernetes et les erreurs rencontrées.

---

## 1. Problèmes de pods

### 1.1 Pod en état Pending

**Symptômes** — Le pod reste en état `Pending` indéfiniment. Il n'est jamais schedulé sur un nœud.

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>
# Chercher dans la section Events des messages du scheduler :
# - "0/3 nodes are available"
# - "Insufficient cpu" ou "Insufficient memory"
# - "didn't match Pod's node affinity/selector"
# - "had taint ... that the pod didn't tolerate"
# - "didn't find available persistent volumes"
```

**Causes et résolutions** :

**Ressources insuffisantes** — Aucun nœud n'a assez de CPU ou de mémoire disponible pour satisfaire les `requests` du pod. Le message indique typiquement « 0/3 nodes are available: 3 Insufficient cpu ».

```bash
# Vérifier la capacité et l'utilisation des nœuds
kubectl describe nodes | grep -A 5 "Allocated resources"  
kubectl top nodes  

# Solutions :
# - Réduire les requests du pod si elles sont surdimensionnées
# - Ajouter des nœuds au cluster
# - Supprimer ou réduire d'autres workloads
# - Activer le Cluster Autoscaler (environnement cloud)
```

**Taints et tolerations** — Le pod ne tolère pas les taints présents sur les nœuds disponibles.

```bash
# Lister les taints des nœuds
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Ajouter la toleration dans le manifeste du pod si approprié :
# tolerations:
#   - key: "node-role.kubernetes.io/control-plane"
#     effect: "NoSchedule"
```

**Affinité ou nodeSelector incompatible** — Le pod demande un nœud avec un label spécifique qu'aucun nœud ne porte.

```bash
# Labels demandés par le pod
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.nodeSelector}'  
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.affinity}'  

# Labels disponibles sur les nœuds
kubectl get nodes --show-labels
```

**PVC non lié** — Le pod référence un PersistentVolumeClaim qui n'a pas trouvé de volume. Voir la section 5 de ce guide.

### 1.2 Pod en état ImagePullBackOff / ErrImagePull

**Symptômes** — Le pod reste en état `ImagePullBackOff` ou `ErrImagePull`. Le conteneur n'est jamais créé.

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>
# Events typiques :
# - "Failed to pull image ... : rpc error: code = NotFound"
# - "Failed to pull image ... : unauthorized"
# - "Failed to pull image ... : context deadline exceeded"
# - "Back-off pulling image ..."
```

**Causes et résolutions** :

**Image inexistante** — Le nom ou le tag de l'image est incorrect. Vérifier que l'image existe dans le registry.

```bash
# Vérifier le nom exact de l'image
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[*].image}'

# Tester le pull manuellement depuis un nœud
crictl pull <image>:<tag>
# ou
docker pull <image>:<tag>

# Erreurs courantes :
# - Faute de frappe dans le nom de l'image
# - Tag "latest" absent ou non mis à jour
# - Registry privé sans le préfixe complet (registry.example.com/image:tag)
```

**Authentification au registry** — Le cluster ne dispose pas des identifiants nécessaires pour un registry privé.

```bash
# Vérifier les imagePullSecrets du pod
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.imagePullSecrets}'

# Vérifier que le secret existe et contient les bons identifiants
kubectl get secret <secret> -n <ns> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Créer ou recréer le secret si nécessaire
kubectl create secret docker-registry regcred \
    --docker-server=registry.example.com \
    --docker-username=<user> \
    --docker-password=<pass> \
    -n <ns>
```

**Timeout réseau** — Le nœud n'arrive pas à joindre le registry (DNS, proxy, pare-feu).

```bash
# Depuis un nœud du cluster, tester l'accès au registry
curl -v https://registry.example.com/v2/  
nslookup registry.example.com  

# Vérifier le proxy du runtime de conteneurs
cat /etc/systemd/system/containerd.service.d/http-proxy.conf
```

### 1.3 Pod en état CrashLoopBackOff

**Symptômes** — Le pod alterne entre `Running` et `CrashLoopBackOff`. Le compteur de restarts augmente. Le délai entre les tentatives de redémarrage s'allonge exponentiellement (10s, 20s, 40s... jusqu'à 5 minutes).

**Diagnostic** :

```bash
# Logs du crash actuel
kubectl logs <pod> -n <ns>

# Logs du crash précédent (essentiel si le conteneur redémarre trop vite)
kubectl logs <pod> -n <ns> --previous

# Code de sortie du conteneur
kubectl get pod <pod> -n <ns> -o jsonpath='{.status.containerStatuses[0].lastState.terminated}'
# exitCode courants :
# 0   = arrêt normal (mais inattendu pour un serveur)
# 1   = erreur applicative générique
# 2   = mauvais usage d'un shell builtin
# 126 = commande non exécutable (permissions)
# 127 = commande introuvable
# 137 = tué par SIGKILL (OOM ou kill externe)
# 139 = segfault (SIGSEGV)
# 143 = tué par SIGTERM (arrêt propre)

# Investiguer dans un conteneur de debug
kubectl debug <pod> -n <ns> --image=busybox --target=<conteneur> -it
# ou lancer un pod éphémère avec la même image
kubectl run debug --image=<image> -n <ns> --rm -it -- /bin/sh
```

**Causes et résolutions** :

**Erreur de configuration applicative** — L'application ne trouve pas un fichier de configuration, une variable d'environnement ou une ressource externe (base de données, API). Les logs `--previous` révèlent généralement le message d'erreur exact.

```bash
# Vérifier les ConfigMaps et Secrets montés
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[0].volumeMounts}'  
kubectl get configmap <cm> -n <ns> -o yaml  
kubectl get secret <secret> -n <ns> -o yaml  
```

**Commande ou point d'entrée incorrect** — L'`ENTRYPOINT` ou la `CMD` du Dockerfile est surchargée par le manifeste Kubernetes avec une commande inexistante ou incorrecte.

```bash
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[0].command}'  
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[0].args}'  
```

**Problème de probe** — Une probe de liveness trop agressive tue le conteneur avant qu'il n'ait fini de démarrer. Cela se manifeste par un conteneur qui fonctionne quelques secondes puis est tué avec le code 137.

```bash
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[0].livenessProbe}'
# Vérifier initialDelaySeconds, periodSeconds, failureThreshold
# Solution : augmenter initialDelaySeconds ou ajouter une startupProbe
```

**Système de fichiers en lecture seule** — Si `readOnlyRootFilesystem: true` est activé, l'application peut échouer si elle tente d'écrire dans des répertoires non montés via `emptyDir` ou un volume.

### 1.4 Pod en état OOMKilled

**Symptômes** — Le pod redémarre avec le code de sortie 137. La raison affichée est `OOMKilled` (Out Of Memory Killed).

**Diagnostic** :

```bash
# Confirmer l'OOMKill
kubectl get pod <pod> -n <ns> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
# Retourne "OOMKilled"

# Vérifier les limites configurées
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.containers[0].resources}'

# Consommation mémoire actuelle (si le pod est en cours d'exécution)
kubectl top pod <pod> -n <ns> --containers

# Vérifier les événements OOM au niveau du nœud
kubectl describe node <nœud> | grep -A 5 "OOMKilling"
```

**Résolution** — L'application consomme plus de mémoire que la `memory limit` autorisée. Trois approches complémentaires sont possibles : augmenter la limite mémoire si elle est sous-dimensionnée par rapport aux besoins réels de l'application, optimiser l'application pour réduire sa consommation (fuites mémoire, caches surdimensionnés), ou configurer un Vertical Pod Autoscaler (VPA) pour ajuster automatiquement les limites.

Un piège courant avec les applications Java est que la JVM ne connaît pas les limites de cgroups par défaut sur les anciennes versions. Les JVM modernes (11+) respectent ces limites, mais il peut être nécessaire de configurer explicitement `-Xmx` en fonction de la limite mémoire du conteneur.

### 1.5 Pod en état Terminating bloqué

**Symptômes** — Un pod reste indéfiniment en état `Terminating` après une suppression.

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>
# Vérifier s'il y a des finalizers
kubectl get pod <pod> -n <ns> -o jsonpath='{.metadata.finalizers}'

# Vérifier l'état du nœud
kubectl get node <nœud>
# Si le nœud est NotReady, il ne peut pas confirmer la suppression du pod.
```

**Résolution** :

```bash
# Si le nœud est sain, forcer la suppression
kubectl delete pod <pod> -n <ns> --grace-period=0 --force

# Si le pod a des finalizers bloquants, les retirer (avec précaution)
kubectl patch pod <pod> -n <ns> -p '{"metadata":{"finalizers":null}}'

# Si le nœud est définitivement perdu
kubectl delete node <nœud>
# Les pods sur ce nœud seront re-schedulés après le timeout par défaut de
# 5 minutes — désormais piloté par les tolerations injectées par l'admission
# controller DefaultTolerationSeconds (tolerationSeconds: 300 sur les taints
# node.kubernetes.io/not-ready et node.kubernetes.io/unreachable). L'ancien
# flag --pod-eviction-timeout du controller-manager est déprécié depuis K8s 1.13.
```

### 1.6 Pod en état CreateContainerConfigError

**Symptômes** — Le pod reste en état `CreateContainerConfigError`. Aucun conteneur n'est créé.

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>
# Events typiques :
# "Error: configmap <nom> not found"
# "Error: secret <nom> not found"
# "Error: couldn't find key <clé> in ConfigMap"
```

**Causes** — Le pod référence un ConfigMap, un Secret ou une clé spécifique qui n'existe pas dans le namespace. Cette erreur survient fréquemment après un déploiement dans un nouveau namespace sans avoir créé les ConfigMaps/Secrets associés, ou après un renommage.

```bash
# Vérifier l'existence des ressources référencées
kubectl get configmap -n <ns>  
kubectl get secret -n <ns>  

# Créer la ressource manquante
kubectl create configmap <nom> --from-file=<fichier> -n <ns>
```

---

## 2. Problèmes de nœuds

### 2.1 Nœud en état NotReady

**Symptômes** — `kubectl get nodes` affiche un ou plusieurs nœuds en état `NotReady`. Les pods sur ces nœuds ne sont plus gérés et peuvent être évacués après le timeout.

**Diagnostic** :

```bash
# Conditions du nœud
kubectl describe node <nœud>
# Section Conditions : vérifier les lignes marquées "True" pour les problèmes
# - MemoryPressure
# - DiskPressure
# - PIDPressure
# - NetworkUnavailable
# - Ready = False (ou Unknown si le nœud ne communique plus)

# Si le nœud est accessible en SSH
ssh <nœud>

# Vérifier kubelet
systemctl status kubelet  
journalctl -u kubelet --since "10 minutes ago" -n 100  

# Vérifier le runtime de conteneurs
systemctl status containerd  
crictl ps                                # Conteneurs en cours d'exécution  
crictl pods                              # Pods gérés par le runtime  

# Vérifier les ressources système
df -h                                    # Espace disque  
free -h                                  # Mémoire  
uptime                                   # Charge CPU  
```

**Causes et résolutions** :

**Kubelet arrêté ou en crash** — Le kubelet ne répond plus au control plane. Vérifier son état et ses logs. Les causes fréquentes sont une erreur de certificat expiré, un problème de configuration après une mise à jour ou un crash dû à un manque de ressources système.

```bash
# Redémarrer kubelet
systemctl restart kubelet  
journalctl -u kubelet -f                 # Suivre les logs après redémarrage  
```

**Runtime de conteneurs défaillant** — containerd ou le socket CRI ne répond plus.

```bash
# Vérifier le socket
crictl info
# Si erreur de connexion :
systemctl restart containerd
```

**Certificats expirés** — Les certificats du kubelet ou du cluster ont expiré. Le message dans les logs kubelet contient « certificate has expired ».

```bash
# Vérifier l'expiration des certificats (sur un nœud control plane)
kubeadm certs check-expiration

# Renouveler les certificats
kubeadm certs renew all  
systemctl restart kubelet  
```

**Espace disque insuffisant** — Le nœud passe en condition `DiskPressure` quand l'espace disponible descend sous le seuil configuré (par défaut 10% pour `imagefs` et 15% pour `nodefs`). Le kubelet commence alors à évincer les pods.

```bash
# Nettoyer les images inutilisées
crictl rmi --prune

# Nettoyer les conteneurs arrêtés
crictl rm $(crictl ps -a -q --state exited)

# Vérifier et nettoyer les logs de conteneurs
find /var/log/containers -name "*.log" -size +100M  
find /var/log/pods -name "*.log" -size +100M  
```

### 2.2 Nœud avec pression de ressources (Pressure)

**Symptômes** — `kubectl describe node` montre une ou plusieurs conditions de pression à `True` : `MemoryPressure`, `DiskPressure` ou `PIDPressure`. Des pods sont évincés du nœud.

**Diagnostic** :

```bash
# Seuils d'éviction configurés
kubectl get --raw /api/v1/nodes/<nœud>/proxy/configz | jq '.kubeletconfig.evictionHard'
# Seuils par défaut :
# memory.available < 100Mi
# nodefs.available < 10%
# imagefs.available < 15%
# nodefs.inodesFree < 5%

# Pods évincés
kubectl get pods -A --field-selector=status.phase=Failed | grep Evicted
# Nettoyer les pods évincés
kubectl get pods -A --field-selector=status.phase=Failed -o json | \
    jq -r '.items[] | select(.status.reason=="Evicted") | "\(.metadata.namespace) \(.metadata.name)"' | \
    xargs -r -n2 kubectl delete pod -n
```

**Résolution** — Identifier la source de la pression (pods consommant trop de mémoire, logs volumineux, images Docker accumulées) et l'éliminer. À long terme, configurer des `ResourceQuotas` et des `LimitRanges` pour empêcher les pods de surconsommer, et s'assurer que les monitoring et alertes détectent la pression avant qu'elle ne provoque des évictions.

### 2.3 Nœud qui ne rejoint pas le cluster

**Symptômes** — Après `kubeadm join`, le nœud n'apparaît pas dans `kubectl get nodes` ou reste en état `NotReady`.

**Diagnostic** :

```bash
# Sur le nouveau nœud
systemctl status kubelet  
journalctl -u kubelet -n 100  

# Erreurs fréquentes dans les logs :
# "unable to connect to the server" → problème réseau ou token expiré
# "failed to run Kubelet: misconfiguration" → prérequis manquants
# "cgroup driver mismatch" → containerd et kubelet en désaccord
```

**Causes et résolutions** :

**Token expiré** — Les tokens kubeadm expirent après 24 heures par défaut. Régénérer un nouveau token depuis un nœud control plane.

```bash
# Sur le control plane
kubeadm token create --print-join-command
```

**Prérequis système non satisfaits** — Vérifier les prérequis sur le nœud worker.

```bash
# Swap désactivée (obligatoire)
swapon --show                            # Doit être vide  
cat /etc/fstab | grep swap               # Ligne commentée  

# Modules noyau chargés
lsmod | grep br_netfilter  
lsmod | grep overlay  

# Paramètres sysctl
sysctl net.bridge.bridge-nf-call-iptables  
sysctl net.ipv4.ip_forward  
# Les deux doivent retourner 1.

# Ports ouverts
ss -tlnp | grep -E "(6443|10250|10259|10257)"
```

**Driver de cgroup incompatible** — Le kubelet et containerd doivent utiliser le même driver de cgroup (systemd est recommandé sur Debian).

```bash
# Vérifier containerd
cat /etc/containerd/config.toml | grep SystemdCgroup
# Doit être : SystemdCgroup = true

# Vérifier kubelet
cat /var/lib/kubelet/config.yaml | grep cgroupDriver
# Doit être : cgroupDriver: systemd
```

---

## 3. Problèmes réseau

### 3.1 Pods ne communiquant pas entre eux

**Symptômes** — Un pod ne peut pas joindre un autre pod par son IP ou via un Service. Les requêtes échouent avec « connection refused », « connection timed out » ou « no route to host ».

**Diagnostic** :

```bash
# Obtenir les IP des pods
kubectl get pods -n <ns> -o wide

# Tester la connectivité depuis un pod
kubectl exec -it <pod-source> -n <ns> -- /bin/sh
# Dans le pod :
ping <ip-pod-destination>                # Connectivité L3  
wget -qO- http://<ip-pod-destination>:<port>/   # Connectivité L7  

# Si le pod n'a pas les outils réseau, utiliser un pod de debug
kubectl run netdebug --image=nicolaka/netshoot --rm -it -n <ns> -- /bin/bash

# Vérifier l'état du plugin CNI
kubectl get pods -n kube-system | grep -E "(calico|flannel|cilium|weave)"  
kubectl logs -n kube-system <pod-cni>  

# Vérifier les Network Policies qui pourraient bloquer le trafic
kubectl get networkpolicies -n <ns>  
kubectl describe networkpolicy <nom> -n <ns>  
```

**Causes et résolutions** :

**Plugin CNI défaillant** — Si les pods du CNI (Calico, Flannel, Cilium) sont en erreur, la connectivité inter-pods est compromise. Vérifier les logs du CNI et redémarrer les DaemonSets si nécessaire.

```bash
kubectl rollout restart daemonset -n kube-system <cni-daemonset>
```

**Network Policy trop restrictive** — Une Network Policy peut bloquer le trafic légitime. Par défaut (sans aucune Network Policy), tout le trafic est autorisé. Dès qu'une Network Policy cible un pod, seul le trafic explicitement autorisé est accepté pour ce pod.

```bash
# Lister les Network Policies affectant un pod
kubectl get networkpolicy -n <ns> -o wide
# Vérifier les sélecteurs de pods et les règles ingress/egress
```

**Nœuds sur des sous-réseaux différents sans routage** — Si les nœuds sont sur des sous-réseaux distincts, le CNI doit pouvoir router le trafic inter-nœuds. Vérifier les routes et le mode d'encapsulation du CNI (VXLAN, IPIP, WireGuard).

### 3.2 Résolution DNS interne défaillante (CoreDNS)

**Symptômes** — Les pods ne peuvent pas résoudre les noms de services Kubernetes (`<service>.<namespace>.svc.cluster.local`) ni les noms de domaines externes. L'erreur typique est « could not resolve host ».

**Diagnostic** :

```bash
# Vérifier que CoreDNS fonctionne
kubectl get pods -n kube-system -l k8s-app=kube-dns  
kubectl logs -n kube-system -l k8s-app=kube-dns  

# Tester la résolution depuis un pod
kubectl run dnstest --image=busybox --rm -it -- nslookup kubernetes.default  
kubectl run dnstest --image=busybox --rm -it -- nslookup google.com  

# Vérifier le Service DNS
kubectl get svc kube-dns -n kube-system
# L'IP du service (généralement 10.96.0.10) doit correspondre au
# nameserver dans /etc/resolv.conf des pods.

# Vérifier la configuration DNS d'un pod
kubectl exec -it <pod> -n <ns> -- cat /etc/resolv.conf
# Doit contenir :
# nameserver 10.96.0.10
# search <ns>.svc.cluster.local svc.cluster.local cluster.local

# Vérifier le ConfigMap de CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
```

**Causes et résolutions** :

**Pods CoreDNS en CrashLoopBackOff** — CoreDNS peut crasher en boucle si sa configuration est invalide ou s'il y a une boucle de résolution DNS. Sur Debian, si `/etc/resolv.conf` de l'hôte pointe vers `127.0.0.53` (systemd-resolved), CoreDNS peut boucler sur lui-même.

```bash
# Vérifier si CoreDNS détecte une boucle
kubectl logs -n kube-system -l k8s-app=kube-dns | grep -i loop

# Solution : modifier le ConfigMap CoreDNS pour pointer vers
# un résolveur externe au lieu de /etc/resolv.conf
kubectl edit configmap coredns -n kube-system
# Remplacer "forward . /etc/resolv.conf" par :
# forward . 8.8.8.8 8.8.4.4
```

**Pods CoreDNS non schedulés** — Si les pods CoreDNS sont en état Pending, la résolution DNS est indisponible pour tout le cluster. Vérifier les taints des nœuds et les ressources disponibles.

### 3.3 Ingress ne route pas le trafic

**Symptômes** — L'URL configurée dans l'Ingress retourne une erreur 404, 502 ou 503, ou le trafic n'atteint pas le Service backend.

**Diagnostic** :

```bash
# Vérifier la ressource Ingress
kubectl get ingress -n <ns>  
kubectl describe ingress <nom> -n <ns>  
# Vérifier : host, paths, backend service/port

# Vérifier que l'Ingress Controller fonctionne
# Note : ingress-nginx (projet K8s) est en retraite officielle depuis le 31 mars 2026.
# Adapter le namespace selon le contrôleur utilisé : traefik, nginx-gateway, kgateway, etc.
kubectl get pods -n ingress-nginx        # ou traefik, nginx-gateway, etc.  
kubectl logs -n ingress-nginx <pod-controller>  

# Vérifier le Service backend
kubectl get svc <backend> -n <ns>  
kubectl get endpoints <backend> -n <ns>  
# Si endpoints est vide : le Service ne trouve aucun pod.
# Vérifier que les labels du Service matchent les labels des pods.

# Tester le Service directement (sans passer par l'Ingress)
kubectl port-forward svc/<backend> 8080:<port> -n <ns>  
curl http://localhost:8080/  

# Vérifier la classe d'Ingress
kubectl get ingressclass
# Le champ ingressClassName de l'Ingress doit correspondre.
```

**Causes courantes** :

**Service sans endpoints** — Le sélecteur de labels du Service ne correspond à aucun pod. C'est la cause la plus fréquente de 502/503 sur un Ingress.

```bash
# Labels du Service
kubectl get svc <backend> -n <ns> -o jsonpath='{.spec.selector}'

# Labels des pods
kubectl get pods -n <ns> --show-labels

# Les labels doivent correspondre exactement.
```

**Port incorrect** — Le port du Service (`targetPort`) ne correspond pas au port réellement exposé par le conteneur (`containerPort`).

**IngressClass manquante ou incorrecte** — Depuis Kubernetes 1.18, le champ `ingressClassName` est recommandé. Si l'Ingress Controller est configuré pour une classe différente de celle spécifiée dans l'Ingress, il ignore la ressource.

**Certificat TLS invalide** — Si l'Ingress est configuré avec TLS et que le Secret contenant le certificat est absent ou invalide, le contrôleur peut rejeter les connexions.

```bash
kubectl get secret <tls-secret> -n <ns>  
kubectl get secret <tls-secret> -n <ns> -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates -subject  
```

---

## 4. Problèmes du control plane

### 4.1 API Server inaccessible

**Symptômes** — `kubectl` retourne « The connection to the server was refused » ou « Unable to connect to the server ». Aucune commande kubectl ne fonctionne.

**Diagnostic** :

```bash
# Vérifier la connectivité réseau vers l'API server
curl -k https://<ip-control-plane>:6443/healthz

# Sur un nœud control plane, vérifier les pods statiques
crictl ps | grep kube-apiserver  
crictl logs <container-id-apiserver>  

# Vérifier le manifeste du pod statique
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Vérifier le kubelet (qui gère les pods statiques)
systemctl status kubelet  
journalctl -u kubelet | grep apiserver  
```

**Causes et résolutions** :

**Certificats expirés** — L'API server refuse les connexions si ses certificats sont expirés.

```bash
kubeadm certs check-expiration  
kubeadm certs renew all  
# Redémarrer les pods statiques en déplaçant temporairement
# les manifestes hors de /etc/kubernetes/manifests/
# puis en les remettant après quelques secondes.
```

**etcd indisponible** — L'API server dépend d'etcd. Si etcd est en panne, l'API server ne peut ni lire ni écrire l'état du cluster.

```bash
crictl ps | grep etcd  
crictl logs <container-id-etcd>  
# Voir section 4.3 pour le diagnostic etcd.
```

**Manifeste du pod statique modifié avec une erreur** — Une modification incorrecte du fichier YAML dans `/etc/kubernetes/manifests/` empêche le redémarrage de l'API server. Vérifier la syntaxe du fichier et les logs kubelet.

### 4.2 Scheduler ou Controller Manager en panne

**Symptômes** — Les nouveaux pods restent en état `Pending` (scheduler en panne) ou les Deployments ne créent pas de ReplicaSets (controller manager en panne). Les pods existants continuent de fonctionner.

**Diagnostic** :

```bash
# Vérifier les pods du control plane
kubectl get pods -n kube-system | grep -E "(scheduler|controller)"
# Si kubectl ne fonctionne pas :
crictl ps | grep -E "(scheduler|controller)"  
crictl logs <container-id>  

# Vérifier les manifestes
cat /etc/kubernetes/manifests/kube-scheduler.yaml  
cat /etc/kubernetes/manifests/kube-controller-manager.yaml  

# Vérifier les lease (leader election)
kubectl get lease -n kube-system
```

**Résolution** — Vérifier les logs du composant en panne. Les causes les plus fréquentes sont des certificats expirés, une configuration modifiée par erreur dans le manifeste du pod statique, ou un problème de connectivité avec l'API server. Restaurer le manifeste d'origine (depuis un backup etckeeper ou le manifeste kubeadm par défaut) et redémarrer le kubelet.

### 4.3 Problèmes etcd

**Symptômes** — L'API server retourne des erreurs « etcdserver: request timed out » ou « etcdserver: leader changed ». Le cluster devient instable ou en lecture seule.

**Diagnostic** :

```bash
# État du cluster etcd (depuis un nœud control plane)
ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint health

# État détaillé
etcdctl endpoint status --write-out=table

# Membres du cluster
etcdctl member list --write-out=table

# Métriques etcd
curl -s --cacert /etc/kubernetes/pki/etcd/ca.crt \
    --cert /etc/kubernetes/pki/etcd/server.crt \
    --key /etc/kubernetes/pki/etcd/server.key \
    https://127.0.0.1:2379/metrics | grep -E "etcd_server_(has_leader|leader_changes)"

# Vérifier la taille de la base
etcdctl endpoint status --write-out=json | jq '.[].Status.dbSize'
# Limite par défaut : 2 Go. Au-delà, etcd refuse les écritures.
```

**Causes et résolutions** :

**Base de données trop volumineuse** — etcd a une limite par défaut de 2 Go. Les événements Kubernetes, les ConfigMaps volumineux et un nombre élevé de ressources peuvent faire grossir la base.

```bash
# Compacter et défragmenter
etcdctl compact $(etcdctl endpoint status --write-out=json | jq -r '.[].Status.revision')  
etcdctl defrag  
```

**Latence disque élevée** — etcd est très sensible à la latence des I/O disque. Un disque lent provoque des timeouts de leader election et de l'instabilité. La recommandation est d'utiliser un SSD dédié pour etcd.

```bash
# Vérifier la latence du WAL (Write Ahead Log)
# Les métriques etcd_disk_wal_fsync_duration_seconds doivent être < 10ms au p99.
```

**Perte de quorum** — Dans un cluster etcd à 3 membres, la perte de 2 membres simultanément entraîne une perte de quorum. Le cluster restant devient en lecture seule. La restauration depuis un snapshot est alors nécessaire (voir annexe C.4).

---

## 5. Problèmes de stockage

### 5.1 PVC en état Pending

**Symptômes** — Un PersistentVolumeClaim reste en état `Pending`. Les pods qui le référencent restent également en `Pending`.

**Diagnostic** :

```bash
kubectl describe pvc <nom> -n <ns>
# Events typiques :
# "no persistent volumes available for this claim and no storage class is set"
# "waiting for first consumer to be created"
# "storageclass.storage.k8s.io <class> not found"

# Vérifier les StorageClasses disponibles
kubectl get storageclass
# Y a-t-il une StorageClass par défaut (annotée avec "is-default-class: true") ?

# Vérifier les PV disponibles (pour le provisionnement statique)
kubectl get pv

# Vérifier le provisioner
kubectl get pods -A | grep -E "(provisioner|csi)"
```

**Causes et résolutions** :

**Aucune StorageClass par défaut** — Si le PVC ne spécifie pas de `storageClassName` et qu'aucune StorageClass n'est marquée comme défaut, le PVC reste en Pending.

```bash
# Définir une StorageClass par défaut
kubectl patch storageclass <nom> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

**Provisioner non installé ou en erreur** — Le provisionnement dynamique nécessite un CSI driver fonctionnel. Vérifier que le provisioner est déployé et que ses pods sont en état Running.

**Volume en mode WaitForFirstConsumer** — Avec `volumeBindingMode: WaitForFirstConsumer`, le PVC attend qu'un pod le consomme avant de provisionner le volume. C'est un comportement normal, pas une erreur.

**Capacité insuffisante** — Le backend de stockage n'a plus d'espace disponible pour créer de nouveaux volumes.

### 5.2 Erreur de montage de volume dans un pod

**Symptômes** — Le pod reste en état `ContainerCreating` avec des événements de type « MountVolume.SetUp failed » ou « FailedMount ».

**Diagnostic** :

```bash
kubectl describe pod <pod> -n <ns>
# Events typiques :
# "Unable to attach or mount volumes: ... timed out"
# "MountVolume.SetUp failed for volume ... : mount failed: exit status 32"
# "FailedMount ... hostPath type check failed"

# Vérifier l'état du PV
kubectl get pv <nom> -o yaml
# Le champ status.phase doit être "Bound"

# Vérifier sur le nœud que le volume est attaché
ssh <nœud>  
lsblk                                   # Disques attachés  
mount | grep <volume>                    # Points de montage  
dmesg | tail -20                         # Erreurs noyau récentes  
```

**Causes courantes** — Le volume est déjà attaché à un autre nœud (pour les volumes `ReadWriteOnce`). Le driver CSI n'est pas installé sur le nœud. Le système de fichiers du volume est corrompu. Pour NFS, le serveur NFS est inaccessible ou le répertoire exporté n'existe pas.

### 5.3 Données perdues après redéploiement

**Symptômes** — Après un `kubectl rollout restart` ou un redéploiement, les données de l'application ont disparu.

**Diagnostic** :

```bash
# Vérifier si le pod utilise un volume persistant
kubectl get pod <pod> -n <ns> -o jsonpath='{.spec.volumes}'

# Vérifier le type de volume
# emptyDir : supprimé avec le pod (données éphémères)
# hostPath : lié au nœud (données perdues si le pod change de nœud)
# persistentVolumeClaim : données persistantes et indépendantes du pod
```

**Cause** — L'application stocke ses données dans un `emptyDir` (ou pire, directement dans le système de fichiers du conteneur) au lieu d'un PersistentVolumeClaim. Les `emptyDir` sont supprimés à chaque destruction du pod. Le système de fichiers du conteneur est recréé à chaque démarrage.

**Résolution** — Migrer le stockage vers un PersistentVolumeClaim. Pour les applications nécessitant une identité stable et un stockage persistant par pod, utiliser un StatefulSet au lieu d'un Deployment.

---

## 6. Problèmes de déploiement et de mise à jour

### 6.1 Deployment bloqué pendant un rollout

**Symptômes** — `kubectl rollout status deployment/<nom>` reste bloqué. Les anciens pods continuent de tourner et les nouveaux pods ne deviennent pas Ready.

**Diagnostic** :

```bash
kubectl rollout status deployment/<nom> -n <ns>  
kubectl get replicaset -n <ns> -l app=<label>  
# Le nouveau ReplicaSet a des pods en erreur.
kubectl get pods -n <ns> -l app=<label>  
kubectl describe pod <nouveau-pod> -n <ns>  
```

**Causes** — Le nouveau pod ne passe pas les readiness probes (image incorrecte, erreur de configuration, dépendance manquante). Avec la stratégie `RollingUpdate` et `maxUnavailable: 0`, Kubernetes attend que les nouveaux pods soient Ready avant de supprimer les anciens. Si les nouveaux pods ne deviennent jamais Ready, le déploiement reste bloqué.

**Résolution** :

```bash
# Annuler le déploiement et revenir à la version précédente
kubectl rollout undo deployment/<nom> -n <ns>

# Vérifier l'historique des déploiements
kubectl rollout history deployment/<nom> -n <ns>

# Revenir à une révision spécifique
kubectl rollout undo deployment/<nom> -n <ns> --to-revision=<N>
```

Configurer un `progressDeadlineSeconds` dans le Deployment (600 secondes par défaut) permet à Kubernetes de marquer automatiquement le déploiement comme échoué si les nouveaux pods ne sont pas prêts dans le délai imparti.

### 6.2 Pods non mis à jour après modification d'un ConfigMap

**Symptômes** — Le ConfigMap a été modifié, mais les pods utilisent toujours les anciennes valeurs.

**Cause** — Kubernetes ne redémarre pas automatiquement les pods quand un ConfigMap ou un Secret monté en volume est modifié. Les fichiers montés sont mis à jour dans le pod (après un délai pouvant aller jusqu'à une minute), mais l'application ne relit pas forcément ses fichiers de configuration sans redémarrage.

Pour les variables d'environnement issues d'un ConfigMap (`envFrom` ou `valueFrom`), la mise à jour n'est jamais propagée sans recréer le pod.

**Résolution** :

```bash
# Forcer le redémarrage des pods
kubectl rollout restart deployment/<nom> -n <ns>

# Solution pérenne : annoter le Deployment avec un hash du ConfigMap
# pour déclencher un rollout automatique à chaque modification.
# Helm et Kustomize offrent des mécanismes natifs pour cela.
```

---

## 7. Problèmes RBAC et sécurité

### 7.1 Erreur « forbidden » sur les opérations kubectl

**Symptômes** — `kubectl` retourne « Error from server (Forbidden): ... is forbidden: User "..." cannot ... ».

**Diagnostic** :

```bash
# Vérifier l'identité actuelle
kubectl auth whoami                      # K8s 1.26+  
kubectl config get-contexts              # Contexte et utilisateur actifs  

# Tester les permissions spécifiques
kubectl auth can-i get pods -n <ns>  
kubectl auth can-i create deployments -n <ns>  
kubectl auth can-i --list -n <ns>  

# Lister les rôles et bindings dans le namespace
kubectl get roles,rolebindings -n <ns>  
kubectl get clusterroles,clusterrolebindings | grep <user-ou-group>  

# Détails d'un rôle
kubectl describe role <nom> -n <ns>  
kubectl describe rolebinding <nom> -n <ns>  
```

**Résolution** — Créer ou modifier le Role/ClusterRole et le RoleBinding/ClusterRoleBinding appropriés. Vérifier que le `subjects` du binding correspond exactement à l'utilisateur, au groupe ou au ServiceAccount concerné (le nom est sensible à la casse).

### 7.2 Pod rejeté par l'admission controller

**Symptômes** — `kubectl apply` retourne une erreur du type « admission webhook denied the request » ou « violates PodSecurity ».

**Diagnostic** :

```bash
# Le message d'erreur indique généralement quelle politique est violée.

# Vérifier les Pod Security Standards du namespace
kubectl get ns <ns> -o yaml | grep pod-security

# Vérifier les webhooks d'admission
kubectl get validatingwebhookconfigurations  
kubectl get mutatingwebhookconfigurations  

# Si OPA Gatekeeper est utilisé
kubectl get constraints  
kubectl describe <constraint-kind> <nom>  
```

**Causes courantes** — Le pod tente de s'exécuter en tant que root dans un namespace configuré avec le niveau `restricted`. Le pod utilise des capabilities non autorisées. Le pod demande un `hostPath` ou un port privilégié. Un webhook OPA Gatekeeper ou Kyverno rejette la configuration.

**Résolution** — Modifier le manifeste du pod pour respecter les politiques en vigueur (utilisateur non-root, `readOnlyRootFilesystem`, `drop: ALL` pour les capabilities, pas de `hostPath`). Si la politique est trop restrictive pour le cas d'usage légitime, ajuster le niveau de Pod Security Standard du namespace ou créer une exception dans Gatekeeper.

---

## 8. Arbre de décision Kubernetes

**Le pod ne démarre pas** → Vérifier son état avec `kubectl get pod` puis `kubectl describe pod` :
- `Pending` → Section 1.1 (ressources, taints, affinité, PVC)
- `ImagePullBackOff` → Section 1.2 (image, registry, authentification)
- `CrashLoopBackOff` → Section 1.3 (logs --previous, config, probes)
- `CreateContainerConfigError` → Section 1.6 (ConfigMap/Secret manquant)
- `OOMKilled` → Section 1.4 (limites mémoire)

**Le nœud est NotReady** → Section 2.1. Vérifier kubelet, containerd, certificats, espace disque.

**La connectivité inter-pods est rompue** → Section 3.1. Vérifier CNI, Network Policies, routage inter-nœuds.

**La résolution DNS ne fonctionne pas** → Section 3.2. Vérifier CoreDNS, resolv.conf des pods.

**L'Ingress ne route pas** → Section 3.3. Vérifier endpoints du Service, IngressClass, logs du contrôleur.

**kubectl ne répond plus** → Section 4.1. Vérifier l'API server, etcd, certificats.

**Le déploiement est bloqué** → Section 6.1. Vérifier les nouveaux pods, faire un rollback si nécessaire.

**« Forbidden »** → Section 7.1. Vérifier RBAC, contexte kubectl, ServiceAccount.

---

## Commandes de diagnostic Kubernetes — Récapitulatif

```bash
# Snapshot rapide de l'état du cluster
kubectl get nodes  
kubectl get pods -A | grep -vE "Running|Completed"  
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -20  
kubectl top nodes  
kubectl top pods -A --sort-by=memory | head -20  
# componentstatuses (cs) est marqué deprecated depuis K8s 1.19 et la sortie
# n'est plus fiable sur les clusters récents — préférer une vérification
# directe des endpoints des composants du control plane :
curl -k https://<control-plane>:6443/livez?verbose  
curl -k https://<control-plane>:6443/readyz?verbose  
kubectl get --raw='/livez?verbose'  
kubectl get --raw='/readyz?verbose'  

# Diagnostic d'un pod
kubectl describe pod <pod> -n <ns>  
kubectl logs <pod> -n <ns> [--previous] [-c <conteneur>]  
kubectl get pod <pod> -n <ns> -o yaml  

# Diagnostic d'un nœud
kubectl describe node <nœud>  
kubectl get pods --field-selector=spec.nodeName=<nœud> -A  

# Diagnostic réseau
kubectl get svc,endpoints -n <ns>  
kubectl get ingress -n <ns>  
kubectl get networkpolicy -n <ns>  
kubectl run netdebug --image=nicolaka/netshoot --rm -it -- /bin/bash  
```

⏭️ [Résolution réseau et stockage](/annexes/C.3-resolution-reseau-stockage.md)
