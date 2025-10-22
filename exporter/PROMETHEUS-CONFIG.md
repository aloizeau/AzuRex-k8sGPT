# Configuration Prometheus - Sans Registry

Cette configuration explique comment configurer Prometheus pour scraper les métriques K8sGPT **sans container registry**.

## 📋 Prérequis

- ✅ Image Docker `k8sgpt-exporter:latest` déployée dans Kubernetes
- ✅ Service `k8sgpt-exporter` déployé dans le namespace `k8sgpt`
- ✅ Prometheus en cours d'exécution dans le cluster

## 🔧 Option 1: Avec Prometheus Operator (Recommandée)

### Créer le ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: k8sgpt-exporter
  namespace: k8sgpt
  labels:
    app: k8sgpt-exporter
    prometheus: kube-prometheus  # À adapter selon votre config
spec:
  selector:
    matchLabels:
      app: k8sgpt-exporter
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    scrapeTimeout: 10s
```

### Déployer

```bash
kubectl apply -f k8sgpt-servicemonitor.yaml

# Vérifier
kubectl get servicemonitor -n k8sgpt
```

## 🔧 Option 2: Sans Prometheus Operator

### Mettre à jour prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Configuration K8sGPT
  - job_name: 'k8sgpt-exporter'
    scrape_interval: 30s
    static_configs:
      - targets: ['k8sgpt-exporter.k8sgpt.svc.cluster.local:8080']
```

### Ou via Kubernetes Service Discovery

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
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
```

## ✅ Vérification

### 1. Port Forward à Prometheus

```bash
kubectl port-forward -n prometheus svc/prometheus 9090:9090
```

### 2. Accéder à http://localhost:9090

### 3. Vérifier les cibles

Aller dans: **Status** → **Targets**

Vous devriez voir `k8sgpt-exporter` avec le statut `UP` (vert)

### 4. Tester une requête

Aller dans: **Graph**

Entrez la requête:
```promql
k8sgpt_issues_total
```

Vous devriez voir les données remontées

## 🚨 Troubleshooting

### Les cibles affichent DOWN

```bash
# Vérifier la connectivité
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://k8sgpt-exporter.k8sgpt.svc.cluster.local:8080/metrics

# Vérifier les logs du pod exporter
kubectl logs -n k8sgpt -l app=k8sgpt-exporter
```

### Pas de résultats K8sGPT trouvés

```bash
# Vérifier que les résultats existent
kubectl get results -n k8sgpt

# Si vide, K8sGPT n'a pas tourné
# Attendre ou vérifier le status du pod K8sGPT
kubectl get pods -n k8sgpt
```

### La requête Prometheus ne retourne rien

```bash
# Tester directement l'exporter
kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080

# Dans un autre terminal
curl http://localhost:8080/metrics | grep k8sgpt_issues_total
```

## 📊 Métriques Disponibles

Après configuration, les métriques suivantes doivent être disponibles:

- `k8sgpt_issues_total` - Total d'issues par namespace
- `k8sgpt_issues_by_kind` - Issues par type de ressource
- `k8sgpt_issues_by_severity` - Issues par sévérité
- `k8sgpt_remediation_available` - Issues avec remédiation
- `k8sgpt_last_analysis_timestamp` - Timestamp dernière analyse
- `k8sgpt_analysis_errors_total` - Total d'erreurs d'analyse
- `k8sgpt_issue` - Info détaillée par issue

## 🎯 Requêtes PromQL Utiles

### Issues par sévérité

```promql
sum by (severity) (k8sgpt_issues_by_severity)
```

### Issues sans remédiation

```promql
k8sgpt_issues_total - k8sgpt_remediation_available
```

### Taux d'erreur par minute

```promql
rate(k8sgpt_analysis_errors_total[5m])
```

### Évolution des issues

```promql
increase(k8sgpt_issues_total[1h])
```

## 🚨 Alertes Recommandées

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: k8sgpt-alerts
  namespace: k8sgpt
spec:
  groups:
  - name: k8sgpt.rules
    interval: 30s
    rules:
    - alert: K8sGPTCriticalIssues
      expr: sum(k8sgpt_issues_by_severity{severity="critical"}) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Issues critiques détectées par K8sGPT"

    - alert: K8sGPTTooManyIssues
      expr: sum(k8sgpt_issues_total) > 20
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Trop d'issues détectées"
```

Prêt à importer le dashboard Grafana ? 🎉
