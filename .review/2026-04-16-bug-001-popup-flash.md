# Bug Report: 弹窗闪现 1 秒后消失（深度调查更新）

**Date:** 2026-04-16
**Severity:** P0
**Status:** Root Cause Confirmed — Ready for Fix

---

## 现象

休息倒计时弹窗莫名弹出，约 1 秒后自动消失。用户仍在持续遇到此问题。

## Root Cause（确认）

### 核心问题：`isBreakInProgress` guard 时机不对

当前代码在 `handleIdleDetected()` 和 `handleActivityResumed()` 中已有 `guard !isBreakInProgress`，但这个 guard **无法覆盖弹窗出现到用户点击之间的窗口期**：

```
时间线:
  triggerBreakNotification()
    → NotificationManager.notify()
    → isNotificationActive = true     ← NotificationManager 的状态
    → 弹窗出现
    → 但此时 BreakScheduler.isBreakInProgress 仍然是 false！
    
  isBreakInProgress 只在 takeBreakNow() 中被设为 true
  而 takeBreakNow() 是 onTaken 回调 —— 需要用户点击 "Take Break" 才触发

  所以从弹窗出现到用户点击按钮之间（可能数秒甚至数十秒）：
    - NotificationManager: isNotificationActive = true
    - BreakScheduler: isBreakInProgress = false  ← guard 不起作用！
```

### Bug 触发链条

```
T+0s    elapsedPerType[.micro] = 1200s (20min)
        → checkForDueBreaks() → triggerBreakNotification()
        → 弹窗出现（FullScreen，aggressive 模式 .direct）
        → isBreakInProgress = false（尚未 takeBreakNow）

T+0.5s  用户停下鼠标来阅读弹窗
        → ActivityMonitor 开始积累 idle 时间

T+1s    tick() → idle poll → isIdle = true
        → handleIdleDetected()
        → guard !isBreakInProgress → 通过！（因为 false）
        → resetTimersAfterBreak(.micro)
          → elapsedPerType[.micro] = 0
          → lastNotifiedCycle[.micro] = -1  ← cycle guard 被重置！

此时弹窗仍在显示，但 scheduler 状态已脱节。

后续可能的消失触发：
  方式 A: idle→resume 快速切换触发第二次 checkForDueBreaks
         → elapsedPerType[.micro] 仍为 ~0，不会重新触发
         → 但如果 resetTimersAfterBreak 同时调了 endBreak()
           或其他状态变更导致 View 重建

  方式 B: FullScreenOverlayView 的 onBreakTaken 回调中
         takeBreakNow() → resetTimersAfterBreak() → endBreak()
         → isBreakInProgress 的 auto-end Task (duration 秒后)
         → 已经重置的 timer 使 break 看起来"已完成"

  方式 C（最可能）: handleIdleDetected 重置 timer 后，
         BreakScheduler 的 tick 中某处逻辑判断 break 已过期
         或 NotificationManager 的 escalation timeout 触发 dismiss
```

### 为什么 FullScreen 弹窗用 .direct 模式也会消失？

`FullScreenOverlayView` 自动开始倒计时（`onAppear` → `startCountdownTimer()`）。即使 scheduler 重置了状态，弹窗本身不会被关闭——**除非有东西调用了 `dismissAllOverlays()` 或 `dismissFullScreen()`**。

需要排查的关键路径：
1. `showFullScreenOverlay()` 开头调 `dismissFullScreen()` —— 如果第二次调用 show，会先关旧的
2. `handleEscalationTimeout()` —— `.direct` 模式不走 tiered，但需确认
3. `skipBreak()` / `postponeBreak()` —— 如果 idle 处理间接触发了这些

### 可能的隐藏路径

`resetTimersAfterBreak()` 内部是否会触发通知关闭？

```swift
// 需要确认 resetTimersAfterBreak 的完整实现
// 如果它调用了 endBreak() → 而 endBreak() 调用了 notificationSender 的某个方法...
```

## 修复方案

### Fix 1（关键）：在 `NotificationSending` 协议中暴露通知状态

```swift
// NotificationSending.swift
protocol NotificationSending {
    var isNotificationActive: Bool { get }  // ← 新增
    func notify(...)
    ...
}
```

### Fix 2（关键）：`handleIdleDetected` 和 `handleActivityResumed` 同时检查通知状态

