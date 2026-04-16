# Bug Report: BUG-POPUP-001 v4 — 弹窗闪退根因分析

**Date:** 2026-04-16
**Severity:** P0
**Status:** Root Cause Identified — Requires Fix
**Reporter:** Code Review Agent

---

## 现象

休息弹窗出现约 1 秒后消失，周期性重复。v3 的修复（`checkForDueBreaks` guard + `skipBreak` resetTimer）未解决。

## 之前修复回顾

| 轮次 | 修复内容 | 结果 |
|------|----------|------|
| v1 | `handleIdleDetected` guard | ❌ 未解决 |
| v2 | idle poll 加 `isNotificationActive` guard | ❌ 未解决 |
| v3 | `checkForDueBreaks` guard + `skipBreak` resetTimer | ❌ 未解决 |

**结论：触发路径不是 idle 检测，也不是缺少 guard。问题在更深层。**

---

## 根因分析

### 根因 1（HIGH）：嵌套 `Task` 回调链导致 `isNotificationActive = false` 与 timer 重置不原子

**问题核心：** 从弹窗 dismiss 到 timer 重置，经过 3 层嵌套 `Task { @MainActor in }` 调度：

```
Layer 1: OverlayWindow callback
  Task { @MainActor in
    dismissFullScreen()       // fullScreenWindows = [] (立即)
    onTaken()                 // → 进入 Layer 2
  }

Layer 2: NotificationManager.acknowledgeBreak()
  cancelEscalation()
  dismissAllOverlays()
  isNotificationActive = false   // ← 此刻起，checkForDueBreaks guard 放行
  callback?()                    // → 进入 Layer 3

Layer 3: BreakScheduler callback
  Task { @MainActor in
    takeBreakNow(breakType)  // ← resetTimersAfterBreak 在这里！
  }
```

**关键：** Layer 2 中 `isNotificationActive = false` 是同步执行的，但 Layer 3 中 `takeBreakNow()` 被包裹在 **新的 `Task`** 中，会延迟到下一个 run loop 迭代才执行。

**危险窗口：** 在 `isNotificationActive = false`（Layer 2）和 `resetTimersAfterBreak`（Layer 3）之间：

- `isNotificationActive = false` ✓ guard 放行
- `isBreakInProgress = false` ✓ guard 放行
- `elapsedPerType[.micro]` **仍 >= interval**（未重置！）
- `lastNotifiedCycle` **仍为上次值**

如果 Timer tick 在此间隙触发 `checkForDueBreaks()`，并且 `elapsedPerType` 已经越过了下一个 cycle 边界，就会**立刻重新触发通知**。

### 根因 2（HIGH）：通知期间 `elapsedPerType` 持续累加

**`tick()` 函数（line 330-333）：**
```swift
for type in BreakType.allCases {
    guard isBreakTypeEnabled(type) else { continue }
    elapsedPerType[type, default: 0] += max(delta, 0)
}
```

**没有** `isNotificationActive` 或 `isBreakInProgress` 的 guard！通知弹窗显示期间，`elapsedPerType` 每秒仍在 +1。

**影响：**
- micro break 在 T=1200s 触发（cycle 1），弹窗显示
- 弹窗显示 20 秒后 countdown 结束 → dismiss chain
- 此时 `elapsedPerType[.micro] = 1220`
- 在根因 1 的间隙中，tick 执行 `checkForDueBreaks()`
- `currentCycle = Int(1220/1200) = 1`，`lastNotifiedCycle = 1`，`1 != 1` → 不触发

**但如果是 tiered 升级（非 direct）：**
- 系统通知 → 120s → 浮动弹窗 → 300s → timeout
- 总共 420 秒的通知期间，elapsed = 1200 + 420 = 1620
- `Int(1620/1200) = 1`，仍然 cycle 1，不触发

**但如果用户连续 postpone：**
- postpone 后 `elapsedPerType[.micro] = max(0, 1200 - 300) = 900`
- 300s 后重新触发，弹窗显示
- 再次 postpone：`elapsedPerType = max(0, 1200 - 300) = 900`
- 这个循环会一直持续 — **但间隔是 5 分钟（postponeDelay），不是 1 分钟**

### 根因 3（MEDIUM）：`dismissFullScreen()` 后 View Timer 仍在运行

`dismissFullScreen()` 立即清空 `fullScreenWindows = []`，但窗口的 fade-out 动画异步执行 0.3 秒。在这 0.3 秒内：

1. `FullScreenOverlayView` 的 SwiftUI Timer **仍在运行**
2. `onDisappear` 尚未触发（窗口还没关闭）
3. 如果 Timer 在此期间 fire 并到达 0 秒，会调用 `onBreakTaken()`

**如果 `handleEscalationTimeout()` 在 countdown 即将结束时触发，可能导致：**
- handleEscalationTimeout → dismiss + skipBreak
- 同时 Timer fire → onBreakTaken → acknowledgeBreak → takeBreakNow
- 两条路径同时执行，状态混乱

