#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_IMAGE_NAME="k8sgpt-exporter:latest"

echo "🔨 Buid local du Docker image (sans registry)..."

# Build avec Docker local (pas besoin de registry)
docker build -t "$DOCKER_IMAGE_NAME" "$SCRIPT_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Image built: $DOCKER_IMAGE_NAME"
else
    echo "❌ Erreur lors du build"
    exit 1
fi

# Si vous utilisez minikube ou kind, charger l'image localement
if command -v minikube &> /dev/null; then
    echo "📦 Charger l'image dans minikube..."
    minikube image load "$DOCKER_IMAGE_NAME"
    echo "✅ Image loaded in minikube"
elif command -v kind &> /dev/null; then
    echo "📦 Charger l'image dans kind..."
    kind load docker-image "$DOCKER_IMAGE_NAME"
    echo "✅ Image loaded in kind"
else
    echo "⚠️  minikube/kind non détecté - utilisant Docker daemon par défaut"
fi

echo ""
echo "📋 Prochaines étapes:"
echo "1. Mettre à jour l'imagePullPolicy dans le deployment: imagePullPolicy: Never"
echo "2. Déployer: kubectl apply -f k8sgpt-exporter-deployment.yaml"
