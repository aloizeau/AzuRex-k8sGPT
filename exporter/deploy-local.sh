#!/bin/bash
set -e

echo "======================================"
echo "🚀 Déploiement K8sGPT Monitoring"
echo "======================================"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NAMESPACE="k8sgpt"
DOCKER_IMAGE_NAME="k8sgpt-exporter:latest"

# Vérifications préalables
echo "✓ Vérification des prérequis..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé"
    exit 1
fi

# Vérifier la connexion à Kubernetes
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Impossible de se connecter au cluster Kubernetes"
    exit 1
fi

echo "✅ Tous les prérequis sont présents"
echo ""

# Step 1: Build l'image Docker locale
echo "📦 Étape 1: Build l'image Docker localement..."
cd "$SCRIPT_DIR"
docker build -t "$DOCKER_IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du build Docker"
    exit 1
fi
echo "✅ Image Docker buildée: $DOCKER_IMAGE_NAME"
echo ""

# Step 2: Charger l'image dans le cluster local (si minikube ou kind)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "📦 Étape 2: Charger l'image dans minikube..."
    minikube image load "$DOCKER_IMAGE_NAME"
    echo "✅ Image chargée dans minikube"
    echo ""
elif command -v kind &> /dev/null; then
    echo "📦 Étape 2: Charger l'image dans kind..."
    kind load docker-image "$DOCKER_IMAGE_NAME"
    echo "✅ Image chargée dans kind"
    echo ""
else
    echo "⚠️  Cluster local non détecté (minikube/kind)"
    echo "   Si vous utilisez Docker Desktop Kubernetes, l'image sera automatiquement disponible"
    echo ""
fi

# Step 3: Créer le namespace si nécessaire
echo "📝 Étape 3: Vérifier/créer le namespace..."
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "✅ Namespace $NAMESPACE existe déjà"
else
    echo "   Création du namespace $NAMESPACE..."
    kubectl create namespace "$NAMESPACE"
    echo "✅ Namespace $NAMESPACE créé"
fi
echo ""

# Step 4: Déployer les ressources
echo "🚀 Étape 4: Déploiement des ressources Kubernetes..."
kubectl apply -f k8sgpt-exporter-deployment.yaml

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors du déploiement"
    exit 1
fi
echo "✅ Ressources déployées"
echo ""

# Step 5: Déployer le ServiceMonitor (si Prometheus Operator est disponible)
echo "📊 Étape 5: Vérification de Prometheus Operator..."
if kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
    echo "   Prometheus Operator détecté - Déploiement du ServiceMonitor..."
    kubectl apply -f k8sgpt-servicemonitor.yaml
    echo "✅ ServiceMonitor déployé"
else
    echo "⚠️  Prometheus Operator non détecté"
    echo "   Vous pouvez configurer Prometheus manuellement avec le scrape config ci-dessous:"
    echo ""
    echo "   scrape_configs:"
    echo "   - job_name: 'k8sgpt-exporter'"
    echo "     kubernetes_sd_configs:"
    echo "     - role: pod"
    echo "     relabel_configs:"
    echo "     - source_labels: [__meta_kubernetes_namespace]"
    echo "       action: keep"
    echo "       regex: k8sgpt"
    echo ""
fi
echo ""

# Step 6: Attendre le déploiement
echo "⏳ Attente du déploiement..."
kubectl rollout status deployment/k8sgpt-exporter -n "$NAMESPACE" --timeout=5m

if [ $? -ne 0 ]; then
    echo "❌ Le déploiement n'a pas abouti dans le délai imparti"
    echo "Vérification des logs:"
    kubectl logs -n "$NAMESPACE" -l app=k8sgpt-exporter --tail=50
    exit 1
fi
echo "✅ Déploiement réussi"
echo ""

# Step 7: Vérifier le service
echo "🔍 Étape 6: Vérification du service..."
kubectl get svc -n "$NAMESPACE"
echo ""

# Step 8: Afficher les informations de connexion
echo "======================================"
echo "✅ DÉPLOIEMENT RÉUSSI!"
echo "======================================"
echo ""
echo "📊 Pour accéder aux métriques:"
echo ""

# Port forward
echo "Option 1 - Port forward local:"
echo "  kubectl port-forward -n $NAMESPACE svc/k8sgpt-exporter 8080:8080"
echo "  Puis accédez à: http://localhost:8080/metrics"
echo ""

# Service DNS
echo "Option 2 - DNS Kubernetes (depuis le cluster):"
echo "  http://k8sgpt-exporter.$NAMESPACE.svc.cluster.local:8080/metrics"
echo ""

# Troubleshooting
echo "🔧 Pour vérifier les logs:"
echo "  kubectl logs -n $NAMESPACE -l app=k8sgpt-exporter -f"
echo ""

echo "📝 Prochaines étapes:"
echo "1. Configurer Prometheus pour scraper: http://k8sgpt-exporter.$NAMESPACE.svc.cluster.local:8080/metrics"
echo "2. Importer le dashboard Grafana fourni"
echo "3. Configurer les alertes dans Prometheus"
echo ""
