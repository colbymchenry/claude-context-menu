#!/bin/bash
# ============================================================
# Install "Open with Claude Code" and "Resume Chat with Claude"
# Finder Quick Actions (macOS)
# ============================================================
# Creates two Automator Quick Action workflows in ~/Library/Services/
# that appear in Finder's right-click → Quick Actions menu.
#
# Note: macOS Quick Actions render icons as white monochrome templates
# only — this is an Apple design limitation. Entries show by name only.
#
# Usage: bash install.sh
# ============================================================

set -euo pipefail

SERVICES_DIR="$HOME/Library/Services"

create_workflow() {
    local name="$1"
    local command="$2"
    local workflow_dir="$SERVICES_DIR/${name}.workflow"
    local contents_dir="$workflow_dir/Contents"

    # Remove existing workflow if present
    rm -rf "$workflow_dir"
    mkdir -p "$contents_dir"

    # --- Info.plist ---
    cat > "$contents_dir/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>WORKFLOW_NAME</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
        </dict>
    </array>
</dict>
</plist>
PLIST
    # Substitute the workflow name
    sed -i '' "s/WORKFLOW_NAME/${name}/" "$contents_dir/Info.plist"

    # --- document.wflow ---
    cat > "$contents_dir/document.wflow" << WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AMApplicationBuild</key>
    <string>523</string>
    <key>AMApplicationVersion</key>
    <string>2.10</string>
    <key>AMWorkflowSchemeVersion</key>
    <string>2.00</string>
    <key>actions</key>
    <array>
        <dict>
            <key>action</key>
            <dict>
                <key>AMAccepts</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Optional</key>
                    <true/>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                        <string>com.apple.cocoa.attributed-string</string>
                        <string>public.file-url</string>
                        <string>public.folder</string>
                    </array>
                </dict>
                <key>AMActionVersion</key>
                <string>1.0.2</string>
                <key>AMApplication</key>
                <array>
                    <string>Automator</string>
                </array>
                <key>AMBundle identifier</key>
                <string>com.apple.RunShellScript-Action</string>
                <key>AMCategory</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>AMIconName</key>
                <string>TerminalAction</string>
                <key>AMKeywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                    <string>Command</string>
                    <string>Run</string>
                    <string>Unix</string>
                </array>
                <key>AMName</key>
                <string>Run Shell Script</string>
                <key>AMProvides</key>
                <dict>
                    <key>Container</key>
                    <string>List</string>
                    <key>Types</key>
                    <array>
                        <string>com.apple.cocoa.string</string>
                    </array>
                </dict>
                <key>AMRequiredResources</key>
                <array/>
                <key>ActionBundlePath</key>
                <string>/System/Library/Automator/Run Shell Script.action</string>
                <key>ActionName</key>
                <string>Run Shell Script</string>
                <key>ActionParameters</key>
                <dict>
                    <key>COMMAND_STRING</key>
                    <string>DIR="\$@"
[ -f "\$DIR" ] &amp;&amp; DIR="\$(dirname "\$DIR")"
open -a Terminal "\$DIR"
sleep 0.5
osascript -e "tell application \\"Terminal\\"" \\
          -e "do script \\"cd '\${DIR}' &amp;&amp; ${command}\\" in front window" \\
          -e "end tell"</string>
                    <key>CheckedForUserDefaultShell</key>
                    <true/>
                    <key>inputMethod</key>
                    <integer>1</integer>
                    <key>shell</key>
                    <string>/bin/bash</string>
                    <key>source</key>
                    <string></string>
                </dict>
                <key>BundleIdentifier</key>
                <string>com.apple.RunShellScript-Action</string>
                <key>CFBundleVersion</key>
                <string>1.0.2</string>
                <key>CanShowSelectedItemsWhenRun</key>
                <false/>
                <key>CanShowWhenRun</key>
                <true/>
                <key>Category</key>
                <array>
                    <string>AMCategoryUtilities</string>
                </array>
                <key>Class Name</key>
                <string>RunShellScriptAction</string>
                <key>InputUUID</key>
                <string>$(uuidgen || echo "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")</string>
                <key>Keywords</key>
                <array>
                    <string>Shell</string>
                    <string>Script</string>
                    <string>Command</string>
                    <string>Run</string>
                    <string>Unix</string>
                </array>
                <key>Name</key>
                <string>Run Shell Script</string>
                <key>OutputUUID</key>
                <string>$(uuidgen || echo "B2C3D4E5-F6A7-8901-BCDE-F12345678901")</string>
                <key>ShowWhenRun</key>
                <false/>
            </dict>
        </dict>
    </array>
    <key>connectors</key>
    <dict/>
    <key>workflowMetaData</key>
    <dict>
        <key>serviceInputTypeIdentifier</key>
        <string>com.apple.Automator.fileSystemObject</string>
        <key>serviceApplicationGroupName</key>
        <string>Finder</string>
        <key>workflowTypeIdentifier</key>
        <string>com.apple.Automator.servicesMenu</string>
    </dict>
</dict>
</plist>
WFLOW

    echo "  Installed: ${name}.workflow"
}

echo "Installing Claude Code Quick Actions..."
echo

mkdir -p "$SERVICES_DIR"

create_workflow "Open with Claude Code" "claude"
create_workflow "Resume Chat with Claude" "claude --resume"

echo
echo "Done! The Quick Actions should now appear in Finder's"
echo "right-click → Quick Actions menu."
echo
echo "If they don't appear immediately, try:"
echo "  1. Open Automator → any workflow → close it (refreshes the cache)"
echo "  2. Or log out and log back in"
