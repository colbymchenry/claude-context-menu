#!/bin/bash
# ============================================================
# Install "Open with Claude Code" and "Resume Chat with Claude"
# context menu entries for Linux file managers
# ============================================================
# Supports: Nautilus (GNOME), Dolphin (KDE), Nemo (Cinnamon/Mint)
# Detects which file managers are installed and configures each.
#
# Usage: bash install.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ICON_SRC="$REPO_DIR/icons/claude-icon.png"
ICON_DEST="$HOME/.local/share/icons/claude-code.png"

installed_any=false

# ---- Step 1: Install icon ----
echo "Installing icon..."
mkdir -p "$HOME/.local/share/icons"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$ICON_DEST"
    echo "  Installed: $ICON_DEST"
else
    echo "  Warning: $ICON_SRC not found — Dolphin/Nemo icons will be missing"
fi

# ---- Helper: detect terminal emulator ----
detect_terminal_cmd() {
    local dir_var="$1"
    local claude_cmd="$2"

    if command -v gnome-terminal &>/dev/null; then
        echo "gnome-terminal --working-directory=\"$dir_var\" -- bash -c '${claude_cmd}; exec bash'"
    elif command -v x-terminal-emulator &>/dev/null; then
        echo "cd \"$dir_var\" && x-terminal-emulator -e bash -c '${claude_cmd}; exec bash'"
    elif command -v xterm &>/dev/null; then
        echo "cd \"$dir_var\" && xterm -e bash -c '${claude_cmd}; exec bash'"
    else
        echo "echo 'No supported terminal emulator found'; read"
    fi
}

# ---- Step 2: Nautilus (GNOME Files) ----
if command -v nautilus &>/dev/null; then
    echo
    echo "Nautilus detected — installing scripts..."
    NAUTILUS_DIR="$HOME/.local/share/nautilus/scripts"
    mkdir -p "$NAUTILUS_DIR"

    cat > "$NAUTILUS_DIR/Open with Claude Code" << 'SCRIPT'
#!/bin/bash
DIR="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
[ -z "$DIR" ] && DIR=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|file://||;s|%20| |g')
DIR=$(echo "$DIR" | head -1)
[ -f "$DIR" ] && DIR="$(dirname "$DIR")"
[ -z "$DIR" ] && DIR="$HOME"

if command -v gnome-terminal &>/dev/null; then
    gnome-terminal --working-directory="$DIR" -- bash -c 'claude; exec bash'
elif command -v x-terminal-emulator &>/dev/null; then
    cd "$DIR" && x-terminal-emulator -e bash -c 'claude; exec bash'
elif command -v xterm &>/dev/null; then
    cd "$DIR" && xterm -e bash -c 'claude; exec bash'
fi
SCRIPT
    chmod +x "$NAUTILUS_DIR/Open with Claude Code"

    cat > "$NAUTILUS_DIR/Resume Chat with Claude" << 'SCRIPT'
#!/bin/bash
DIR="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
[ -z "$DIR" ] && DIR=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|file://||;s|%20| |g')
DIR=$(echo "$DIR" | head -1)
[ -f "$DIR" ] && DIR="$(dirname "$DIR")"
[ -z "$DIR" ] && DIR="$HOME"

if command -v gnome-terminal &>/dev/null; then
    gnome-terminal --working-directory="$DIR" -- bash -c 'claude --resume; exec bash'
elif command -v x-terminal-emulator &>/dev/null; then
    cd "$DIR" && x-terminal-emulator -e bash -c 'claude --resume; exec bash'
elif command -v xterm &>/dev/null; then
    cd "$DIR" && xterm -e bash -c 'claude --resume; exec bash'
fi
SCRIPT
    chmod +x "$NAUTILUS_DIR/Resume Chat with Claude"

    echo "  Installed: $NAUTILUS_DIR/Open with Claude Code"
    echo "  Installed: $NAUTILUS_DIR/Resume Chat with Claude"
    echo "  Note: Nautilus scripts submenu does not support custom icons"
    installed_any=true
fi

# ---- Step 3: Dolphin (KDE) ----
if command -v dolphin &>/dev/null; then
    echo
    echo "Dolphin detected — installing service menu..."
    DOLPHIN_DIR="$HOME/.local/share/kio/servicemenus"
    mkdir -p "$DOLPHIN_DIR"

    cat > "$DOLPHIN_DIR/claude-code.desktop" << EOF
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=OpenClaude;ResumeClaude;

[Desktop Action OpenClaude]
Name=Open with Claude Code
Icon=$ICON_DEST
Exec=konsole --workdir %f -e bash -c "claude; exec bash"

[Desktop Action ResumeClaude]
Name=Resume Chat with Claude
Icon=$ICON_DEST
Exec=konsole --workdir %f -e bash -c "claude --resume; exec bash"
EOF

    echo "  Installed: $DOLPHIN_DIR/claude-code.desktop"
    installed_any=true
fi

# ---- Step 4: Nemo (Cinnamon / Linux Mint) ----
if command -v nemo &>/dev/null; then
    echo
    echo "Nemo detected — installing actions..."
    NEMO_DIR="$HOME/.local/share/nemo/actions"
    mkdir -p "$NEMO_DIR"

    # Detect preferred terminal for Nemo
    NEMO_TERM_OPEN=""
    NEMO_TERM_RESUME=""
    if command -v gnome-terminal &>/dev/null; then
        NEMO_TERM_OPEN='gnome-terminal --working-directory="%F" -- bash -c "claude; exec bash"'
        NEMO_TERM_RESUME='gnome-terminal --working-directory="%F" -- bash -c "claude --resume; exec bash"'
    elif command -v x-terminal-emulator &>/dev/null; then
        NEMO_TERM_OPEN='bash -c "cd \"%F\" && x-terminal-emulator -e bash -c \"claude; exec bash\""'
        NEMO_TERM_RESUME='bash -c "cd \"%F\" && x-terminal-emulator -e bash -c \"claude --resume; exec bash\""'
    elif command -v xterm &>/dev/null; then
        NEMO_TERM_OPEN='bash -c "cd \"%F\" && xterm -e bash -c \"claude; exec bash\""'
        NEMO_TERM_RESUME='bash -c "cd \"%F\" && xterm -e bash -c \"claude --resume; exec bash\""'
    else
        NEMO_TERM_OPEN='bash -c "echo No supported terminal found; read"'
        NEMO_TERM_RESUME='bash -c "echo No supported terminal found; read"'
    fi

    cat > "$NEMO_DIR/claude-code-open.nemo_action" << EOF
[Nemo Action]
Name=Open with Claude Code
Icon-Name=$ICON_DEST
Exec=$NEMO_TERM_OPEN
Selection=any
Extensions=dir;
EOF

    cat > "$NEMO_DIR/claude-code-resume.nemo_action" << EOF
[Nemo Action]
Name=Resume Chat with Claude
Icon-Name=$ICON_DEST
Exec=$NEMO_TERM_RESUME
Selection=any
Extensions=dir;
EOF

    echo "  Installed: $NEMO_DIR/claude-code-open.nemo_action"
    echo "  Installed: $NEMO_DIR/claude-code-resume.nemo_action"
    installed_any=true
fi

echo

if [ "$installed_any" = true ]; then
    echo "Done! Context menu entries have been installed."
    echo "You may need to restart your file manager for changes to take effect."
else
    echo "No supported file manager detected (Nautilus, Dolphin, or Nemo)."
    echo "If your file manager was not detected, please open an issue."
fi
