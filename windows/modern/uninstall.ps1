#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PkgName    = 'ClaudeCode.ContextMenu'
$InstallDir = Join-Path $env:LOCALAPPDATA 'ClaudeCode\ShellExtension'

Write-Host ''
Write-Host '  Claude Code - Context Menu Uninstaller' -ForegroundColor Cyan
Write-Host '  =======================================' -ForegroundColor Cyan
Write-Host ''

# ── Remove sparse package ────────────────────────────────────────────────────

$pkg = Get-AppxPackage -Name $PkgName -ErrorAction SilentlyContinue
if ($pkg) {
    Write-Host '  Removing modern context menu...' -NoNewline
    Remove-AppxPackage $pkg.PackageFullName
    Write-Host ' OK' -ForegroundColor Green
}

# ── Remove installed files ───────────────────────────────────────────────────

if (Test-Path $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
    $parent = Split-Path $InstallDir -Parent
    if ((Test-Path $parent) -and @(Get-ChildItem $parent).Count -eq 0) {
        Remove-Item $parent -Force
    }
}

# ── Remove classic menu entries ──────────────────────────────────────────────

Write-Host '  Removing classic context menu entries...' -NoNewline

$regPaths = @(
    'HKCU:\Software\Classes\Directory\shell\ClaudeCode',
    'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCode',
    'HKCU:\Software\Classes\Directory\shell\ClaudeCodeResume',
    'HKCU:\Software\Classes\Directory\Background\shell\ClaudeCodeResume'
)
foreach ($path in $regPaths) {
    if (Test-Path $path) { Remove-Item $path -Recurse -Force }
}
Write-Host ' OK' -ForegroundColor Green

# ── Restart Explorer ─────────────────────────────────────────────────────────

if ($pkg) {
    Write-Host '  Restarting Explorer...' -NoNewline
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
    Write-Host ' OK' -ForegroundColor Green
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '  Done! All context menu entries have been removed.' -ForegroundColor Green
Write-Host ''
