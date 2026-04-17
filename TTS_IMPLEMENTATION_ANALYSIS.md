# EyeGuard macOS Chinese TTS Voice Guidance Implementation Analysis

**Project:** EyeGuard Swift (macOS)  
**Date:** April 15, 2026  
**Goal:** Add Chinese TTS voice guidance to eye exercise flow  
**Status:** Analysis Report (No modifications made)

---

## Executive Summary

The EyeGuard project is well-architected for adding Chinese TTS voice guidance. The project:
- **Already has dual Chinese/English text** throughout (chineseName, instructionsChinese)
- **Has a clean audio layer** (SoundManager) using AVFoundation with MainActor concurrency
- **Has clear exercise timing architecture** with instructions synced to exercise phases
- **Runs on macOS 14+**, which fully supports AVSpeechSynthesizer with Chinese language

**Key finding:** AVSpeechSynthesizer is NOT currently imported anywhere. It must be added to SoundManager.

---

## 1. AVSpeechSynthesizer Capabilities on macOS

### ✅ Available & Supported

**AVSpeechSynthesizer** is part of `AVFoundation` framework (already imported in SoundManager):

```swift
import AVFoundation  // ✅ Already present
import AppKit        // ✅ Already present (needed for NSSound fallback)
```

**Chinese Language Support:**
- Locale: `zh_CN` (Simplified Chinese)
- Voice identifier: `com.apple.speech.synthesis.voice.Siyi` (available on macOS 14+)
- Alternative: `AVSpeechSynthesisVoiceIdentifierFemale` variants
- **Supported features:**
  - Continuous speech synthesis (not just sound effects)
  - Adjustable speech rate (0.0–2.0)
  - Adjustable pitch (0.5–2.0)
  - Adjustable volume (0.0–1.0)
  - Delegate callbacks for progress/completion
  - Pause/resume/stop control
  - Pre-utterance speech (e.g., "Step 1 of 5")

### Current State in EyeGuard

- **Not imported:** No `import AVSpeechSynthesizer` or speech-related code
- **No speech files:** Project has NO speech-related source files
- **Related components:**
  - `SpeechBubbleView.swift` is **UI only** (displays text bubble, not audio synthesis)
  - `SoundManager.swift` manages sound effects, not speech

---

## 2. SoundManager.swift Architecture Analysis

### Current Structure

**Location:** `EyeGuard/Sources/Audio/SoundManager.swift`  
**Lines:** 291 lines  
**MainActor:** Yes (thread-safe for UI updates)

#### Current Capabilities

```swift
@MainActor
final class SoundManager: SoundPlaying {
    static let shared = SoundManager()
    
    enum SoundType: String, Sendable {
        case breakStart       // ✅ Only active sound
        case breakComplete    // Disabled
        case tipRotation      // Disabled
        case alert            // Disabled
        case ambient          // Disabled
    }
    
    enum AmbientPreset: String, CaseIterable {
        case rain, ocean, forest, wind, silence
    }
}
```

#### Key State Management

- **AVAudioEngine:** Used for procedural ambient sound generation (not needed for TTS)
- **Volume:** Stored in UserDefaults (`soundVolume`)
- **Muted:** Stored in UserDefaults (`soundMuted`)
- **Ambient preset:** Stored in UserDefaults (`ambientPreset`)

#### Current API

```swift
func play(_ type: SoundType)      // Plays sound effects
func startAmbient()                // Starts ambient engine
func stopAmbient()                 // Stops ambient engine
func onBreakStart()                // Convenience wrapper
func onBreakComplete()             // Convenience wrapper
func onTipRotation()               // Convenience wrapper
```

### Integration Points

1. **Protocol-based design:** SoundManager conforms to `SoundPlaying` protocol
2. **UserDefaults:** Persists volume, mute state, and preset selection
3. **Concurrency:** MainActor ensures thread-safety
4. **Logging:** Uses `os.Logger` (imported via `import os`)

---

## 3. Audio Directory Contents

