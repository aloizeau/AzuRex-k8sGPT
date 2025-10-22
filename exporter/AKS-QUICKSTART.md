# ⚡ AKS Quick Start - K8sGPT Monitoring

## 🔴 Vous Avez Cette Erreur?

```
ErrImageNeverPull: Error from server (BadRequest): container "exporter" in pod 
"k8sgpt-exporter-988946cb6-jww96" is waiting to start: ErrImageNeverPull
```

**Cause:** `deploy-local.ps1` est pour **local clusters** (minikube, kind, Docker Desktop).

**AKS a besoin d'un registry externe!**

---

## ✅ Solution en 1 Ligne (pour AKS)

```powershell
.\deploy-to-aks.ps1 -AcrName myregistry -AksCluster my-aks -ResourceGroup my-rg
```

Remplacez:
- `myregistry` → Votre Azure Container Registry
- `my-aks` → Votre cluster AKS  
- `my-rg` → Votre Resource Group

---

## 🚀 Étapes Rapides

### 1️⃣ Vérifier vos ressources Azure

```powershell
# Lister ACR
az acr list

# Lister AKS
az aks list

# Si manquantes, créer:
az acr create -g MY_RG -n myregistry --sku Basic
az aks create -g MY_RG -n my-aks --node-count 3
```

### 2️⃣ Lancer le script

```powershell
cd exporter
.\deploy-to-aks.ps1 `
  -AcrName myregistry `
  -AksCluster my-aks `
  -ResourceGroup my-rg
```

Le script fera **automatiquement**:
- ✅ Build l'image Docker
- ✅ Push vers ACR
- ✅ Configure AKS
- ✅ Déploie les pods
- ✅ Attend le rollout

### 3️⃣ Vérifier

```powershell
# Pods prêts?
kubectl get pods -n k8sgpt

# Logs?
kubectl logs -n k8sgpt -l app=k8sgpt-exporter -f

# Métriques?
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080
# Puis: curl http://localhost:8080/metrics
```

---

## 📋 Prérequis

- [ ] Azure CLI installé (`az --version`)
- [ ] ACR créé
- [ ] AKS cluster créé  
- [ ] kubectl configuré (`kubectl cluster-info`)
- [ ] Docker installé (`docker --version`)

---

## 🎯 Variables à Utiliser

```powershell
# Pour récupérer vos infos:
az account show --query name
az acr list --query "[].name"
az aks list --query "[].name"
az aks list --query "[].resourceGroup"
```

---

## ✨ Le Script Fait Tout!

```
1. Build image Docker
   ↓
2. Login à ACR
   ↓
3. Push vers ACR
   ↓
4. Attach ACR à AKS
   ↓
5. Update YAML avec image ACR
   ↓
6. Deploy vers AKS
   ↓
7. Wait for rollout
   ↓
8. ✅ DONE!
```

---

## 🐛 Si ça ne marche pas

### Problem: Docker daemon not running
```powershell
# Restart Docker
Restart-Service docker
```

### Problem: ACR not found
```powershell
# Vérifier le nom exact
az acr list --query "[].name"
```

### Problem: AKS credentials invalid
```powershell
# Récupérer credentials
az aks get-credentials -n my-aks -g my-rg --overwrite-existing
```

---

## 📚 Documentation Complète

Voir: `AKS-DEPLOYMENT.md`

---

## 🎉 C'est Tout!

```powershell
.\deploy-to-aks.ps1 -AcrName myregistry -AksCluster my-aks -ResourceGroup my-rg
```

Le reste est automatique! 🚀