### 根因 4（MEDIUM）：`acknowledgeBreak()` 中 `dismissAllOverlays()` 重复 dismiss

回调链中存在重复 dismiss：

```
OverlayWindow.onBreakTaken:
  dismissFullScreen()          // ← 第一次 dismiss
  onTaken()
    → acknowledgeBreak()
      → dismissAllOverlays()   // ← 第二次 dismiss（no-op，但语义冗余）
      → isNotificationActive = false
      → callback()             // → takeBreakNow (in new Task)
```

虽然第二次 dismiss 是 no-op，但增加了逻辑复杂度和出错概率。

---

## 最可能的 "每分钟闪退" 场景重建

综合根因 1 + 2，最可能的场景：

```
T=0:     用户开始使用
T=1200:  micro break 触发 → 弹窗出现
T=1200:  checkForDueBreaks: lastNotifiedCycle[.micro] = 1
T=1200-1220: 弹窗显示 20 秒
T=1220:  countdown 到 0 → onBreakTaken callback chain 开始
T=1220:  Layer 1: dismissFullScreen() → fullScreenWindows = []
T=1220:  Layer 2: acknowledgeBreak() → isNotificationActive = false
         ⚠️ 此刻 Timer tick 可能在 Layer 3 之前 fire
T=1220:  tick(): elapsedPerType[.micro] += 1 → 1221
         checkForDueBreaks(): guards 通过！
         currentCycle = Int(1221/1200) = 1
         lastNotifiedCycle = 1
         1 != 1 → 不触发 ← 本次安全

T=1220:  Layer 3: takeBreakNow() 执行
         isBreakInProgress = true
         resetTimersAfterBreak: elapsed = 0, lastNotifiedCycle = -1
         auto-end Task: 20 秒后 isBreakInProgress = false

T=1240:  auto-end Task fire → isBreakInProgress = false
         此时 elapsed ≈ 20 (累加了 20 秒)
         不触发（cycle 0）

--- 正常情况下上述不会闪退 ---

⚠️ 但如果 acknowledgeBreak() 中 callback 因为某种原因没有执行
   （例如 weak self 已 nil），timer 永远不重置：
   - isNotificationActive = false
   - isBreakInProgress = false  
   - elapsedPerType 持续累加
   - 每次越过 interval 边界就重新触发
   - 但通知立刻被 guard "guard !isNotificationActive" 保护...
   
   等等，如果上一次通知已经正常结束（isNotificationActive = false），
   timer 没重置，elapsed 继续累加到 2400 → cycle 2 → 重新触发通知 → 弹窗出现
   → 20s 后结束 → 又没重置 → 累加到 3600 → cycle 3 → 重新触发...
   每 20 分钟一次，不是 1 分钟。
```

**修正假设：如果用户 interval 设为最小值（10 分钟=600 秒），并且使用了 direct 升级策略（aggressive 模式）：**

弹窗每 10 分钟出现一次，持续 20 秒后自动消失。如果用户感觉"频繁闪退"，可能是正常行为被误认为 bug。

**但 "每 1 分钟" 的模式需要另一个解释：**

如果 `postponeDelay` 被意外设为很短值，或者 postpone 路径存在问题：每次 postpone 后 `elapsedPerType = interval - delay`，延迟后重新触发。如果 delay 很小，就会快速循环。

---

## 修复方案

### Fix 1（必须）：消除嵌套 Task，使 dismiss→reset 原子化

**问题：** `triggerBreakNotification` 中的 `onTaken`/`onSkipped`/`onPostponed` 回调都被包裹在 `Task { @MainActor in }` 中，导致延迟执行。

**修复：** 由于 `BreakScheduler` 已经是 `@MainActor`，且这些回调在 `NotificationManager`（也在 MainActor 上）中被调用，不需要额外的 `Task` 包装。

```swift
// BreakScheduler.swift, triggerBreakNotification()
// BEFORE:
onTaken: { [weak self] in
    Task { @MainActor in          // ← 多余的 Task
        self?.takeBreakNow(breakType)
    }
},
onSkipped: { [weak self] in
    Task { @MainActor in          // ← 多余的 Task
        self?.skipBreak(breakType)
    }
},
onPostponed: { [weak self] delay in
    Task { @MainActor in          // ← 多余的 Task
        self?.postponeBreak(breakType, by: delay)
    }
},

// AFTER:
onTaken: { @Sendable [weak self] in
    self?.takeBreakNow(breakType)  // 同步执行，与 isNotificationActive=false 在同一 run loop
},
onSkipped: { @Sendable [weak self] in
    self?.skipBreak(breakType)
},
onPostponed: { @Sendable [weak self] delay in
    self?.postponeBreak(breakType, by: delay)
},
```

**注意：** 如果编译器要求 `@Sendable` + `@MainActor` 隔离，可能仍需要 `Task`。在这种情况下，使用 Fix 2 作为替代。

