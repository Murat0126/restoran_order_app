<#
.SYNOPSIS
  Открывает входящий TCP-порт в Windows Firewall, чтобы планшеты и
  телефоны в той же Wi-Fi-сети могли достучаться до сервера.

.PARAMETER Port
  Порт сервера. По умолчанию 8765.

.NOTES
  Скрипт нужно запускать от имени Администратора.
  Удалить правило обратно:  Remove-NetFirewallRule -DisplayName "Dart Frog (POS) <port>"
#>

[CmdletBinding()]
param(
    [int]$Port = 8765
)

$ErrorActionPreference = "Stop"

# Проверка прав администратора.
$isAdmin = ([Security.Principal.WindowsPrincipal]`
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Запустите PowerShell как Администратор."
    exit 1
}

$ruleName = "Dart Frog (POS) $Port"
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule

New-NetFirewallRule `
    -DisplayName $ruleName `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort $Port `
    -Action Allow `
    -Profile Private,Domain | Out-Null

Write-Host "Открыт TCP $Port (Private + Domain профили)." -ForegroundColor Green
Write-Host "Для удаления:  Remove-NetFirewallRule -DisplayName `"$ruleName`"" -ForegroundColor DarkGray
