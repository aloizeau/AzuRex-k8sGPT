# =============================================================================
# Script pour télécharger, installer et configurer la dernière version de k8sGPT
# =============================================================================

# --- Paramètres ---
$downloadUrl = "https://github.com/k8sgpt-ai/k8sgpt/releases/latest/download/k8sgpt_Windows_x86_64.zip"
$installDir = "C:\tools\k8sgpt"
$zipFileName = "k8sgpt.zip"
$tempZipPath = Join-Path $env:TEMP $zipFileName

# --- Début du Script ---

Write-Host "Début de l'installation de k8sGPT..."

# Étape 1: Télécharger la dernière version
try {
    Write-Host "Téléchargement de k8sGPT depuis $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZipPath -UseBasicParsing
    Write-Host "Téléchargement terminé avec succès."
}
catch {
    Write-Error "Échec du téléchargement. Erreur: $($_.Exception.Message)"
    # Arrête le script en cas d'échec du téléchargement
    exit 1
}

# Étape 2: Créer le répertoire d'installation s'il n'existe pas
if (-not (Test-Path -Path $installDir)) {
    Write-Host "Création du répertoire d'installation : $installDir"
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

# Étape 3: Extraire le contenu du ZIP en écrasant les fichiers existants
try {
    Write-Host "Extraction de $tempZipPath vers $installDir..."
    # L'option -Force permet d'écraser les fichiers existants
    Expand-Archive -Path $tempZipPath -DestinationPath $installDir -Force
    Write-Host "Extraction terminée."
}
catch {
    Write-Error "Échec de l'extraction. Erreur: $($_.Exception.Message)"
    exit 1
}
finally {
    # Nettoyer le fichier ZIP téléchargé
    Write-Host "Nettoyage du fichier ZIP temporaire..."
    Remove-Item -Path $tempZipPath -Force
}

# Étape 4: Ajouter le répertoire au PATH de l'utilisateur s'il n'y est pas déjà
Write-Host "Vérification de la variable d'environnement PATH..."

# Récupère le PATH pour l'utilisateur courant
$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = $userPath -split ';'

# Vérifie si le chemin est déjà dans le PATH (insensible à la casse)
if ($pathEntries -notcontains $installDir) {
    Write-Host "Ajout de '$installDir' à la variable PATH de l'utilisateur."
    
    # Construit le nouveau PATH
    $newPath = ($userPath, $installDir) -join ';'
    
    # Met à jour la variable d'environnement de manière persistante
    [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    
    Write-Host "Le PATH a été mis à jour. Vous devrez redémarrer votre console pour que les changements prennent effet."
}
else {
    Write-Host "'$installDir' est déjà présent dans le PATH. Aucune modification n'est nécessaire."
}

Write-Host "Installation de k8sGPT terminée avec succès !"
Write-Host "Veuillez ouvrir une nouvelle console PowerShell pour utiliser la commande 'k8sgpt'."