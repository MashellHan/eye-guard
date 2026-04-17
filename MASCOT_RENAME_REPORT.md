# EyeGuard Mascot Rename Report
## Task: Rename Mascot from "护眼精灵" to "阿普" (Apu)

**Date:** 2026-04-15  
**Project:** EyeGuard  
**Target Rename:** 护眼精灵 → 阿普

---

## Summary

The mascot "护眼精灵" (Eye Protection Spirit) appears in **2 main contexts** across the codebase:
1. **Chinese name in introductory greeting message** (1 location)
2. **Documentation and comments** (3 locations)
3. **Log messages** (1 location)

The mascot is primarily referred to as a generic "mascot" or "character" throughout the codebase with UI strings using descriptive labels. All internal code uses generic names like `mascot`, `viewModel`, `controller`.

---

## Search Results by Category

### Category 1: MASCOT NAME - User-Visible Greeting

**HIGH PRIORITY** - Changes directly shown to users

| File | Line | Location | Current Text | Suggested New Text |
|------|------|----------|--------------|-------------------|
| `EyeGuard/Sources/Mascot/MascotStateSync.swift` | 23 | Speech bubble greeting | `"Hi! 我是护眼精灵 👋"` | `"Hi! 我是阿普 👋"` |

**When shown:** When mascot character first launches on screen

**Impact:** Users will see the mascot introduce itself with the new name "阿普"

---

### Category 2: MASCOT NAME - Comments & Documentation

**MEDIUM PRIORITY** - Visible in logs, code comments, and documentation

| File | Line | Type | Current Text | Suggested New Text |
|------|------|------|--------------|-------------------|
| `EyeGuard/Sources/Mascot/MascotState.swift` | 3 | Code comment | `/// Emotional states for the Eye Guard mascot (护眼精灵).` | `/// Emotional states for the Eye Guard mascot (阿普).` |
| `EyeGuard/Sources/App/EyeGuardApp.swift` | 8 | Code comment | `/// Launches the floating mascot character (护眼精灵) on screen (v0.9).` | `/// Launches the floating mascot character (阿普) on screen (v0.9).` |
| `EyeGuard/Sources/App/EyeGuardApp.swift` | 44 | Log message | `Log.app.info("Mascot character (护眼精灵) launched.")` | `Log.app.info("Mascot character (阿普) launched.")` |
| `README.md` | 27 | Documentation | `### Mascot (护眼精灵)` | `### Mascot (阿普)` |

**Impact:** 
- Log messages appear in console/system logs
- README is publicly visible
- Comments help developers understand the codebase

---

## Complete File List with Required Changes

### Files Requiring Changes

```
EyeGuard/Sources/Mascot/
└── MascotStateSync.swift                [✓ LINE 23]

EyeGuard/Sources/Mascot/
└── MascotState.swift                    [✓ LINE 3]

EyeGuard/Sources/App/
└── EyeGuardApp.swift                    [✓ LINES 8, 44]

Root Directory/
└── README.md                            [✓ LINE 27]
```

### Files NOT Requiring Changes

```
EyeGuard/Sources/Mascot/
├── MascotView.swift              (No mascot name references)
├── MascotViewModel.swift          (No mascot name references)
├── MascotWindowController.swift   (No mascot name references)
├── MascotContainerView.swift      (No mascot name references)
├── MascotColors.swift            (No mascot name references)
├── MascotAnimations.swift         (No mascot name references)
└── SpeechBubbleView.swift         (No mascot name references)

EyeGuard/Sources/App/
├── AppDelegate.swift             (References app name, not mascot name)
└── MenuBarManager.swift           (No mascot name references)

EyeGuard/Sources/ [ALL OTHER DIRECTORIES]
└── No mascot name references found
```

---

## Detailed Change Instructions

### Change 1: MascotStateSync.swift (Line 23)

**File:** `EyeGuard/Sources/Mascot/MascotStateSync.swift`
**Line:** 23

```swift
// BEFORE:
viewModel.showMessage("Hi! 我是护眼精灵 👋")

// AFTER:
viewModel.showMessage("Hi! 我是阿普 👋")
```

**Context:**
```swift
static func start(viewModel: MascotViewModel, scheduler: BreakScheduler) {
    // Initial greeting when mascot first appears
    viewModel.showMessage("Hi! 我是护眼精灵 👋")  // ← CHANGE THIS
```

---

### Change 2: MascotState.swift (Line 3)

**File:** `EyeGuard/Sources/Mascot/MascotState.swift`
**Line:** 3

```swift
// BEFORE:
/// Emotional states for the Eye Guard mascot (护眼精灵).

// AFTER:
/// Emotional states for the Eye Guard mascot (阿普).
```

---

