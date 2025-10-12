helm repo add k8sgpt https://charts.k8sgpt.ai
helm repo update
helm upgrade --install k8sgpt-operator k8sgpt/k8sgpt-operator -n k8sgpt-operator --create-namespace -f operateur-values.yaml
kubectl create namespace k8sgpt
kubectl create secret generic k8sgpt-secret -n k8sgpt --from-literal=azureopenai_secret=<your_secret_value>
kubectl apply -f operator-config.yaml
