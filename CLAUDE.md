# Claude Code Context Menu

Right-click context menu entries for "Open with Claude Code" and "Resume Chat with Claude" on Windows, macOS, and Linux.

## Project Structure

```
icons/
  claude-icon.png          Source icon (256x256 RGBA PNG)
  claude-icon.ico          Windows icon (generated from PNG via Pillow)
windows/
  installer.iss            Inno Setup script → .exe installer
  install.cmd              Launches PowerShell installer (from-source flow)
  uninstall.cmd            Launches PowerShell uninstaller
  modern/
    ClaudeCodeShellExtension.csproj   .NET 8 COM shell extension
    ExplorerCommand.cs                IExplorerCommand implementation
    install.ps1                       PowerShell installer (from-source)
    uninstall.ps1                     PowerShell uninstaller
macos/
  ClaudeCodeMenu/          Finder Sync Extension (Swift/Xcode)
  install.sh / uninstall.sh
linux/
  install.sh / uninstall.sh
```

## Windows Installer (.exe via Inno Setup)

### Build

```bash
# 1. Build .NET DLLs (requires .NET 8 SDK)
cd windows/modern && dotnet build -c Release

# 2. Compile installer (requires Inno Setup 6.x)
iscc windows/installer.iss
# Or with version: iscc /DMyAppVersion=1.2.3 windows/installer.iss
# Output: windows/Output/ClaudeCodeContextMenu-Setup-<version>-x64.exe
```

### Key Details

- `PrivilegesRequired=lowest` — no admin, all registry under HKCU
- Install path: `%LOCALAPPDATA%\ClaudeCode\ShellExtension`
- Registry: `HKCU\Software\Classes\Directory\shell\ClaudeCode` (+ Background, + Resume variants)
- Classic menu: always installed. Modern menu (Win11 top-level): requires Win11 + Developer Mode + .NET 8 Runtime
- `{code:GetCmd*}` functions detect Windows Terminal vs CMD at install time
- Post-install Pascal Script generates AppxManifest.xml and registers sparse MSIX package
- Uninstall removes AppxPackage, registry keys, and files automatically
- COM CLSIDs: Open=`E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E60`, Resume=`E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E61`
- MSIX package name: `ClaudeCode.ContextMenu`, publisher: `CN=ClaudeCodeDev`

### Inno Setup Notes

- `FileCopy` is deprecated in Inno Setup 6.7+ — use `CopyFile` instead
- ISCC.exe installs to `%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe` (user install via winget)
- `SaveStringToFile` writes ANSI; fine for our ASCII-only AppxManifest.xml
- `{code:FunctionName}` return values are NOT further constant-expanded (safe for `%1`/`%V`)

## Generating claude-icon.ico

```python
from PIL import Image
img = Image.open('icons/claude-icon.png')
img.save('icons/claude-icon.ico', format='ICO', sizes=[(256, 256), (48, 48), (32, 32), (16, 16)])
```

Requires `pip install Pillow`.
