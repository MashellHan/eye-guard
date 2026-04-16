#!/bin/bash
# package.sh — Build EyeGuard.app and create DMG
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo "==> Building app..."
bash scripts/build-app.sh

echo "==> Signing (ad-hoc)..."
codesign --sign - --force --deep EyeGuard.app

echo "==> Creating DMG..."
hdiutil create -volname "EyeGuard" -srcfolder EyeGuard.app -ov -format UDZO EyeGuard.dmg

SHA=$(shasum -a 256 EyeGuard.dmg | awk '{print $1}')
echo ""
echo "✅ Done: EyeGuard.dmg"
echo "   SHA256: $SHA"
