# EyeGuard Chinese TTS — Quick Reference

## ⚡ At a Glance

| Item | Value | Status |
|------|-------|--------|
| **Framework** | AVSpeechSynthesizer (AVFoundation) | ✅ Available |
| **Chinese Support** | zh_CN (Simplified) | ✅ macOS 14+ |
| **Current TTS Code** | None | ❌ Missing |
| **Audio Manager** | SoundManager.swift | ✅ Ready |
| **Text Content** | English + Chinese | ✅ Ready (38+ lines) |
| **Timing** | ~2.5 min session | ✅ Structured |
| **Minimum Effort** | ~100 lines | 📊 Option A |

---

## 🎯 What's Ready

✅ **SoundManager** — Audio layer exists, @MainActor, UserDefaults pattern  
✅ **Exercise instructions** — 38+ bilingual strings in EyeExercise.swift  
✅ **Session timing** — Clear phases (intro → exercising → completed)  
✅ **Trigger points** — `currentStep` and `remainingSeconds` binding  
✅ **macOS 14+ guarantee** — Minimum deployment target  
✅ **Chinese voices** — Multiple system voices available  

---

## 🔧 What's Missing

❌ **AVSpeechSynthesizer import** — Need to import/use in SoundManager  
❌ **speak() method** — Core TTS function  
❌ **TTS toggle preference** — User on/off control  
❌ **stopSpeaking() utility** — Cancel mid-speech  
❌ **Integration callbacks** — In ExerciseSessionView & ExerciseView  
❌ **Preferences UI** — Toggle and rate slider  

---

## 📝 Code Summary

### Current Audio Architecture
```
SoundManager (@MainActor, Singleton)
├── SoundType: breakStart, breakComplete, tipRotation, alert, ambient
├── AmbientPreset: rain, ocean, forest, wind, silence
├── Volume: UserDefaults
├── Muted: UserDefaults
└── play(), startAmbient(), stopAmbient()
```

### Exercise Data (Ready to Speak)
```
EyeExercise (enum, 5 types)
├── lookAround (40s, 9 steps)
├── nearFar (30s, 6 steps)
├── circularMotion (30s, 6 steps)
├── palmWarming (30s, 6 steps)
└── rapidBlink (20s, 6 steps)

Each has:
✅ .name (English)
✅ .chineseName (Chinese)
✅ .instructions[] (English)
✅ .instructionsChinese[] (Chinese)
✅ .duration (seconds)
```

### Session Flow (Trigger Points)
```
ExerciseSessionView
├── sessionPhase: .intro → .exercising → .completed
├── currentExerciseIndex: 0–4
├── currentStep: 0–8 (per exercise)
├── remainingSeconds: countdown timer
└── onChange(of: remainingSeconds) { ← TTS TRIGGER HERE
    updateMascotPupil()
}
```

---

## 🚀 Recommended Implementation (Option A)

### Step 1: Extend SoundManager (~60 lines)

**Add to SoundManager.swift:**

```swift
// After line 4: (AVFoundation already imported ✓)

// Add new property after line 100
private var speechSynthesizer: AVSpeechSynthesizer?

// Add after line 88 (isMuted property)
var isTTSEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: "ttsEnabled") }
    set { UserDefaults.standard.set(newValue, forKey: "ttsEnabled") }
}

// Add public method after line 155
func speak(_ text: String, language: String = "zh_CN") {
    guard isTTSEnabled, !isMuted else { return }
    
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    utterance.volume = volume
    
    if speechSynthesizer == nil {
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
    speechSynthesizer?.speak(utterance)
    Log.sound.info("Speaking: \(text.prefix(30))...")
}

// Add public method after speak()
func stopSpeaking() {
    speechSynthesizer?.stopSpeaking(at: .immediate)
}
```

### Step 2: Update SoundPlaying Protocol (~5 lines)

**Add to SoundPlaying.swift:**

```swift
/// Speaks text in the given language using text-to-speech.
func speak(_ text: String, language: String)

/// Stops any ongoing speech synthesis.
func stopSpeaking()

/// Whether TTS is enabled in preferences.
var isTTSEnabled: Bool { get set }
```