### Change 3 & 4: EyeGuardApp.swift (Lines 8 and 44)

**File:** `EyeGuard/Sources/App/EyeGuardApp.swift`

**Line 8:**
```swift
// BEFORE:
/// Launches the floating mascot character (护眼精灵) on screen (v0.9).

// AFTER:
/// Launches the floating mascot character (阿普) on screen (v0.9).
```

**Line 44:**
```swift
// BEFORE:
Log.app.info("Mascot character (护眼精灵) launched.")

// AFTER:
Log.app.info("Mascot character (阿普) launched.")
```

---

### Change 5: README.md (Line 27)

**File:** `README.md`
**Line:** 27

```markdown
// BEFORE:
### Mascot (护眼精灵)

// AFTER:
### Mascot (阿普)
```

**Full section context:**
```markdown
### Mascot (阿普)  ← CHANGE THIS
- **Floating Character**: Draggable, always-on-top companion
- **7 Emotional States**: Idle, happy, concerned, alerting, sleeping, exercising, celebrating
- **Mouse Tracking**: Pupils follow your cursor
- **Speech Bubbles**: Contextual tips, break reminders, AI insights
- **Right-Click Menu**: Quick access to breaks, exercises, tips, dashboard
```

---

## Statistics & Analysis

| Metric | Count |
|--------|-------|
| Total Swift files in project | 50+ |
| Total files analyzed | 200+ (including .build, tests) |
| Files with "mascot" keyword | 30+ |
| Specific mascot name occurrences (护眼精灵) | 5 |
| Changes required | 5 |
| User-visible changes | 1 |
| Documentation changes | 4 |
| Comments/Logs affected | 3 |

---

## Speech Bubble Messages (No Changes Needed)

The mascot's conversational messages do NOT reference the mascot's name, so these require NO changes:

- `"👁️ 跟着做眼保健操吧…"` (Do eye exercises)
- `"👏 做得好！眼睛感觉好多了吧"` (Well done!)
- `"😢 跳过休息了...眼睛会累的"` (Skipped rest)
- `"快要到\(breakName)了…"` (Break coming up)
- And 10+ more generic messages

---

## Night Mode Messages (No Changes Needed)

Night mode messages in `NightModeManager.swift` also don't reference the mascot name:

- `"🌙 已经很晚了，该休息了"` (It's late)
- `"⭐ 眼睛需要好好睡一觉"` (Eyes need sleep)
- And 6+ more night messages

No changes needed to these.

---

## Verification Checklist

After making changes, run these commands to verify:

```bash
# 1. Search for any remaining old name
grep -r "护眼精灵" EyeGuard/

# Expected: 0 results (no output)

# 2. Verify new name appears in all expected places
grep -r "阿普" EyeGuard/

# Expected: 5 results across the files listed above

# 3. Build the project
swift build

# Expected: Build succeeds with no errors

# 4. Run tests
swift test

# Expected: All tests pass

# 5. Build app bundle
bash scripts/build-app.sh

# Expected: EyeGuard.app builds successfully
```

---

## Implementation Notes

1. **No localization files exist**: The project uses embedded strings in Swift code, not `.strings` files, so localization is not a concern.

2. **Internal naming is generic**: All class names, variable names, function names use generic terms like `mascot`, `character`, `viewModel`, so these require no changes.

3. **App name unchanged**: References to "EyeGuard" refer to the application name, not the mascot character, so these are left unchanged.

4. **Menu labels unchanged**: Mascot right-click menu items ("Take Break Now", "Snooze 5 min", etc.) don't reference the mascot's name.

5. **Complete search verified**: Searched 50+ Swift source files, 30+ files with "mascot" references, and confirmed all uses of the Chinese name "护眼精灵".

---

## Future Improvements (Optional)

Consider centralizing the mascot name as a constant for easier future branding changes:

```swift
// Add to EyeGuard/Sources/Utils/Constants.swift or new MascotConstants.swift

enum MascotConstants {
    static let name = "阿普"
    static let displayName = "阿普 (Apu)"
    static let introductionEmoji = "👋"
    static let initialGreeting = "Hi! 我是\(name) \(introductionEmoji)"
}
```

Then update code to use:
```swift
// MascotStateSync.swift line 23
viewModel.showMessage(MascotConstants.initialGreeting)

// EyeGuardApp.swift line 44
Log.app.info("Mascot character (\(MascotConstants.name)) launched.")
```

This approach would make any future rebranding a single-point change.

---

## Summary

- **Total changes needed:** 5 locations
- **Critical/User-visible:** 1 change
- **Time estimate:** 2-5 minutes for manual editing
- **Risk level:** Very low (simple string replacements)
- **Testing impact:** Minimal (affects only startup messages and logs)