**Location:** `EyeGuard/Sources/Audio/`

```
Audio/
├── SoundManager.swift   (10,003 bytes - Only file)
```

**Summary:**
- Single file managing all audio
- No external audio assets (procedurally generated)
- No speech synthesis code

---

## 4. EyeExercise.swift Analysis

### Structure & Timing

**Location:** `EyeGuard/Sources/Exercises/EyeExercise.swift`  
**Lines:** 245 lines

```swift
enum EyeExercise: String, CaseIterable, Sendable {
    case lookAround          // Duration: 40s
    case nearFar             // Duration: 30s
    case circularMotion      // Duration: 30s
    case palmWarming         // Duration: 30s
    case rapidBlink          // Duration: 20s
}
```

### Key Data Already Available

#### ✅ English Instructions
```swift
var instructions: [String] {
    switch self {
    case .lookAround:
        return [
            "Look up and hold for 3 seconds",
            "Look down and hold for 3 seconds",
            // ... 7 more steps
        ]
    // 5 exercises × ~6-9 instructions each = 38+ total instruction strings
}
```

#### ✅ Chinese Instructions (同时提供)
```swift
var instructionsChinese: [String] {
    switch self {
    case .lookAround:
        return [
            "向上看，保持3秒",
            "向下看，保持3秒",
            // ... 7 more steps
        ]
}
```

#### ✅ Exercise Names (Bilingual)
```swift
var name: String              // English: "Look Around"
var chineseName: String       // Chinese: "上下左右看"
var duration: Int             // Seconds
var mascotPupilPattern: [...]  // Animation sync
```

### Timing Architecture

Each instruction has an implicit timing:

| Exercise | Duration | Steps | Avg Time/Step |
|----------|----------|-------|---------------|
| lookAround | 40s | 9 | ~4-5s |
| nearFar | 30s | 6 | ~5s |
| circularMotion | 30s | 6 | ~5s |
| palmWarming | 30s | 6 | ~5s |
| rapidBlink | 20s | 6 | ~3-4s |

**Total session:** ~150 seconds (~2.5 minutes)

### Mascot Animation Sync

```swift
var mascotPupilPattern: [(offset: (Double, Double), holdSeconds: Double)] {
    // Each pattern element has explicit duration
    // e.g., lookAround: ((0, -1), 3)  means: look up, hold 3 seconds
}
```

---

## 5. ExerciseSessionView.swift Flow Analysis

### Session Architecture

**Location:** `EyeGuard/Sources/Exercises/ExerciseSessionView.swift`  
**Lines:** 507 lines

#### Session Phases
```swift
private enum SessionPhase {
    case intro       // "Ready to exercise?"
    case exercising  // Active exercise display
    case completed   // Celebration screen
}
```

#### Key State Variables
```swift
@State private var sessionPhase: SessionPhase = .intro
@State private var currentExerciseIndex: Int = 0
@State private var currentStep: Int = 0
@State private var remainingSeconds: Int = 0
@State private var totalSessionSeconds: Int = 0
@State private var elapsedSessionSeconds: Int = 0
@State private var countdownTimer: Timer?
```

### Timer & Step Advancement

#### Countdown Loop (Lines 441-462)
```swift
private func startCountdown() {
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        Task { @MainActor in
            if remainingSeconds > 0 {
                withAnimation {
                    remainingSeconds -= 1  // Decrements each second
                }
                elapsedSessionSeconds += 1
            }
            
            if remainingSeconds <= 0 {
                // Auto-advance to next exercise
                if currentExerciseIndex < exercises.count - 1 {
                    nextExercise()
                } else {
                    completeSession()
                }
            }
        }
    }
}
```

#### Step Transitions
- **Triggered by:** `remainingSeconds` changes
- **Updated in:** `updateMascotPupil()` (Lines 472-506)
- **Observer:** `onChange(of: remainingSeconds)` calls `updateMascotPupil()`
- **Current step:** `currentStep` is exposed as `@Binding` to ExerciseView

