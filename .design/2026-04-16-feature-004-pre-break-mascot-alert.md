# Feature Design: 休息前精灵预提醒（Pre-Break Mascot Alert）

**Date:** 2026-04-16
**Status:** ⚠️ Partially Implemented (`34a71b9`) — 缺气泡按钮、TTS、隐藏降级
**Priority:** P1

---

## 需求

在全屏休息倒计时弹窗出现**之前**，精灵（阿普）先通过 speech bubble + 状态变化给用户一个预警缓冲：「还有 10 秒进入休息模式」，而不是突然弹出全屏覆盖打断工作。

## 现状

```
当前流程:
  elapsedPerType[.micro] 到 20min
  → checkForDueBreaks()
  → triggerBreakNotification()
  → NotificationManager.notify()
  → .direct 模式: 立刻 showFullScreenOverlay()
  → 全屏弹窗瞬间覆盖 ← 打断感强
```

精灵已有的能力：
- ✅ `MascotState.alerting` — "Break time! bouncing, alert glow pulse, iris turns warm red"
- ✅ `MascotState.concerned` — "User has been working too long, iris turns amber"
- ✅ `viewModel.showMessage(text, duration:)` — speech bubble 显示
- ✅ `viewModel.triggerPopBounce()` — 弹跳动画
- ✅ peek mode auto-reveal — bubble 出现时自动从 peek 弹出
- ✅ `SoundManager.play(.alert)` — 提示音效

## 设计

### 交互时间线

```
                    倒计时 10s                              0s
                    ────────────────────────────────────────→
                    
精灵状态:     concerned → alerting ──────────────→ (弹窗出现后 resting)
精灵气泡:     "还有 10 秒进入休息~"                  气泡消失
精灵位置:     peek 自动弹出                          
精灵动画:     瞳孔变琥珀色 → 弹跳 + 光晕脉冲        
音效:         叮~ (gentle alert)                      
气泡倒数:     "10...9...8..."  (气泡内文字更新)      
TTS (可选):   "十秒后进入休息"
                    
最后 3 秒:    精灵加速弹跳 + 气泡 "3...2...1..."
                    
T=0:          全屏弹窗正常出现
              精灵切换到 resting 状态
```

### 精灵气泡文案（随机选取）

**Micro Break (20s):**
```
"👀 还有 {N} 秒，该让眼睛休息一下了~"
"🌿 马上进入 20 秒眼休息~"
"💧 准备好了吗？20 秒远眺时间~"
```

**Macro Break (5min):**
```
"☕ 还有 {N} 秒，该起来活动了~"
"🧘 5 分钟大休息马上开始~"
"🚶 准备站起来走走吧~"
```

**Mandatory Break (15min):**
```
"⚠️ 你已经连续工作很久了！{N} 秒后强制休息"
"🛑 15 分钟休息倒计时即将开始！"
"🔴 眼睛需要好好休息了！马上进入休息模式"
```

### 倒计时气泡更新

气泡不是一直显示同一条文字，而是在最后几秒更新倒数数字：

```
T-10s: "🌿 马上进入 20 秒眼休息~"
T-5s:  "5..."
T-4s:  "4..."
T-3s:  "3..." (精灵加速弹跳)
T-2s:  "2..."
T-1s:  "1..."
T-0s:  气泡消失，全屏弹窗接管
```

### 预提醒时间配置

不同 break 类型预提醒的秒数不同（大休息给更多准备时间）：

```
Micro Break (20s):     预提醒 10 秒
Macro Break (5min):    预提醒 15 秒
Mandatory Break (15min): 预提醒 20 秒
```

### 用户可选行为

预提醒期间用户可以：
1. **什么都不做** → 倒数结束后正常弹出休息弹窗
2. **点击精灵** → 提前进入休息（"好的，现在就休息"）
3. **点击气泡的「延后」** → 延后 5 分钟（等同于当前 postpone）

气泡中加入小按钮：

```
┌──────────────────────────────────┐
│ 🌿 还有 10 秒进入休息~           │
│                                  │
│   [立刻休息]     [延后 5 分钟]    │
└──────────────────────────────────┘
         ▽ (精灵)
```

