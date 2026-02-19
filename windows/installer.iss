; Claude Code Context Menu - Inno Setup Installer
; =================================================
; Build:   iscc windows/installer.iss
; Version: iscc /DMyAppVersion=1.2.3 windows/installer.iss
;
; Prerequisites:
;   1. Build DLLs first: cd windows/modern && dotnet build -c Release
;   2. Inno Setup 6.x installed (https://jrsoftware.org/isinfo.php)

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

[Setup]
AppId={{B8F5E3A1-9C4D-4E67-A2B3-C5D6E7F8A9B0}
AppName=Claude Code Context Menu
AppVersion={#MyAppVersion}
AppVerName=Claude Code Context Menu {#MyAppVersion}
AppPublisher=Anthropic
DefaultDirName={localappdata}\ClaudeCode\ShellExtension
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=ClaudeCodeContextMenu-Setup-{#MyAppVersion}-x64
SetupIconFile=..\icons\claude-icon.ico
UninstallDisplayIcon={app}\claude-icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
DefaultGroupName=Claude Code Context Menu

[Files]
; Shell extension DLLs (pre-built)
Source: "modern\bin\Release\net8.0-windows\ClaudeCodeShellExtension.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "modern\bin\Release\net8.0-windows\ClaudeCodeShellExtension.comhost.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "modern\bin\Release\net8.0-windows\ClaudeCodeShellExtension.deps.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "modern\bin\Release\net8.0-windows\ClaudeCodeShellExtension.runtimeconfig.json"; DestDir: "{app}"; Flags: ignoreversion
; Icons
Source: "..\icons\claude-icon.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\icons\claude-icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; === Open with Claude Code — folder right-click ===
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCode"; ValueType: string; ValueName: ""; ValueData: "Open with Claude Code"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCode"; ValueType: string; ValueName: "Icon"; ValueData: "claude.exe"
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCode\command"; ValueType: string; ValueName: ""; ValueData: "{code:GetCmdOpen}"

; === Open with Claude Code — folder background right-click ===
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCode"; ValueType: string; ValueName: ""; ValueData: "Open with Claude Code"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCode"; ValueType: string; ValueName: "Icon"; ValueData: "claude.exe"
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCode\command"; ValueType: string; ValueName: ""; ValueData: "{code:GetCmdOpenBg}"

; === Resume Chat with Claude — folder right-click ===
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCodeResume"; ValueType: string; ValueName: ""; ValueData: "Resume Chat with Claude"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCodeResume"; ValueType: string; ValueName: "Icon"; ValueData: "claude.exe"
Root: HKCU; Subkey: "Software\Classes\Directory\shell\ClaudeCodeResume\command"; ValueType: string; ValueName: ""; ValueData: "{code:GetCmdResume}"

; === Resume Chat with Claude — folder background right-click ===
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCodeResume"; ValueType: string; ValueName: ""; ValueData: "Resume Chat with Claude"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCodeResume"; ValueType: string; ValueName: "Icon"; ValueData: "claude.exe"
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\ClaudeCodeResume\command"; ValueType: string; ValueName: ""; ValueData: "{code:GetCmdResumeBg}"

[UninstallDelete]
; Clean up files generated at install time
Type: files; Name: "{app}\stub.exe"
Type: files; Name: "{app}\AppxManifest.xml"

[Code]
var
  HasWT: Boolean;
  IsWin11: Boolean;
  HasDevMode: Boolean;
  HasDotNetRuntime: Boolean;
  StatusPage: TOutputMsgMemoWizardPage;

const
  OpenClsid   = 'E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E60';
  ResumeClsid = 'E3C4A0D1-B5F2-4C67-8A9E-1D2F3B4C5E61';
  PkgName     = 'ClaudeCode.ContextMenu';

// ---------------------------------------------------------------------------
// Detection helpers
// ---------------------------------------------------------------------------

function FileExistsInPath(const FileName: string): Boolean;
var
  PathEnv, Dir: string;
  P: Integer;
begin
  Result := False;
  PathEnv := GetEnv('PATH');
  while Length(PathEnv) > 0 do
  begin
    P := Pos(';', PathEnv);
    if P = 0 then
    begin
      Dir := PathEnv;
      PathEnv := '';
    end else
    begin
      Dir := Copy(PathEnv, 1, P - 1);
      Delete(PathEnv, 1, P);
    end;
    if (Dir <> '') and FileExists(Dir + '\' + FileName) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function DetectWindowsTerminal: Boolean;
begin
  Result := FileExistsInPath('wt.exe');
  if not Result then
    Result := FileExists(ExpandConstant('{localappdata}\Microsoft\WindowsApps\wt.exe'));
end;

function DetectWin11: Boolean;
var
  Version: TWindowsVersion;
begin
  GetWindowsVersionEx(Version);
  Result := Version.Build >= 22000;
end;

function DetectDevMode: Boolean;
var
  Value: Cardinal;
begin
  Result := False;
  if RegQueryDWordValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock',
                        'AllowDevelopmentWithoutDevLicense', Value) then
    Result := (Value = 1);
end;

function DetectDotNetRuntime: Boolean;
var
  ResultCode: Integer;
  TempFile: string;
  Output: AnsiString;
begin
  Result := False;
  TempFile := ExpandConstant('{tmp}\dotnet_check.txt');
  if Exec('cmd.exe', '/c dotnet --list-runtimes > "' + TempFile + '" 2>&1',
           '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if (ResultCode = 0) and LoadStringFromFile(TempFile, Output) then
    begin
      if Pos('Microsoft.NETCore.App 8.', String(Output)) > 0 then
        Result := True;
    end;
  end;
  DeleteFile(TempFile);
end;

// ---------------------------------------------------------------------------
// Registry command getters — called via {code:} at install time
// ---------------------------------------------------------------------------

function GetCmdOpen(Param: string): string;
begin
  if HasWT then
    Result := 'wt.exe -d "%1" cmd /k claude'
  else
    Result := 'cmd.exe /k "cd /d "%1" && claude"';
end;

function GetCmdOpenBg(Param: string): string;
begin
  if HasWT then
    Result := 'wt.exe -d "%V" cmd /k claude'
  else
    Result := 'cmd.exe /k "cd /d "%V" && claude"';
end;

function GetCmdResume(Param: string): string;
begin
  if HasWT then
    Result := 'wt.exe -d "%1" cmd /k "claude --resume"'
  else
    Result := 'cmd.exe /k "cd /d "%1" && claude --resume"';
end;

function GetCmdResumeBg(Param: string): string;
begin
  if HasWT then
    Result := 'wt.exe -d "%V" cmd /k "claude --resume"'
  else
    Result := 'cmd.exe /k "cd /d "%V" && claude --resume"';
end;

// ---------------------------------------------------------------------------
// MSIX architecture helper
// ---------------------------------------------------------------------------

function GetMsixArch: string;
begin
  if IsArm64 then
    Result := 'arm64'
  else
    Result := 'x64';
end;

// ---------------------------------------------------------------------------
// InitializeSetup — runs detection before wizard appears
// ---------------------------------------------------------------------------

function InitializeSetup: Boolean;
begin
  HasWT            := DetectWindowsTerminal;
  IsWin11          := DetectWin11;
  HasDevMode       := DetectDevMode;
  HasDotNetRuntime := DetectDotNetRuntime;
  Result := True;
end;

// ---------------------------------------------------------------------------
// Wizard page — shows detection results
// ---------------------------------------------------------------------------

procedure InitializeWizard;
var
  S: string;
begin
  StatusPage := CreateOutputMsgMemoPage(wpWelcome,
    'System Detection',
    'Your system has been scanned for compatible features.',
    'Detection results:',
    '');

  if IsWin11 then
    S := '[+]  Windows 11 detected' + #13#10
  else
    S := '[-]  Windows 10 detected' + #13#10;

  if HasWT then
    S := S + '[+]  Windows Terminal detected' + #13#10
  else
    S := S + '[-]  Windows Terminal not found (will use CMD)' + #13#10;

  if IsWin11 then
  begin
    if HasDevMode then
      S := S + '[+]  Developer Mode enabled' + #13#10
    else
      S := S + '[X]  Developer Mode not enabled' + #13#10;

    if HasDotNetRuntime then
      S := S + '[+]  .NET 8 Runtime detected' + #13#10
    else
      S := S + '[X]  .NET 8 Runtime not found' + #13#10;
  end;

  S := S + #13#10;
  S := S + 'Classic context menu entries will always be installed.' + #13#10;

  if IsWin11 and HasDevMode and HasDotNetRuntime then
    S := S + 'Modern top-level context menu will also be installed.'
  else if IsWin11 then
  begin
    S := S + #13#10 + 'For top-level context menu on Windows 11, you also need:' + #13#10;
    if not HasDevMode then
      S := S + '  - Developer Mode  (Settings > Privacy & Security > For developers)' + #13#10;
    if not HasDotNetRuntime then
      S := S + '  - .NET 8 Runtime  (https://dotnet.microsoft.com/download/dotnet/8.0)' + #13#10;
  end;

  StatusPage.RichEditViewer.Text := S;
end;

// ---------------------------------------------------------------------------
// Post-install: register modern context menu (Win11 + DevMode + .NET 8)
// ---------------------------------------------------------------------------

procedure RegisterModernMenu;
var
  ManifestPath, Manifest, Arch, AppDir: string;
  ResultCode: Integer;
begin
  Arch   := GetMsixArch;
  AppDir := ExpandConstant('{app}');

  // Copy cmd.exe as stub.exe (required by AppxManifest)
  CopyFile(ExpandConstant('{sys}\cmd.exe'), AppDir + '\stub.exe', False);

  // Generate AppxManifest.xml
  ManifestPath := AppDir + '\AppxManifest.xml';

  Manifest :=
    '<?xml version="1.0" encoding="utf-8"?>' + #13#10 +
    '<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"' + #13#10 +
    '         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"' + #13#10 +
    '         xmlns:desktop4="http://schemas.microsoft.com/appx/manifest/desktop/windows10/4"' + #13#10 +
    '         xmlns:desktop5="http://schemas.microsoft.com/appx/manifest/desktop/windows10/5"' + #13#10 +
    '         xmlns:com="http://schemas.microsoft.com/appx/manifest/com/windows10"' + #13#10 +
    '         xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10"' + #13#10 +
    '         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"' + #13#10 +
    '         IgnorableNamespaces="uap uap10 desktop4 desktop5 com rescap">' + #13#10 +
    '    <Identity Name="' + PkgName + '" Version="1.0.0.0"' + #13#10 +
    '              Publisher="CN=ClaudeCodeDev" ProcessorArchitecture="' + Arch + '" />' + #13#10 +
    '    <Properties>' + #13#10 +
    '        <DisplayName>Claude Code Context Menu</DisplayName>' + #13#10 +
    '        <PublisherDisplayName>Claude Code</PublisherDisplayName>' + #13#10 +
    '        <Logo>claude-icon.png</Logo>' + #13#10 +
    '        <uap10:AllowExternalContent>true</uap10:AllowExternalContent>' + #13#10 +
    '    </Properties>' + #13#10 +
    '    <Dependencies>' + #13#10 +
    '        <TargetDeviceFamily Name="Windows.Desktop"' + #13#10 +
    '                            MinVersion="10.0.22000.0" MaxVersionTested="10.0.26100.0" />' + #13#10 +
    '    </Dependencies>' + #13#10 +
    '    <Resources><Resource Language="en-us" /></Resources>' + #13#10 +
    '    <Applications>' + #13#10 +
    '        <Application Id="App" Executable="stub.exe" EntryPoint="Windows.FullTrustApplication">' + #13#10 +
    '            <uap:VisualElements DisplayName="Claude Code" Description="Claude Code Context Menu"' + #13#10 +
    '                Square150x150Logo="claude-icon.png" Square44x44Logo="claude-icon.png"' + #13#10 +
    '                BackgroundColor="transparent" AppListEntry="none" />' + #13#10 +
    '            <Extensions>' + #13#10 +
    '                <com:Extension Category="windows.comServer">' + #13#10 +
    '                    <com:ComServer>' + #13#10 +
    '                        <com:SurrogateServer DisplayName="Claude Code Context Menu">' + #13#10 +
    '                            <com:Class Id="' + OpenClsid + '" Path="ClaudeCodeShellExtension.comhost.dll" ThreadingModel="Both" />' + #13#10 +
    '                            <com:Class Id="' + ResumeClsid + '" Path="ClaudeCodeShellExtension.comhost.dll" ThreadingModel="Both" />' + #13#10 +
    '                        </com:SurrogateServer>' + #13#10 +
    '                    </com:ComServer>' + #13#10 +
    '                </com:Extension>' + #13#10 +
    '                <desktop4:Extension Category="windows.fileExplorerContextMenus">' + #13#10 +
    '                    <desktop4:FileExplorerContextMenus>' + #13#10 +
    '                        <desktop5:ItemType Type="Directory">' + #13#10 +
    '                            <desktop5:Verb Id="OpenClaude" Clsid="' + OpenClsid + '" />' + #13#10 +
    '                            <desktop5:Verb Id="ResumeClaude" Clsid="' + ResumeClsid + '" />' + #13#10 +
    '                        </desktop5:ItemType>' + #13#10 +
    '                        <desktop5:ItemType Type="Directory\Background">' + #13#10 +
    '                            <desktop5:Verb Id="OpenClaudeBg" Clsid="' + OpenClsid + '" />' + #13#10 +
    '                            <desktop5:Verb Id="ResumeClaudeBg" Clsid="' + ResumeClsid + '" />' + #13#10 +
    '                        </desktop5:ItemType>' + #13#10 +
    '                    </desktop4:FileExplorerContextMenus>' + #13#10 +
    '                </desktop4:Extension>' + #13#10 +
    '            </Extensions>' + #13#10 +
    '        </Application>' + #13#10 +
    '    </Applications>' + #13#10 +
    '    <Capabilities><rescap:Capability Name="runFullTrust" /></Capabilities>' + #13#10 +
    '</Package>';

  SaveStringToFile(ManifestPath, Manifest, False);

  // Register sparse MSIX package
  Exec('powershell.exe',
    '-NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -Register ''' +
    ManifestPath + ''' -ExternalLocation ''' + AppDir + '''"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// ---------------------------------------------------------------------------
// Explorer restart
// ---------------------------------------------------------------------------

procedure RestartExplorer;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/f /im explorer.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(2000);
  Exec('explorer.exe', '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
end;

// ---------------------------------------------------------------------------
// Remove AppxPackage (used by both upgrade and uninstall)
// ---------------------------------------------------------------------------

procedure RemoveAppxPackage;
var
  ResultCode: Integer;
begin
  Exec('powershell.exe',
    '-NoProfile -ExecutionPolicy Bypass -Command "' +
    '$pkg = Get-AppxPackage -Name ''' + PkgName + ''' -ErrorAction SilentlyContinue; ' +
    'if ($pkg) { Remove-AppxPackage $pkg.PackageFullName }"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// ---------------------------------------------------------------------------
// Post-install step
// ---------------------------------------------------------------------------

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Remove any previously registered package (clean upgrade)
    RemoveAppxPackage;

    // Register modern menu if all conditions are met
    if IsWin11 and HasDevMode and HasDotNetRuntime then
    begin
      RegisterModernMenu;
      RestartExplorer;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Uninstall step
// ---------------------------------------------------------------------------

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    RemoveAppxPackage;
    RestartExplorer;
  end;
end;
