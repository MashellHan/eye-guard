# Bug Report: 弹窗闪退复发 — 每分钟重复出现 (BUG-POPUP-001 v3)

**Date:** 2026-04-16
**Severity:** P0
**Status:** Root Cause Analysis — Multiple Possible Causes

---

## 现象

休息弹窗每约 1 分钟出现一次，显示约 1 秒后消失。连续多次。

## 之前的修复

- `16257cf`: `handleIdleDetected()` 加 `guard !isBreakInProgress`
- `0f0d9a9`: 加 `guard !notificationSender.isNotificationActive`，idle poll 条件中加同样 guard

**这些修复保护了 idle 轮询路径，但问题仍然存在。**

## 深度分析

### 排除项

| 假设 | 排除原因 |
|------|---------|
| idle 检测重置 timer | 已有 guard，不会在 isNotificationActive 时触发 |
| 默认 20 分钟间隔下 cycle 递增 | `Int(1201/1200) = 1`，skip 后 lastNotifiedCycle=1，不会重新触发 |
| Pre-alert 干扰 | `elapsed >= interval` 后不满足 `elapsed < interval` 条件 |
| ESC 自动触发 | 需要用户按键，不会自动发生 |

### 可能的根因

#### 假设 A（最可能）：用户设置了短间隔

用户可能在 Preferences 中将 micro break interval 设为较短值（slider range 10-30 分钟）。如果设为 10 分钟，弹窗会更频繁出现。但仍然无法解释"每 1 分钟"的模式。

#### 假设 B：`checkForDueBreaks()` 缺少 notification guard

```swift
// BreakScheduler.swift:335
checkForDueBreaks()  // ← 每个 tick 都调用，无条件
```

`checkForDueBreaks()` 没有检查 `isNotificationActive` 或 `isBreakInProgress`。虽然 `notify()` 内部有 `guard !isNotificationActive` 保护，但如果通知的 dismiss 路径在某个 tick 之间执行完毕，下一个 tick 的 `checkForDueBreaks()` 可能会重新触发。

**修复：**
```swift
func checkForDueBreaks() {
    guard !isBreakInProgress else { return }
    guard !notificationSender.isNotificationActive else { return }
    // ... rest of logic
}
```

#### 假设 C：`postponeBreak` 设置了短延迟

`onPostponed` 回调调用 `BreakScheduler.postponeBreak(type, by: delay)`：

```swift
func postponeBreak(_ type: BreakType, by delay: TimeInterval) {
    let interval = intervalForType(type)
    elapsedPerType[type] = max(0, interval - delay)
    lastNotifiedCycle[type] = Int(elapsedPerType[type, default: 0] / interval)
}
```

如果 `delay = EyeGuardConstants.postponeDelay`，检查这个值：

需要确认 `postponeDelay` 是多少。如果是 60 秒（1 分钟），那每次 postpone 后 60 秒就会重新触发 — **完美匹配用户描述的每分钟一次**！

#### 假设 D：`postponeDelay` 值太短

```
如果 postponeDelay = 60 (1 分钟)：
  T=0:    break 触发 → 弹窗出现
  T=1:    弹窗被某种路径 dismiss → onPostponed → postponeBreak(delay=60)
          → elapsedPerType[.micro] = 1200 - 60 = 1140
          → lastNotifiedCycle = Int(1140/1200) = 0
  T=2-60: elapsedPerType 累加: 1140, 1141, ..., 1199
          → currentCycle = 0, 不触发
  T=61:   elapsedPerType = 1200 → currentCycle = 1
          → lastNotifiedCycle = 0, 1 != 0 → 触发！
          → 弹窗又出现了
  T=62:   又被 dismiss → postpone → 重复
```

**这完美解释了每分钟一次的模式！**

## 已确认的值

```swift
// Constants.swift:70
static let postponeDelay: TimeInterval = 5 * 60  // 5 分钟
```

所以 postpone 路径会导致每 5 分钟重复一次，不是 1 分钟。用户说的"一分钟"可能不精确。

**但核心问题不变：** `skipBreak()` 不重置 timer，弹窗被跳过后 `elapsedPerType` 持续累加，到下一个 cycle 就会重新触发。对于 postpone 路径，5 分钟后重新触发是设计行为（延后 5 分钟），但如果弹窗每次出现都被"某种原因"自动 dismiss，就会形成 5 分钟循环。

## 修复方案

### Fix 1（必须）：`checkForDueBreaks` 加 guard

```swift
func checkForDueBreaks() {
    guard !isBreakInProgress else { return }
    guard !notificationSender.isNotificationActive else { return }
    // ... existing logic
}
```

### Fix 2（必须）：`skipBreak` 应该重置 timer

```swift
func skipBreak(_ type: BreakType) {
    recordBreak(type: type, wasTaken: false)
    resetTimersAfterBreak(type)  // ← 新增：跳过也重置，否则会立刻重新触发
}
```

### Fix 3（调查）：确认 `postponeDelay` 值

如果 `postponeDelay` < 5 分钟，需要增大到合理值（至少 5 分钟）。

### Fix 4（防御）：添加最小 postpone 间隔 guard

```swift
func postponeBreak(_ type: BreakType, by delay: TimeInterval) {
    let safeDelay = max(delay, 300)  // 至少 5 分钟
    // ...
}
```

## 变更文件

| File | Change |
|------|--------|
| `Sources/Scheduling/BreakScheduler.swift` | Fix 1: checkForDueBreaks guard; Fix 2: skipBreak 重置 timer |
| `Sources/Utils/Constants.swift` | Fix 3: 确认/调整 postponeDelay |
| `Tests/BreakSchedulerTests.swift` | 新增: skip 后不重新触发测试 |