#### UI Display Sequence
1. **Intro phase:** Shows all 5 exercises, durations, preview list
2. **Exercising phase:** 
   - Exercise header + Chinese name
   - Animated visual
   - Current instruction (English + Chinese)
   - Countdown timer
3. **Completed phase:** Celebration screen

### Integration Points for TTS

```swift
// During intro (Line 119)
Text("👋 眼保健操时间到!")  // Chinese text already

// During exercise (Line 215)
ExerciseView(
    exercise: currentExercise,
    currentStep: $currentStep,        // ← Could trigger TTS
    remainingSeconds: $remainingSeconds
)

// Step updates trigger via (Line 276-278)
.onChange(of: remainingSeconds) {
    updateMascotPupil()
    // ← Could also trigger TTS here
}
```

---

## 6. Package.swift Dependencies

**Location:** `Package.swift` (28 lines)

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EyeGuard",
    platforms: [
        .macOS(.v14)  // ✅ macOS 14+ required
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "EyeGuard",
            path: "EyeGuard/Sources"
        ),
        .testTarget(
            name: "EyeGuardTests",
            dependencies: ["EyeGuard", .product(name: "Testing", package: "swift-testing")],
            path: "EyeGuard/Tests"
        )
    ]
)
```

### Audio Dependencies Status

| Framework | Status | Need to Add? | Notes |
|-----------|--------|-------------|-------|
| AVFoundation | ✅ Imported in SoundManager | NO | Already used for AVAudioEngine |
| AppKit | ✅ Imported in SoundManager | NO | Already used for NSSound |
| Foundation | ✅ Imported everywhere | NO | Standard |
| AVSpeechSynthesizer | ❌ NOT imported | **YES** | Part of AVFoundation, just need import statement |

---

## 7. What's Needed to Add Chinese TTS

### Architecture Overview

```
ExerciseSessionView
    ├─ remainingSeconds (changes every 1s)
    │   └─ onChange trigger
    │       └─ [NEW] TextToSpeechManager.speakInstruction()
    │
    ├─ currentStep (updates when instructions advance)
    │   └─ [NEW] Could trigger TTS update
    │
    └─ sessionPhase transitions
        └─ intro: "Ready to start?"
        ├─ exercising: current instruction
        └─ completed: celebration message
```

### Implementation Strategy

#### Option A: Extend SoundManager (Recommended)
- **Pros:** Single audio manager, cleaner API, reuse MainActor, UserDefaults integration
- **Cons:** Mixes speech with sound effects
- **Effort:** ~100 lines
- **Where to add:** SoundManager.swift

#### Option B: Create TextToSpeechManager
- **Pros:** Separation of concerns, pure speech synthesis
- **Cons:** Duplicate MainActor, UserDefaults management
- **Effort:** ~150 lines
- **Where to add:** New file `EyeGuard/Sources/Audio/TextToSpeechManager.swift`

#### Option C: Create SpeechProtocol
- **Pros:** Protocol-oriented, testable via DI
- **Cons:** Most complex
- **Effort:** ~200 lines
- **Where to add:** 
  - New protocol: `EyeGuard/Sources/Protocols/VoiceGuidance.swift`
  - New implementation: `EyeGuard/Sources/Audio/VoiceGuidanceManager.swift`

---

## 8. Key Implementation Details

### AVSpeechSynthesizer Usage

```swift
import AVFoundation

