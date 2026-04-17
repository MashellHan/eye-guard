#!/bin/bash

# EyeGuard Mascot Rename Script
# From: 护眼精灵 (Eye Protection Spirit)
# To:   阿普 (Apu)

PROJECT_DIR="/Users/mengxionghan/.superset/projects/Tmp/eye-guard"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        EyeGuard Mascot Rename - Helper Commands               ║"
echo "║           From: 护眼精灵  →  To: 阿普                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# STEP 1: Verify current state
echo "STEP 1: Verify Current State"
echo "─────────────────────────────────────────────────────────────────"
echo "Command: grep -r \"护眼精灵\" EyeGuard/"
echo ""
echo "Current occurrences (should be 5):"
cd "$PROJECT_DIR"
grep -r "护眼精灵" EyeGuard/ || echo "(No matches found)"
echo ""
echo ""

# STEP 2: Show the 5 exact locations
echo "STEP 2: The 5 Locations That Need Changes"
echo "─────────────────────────────────────────────────────────────────"
echo ""

echo "Location 1 - MascotStateSync.swift:23 (USER-VISIBLE)"
echo "File: EyeGuard/Sources/Mascot/MascotStateSync.swift"
echo "Before: viewModel.showMessage(\"Hi! 我是护眼精灵 👋\")"
echo "After:  viewModel.showMessage(\"Hi! 我是阿普 👋\")"
echo ""

echo "Location 2 - MascotState.swift:3"
echo "File: EyeGuard/Sources/Mascot/MascotState.swift"
echo "Before: /// Emotional states for the Eye Guard mascot (护眼精灵)."
echo "After:  /// Emotional states for the Eye Guard mascot (阿普)."
echo ""

echo "Location 3 - EyeGuardApp.swift:8"
echo "File: EyeGuard/Sources/App/EyeGuardApp.swift"
echo "Before: /// Launches the floating mascot character (护眼精灵) on screen (v0.9)."
echo "After:  /// Launches the floating mascot character (阿普) on screen (v0.9)."
echo ""

echo "Location 4 - EyeGuardApp.swift:44"
echo "File: EyeGuard/Sources/App/EyeGuardApp.swift"
echo "Before: Log.app.info(\"Mascot character (护眼精灵) launched.\")"
echo "After:  Log.app.info(\"Mascot character (阿普) launched.\")"
echo ""

echo "Location 5 - README.md:27"
echo "File: README.md"
echo "Before: ### Mascot (护眼精灵)"
echo "After:  ### Mascot (阿普)"
echo ""
echo "─────────────────────────────────────────────────────────────────"
echo ""

# STEP 3: Show sed commands for automated replacement
echo "STEP 3: Automated Replacement Commands (OPTIONAL)"
echo "─────────────────────────────────────────────────────────────────"
echo ""
echo "You can use these sed commands to auto-replace (macOS compatible):"
echo ""
echo "# For MascotStateSync.swift"
echo "sed -i '' 's/我是护眼精灵 👋/我是阿普 👋/g' \\
  EyeGuard/Sources/Mascot/MascotStateSync.swift"
echo ""
echo "# For MascotState.swift"
echo "sed -i '' 's/mascot (护眼精灵)/mascot (阿普)/g' \\
  EyeGuard/Sources/Mascot/MascotState.swift"
echo ""
echo "# For EyeGuardApp.swift"
echo "sed -i '' 's/character (护眼精灵)/character (阿普)/g' \\
  EyeGuard/Sources/App/EyeGuardApp.swift"
echo ""
echo "# For README.md"
echo "sed -i '' 's/Mascot (护眼精灵)/Mascot (阿普)/g' README.md"
echo ""
echo "─────────────────────────────────────────────────────────────────"
echo ""

# STEP 4: Verification commands
echo "STEP 4: Verification Commands (After Making Changes)"
echo "─────────────────────────────────────────────────────────────────"
echo ""
echo "# Verify old name is completely gone"
echo "$ grep -r \"护眼精灵\" EyeGuard/"
echo "  (Should return: No matches)"
echo ""
echo "# Verify new name appears in 5 locations"
echo "$ grep -r \"阿普\" EyeGuard/"
echo "  (Should return: 5 results)"
echo ""
echo "# Build test"
echo "$ swift build"
echo "  (Should succeed with no errors)"
echo ""
echo "# Run tests"
echo "$ swift test"
echo "  (Should pass all tests)"
echo ""
echo "─────────────────────────────────────────────────────────────────"
echo ""

echo "✅ Next Steps:"
echo "   1. Edit the 5 files listed above"
echo "   2. Run the verification commands"
echo "   3. Test the application"
echo ""
echo "ℹ️  For detailed information, see:"
echo "   • MASCOT_RENAME_REPORT.md - Full detailed report"
echo "   • MASCOT_RENAME_QUICK_REFERENCE.txt - Quick reference"
echo "   • SEARCH_SUMMARY.md - Comprehensive search results"
echo ""

