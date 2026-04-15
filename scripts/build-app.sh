#!/bin/bash
# build-app.sh — Packages the SPM-built EyeGuard executable into a proper macOS .app bundle.
#
# Usage:
#   bash scripts/build-app.sh
#
# The script:
#   1. Builds the release binary via `swift build -c release`
#   2. Creates EyeGuard.app/Contents/{MacOS,Resources}
#   3. Copies the executable into the bundle
#   4. Generates Info.plist with LSUIElement=true (menu-bar-only app)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="EyeGuard"
BUNDLE_ID="com.eyeguard.app"
VERSION="1.0.0"
BUILD_VERSION="10"
COPYRIGHT="Copyright $(date +%Y) EyeGuard. All rights reserved."

APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building $APP_NAME (release)..."
cd "$PROJECT_DIR"
swift build -c release

# Locate the built executable
EXECUTABLE="$(swift build -c release --show-bin-path)/$APP_NAME"
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Built executable not found at $EXECUTABLE"
    exit 1
fi

echo "==> Creating app bundle at $APP_BUNDLE..."

# Clean previous bundle
rm -rf "$APP_BUNDLE"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXECUTABLE" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Generate Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>${COPYRIGHT}</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>EyeGuard needs to monitor system events for break scheduling.</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

echo "==> App bundle created successfully."
echo "    $APP_BUNDLE"
echo ""
echo "    To run:  open $APP_BUNDLE"
echo "    To kill: pkill -f EyeGuard.app"
