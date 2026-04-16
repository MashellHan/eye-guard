# Feature Design: 眼保健操与休息倒计时深度整合

**Date:** 2026-04-16
**Status:** Ready for Implementation
**Priority:** P1
**Updated:** 2026-04-16 — 重大修订：眼保健操改为**音频指导为主**模式

---

## 核心设计原则

> **眼保健操的本质是让眼睛休息，用户不应该盯着屏幕看指示来做操。**
>
> 当前实现完全依赖视觉动画引导（ExerciseView 里的方向箭头、脉冲圆圈、旋转点等），
> 用户必须**睁着眼盯着屏幕**才能跟着做。这与眼保健操的目的完全矛盾。
>
> 正确的模式：**声音指导为主，屏幕为辅**。用户闭上眼或看向远方，听语音/音效指导完成动作。

---

## 现状分析

### 当前架构关系图

```
BreakScheduler (调度核心)
  ├── micro break (20s)  → BreakOverlayView / FullScreenOverlayView
  │     └── 倒计时 20s → 完成
  │     └── ❌ 无眼保健操入口（仅 macro/mandatory 有）
  │
  ├── macro break (5min) → FullScreenOverlayView
  │     └── 倒计时 5min → 完成
  │     └── ✅ 有「开始眼保健操」按钮（可选）
  │     └── 眼保健操与倒计时是 **互斥关系**：点击后停止倒计时，进入 ExerciseSessionView
  │
  └── mandatory break (15min) → FullScreenOverlayView
        └── 同 macro
```

### 发现的问题

| # | 问题 | 严重度 |
|---|------|--------|
| 1 | **⚠️ 眼保健操完全依赖视觉引导**：ExerciseView 用屏幕动画（箭头、圆圈、旋转点）引导动作，用户必须盯着屏幕做，与休息初衷矛盾 | **CRITICAL** |
| 2 | **TTS 语音是辅助不是主导**：虽然有 `isAudioGuidanceEnabled` toggle 和 TTS 播报，但语音只是念指令文字，不是完整的音频引导体验 | HIGH |
| 3 | **眼保健操与倒计时互斥**：`stopTimer()` 停掉倒计时，做完操直接关闭 | MEDIUM |
| 4 | **长时间用眼后无主动推荐**：mandatory break 弹窗中眼保健操只是小按钮 | HIGH |
| 5 | **micro break 无任何引导**：20s 干等 | MEDIUM |
| 6 | **眼保健操完成不计入 breakQuality 加分** | LOW |

### 语音指导现状

**已有的 TTS 能力：**
- ✅ `SoundManager.speak()` — AVSpeechSynthesizer, zh-CN, 0.9x 语速
- ✅ `speakExerciseStep()` — 播报练习名 + 步骤指令
- ✅ `onExerciseStepTransition()` — "Pop" 音效
- ✅ `onExerciseComplete()` — "Glass" + TTS "做得好！眼保健操完成"

**不足：**
- ❌ TTS 只是**念文字**，不是完整的声音引导流程
- ❌ 没有节奏/节拍音（如眨眼的节拍 "嘀…嘀…嘀…"）
- ❌ 没有方位音效（如"向上看"时配合上升音调）
- ❌ 没有呼吸引导音（掌心热敷时的吸气/呼气节奏）
- ❌ 环境音 `startAmbient()` 已被禁用

---

## Feature 设计

### Feature 1: 音频指导模式（Audio-First Exercise Mode）⭐ 核心

#### 设计理念

眼保健操进入后，屏幕变为**极简静态界面**（深色背景 + 最少信息），一切引导通过**声音**完成。用户可以闭眼或看向远方。

#### 音频引导时间线设计

每个练习的音频引导由三层声音组成：

```
Layer 1: TTS 语音指令   ──────  "向上看，保持三秒"
Layer 2: 节奏/音效      ──────  嘀...嘀...嘀 (3 秒节拍)
Layer 3: 环境音(可选)    ──────  轻柔白噪音/自然音
```

