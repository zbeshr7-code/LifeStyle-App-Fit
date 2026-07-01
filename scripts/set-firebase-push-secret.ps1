# Upload Firebase service account JSON to Supabase Edge Function secrets.
# Usage:
#   .\scripts\set-firebase-push-secret.ps1 "C:\path\to\lifestyle-fit-firebase-adminsdk-....json"

param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceAccountPath,

    [string]$ProjectRef = "legcosmcypmrkyzhvbwo"
)

if (-not (Test-Path $ServiceAccountPath)) {
    Write-Error "File not found: $ServiceAccountPath"
    exit 1
}

$minified = Get-Content -Raw $ServiceAccountPath | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 10
$parsed = $minified | ConvertFrom-Json
Write-Host "Firebase project_id: $($parsed.project_id)"
if ($parsed.project_id -ne "lifestyle-fit") {
    Write-Warning "Expected project_id 'lifestyle-fit' (must match firebase_options.dart)."
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $repoRoot ".firebase-secret.env"
$line = 'FIREBASE_SERVICE_ACCOUNT_JSON=' + [char]39 + $minified + [char]39
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($envFile, $line, $utf8)

Push-Location $repoRoot
try {
    supabase secrets set --env-file .firebase-secret.env --project-ref $ProjectRef
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Secret FIREBASE_SERVICE_ACCOUNT_JSON set successfully."
    }
}
finally {
    Pop-Location
    Remove-Item $envFile -Force -ErrorAction SilentlyContinue
}
