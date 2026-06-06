# Конвертирует docs/TZ.md в docs/TZ.docx через pandoc.
# Запуск: PowerShell  docs\build-docx.ps1
$ErrorActionPreference = "Stop"

$pandoc = "C:\Users\Aki\AppData\Local\Pandoc\pandoc-3.9.0.2\pandoc.exe"
if (-not (Test-Path $pandoc)) {
    $cmd = Get-Command pandoc -ErrorAction SilentlyContinue
    if ($cmd) { $pandoc = $cmd.Source } else {
        throw "pandoc не найден. Установи через winget install JohnMacFarlane.Pandoc"
    }
}

$root = Split-Path -Parent $PSCommandPath

$docs = @("TZ", "ARCHITECTURE", "DEPLOY", "STITCH_PROMPTS", "THEMING_GUIDE", "I18N_GUIDE", "ROUTING_GUIDE", "API_AND_REALTIME_GUIDE", "WIDGETS_GUIDE", "WAITER_GUIDE")
foreach ($name in $docs) {
    $inPath = Join-Path $root "$name.md"
    $outPath = Join-Path $root "$name.docx"
    if (-not (Test-Path $inPath)) { continue }
    & $pandoc $inPath -o $outPath `
        --from=markdown+pipe_tables+raw_html `
        --toc --toc-depth=2 `
        --top-level-division=section
    Write-Host "$name → $outPath ($([math]::Round((Get-Item $outPath).Length/1KB, 1)) KB)"
}
