# Build signed AAB (Windows)
# Requires: android/key.properties + android/upload-keystore.jks (not in git)

Set-Location $PSScriptRoot
flutter pub get
Set-Location android
./gradlew.bat bundleRelease
Write-Host ""
Write-Host "AAB ready:" -ForegroundColor Green
Write-Host (Resolve-Path "..\build\app\outputs\bundle\release\app-release.aab")
