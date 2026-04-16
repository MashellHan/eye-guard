# Bug Report: 眼保健操音频重复 + 字幕/音频不同步 (BUG-006)

**Date:** 2026-04-16
**Severity:** P1
**Status:** Root Cause Confirmed

---

## 现象

1. **音频重复：** TTS 会重复读同一条指令（如"完成5圈"被读多次）
2. **字幕太快：** 视觉指令切换过快，TTS 还没读完就跳下一条了
3. **用户报告：** "完成 5 圈 会重复 5 次"

## 根因

### 根因 1：双重播报（音频重复）

`startSession()` 和 `nextExercise()` 手动播报第一条指令：

```swift
// startSession() line 422-427
SoundManager.shared.speakExerciseIntro()        // 入队: "开始眼保健操"
SoundManager.shared.speakExerciseStep(name, step: firstInstruction)  // 入队: "上下左右看，向上看，保持3秒"
```

同时 countdown timer 每秒调用 `speakStepIfNeeded()`，当 `stepIndex` 变化时也会调用 `speakInstruction()`。由于 TTS 使用 AVSpeechSynthesizer 原生队列（移除了 isSpeaking guard），所有 speak 调用都会入队，不会被丢弃。

**结果：** 第一条指令被播报两次——一次在 startSession 中，一次在 speakStepIfNeeded 首次触发时（如果 currentStep 初始值匹配问题）。

### 根因 2：字幕切换过快

```swift
// speakStepIfNeeded() line 544-545
let stepDuration = max(5, exerciseDuration / instructions.count)
let stepIndex = min(elapsed / stepDuration, instructions.count - 1)
```

以 `circularMotion`（30 秒，6 条指令）为例：
- `stepDuration = max(5, 30/6) = 5` 秒
- 每 5 秒切换一条指令

但中文 TTS 读"缓慢顺时针转动眼球"需要约 3 秒，读"完成5圈"需要约 1.5 秒。5 秒间隔勉强够，但每次切换时还有 300ms 的 chime 延迟，实际留给 TTS 的只有 ~4.7 秒。

**更严重的是：** `speakExerciseStep(name, step:)` 会先读练习名再读指令，总时长可能达到 5-6 秒，但下一条在 5 秒后就触发了。导致队列堆积，后续指令被延迟播放，形成音频和字幕脱节。

### 根因 3："完成5圈"重复的具体原因

`speakStepIfNeeded()` 中 step transition chime + 300ms delay 后调用 `speakInstruction()`。如果 stepIndex 在 timer tick 中连续变化，可能在上一个 speak 的 Task delay 期间又触发了新 speak。但更可能是因为 `currentStep` 在 `nextExercise()` 中被重置为 0，而 `speakExerciseStep()` 又手动播报了第一条——两次入队。

## 修复方案

### Fix 1（必须）：移除 startSession/nextExercise 中的手动播报

让 `speakStepIfNeeded()` 统一管理所有步骤播报：

```swift
// startSession() — 只保留 intro
if isAudioGuidanceEnabled {
    SoundManager.shared.speakExerciseIntro()
    // 不再手动调用 speakExerciseStep — 由 speakStepIfNeeded 统一处理
}

// nextExercise() — 只播报过渡音效
if isAudioGuidanceEnabled {
    SoundManager.shared.onExerciseStepTransition()
    // 不再手动调用 speakExerciseStep
}
```

同时让 `speakStepIfNeeded()` 初始时用 `currentStep = -1` 确保第一条指令被触发：

```swift
@State private var currentStep: Int = -1  // 改为 -1
```

### Fix 2（必须）：根据 TTS 时长动态计算 stepDuration

```swift
let minStepDuration = 8  // TTS 读中文 + chime 至少需要 8 秒
let stepDuration = max(minStepDuration, exerciseDuration / instructions.count)
```

或者更好：**不按固定时间切换，而是等 TTS 读完再切换**（需要 AVSpeechSynthesizerDelegate）。

### Fix 3（推荐）：等 TTS 读完再切换步骤

在 `SoundManager` 中添加 `isSpeaking` 属性查询，`speakStepIfNeeded()` 在 TTS 仍在播放时不切换步骤。

## 变更文件

| File | Change |
|------|--------|
| `Sources/Exercises/ExerciseSessionView.swift` | Fix 1: 移除双重播报; Fix 2: 增加 minStepDuration |
| `Sources/Audio/SoundManager.swift` | Fix 3: 可选 — 暴露 isSpeaking 查询 |
