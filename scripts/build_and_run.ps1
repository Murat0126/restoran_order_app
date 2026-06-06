<#
.SYNOPSIS
  Один скрипт: собирает client_menu (Flutter Web) → копирует в server/public/
  → запускает dart_frog dev. После этого ВСЯ система (API, WebSocket, QR-меню)
  доступна по одному адресу `http://<ip>:<port>/`.

.PARAMETER Port
  Порт, на котором поднимаем сервер. По умолчанию 8765.

.PARAMETER NoBuild
  Пропустить пересборку Flutter Web. Полезно, если правил только сервер.

.PARAMETER NoRun
  Только собрать, не запускать. Полезно для CI/деплоя.

.EXAMPLE
  ./scripts/build_and_run.ps1
  ./scripts/build_and_run.ps1 -Port 8080
  ./scripts/build_and_run.ps1 -NoBuild
#>

[CmdletBinding()]
param(
    [int]$Port = 8765,
    [switch]$NoBuild,
    [switch]$NoRun
)

$ErrorActionPreference = "Stop"

# Корень репозитория = на уровень выше папки scripts.
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot
Write-Host "Repo root: $repoRoot" -ForegroundColor DarkGray

# --- 1. Билд Flutter Web ---
if (-not $NoBuild) {
    Write-Host "`n[1/3] Сборка client_menu (Flutter Web release)..." -ForegroundColor Cyan
    Push-Location "client_menu"
    try {
        # `--base-href /` — чтобы пути от корня работали при выкладывании
        # на любой хост (включая HTTPS-туннели).
        flutter build web --release --base-href "/"
        if ($LASTEXITCODE -ne 0) { throw "flutter build web завершился с ошибкой" }
    } finally {
        Pop-Location
    }

    Write-Host "`n[2/3] Копирование сборки в server/public/..." -ForegroundColor Cyan
    $publicDir = Join-Path $repoRoot "server\public"
    # Чистим старое содержимое, но оставляем .gitkeep.
    Get-ChildItem $publicDir -Force -Exclude ".gitkeep" |
        ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
    Copy-Item -Recurse -Force "client_menu\build\web\*" $publicDir
    Write-Host "  готово: $((Get-ChildItem $publicDir -Recurse -File).Count) файлов" -ForegroundColor DarkGray
} else {
    Write-Host "[1-2/3] Пропуск билда (--NoBuild)." -ForegroundColor Yellow
}

# --- 2. Запуск сервера ---
if ($NoRun) {
    Write-Host "`n[3/3] Готово. Сервер не запускаем (--NoRun)." -ForegroundColor Green
    return
}

# Печатаем подсказку с локальным IP, чтобы можно было сразу зайти с телефона.
$localIps = Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp,Manual `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' } |
    Select-Object -ExpandProperty IPAddress

Write-Host "`n[3/3] Запуск dart_frog dev на порту $Port..." -ForegroundColor Cyan
Write-Host "  Меню гостя       :  http://localhost:$Port/?t=<qr_token>"  -ForegroundColor White
foreach ($ip in $localIps) {
    Write-Host "  Из Wi-Fi заведения:  http://${ip}:${Port}/?t=<qr_token>" -ForegroundColor White
}
Write-Host "  Печать QR-стикеров:  http://localhost:$Port/api/admin/qr-poster" -ForegroundColor White
Write-Host "  Не забудьте: Windows Firewall может блокировать порт $Port извне." -ForegroundColor DarkYellow
Write-Host ""

Set-Location "server"
dart_frog dev --port $Port
