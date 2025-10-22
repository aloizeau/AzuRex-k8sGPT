# ⚡ Quick Import Grafana Dashboard

## 3 Étapes Simples

### 1️⃣ Copier le JSON

```powershell
# Windows - Copier dans le clipboard
Get-Content "d:\_repos\AzuRex-k8sGPT\exporter\grafana-dashboard-k8sgpt.json" | Set-Clipboard

# Linux/Mac
cat exporter/grafana-dashboard-k8sgpt.json | xclip -selection clipboard
```

### 2️⃣ Ouvrir Grafana et Importer

1. Aller sur: `http://localhost:3000` (ou votre URL Grafana)
2. Cliquer: **Dashboards** → **New** → **Import**
3. Coller le JSON
4. Sélectionner: **Prometheus** (datasource)
5. Cliquer: **Import** ✅

### 3️⃣ Vérifier

- Le dashboard apparaît avec les panels
- Voir les données K8sGPT en live

---

## 📊 Infos Dashboard

| Détail | Valeur |
|--------|--------|
| **Titre** | K8sGPT Monitoring |
| **UID** | k8sgpt-monitoring-v2 |
| **Fichier** | grafana-dashboard-k8sgpt.json |
| **Version** | 1.0 |
| **Tags** | k8sgpt, kubernetes, monitoring |

---

## ✅ Panels Disponibles

1. **Total des Issues** - Gauge avec seuils
2. **Issues par Sévérité** - Pie chart
3. **Évolution Temporelle** - Time series
4. **Par Type Ressource** - Bar chart
5. **Par Namespace** - Bar chart  
6. **Table Active** - Toutes les issues

---

## 🔍 Troubleshooting

**Pas de données?**
```bash
curl http://localhost:8080/metrics | grep k8sgpt_
# Doit retourner des métriques
```

**Erreur import?**
```bash
# Vérifier le JSON
jq . exporter/grafana-dashboard-k8sgpt.json
# Doit afficher le contenu correctement
```

**Prometheus not connected?**
```
Configuration → Data Sources → Prometheus → Test
# Doit afficher "Data source is working"
```

---

**C'est tout! Le dashboard est prêt à être importé.** 🎉
