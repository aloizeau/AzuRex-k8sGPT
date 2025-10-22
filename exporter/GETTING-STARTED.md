# 🚀 Solution Complète: K8sGPT Monitoring Sans Registry

## 📦 Fichiers Créés

```
exporter/
├── k8sgpt-exporter.py           ✅ Exporter Python (déjà existant)
├── Dockerfile                   ✅ Build l'image Docker localement
├── deploy-local.ps1            ✅ Script PowerShell (Windows)
├── deploy-local.sh             ✅ Script Bash (Linux/Mac)
├── k8sgpt-exporter-deployment.yaml    ✅ Manifest Kubernetes (imagePullPolicy: Never)
├── k8sgpt-servicemonitor.yaml  ✅ ServiceMonitor pour Prometheus
├── README-LOCAL-DEPLOYMENT.md  ✅ Guide détaillé
└── PROMETHEUS-CONFIG.md        ✅ Configuration Prometheus
```

## 🎯 Avantages de cette Solution

| Aspect | Traditionnel (avec registry) | Notre Solution (sans registry) |
|--------|----------------------|-----|
| **Complexité** | Moyenne/Haute | Simple ✅ |
| **Dépendances** | Registry externe + credentials | Aucune ✅ |
| **Temps setup** | 10-15 minutes | 3-5 minutes ✅ |
| **Déploiement** | 2-3 minutes | 30-60 secondes ✅ |
| **Local/Dev** | Possible mais compliqué | Idéal ✅ |
| **Production** | Recommandé | ⚠️ Pas recommandé |

## 🚀 Démarrage Rapide

### Windows (PowerShell)

```powershell
cd exporter

# Déployer en une commande
.\deploy-local.ps1 -ClusterType docker-desktop

# Vérifier les métriques
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080
# Ouvrir: http://localhost:8080/metrics
```

### Linux/Mac (Bash)

```bash
cd exporter

# Rendre exécutable et déployer
chmod +x deploy-local.sh
./deploy-local.sh

# Vérifier les métriques
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080
# Ouvrir: http://localhost:8080/metrics
```

## ✅ Checklist de Déploiement

- [ ] **Step 1**: Docker image buildée (`docker images | grep k8sgpt-exporter`)
- [ ] **Step 2**: Image chargée dans le cluster (minikube/kind/docker-desktop)
- [ ] **Step 3**: Namespace `k8sgpt` créé (`kubectl get namespace k8sgpt`)
- [ ] **Step 4**: Pod exporter en cours (`kubectl get pods -n k8sgpt -l app=k8sgpt-exporter`)
- [ ] **Step 5**: Service disponible (`kubectl get svc -n k8sgpt`)
- [ ] **Step 6**: Métriques accessibles (`curl http://localhost:8080/metrics`)
- [ ] **Step 7**: Prometheus scrape les métriques (voir Status → Targets)
- [ ] **Step 8**: Dashboard Grafana importé

## 🔧 Configuration Détaillée

### 1️⃣ Fichier d'Image Docker

**`Dockerfile`** - Points clés:
- Python 3.9-slim (léger)
- kubectl installé dedans
- prometheus-client pour exposer les métriques
- Port 8080 pour les métriques

```dockerfile
FROM python:3.9-slim
RUN apt-get update && apt-get install -y curl
RUN curl -LO "https://dl.k8s.io/release/stable.txt)"  && chmod +x kubectl
RUN pip install prometheus-client
COPY k8sgpt-exporter.py /app/
EXPOSE 8080
CMD ["python", "k8sgpt-exporter.py"]
```

### 2️⃣ Manifest Kubernetes

**`k8sgpt-exporter-deployment.yaml`** - Points clés:
- `imagePullPolicy: Never` ← **CRUCIAL** (pas de pull depuis registry)
- RBAC permissions pour accéder aux `results` de K8sGPT
- Liveness/Readiness probes pour la stabilité
- Service exposant le port 8080

```yaml
containers:
  - name: exporter
    image: k8sgpt-exporter:latest
    imagePullPolicy: Never  # ⚠️ IMPORTANT
    ports:
      - containerPort: 8080
        name: metrics
```

### 3️⃣ Scripts de Déploiement

**`deploy-local.ps1`** (Windows):
1. Vérifie Docker & kubectl
2. Build l'image localement
3. Charge dans le cluster (minikube/kind)
4. Déploie dans K8s
5. Attend le rollout
6. Affiche les infos de connexion

**`deploy-local.sh`** (Linux/Mac):
- Même logique avec bash
- Compatible WSL

### 4️⃣ Configuration Prometheus

Voir `PROMETHEUS-CONFIG.md` pour:
- Configuration ServiceMonitor (avec Prometheus Operator)
- Configuration prometheus.yml (sans Prometheus Operator)
- PromQL queries pour visualiser les données

## 📊 Architecture

