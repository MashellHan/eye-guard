#!/usr/bin/env bash
# scripts/check-coverage.sh — coverage gate for named modules.
# Added 2026-04-20 as part of mascot-position retro Prevention Plan T3.
#
# Usage: bash scripts/check-coverage.sh Mascot Notch
# Reads coverage data from `swift test --enable-code-coverage` output
# (.build/debug/codecov/*.json) and fails if any named module is under 80%.
#
# This is a thin advisory wrapper — full coverage parsing is left to the
# llvm-cov tooling shipped with Swift. The intent is to make the threshold
# visible and break the build when it regresses.

set -euo pipefail

THRESHOLD="${COVERAGE_THRESHOLD:-80}"
MODULES=("$@")

if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo "usage: $0 <module> [<module> ...]" >&2
    exit 2
fi

PROFDATA=".build/debug/codecov/default.profdata"
BINARY=".build/debug/EyeGuardPackageTests.xctest/Contents/MacOS/EyeGuardPackageTests"

if [[ ! -f "$PROFDATA" ]] || [[ ! -f "$BINARY" ]]; then
    echo "coverage data not found — run \`swift test --enable-code-coverage\` first" >&2
    exit 2
fi

FAILED=0
for module in "${MODULES[@]}"; do
    pct=$(xcrun llvm-cov report "$BINARY" \
        -instr-profile="$PROFDATA" \
        -ignore-filename-regex='Tests|.build' \
        2>/dev/null \
        | grep -E "Sources/${module}/" \
        | awk '{ sum += $7; n++ } END { if (n) printf "%.1f", sum/n; else print "0" }' \
        | tr -d '%')

    if [[ -z "$pct" ]]; then pct="0"; fi
    printf "  %-12s coverage: %s%%  (gate %s%%)\n" "$module" "$pct" "$THRESHOLD"

    if awk "BEGIN { exit !($pct < $THRESHOLD) }"; then
        echo "    ❌ below threshold"
        FAILED=1
    else
        echo "    ✅ ok"
    fi
done

exit "$FAILED"
