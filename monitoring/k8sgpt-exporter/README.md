# k8sGPT Exporter PoC

This PoC reads the Kubernetes Custom Resources of kind `K8sGPT` (group `core.k8sgpt.ai/v1alpha1`) and exposes basic Prometheus metrics.

Files:

- `exporter.py` - PoC Python exporter
- `requirements.txt` - Python dependencies
- `k8s-manifest.yml` - Namespace/ServiceAccount/Role/RoleBinding/Deployment/Service/ConfigMap

Install (quick, for testing):

1. Apply the manifest:

```powershell
kubectl apply -f monitoring/k8sgpt-exporter/k8s-manifest.yml
```

Note: The ConfigMap contains the exporter script. The Deployment image uses `python:3.11-slim` and installs dependencies at container start (slow for prod).

1. Forward port locally to test metrics:

```powershell
kubectl port-forward -n k8sgpt-monitoring svc/k8sgpt-exporter 8080:8080
Invoke-RestMethod -Uri http://localhost:8080/metrics
```

Configuration:

- Use environment variables in the Deployment (`POLL_INTERVAL`, `EXPORTER_PORT`, `TRUNCATE_LABEL`, `NAMESPACE`) to tune.
- The exporter expects read access to the CRD: Role grants get/list/watch on `k8sgpts` in the `core.k8sgpt.ai` group.

Limitations & next steps:

- The PoC stores long text in labels/info; Prometheus isn't ideal for long free-form text. For full text steps, prefer Loki or Elasticsearch and use a log exporter.
- Consider building a small HTTP server that exposes JSON of analyses and use Loki/Fluentbit to ship or create a dedicated exporter image.
- Production: build an image with dependencies preinstalled rather than pip install at runtime, and improve metric cleanup handling.