### 精灵状态转换增强

```swift
// 当前 MascotState 已有 concerned 和 alerting:
// concerned: "iris turns amber, pupil contracts" → 用于预提醒前半段
// alerting:  "bouncing, alert glow pulse, iris turns warm red" → 用于最后 3 秒

// 状态转换时间线:
T-10s:  idle → concerned (瞳孔变琥珀色，表情变严肃)
T-3s:   concerned → alerting (弹跳 + 脉冲光晕，暗示紧迫)
T-0s:   alerting → resting (进入休息状态)
```

## Architecture

### 新增 Pre-Break Phase

在 `BreakScheduler` 的 `checkForDueBreaks` 和 `triggerBreakNotification` 之间插入预提醒阶段：

```
当前:
  elapsedPerType 到达 interval → triggerBreakNotification → 弹窗

改后:
  elapsedPerType 到达 (interval - preAlertDuration)
    → startPreAlert()
    → 精灵提醒 + 倒计时
    → preAlertDuration 后 → triggerBreakNotification → 弹窗
```

### 实现方案

**方案选择：在 BreakScheduler 中增加 pre-alert 阶段**

```swift
// BreakScheduler 新增状态
private(set) var isPreAlertActive: Bool = false
private(set) var preAlertBreakType: BreakType?
private(set) var preAlertRemainingSeconds: Int = 0
private var preAlertTask: Task<Void, Never>?

/// 各 break 类型的预提醒时间
private func preAlertDuration(for type: BreakType) -> TimeInterval {
    switch type {
    case .micro:     return 10
    case .macro:     return 15
    case .mandatory: return 20
    }
}
```

**修改 `checkForDueBreaks`：提前触发预提醒**

```swift
func checkForDueBreaks() {
    for type in BreakType.allCases {
        guard isBreakTypeEnabled(type) else { continue }
        let elapsed = elapsedPerType[type, default: 0]
        let interval = intervalForType(type)
        let preAlert = preAlertDuration(for: type)
        
        // 检查是否该进入 pre-alert
        if elapsed >= (interval - preAlert) && !isPreAlertActive {
            startPreAlert(for: type)
        }
        
        // 原有的 due break 检查（不变）
        ...
    }
}
```

**Pre-Alert → 通知链路：**

```swift
private func startPreAlert(for type: BreakType) {
    isPreAlertActive = true
    preAlertBreakType = type
    let duration = Int(preAlertDuration(for: type))
    preAlertRemainingSeconds = duration
    
    // 通知精灵
    NotificationCenter.default.post(
        name: .preAlertStarted,
        object: nil,
        userInfo: ["breakType": type, "seconds": duration]
    )
    
    // 倒计时
    preAlertTask = Task {
        for i in stride(from: duration, through: 1, by: -1) {
            preAlertRemainingSeconds = i
            
            // 通知精灵更新气泡
            NotificationCenter.default.post(
                name: .preAlertCountdown,
                object: nil,
                userInfo: ["remaining": i, "breakType": type]
            )
            
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
        }
        
        preAlertRemainingSeconds = 0
        isPreAlertActive = false
        preAlertBreakType = nil
        
        // pre-alert 结束，正常触发通知
        // （实际上 checkForDueBreaks 的下一次 tick 会自然触发）
    }
}
```

### 精灵响应

```swift
// MascotWindowController 监听 pre-alert 通知
NotificationCenter.default.addObserver(
    forName: .preAlertStarted, ...
) { [weak self] notification in
    let breakType = notification.userInfo?["breakType"] as? BreakType
    let seconds = notification.userInfo?["seconds"] as? Int ?? 10
    
    // 1. 切换精灵状态
    self?.viewModel?.transition(to: .concerned)
    
    // 2. 显示气泡
    let message = Self.preAlertMessage(for: breakType, seconds: seconds)
    self?.viewModel?.showMessage(message, duration: TimeInterval(seconds))
    
    // 3. 播放提示音
    SoundManager.shared.play(.alert)
    
    // 4. TTS（如果启用）
    if isAudioGuidanceEnabled {
        SoundManager.shared.speak("\(seconds)秒后进入休息")
    }
}

// 倒计时更新
NotificationCenter.default.addObserver(
    forName: .preAlertCountdown, ...
) { [weak self] notification in
    let remaining = notification.userInfo?["remaining"] as? Int ?? 0
    
    if remaining <= 5 {
        self?.viewModel?.showMessage("\(remaining)...", duration: 1.5)
    }
    if remaining == 3 {
        self?.viewModel?.transition(to: .alerting)
    }
}
```

