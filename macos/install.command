#!/bin/bash
# Double-click this file to install Claude Code context menu entries on macOS.
cd "$(dirname "$0")"
bash install.sh
echo
echo "You can close this window now."
read -n 1 -s -r -p "Press any key to close..."
