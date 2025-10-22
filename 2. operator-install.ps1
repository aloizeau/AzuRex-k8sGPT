helm repo add k8sgpt https://charts.k8sgpt.ai
helm repo update
helm install release k8sgpt/k8sgpt-operator -n k8sgpt-operator --create-namespace --set interplex.enabled=true --set grafanaDashboard.enabled=true --set serviceMonitor.enabled=true

