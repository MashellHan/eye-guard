# Feature Design: ESC 键退出弹窗

**Date:** 2026-04-16
**Status:** ✅ Done (implemented in `4d047c1`)
**Priority:** P0 (体验基础)
**Effort:** XS

---

## 需求

所有弹窗/覆盖层支持按 ESC 键退出。

## 影响范围

| View | 当前退出方式 | ESC 行为 |
|------|-------------|---------|
| `BreakOverlayView` | Skip 按钮 | 调用 `onSkipped()` + `onDismiss()` |
| `FullScreenOverlayView` | 「跳过休息」按钮 | 调用 `onPostponed()` |
| `ExerciseSessionView` | ✕ 按钮 | 调用 `onSkip()` |
| `PreferencesView` | 窗口关闭 | 原生支持，无需修改 |
| `DashboardView` | 窗口关闭 | 原生支持，无需修改 |

## Implementation

```swift
// 方案：.onExitCommand（macOS 原生 ESC 处理）

// BreakOverlayView
.onExitCommand {
    skipBreak()
}

// FullScreenOverlayView
.onExitCommand {
    stopTimer()
    onPostponed()
}

// ExerciseSessionView
.onExitCommand {
    onSkip()
}
```

注意：`mandatory` DismissPolicy 下应**忽略 ESC**（强制休息不可跳过）：

```swift
// FullScreenOverlayView
.onExitCommand {
    guard case .mandatory = dismissPolicy else {
        // mandatory 模式不允许 ESC 退出
    }
    stopTimer()
    onPostponed()
}
```

## 变更文件

| File | Change |
|------|--------|
| `Sources/Notifications/BreakOverlayView.swift` | 添加 `.onExitCommand` |
| `Sources/Notifications/FullScreenOverlayView.swift` | 添加 `.onExitCommand`（mandatory 除外） |
| `Sources/Exercises/ExerciseSessionView.swift` | 添加 `.onExitCommand` |

## Acceptance Criteria

- [ ] 非 mandatory 弹窗中按 ESC 可退出
- [ ] mandatory 模式按 ESC 无反应
- [ ] ESC 退出行为与点击 Skip/跳过 按钮一致
- [ ] 测试覆盖 ESC 退出路径
