#!/bin/bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
ICONS_DIR="$SCRIPT_DIR/../../icons"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/ClaudeCodeMenu.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_PATH="$BUILD_DIR/ClaudeCodeMenu.dmg"
APP_NAME="Claude Code Menu"

# Signing identity — matches your Electron apps
SIGNING_IDENTITY="Developer ID Application: RETAILER LLC (C7G662Y5QT)"
TEAM_ID="C7G662Y5QT"

# ─── Load Apple credentials ─────────────────────────────────────────────────
# Same pattern as cmem — source from .apple-credentials file
# Checks project dir first, then home dir as fallback
APPLE_CREDENTIALS=""
if [ -f "$PROJECT_DIR/.apple-credentials" ]; then
    APPLE_CREDENTIALS="$PROJECT_DIR/.apple-credentials"
elif [ -f "$HOME/.apple-credentials" ]; then
    APPLE_CREDENTIALS="$HOME/.apple-credentials"
fi

if [ -n "$APPLE_CREDENTIALS" ]; then
    source "$APPLE_CREDENTIALS"
    echo "==> Loaded credentials from $APPLE_CREDENTIALS"
else
    echo ""
    echo "ERROR: No .apple-credentials file found."
    echo ""
    echo "Create one at either location:"
    echo "  $PROJECT_DIR/.apple-credentials"
    echo "  $HOME/.apple-credentials"
    echo ""
    echo "Contents:"
    echo '  export APPLE_ID="your-apple-id@email.com"'
    echo '  export APPLE_PASSWORD="your-app-specific-password"'
    echo '  export APPLE_TEAM_ID="C7G662Y5QT"'
    echo ""
    echo "Get an app-specific password at: https://appleid.apple.com/account/manage"
    echo "  Sign in → App-Specific Passwords → Generate"
    echo ""
    exit 1
fi

# Resolve credential env vars
APPLE_ID="${APPLE_ID:?APPLE_ID not set in .apple-credentials}"
APPLE_PASSWORD="${APPLE_PASSWORD:?APPLE_PASSWORD not set in .apple-credentials}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-$TEAM_ID}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
info()  { echo "==> $*"; }
warn()  { echo "⚠️  $*" >&2; }
error() { echo "❌ $*" >&2; exit 1; }

generate_icns() {
    local src="$1" dest="$2"
    local iconset_dir="${dest%.icns}.iconset"
    mkdir -p "$iconset_dir"
    sips -z 16   16   "$src" --out "$iconset_dir/icon_16x16.png"       >/dev/null 2>&1
    sips -z 32   32   "$src" --out "$iconset_dir/icon_16x16@2x.png"    >/dev/null 2>&1
    sips -z 32   32   "$src" --out "$iconset_dir/icon_32x32.png"       >/dev/null 2>&1
    sips -z 64   64   "$src" --out "$iconset_dir/icon_32x32@2x.png"    >/dev/null 2>&1
    sips -z 128  128  "$src" --out "$iconset_dir/icon_128x128.png"     >/dev/null 2>&1
    sips -z 256  256  "$src" --out "$iconset_dir/icon_128x128@2x.png"  >/dev/null 2>&1
    sips -z 256  256  "$src" --out "$iconset_dir/icon_256x256.png"     >/dev/null 2>&1
    sips -z 512  512  "$src" --out "$iconset_dir/icon_256x256@2x.png"  >/dev/null 2>&1
    sips -z 512  512  "$src" --out "$iconset_dir/icon_512x512.png"     >/dev/null 2>&1
    sips -z 1024 1024 "$src" --out "$iconset_dir/icon_512x512@2x.png"  >/dev/null 2>&1
    iconutil -c icns "$iconset_dir" -o "$dest"
    rm -rf "$iconset_dir"
}

# ─── Prerequisites ───────────────────────────────────────────────────────────
info "Checking prerequisites..."

if ! command -v xcodegen &>/dev/null; then
    info "Installing xcodegen via Homebrew..."
    brew install xcodegen
fi

# Verify full Xcode is selected (not just Command Line Tools)
XCODE_PATH="$(xcode-select -p 2>/dev/null || true)"
if [[ "$XCODE_PATH" != *"Xcode.app"* ]]; then
    error "Full Xcode is required (FinderSync framework is not in Command Line Tools).
    Install Xcode from the App Store, then run:
      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

# Check if signing identity exists in keychain
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "$TEAM_ID"; then
    error "Developer ID certificate for $TEAM_ID not found in keychain.
    Import your certificate or check Keychain Access."
fi
info "Found Developer ID certificate: $SIGNING_IDENTITY"

if ! command -v create-dmg &>/dev/null; then
    info "Installing create-dmg via Homebrew..."
    brew install create-dmg
fi

# ─── Step 1: Generate icon assets ───────────────────────────────────────────
info "Generating icon assets..."

ICON_SOURCE="$ICONS_DIR/claude-icon.png"
if [ ! -f "$ICON_SOURCE" ]; then
    error "Icon source not found: $ICON_SOURCE"
fi

# App icon catalog
APP_ICON_DIR="$PROJECT_DIR/ClaudeCodeMenu/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 64 128 256 512 1024; do
    sips -z $size $size "$ICON_SOURCE" --out "$APP_ICON_DIR/icon_${size}x${size}.png" >/dev/null 2>&1 || true
