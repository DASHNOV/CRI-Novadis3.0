# Script de test pour l'authentification en développement

$baseUrl = "http://localhost:5245"

Write-Host "Test de l'authentification Novadis API" -ForegroundColor Cyan
Write-Host ""

# 1. Demander un code de connexion
Write-Host "1. Demande d'un code de connexion..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@novadis.local"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody
    Write-Host "Code envoye avec succes" -ForegroundColor Green
    Write-Host "Message: $($loginResponse.message)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Erreur lors de la demande de code: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Récupérer le code (endpoint de développement)
Write-Host "2. Recuperation du code (DEV ONLY)..." -ForegroundColor Yellow
try {
    $codeResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/dev/get-code/admin@novadis.local" -Method GET
    Write-Host "Code recupere avec succes" -ForegroundColor Green
    Write-Host "Email: $($codeResponse.data.email)" -ForegroundColor Gray
    Write-Host "Code: $($codeResponse.data.code)" -ForegroundColor Green -BackgroundColor Black
    Write-Host "Expire dans: $($codeResponse.data.expiresIn) minutes" -ForegroundColor Gray
    Write-Host ""
    
    $code = $codeResponse.data.code
} catch {
    Write-Host "Erreur lors de la recuperation du code: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Vérifier le code et obtenir un token
Write-Host "3. Verification du code..." -ForegroundColor Yellow
$verifyBody = @{
    email = "admin@novadis.local"
    code = $code
} | ConvertTo-Json

try {
    $verifyResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/verify" -Method POST -ContentType "application/json" -Body $verifyBody
    Write-Host "Authentification reussie" -ForegroundColor Green
    Write-Host "Utilisateur: $($verifyResponse.data.user.firstName) $($verifyResponse.data.user.lastName)" -ForegroundColor Gray
    Write-Host "Role: $($verifyResponse.data.user.role)" -ForegroundColor Gray
    Write-Host "Access Token: $($verifyResponse.data.accessToken.Substring(0, 50))..." -ForegroundColor Gray
    Write-Host ""
    
    $accessToken = $verifyResponse.data.accessToken
} catch {
    Write-Host "Erreur lors de la verification du code: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Tester l'accès à une ressource protégée
Write-Host "4. Test d'acces a /api/auth/me..." -ForegroundColor Yellow
try {
    $headers = @{
        Authorization = "Bearer $accessToken"
    }
    $meResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/me" -Method GET -Headers $headers
    Write-Host "Acces autorise" -ForegroundColor Green
    Write-Host "Email: $($meResponse.data.email)" -ForegroundColor Gray
    Write-Host "Nom complet: $($meResponse.data.firstName) $($meResponse.data.lastName)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "Erreur lors de l'acces a la ressource protegee: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Tous les tests sont passes avec succes!" -ForegroundColor Green
