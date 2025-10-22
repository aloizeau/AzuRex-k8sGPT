# 🚀 Déployer sur AKS avec ACR

## ⚠️ Vous avez AKS? Utilisez Ce Guide!

Le script `deploy-local.ps1` était conçu pour **local clusters** (minikube, kind, Docker Desktop).

Pour **Azure Kubernetes Service (AKS)**, vous devez utiliser un **container registry** comme **Azure Container Registry (ACR)**.

---

## 🎯 Architecture pour AKS

```
┌─────────────────────────────────────────┐
│         Votre Machine                   │
├─────────────────────────────────────────┤
│ 1. Build image Docker                   │
│    docker build -t myregistry/app:v1 . │
│              ↓                          │
│ 2. Push vers ACR                       │
│    docker push myregistry/app:v1       │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│    Azure Container Registry (ACR)       │
│    myregistry.azurecr.io                │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│         AKS Cluster                     │
│  - Pull image depuis ACR               │
│  - Run pod avec image                  │
│  - Expose metrics                      │
└─────────────────────────────────────────┘
```

---

## ✅ Déploiement en 1 Commande

```powershell
# Remplacer les valeurs en MAJUSCULES!

.\deploy-to-aks.ps1 `
  -AcrName MY_REGISTRY `
  -AksCluster MY_AKS_CLUSTER `
  -ResourceGroup MY_RESOURCE_GROUP `
  -ImageTag latest
```

**Exemple réel:**

```powershell
.\deploy-to-aks.ps1 `
  -AcrName azurexregistry `
  -AksCluster azurex-aks `
  -ResourceGroup azurex-rg
```

---

## 📋 Prérequis

### 1️⃣ Azure CLI Installé

```powershell
# Vérifier
az --version

# Sinon installer
winget install microsoft.azurecli
```

### 2️⃣ ACR Existant (ou Créer)

```powershell
# Lister les ACR existants
az acr list -g MY_RESOURCE_GROUP

# Ou créer un nouveau
az acr create `
  --resource-group MY_RESOURCE_GROUP `
  --name MY_REGISTRY `
  --sku Basic
```

### 3️⃣ AKS Cluster Existant

```powershell
# Lister les clusters
az aks list -g MY_RESOURCE_GROUP

# Ou créer un nouveau
az aks create `
  --resource-group MY_RESOURCE_GROUP `
  --name MY_AKS_CLUSTER `
  --node-count 3
```

### 4️⃣ kubectl Configuré

```powershell
# Récupérer les credentials
az aks get-credentials `
  -n MY_AKS_CLUSTER `
  -g MY_RESOURCE_GROUP

# Vérifier
kubectl cluster-info
```

---

## 🔍 Étapes Détaillées (Si vous le faites manuel)

### Step 1: Build l'image

```powershell
$ACR_NAME = "myregistry"
$ACR_DOMAIN = "$ACR_NAME.azurecr.io"
$IMAGE = "$ACR_DOMAIN/k8sgpt-exporter:latest"

docker build -t $IMAGE exporter/
```

### Step 2: Login à ACR

```powershell
az acr login --name $ACR_NAME
```

### Step 3: Push vers ACR

```powershell
docker push $IMAGE
```

Vérifier sur le portail Azure: **Container Registry** → **Repositories**

### Step 4: Attacher ACR à AKS

```powershell
az aks update `
  -n MY_AKS_CLUSTER `
  -g MY_RESOURCE_GROUP `
  --attach-acr $ACR_NAME
```

### Step 5: Mettre à jour le YAML

Éditer `k8sgpt-exporter-deployment.yaml`:

```yaml
containers:
  - name: exporter
    image: myregistry.azurecr.io/k8sgpt-exporter:latest  # ← Votre ACR
    imagePullPolicy: IfNotPresent  # ← Changez de "Never"
```

### Step 6: Déployer

```powershell
kubectl apply -f k8sgpt-exporter-deployment.yaml
```

### Step 7: Vérifier

```powershell
kubectl get pods -n k8sgpt
kubectl logs -n k8sgpt -l app=k8sgpt-exporter -f
```

---

## ✅ Vérification Post-Déploiement

```powershell
# Pods running?
kubectl get pods -n k8sgpt

# Status?
kubectl describe pod -n k8sgpt -l app=k8sgpt-exporter

# Logs?
kubectl logs -n k8sgpt -l app=k8sgpt-exporter --tail=100

# Service prêt?
kubectl get svc -n k8sgpt
```

---

## 🐛 Troubleshooting

### Pod en CrashLoopBackOff?

```powershell
kubectl describe pod -n k8sgpt -l app=k8sgpt-exporter
kubectl logs -n k8sgpt -l app=k8sgpt-exporter
```

### Image not found?

```powershell
# Vérifier que l'image existe dans ACR
az acr repository list -n MY_REGISTRY

# Vérifier le lien ACR-AKS
az aks show -n MY_AKS_CLUSTER -g MY_RESOURCE_GROUP | Select-Object *identity*
```

### Pas de permissions?

```powershell
# Vérifier que AKS peut accéder à ACR
az role assignment list --scope /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{registry}
```

---

## 📊 Configuration Prometheus pour AKS

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'k8sgpt-exporter'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - k8sgpt
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: k8sgpt-exporter
      - source_labels: [__meta_kubernetes_pod_port_name]
        action: keep
        regex: metrics
```

---

## 🎓 Variables à Remplacer

| Variable | Exemple | Où Trouver |
|----------|---------|-----------|
| `MY_REGISTRY` | `azurexregistry` | Azure Portal → ACR → Overview |
| `MY_AKS_CLUSTER` | `azurex-aks` | Azure Portal → Kubernetes Services |
| `MY_RESOURCE_GROUP` | `azurex-rg` | Azure Portal → Resource Groups |
| `MY_SUBSCRIPTION_ID` | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | `az account show --query id` |

---

## 🔐 Authentification ACR

### Option 1: Service Principal (Recommandé)

```powershell
# Créer Service Principal
az ad sp create-for-rbac `
  --name k8sgpt-exporter-sp `
  --role acrpull `
  --scopes /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{registry}
```

### Option 2: Admin User

```powershell
# Activer Admin User
az acr update -n MY_REGISTRY --admin-enabled true

# Récupérer credentials
az acr credential show -n MY_REGISTRY
```

---

## 📈 Prochaines Étapes

1. ✅ Configurer ACR et AKS
2. ✅ Lancer `deploy-to-aks.ps1`
3. ✅ Vérifier les pods
4. ⏭️ Configurer Prometheus
5. ⏭️ Importer dashboard Grafana
6. ⏭️ Configurer alertes

---

## 💡 Besoin d'Aide?

Erreur spécifique? Vérifiez:

- **Docker build échoue**: `docker build -t ... --progress=plain`
- **Push fails**: `az acr login -n MY_REGISTRY` et retry
- **Pod won't start**: `kubectl describe pod ...`
- **Permissions denied**: Vérifier Service Principal ou Admin User

---

**Vous êtes prêt pour AKS! 🚀**

C'est beaucoup plus simple avec le script `deploy-to-aks.ps1` en une seule commande! 😉
