#!/bin/bash

echo "Déploiement du monitoring K8sGPT..."

# Build de l'image Docker
echo "Building Docker image..."
docker build -t k8sgpt-exporter:latest ./

# Si vous avez un registry privé
# docker tag k8sgpt-exporter:latest your-registry/k8sgpt-exporter:latest
# docker push your-registry/k8sgpt-exporter:latest

# Déploiement dans Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f k8sgpt-exporter-deployment.yaml
kubectl apply -f k8sgpt-servicemonitor.yaml
kubectl apply -f prometheus-rules.yaml

# Vérification du déploiement
echo "Checking deployment status..."
kubectl rollout status deployment/k8sgpt-exporter -n k8sgpt

# Afficher l'URL des métriques
echo "Metrics available at:"
kubectl get svc k8sgpt-exporter -n k8sgpt

echo "Deployment complete!"