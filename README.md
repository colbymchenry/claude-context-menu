# <img width="256" height="256" alt="claude-icon" src="https://github.com/user-attachments/assets/39d92075-ade9-47f8-9999-8ab7369e6257" />
Claude Code Context Menu

Right-click context menu entries for **"Open with Claude Code"** and **"Resume Chat with Claude"** on Windows, macOS, and Linux.

| Entry | What it does |
|-------|-------------|
| **Open with Claude Code** | Opens a terminal in the selected folder and starts `claude` |
| **Resume Chat with Claude** | Opens a terminal in the selected folder and runs `claude --resume` (interactive session picker) |

## Windows

Two variants — pick one:

| File | Terminal |
|------|----------|
| `windows/install.reg` | CMD (`cmd.exe`) |
| `windows/install-wt.reg` | [Windows Terminal](https://aka.ms/terminal) (`wt.exe`) |

**Install:** Double-click the `.reg` file and confirm the merge. No admin rights required.

**Uninstall:** Double-click `windows/uninstall.reg`.

Both entries appear when you right-click a folder or right-click empty space inside a folder. On Windows 11 they're under "Show more options" (classic context menu).

The entries show the Claude icon automatically (extracted from `claude.exe` via PATH).

> **Note:** If `claude` isn't in your PATH, edit the `.reg` file and replace `claude` with the full path, e.g. `C:\\Users\\YourName\\AppData\\Local\\Programs\\claude\\claude.exe`.

## macOS

```bash
bash macos/install.sh
```

This creates two Finder Quick Actions in `~/Library/Services/`. They appear in Finder's right-click → **Quick Actions** menu.

**Uninstall:**
```bash
bash macos/uninstall.sh
```

> **Note:** macOS renders Quick Action icons as white monochrome templates — this is an Apple design limitation. The entries show by name only.

If the entries don't appear immediately, open and close Automator once to refresh the cache, or log out and back in.

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
│   └── claude-icon.png          256×256 icon for Linux file managers
├── windows/
│   ├── install.reg              CMD variant
│   ├── install-wt.reg           Windows Terminal variant
│   └── uninstall.reg
├── macos/
│   ├── install.sh
│   └── uninstall.sh
└── linux/
    ├── install.sh
    └── uninstall.sh
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and available as `claude` in your terminal
