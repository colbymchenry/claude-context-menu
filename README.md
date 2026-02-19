<h1><img width="32" height="32" alt="claude-icon" src="https://github.com/user-attachments/assets/39d92075-ade9-47f8-9999-8ab7369e6257" />&nbsp; Claude Code Context Menu</h1>

Right-click context menu entries for **"Open with Claude Code"** and **"Resume Chat with Claude"** on Windows, macOS, and Linux.

| Entry | What it does |
|-------|-------------|
| **Open with Claude Code** | Opens a terminal in the selected folder and starts `claude` |
| **Resume Chat with Claude** | Opens a terminal in the selected folder and runs `claude --resume` (interactive session picker) |

## Windows

<img width="510" height="397" alt="CONTEXT_MENU" src="https://github.com/user-attachments/assets/abd7f80a-2bc7-4009-83df-c34e101fd85f" />

Download **ClaudeCodeContextMenu-Setup.exe** from the [latest release](https://github.com/anthropics/claude-context-menu/releases/latest) and run it.

1. Run the installer — no admin required
2. A **System Detection** page shows what was found (Windows Terminal, Developer Mode, .NET 8, etc.)
3. Click through the wizard — classic context menu entries are installed automatically
4. On Windows 11 with [.NET 8 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) + [Developer Mode](ms-settings:developers), entries also appear in the top-level right-click menu
5. Right-click any folder to see **"Open with Claude Code"** and **"Resume Chat with Claude"**

**Uninstall:** Settings → Apps → Installed apps → **Claude Code Context Menu** → Uninstall.

<details>
<summary>Alternative: install from source</summary>

Double-click **`windows/install.cmd`**. This runs the PowerShell installer directly from the repo — it can also download the .NET 8 SDK and build the shell extension on-the-fly.

Uninstall: Double-click `windows/uninstall.cmd`.
</details>

## macOS

<img width="374" height="609" alt="Screenshot 2026-02-19 at 4 49 48 PM" src="https://github.com/user-attachments/assets/1f48ba6e-150a-4250-919e-72691ed7b499" />

Download **ClaudeCodeMenu.dmg** from the [latest release](https://github.com/anthropics/claude-context-menu/releases/latest), open it, and drag **Claude Code Menu** to Applications.

1. Launch **Claude Code Menu** — helper scripts install automatically
2. Click **"Enable Finder Extension in System Settings"**
3. Toggle on **Claude Code Menu** under Added Extensions
4. Right-click any file or folder in Finder — entries appear at the top level with the Claude icon

**Uninstall:** Move Claude Code Menu to Trash. To also remove helper scripts:
```bash
rm -rf ~/Library/Application\ Scripts/com.anthropic.ClaudeCodeMenu.FinderExtension
```

## Linux (Not Tested)

```bash
bash linux/install.sh
```

The script detects installed file managers and configures each:

| File manager | Location | Icons |
|-------------|----------|-------|
| **Nautilus** (GNOME Files) | Right-click → Scripts | No (Nautilus limitation) |
| **Dolphin** (KDE) | Right-click context menu | Yes |
| **Nemo** (Cinnamon/Mint) | Right-click context menu | Yes |

The icon is installed to `~/.local/share/icons/claude-code.png`.

Terminal detection falls back through: `gnome-terminal` → `x-terminal-emulator` → `xterm`.

**Uninstall:**
```bash
bash linux/uninstall.sh
```

## Project structure

```
claude-context-menu/
├── icons/
│   ├── claude-icon.png        Icon for all platforms
│   └── claude-icon.ico        Windows icon (used by installer)
├── windows/
│   ├── installer.iss          Inno Setup script → .exe installer
│   ├── install.cmd            Double-click to install (from source)
│   ├── uninstall.cmd          Double-click to uninstall
│   └── modern/                Shell extension source (C#/.NET 8)
├── macos/
│   ├── ClaudeCodeMenu/        Finder Sync Extension (Swift, builds DMG)
│   ├── install.sh             Quick Actions fallback
│   └── uninstall.sh
└── linux/
    ├── install.sh             bash linux/install.sh
    └── uninstall.sh
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and available as `claude` in your terminal