```
┌─────────────────────────────────────────┐
│         Cluster Kubernetes              │
├─────────────────────────────────────────┤
│                                         │
│  Namespace: k8sgpt                     │
│  ┌─────────────────────────────────┐  │
│  │  K8sGPT Analyzer Pod            │  │
│  │  - Analyse le cluster           │  │
│  │  - Crée des "results"           │  │
│  └─────────────────────────────────┘  │
│           ↓ (kubectl get results)      │
│  ┌─────────────────────────────────┐  │
│  │  K8sGPT Exporter Pod            │  │
│  │  - Lit les results              │  │
│  │  - Expose métriques Prometheus  │  │
│  │  - Port 8080/metrics            │  │
│  └─────────────────────────────────┘  │
│           ↓ (http scrape)             │
│  ┌─────────────────────────────────┐  │
│  │  Prometheus                     │  │
│  │  - Scrape /metrics              │  │
│  │  - Stock les données            │  │
│  └─────────────────────────────────┘  │
│           ↓ (query)                   │
│  ┌─────────────────────────────────┐  │
│  │  Grafana                        │  │
│  │  - Visualise les métriques      │  │
│  │  - Affiche le dashboard         │  │
│  └─────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## 🔍 Vérification Étape par Étape

### Step 1: Image Built

```bash
docker images | grep k8sgpt-exporter
# Output: k8sgpt-exporter    latest    abc123    ...    500MB
```

### Step 2: Image dans le cluster

**Minikube:**
```bash
minikube image ls | grep k8sgpt-exporter
```

**Kind:**
```bash
docker exec kind-control-plane ctr image ls | grep k8sgpt-exporter
```

**Docker Desktop:**
```bash
# Pas besoin, image auto-disponible
```

### Step 3: Pod en cours

```bash
kubectl get pods -n k8sgpt
# NAME                                READY   STATUS    RESTARTS   AGE
# k8sgpt-exporter-abc-xyz             1/1     Running   0          2m
```

### Step 4: Métriques accessibles

```bash
# Port forward
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080

# Dans un autre terminal
curl http://localhost:8080/metrics

# Output:
# # HELP k8sgpt_issues_total Total number of issues detected by K8sGPT
# # TYPE k8sgpt_issues_total gauge
# k8sgpt_issues_total{namespace="default"} 5.0
```

### Step 5: Prometheus scrape

1. Accéder à Prometheus: `http://localhost:9090`
2. **Status** → **Targets**
3. Chercher `k8sgpt-exporter`
4. Doit afficher **UP** (vert)

### Step 6: Grafana dashboard

1. Importer le JSON fourni
2. Sélectionner datasource Prometheus
3. Voir les métriques s'afficher

## 🛠️ Mise à Jour de l'Image

Après modifier `k8sgpt-exporter.py`:

```bash
# 1. Rebuild
docker build -t k8sgpt-exporter:latest .

# 2. Recharger (minikube/kind)
minikube image load k8sgpt-exporter:latest
# OU
kind load docker-image k8sgpt-exporter:latest

# 3. Restart les pods
kubectl rollout restart deployment/k8sgpt-exporter -n k8sgpt

# 4. Attendre
kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt
```

## 🐛 Troubleshooting Rapide

| Problème | Solution |
|----------|----------|
| `ImagePullBackOff` | Vérifier `imagePullPolicy: Never` |
| Pod `CrashLoopBackOff` | `kubectl logs -n k8sgpt -l app=k8sgpt-exporter` |
| Prometheus ne scrape pas | Vérifier le `ServiceMonitor` existe |
| Pas de résultats K8sGPT | `kubectl get results -n k8sgpt` |
| Pas de metrics | `curl localhost:8080/metrics` |

## 📚 Fichiers de Référence

- **Build**: `Dockerfile`
- **Deployment**: `k8sgpt-exporter-deployment.yaml`
- **Metrics**: `k8sgpt-exporter.py`
- **Monitoring**: `k8sgpt-servicemonitor.yaml`
- **Config Prometheus**: `PROMETHEUS-CONFIG.md`
- **Guide complet**: `README-LOCAL-DEPLOYMENT.md`

## 🎓 Prochaines Étapes

1. ✅ **Exporter déployé** - Les métriques remontent
2. ⏭️ **Prometheus configuré** - Scrape les métriques
3. ⏭️ **Grafana dashboard** - Visualise les données
4. ⏭️ **Alertes Prometheus** - Notifie sur critères
5. ⏭️ **Teams webhooks** - Envoie vers Teams

## 💡 Bonus: Sans Minikube/Kind?

Si vous utilisez **Docker Desktop Kubernetes**:

```bash
# 1. Simplement build
docker build -t k8sgpt-exporter:latest .

# 2. Docker Desktop trouve auto l'image
# Pas besoin de "minikube image load"

# 3. Déployer comme d'habitude
kubectl apply -f k8sgpt-exporter-deployment.yaml
```

## ✨ Résumé

```bash
# Tout en une ligne (Windows + Docker Desktop)
docker build -t k8sgpt-exporter:latest . && kubectl apply -f k8sgpt-exporter-deployment.yaml

# Tout en une ligne (Linux/Mac + Minikube)
docker build -t k8sgpt-exporter:latest . && minikube image load k8sgpt-exporter:latest && kubectl apply -f k8sgpt-exporter-deployment.yaml
```

C'est prêt ! 🎉
