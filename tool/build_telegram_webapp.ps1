# Telegram Mini App'ni yig'ib, backend'ning `webapp/` papkasiga ko'chiradi.
# Backend uni https://<host>/app/ manzilida tarqatadi.
#
#   powershell -File tool/build_telegram_webapp.ps1
#   powershell -File tool/build_telegram_webapp.ps1 -BackendDir D:\code\warder_do_back
#
# `canvaskit/` ko'chirilmaydi: Flutter uni baribir gstatic.com CDN'dan
# yuklaydi, lokal nusxa esa ~30 MB joy egallaydi.
param(
    [string]$BackendDir = "C:\dev\projetcs\warder_do_back",
    [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

$buildArgs = @("build", "web", "--release", "--base-href", "/app/")
if ($ApiBaseUrl) { $buildArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl" }
flutter @buildArgs
if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }

$target = Join-Path $BackendDir "webapp"
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
New-Item -ItemType Directory $target | Out-Null

Get-ChildItem "build/web" -Force |
    Where-Object { $_.Name -ne "canvaskit" } |
    Copy-Item -Destination $target -Recurse -Force

# Phosphor'dan faqat "Fill" uslubi ishlatiladi. Flutter qolgan 5 ta uslubni
# ham qo'shadi (~2 MB) va web ularni ishga tushishda yuklaydi — olib tashlaymiz.
$manifestPath = Join-Path $target "assets/FontManifest.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$unused = $manifest | Where-Object {
    $_.family -like "packages/phosphor_flutter/*" -and $_.family -ne "packages/phosphor_flutter/PhosphorFill"
}
foreach ($family in $unused) {
    foreach ($font in $family.fonts) {
        Remove-Item (Join-Path $target "assets/$($font.asset)") -ErrorAction SilentlyContinue
    }
}
$kept = @($manifest | Where-Object { $unused -notcontains $_ })
# BOM'siz UTF-8 — Windows PowerShell 5.1 va PowerShell 7 da bir xil ishlaydi.
$json = ConvertTo-Json -InputObject $kept -Depth 5 -Compress
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding $false))

$size = (Get-ChildItem $target -Recurse | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("Mini App -> {0} ({1:N1} MB)" -f $target, $size)
