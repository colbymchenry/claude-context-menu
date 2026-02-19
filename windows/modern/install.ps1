#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Paths & constants ──────────────────────────────────────────────────────────

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot    = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$IconSrc     = Join-Path $RepoRoot 'icons\claude-icon.png'
$InstallDir  = Join-Path $env:LOCALAPPDATA 'ClaudeCode\ShellExtension'
$BuildOutput = Join-Path $ScriptDir 'bin\Release\net8.0-windows'

$OpenClsid    = 'E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E60'
$ResumeClsid  = 'E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E61'
$PkgName      = 'ClaudeCode.ContextMenu'
$PkgPublisher = 'CN=ClaudeCodeDev'

$DotnetSdkUrls = @{
    'AMD64' = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.418/dotnet-sdk-8.0.418-win-x64.exe'
    'ARM64' = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.418/dotnet-sdk-8.0.418-win-arm64.exe'
    'x86'   = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.418/dotnet-sdk-8.0.418-win-x86.exe'
}

# ── Helpers ────────────────────────────────────────────────────────────────────

function Write-Check($text)  { Write-Host "  [" -NoNewline; Write-Host "+" -ForegroundColor Green -NoNewline; Write-Host "] $text" }
function Write-Cross($text)  { Write-Host "  [" -NoNewline; Write-Host "X" -ForegroundColor Red -NoNewline; Write-Host "] $text" }
function Write-Bullet($text) { Write-Host "  [" -NoNewline; Write-Host "-" -ForegroundColor DarkGray -NoNewline; Write-Host "] $text" }

# ── Header ─────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '  Claude Code - Context Menu Installer' -ForegroundColor Cyan
Write-Host '  =====================================' -ForegroundColor Cyan
Write-Host ''

# ── Detect environment ─────────────────────────────────────────────────────────

$build   = [System.Environment]::OSVersion.Version.Build
$isWin11 = $build -ge 22000
$arch    = $env:PROCESSOR_ARCHITECTURE  # AMD64, ARM64, or x86
$useWT   = $null -ne (Get-Command wt.exe -ErrorAction SilentlyContinue)

# .NET 8 SDK
$hasDotnet8 = $false
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    $sdkList = & dotnet --list-sdks 2>&1 | Out-String
    if ($sdkList -match '(?m)^8\.') { $hasDotnet8 = $true }
}

# Developer Mode
$hasDevMode = $false
try {
    $reg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
    if ($reg -and $reg.AllowDevelopmentWithoutDevLicense -eq 1) { $hasDevMode = $true }
} catch {}

# Display status
$osLabel = if ($isWin11) { "Windows 11 (build $build)" } else { "Windows 10 (build $build)" }
Write-Host "  System:   $osLabel ($arch)"

if ($useWT) { Write-Check 'Windows Terminal detected' }
else        { Write-Bullet 'Windows Terminal not found, using CMD' }

if ($hasDotnet8) { Write-Check '.NET 8 SDK detected' }
else             { Write-Cross '.NET 8 SDK not found' }

if ($isWin11) {
    if ($hasDevMode) { Write-Check 'Developer Mode enabled' }
    else             { Write-Cross 'Developer Mode not enabled' }
}

Write-Host ''

# ── Helper: refresh PATH from registry (picks up changes from installers) ────

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $userPath    = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $env:PATH    = "$machinePath;$userPath"
}

# ── Helper: check for .NET 8 SDK with fresh PATH ────────────────────────────

function Test-Dotnet8 {
    Refresh-Path
    $d = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $d) { return $false }
    $list = & dotnet --list-sdks 2>&1 | Out-String
    return $list -match '(?m)^8\.'
}

# ── Ask about modern menu ────────────────────────────────────────────────────

$installModern = $false

