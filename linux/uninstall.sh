#!/bin/bash
# ============================================================
# Remove "Open with Claude Code" and "Resume Chat with Claude"
# context menu entries for Linux file managers
# ============================================================
# Removes entries for: Nautilus (GNOME), Dolphin (KDE), Nemo (Cinnamon/Mint)
#
# Usage: bash uninstall.sh
# ============================================================

set -euo pipefail

echo "Removing Claude Code context menu entries..."

# ---- Nautilus ----
NAUTILUS_DIR="$HOME/.local/share/nautilus/scripts"
if [ -f "$NAUTILUS_DIR/Open with Claude Code" ] || [ -f "$NAUTILUS_DIR/Resume Chat with Claude" ]; then
    rm -f "$NAUTILUS_DIR/Open with Claude Code"
    rm -f "$NAUTILUS_DIR/Resume Chat with Claude"
    echo "  Removed: Nautilus scripts"
fi

# ---- Dolphin ----
DOLPHIN_FILE="$HOME/.local/share/kio/servicemenus/claude-code.desktop"
if [ -f "$DOLPHIN_FILE" ]; then
    rm -f "$DOLPHIN_FILE"
    echo "  Removed: Dolphin service menu"
fi

# ---- Nemo ----
NEMO_DIR="$HOME/.local/share/nemo/actions"
if [ -f "$NEMO_DIR/claude-code-open.nemo_action" ] || [ -f "$NEMO_DIR/claude-code-resume.nemo_action" ]; then
    rm -f "$NEMO_DIR/claude-code-open.nemo_action"
    rm -f "$NEMO_DIR/claude-code-resume.nemo_action"
    echo "  Removed: Nemo actions"
fi

# ---- Icon ----
ICON="$HOME/.local/share/icons/claude-code.png"
if [ -f "$ICON" ]; then
    rm -f "$ICON"
    echo "  Removed: Icon ($ICON)"
fi

echo
echo "Done! All Claude Code context menu entries have been removed."
echo "You may need to restart your file manager for changes to take effect."