### Step 3: Add TTS Callbacks in ExerciseSessionView (~10 lines)

**Around line 276 in ExerciseSessionView.swift:**

```swift
.onChange(of: remainingSeconds) {
    updateMascotPupil()
    
    // Speak current instruction (Chinese)
    let instruction = currentExercise.instructionsChinese
    if currentStep < instruction.count {
        SoundManager.shared.speak(instruction[currentStep], language: "zh_CN")
    }
}
```

### Step 4: Add Preferences Toggle (~20 lines)

**In PreferencesView.swift, add new section:**

```swift
Section("Voice Guidance / 语音指导") {
    Toggle("Enable TTS", isOn: Binding(
        get: { SoundManager.shared.isTTSEnabled },
        set: { SoundManager.shared.isTTSEnabled = $0 }
    ))
    
    Slider(value: Binding(
        get: { CGFloat(SoundManager.shared.volume) },
        set: { SoundManager.shared.volume = Float($0) }
    ), in: 0...1)
    .disabled(!SoundManager.shared.isTTSEnabled)
}
```

---

## ⚠️ Important Notes

1. **Audio Overlap:** If instruction takes 3 seconds but next triggers at 3 seconds, call `stopSpeaking()` first
2. **Skip Handling:** Add `SoundManager.shared.stopSpeaking()` to `skipCurrentExercise()` and `completeSession()`
3. **Initialization:** Lazy-init speechSynthesizer (don't create until first speak)
4. **Language:** Default to "zh_CN"; can add user preference later
5. **Volume:** Reuse existing `SoundManager.volume` for consistency

---

## 📊 Testing Checklist

- [ ] Speak intro message ("眼保健操时间到")
- [ ] Speak each instruction as exercise progresses
- [ ] Cancel TTS when skipping exercise
- [ ] Cancel TTS when skipping session
- [ ] Speak completion message ("眼保健操已完成！")
- [ ] TTS disabled via preference toggle
- [ ] Volume slider affects TTS volume
- [ ] Multiple rapid skips don't crash (stopSpeaking safe)
- [ ] No audio overlap (one utterance at a time)
- [ ] Works after app restart (UserDefaults persisted)

---

## 📚 Files Affected

| File | Lines | Type | Change |
|------|-------|------|--------|
| SoundManager.swift | +60 | Implementation | Add TTS methods |
| SoundPlaying.swift | +3 | Protocol | Add TTS methods |
| ExerciseSessionView.swift | +5 | Integration | Trigger TTS |
| PreferencesView.swift | +20 | UI | TTS toggle |
| ExerciseView.swift | +2 | Integration | Optional: Step trigger |

**Total effort:** ~90 lines across 5 files

---

## 🎤 Chinese Voice Options

Available on macOS 14+:
- `com.apple.speech.synthesis.voice.Siyi` (Default female)
- `com.apple.speech.synthesis.voice.Tingting` (Alternative female)
- `com.apple.speech.synthesis.voice.Zhen` (Male)

Example:
```swift
utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Siyi")
```

---

## 🔍 Key Code Locations

| Purpose | File | Line(s) |
|---------|------|---------|
| Audio manager | SoundManager.swift | 1–291 |
| Audio protocol | SoundPlaying.swift | 1–34 |
| Exercise data | EyeExercise.swift | 72–185 (instructions) |
| Session loop | ExerciseSessionView.swift | 441–462 (timer), 276–278 (trigger) |
| Exercise display | ExerciseView.swift | 296–314 (instruction display) |

---

## 💡 Future Enhancements

- [ ] Speech rate adjustment (0.5–2.0) in preferences
- [ ] Language selection (zh_CN vs en_US)
- [ ] Accessibility: VoiceOver integration
- [ ] Analytics: Track TTS usage
- [ ] Pre-recording: Higher quality audio
- [ ] Pause/resume during exercise
- [ ] Custom voice pack download

