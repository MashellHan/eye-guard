---
name: ui-snapshot
description: Capture EyeGuard window screenshots for a given UI state. Wraps the screencapture + DEBUG_UI_STATE flow. Use during testing or to grab a single state for inspection.
user-invocable: true
allowed-tools: Bash
argument-hint: <ui-state> [output-dir]
---

抓取 EyeGuard 在指定 UI 状态下的窗口截图。

参数：
- $1 = ui-state（必填，见 `docs/conventions/test-matrix.md` 里的状态名）
- $2 = output-dir（可选，默认 `.agent_workspace/snapshots/`）

!`STATE="${1:?usage: /ui-snapshot <state> [out]}"; OUT="${2:-.agent_workspace/snapshots}"; mkdir -p "$OUT"; pkill -f EyeGuard.app 2>/dev/null; sleep 1; DEBUG_UI_STATE="$STATE" open /Users/mengxionghan/workspace/eye-guard/EyeGuard.app; sleep 3; PID=$(pgrep -f "EyeGuard.app/Contents/MacOS/EyeGuard"); WIDS=$(osascript -e "tell application \"System Events\" to get id of windows of process \"EyeGuard\"" 2>/dev/null | tr ',' '\n' | tr -d ' '); echo "PID=$PID windows=$WIDS"; for wid in $WIDS; do screencapture -o -l$wid "$OUT/$STATE-w$wid.png" 2>/dev/null && echo "saved $OUT/$STATE-w$wid.png"; done; ls -la "$OUT/" | grep "$STATE"`

抓完用 Read 工具读截图分析。
