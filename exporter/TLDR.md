# 🎯 TL;DR - Solution K8sGPT Monitoring Sans Registry

## ⚡ EN 30 SECONDES

**Le problème**: Vous voulez déployer K8sGPT exporter sans registry externe (Docker Hub, ACR, etc.)

**La solution**: Build local + ImagePullPolicy: Never + Scripts automatisés

## 🚀 LET'S GO (3 COMMANDES)

```powershell
# Windows PowerShell
cd exporter
.\deploy-local.ps1 -ClusterType docker-desktop
```

```bash
# Linux/Mac
cd exporter && chmod +x deploy-local.sh && ./deploy-local.sh
```

## ✅ VÉRIFIER

```bash
kubectl get pods -n k8sgpt
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080
curl http://localhost:8080/metrics
```

## 📁 CE QUI A ÉTÉ CRÉÉ

| Type | Fichier | Raison |
|------|---------|--------|
| **Doc** | QUICKSTART.md | Démarrage rapide |
| **Doc** | GETTING-STARTED.md | Guide complet |
| **Docker** | Dockerfile | Build image |
| **K8s** | k8sgpt-exporter-deployment.yaml | Deploy (imagePullPolicy: Never) |
| **Script** | deploy-local.ps1 | Automation (Windows) |
| **Script** | deploy-local.sh | Automation (Linux/Mac) |

## ⏱️ TIMING

| Étape | Durée |
|-------|-------|
| Build image | 2-3 min |
| Deploy K8s | 30-60 sec |
| **Total** | **~5 min** ⚡ |

## 🎯 ARCHITECTURE

```
Code modifié?    → Build image
                 ↓
Image buildée?   → Load dans cluster (minikube/kind/docker-desktop)
                 ↓
Image en cluster? → Deploy (imagePullPolicy: Never)
                 ↓
Pod running?     → Expose metrics /metrics:8080
                 ↓
Prometheus scrape → Grafana visualize → Done!
```

## 💡 CLÉS DU SUCCÈS

1. **`imagePullPolicy: Never`** ← CRUCIAL dans le YAML
2. **Build local**: `docker build -t k8sgpt-exporter:latest .`
3. **Load cluster**: `minikube image load k8sgpt-exporter:latest`
4. **Deploy**: `kubectl apply -f deployment.yaml`

## 🆘 PROBLÈMES?

```bash
# Vérifier les logs
kubectl logs -n k8sgpt -l app=k8sgpt-exporter

# Reset complet
kubectl delete deployment k8sgpt-exporter -n k8sgpt
# ... relancer le script
```

## 📚 DOCS COMPLÈTES

- **Commencer**: `QUICKSTART.md`
- **Détails**: `GETTING-STARTED.md`
- **Problèmes**: `README-LOCAL-DEPLOYMENT.md`
- **Prometheus**: `PROMETHEUS-CONFIG.md`

## 🎉 NEXT STEPS

1. Lancer le script
2. Vérifier les pods
3. Configurer Prometheus
4. Importer Grafana dashboard

---

**C'est tout! You're all set. 🚀**
