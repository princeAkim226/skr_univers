# Construit les deux sites web séparément :
#   build/web_app   = copie web de l'application mobile
#   build/web_admin = plateforme d'administration
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "1/2 Build app web (copie mobile)..."
flutter build web -t lib/main.dart --output build/web_app

Write-Host "2/2 Build plateforme admin..."
Copy-Item web\index.html web\index.html.bak -Force
Copy-Item web\manifest.json web\manifest.json.bak -Force
Copy-Item web_admin\index.html web\index.html -Force
Copy-Item web_admin\manifest.json web\manifest.json -Force
try {
  flutter build web -t lib/admin_main.dart --output build/web_admin
} finally {
  Copy-Item web\index.html.bak web\index.html -Force
  Copy-Item web\manifest.json.bak web\manifest.json -Force
  Remove-Item web\index.html.bak, web\manifest.json.bak -ErrorAction SilentlyContinue
}

Write-Host "OK"
Write-Host "App web  : build/web_app"
Write-Host "Admin    : build/web_admin"
