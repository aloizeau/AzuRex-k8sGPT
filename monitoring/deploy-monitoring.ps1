helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --version 78.2.0  -f prometheus-values.yml -n observability --create-namespace
kubectl --namespace observability get pods -l "release=prometheus"