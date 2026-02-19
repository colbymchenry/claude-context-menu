#!/bin/bash
# ============================================================
# Remove "Open with Claude Code" and "Resume Chat with Claude"
# Finder Quick Actions (macOS)
# ============================================================
# Usage: bash uninstall.sh
# ============================================================

set -euo pipefail

echo "Removing Claude Code Quick Actions..."

rm -rf ~/Library/Services/"Open with Claude Code.workflow"
echo "  Removed: Open with Claude Code.workflow"

rm -rf ~/Library/Services/"Resume Chat with Claude.workflow"
echo "  Removed: Resume Chat with Claude.workflow"

echo
echo "Done! The Quick Actions have been removed."
