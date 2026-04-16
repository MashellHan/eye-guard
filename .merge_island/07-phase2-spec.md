# Phase 2 详细规格：护眼核心功能移植

## 概述

将 EyeGuard 的核心护眼引擎移植到 mio-guard 项目。这是最关键的阶段——移植后 Eye Guard 模式就真正可用了。

---

## 2.5 EyeGuardModule — 模块入口（最先实现）

### 文件：`Modules/EyeGuard/EyeGuardModule.swift`

```swift
import Foundation

@MainActor
final class EyeGuardModule: AppModule {
    let id = "eye_guard"
    
    private(set) var isActive = false
    
    // 子系统
    private var scheduler: BreakScheduler?
    private var activityMonitor: ActivityMonitor?
    private var nightModeManager: NightModeManager?
    
    // 事件流
    private var eventContinuation: AsyncStream<AppEvent>.Continuation?
    
    func activate() {
        guard !isActive else { return }
        isActive = true
        
        activityMonitor = ActivityMonitor()
        scheduler = BreakScheduler(activityMonitor: activityMonitor!)
        nightModeManager = NightModeManager()
        
        scheduler?.startScheduling()
        activityMonitor?.startMonitoring()
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        
        scheduler?.stopScheduling()
        activityMonitor?.stopMonitoring()
        
        scheduler = nil
        activityMonitor = nil
        nightModeManager = nil
    }
    
    func handleEvent(_ event: AppEvent) {
        switch event {
        case .screenLocked:
            scheduler?.handleScreenLocked()
        case .screenUnlocked:
            scheduler?.handleScreenUnlocked()
        default:
            break
        }
    }
    
    // MARK: - Public accessors for UI
    
    var currentSessionDuration: TimeInterval {
        scheduler?.currentSessionDuration ?? 0
    }
    
    var healthScore: Int {
        scheduler?.healthScore ?? 100
    }
    
    var nextBreakIn: TimeInterval {
        scheduler?.timeUntilNextBreak ?? 0
    }
}
```

### 关键点
- `activate()`/`deactivate()` 控制资源生命周期
- ModeManager 切换到 Island-only 时调用 `deactivate()` 释放 timer/monitor
- UI 通过 public accessors 读取状态（不直接暴露 BreakScheduler）

---

## 2.1 BreakScheduler 移植

### 源文件：`eye-guard/EyeGuard/Sources/Scheduling/BreakScheduler.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/BreakScheduler.swift`

### 移植注意事项

1. **依赖解耦**：EyeGuard 的 BreakScheduler 直接引用 `NotificationManager`、`MascotWindowController`。合并后需要改为协议/回调：

```swift
// 原代码（耦合）
notificationManager.showBreakOverlay(type: .micro)
mascotController?.viewModel?.triggerCelebration()

// 改为（解耦）
onBreakTriggered?(breakType)  // EyeGuardModule 负责路由
onBreakCompleted?()
```

2. **Timer 兼容**：BreakScheduler 使用 `Task.sleep`，与 MioIsland 的 Combine timer 不冲突

3. **idle 检测**：最新版使用 CGEventTap（commit b785eb8），需要一起移植

### 需要同步移植的文件
- `BreakType.swift` — 枚举定义
- `ActivityMonitoring.swift` — 协议

---

## 2.2 ActivityMonitor 移植

### 源文件：`eye-guard/EyeGuard/Sources/Monitoring/ActivityMonitor.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/ActivityMonitor.swift`

### 注意事项

1. 最新版使用 `CGEventTap` 代替 `NSEvent.addGlobalMonitorForEvents`
2. 需要 Accessibility 权限（`AXIsProcessTrusted`）
3. MioIsland 本身不需要 Accessibility 权限，合并后需要在 Info.plist 添加 `NSAppleEventsUsageDescription`
4. 屏幕锁定检测：`DistributedNotificationCenter` 监听 `com.apple.screenIsLocked`

---

## 2.3 Models 移植

| 文件 | 说明 | 改动 |
|------|------|------|
| `BreakType.swift` | micro/macro/mandatory 枚举 | 直接复制 |
| `ReminderMode.swift` | gentle/standard/strict 模式 | 直接复制 |
| `Models.swift` | DailyData, BreakRecord 等 | 检查是否与 MioIsland Models 冲突 |

---

## 2.7 SoundManager 合并

### 冲突分析

| 功能 | EyeGuard SoundManager | MioIsland SoundManager |
|------|----------------------|----------------------|
| 系统音效 | ✅ NSSound | ✅ NSSound |
| TTS | ✅ AVSpeechSynthesizer | ❌ |
| 环境音 | ✅ AVAudioEngine (disabled) | ❌ |
| 触感 | ❌ | ❌ |

### 合并方案

```swift
// 统一 SoundManager
@MainActor
final class UnifiedSoundManager: SoundPlaying {
    static let shared = UnifiedSoundManager()
    
    // System sounds (both modules)
    func playSound(_ name: String) { ... }
    
    // TTS (EyeGuard only)
    func speak(_ text: String, language: String = "zh-CN") { ... }
    func stopSpeaking() { ... }
    
    // Ambient (EyeGuard, re-enable)
    func startAmbient(_ preset: AmbientPreset) { ... }
    func stopAmbient() { ... }
}
```

保留两边所有功能，EyeGuard 特有功能用 `#if` 或运行时检查 ModeManager。

---

## 2.6 ModeManager ↔ EyeGuardModule 接入

### AppDelegate 修改

```swift
// 现有 MioIsland AppDelegate 中添加
class AppDelegate: NSObject, NSApplicationDelegate {
    let modeManager = ModeManager()
    var eyeGuardModule: EyeGuardModule?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // ... existing MioIsland setup ...
        
        eyeGuardModule = EyeGuardModule()
        
        modeManager.onModeChanged = { [weak self] mode in
            guard let self else { return }
            if self.modeManager.isEyeGuardEnabled {
                self.eyeGuardModule?.activate()
            } else {
                self.eyeGuardModule?.deactivate()
            }
        }
        
        // 初始激活
        if modeManager.isEyeGuardEnabled {
            eyeGuardModule?.activate()
        }
    }
}
```

---

## 测试清单

- [ ] Eye Guard 模式激活后 20 分钟触发微休息
- [ ] 切换到 Island-only 模式后 timer 停止
- [ ] 切回 Dual 模式后 timer 恢复（从 0 开始）
- [ ] 锁屏后解锁，session duration 重置
- [ ] CGEventTap idle 检测正常（5 分钟无操作 → idle）
- [ ] SoundManager 不冲突（EyeGuard 音效 + MioIsland 音效可同时工作）