if ($isWin11) {
    if ($hasDotnet8 -and $hasDevMode) {
        $installModern = $true
    } elseif (-not $hasDotnet8) {
        Write-Host '  The Windows 11 top-level context menu requires the .NET 8 SDK.' -ForegroundColor Yellow
        Write-Host '  Without it, entries will only appear under "Show more options".' -ForegroundColor Yellow
        Write-Host ''
        $answer = Read-Host '  Download .NET 8 SDK installer? (Y/n)'
        if ($answer -eq '' -or $answer -match '^[Yy]') {
            $url = $DotnetSdkUrls[$arch]
            if (-not $url) {
                Write-Host "  Unknown architecture: $arch" -ForegroundColor Red
                Write-Host '  Please install .NET 8 SDK manually from https://dotnet.microsoft.com/download/dotnet/8.0'
            } else {
                $fileName = Split-Path $url -Leaf
                $downloadPath = Join-Path $env:TEMP $fileName

                Write-Host ''
                Write-Host "  Downloading .NET 8 SDK ($arch)..." -ForegroundColor Cyan

                try {
                    $ProgressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing
                    $ProgressPreference = 'Continue'

                    Write-Host '  Download complete. Launching installer...' -ForegroundColor Green
                    Write-Host ''
                    Start-Process -FilePath $downloadPath

                    # Wait for the user to finish the .NET installer, then verify
                    while ($true) {
                        Write-Host ''
                        Write-Host '  After the .NET 8 SDK installation completes,' -ForegroundColor Cyan
                        Read-Host '  press Enter to continue'

                        if (Test-Dotnet8) {
                            Write-Host ''
                            Write-Check '.NET 8 SDK detected'
                            $hasDotnet8 = $true
                            if ($hasDevMode) { $installModern = $true }
                            break
                        } else {
                            Write-Host ''
                            Write-Cross '.NET 8 SDK not detected yet. Please complete the installer before continuing.'
                        }
                    }
                } catch {
                    Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host '  Install manually from: https://dotnet.microsoft.com/download/dotnet/8.0'
                    Write-Host ''
                }
            }
        }

        if ($hasDotnet8 -and -not $hasDevMode) {
            Write-Host ''
            Write-Host '  Developer Mode is also needed for the modern menu.' -ForegroundColor Yellow
            Write-Host '  Enable at: Settings > Privacy & Security > For developers' -ForegroundColor Yellow
            Write-Host ''
        }
    } elseif (-not $hasDevMode) {
        Write-Host '  Developer Mode is required for the Windows 11 top-level context menu.' -ForegroundColor Yellow
        Write-Host '  Enable at: Settings > Privacy & Security > For developers' -ForegroundColor Yellow
        Write-Host '  Then re-run this installer.' -ForegroundColor Yellow
        Write-Host ''
    }
}

# ── Remove previous modern installation ───────────────────────────────────────

$existing = Get-AppxPackage -Name $PkgName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host '  Removing previous installation...'
    Remove-AppxPackage $existing.PackageFullName
}

# ── Build registry commands based on terminal ─────────────────────────────────

if ($useWT) {
    $cmdOpen      = 'wt.exe -d "%1" cmd /k claude'
    $cmdOpenBg    = 'wt.exe -d "%V" cmd /k claude'
    $cmdResume    = 'wt.exe -d "%1" cmd /k "claude --resume"'
    $cmdResumeBg  = 'wt.exe -d "%V" cmd /k "claude --resume"'
} else {
    $cmdOpen      = 'cmd.exe /k "cd /d "%1" && claude"'
    $cmdOpenBg    = 'cmd.exe /k "cd /d "%V" && claude"'
    $cmdResume    = 'cmd.exe /k "cd /d "%1" && claude --resume"'
    $cmdResumeBg  = 'cmd.exe /k "cd /d "%V" && claude --resume"'
}

# ── Install classic context menu entries ──────────────────────────────────────

Write-Host '  Installing context menu entries...' -ForegroundColor White

$regBase = 'HKCU:\Software\Classes'

