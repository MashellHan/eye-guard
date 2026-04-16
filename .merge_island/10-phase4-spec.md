# Phase 4 详细规格：眼保健操 + TTS + SoundManager 合并

## 概述

移植眼保健操系统和 TTS 语音引导，同时合并两边的 SoundManager。

---

## 4.1 Exercises 移植

### 源文件
- `eye-guard/EyeGuard/Sources/Exercises/EyeExercise.swift` — 5 种练习定义
- `eye-guard/EyeGuard/Sources/Exercises/ExerciseSessionView.swift` — 练习 session 流程
- `eye-guard/EyeGuard/Sources/Exercises/ExerciseView.swift` — 单个练习 UI

### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/Exercises/`

### 移植注意

1. ExerciseSessionView 引用了 SoundManager（TTS 语音）— 需要等 4.2 完成
2. 全屏覆盖复用 Phase 3 的 OverlayWindowController
3. 练习完成后更新 `EyeGuardModule.exerciseSessionsToday`

### 接入点

FullScreenOverlayView 中的"开始眼保健操"按钮：
```swift
Button("🏋 开始眼保健操") {
    onDismiss()
    EyeGuardModule.shared?.startExerciseSession()
}
```

EyeGuardModule 新增：
```swift
func startExerciseSession() {
    overlayManager.dismissAll()
    let exerciseView = ExerciseSessionView(
        onComplete: { [weak self] in
            self?.breakScheduler?.recordExerciseSession()
        }
    )
    overlayManager.showExerciseOverlay(exerciseView)
}
```

---

## 4.2 TTS + SoundManager 合并 (Task 2.7)

### 当前状态

MioIsland SoundManager (`Core/SoundManager.swift`):
- NSSound 系统音效
- 简单的 play/stop

EyeGuard SoundManager (`Audio/SoundManager.swift`):
- NSSound 系统音效
- AVSpeechSynthesizer TTS
- AVAudioEngine 环境音（disabled）

### 合并策略

**不替换 MioIsland 的 SoundManager**，而是在 EyeGuard 模块内新建 `EyeGuardSoundManager`：

```swift
@MainActor
final class EyeGuardSoundManager {
    static let shared = EyeGuardSoundManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [String] = []
    private var isSpeaking = false
    
    // MARK: - System Sounds
    
    func playBreakStart() {
        NSSound(named: "Tink")?.play()
    }
    
    func playBreakComplete() {
        NSSound(named: "Glass")?.play()
    }
    
    func playExerciseStep() {
        NSSound(named: "Pop")?.play()
    }
    
    // MARK: - TTS
    
    func speak(_ text: String, language: String = "zh-CN") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func clearQueue() {
        speechQueue.removeAll()
        stopSpeaking()
    }
}
```

这样两个 SoundManager 互不干扰：
- MioIsland 的音效走 `SoundManager`
- EyeGuard 的音效走 `EyeGuardSoundManager`

---

## 4.3 Tips 移植

### 源文件
- `eye-guard/EyeGuard/Sources/Tips/TipDatabase.swift` — 25 条护眼小贴士
- `eye-guard/EyeGuard/Sources/Tips/EyeHealthTip.swift` — 模型
- `eye-guard/EyeGuard/Sources/Tips/TipBubbleView.swift` — 气泡 UI

### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/Tips/`

直接复制，无依赖冲突。BreakOverlayView 和 FullScreenOverlayView 中引用。

---

## 文件清单

| 文件 | 来源 | 行数估计 |
|------|------|----------|
| `Modules/EyeGuard/Exercises/EyeExercise.swift` | 移植 | ~150 |
| `Modules/EyeGuard/Exercises/ExerciseView.swift` | 移植 | ~200 |
| `Modules/EyeGuard/Exercises/ExerciseSessionView.swift` | 移植+适配 | ~300 |
| `Modules/EyeGuard/EyeGuardSoundManager.swift` | 新建 | ~120 |
| `Modules/EyeGuard/Tips/EyeHealthTip.swift` | 复制 | ~30 |
| `Modules/EyeGuard/Tips/TipDatabase.swift` | 复制 | ~200 |
| `Modules/EyeGuard/Tips/TipBubbleView.swift` | 移植 | ~60 |

## 测试清单

- [ ] 5 种眼保健操可完整播放
- [ ] TTS 中文语音在每步切换时播报
- [ ] 练习完成后 exerciseSessionsToday +1
- [ ] 跳过练习时 TTS 队列清空
- [ ] 休息覆盖中的"做操"按钮可启动练习
- [ ] 休息音效正常播放（不影响 MioIsland 音效）
