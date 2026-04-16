#!/bin/bash
# release.sh — Package, create GitHub Release, and update Homebrew tap
# Usage: bash scripts/release.sh <version>
# Example: bash scripts/release.sh 3.1
set -euo pipefail

VERSION="${1:?Usage: release.sh <version>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

TAP_REPO="MashellHan/homebrew-tap"
CASK_FILE="Casks/eye-guard.rb"

# 1. Package
echo "==> Packaging v${VERSION}..."
bash scripts/package.sh

SHA=$(shasum -a 256 EyeGuard.dmg | awk '{print $1}')

# 2. Create GitHub Release
echo "==> Creating GitHub Release v${VERSION}..."
gh release create "v${VERSION}" EyeGuard.dmg \
  --title "EyeGuard v${VERSION}" \
  --notes "EyeGuard v${VERSION}

Install:
\`\`\`bash
brew tap MashellHan/tap && brew install --cask eye-guard
\`\`\`"

# 3. Update Homebrew tap
echo "==> Updating Homebrew tap..."
TMPDIR=$(mktemp -d)
git clone "https://github.com/${TAP_REPO}.git" "$TMPDIR/tap" --depth 1
cd "$TMPDIR/tap"

cat > "$CASK_FILE" <<RUBY
cask "eye-guard" do
  version "${VERSION}"
  sha256 "${SHA}"

  url "https://github.com/MashellHan/eye-guard/releases/download/v#{version}/EyeGuard.dmg"
  name "EyeGuard"
  desc "Medical-grade eye health guardian for macOS with 20-20-20 rule reminders"
  homepage "https://github.com/MashellHan/eye-guard"

  depends_on macos: ">= :sonoma"

  app "EyeGuard.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/EyeGuard.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.eyeguard.app.plist",
  ]
end
RUBY

git add -A
git commit -m "chore: bump eye-guard to v${VERSION}"
git push

rm -rf "$TMPDIR"

echo ""
echo "✅ Released v${VERSION}"
echo "   Install: brew tap MashellHan/tap && brew install --cask eye-guard"
