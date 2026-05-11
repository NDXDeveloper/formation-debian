🔝 Retour au [Sommaire](/SOMMAIRE.md)

# 12.4 Autoscaling et gestion des ressources

## Module 12 — Kubernetes Production · Parcours 2

---

## Introduction

Les sections précédentes ont établi les garde-fous statiques de la gestion des ressources : les Resource Quotas plafonnent la consommation par namespace, les LimitRanges bornent chaque conteneur, et les requests/limits définies par les développeurs dimensionnent chaque pod individuellement (cf. 12.2.4). Ces mécanismes sont nécessaires mais insuffisants face à la réalité d'une charge de production : le trafic fluctue au fil de la journée, les pics saisonniers saturent les ressources prévues pour la charge nominale, et les périodes creuses laissent tourner des pods qui consomment des ressources inutilement.

L'autoscaling est la capacité du cluster à ajuster automatiquement ses ressources — nombre de pods, dimensionnement de chaque pod, nombre de nœuds — en fonction de la charge réelle observée. C'est le passage d'un dimensionnement statique, décidé à l'avance par un humain, à un dimensionnement dynamique, piloté par les métriques en temps réel.

---

## Le problème du dimensionnement statique

### Sous-dimensionnement

Un Deployment configuré avec 3 réplicas et 500m de CPU par pod fonctionne correctement en charge nominale. Lors d'un pic de trafic (campagne marketing, événement médiatique, Black Friday), les pods saturent : le CPU est throttled, les temps de réponse augmentent, les health checks échouent, des pods redémarrent en cascade. Le service se dégrade ou devient indisponible.

La réponse manuelle — un opérateur exécute `kubectl scale deployment backend --replicas=10` — intervient trop tard, nécessite une présence humaine et n'est pas reproductible.

### Surdimensionnement

Pour éviter les incidents de sous-dimensionnement, la tentation est de provisionner largement : 10 réplicas au lieu de 3, 2 Go de RAM au lieu de 512 Mo. Le service est confortable en pic, mais pendant les 90 % du temps où la charge est nominale, 70 % des ressources sont gaspillées. Sur un cluster bare-metal avec des nœuds Debian, ce gaspillage se traduit directement en matériel sous-utilisé. Sur un cluster cloud, il se traduit en coûts inutiles.

### L'optimum dynamique

L'autoscaling vise l'optimum dynamique : juste assez de ressources pour absorber la charge actuelle avec une marge de sécurité, pas plus. Cet optimum change en permanence, ce qui exige un ajustement automatisé et continu.

```
Charge réelle          Dimensionnement statique       Autoscaling
                       (pré-provisionné)

   ▲                     ▲                            ▲
   │    ╱╲               │ ────────────────            │    ╱╲
   │   ╱  ╲     ╱╲       │                             │   ╱  ╲     ╱╲
   │  ╱    ╲   ╱  ╲      │    Gaspillage               │  ╱    ╲   ╱  ╲
   │ ╱      ╲ ╱    ╲     │    permanent                │ ╱      ╲ ╱    ╲
   │╱        ╳      ╲    │                             │╱  ──────╳──    ╲──
   ──────────────────►    ──────────────────►           ──────────────────►
         Temps                  Temps                         Temps

                          Ressources fixes              Ressources adaptées
                          >> charge moyenne              ≈ charge réelle + marge
```

---

## Les trois dimensions de l'autoscaling

Kubernetes offre trois mécanismes d'autoscaling complémentaires, chacun opérant à un niveau différent :

### Dimension horizontale — Nombre de pods (HPA)

Le **Horizontal Pod Autoscaler** ajuste le nombre de réplicas d'un Deployment (ou StatefulSet) en fonction de métriques observées : utilisation CPU, consommation mémoire, métriques custom (requêtes par seconde, profondeur de file d'attente, latence).

```
Charge basse :   [Pod] [Pod]  
Charge haute :   [Pod] [Pod] [Pod] [Pod] [Pod] [Pod]  
```

L'HPA est le mécanisme le plus utilisé et le plus mature. Il est adapté aux applications *stateless* qui peuvent absorber plus de charge en ajoutant des instances identiques.

### Dimension verticale — Taille de chaque pod (VPA)

Le **Vertical Pod Autoscaler** ajuste les requests et limits de CPU et de mémoire de chaque conteneur en fonction de sa consommation réelle observée. Il résout le problème du dimensionnement initial : comment savoir quelle quantité de CPU et de mémoire demander pour un conteneur dont on ne connaît pas encore le profil de charge ?