let synthesizer = AVSpeechSynthesizer()
let utterance = AVSpeechUtterance(string: "你好世界")
utterance.voice = AVSpeechSynthesisVoice(language: "zh_CN")
utterance.rate = 0.5  // Slower for clarity (default: 0.5)
utterance.pitch = 1.0
utterance.volume = 0.8
synthesizer.speak(utterance)
```

### Chinese Voice Support on macOS 14+

```swift
// Available voices
AVSpeechSynthesisVoice(language: "zh_CN")  // Simplified Chinese
// Voice identifiers:
// - "com.apple.speech.synthesis.voice.Siyi"
// - "com.apple.speech.synthesis.voice.Tingting"
// - "com.apple.speech.synthesis.voice.Zhen"
```

### Timing Constraints

| Timing | Value | Usage |
|--------|-------|-------|
| Max instruction length | 150 chars (~20s speech) | Chinese: 向上看，保持3秒 (~2s) |
| Min inter-instruction gap | 0.5s | Avoid overlap |
| Exercise transition | 0.5s | Brief pause |
| Total session duration | ~2.5 min | 38 instructions × ~2-4s each |

### UserDefaults Integration

```swift
// Should store:
UserDefaults.standard.bool(forKey: "ttsEnabled")       // User toggle
UserDefaults.standard.float(forKey: "ttsVolume")       // 0.0–1.0
UserDefaults.standard.float(forKey: "ttsSpeechRate")   // 0.5–2.0
UserDefaults.standard.string(forKey: "ttsLanguage")    // "zh_CN" or "en_US"
```

---

## 9. Integration Timeline & Touch Points

### Where TTS Can Be Triggered

#### 1. **Session Introduction** (ExerciseSessionView ~119)
```
"👋 眼保健操时间到！"  →  TTS: "眼保健操时间到"
```

#### 2. **Each Exercise Start** (ExerciseSessionView currentExerciseIndex changes)
```
"Look Around / 上下左右看"  →  TTS: "上下左右看, 看向上方，保持3秒"
```

#### 3. **Each Instruction Step** (currentStep updates)
- Triggered via `onChange(of: currentStep)` in ExerciseView
- 38+ total instruction steps across all exercises
- Example: "Look down and hold for 3 seconds" → TTS

#### 4. **Session Completion** (sessionPhase = .completed)
```
"完成！" →  TTS: "眼保健操已完成，非常棒！"
```

### Callback Chain

```swift
// Timer tick (every 1 second)
Timer → remainingSeconds -= 1

// ExerciseView animation loop (every 0.05–3s depending on exercise)
updateAnimation() → currentStep = calculated_index

// Binding observer in ExerciseSessionView
@onChange(of: remainingSeconds) {
    updateMascotPupil()
    // ADD HERE: textToSpeech.speak(instruction: currentExercise.instructionsChinese[currentStep])
}
```

---

## 10. Critical Considerations

### ✅ Strengths of Current Architecture

1. **MainActor already applied** → Thread-safe TTS calls
2. **Dual text (English + Chinese)** → Already structured for TTS
3. **Clean timing** → Instructions sync with exercise phases
4. **UserDefaults pattern established** → Store TTS preferences
5. **Protocol-based sound** → Easy to add TTS protocol
6. **macOS 14+ minimum** → AVSpeechSynthesizer always available
7. **Isolated audio layer** → SoundManager is single source of truth

### ⚠️ Challenges & Edge Cases

1. **Audio overlap:** TTS takes 1-4 seconds; instructions change every 3-5 seconds
   - **Solution:** Cancel previous utterance before speaking new one
   
2. **Rapid skipping:** User can skip exercises; TTS might be mid-utterance
   - **Solution:** Implement `synthesizer.stopSpeaking()` in skip handlers
   
3. **Accessibility toggle:** Some users might not want TTS
   - **Solution:** Add `ttsEnabled` boolean to UserDefaults
   
4. **Non-blocking UI:** TTS must not freeze exercise animations
   - **Solution:** Delegate to AVSpeechSynthesizerDelegate for callbacks (already non-blocking)
   
5. **Volume mixing:** Both sound effects and TTS playing
   - **Solution:** Consider audio session categories (e.g., `defaultToSpeaker`)
   
6. **Localization:** Current code has English + Chinese; avoid hardcoding language
   - **Solution:** Use `Locale` and `AVSpeechSynthesisVoice.speechVoices`

### ⚠️ Performance Notes

- **AVSpeechSynthesizer:** Lightweight, hardware-accelerated on macOS
- **Memory:** ~2-3 MB per synthesizer instance (singleton fine)
- **CPU:** <5% during speech synthesis
- **Battery:** Minimal impact on macOS (not mobile)

---

## 11. Code Insertion Points (No Changes Made)

### File: SoundManager.swift

**Suggested additions (NOT IMPLEMENTED):**

```swift
// After line 4: import os
+ import AVFoundation  // Already there
+ private var speechSynthesizer: AVSpeechSynthesizer?