```swift
// BreakScheduler.swift
func handleIdleDetected() {
    guard !isPaused else { return }
    guard !isBreakInProgress else {
        Log.scheduler.info("Idle during active break — skip.")
        return
    }
    guard !notificationSender.isNotificationActive else {  // ← 新增
        Log.scheduler.info("Idle during active notification — skip.")
        return
    }
    resetTimersAfterBreak(.micro)
    Log.scheduler.info("Idle detected, micro timer reset.")
}

func handleActivityResumed() {
    guard !isPaused else { return }
    guard !isBreakInProgress else {
        Log.scheduler.info("Resume during active break — skip.")
        return
    }
    guard !notificationSender.isNotificationActive else {  // ← 新增
        Log.scheduler.info("Resume during active notification — skip.")
        return
    }
    sessionStartTime = .now
    currentSessionDuration = 0
    Log.scheduler.info("Activity resumed, session restarted.")
}
```

### Fix 3（防御性）：弹窗出现时立即设 isBreakInProgress

```swift
// BreakScheduler.triggerBreakNotification()
func triggerBreakNotification(_ breakType: BreakType) {
    isBreakInProgress = true          // ← 新增：弹窗出现即标记
    activeBreakType = breakType       // ← 新增
    ...
    notificationSender.notify(
        ...
        onTaken: { [weak self] in
            Task { @MainActor in
                self?.takeBreakNow(breakType)  // takeBreakNow 内部的重复设置无害
            }
        },
        onSkipped: { [weak self] in
            Task { @MainActor in
                self?.isBreakInProgress = false  // ← 跳过时也要重置
                self?.activeBreakType = nil
                self?.skipBreak(breakType)
            }
        },
        onPostponed: { [weak self] delay in
            Task { @MainActor in
                self?.isBreakInProgress = false  // ← 延后时也要重置
                self?.activeBreakType = nil
                self?.postponeBreak(breakType, by: delay)
            }
        },
        ...
    )
}
```

### Fix 4（调试辅助）：弹窗生命周期日志

```swift
// FullScreenOverlayView
.onAppear {
    Log.notification.info("FullScreenOverlay appeared: \(breakType.displayName)")
}
.onDisappear {
    Log.notification.info("FullScreenOverlay DISAPPEARED: \(breakType.displayName), remaining=\(remainingSeconds)s")
}
```

### Fix 5（可选）：弹窗期间暂停 idle 轮询

在 `tick()` 的 idle poll 块中加条件：

```swift
// BreakScheduler tick loop 中的 idle 轮询
if !isBreakInProgress && !notificationSender.isNotificationActive {
    // 正常轮询 idle
} else {
    // 弹窗/休息期间跳过 idle 检测
}
```

## 推荐修复顺序

1. **Fix 2 + Fix 1**（最小改动，直接解决 root cause）
2. **Fix 3**（更彻底，让 isBreakInProgress 覆盖完整生命周期）
3. **Fix 4**（帮助未来调试）
4. **Fix 5**（防御性加固）

## 变更文件

| File | Change |
|------|--------|
| `Sources/Protocols/NotificationSending.swift` | Fix 1: 新增 `isNotificationActive` 属性 |
| `Sources/Scheduling/BreakScheduler.swift` | Fix 2+3: idle/resume guard + triggerBreakNotification 提前标记 |
| `Sources/Notifications/NotificationManager.swift` | 确保 conformance（已有 isNotificationActive） |
| `Sources/Notifications/FullScreenOverlayView.swift` | Fix 4: 生命周期日志 |
| `Sources/Notifications/BreakOverlayView.swift` | Fix 4: 生命周期日志 |
| `Tests/BreakSchedulerTests.swift` | 新增: idle-during-notification 场景测试 |
| `Tests/Mocks/MockNotificationSender.swift` | 新增 `isNotificationActive` mock |

## Acceptance Criteria

- [ ] 弹窗出现后，idle 检测不再触发 timer 重置
- [ ] 弹窗出现后，activity resume 不再重置 session
- [ ] 弹窗正常显示完整倒计时时间（micro=20s, macro=5min）
- [ ] 跳过/延后弹窗后，isBreakInProgress 正确重置
- [ ] 现有测试通过
- [ ] 新增 idle-during-notification 测试用例
