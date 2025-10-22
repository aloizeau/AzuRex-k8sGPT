# Guide de Déploiement - Sans Container Registry

## 🎯 Vue d'ensemble

Cette solution permet de déployer le monitoring K8sGPT **sans aucun container registry** (Docker Hub, ACR, ECR, etc.).

L'image Docker est buildée localement et chargée directement dans le cluster.

## 📋 Prérequis

- Docker installé localement
- kubectl configuré
- Cluster Kubernetes en local (minikube, kind) OU Docker Desktop Kubernetes
- bash/PowerShell

## 🚀 Installation Rapide

### Option 1: Bash (Linux/Mac/WSL)

```bash
cd exporter
chmod +x deploy-local.sh
./deploy-local.sh
```

### Option 2: PowerShell (Windows)

```powershell
cd exporter

# Build l'image
docker build -t k8sgpt-exporter:latest .

# Charger dans le cluster (si minikube)
minikube image load k8sgpt-exporter:latest

# Déployer
kubectl apply -f k8sgpt-exporter-deployment.yaml
```

## 📝 Étapes Détaillées

### 1️⃣ Build l'image Docker

```bash
cd exporter
docker build -t k8sgpt-exporter:latest .
```

**Resultat:**
```
$ docker images | grep k8sgpt
k8sgpt-exporter     latest    abc123def456    5 minutes ago    500MB
```

### 2️⃣ Charger l'image dans le cluster

#### Pour **minikube**:
```bash
minikube image load k8sgpt-exporter:latest
```

#### Pour **kind**:
```bash
kind load docker-image k8sgpt-exporter:latest
```

#### Pour **Docker Desktop Kubernetes**:
L'image est automatiquement disponible (pas de step supplémentaire)

### 3️⃣ Déployer les ressources

```bash
kubectl apply -f k8sgpt-exporter-deployment.yaml
```

**Vérifier le déploiement:**
```bash
kubectl get pods -n k8sgpt
kubectl describe deployment k8sgpt-exporter -n k8sgpt
```

## ✅ Vérification

### Vérifier que le pod est en cours d'exécution

```bash
kubectl get pods -n k8sgpt -w

# Output attendu:
# NAME                                READY   STATUS    RESTARTS   AGE
# k8sgpt-exporter-abc123-xyz789       1/1     Running   0          2m
```

### Vérifier les logs

```bash
kubectl logs -n k8sgpt -l app=k8sgpt-exporter

# Output attendu:
# INFO:root:K8sGPT Prometheus exporter started on port 8080
# INFO:root:Metrics updated: 5 issues found
```

### Tester les métriques

```bash
# Via port-forward
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080

# Dans un autre terminal
curl http://localhost:8080/metrics

# Output:
# # HELP k8sgpt_issues_total Total number of issues detected by K8sGPT
# # TYPE k8sgpt_issues_total gauge
# k8sgpt_issues_total{namespace="default"} 5.0
# ...
```

## 🔄 Mise à Jour de l'Image

Si vous modifiez le code Python:

```bash
# 1. Rebuild l'image
docker build -t k8sgpt-exporter:latest .

# 2. Recharger dans le cluster
minikube image load k8sgpt-exporter:latest  # ou kind

# 3. Redéployer les pods
kubectl rollout restart deployment/k8sgpt-exporter -n k8sgpt

# 4. Vérifier les new pods
kubectl get pods -n k8sgpt -w
```

## 📊 Configuration Prometheus

### Option A: Avec Prometheus Operator

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: k8sgpt-exporter
  namespace: k8sgpt
spec:
  selector:
    matchLabels:
      app: k8sgpt-exporter
  endpoints:
  - port: metrics
    interval: 30s
```

### Option B: Sans Prometheus Operator

Dans votre `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'k8sgpt-exporter'
    static_configs:
      - targets: ['k8sgpt-exporter.k8sgpt.svc.cluster.local:8080']
    scrape_interval: 30s
```

Ou via Kubernetes service discovery:

```yaml
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

## 🐛 Troubleshooting

### L'image n'est pas trouvée

**Erreur:**
```
Failed to pull image "k8sgpt-exporter:latest": rpc error: code = Unknown desc = Error response from daemon
```

**Solution:**
```bash
# Vérifier que l'image est chargée
docker images | grep k8sgpt

# Si absent, rebuilder
docker build -t k8sgpt-exporter:latest .

# Recharger dans le cluster
minikube image load k8sgpt-exporter:latest
```

### Le pod reste en CrashLoopBackOff

**Vérifier les logs:**
```bash
kubectl logs -n k8sgpt -l app=k8sgpt-exporter

# ou avec plus de détails
kubectl describe pod -n k8sgpt -l app=k8sgpt-exporter
```

**Causes communes:**
- kubectl n'est pas disponible dans le container
- Permissions RBAC insuffisantes
- Python dépendances manquantes

### Pas de résultats K8sGPT

```bash
# Vérifier que K8sGPT a produit des résultats
kubectl get results -n k8sgpt

# Si vide, K8sGPT n'a pas encore tourné
# Attendre ou vérifier le statut du pod K8sGPT
kubectl get pods -n k8sgpt
```

## 📊 Grafana Import

1. **Accéder à Grafana**
2. **Dashboards** → **Import**
3. **Paste JSON** (voir `grafana-dashboard.json`)
4. **Sélectionner Prometheus** comme datasource
5. **Import**

## 🔐 Sécurité

### Ajouter des limits

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Ajouter des Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /metrics
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /metrics
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

## 📦 Comparaison: Avec vs Sans Registry

| Aspect | Avec Registry | Sans Registry |
|--------|---------------|---------------|
| Setup Complexity | Moyen | Simple |
| Dépendances Externes | Registry (Docker Hub/ACR) | Aucune |
| Build Time | 5-10 min (including push) | 2-3 min |
| Temps Deployment | 1-2 min | 30 secondes |
| Scaling Multi-node | Facile | Nécessite image sur chaque node |
| Production Ready | ✅ | ⚠️ (local only) |

## 🎓 Prochaines Étapes

1. ✅ Déployer l'exporter
2. ✅ Configurer Prometheus
3. ⏭️ **Importer le dashboard Grafana**
4. ⏭️ Configurer les alertes
5. ⏭️ Mettre en place Teams webhooks

Besoin d'aide sur une étape spécifique ?
