# git-push-and-merge-dev.ps1
# Flow: commit + push sur la branche courante, puis merge dans dev

function Stop-WithError {
    param([string]$Message)
    Write-Host ""
    Write-Host "ERREUR : $Message" -ForegroundColor Red
    exit 1
}

function Invoke-Git {
    param([string[]]$GitArgs, [string]$ErrorMessage)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        Stop-WithError $ErrorMessage
    }
}

# -- Récupération de la branche courante --
$sourceBranch = git rev-parse --abbrev-ref HEAD 2>&1
if ($LASTEXITCODE -ne 0) {
    Stop-WithError "Impossible de déterminer la branche courante. Êtes-vous dans un dépôt Git ?"
}

$sourceBranch = $sourceBranch.Trim()

if ($sourceBranch -eq "dev") {
    Stop-WithError "Vous êtes déjà sur la branche 'dev'. Placez-vous sur une autre branche avant de lancer ce script."
}

Write-Host ""
Write-Host "Branche source : $sourceBranch" -ForegroundColor Yellow

# -- Message de commit --
Write-Host ""
$commitMessage = Read-Host "Message du commit"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    Stop-WithError "Le message de commit ne peut pas être vide."
}

# -- git add . --
Write-Host ""
Write-Host "[1/6] git add ." -ForegroundColor Cyan
Invoke-Git -GitArgs @("add", ".") -ErrorMessage "Échec de 'git add .'."

# -- git commit --
Write-Host "[2/6] git commit -m `"$commitMessage`"" -ForegroundColor Cyan
& git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Stop-WithError "Échec de 'git commit'. Il n'y a peut-être rien à committer."
}

# -- git push origin <sourceBranch> --
Write-Host "[3/6] git push origin $sourceBranch" -ForegroundColor Cyan
Invoke-Git -GitArgs @("push", "origin", $sourceBranch) -ErrorMessage "Échec de 'git push origin $sourceBranch'. Vérifiez votre connexion ou les droits sur le dépôt distant."

# -- git checkout dev --
Write-Host "[4/6] git checkout dev" -ForegroundColor Cyan
Invoke-Git -GitArgs @("checkout", "dev") -ErrorMessage "Échec de 'git checkout dev'. Vérifiez que la branche 'dev' existe."

# -- git merge --no-ff <sourceBranch> --
Write-Host "[5/6] git merge --no-ff $sourceBranch" -ForegroundColor Cyan
& git merge --no-ff $sourceBranch -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    $conflictedFiles = git diff --name-only --diff-filter=U
    if ($conflictedFiles) {
        $fileList = ($conflictedFiles -join "`n  - ")
        Stop-WithError "Conflit(s) de merge détecté(s). Résolvez les conflits manuellement dans les fichiers suivants, puis commitez et pushez manuellement :`n  - $fileList"
    }
    Stop-WithError "Échec du merge de '$sourceBranch' dans 'dev'."
}

# -- git push origin dev --
Write-Host "[6/6] git push origin dev" -ForegroundColor Cyan
Invoke-Git -GitArgs @("push", "origin", "dev") -ErrorMessage "Échec de 'git push origin dev'. Vérifiez votre connexion ou les droits sur le dépôt distant."

Write-Host ""
Write-Host "Terminé avec succès !" -ForegroundColor Green
Write-Host "  '$sourceBranch' -> commit '$commitMessage' -> push -> merge dans 'dev' -> push" -ForegroundColor Green
Write-Host ""
