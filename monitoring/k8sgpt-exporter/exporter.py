#!/usr/bin/env python3
"""
Simple PoC exporter that reads K8s custom resources of kind K8sGPT
(core.k8sgpt.ai/v1alpha1) and exposes Prometheus metrics.

Behavior:
- Runs in-cluster if possible (KUBERNETES_SERVICE_HOST present), otherwise uses kubeconfig.
- Polls the k8sgpt CRs every 30s and updates Prometheus metrics.
- Exposes /metrics on port 8080.

Notes:
- This is a PoC. It truncates long text fields and keeps simple metrics.
- Requires: prometheus_client, kubernetes
"""

import os
import time
import logging
from prometheus_client import start_http_server, Gauge, Info
from kubernetes import client, config

# Configuration
POLL_INTERVAL = int(os.getenv('POLL_INTERVAL', '30'))
EXPORTER_PORT = int(os.getenv('EXPORTER_PORT', '8080'))
NAMESPACE = os.getenv('NAMESPACE')  # if set, limit to namespace
TRUNCATE_LABEL = int(os.getenv('TRUNCATE_LABEL', '200'))

# Metrics
# Info metric for each analysis: set value to 1 and include textual labels truncated
analysis_info = Info('k8sgpt_analysis_info', 'Info about k8sGPT analysis (labels include truncated text)')
# Gauge for number of issues by severity
issues_total = Gauge('k8sgpt_analysis_issues_total', 'Number of issues detected by k8sGPT', ['namespace', 'severity'])
# Simple presence metric for a given analysis name
analysis_present = Gauge('k8sgpt_analysis_present', 'Presence of analysis objects', ['namespace', 'analysis_name', 'severity'])

logger = logging.getLogger('k8sgpt-exporter')
logging.basicConfig(level=logging.INFO)


def truncate(s, n=200):
    if s is None:
        return ''
    s = str(s)
    return s if len(s) <= n else s[:n-3] + '...'


def load_k8s_client():
    # Try in-cluster first
    try:
        config.load_incluster_config()
        logger.info('Loaded in-cluster kubernetes config')
    except Exception:
        config.load_kube_config()
        logger.info('Loaded local kubeconfig')
    return client.CustomObjectsApi()


def list_k8sgpt_crs(api):
    group = 'core.k8sgpt.ai'
    version = 'v1alpha1'
    plural = 'k8sgpts'
    if NAMESPACE:
        resp = api.list_namespaced_custom_object(group=group, version=version, namespace=NAMESPACE, plural=plural)
    else:
        resp = api.list_cluster_custom_object(group=group, version=version, plural=plural)
    return resp.get('items', [])


def update_metrics(items):
    # Reset gauges
    # For simplicity, we'll clear by setting to 0 first in a naive way
    # (prometheus_client does not provide delete for Gauge labels easily here)
    seen = set()
    # Zero all previous by iterating label combinations might be needed in prod

    for it in items:
        metadata = it.get('metadata', {})
        namespace = metadata.get('namespace', 'default')
        name = metadata.get('name')
        spec = it.get('spec', {})
        # The shape of spec depends on k8sGPT CR. We try to extract common fields.
        analysis_name = spec.get('analysis', {}).get('name') or name or 'unknown'
        result_summary = spec.get('result', {}).get('summary') or spec.get('ai', {}).get('summary') or ''
        recommended_steps = spec.get('result', {}).get('recommended_steps') or spec.get('ai', {}).get('recommended_steps') or ''
        severity = spec.get('result', {}).get('severity') or 'info'
        issues = spec.get('issues', {}).get('count') if isinstance(spec.get('issues'), dict) else None
        if issues is None:
            # fallback: try status fields
            issues = it.get('status', {}).get('issues_count') or 0

        # Truncate text fields for labels
        rs_trunc = truncate(result_summary, TRUNCATE_LABEL)
        steps_trunc = truncate(recommended_steps, TRUNCATE_LABEL)

        # Update metrics
        # Info can't have label sets dynamically per item directly; use info with unique name label key
        # We'll use the analysis_present Gauge for presence and add info via Info with namespace+name labels
        try:
            analysis_present.labels(namespace=namespace, analysis_name=analysis_name, severity=severity).set(1)
        except Exception as e:
            logger.debug('Failed to set analysis_present: %s', e)

        try:
            issues_total.labels(namespace=namespace, severity=severity).set(int(issues))
        except Exception:
            try:
                issues_total.labels(namespace=namespace, severity=severity).set(0)
            except Exception:
                pass

        # Use Info metric by registering a name combining namespace and analysis_name
        key = f"{namespace}:{analysis_name}"
        try:
            analysis_info.info({
                'key': key,
                'analysis_name': analysis_name,
                'result_summary': rs_trunc,
                'recommended_steps': steps_trunc,
                'severity': severity,
            })
        except Exception as e:
            logger.debug('Failed to set Info metric: %s', e)

        seen.add((namespace, severity))

    # Optionally, zero-out severities not seen. Skipped in PoC.


def main():
    api = load_k8s_client()
    start_http_server(EXPORTER_PORT)
    logger.info('Started metrics server on port %s', EXPORTER_PORT)

    while True:
        try:
            items = list_k8sgpt_crs(api)
            logger.info('Found %d k8sgpt CR(s)', len(items))
            update_metrics(items)
        except Exception as e:
            logger.exception('Error polling k8s API: %s', e)
        time.sleep(POLL_INTERVAL)


if __name__ == '__main__':
    main()