**各练习的音频脚本：**

```
lookAround (40s):
  TTS: "闭上眼睛，我们开始做眼保健操"
  TTS: "眼球向上看" + 上升音调 → 节拍 嘀(1s) 嘀(2s) 嘀(3s)
  TTS: "向下看"     + 下降音调 → 节拍 × 3
  TTS: "向左看"     + 音效     → 节拍 × 3
  TTS: "向右看"     + 音效     → 节拍 × 3
  TTS: "右上方"     → 节拍 × 3
  TTS: "左下方"     → 节拍 × 3
  TTS: "左上方"     → 节拍 × 3
  TTS: "右下方"     → 节拍 × 3
  TTS: "回到中间，放松"
  [chime 音效]

nearFar (30s):
  TTS: "伸出拇指放在眼前 15 厘米"
  TTS: "看拇指" → 低音 嗡(3s)
  TTS: "看远处" → 高音 叮(3s)
  重复 5 次（交替低/高音）
  TTS: "很好，放松眨眨眼"

circularMotion (30s):
  TTS: "闭上眼，缓慢转动眼球"
  TTS: "顺时针转" → 持续低频 旋转音效 (12s)
  TTS: "停，轻轻眨眼"
  TTS: "逆时针转" → 反向旋转音效 (12s)
  TTS: "停，闭眼放松"

palmWarming (30s):
  TTS: "双手搓热"     → 摩擦音效 (3s)
  TTS: "手掌轻轻覆盖双眼"
  [切换到呼吸引导模式]
  吸气音(3s) → TTS: "吸" → 呼气音(4s) → TTS: "呼"
  重复 3 次呼吸循环
  TTS: "慢慢放下手，睁开眼"

rapidBlink (20s):
  TTS: "快速眨眼，跟着节奏"
  节拍: 嘀-嘀-嘀-嘀 (0.5s 间隔, 共 20 下)
  10 下后 TTS: "很好，继续"
  再 10 下
  TTS: "闭眼休息三秒" → 静默 3s
```

#### UI 变化 — 极简音频模式界面

进入眼保健操后，屏幕**不再显示动画**，改为：

```
┌──────────────────────────────────────────────┐
│                                              │
│              (深色/毛玻璃背景)                 │
│                                              │
│           🐸 (小吉祥物，静态)                  │
│                                              │
│         🎵 正在播放语音指导...                  │
│                                              │
│         「 向上看，保持三秒 」                   │  ← 当前指令文字
│              (仅供偷瞄参考)                     │     字体大、高对比
│                                              │
│         ●●●○○  第 3/5 组                      │  ← 极简进度点
│                                              │
│         ⏱ 剩余 1:20                           │
│                                              │
│    [⏸ 暂停]              [⏭ 跳过]             │
│                                              │
└──────────────────────────────────────────────┘
```

关键：
- **无动画、无需盯屏幕**：屏幕只是显示最基本信息供偷瞄
- 文字大、高对比度，余光就能看到当前步骤
- 吉祥物静态，不做瞳孔追踪动画（当前 mascotPupilPattern 引导用户看屏幕，删除）
- 增加**暂停按钮**：音频指导可暂停

#### Implementation

| File | Change |
|------|--------|
| `SoundManager.swift` | 新增 `AudioExerciseGuide` 模块：完整的音频脚本引擎，管理 TTS + 音效 + 节拍的时间线编排 |
| `SoundManager.swift` | 新增 `playDirectionalCue()` 方位音效、`playBreathingCue()` 呼吸音、`playBeatPattern()` 节拍序列 |
| `ExerciseSessionView.swift` | 重构：`exercisingView` 改为极简静态界面，删除 `mascotExerciseView` 瞳孔追踪 |
| `ExerciseView.swift` | 大幅简化：删除所有动画（lookAroundAnimation 等），改为纯文字显示当前步骤 |
| `EyeExercise.swift` | 新增 `audioScript: [AudioStep]` 属性，定义每个练习的音频时间线 |
| `EyeExercise.swift` | 删除 `mascotPupilPattern`（引导用户看屏幕，违反原则） |