### SpeechBubbleView 增强

当前 SpeechBubbleView 只显示文字。Pre-alert 需要加入按钮：

```swift
/// 增强版 speech bubble，支持可选的 action 按钮
struct SpeechBubbleView: View {
    let text: String
    var isNightMode: Bool = false
    
    // 新增: 可选按钮
    var primaryAction: (() -> Void)?
    var primaryLabel: String?
    var secondaryAction: (() -> Void)?
    var secondaryLabel: String?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    ...
                
                // 按钮行
                if primaryAction != nil || secondaryAction != nil {
                    HStack(spacing: 8) {
                        if let action = primaryAction, let label = primaryLabel {
                            Button(label, action: action)
                                .font(.system(size: 10, weight: .medium))
                                .buttonStyle(.borderedProminent)
                                .tint(.teal)
                                .controlSize(.mini)
                        }
                        if let action = secondaryAction, let label = secondaryLabel {
                            Button(label, action: action)
                                .font(.system(size: 10))
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                        }
                    }
                }
            }
            .padding(...)
            .background(...)
            
            Triangle()
                ...
        }
    }
}
```

## 变更文件

| File | Change |
|------|--------|
| `Sources/Scheduling/BreakScheduler.swift` | 新增 pre-alert 状态和倒计时逻辑 |
| `Sources/Utils/Constants.swift` | 新增 `Notification.Name.preAlertStarted / preAlertCountdown`、各 break 的 preAlertDuration 常量 |
| `Sources/Mascot/MascotWindowController.swift` | 监听 pre-alert 通知，驱动精灵状态转换和气泡 |
| `Sources/Mascot/SpeechBubbleView.swift` | 增强：支持 action 按钮（立刻休息/延后） |
| `Sources/Mascot/MascotViewModel.swift` | 新增 `showPreAlert(text:, primaryAction:, secondaryAction:)` |
| `Sources/Audio/SoundManager.swift` | 可选: 预提醒专用音效 |
| `Tests/BreakSchedulerTests.swift` | 新增: pre-alert 触发时机、取消、与通知的衔接测试 |

## 边界场景

| 场景 | 处理 |
|------|------|
| 用户在预提醒期间点击「延后」 | 取消 preAlertTask，调用 postponeBreak，精灵回到 idle |
| 用户在预提醒期间点击「立刻休息」 | 取消 preAlertTask，直接 triggerBreakNotification |
| 预提醒期间用户 idle（离开电脑） | handleIdleDetected 应同时取消 preAlertTask |
| 预提醒期间多个 break 同时到期 | 只对最高优先级的 break 显示预提醒 |
| 用户设置为 gentle 模式（系统通知） | 预提醒仍然有效（精灵层面），只是后续弹窗是系统通知而非全屏 |
| 精灵被用户隐藏 | 仅播放音效 + TTS，不显示气泡 |

## Acceptance Criteria

- [ ] 全屏休息弹窗出现前 10-20s（根据 break 类型），精灵从 peek 弹出并显示预提醒气泡
- [ ] 精灵状态: idle → concerned (预提醒) → alerting (最后 3s) → resting (弹窗出现)
- [ ] 气泡在最后 5s 显示倒计时数字 "5...4...3...2...1..."
- [ ] 气泡含「立刻休息」和「延后 5 分钟」按钮
- [ ] 点击「延后」取消当前休息，postpone 5 分钟
- [ ] 点击「立刻休息」直接进入休息模式
- [ ] 播放提示音效
- [ ] 预提醒期间 idle → 自动取消预提醒
- [ ] 精灵被隐藏时降级为仅音效
- [ ] 现有测试通过，新增预提醒逻辑测试