function Add-MenuEntry($RegPath, $Label, $Command) {
    New-Item -Path "$RegPath\command" -Force | Out-Null
    Set-ItemProperty $RegPath -Name '(Default)' -Value $Label
    Set-ItemProperty $RegPath -Name 'Icon' -Value 'claude.exe'
    Set-ItemProperty "$RegPath\command" -Name '(Default)' -Value $Command
}

Add-MenuEntry "$regBase\Directory\shell\ClaudeCode"              'Open with Claude Code'   $cmdOpen
Add-MenuEntry "$regBase\Directory\Background\shell\ClaudeCode"   'Open with Claude Code'   $cmdOpenBg
Add-MenuEntry "$regBase\Directory\shell\ClaudeCodeResume"            'Resume Chat with Claude' $cmdResume
Add-MenuEntry "$regBase\Directory\Background\shell\ClaudeCodeResume" 'Resume Chat with Claude' $cmdResumeBg

Write-Check 'Open with Claude Code'
Write-Check 'Resume Chat with Claude'

# ── Modern context menu (Windows 11 + .NET 8 + Developer Mode) ───────────────

if ($installModern) {
    Write-Host ''
    Write-Host '  Installing modern context menu (top-level right-click)...' -ForegroundColor White

    # Determine ProcessorArchitecture for manifest
    $msixArch = switch ($arch) {
        'AMD64' { 'x64' }
        'ARM64' { 'arm64' }
        'x86'   { 'x86' }
        default { 'x64' }
    }

    # Build
    Write-Host '    Building shell extension...' -NoNewline
    Push-Location $ScriptDir
    try {
        $buildLog = & dotnet build -c Release --nologo -v quiet 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Host ' FAILED' -ForegroundColor Red
            Write-Host $buildLog
            Write-Host ''
            Write-Host '  Classic menu entries were installed.' -ForegroundColor Yellow
            Write-Host '  Modern menu skipped (build failed).' -ForegroundColor Yellow
            Write-Host ''
            exit 0
        }
    } finally { Pop-Location }
    Write-Host ' OK' -ForegroundColor Green

    # Install files
    if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force }
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    Copy-Item "$BuildOutput\ClaudeCodeShellExtension.dll"                $InstallDir
    Copy-Item "$BuildOutput\ClaudeCodeShellExtension.comhost.dll"        $InstallDir
    Copy-Item "$BuildOutput\ClaudeCodeShellExtension.deps.json"          $InstallDir
    Copy-Item "$BuildOutput\ClaudeCodeShellExtension.runtimeconfig.json" $InstallDir

    if (Test-Path $IconSrc) {
        Copy-Item $IconSrc (Join-Path $InstallDir 'claude-icon.png')
    }
    Copy-Item "$env:WINDIR\System32\cmd.exe" (Join-Path $InstallDir 'stub.exe')

    # Generate AppxManifest
    $manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:desktop4="http://schemas.microsoft.com/appx/manifest/desktop/windows10/4"
         xmlns:desktop5="http://schemas.microsoft.com/appx/manifest/desktop/windows10/5"
         xmlns:com="http://schemas.microsoft.com/appx/manifest/com/windows10"
         xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap uap10 desktop4 desktop5 com rescap">
    <Identity Name="$PkgName" Version="1.0.0.0"
              Publisher="$PkgPublisher" ProcessorArchitecture="$msixArch" />
    <Properties>
        <DisplayName>Claude Code Context Menu</DisplayName>
        <PublisherDisplayName>Claude Code</PublisherDisplayName>
        <Logo>claude-icon.png</Logo>
        <uap10:AllowExternalContent>true</uap10:AllowExternalContent>
    </Properties>
    <Dependencies>
        <TargetDeviceFamily Name="Windows.Desktop"
                            MinVersion="10.0.22000.0" MaxVersionTested="10.0.26100.0" />
    </Dependencies>
    <Resources><Resource Language="en-us" /></Resources>
    <Applications>
        <Application Id="App" Executable="stub.exe" EntryPoint="Windows.FullTrustApplication">
            <uap:VisualElements DisplayName="Claude Code" Description="Claude Code Context Menu"
                Square150x150Logo="claude-icon.png" Square44x44Logo="claude-icon.png"
                BackgroundColor="transparent" AppListEntry="none" />
            <Extensions>
                <com:Extension Category="windows.comServer">
                    <com:ComServer>
                        <com:SurrogateServer DisplayName="Claude Code Context Menu">
                            <com:Class Id="$OpenClsid" Path="ClaudeCodeShellExtension.comhost.dll" ThreadingModel="Both" />
                            <com:Class Id="$ResumeClsid" Path="ClaudeCodeShellExtension.comhost.dll" ThreadingModel="Both" />
                        </com:SurrogateServer>
                    </com:ComServer>
                </com:Extension>
                <desktop4:Extension Category="windows.fileExplorerContextMenus">
                    <desktop4:FileExplorerContextMenus>
                        <desktop5:ItemType Type="Directory">
                            <desktop5:Verb Id="OpenClaude" Clsid="$OpenClsid" />
                            <desktop5:Verb Id="ResumeClaude" Clsid="$ResumeClsid" />
                        </desktop5:ItemType>
                        <desktop5:ItemType Type="Directory\Background">
                            <desktop5:Verb Id="OpenClaudeBg" Clsid="$OpenClsid" />
                            <desktop5:Verb Id="ResumeClaudeBg" Clsid="$ResumeClsid" />
                        </desktop5:ItemType>
                    </desktop4:FileExplorerContextMenus>
                </desktop4:Extension>
            </Extensions>
        </Application>
    </Applications>
    <Capabilities><rescap:Capability Name="runFullTrust" /></Capabilities>