### Fix 2（替代/互补）：在 `acknowledgeBreak()` 等函数中，先重置 timer 再设 `isNotificationActive = false`

将 `isNotificationActive = false` 移到 callback 执行**之后**，确保 timer 重置完毕后才放行 guard：

```swift
// NotificationManager.swift
func acknowledgeBreak() {
    let callback = onTakenCallback
    cancelEscalation()
    dismissAllOverlays()
    clearCallbacks()
    // ... other cleanup ...

    callback?()  // ← 先执行回调（重置 timer）

    isNotificationActive = false  // ← 最后才放行 guard
}

func postponeBreak(breakType: BreakType) {
    let callback = onPostponedCallback
    cancelEscalation()
    dismissAllOverlays()
    clearCallbacks()
    // ...

    callback?(EyeGuardConstants.postponeDelay)  // ← 先执行

    isNotificationActive = false  // ← 最后放行
}

func handleEscalationTimeout() {
    let callback = onSkippedCallback
    dismissAllOverlays()
    clearCallbacks()
    // ...

    callback?()  // ← 先执行

    isNotificationActive = false  // ← 最后放行
}
```

**这是最安全的修复。** 即使回调仍被包裹在 `Task` 中，`isNotificationActive` 也不会过早变为 false。

### Fix 3（推荐）：通知期间停止累加 `elapsedPerType`

在 `tick()` 中，当通知活跃时不累加 elapsed：

```swift
// BreakScheduler.swift, tick()
// BEFORE:
for type in BreakType.allCases {
    guard isBreakTypeEnabled(type) else { continue }
    elapsedPerType[type, default: 0] += max(delta, 0)
}

// AFTER:
if !isBreakInProgress && !notificationSender.isNotificationActive {
    for type in BreakType.allCases {
        guard isBreakTypeEnabled(type) else { continue }
        elapsedPerType[type, default: 0] += max(delta, 0)
    }
}
```

**原理：** 通知显示期间，用户正在被提醒休息，不应继续累加"距上次休息的时间"。

### Fix 4（防御）：OverlayWindow 回调中不再自行 dismiss

让 `NotificationManager` 统一管理 dismiss，避免重复 dismiss 和回调时序问题：

```swift
// OverlayWindow.swift, showFullScreenOverlay()
// BEFORE:
onBreakTaken: { [weak self] in
    Task { @MainActor in
        self?.dismissFullScreen()  // ← overlay 自行 dismiss
        onTaken()
    }
},

// AFTER:
onBreakTaken: { @Sendable in
    onTaken()  // ← 只调回调，由 NotificationManager.acknowledgeBreak 统一 dismiss
},
```

### Fix 5（防御）：`dismissFullScreen()` 中立即 invalidate 所有 FullScreenOverlayView 的 Timer

目前 `dismissFullScreen()` 清空数组后窗口异步关闭，View 的 Timer 仍可能 fire。增加同步 close：

```swift
func dismissFullScreen() {
    guard !fullScreenWindows.isEmpty else { return }
    let windows = fullScreenWindows
    fullScreenWindows = []
    
    for fsWindow in windows {
        // 立即取消 hosting view 的事件处理
        fsWindow.contentView = nil  // ← 移除 SwiftUI view，触发 onDisappear → stopTimer
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            fsWindow.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                fsWindow.close()
            }
        })
    }
}
```

---

## 优先级

| Fix | 优先级 | 影响 |
|-----|--------|------|
| Fix 2 | **P0 — 必须** | 根本解决 race condition，最安全最小改动 |
| Fix 3 | **P0 — 必须** | 防止通知期间 elapsed 累加导致的重复触发 |
| Fix 1 | P1 — 推荐 | 消除不必要的 Task 嵌套 |
| Fix 5 | P1 — 推荐 | 防止 dismiss 后 Timer 残留 fire |
| Fix 4 | P2 — 改善 | 简化 dismiss 流程 |

## 变更文件

| File | Change |
|------|--------|
| `Sources/Notifications/NotificationManager.swift` | Fix 2: `isNotificationActive = false` 移到 callback 之后 |
| `Sources/Scheduling/BreakScheduler.swift` | Fix 1: 移除多余 Task 包装; Fix 3: tick 中加 guard |
| `Sources/Notifications/OverlayWindow.swift` | Fix 4: 移除自行 dismiss; Fix 5: dismiss 时清空 contentView |
| `Tests/BreakSchedulerTests.swift` | 新增: dismiss→reset 原子性测试 |

## 测试验证

```swift
@Test("dismiss 后不应在 timer 重置前重新触发通知")
func dismissDoesNotRetriggerBeforeReset() {
    // 1. 触发 micro break → isNotificationActive = true
    // 2. 调用 acknowledgeBreak()
    // 3. 验证 checkForDueBreaks() 不会重新触发
    // 4. 验证 elapsedPerType[.micro] == 0
}
```