// New property after line 88
+ var isTTSEnabled: Bool {
+     get { UserDefaults.standard.bool(forKey: "ttsEnabled") }
+     set { UserDefaults.standard.set(newValue, forKey: "ttsEnabled") }
+ }

// New method in public API section (after line 155)
+ func speak(_ text: String, language: String = "zh_CN") {
+     guard isTTSEnabled, !isMuted else { return }
+     // Implementation here
+ }

// New method in system sound section (after line 172)
+ private func initializeSpeechSynthesizer() {
+     // Lazy initialization
+ }
```

### File: ExerciseSessionView.swift

**Suggested call site (NOT IMPLEMENTED):**

```swift
// Around line 276-278 in mascotExerciseView
.onChange(of: remainingSeconds) {
    updateMascotPupil()
+   // Speak current instruction (Chinese)
+   if let instruction = currentExercise.instructionsChinese[safe: currentStep] {
+       SoundManager.shared.speak(instruction, language: "zh_CN")
+   }
}
```

---

## 12. Summary: What Needs Implementation

### Must Add

1. **Import statement** in SoundManager.swift:
   ```swift
   import AVSpeechSynthesizer  // Or already via AVFoundation
   ```

2. **AVSpeechSynthesizer instance** (lazy or initialization):
   ```swift
   private var speechSynthesizer: AVSpeechSynthesizer?
   ```

3. **speak() method** in SoundManager or new manager:
   ```swift
   func speak(_ text: String, language: String)
   ```

4. **Cancel previous** utility:
   ```swift
   func stopSpeaking()
   ```

5. **UserDefaults preference**:
   ```swift
   var isTTSEnabled: Bool { get set }
   ```

### Should Add

6. **Exercise start callback** in ExerciseSessionView
7. **Step change callback** in ExerciseView
8. **Session completion speech** in ExerciseSessionView
9. **Preferences UI toggle** for TTS on/off
10. **Speech rate slider** in preferences (0.5–2.0)
11. **Language selection** (zh_CN vs en_US)

### Could Add (Enhancement)

12. Pre-recording quality Chinese voices
13. Speech completion callbacks for UI feedback
14. Interrupt detection (user speaks over TTS)
15. Metrics tracking (time-to-speech, clarity ratings)

---

## 13. File-by-File Checklist

| File | Status | Changes Needed | Priority |
|------|--------|----------------|----------|
| Package.swift | ✅ OK | None (AVFoundation available) | — |
| SoundManager.swift | ⚠️ Partial | Add TTS methods | HIGH |
| SoundPlaying.swift | ⚠️ Partial | Add TTS protocol methods | HIGH |
| ExerciseSessionView.swift | ✅ Trigger points | Add speak() callbacks | HIGH |
| ExerciseView.swift | ✅ Instruction display | Add speak() callbacks | MEDIUM |
| EyeExercise.swift | ✅ Ready | No changes needed | — |
| Preferences UI | ❌ Missing | Add TTS toggle/rate slider | MEDIUM |

---

## Appendix: Reference Resources

### macOS Speech Synthesis Documentation
- AVSpeechSynthesizer: Framework reference
- Chinese voice support: Requires macOS 10.7+, macOS 14+ for multiple voices
- Voice identifiers: Available via `AVSpeechSynthesisVoice.speechVoices(for: Locale)`

### Project References
- Exercise timing: EyeExercise.swift lines 49–58
- Instructions: EyeExercise.swift lines 72–127 & 130–185
- Session flow: ExerciseSessionView.swift lines 387–437
- Sound API: SoundPlaying.swift protocol
