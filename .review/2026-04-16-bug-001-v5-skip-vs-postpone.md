# Bug Report: "跳过休息"按钮实际调用 postpone 而非 skip (BUG-POPUP-001 v5)

**Date:** 2026-04-16
**Severity:** P0
**Status:** Root Cause Confirmed

---

## 现象

用户在 micro break（20 秒）弹窗上点击"跳过休息"后，不到 5 分钟又弹出休息提醒。Menu bar 显示的"距下次休息"远不到 20 分钟。

## 根因

**FullScreenOverlayView 中的"跳过休息"按钮调用的是 `onPostponed()`，而不是概念上应该调用的 skip 逻辑。**

### 调用链

```
用户点击"跳过休息"
→ FullScreenOverlayView: onPostponed()
→ NotificationManager.postponeBreak(breakType:)
  → callback?(EyeGuardConstants.postponeDelay)  // delay = 5 * 60 = 300s
→ BreakScheduler.postponeBreak(.micro, by: 300)
  → elapsedPerType[.micro] = max(0, 1200 - 300) = 900
  → lastNotifiedCycle[.micro] = Int(900 / 1200) = 0
```

**结果：** elapsed 从 900 开始累加，300 秒（5 分钟）后到 1200 → 重新触发！

### 对比 skip 的行为

```
如果调用 skipBreak:
→ BreakScheduler.skipBreak(.micro)
  → recordBreak(type: .micro, wasTaken: false)
  → resetTimersAfterBreak(.micro)
    → elapsedPerType[.micro] = 0
    → lastNotifiedCycle[.micro] = -1
```

**结果：** elapsed 从 0 开始累加，需要 1200 秒（20 分钟）才会重新触发。

### 为什么这是 BUG-POPUP-001 的真正根因

之前 4 轮修复都在解决 race condition 和 guard 问题，但用户描述的"频繁弹窗"核心原因其实是：**"跳过"实际做的是"延后 5 分钟"**。

用户期望：点"跳过休息" → 20 分钟后才再提醒
实际行为：点"跳过休息" → 5 分钟后再提醒

## ESC 退出的同样问题

`FullScreenOverlayView.onExitCommand` 中按 ESC 也调用 `onPostponed()`：

```swift
.onExitCommand {
    guard case .mandatory = dismissPolicy else {
        stopTimer()
        onPostponed()  // ← ESC 也是 postpone，不是 skip
        return
    }
    shakeTrigger = true
}
```

**这意味着 ESC 退出弹窗 = 5 分钟后重来。**

## BreakOverlayView（浮动弹窗）也有同样问题

浮动弹窗中同时有 `onSkipped` 和 `onPostponed`，在 NotificationManager.showTier(.floating) 中：
- `onSkipped` → 调用 BreakScheduler 的 `skipBreak()` ✅ 正确重置
- `onPostponed` → 调用 BreakScheduler 的 `postponeBreak()` → 5 分钟后重来

但 FullScreenOverlayView **没有 `onSkipped` 回调**，只有 `onPostponed`。所以全屏弹窗上没法真正"跳过"。

## 修复方案

### Fix 1（必须）：FullScreenOverlayView "跳过休息"改为调用 skip 逻辑

**方案 A（最小改动）：** 给 FullScreenOverlayView 增加 `onSkipped` 回调，"跳过休息"按钮调用它

```swift
// FullScreenOverlayView.swift
let onSkipped: @Sendable () -> Void  // 新增

// "跳过休息"按钮
Button {
    stopTimer()
    onSkipped()  // 改为 skip，不是 postpone
} label: {
    Text("跳过休息")
}
```

**方案 B（语义对齐）：** "跳过休息"按钮保持调用 `onPostponed`，但把 postponeDelay 改为等于 interval（20 分钟），使"延后"等价于"跳过后重新计时"。不推荐——语义混乱。

### Fix 2（推荐）：ESC 退出也改为 skip

```swift
.onExitCommand {
    guard case .mandatory = dismissPolicy else {
        stopTimer()
        onSkipped()  // ESC = skip，不是 postpone
        return
    }
    shakeTrigger = true
}
```

### Fix 3（可选）：保留"延后"作为独立功能

如果产品上希望同时提供"跳过"和"延后"：
- "跳过休息" → `onSkipped()` → 重置到 0，20 分钟后再提醒
- "5 分钟后提醒" → `onPostponed()` → 5 分钟后再提醒

## 变更文件

| File | Change |
|------|--------|
| `Sources/Notifications/FullScreenOverlayView.swift` | 增加 `onSkipped` 回调，"跳过休息"和 ESC 改为调用它 |
| `Sources/Notifications/OverlayWindow.swift` | `showFullScreenOverlay` 增加 `onSkipped` 参数 |
| `Sources/Notifications/NotificationManager.swift` | `showTier(.fullScreen)` 传入 `onSkipped` |
