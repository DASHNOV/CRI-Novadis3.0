<#
.SYNOPSIS
Script de nettoyage des caches, logs et fichiers temporaires du projet.
#>

$ProjectRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ProjectRoot = Split-Path -Path $ProjectRoot -Parent

Write-Host "Démarrage du grand nettoyage..." -ForegroundColor Cyan

# 1. Vider les dossiers de cache locaux et de build
$dirsToRemove = @(
    "$ProjectRoot\frontend\build",
    "$ProjectRoot\frontend\.dart_tool",
    "$ProjectRoot\backend\src\NovadisApi\bin",
    "$ProjectRoot\backend\src\NovadisApi\obj",
    "$ProjectRoot\backend\src\NovadisApi\publish",
    "$ProjectRoot\backend\src\NovadisApi.Tests\bin",
    "$ProjectRoot\backend\src\NovadisApi.Tests\obj"
)

foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        Write-Host "Suppression du dossier : $_" -ForegroundColor Yellow
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 2. Supprimer les fichiers de logs récurrents, caches OS et backups
$filesPatternToRemove = @(
    "*.log",
    "*.bak",
    "*.tmp",
    ".DS_Store",
    "Thumbs.db",
    "build_logs.txt",
    "flutter_analyze.txt"
)

foreach ($pattern in $filesPatternToRemove) {
    $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter $pattern -File -Force -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        # Eviter de toucher à d'éventuels .log pertinents protégés dans .git ou autres
        if (-not ($file.FullName -match "\\\.git\\")) {
            Write-Host "Suppression du fichier : $($file.FullName)" -ForegroundColor Yellow
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Nettoyage terminé ! Espace et contexte optimisés." -ForegroundColor Green