**新增类型：**

```swift
/// 音频指导步骤
struct AudioStep: Sendable {
    enum StepType: Sendable {
        case speak(String)           // TTS 语音
        case beat(interval: Double, count: Int)  // 节拍音效
        case soundEffect(SoundManager.SoundType) // 单次音效
        case breathing(inhale: Double, exhale: Double, cycles: Int) // 呼吸引导
        case silence(Double)         // 静默等待
    }
    
    let type: StepType
    let displayText: String    // 屏幕上显示的文字（供偷瞄）
}
```

---

### Feature 2: 智能眼保健操推荐（根据用眼时长）

#### 逻辑

```
连续用眼时长        推荐策略
─────────────────────────────────────────────
< 20min (micro)    推荐 rapidBlink (20s，正好 = micro break 时长)
20-60min (macro)   推荐 2-3 个动作（lookAround + nearFar + rapidBlink）
> 60min (mandatory) 推荐完整 5 组 + 强提示「强烈建议做眼保健操」
```

#### UI — FullScreenOverlayView 推荐区

```
┌──────────────────────────────────────────────┐
│           🐸 阿普提醒你：该休息了              │
│                                              │
│     你已连续使用屏幕 1h 32m                    │
│     ⚠️ 强烈建议做眼保健操                     │
│                                              │
│  ┌────────────────────────────────────────┐   │
│  │  🎵 推荐练习：3 组（约 1 分 30 秒）       │   │
│  │  全程语音指导，可闭眼跟做                  │   │
│  │                                        │   │
│  │  [▶ 开始语音指导]    [⏭ 仅休息倒计时]     │   │
│  └────────────────────────────────────────┘   │
│                                              │
│        ⏱ 5:00 (倒计时在背景继续)               │
│              跳过休息                          │
└──────────────────────────────────────────────┘
```

#### 关键改变
- 推荐区域**默认展开**
- 强调「全程语音指导，可闭眼跟做」
- 倒计时和眼保健操**不再互斥**：做操期间倒计时继续

#### Implementation

| File | Change |
|------|--------|
| `BreakScheduler.swift` | 新增 `recommendedExercises(for duration: TimeInterval) -> [EyeExercise]` |
| `FullScreenOverlayView.swift` | 重构 exercise section，推荐区默认展开，传递连续用眼时长 |
| `BreakOverlayView.swift` | micro break 集成 rapidBlink 音频引导 |
| `NotificationManager.swift` | 传递 `currentSessionDuration` 给弹窗 |

---

### Feature 3: Micro Break 语音引导

20s micro break = rapidBlink 时间。不走 ExerciseSessionView 全流程，直接在弹窗内嵌入音频引导：

```
弹窗出现 →
  TTS: "眨眼休息，跟着节奏"
  节拍: 嘀(0.5s间隔) × 20
  TTS: "很好，闭眼休息"
  静默 3s →
  倒计时结束，自动关闭
```

屏幕只显示倒计时圈 + 「正在语音指导...」，无需看。

| File | Change |
|------|--------|
| `BreakOverlayView.swift` / `FullScreenOverlayView.swift` | micro break 自动启动 rapidBlink 音频引导 |

---

### Feature 4: 倒计时语音

休息倒计时最后 5 秒加入语音：

```swift
if remainingSeconds <= 5 && remainingSeconds > 0 {
    SoundManager.shared.speak("\(remainingSeconds)")
}
if remainingSeconds == 0 {
    SoundManager.shared.speak("休息结束，继续加油")
}
```

| File | Change |
|------|--------|
| `SoundManager.swift` | 新增 `speakCountdown(_:)` |
| `FullScreenOverlayView.swift` | 倒计时最后 5s 调用 |

---