done
cp "$APP_ICON_DIR/icon_32x32.png"     "$APP_ICON_DIR/icon_16x16@2x.png"
cp "$APP_ICON_DIR/icon_64x64.png"     "$APP_ICON_DIR/icon_32x32@2x.png"
cp "$APP_ICON_DIR/icon_256x256.png"   "$APP_ICON_DIR/icon_128x128@2x.png"
cp "$APP_ICON_DIR/icon_512x512.png"   "$APP_ICON_DIR/icon_256x256@2x.png"
cp "$APP_ICON_DIR/icon_1024x1024.png" "$APP_ICON_DIR/icon_512x512@2x.png"
rm -f "$APP_ICON_DIR/icon_64x64.png" "$APP_ICON_DIR/icon_1024x1024.png"

# Extension context menu icon
EXT_ICON_DIR="$PROJECT_DIR/FinderExtension/Assets.xcassets/ClaudeIcon.imageset"
sips -z 16 16 "$ICON_SOURCE" --out "$EXT_ICON_DIR/claude-icon.png"    >/dev/null 2>&1
sips -z 32 32 "$ICON_SOURCE" --out "$EXT_ICON_DIR/claude-icon@2x.png" >/dev/null 2>&1
sips -z 48 48 "$ICON_SOURCE" --out "$EXT_ICON_DIR/claude-icon@3x.png" >/dev/null 2>&1

info "Icons generated."

# ─── Step 2: Compile AppleScripts ────────────────────────────────────────────
info "Compiling AppleScripts..."

SCRIPTS_SRC="$PROJECT_DIR/scripts"
SCRIPTS_DEST="$PROJECT_DIR/ClaudeCodeMenu/Resources"
mkdir -p "$SCRIPTS_DEST"

for script in "$SCRIPTS_SRC"/*.applescript; do
    name="$(basename "$script" .applescript)"
    osacompile -o "$SCRIPTS_DEST/$name.scpt" "$script"
    info "  Compiled $name.scpt"
done

# ─── Step 3: Generate Xcode project ─────────────────────────────────────────
info "Generating Xcode project..."
cd "$PROJECT_DIR"
xcodegen generate

# ─── Step 4: Build + Sign ───────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Generate .icns for DMG
ICNS_PATH="$BUILD_DIR/AppIcon.icns"
generate_icns "$ICON_SOURCE" "$ICNS_PATH"

info "Archiving..."
LOG="$BUILD_DIR/xcodebuild.log"

xcodebuild archive \
    -project ClaudeCodeMenu.xcodeproj \
    -scheme ClaudeCodeMenu \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    ONLY_ACTIVE_ARCH=NO \
    2>&1 | tee "$LOG" | grep -E "ARCHIVE|error:" || true

if ! grep -q "ARCHIVE SUCCEEDED" "$LOG"; then
    echo ""
    echo "Build failed. Last 20 lines:"
    tail -20 "$LOG"
    exit 1
fi

info "Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$PROJECT_DIR/exportOptions.plist" \
    2>&1 | tee -a "$LOG" | grep -E "EXPORT|error:" || true

if ! grep -q "EXPORT SUCCEEDED" "$LOG"; then
    echo ""
    echo "Export failed. Last 20 lines:"
    tail -20 "$LOG"
    exit 1
fi

APP_PATH="$EXPORT_DIR/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    error "Build failed: app not found at $APP_PATH"
fi

info "App built: $APP_PATH"

# Verify code signature
info "Verifying code signature..."
codesign --verify --deep --strict "$APP_PATH" 2>&1
info "Signature valid."

# ─── Step 5: Notarize ───────────────────────────────────────────────────────
info "Notarizing (this takes 1-5 minutes)..."

NOTARIZE_ZIP="$BUILD_DIR/ClaudeCodeMenu-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$NOTARIZE_ZIP"

xcrun notarytool submit "$NOTARIZE_ZIP" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

info "Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

rm -f "$NOTARIZE_ZIP"
info "Notarization complete. App will pass Gatekeeper on any Mac."

# ─── Step 6: Create DMG ─────────────────────────────────────────────────────
info "Creating DMG..."

rm -f "$DMG_PATH"

create-dmg \
    --volname "$APP_NAME" \
    --volicon "$ICNS_PATH" \
    --window-size 660 400 \
    --icon-size 80 \
    --icon "$APP_NAME.app" 180 170 \
    --app-drop-link 480 170 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH" \
    || true  # create-dmg exits non-zero when setting custom icon fails, which is cosmetic

if [ ! -f "$DMG_PATH" ]; then
    error "DMG creation failed"
fi

# Set custom icon on the DMG file itself
if command -v fileicon &>/dev/null; then
    fileicon set "$DMG_PATH" "$ICNS_PATH" || true
fi

info "DMG created: $DMG_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done! To install:"
echo ""
echo "  1. Open $DMG_PATH"
echo "  2. Drag 'Claude Code Menu' to Applications"
echo "  3. Launch it — scripts auto-install"
echo "  4. Enable in System Settings → Extensions → Added Extensions"
echo "  5. Right-click any folder in Finder — Claude entries appear"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
