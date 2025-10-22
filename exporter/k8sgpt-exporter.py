#!/usr/bin/env python3
import json
import subprocess
import time
from prometheus_client import start_http_server, Gauge, Counter, Info
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Métriques Prometheus
k8sgpt_issues_total = Gauge('k8sgpt_issues_total', 'Total number of issues detected by K8sGPT', ['namespace'])
k8sgpt_issues_by_kind = Gauge('k8sgpt_issues_by_kind', 'Issues by Kubernetes resource kind', ['kind', 'namespace'])
k8sgpt_issues_by_severity = Gauge('k8sgpt_issues_by_severity', 'Issues by severity level', ['severity', 'namespace'])
k8sgpt_remediation_available = Gauge('k8sgpt_remediation_available', 'Number of issues with remediation available', ['namespace'])
k8sgpt_last_analysis = Gauge('k8sgpt_last_analysis_timestamp', 'Timestamp of last K8sGPT analysis')
k8sgpt_analysis_errors = Counter('k8sgpt_analysis_errors_total', 'Total number of analysis errors')
k8sgpt_issue_info = Info('k8sgpt_issue', 'Detailed issue information')

def get_k8sgpt_results():
    """Récupère les résultats K8sGPT via kubectl"""
    try:
        result = subprocess.run(
            ['kubectl', 'get', 'results', '-n', 'k8sgpt', '-o', 'json'],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to get K8sGPT results: {e}")
        k8sgpt_analysis_errors.inc()
        return None
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON: {e}")
        k8sgpt_analysis_errors.inc()
        return None

def parse_severity(error_text):
    """Détermine la sévérité basée sur le texte de l'erreur"""
    if any(word in error_text.lower() for word in ['critical', 'failed', 'crash', 'oom']):
        return 'critical'
    elif any(word in error_text.lower() for word in ['warning', 'deprecated', 'misconfigured']):
        return 'warning'
    else:
        return 'info'

def update_metrics():
    """Met à jour les métriques Prometheus"""
    data = get_k8sgpt_results()
    
    if not data or 'items' not in data:
        logger.warning("No K8sGPT results found")
        return
    
    # Reset des métriques
    k8sgpt_issues_total._metrics.clear()
    k8sgpt_issues_by_kind._metrics.clear()
    k8sgpt_issues_by_severity._metrics.clear()
    k8sgpt_remediation_available._metrics.clear()
    
    issues_by_namespace = {}
    issues_by_kind = {}
    issues_by_severity = {}
    remediation_count = {}
    
    for item in data.get('items', []):
        namespace = item.get('metadata', {}).get('namespace', 'default')
        
        # Comptage total par namespace
        issues_by_namespace[namespace] = issues_by_namespace.get(namespace, 0) + 1
        
        # Analyse du spec
        spec = item.get('spec', {})
        kind = spec.get('kind', 'unknown')
        error = spec.get('error', [])
        
        # Comptage par kind
        key = (kind, namespace)
        issues_by_kind[key] = issues_by_kind.get(key, 0) + 1
        
        # Déterminer la sévérité
        if isinstance(error, list):
            error_text = ' '.join([str(e) for e in error])  # Convert all items to strings
        else:
            error_text = str(error)
        severity = parse_severity(error_text)
        sev_key = (severity, namespace)
        issues_by_severity[sev_key] = issues_by_severity.get(sev_key, 0) + 1
        
        # Vérifier si une remédiation est disponible
        if spec.get('details', ''):
            remediation_count[namespace] = remediation_count.get(namespace, 0) + 1
        
        # Info détaillée pour chaque issue
        try:
            k8sgpt_issue_info.info({
                'namespace': namespace,
                'kind': kind,
                'name': str(spec.get('name', 'unknown')),
                'severity': severity,
                'has_remediation': str(bool(spec.get('details', '')))
            })
        except Exception as e:
            logger.warning(f"Could not add issue info: {e}")
    
    # Mise à jour des métriques
    for namespace, count in issues_by_namespace.items():
        k8sgpt_issues_total.labels(namespace=namespace).set(count)
    
    for (kind, namespace), count in issues_by_kind.items():
        k8sgpt_issues_by_kind.labels(kind=kind, namespace=namespace).set(count)
    
    for (severity, namespace), count in issues_by_severity.items():
        k8sgpt_issues_by_severity.labels(severity=severity, namespace=namespace).set(count)
    
    for namespace, count in remediation_count.items():
        k8sgpt_remediation_available.labels(namespace=namespace).set(count)
    
    k8sgpt_last_analysis.set(time.time())
    logger.info(f"Metrics updated: {len(data.get('items', []))} issues found")

def main():
    # Démarrer le serveur HTTP pour Prometheus
    start_http_server(8080)
    logger.info("K8sGPT Prometheus exporter started on port 8080")
    
    while True:
        try:
            update_metrics()
        except Exception as e:
            logger.error(f"Error updating metrics: {e}")
            k8sgpt_analysis_errors.inc()
        
        # Attendre 30 secondes avant la prochaine mise à jour
        time.sleep(30)

if __name__ == '__main__':
    main()