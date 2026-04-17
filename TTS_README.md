# EyeGuard Chinese TTS Implementation Guide

> **Complete analysis and implementation roadmap for adding Chinese text-to-speech voice guidance to EyeGuard exercise sessions**

**Status:** ✅ Analysis Complete | ❌ Implementation Not Started  
**Date:** April 15, 2026  
**Files Modified:** 0 (read-only analysis)

---

## 📋 Quick Links

1. **[TTS_QUICK_REFERENCE.md](TTS_QUICK_REFERENCE.md)** ← **START HERE** (7 KB)
   - At-a-glance overview
   - What's ready vs. what's missing
   - Recommended implementation (Option A)
   - Testing checklist

2. **[TTS_IMPLEMENTATION_ANALYSIS.md](TTS_IMPLEMENTATION_ANALYSIS.md)** (18 KB)
   - Comprehensive technical analysis
   - AVSpeechSynthesizer capabilities
   - SoundManager architecture review
   - Exercise timing breakdown
   - Integration points and edge cases

3. **[TTS_INTEGRATION_ARCHITECTURE.txt](TTS_INTEGRATION_ARCHITECTURE.txt)** (16 KB)
   - Visual state diagrams
   - Current vs. desired architecture
   - File-by-file change summary
   - Timing & sequence examples
   - Error handling scenarios

---

## 🎯 Executive Summary

### ✅ What's Ready

The EyeGuard project is **well-architected for Chinese TTS** with minimal changes needed:

- **Audio manager exists:** SoundManager.swift (291 lines, @MainActor, production-ready)
- **Chinese text available:** 38+ bilingual instruction strings already in EyeExercise.swift
- **Perfect timing:** Exercise phases align with TTS utterance timing (1-4 seconds per instruction)
- **Framework available:** AVSpeechSynthesizer on macOS 14+ with multiple Chinese voices
- **Pattern established:** UserDefaults for preferences, protocol-based design for testability
- **Trigger points identified:** `remainingSeconds` and `currentStep` bindings ready for TTS callbacks

### ❌ What's Missing

- **AVSpeechSynthesizer usage:** Not currently imported or used
- **speak() method:** Core TTS function doesn't exist
- **stopSpeaking() utility:** No speech cancellation mechanism
- **TTS toggle preference:** No user on/off control
- **Integration callbacks:** No calls to TTS from exercise views
- **Preferences UI:** No toggle or volume slider for TTS

### 📊 Implementation Effort

| Category | Effort | Files |
|----------|--------|-------|
| **Core TTS** | ~60 lines | SoundManager.swift |
| **Protocol update** | ~3 lines | SoundPlaying.swift |
| **Exercise integration** | ~10 lines | ExerciseSessionView.swift |
| **Preferences UI** | ~20 lines | PreferencesView.swift |
| **Testing** | ~2 hours | Manual QA |
| **TOTAL** | ~100 lines | 4 files |

---

## 🚀 Recommended Implementation (Option A)

### Step 1: Extend SoundManager (60 lines)

Add to **SoundManager.swift** after line 88:

```swift
// Add TTS support
private var speechSynthesizer: AVSpeechSynthesizer?

var isTTSEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: "ttsEnabled") }
    set { UserDefaults.standard.set(newValue, forKey: "ttsEnabled") }
}

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

func stopSpeaking() {
    speechSynthesizer?.stopSpeaking(at: .immediate)
}
```

### Step 2: Update SoundPlaying Protocol (3 lines)

Add to **SoundPlaying.swift**:

```swift
func speak(_ text: String, language: String)
func stopSpeaking()
var isTTSEnabled: Bool { get set }
```

### Step 3: Trigger TTS in ExerciseSessionView (10 lines)

Modify **ExerciseSessionView.swift** around line 276:

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

### Step 4: Add Preferences UI (20 lines)

Add to **PreferencesView.swift**:

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

## 🎯 Testing Checklist

- [ ] Intro screen speaks: "眼保健操时间到"
- [ ] Each exercise intro speaks: e.g., "上下左右看"
- [ ] Each instruction step speaks correctly
- [ ] Multiple rapid skips don't crash (calls stopSpeaking)
- [ ] Completion screen speaks: "眼保健操已完成！"
- [ ] TTS toggle in preferences works
- [ ] Volume slider affects TTS volume
- [ ] TTS disabled by preference respected
- [ ] App restart preserves TTS preference
- [ ] No audio overlap (one utterance at a time)

---

## 🔑 Key Implementation Details

### Chinese Voice Support

Available on macOS 14+:
- `zh_CN` language code
- Voice identifiers: `Siyi`, `Tingting`, `Zhen`
- Multiple female/male options

```swift
utterance.voice = AVSpeechSynthesisVoice(language: "zh_CN")
// or
utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Siyi")
```

### Timing Considerations

| Exercise | Duration | Steps | Avg Time/Step | Notes |
|----------|----------|-------|---------------|-------|
| lookAround | 40s | 9 | ~4–5s | TTS: 2s, gap: 2–3s |
| nearFar | 30s | 6 | ~5s | TTS: 2s, gap: 3s |
| circularMotion | 30s | 6 | ~5s | TTS: 1.5s, gap: 3.5s |
| palmWarming | 30s | 6 | ~5s | TTS: 2s, gap: 3s |
| rapidBlink | 20s | 6 | ~3–4s | TTS: 1.5s, gap: 1.5–2.5s |

**Total session:** ~2.5 minutes × 38 instructions = good fit

### Edge Cases Handled

