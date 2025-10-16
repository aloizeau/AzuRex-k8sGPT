k8sGPT Grafana dashboard

Fichiers:
- k8sgpt-dashboard.json : dashboard Grafana (tableau des analyses + graphiques)

But
-----
Ce dashboard suppose que k8sGPT expose les métriques Prometheus suivantes (à adapter si nécessaire) :

- k8sgpt_analysis_result_total{namespace,analysis_name,result,severity}
- k8sgpt_analysis_duration_seconds_sum / _count (histogram/summary)
- k8sgpt_analysis_issues_total{namespace,severity}
- k8sgpt_analysis_info{namespace,analysis_name,result_summary,recommended_steps,first_seen}

Import
------
1. Copier `k8sgpt-dashboard.json` sur votre poste.
2. Dans Grafana : + > Import > Upload JSON file.
3. Choisir la datasource Prometheus et la variable `namespace`.

Alternatives
------------
- Si k8sGPT stocke les résultats dans un CRD uniquement (pas de métriques), vous pouvez exporter un exporter (Script/Sidecar) pour exposer ces CRs en métriques Prometheus ou utiliser un datasource Loki/Elasticsearch pour afficher les textes détaillés.

Notes
-----
- Les champs de la table utilisent la métrique `k8sgpt_analysis_info` qui doit exposer labels avec le texte des étapes de résolution (recommended_steps). Si les textes sont longs, préférez un datasource Loki (logs) et un panneau table lié.
- Variable `namespace` utilise una requête Prometheus générique; adaptez la selon vos métriques.
