# 📊 Importer le Dashboard Grafana K8sGPT

## ✅ Changements Effectués

Le nouveau dashboard a été créé avec:
- ✅ **Titre**: "K8sGPT Monitoring"
- ✅ **UID**: "k8sgpt-monitoring-v2"
- ✅ **Fichier**: `grafana-dashboard-k8sgpt.json`
- ✅ **Panels**: Simplifiés et optimisés pour la compatibilité

---

## 🚀 Comment Importer dans Grafana

### Option 1: Via l'Interface Web (Recommandé)

1. **Ouvrir Grafana**
   ```
   http://localhost:3000
   # ou votre URL Grafana
   ```

2. **Aller dans Dashboards**
   - Menu → Dashboards → New → Import

3. **Importer le JSON**
   - Coller le contenu de: `grafana-dashboard-k8sgpt.json`
   - OU cliquer "Upload JSON file"

4. **Sélectionner la datasource**
   - Choisir: **Prometheus**

5. **Cliquer Import**
   - Dashboard s'affiche automatiquement ✅

### Option 2: Via kubectl (si Grafana est en K8s)

```bash
# Créer ConfigMap avec le dashboard
kubectl create configmap grafana-k8sgpt-dashboard \
  --from-file=grafana-dashboard-k8sgpt.json \
  -n monitoring

# Label pour auto-discovery (si configuré)
kubectl label configmap grafana-k8sgpt-dashboard \
  grafana_dashboard=1 \
  -n monitoring
```

### Option 3: Via Docker/Compose

```yaml
volumes:
  - ./grafana-dashboard-k8sgpt.json:/etc/grafana/provisioning/dashboards/k8sgpt.json
```

---

## 📋 Panels Inclus

| Panel | Description |
|-------|-------------|
| **Total des Issues** | Stat card avec seuils (vert/jaune/rouge) |
| **Issues par Sévérité** | Pie chart (critical/warning/info) |
| **Évolution des Issues** | Time series avec tendance |
| **Issues par Ressource** | Bar chart (type de ressource) |
| **Issues par Namespace** | Bar chart (namespaces) |
| **Tableau Actif** | Table avec toutes les issues |

---

## ✅ Variables Disponibles

- **Namespace**: Filtrer par namespace (multi-select)
- **Severity**: Filtrer par sévérité (multi-select)

---

## 🔍 Vérifier la Connexion Prometheus

Avant d'importer, vérifiez:

```bash
# Depuis Grafana, aller dans Configuration → Data Sources
# Vérifier que Prometheus est:
# ✅ Configured
# ✅ Connected (Status: Success)

# Test manuel
curl http://prometheus:9090/api/v1/query?query=k8sgpt_issues_total
```

---

## 🐛 Si ça ne marche pas

### Problem: Dashboard blank (pas de données)

```bash
# Vérifier que les métriques existent
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080

# Dans un autre terminal
curl http://localhost:8080/metrics | grep k8sgpt_

# Doit afficher des métriques:
# k8sgpt_issues_total{namespace="default"} 5.0
# k8sgpt_issues_by_severity{namespace="default",severity="warning"} 2.0
```

### Problem: Erreur d'import

- Vérifier que le JSON est valide: `jq . grafana-dashboard-k8sgpt.json`
- Essayer avec un datasource vide d'abord
- Utiliser l'UID unique: `k8sgpt-monitoring-v2`

### Problem: Prometheus pas de données

```bash
# Vérifier que Prometheus scrape les métriques
# Dans Prometheus UI: Status → Targets
# Chercher k8sgpt-exporter (doit être GREEN)
```

---

## 📝 Notes

- Le dashboard auto-refresh toutes les 30s
- Les variables permettent de filtrer dynamiquement
- Les seuils de couleur sont configurés:
  - 🟢 Green: < 5 issues
  - 🟡 Yellow: 5-9 issues
  - 🔴 Red: ≥ 10 issues

---

## 🎉 Résumé

**Nouveau fichier**: `grafana-dashboard-k8sgpt.json`

```powershell
# Récupérer le contenu
Get-Content "d:\_repos\AzuRex-k8sGPT\exporter\grafana-dashboard-k8sgpt.json" | Set-Clipboard

# Puis dans Grafana:
# 1. Dashboards → New → Import
# 2. Coller le JSON
# 3. Sélectionner Prometheus
# 4. Click Import
```

C'est prêt! 🚀