1. **Audio overlap:** Call `stopSpeaking()` before starting new utterance
2. **Skip during speech:** `stopSpeaking()` cancels immediately
3. **Muted system:** Check `!isMuted` guard
4. **Disabled TTS:** Check `isTTSEnabled` guard
5. **Language fallback:** Already handled by AVSpeechSynthesisVoice

---

## 📚 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│ ExerciseSessionView (UI)                                            │
│                                                                     │
│  ├─ remainingSeconds: 30 → 29 → 28...  (Timer, 1s intervals)     │
│  │  └─ onChange → updateMascotPupil()                             │
│  │     └─ [NEW] SoundManager.speak(instructionsChinese[step])     │
│  │                                                                 │
│  ├─ currentExerciseIndex: 0–4                                     │
│  │  └─ [NEW] Speak exercise intro on change                       │
│  │                                                                 │
│  └─ currentStep: 0–8 per exercise                                 │
│     └─ [NEW] Trigger TTS on step change                           │
│                                                                     │
├─ EyeExercise (Data) ✓ Ready                                        │
│  ├─ instructions[]: English text                                   │
│  ├─ instructionsChinese[]: Chinese text ← SPEAK THIS              │
│  ├─ name / chineseName: Exercise names                            │
│  └─ duration: Exercise timing                                      │
│                                                                     │
└─ SoundManager (Audio) ← MODIFY HERE                                │
   ├─ play(SoundType): Existing sound effects                        │
   ├─ [NEW] speak(text, language): TTS synthesis                    │
   ├─ [NEW] stopSpeaking(): Cancel speech                            │
   └─ [NEW] isTTSEnabled: Preference toggle                          │
```

---

## 🔗 File References

### EyeExercise.swift (245 lines)
- **Lines 49–58:** Exercise durations
- **Lines 72–127:** English instructions (9 steps each)
- **Lines 130–185:** Chinese instructions (ready for TTS!)
- **Lines 39–46:** Chinese exercise names

### SoundManager.swift (291 lines)
- **Lines 1–23:** Class definition, imports
- **Lines 60–89:** State management (volume, muted, preset)
- **Lines 107–155:** Public API (play, startAmbient, stopAmbient)
- **← ADD HERE:** speak(), stopSpeaking(), isTTSEnabled

### ExerciseSessionView.swift (507 lines)
- **Lines 276–278:** onChange trigger for remainingSeconds
- **Lines 387–396:** startSession()
- **Lines 441–462:** Countdown timer logic
- **← INTEGRATE HERE:** TTS callbacks

### Package.swift (28 lines)
- **Line 8:** `.macOS(.v14)` ✓ Supports AVSpeechSynthesizer

---

## 💡 Future Enhancements

**Phase 2 (Optional):**
- [ ] Speech rate adjustment (0.5–2.0x)
- [ ] Language selection (zh_CN vs en_US)
- [ ] VoiceOver accessibility integration
- [ ] Pause/resume speech
- [ ] Speech completion callbacks for UI feedback
- [ ] Metrics: Track TTS usage patterns
- [ ] Higher-quality pre-recorded voices

---

## 🆘 Common Issues & Solutions

### Issue: "AVSpeechSynthesizer not found"
**Cause:** Not imported  
**Solution:** Already part of `AVFoundation` which is imported in SoundManager.swift

### Issue: "Chinese voice not available"
**Cause:** Older macOS version  
**Solution:** Project requires macOS 14+, which guarantees Chinese voice support

### Issue: "TTS and sound effects overlap"
**Cause:** Both play simultaneously  
**Solution:** Call `stopSpeaking()` before advancing exercise, use `isMuted` guard

### Issue: "TTS doesn't persist after app restart"
**Cause:** Not stored in UserDefaults  
**Solution:** Use `isTTSEnabled` property backed by UserDefaults

### Issue: "Accent/pitch sounds wrong"
**Cause:** Voice identifier or rate settings  
**Solution:** Test with different voice IDs (`Siyi`, `Tingting`, `Zhen`), adjust rate 0.5–1.5

---

## 📞 Questions?

Refer to the detailed analysis documents:
1. **Quick overview?** → [TTS_QUICK_REFERENCE.md](TTS_QUICK_REFERENCE.md)
2. **Full architecture?** → [TTS_INTEGRATION_ARCHITECTURE.txt](TTS_INTEGRATION_ARCHITECTURE.txt)
3. **Deep dive?** → [TTS_IMPLEMENTATION_ANALYSIS.md](TTS_IMPLEMENTATION_ANALYSIS.md)

---

## 📝 Document Index

| Document | Size | Focus | Read Time |
|----------|------|-------|-----------|
| TTS_README.md | This file | Overview & quick start | 5 min |
| TTS_QUICK_REFERENCE.md | 7 KB | Implementation checklist | 10 min |
| TTS_IMPLEMENTATION_ANALYSIS.md | 18 KB | Technical deep dive | 30 min |
| TTS_INTEGRATION_ARCHITECTURE.txt | 16 KB | Visual diagrams & state flows | 20 min |

---

**Total Analysis:** ~41 KB | **Implementation:** ~100 lines | **Effort:** 2–3 hours  
**Difficulty:** ⭐⭐ (Moderate — straightforward TTS integration, clean codebase)  
**Risk:** ⭐ (Low — isolated to SoundManager, protocol-based design, well-tested framework)

---

*Generated: April 15, 2026*  
*EyeGuard macOS Project — Simplified Chinese TTS Voice Guidance*  
*No files modified. Analysis only.*
