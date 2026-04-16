# Bug Report: 眼保健操页面 UI 问题

**Date:** 2026-04-16
**Status:** Ready for Fix
**Priority:** P1

---

## Bug A: 页面背景颜色脏灰

### 现象

ExerciseSessionView 页面背景呈现脏灰色，与精灵的薄荷绿配色和紫色动画元素冲突。

### 根因

`ExerciseSessionView.swift:76` 使用 `.background(.ultraThinMaterial)`，而承载窗口是 `MascotWindowController.showExerciseWindow()` 创建的 borderless NSWindow：

```swift
// 窗口设置
window.backgroundColor = .clear
window.isOpaque = false

// SwiftUI View
.background(.ultraThinMaterial)  // ← 问题所在
```

`.ultraThinMaterial` 透明度极高，会混合窗口后面的桌面内容（壁纸、其他窗口），导致不可控的灰色混合效果。在 `backgroundColor = .clear` + `isOpaque = false` 的窗口上使用半透明材质是典型的视觉问题。

### 修复方案

**推荐：使用不透明渐变背景替代半透明材质**

```swift
// ExerciseSessionView.swift:76
// Before:
.background(.ultraThinMaterial)

// After:
.background(
    LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.14, blue: 0.18),  // 深色底
            Color(red: 0.16, green: 0.20, blue: 0.26)    // 稍亮顶
        ],
        startPoint: .bottom,
        endPoint: .top
    )
)
```

或者使用 `.thickMaterial`（透明度最低的材质）作为折中：

```swift
.background(.thickMaterial)
```

---

## Bug B: TTS 语音重复/切换过快（"每次眨眼 每次眨眼 每次..."）

### 现象

用户报告：语音指导在快速眨眼（Rapid Blink）等练习中，上一条指令还没读完就开始重复下一条，出现 "每次眨眼 每次眨眼 每次..." 的反复重读。

### 根因

`speakStepIfNeeded()` 每秒（Timer 回调）都会计算 `stepIndex` 并与 `currentStep` 比较。问题在于 **step 切换间隔太短**：

```swift
// ExerciseSessionView.swift:521-522
let stepDuration = max(1, exerciseDuration / instructions.count)
let stepIndex = min(elapsed / stepDuration, instructions.count - 1)
```

以 `rapidBlink` 为例：
- `duration = 20s`，`instructionsChinese` 有 **6 条**
- `stepDuration = 20 / 6 = 3` 秒
- 但每条中文指令（如 "每次眨眼要快速但完整"）TTS 朗读需要 **约 2-4 秒**

当 step 每 3 秒切换一次，而 TTS 还在读上一条时：
1. `SoundManager.speak()` 先调用 `stopSpeaking(at: .word)` 中断当前朗读
2. 立刻开始读新的指令
3. 如果新指令也来不及读完，3 秒后又被中断
4. 形成 "每次眨眼" → 中断 → "每次眨眼" → 中断的循环

### 修复方案

**方案 1（推荐）：检查 TTS 是否正在朗读，正在读时不切换**

```swift
private func speakStepIfNeeded() {
    // 如果 TTS 还在说上一条，不打断
    guard !SoundManager.shared.isSpeaking else { return }
    
    let exercise = currentExercise
    let instructions = exercise.instructionsChinese
    guard !instructions.isEmpty else { return }
    
    let exerciseDuration = exercise.duration
    let elapsed = exerciseDuration - remainingSeconds
    
    let stepDuration = max(1, exerciseDuration / instructions.count)
    let stepIndex = min(elapsed / stepDuration, instructions.count - 1)
    
    if stepIndex != currentStep && stepIndex < instructions.count {
        currentStep = stepIndex
        SoundManager.shared.onExerciseStepTransition()
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                SoundManager.shared.speakInstruction(instructions[stepIndex])
            }
        }
    }
}
```

**方案 2：增大 stepDuration 最小值**

```swift
let stepDuration = max(5, exerciseDuration / instructions.count)
// 保证每步至少 5 秒，足够 TTS 读完
```

**方案 3：移除 stopSpeaking 逻辑（让当前朗读自然结束）**

```swift
// SoundManager.speak() 中
// Before:
if speechSynthesizer.isSpeaking {
    speechSynthesizer.stopSpeaking(at: .word)
}

// After:
if speechSynthesizer.isSpeaking {
    return  // 不打断，等读完
}
```

**推荐组合：方案 1 + 方案 2**，既检查 isSpeaking 又保证最小步长 5 秒。

## 变更文件

| File | Change |
|------|--------|
| `Sources/Exercises/ExerciseSessionView.swift` | 修复背景颜色（L76），修复 speakStepIfNeeded 逻辑 |
| `Sources/Audio/SoundManager.swift` | 可选：调整 speak() 不再强制中断 |

## Acceptance Criteria

- [ ] 眼保健操页面背景颜色一致、不再出现脏灰
- [ ] TTS 语音指导不再重复/被截断
- [ ] 每条指令能完整读完后再切换到下一条
- [ ] 所有 5 种练习的 TTS 节奏正常