```
Avant VPA :   [Pod: 250m CPU, 256Mi RAM]   ← estimations initiales  
Après VPA :   [Pod: 420m CPU, 380Mi RAM]   ← basé sur l'observation réelle  
```

Le VPA est particulièrement utile pour les applications *stateful* ou les services dont le nombre de réplicas est fixe (une seule instance), où le scaling horizontal n'est pas applicable.

### Dimension infrastructure — Nombre de nœuds (Cluster Autoscaler / Karpenter)

Le **Cluster Autoscaler** ajuste le nombre de nœuds du cluster en fonction des besoins de scheduling. Lorsque des pods sont en état `Pending` parce qu'aucun nœud n'a assez de ressources disponibles, le Cluster Autoscaler provisionne de nouveaux nœuds. Lorsque des nœuds sont sous-utilisés et que leurs pods peuvent être replanifiés ailleurs, il les retire.

```
Nœuds actuels :   [Node 1] [Node 2] [Node 3]  
Pods Pending :    Le scheduler ne trouve pas de place  
Cluster Autoscaler : ajoute [Node 4]  
```

Le Cluster Autoscaler est principalement utilisé en environnement cloud (AWS, GCP, Azure) où les nœuds peuvent être provisionnés à la demande. Sur infrastructure bare-metal Debian, les options sont plus limitées mais existent (intégration avec des hyperviseurs, pools de nœuds pré-provisionnés).

Pour les clusters managés modernes (EKS, AKS, GKE), **Karpenter** (v1.0.0 GA en août 2024, sous `kubernetes-sigs/karpenter` — branches v1.x successives jusqu'à v1.5+ en 2026) est désormais l'alternative recommandée : provisionnement direct d'instances sans node groups figés, choix dynamique du type d'instance le mieux adapté, démarrage de nœud en 30–60 secondes (cf. 12.4.3).

### Complémentarité des trois dimensions

Les trois autoscalers opèrent à des échelles de temps et de granularité différentes :

| Autoscaler | Granularité | Temps de réaction | Prérequis |
|:-----------|:------------|:------------------|:----------|
| HPA | Pod (réplicas) | Secondes à minutes | Metrics Server ou Prometheus Adapter |
| VPA | Conteneur (requests/limits) | Minutes à heures | VPA controller installé |
| Cluster Autoscaler | Nœud (infrastructure) | Minutes | Intégration cloud provider ou IaaS |

Un cluster de production mature combine idéalement les trois : le HPA gère les fluctuations de charge rapides en ajustant le nombre de pods, le VPA optimise le dimensionnement de chaque pod sur la base de l'observation à long terme, et le Cluster Autoscaler assure que l'infrastructure sous-jacente peut accueillir la charge totale.

---

## Le Metrics Server : fondation de l'autoscaling

### Rôle

Le Metrics Server est le composant qui collecte les métriques de consommation de ressources (CPU et mémoire) auprès des kubelets de chaque nœud et les expose via l'API `metrics.k8s.io`. Il est le prérequis minimal pour le fonctionnement du HPA et des commandes `kubectl top`.

```
kubelet (cAdvisor)         kubelet (cAdvisor)         kubelet (cAdvisor)
   Node 1                     Node 2                     Node 3
      │                          │                          │
      └──────────────┬───────────┘──────────────────────────┘
                     │
              Metrics Server
              (agrège les métriques)
                     │
              API metrics.k8s.io
                     │
           ┌─────────┼─────────┐
           │         │         │
          HPA    kubectl top  Dashboard
```

### Installation sur Debian

Le Metrics Server n'est pas installé par défaut par `kubeadm`. Son déploiement est simple :

```bash
# Installation depuis les manifestes officiels
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Vérification
kubectl get pods -n kube-system | grep metrics-server  
kubectl top nodes  
kubectl top pods -n app-production  
```

Sur un cluster bare-metal avec des certificats auto-signés, le Metrics Server peut nécessiter l'argument `--kubelet-insecure-tls` pour accepter les certificats des kubelets. Ce paramètre doit être utilisé avec précaution et uniquement si les certificats kubelet ne sont pas signés par une CA reconnue par le Metrics Server.

### Au-delà du Metrics Server : métriques custom

Le Metrics Server ne fournit que les métriques de base (CPU et mémoire). Pour l'autoscaling sur des métriques applicatives (requêtes par seconde, latence, profondeur de file d'attente), il faut exposer des métriques custom via l'API `custom.metrics.k8s.io`. Le **Prometheus Adapter** est la solution standard pour connecter Prometheus à cette API et rendre ses métriques disponibles pour le HPA.