### Feature 5: 语音温度与鼓励

在关键节点插入有温度的语音：

```
开始前:  "来，闭上眼睛，我们一起做眼保健操"
第 3 步后: "很好，继续保持"（随机从鼓励语料库选取）
结束时:  "太棒了！你的眼睛一定感觉好多了"
```

鼓励语料库：
- "很好，继续保持"
- "做得不错"
- "放松，慢慢来"
- "你的眼睛会感谢你的"

| File | Change |
|------|--------|
| `SoundManager.swift` | 新增鼓励语料库和 `speakEncouragement()` |
| `ExerciseSessionView.swift` | 在开始/中途/结束插入鼓励 |

---

### Feature 6: 眼保健操质量加分

```
breakQuality 最高 10 分
  - 基础休息: 6/10
  - 休息 + 做操: 10/10 (额外 +4)
```

| File | Change |
|------|--------|
| `HealthScoreCalculator.swift` | `breakQuality` 加入 `exerciseSessionsToday` 权重 |
| `BreakScheduler.swift` | `recordExerciseSession()` 后触发 `recalculateHealthScore()` |

---

## 优先级排序

| Priority | Feature | 工作量 | 用户价值 |
|----------|---------|--------|---------|
| **P0** | Feature 1: 音频指导模式（核心重构） | L | ⭐⭐⭐⭐⭐ |
| **P0** | Feature 2: 智能推荐 + 倒计时不互斥 | M | ⭐⭐⭐⭐⭐ |
| **P1** | Feature 3: Micro break 语音引导 | S | ⭐⭐⭐⭐ |
| **P1** | Feature 4: 倒计时语音 | XS | ⭐⭐⭐ |
| **P2** | Feature 5: 语音温度与鼓励 | XS | ⭐⭐⭐ |
| **P2** | Feature 6: 质量加分 | XS | ⭐⭐⭐ |

## 变更文件总览

| File | 变更类型 |
|------|---------|
| `Sources/Audio/SoundManager.swift` | **重大扩展**：AudioExerciseGuide 引擎、方位音效、节拍、呼吸引导、鼓励语料库 |
| `Sources/Exercises/EyeExercise.swift` | 新增 `audioScript` 属性，删除 `mascotPupilPattern` |
| `Sources/Exercises/ExerciseSessionView.swift` | **重构**：删除视觉动画，改为极简音频模式界面 |
| `Sources/Exercises/ExerciseView.swift` | **大幅简化**：删除所有动画，保留纯文字步骤显示 |
| `Sources/Notifications/FullScreenOverlayView.swift` | 推荐区重构、传递用眼时长、倒计时语音 |
| `Sources/Notifications/BreakOverlayView.swift` | Micro break 音频引导 |
| `Sources/Scheduling/BreakScheduler.swift` | `recommendedExercises()`、倒计时不互斥 |
| `Sources/Notifications/NotificationManager.swift` | 传递 `currentSessionDuration` |
| `Sources/Reporting/HealthScoreCalculator.swift` | breakQuality 加分 |

## Acceptance Criteria

- [ ] 眼保健操以**语音 + 音效指导为主**，屏幕仅显示极简信息
- [ ] 每个练习有完整的音频脚本：TTS 指令 + 节拍/音效 + 呼吸引导
- [ ] 用户可闭眼完成全部练习，无需看屏幕
- [ ] `mascotPupilPattern` 瞳孔追踪动画移除（引导用户盯屏幕）
- [ ] 连续用眼 > 1h 时弹窗默认推荐眼保健操，显示用眼时长
- [ ] 倒计时与眼保健操**并行**
- [ ] micro break 自动播放 rapidBlink 节拍引导
- [ ] 倒计时最后 5s 语音倒数
- [ ] 语音指导可通过 toggle 关闭（关闭后退回到视觉模式作为 fallback）
- [ ] breakQuality 因做操加分
- [ ] 现有测试通过，新增音频脚本和推荐逻辑测试
