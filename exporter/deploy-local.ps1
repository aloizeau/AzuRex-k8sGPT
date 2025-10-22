# Deploy K8sGPT Exporter - PowerShell Script (Windows)
# Usage: .\deploy-local.ps1

param(
    [string]$ClusterType = "docker-desktop"  # docker-desktop, minikube, or kind
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

# ==================== MAIN ====================

Write-Section "🚀 K8sGPT Exporter Local Deployment"

# Check Prerequisites
Write-Host "Vérification des prérequis..."

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker n'est pas installé"
    exit 1
}
Write-Success "Docker détecté"

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl n'est pas installé"
    exit 1
}
Write-Success "kubectl détecté"

try {
    kubectl cluster-info > $null 2>&1
}
catch {
    Write-Error "Impossible de se connecter au cluster Kubernetes"
    exit 1
}
Write-Success "Connexion au cluster OK"
Write-Success "Tous les prérequis sont présents"

# ==================== STEP 1: Build Docker Image ====================

Write-Section "📦 Étape 1: Build de l'image Docker"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ImageName = "k8sgpt-exporter:latest"

Write-Host "Build de $ImageName..."
Push-Location $ScriptPath

try {
    docker build -t $ImageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors du build Docker"
        exit 1
    }
    Write-Success "Image Docker buildée: $ImageName"
}
finally {
    Pop-Location
}

# ==================== STEP 2: Load Image to Cluster ====================

Write-Section "📦 Étape 2: Chargement de l'image dans le cluster"

switch ($ClusterType.ToLower()) {
    "minikube" {
        Write-Host "Chargement dans minikube..."
        if (Get-Command minikube -ErrorAction SilentlyContinue) {
            minikube image load $ImageName
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Image chargée dans minikube"
            }
            else {
                Write-Error "Erreur lors du chargement dans minikube"
                exit 1
            }
        }
        else {
            Write-Error "minikube n'est pas installé"
            exit 1
        }
    }
    "kind" {
        Write-Host "Chargement dans kind..."
        if (Get-Command kind -ErrorAction SilentlyContinue) {
            kind load docker-image $ImageName
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Image chargée dans kind"
            }
            else {
                Write-Error "Erreur lors du chargement dans kind"
                exit 1
            }
        }
        else {
            Write-Error "kind n'est pas installé"
            exit 1
        }
    }
    "docker-desktop" {
        Write-Info "Docker Desktop Kubernetes - l'image sera automatiquement disponible"
    }
    default {
        Write-Warning "Type de cluster inconnu: $ClusterType"
        Write-Info "L'image sera chargée à partir du Docker daemon"
    }
}

# ==================== STEP 3: Create Namespace ====================

Write-Section "📝 Étape 3: Vérification du namespace"

$Namespace = "k8sgpt"

$nsExists = kubectl get namespace $Namespace -ErrorAction SilentlyContinue
if ($nsExists) {
    Write-Success "Namespace $Namespace existe déjà"
}
else {
    Write-Host "Création du namespace $Namespace..."
    kubectl create namespace $Namespace
    Write-Success "Namespace $Namespace créé"
}

# ==================== STEP 4: Deploy Resources ====================

Write-Section "🚀 Étape 4: Déploiement des ressources"

$DeploymentFile = Join-Path $ScriptPath "k8sgpt-exporter-deployment.yaml"

if (-not (Test-Path $DeploymentFile)) {
    Write-Error "Fichier de déploiement non trouvé: $DeploymentFile"
    exit 1
}

Write-Host "Déploiement de $DeploymentFile..."
kubectl apply -f $DeploymentFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors du déploiement"
    exit 1
}

Write-Success "Ressources déployées"

# ==================== STEP 5: Check Prometheus Operator ====================

Write-Section "📊 Étape 5: Vérification de Prometheus Operator"

$crdExists = kubectl get crd servicemonitors.monitoring.coreos.com -ErrorAction SilentlyContinue

if ($crdExists) {
    Write-Info "Prometheus Operator détecté"
    $ServiceMonitorFile = Join-Path $ScriptPath "k8sgpt-servicemonitor.yaml"
    
    if (Test-Path $ServiceMonitorFile) {
        Write-Host "Déploiement du ServiceMonitor..."
        kubectl apply -f $ServiceMonitorFile
        Write-Success "ServiceMonitor déployé"
    }
}
else {
    Write-Warning "Prometheus Operator non détecté"
    Write-Info "Vous devrez configurer Prometheus manuellement"
}

# ==================== STEP 6: Wait for Deployment ====================

Write-Section "⏳ Étape 6: Attente du déploiement"

Write-Host "Attente du rollout..."
$maxAttempts = 60
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ready = kubectl get deployment k8sgpt-exporter -n $Namespace -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' -ErrorAction SilentlyContinue
    
    if ($ready -eq "True") {
        Write-Success "Déploiement réussi!"
        break
    }
    
    $attempt++
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 1
}

if ($attempt -eq $maxAttempts) {
    Write-Error "Timeout lors du déploiement"
    Write-Info "Vérification des logs:"
    kubectl logs -n $Namespace -l app=k8sgpt-exporter --tail=50
    exit 1
}

# ==================== STEP 7: Verify Service ====================

Write-Section "🔍 Étape 7: Vérification du service"

Write-Host "Services déployés:"
kubectl get svc -n $Namespace

# ==================== STEP 8: Display Connection Info ====================

Write-Section "✅ DÉPLOIEMENT RÉUSSI!"

Write-Host "📊 Pour accéder aux métriques:" -ForegroundColor Green
Write-Host ""
Write-Host "Option 1 - Port forward local:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward -n $Namespace svc/k8sgpt-exporter 8080:8080"
Write-Host "  Puis accédez à: http://localhost:8080/metrics"
Write-Host ""

Write-Host "Option 2 - DNS Kubernetes (depuis le cluster):" -ForegroundColor Yellow
Write-Host "  http://k8sgpt-exporter.$Namespace.svc.cluster.local:8080/metrics"
Write-Host ""

Write-Host "🔧 Pour vérifier les logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -n $Namespace -l app=k8sgpt-exporter -f"
Write-Host ""

Write-Host "📝 Prochaines étapes:" -ForegroundColor Magenta
Write-Host "  1. Configurer Prometheus pour scraper: http://k8sgpt-exporter.$Namespace.svc.cluster.local:8080/metrics"
Write-Host "  2. Importer le dashboard Grafana fourni"
Write-Host "  3. Configurer les alertes dans Prometheus"
Write-Host ""

Write-Host "✨ Configuration complète!" -ForegroundColor Green