---

## Interactions et conflits entre autoscalers

### HPA + VPA : cohabitation délicate

Le HPA et le VPA ciblent la même ressource (le Deployment) mais sur des axes différents (nombre de réplicas vs dimensionnement individuel). Leur utilisation simultanée sur la **même métrique** (CPU) crée un conflit : le VPA augmente les requests CPU, ce qui fait baisser le ratio d'utilisation vu par le HPA, qui réduit le nombre de réplicas, ce qui fait remonter la charge par pod, etc. — une boucle d'oscillation.

**Règle pratique** : ne pas utiliser le HPA et le VPA sur la même métrique pour le même Deployment. Les configurations recommandées sont les suivantes :

- HPA sur CPU + VPA en mode *recommendation only* (le VPA ne modifie pas les pods, il fournit uniquement des recommandations que l'opérateur applique manuellement).
- HPA sur des métriques custom (requêtes par seconde) + VPA sur CPU et mémoire.
- HPA seul pour les services stateless à charge variable.
- VPA seul pour les services avec un nombre fixe de réplicas.

### HPA + Cluster Autoscaler : synergie naturelle

Le HPA et le Cluster Autoscaler se complètent naturellement : lorsque le HPA crée de nouveaux pods et que les nœuds existants n'ont plus de capacité, les pods restent en `Pending`. Le Cluster Autoscaler détecte ces pods non planifiables et provisionne de nouveaux nœuds. Inversement, lorsque le HPA réduit le nombre de pods, le Cluster Autoscaler détecte les nœuds sous-utilisés et les retire.

### VPA + Cluster Autoscaler

Le VPA peut augmenter les requests d'un pod au-delà de la capacité disponible sur le nœud actuel. Le pod est alors replanifié (après éviction) et peut nécessiter un nœud plus grand. Le Cluster Autoscaler intervient si aucun nœud existant ne peut accueillir le pod avec ses nouvelles requests.

---

## Prérequis pour cette section

Cette section s'appuie sur les connaissances acquises dans les modules et sections précédents :

- Requests et Limits, classes de QoS (Section 12.2.4) : compréhension du dimensionnement des pods.
- Resource Quotas et LimitRanges (Section 12.2.4) : garde-fous statiques que l'autoscaling doit respecter.
- Métriques et monitoring (Module 15.2, en anticipation) : Prometheus, métriques custom — le carburant de l'autoscaling.
- Gestion des nœuds Debian (Section 12.1.1) : dimensionnement des nœuds, réservation de ressources.

---

## Plan de la section

Cette section 12.4 se décompose en quatre sous-parties couvrant chaque dimension de l'autoscaling et l'optimisation globale :

- **12.4.1 — Horizontal Pod Autoscaler (HPA)** : configuration, métriques (CPU, mémoire, custom, external), algorithme de scaling, comportement de stabilisation, intégration avec Prometheus Adapter.
- **12.4.2 — Vertical Pod Autoscaler (VPA)** : installation, modes de fonctionnement (Off, Initial, Auto), recommandations, interaction avec les LimitRanges et les Resource Quotas.
- **12.4.3 — Cluster Autoscaler** : architecture, intégration cloud et bare-metal, profils de scaling, node pools, expanders et priorités.
- **12.4.4 — Right-sizing et optimisation des ressources** : méthodologie d'optimisation, outils d'analyse (Goldilocks, Kubecost), détection du gaspillage, stratégies de consolidation et bonnes pratiques FinOps.

L'objectif est de fournir les connaissances nécessaires pour passer d'un cluster statiquement dimensionné à un cluster dynamiquement optimisé, capable d'absorber les fluctuations de charge tout en minimisant le gaspillage de ressources.

---

*L'autoscaling n'est pas un mécanisme que l'on active et que l'on oublie. C'est un système de contrôle qui nécessite un paramétrage soigneux, un monitoring continu et des ajustements itératifs. Les sous-sections qui suivent détaillent la configuration, les pièges courants et les bonnes pratiques pour chaque dimension de l'autoscaling.*

⏭️ [Horizontal Pod Autoscaler (HPA)](/module-12-kubernetes-production/04.1-hpa.md)
