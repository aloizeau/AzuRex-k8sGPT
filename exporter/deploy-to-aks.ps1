# Deploy K8sGPT Exporter to Azure AKS with ACR
# Usage: .\deploy-to-aks.ps1 -AcrName myregistry -AksCluster my-aks -ResourceGroup my-rg

param(
    [Parameter(Mandatory = $true)]
    [string]$AcrName,
    
    [Parameter(Mandatory = $true)]
    [string]$AksCluster,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

# ==================== MAIN ====================

Write-Section "🚀 Deploy K8sGPT Exporter to AKS"

$AcrDomain = "$AcrName.azurecr.io"
$ImageName = "$AcrDomain/k8sgpt-exporter:$ImageTag"

Write-Info "Configuration:"
Write-Host "  ACR: $AcrName"
Write-Host "  AKS: $AksCluster"
Write-Host "  RG: $ResourceGroup"
Write-Host "  Image: $ImageName"
Write-Host ""

# Step 1: Verify ACR exists
Write-Section "Step 1: Vérifier ACR"

try {
    $acr = az acr show -n $AcrName -g $ResourceGroup | ConvertFrom-Json
    Write-Success "ACR '$AcrName' existe"
}
catch {
    Write-Error "ACR '$AcrName' not found in RG '$ResourceGroup'"
    exit 1
}

# Step 2: Build Docker image
Write-Section "Step 2: Build l'image Docker"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $ScriptPath

Write-Host "Building $ImageName..."
docker build -t $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors du build Docker"
    Pop-Location
    exit 1
}

Write-Success "Image Docker buildée"

# Step 3: Login to ACR
Write-Section "Step 3: Se connecter à ACR"

Write-Host "Connexion à $AcrDomain..."
az acr login --name $AcrName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de la connexion à ACR"
    Pop-Location
    exit 1
}

Write-Success "Connecté à ACR"

# Step 4: Push image to ACR
Write-Section "Step 4: Pousser l'image vers ACR"

Write-Host "Pushing $ImageName..."
docker push $ImageName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors du push vers ACR"
    Pop-Location
    exit 1
}

Write-Success "Image poussée vers ACR"

# Step 5: Configure AKS to access ACR
Write-Section "Step 5: Configurer AKS pour accéder à ACR"

Write-Host "Attaching ACR to AKS..."
az aks update `
    -n $AksCluster `
    -g $ResourceGroup `
    --attach-acr $AcrName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de l'attachment ACR-AKS"
    Pop-Location
    exit 1
}

Write-Success "ACR attaché à AKS"

# Step 6: Update deployment YAML
Write-Section "Step 6: Mettre à jour le YAML"

$DeploymentFile = "k8sgpt-exporter-deployment.yaml"
$BackupFile = "k8sgpt-exporter-deployment.yaml.bak"

# Backup
Copy-Item $DeploymentFile $BackupFile
Write-Info "Backup créé: $BackupFile"

# Update image in YAML
(Get-Content $DeploymentFile) `
    -replace 'image: k8sgpt-exporter:latest', "image: $ImageName" `
    -replace 'imagePullPolicy: Never', 'imagePullPolicy: IfNotPresent' | `
    Set-Content $DeploymentFile

Write-Success "YAML mis à jour avec l'image ACR"

# Step 7: Get AKS credentials
Write-Section "Step 7: Récupérer les credentials AKS"

Write-Host "Récupération des credentials AKS..."
az aks get-credentials -n $AksCluster -g $ResourceGroup --overwrite-existing

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de la récupération des credentials"
    Pop-Location
    exit 1
}

Write-Success "Credentials AKS configurés"

# Step 8: Deploy to AKS
Write-Section "Step 8: Déployer vers AKS"

Write-Host "Déploiement..."
kubectl apply -f $DeploymentFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors du déploiement"
    Pop-Location
    exit 1
}

Write-Success "Déployé vers AKS"

# Step 9: Wait for deployment
Write-Section "Step 9: Attendre le rollout"

Write-Host "Attente du déploiement..."
$maxAttempts = 120
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $ready = (kubectl get deployment k8sgpt-exporter -n k8sgpt -o jsonpath='{.status.conditions[?(@.type=="Available")].status}') 2>$null
    
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
    kubectl logs -n k8sgpt -l app=k8sgpt-exporter --tail=50
    Pop-Location
    exit 1
}

# Step 10: Verify deployment
Write-Section "Step 10: Vérification"

Write-Host "Pods déployés:"
kubectl get pods -n k8sgpt -l app=k8sgpt-exporter

Write-Host ""
Write-Host "Services:"
kubectl get svc -n k8sgpt

# Cleanup
Pop-Location

# Final message
Write-Section "✅ DÉPLOIEMENT RÉUSSI!"

Write-Host "Configuration:" -ForegroundColor Green
Write-Host "  Image: $ImageName"
Write-Host "  Cluster: $AksCluster"
Write-Host "  Namespace: k8sgpt"
Write-Host ""

Write-Host "Accéder aux métriques:" -ForegroundColor Green
Write-Host "  kubectl port-forward -n k8sgpt svc/k8sgpt-exporter 8080:8080"
Write-Host "  curl http://localhost:8080/metrics"
Write-Host ""

Write-Host "Logs:" -ForegroundColor Green
Write-Host "  kubectl logs -n k8sgpt -l app=k8sgpt-exporter -f"
Write-Host ""

Write-Host "Note: Backup du YAML original: $BackupFile" -ForegroundColor Yellow
Write-Host ""
