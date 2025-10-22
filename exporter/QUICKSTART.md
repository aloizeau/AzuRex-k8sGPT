# 🎯 RÉSUMÉ - Solution Sans Registry (Quick Start)

## ⚡ 3 Commandes pour Déployer

### Windows (PowerShell)
```powershell
cd exporter
.\deploy-local.ps1 -ClusterType docker-desktop
```

### Linux/Mac (Bash)
```bash
cd exporter
chmod +x deploy-local.sh
./deploy-local.sh
```

### Manuel (All OS)
```bash
# 1. Build
docker build -t k8sgpt-exporter:latest exporter/

# 2. Charger dans le cluster (si minikube/kind)
minikube image load k8sgpt-exporter:latest

# 3. Déployer
kubectl apply -f exporter/k8sgpt-exporter-deployment.yaml
```

---

## ✅ Vérification Rapide

```bash
# Pods running?
kubectl get pods -n k8sgpt

# Service up?
kubectl get svc -n k8sgpt

# Metrics accessible?
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080
curl http://localhost:8080/metrics
```

---

## 📊 Intégration Prometheus

**Option A: Avec Prometheus Operator** (auto)
```bash
kubectl apply -f exporter/k8sgpt-servicemonitor.yaml
```

**Option B: Sans Prometheus Operator** (voir `PROMETHEUS-CONFIG.md`)

---

## 🎨 Dashboard Grafana

Voir le fichier: `exporter/grafana-dashboard.json`

Importer dans Grafana:
1. Dashboards → Import
2. Coller le JSON
3. Sélectionner Prometheus
4. Done! 🎉

---

## 🚫 Pas de Registry Nécessaire

| Étape | Avant (Registry) | Maintenant (Local) |
|-------|-----------------|-------------------|
| Build | Build + Push (5 min) | Build (2 min) |
| Auth | Credentials registry | Aucun |
| Load | Pull depuis registry | Image locale |
| Déploiement | 2-3 min | 30s |

---

## 📁 Fichiers Clés

- **`Dockerfile`** - Image Docker
- **`k8sgpt-exporter.py`** - Code exporter (existe déjà)
- **`deploy-local.ps1`** - Script Windows
- **`deploy-local.sh`** - Script Linux/Mac
- **`k8sgpt-exporter-deployment.yaml`** - Manifest (imagePullPolicy: Never)
- **`k8sgpt-servicemonitor.yaml`** - Prometheus integration
- **`PROMETHEUS-CONFIG.md`** - Configuration détaillée

---

## 🆘 Problèmes?

```bash
# Vérifier les logs
kubectl logs -n k8sgpt -l app=k8sgpt-exporter -f

# Vérifier le status
kubectl describe deployment k8sgpt-exporter -n k8sgpt

# Vérifier l'image
docker images | grep k8sgpt-exporter
```

---

## 🎓 Docs Complètes

- **`GETTING-STARTED.md`** - Guide détaillé
- **`README-LOCAL-DEPLOYMENT.md`** - Troubleshooting
- **`PROMETHEUS-CONFIG.md`** - Configuration Prometheus

---

## ⏱️ Temps Total

- **Setup**: 2-3 minutes
- **Déploiement**: 30-60 secondes
- **Vérification**: 1 minute
- **Total**: ~5 minutes! ✨

---

**Prêt? Lancez le script et profitez!** 🚀
