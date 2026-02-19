<h1><img width="32" height="32" alt="claude-icon" src="https://github.com/user-attachments/assets/39d92075-ade9-47f8-9999-8ab7369e6257" />&nbsp; Claude Code Context Menu</h1>

Right-click context menu entries for **"Open with Claude Code"** and **"Resume Chat with Claude"** on Windows, macOS, and Linux.

| Entry | What it does |
|-------|-------------|
| **Open with Claude Code** | Opens a terminal in the selected folder and starts `claude` |
| **Resume Chat with Claude** | Opens a terminal in the selected folder and runs `claude --resume` (interactive session picker) |

## Windows

<img width="510" height="397" alt="CONTEXT_MENU" src="https://github.com/user-attachments/assets/abd7f80a-2bc7-4009-83df-c34e101fd85f" />

Double-click **`windows/install.cmd`**.

The installer auto-detects your setup and walks you through everything:
- Auto-detects Windows Terminal vs CMD
- On Windows 11, offers to download and install the [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) if needed, then builds a shell extension for the top-level right-click menu
- Adds entries to the classic context menu on any Windows version
- Restarts Explorer automatically so entries appear immediately

On Windows 11 with .NET 8 SDK + [Developer Mode](ms-settings:developers), entries appear in **both** the top-level right-click menu and the classic "Show more options" menu. Without those, entries still appear in the classic menu.

**Uninstall:** Double-click `windows/uninstall.cmd`.

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

<details>
<summary>Alternative: Quick Actions (no app install)</summary>

```bash
bash macos/install.sh
```

Creates two Finder Quick Actions in `~/Library/Services/`. They appear under right-click → **Quick Actions** submenu (not top-level).

Uninstall: `bash macos/uninstall.sh`
</details>

## Linux

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
│   └── claude-icon.png        Icon for all platforms
├── windows/
│   ├── install.cmd            Double-click to install
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
