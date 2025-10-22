helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --version 78.2.0  -f ./yaml/prometheus-values.yaml -n observability --create-namespace
kubectl --namespace observability get pods -l "release=prometheus"
kubectl port-forward -n observability svc/prometheus-grafana 3000:80&