# Essential Commands - K8sGPT Monitoring

## 🚀 DÉPLOIEMENT

```bash
# Windows PowerShell
cd exporter
.\deploy-local.ps1 -ClusterType docker-desktop

# Linux/Mac
cd exporter
chmod +x deploy-local.sh
./deploy-local.sh
```

## ✅ VÉRIFICATION

```bash
# Pods en cours?
kubectl get pods -n k8sgpt

# Service prêt?
kubectl get svc -n k8sgpt

# Déploiement status?
kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt

# Logs exporter?
kubectl logs -n k8sgpt -l app=k8sgpt-exporter -f

# Détails pod?
kubectl describe pod -n k8sgpt -l app=k8sgpt-exporter
```

## 📊 MÉTRIQUES

```bash
# Port forward
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080

# Tester (autre terminal)
curl http://localhost:8080/metrics

# Voir toutes les métriques k8sgpt
curl http://localhost:8080/metrics | grep k8sgpt_

# Métriques JSON (via Python)
python -m json.tool <<< "$(curl http://localhost:8080/metrics)"
```

## 🔄 MISE À JOUR

```bash
# Rebuild après modif du code
docker build -t k8sgpt-exporter:latest exporter/

# Charger dans cluster (minikube/kind)
minikube image load k8sgpt-exporter:latest
# OU
kind load docker-image k8sgpt-exporter:latest

# Restart pods
kubectl rollout restart deployment/k8sgpt-exporter -n k8sgpt

# Attendre
kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt

# Vérifier les new pods
kubectl get pods -n k8sgpt -w
```

## 🐛 TROUBLESHOOTING

```bash
# Pod stuck?
kubectl describe pod -n k8sgpt -l app=k8sgpt-exporter

# Events?
kubectl get events -n k8sgpt

# All pods status
kubectl get pods -n k8sgpt -o wide

# Resource usage
kubectl top pods -n k8sgpt

# Delete et redeploy
kubectl delete deployment k8sgpt-exporter -n k8sgpt
kubectl apply -f exporter/k8sgpt-exporter-deployment.yaml
```

## 📈 PROMETHEUS

```bash
# Vérifier ServiceMonitor
kubectl get servicemonitor -n k8sgpt

# Vérifier Prometheus scrape
kubectl port-forward -n prometheus svc/prometheus 9090:9090
# Aller à: http://localhost:9090/targets

# Query dans Prometheus
# Graph tab -> Entrer: k8sgpt_issues_total
```

## 🎨 GRAFANA

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# URL
# http://localhost:3000

# Import dashboard:
# 1. Dashboards → New → Import
# 2. Coller contenu de: grafana-dashboard.json
# 3. Sélectionner: Prometheus datasource
# 4. Click: Import
```

## 🔍 DIAGNOSTIC COMPLET

```bash
# All in one check
echo "=== PODS ===" && kubectl get pods -n k8sgpt && \
echo "=== SERVICES ===" && kubectl get svc -n k8sgpt && \
echo "=== DEPLOYMENT STATUS ===" && kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt && \
echo "=== RECENT LOGS ===" && kubectl logs -n k8sgpt -l app=k8sgpt-exporter --tail=20 && \
echo "=== METRICS TEST ===" && kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080 &
sleep 2 && curl -s http://localhost:8080/metrics | head -20
```

## 🗑️ CLEANUP

```bash
# Supprimer exporter
kubectl delete deployment k8sgpt-exporter -n k8sgpt
kubectl delete service k8sgpt-exporter -n k8sgpt
kubectl delete serviceaccount k8sgpt-exporter -n k8sgpt
kubectl delete clusterrole k8sgpt-exporter
kubectl delete clusterrolebinding k8sgpt-exporter

# Supprimer image Docker
docker rmi k8sgpt-exporter:latest
```

## 💾 BACKUP/EXPORT

```bash
# Export la configuration
kubectl get deployment k8sgpt-exporter -n k8sgpt -o yaml > backup-deployment.yaml
kubectl get service k8sgpt-exporter -n k8sgpt -o yaml > backup-service.yaml

# Export les métriques actuelles
curl http://localhost:8080/metrics > k8sgpt-metrics-backup.txt
```

## 🎯 UNE SEULE COMMANDE

```bash
# Déployer + Vérifier + Afficher metrics
docker build -t k8sgpt-exporter:latest exporter/ && \
minikube image load k8sgpt-exporter:latest && \
kubectl apply -f exporter/k8sgpt-exporter-deployment.yaml && \
kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt && \
echo "✅ Déployé! Accès aux metrics:" && \
echo "kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080" && \
echo "curl http://localhost:8080/metrics"
```

---

**Sauvegardez cette page! 🚀**