</Package>
"@
    $manifestPath = Join-Path $InstallDir 'AppxManifest.xml'
    $manifest | Out-File -Encoding utf8 $manifestPath

    # Register sparse package
    Write-Host '    Registering package...' -NoNewline
    try {
        Add-AppxPackage -Register $manifestPath -ExternalLocation $InstallDir 2>&1 | Out-Null
        Write-Host ' OK' -ForegroundColor Green
        Write-Check 'Modern context menu registered'
    } catch {
        Write-Host ' FAILED' -ForegroundColor Red
        Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkGray
        Write-Host ''
        Write-Host '  Classic menu entries were installed.' -ForegroundColor Yellow
        Write-Host '  Modern menu failed — enable Developer Mode and re-run.' -ForegroundColor Yellow
        Write-Host ''
        exit 0
    }
}

# ── Restart Explorer (needed for modern menu to appear) ──────────────────────

if ($installModern) {
    Write-Host ''
    Write-Host '  Restarting Explorer...' -NoNewline
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process explorer
    Write-Host ' OK' -ForegroundColor Green
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '  =============================================' -ForegroundColor Green
Write-Host '  Done!' -ForegroundColor Green
Write-Host '  =============================================' -ForegroundColor Green
Write-Host ''
if ($installModern) {
    Write-Host '  Right-click any folder to see:'
    Write-Host '    - "Open with Claude Code"     (top-level + classic menu)'
    Write-Host '    - "Resume Chat with Claude"   (top-level + classic menu)'
} elseif ($isWin11) {
    Write-Host '  Right-click any folder > "Show more options" to see:'
    Write-Host '    - "Open with Claude Code"'
    Write-Host '    - "Resume Chat with Claude"'
    if (-not $hasDotnet8) {
        Write-Host ''
        Write-Host '  Re-run after installing .NET 8 SDK to add top-level entries.' -ForegroundColor DarkGray
    }
} else {
    Write-Host '  Right-click any folder to see:'
    Write-Host '    - "Open with Claude Code"'
    Write-Host '    - "Resume Chat with Claude"'
}
Write-Host ''
