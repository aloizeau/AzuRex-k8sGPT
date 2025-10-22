kubectl create namespace k8sgpt
kubectl create secret generic k8sgpt-secret -n k8sgpt --from-literal=azureopenai_secret="< YOUR_AZURE_OPENAI_KEY />"
kubectl apply -f yaml\k8sgpt-analyzer.yaml