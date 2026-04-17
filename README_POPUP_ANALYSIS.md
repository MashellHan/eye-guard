# Eye-Guard Reminder/Break Popup - Complete Analysis

## 📋 Overview

This directory contains three comprehensive documents analyzing the Eye-Guard macOS application's reminder and break popup implementation:

### 1. **EYE_GUARD_POPUP_ANALYSIS.md** (1190 lines)
   - **Complete technical deep-dive** with source code references
   - Explains how breaks are triggered, escalated, and dismissed
   - Contains detailed code snippets from every relevant file
   - Covers timer logic, window management, and potential issues
   - Best for: Understanding the full system architecture

### 2. **POPUP_FLOW_DIAGRAMS.md** (340 lines)
   - **Visual ASCII flow diagrams** showing the complete system
   - Break trigger flow from timer to notification
   - 3-tier escalation timeline and transitions
   - Countdown timer lifecycle for both Tier 2 and Tier 3
   - Early close scenarios and edge cases
   - State management relationships
   - Best for: Visual understanding of the system flow

### 3. **QUICK_REFERENCE.md** (280 lines)
   - **Fast lookup reference guide**
   - File locations and purposes
   - Key constants and timing values
   - Step-by-step trigger chain
   - NSWindow configuration parameters
   - Dismissal paths and potential issues
   - Testing commands and logging setup
   - Best for: Quick lookups during development

---

## 🎯 Quick Start

**I need to understand how the popup gets triggered:**
→ Read: POPUP_FLOW_DIAGRAMS.md → Section 1 (Break Trigger Flow)

**I need to know why the popup closes too quickly:**
→ Read: EYE_GUARD_POPUP_ANALYSIS.md → Part 5 (Dismiss/Close Logic)

**I need to find the timer code:**
→ Read: QUICK_REFERENCE.md → NSWindow Configuration or check code at:
   - `Sources/Notifications/BreakOverlayView.swift` (Tier 2 timer)
   - `Sources/Notifications/FullScreenOverlayView.swift` (Tier 3 timer)

**I need to debug the escalation system:**
→ Read: POPUP_FLOW_DIAGRAMS.md → Section 4 (Escalation Timeout)

---

## 🔑 Key Files

### Notification System (Sources/Notifications/)
- **NotificationManager.swift** — 3-tier escalation orchestrator
- **OverlayWindow.swift** — NSWindow management for Tier 2 & 3
- **BreakOverlayView.swift** — SwiftUI UI for Tier 2 popup (340×300 floating)
- **FullScreenOverlayView.swift** — SwiftUI UI for Tier 3 (full-screen)

### Scheduling System (Sources/Scheduling/)
- **BreakScheduler.swift** — 1-second timer loop, break due detection
- **BreakType.swift** — Enum: micro (20m), macro (60m), mandatory (120m)

### Configuration (Sources/Utils/)
- **Constants.swift** — All timing values, intervals, durations

---

## ⏱️ Key Timing

| What | Duration | What | Duration |
|------|----------|------|----------|
| **Break Intervals** | | **Break Durations** | |
| Micro | 20 min | Micro | 20 sec |
| Macro | 60 min | Macro | 5 min |
| Mandatory | 120 min | Mandatory | 15 min |
| **Escalation Delays** | | **UI Animations** | |
| Tier 1→2 | 2 min | Fade-in | 0.3 sec |
| Tier 2→3 | 5 min | Fade-out | 0.3 sec |
| Tier 3 max | 15+10 min* | | |

*Max 2×5-min extensions for mandatory breaks

---

## 🔄 Notification Tiers

### Tier 1: System Notification (Immediate)
- Standard macOS notification banner
- Dismissible by user
- Has sound alert

### Tier 2: Floating Overlay (After 2 min)
- Appears in top-right corner (340×300)
- Semi-transparent frosted glass
- User can drag, take break, skip, or start exercises
- Countdown timer when "Take Break" clicked
- Dismisses after 5 minutes if ignored

### Tier 3: Full-Screen Overlay (After 7 min total, mandatory only)
- Covers entire screen(s)
- Cannot be ignored easily
- 15-minute countdown (can extend 2×5 min)
- Requires explicit action to dismiss

---

## 🎯 How to Find Code

### "How does the timer start?"
```
BreakOverlayView.swift line 235-239
→ startBreak() function
→ startCountdownTimer() method
```

### "How long does the popup stay visible?"
```
Constants.swift:
- microBreakDuration = 20 seconds
- macroBreakDuration = 5 minutes (300s)
- mandatoryBreakDuration = 15 minutes (900s)

tier2EscalationDelay = 5 minutes (timeout if ignored)
```

### "How is the window created?"
```
OverlayWindow.swift line 71-100 (Tier 2)
OverlayWindow.swift line 135-172 (Tier 3)
→ NSWindow initialization
→ NSWindow properties configuration
```

### "How does the popup dismiss?"
```
OverlayWindow.swift line 175-189 (dismiss method with animation)
OverlayWindow.swift line 216-218 (dismissImmediate without animation)

BreakOverlayView.swift line 269-273 (completeBreak callback)
```

---

## 🚨 Known Edge Cases

### 1. Popup closes immediately after showing
- **Cause:** Another popup replaces it via `dismissImmediate()`
- **Found in:** OverlayWindow.swift lines 52-55
- **When:** New break becomes due while showing previous break

### 2. Timer appears frozen but popup still visible
- **Cause:** `onDisappear` stops timer before completion
- **Found in:** BreakOverlayView.swift lines 80-82
- **Fix:** Keep the view alive or pause timer instead of stopping

### 3. Full-screen overlay doesn't appear on all monitors
- **Cause:** NSScreen.screens might be empty
- **Found in:** OverlayWindow.swift lines 116-120
- **Fix:** Guard check already in place

### 4. Escalation continues even after user action
- **Cause:** escalationTask not cancelled in time
- **Found in:** NotificationManager.swift lines 86-122
- **Fix:** cancelEscalation() should be called immediately

### 5. Callback invoked multiple times
- **Cause:** No guard against duplicate invocations
- **Found in:** NotificationManager.swift lines 127-138
- **Fix:** Check `isNotificationActive` flag

---

## 📊 State Diagram

```
APP LAUNCH
    ↓
BreakScheduler.init()
    ├─ startTimerLoop() ← Async Task running forever
    └─ loadPersistedData()
         ↓
TIMER LOOP (every 1 second)
    ↓
tick() function
    ├─ Update session duration
    ├─ Update per-type elapsed times
    ├─ checkForDueBreaks()
    │   ↓ Break due?
    │   ↓ YES → triggerBreakNotification()
    │
    └─ [Heavy work every 5-60 seconds]
         ↓
NotificationManager.notify()
    ├─ Store callbacks
    ├─ Show Tier 1 (immediate)
    ├─ Start escalationTask
    │   ├─ Wait 2 min → Show Tier 2
    │   ├─ Wait 5 min → Show Tier 3 (if mandatory)
    │   └─ Wait 5 min → Timeout if no action
    │
    └─ User interaction
         ├─ Click "Take Break" → Start countdown
         ├─ Countdown reaches 0 → Dismiss + callback
         ├─ Click "Skip" → Dismiss + callback
         └─ 5 min timeout → Auto-dismiss + callback
              ↓
         BreakScheduler.takeBreakNow() or skipBreak()
              ↓
         Reset timers, record break, recalculate health score
              ↓
         Next break cycle begins
```

---

## 🧪 Testing Helpers

### Run All Tests
```bash
cd /Users/mengxionghan/.superset/projects/Tmp/eye-guard
swift test
```

### Run Specific Test Suite
```bash
swift test --filter OverlayWindowControllerTests
swift test --filter BreakSchedulerTests
```

### View Debug Logs
```bash
log stream --predicate 'process == "EyeGuard"' --level debug
```

### Key Test Files
- `Tests/OverlayWindowTests.swift` — Window creation/dismissal (9 tests)
- `Tests/BreakSchedulerTests.swift` — Timing and triggers
- `Tests/NotificationManagerTests.swift` — 3-tier escalation

---

## 📖 Document Structure

### EYE_GUARD_POPUP_ANALYSIS.md

1. **Project Overview** - Architecture
2. **Part 1** - How breaks are triggered (BreakScheduler)
3. **Part 2** - 3-Tier notification system
4. **Part 3** - Popup window implementation (NSWindow + SwiftUI)
5. **Part 4** - Timer logic (countdown mechanisms)
6. **Part 5** - Dismiss/close logic & edge cases
7. **Part 6** - Project structure summary
8. **Part 7** - Testing infrastructure
9. **Summary table** - Quick reference

### POPUP_FLOW_DIAGRAMS.md

1. **Break Trigger Flow** - Timer → Notification
2. **3-Tier Escalation** - Visual flow of all tiers
3. **Popup Countdown Lifecycle** - Tier 2 & Tier 3 timer
4. **Escalation Timeout** - No user action scenario
5. **Window Dismissal Animation** - Fade out process
6. **Early Close Scenarios** - 5 edge cases
7. **State Management Flow** - Component relationships

### QUICK_REFERENCE.md

1. **File Locations** - Where to find code
2. **Constants & Timing** - All timing values
3. **Trigger Chain** - Step-by-step execution
4. **NSWindow Configuration** - Tier 2 & 3 properties
5. **SwiftUI Timer Implementations** - Code snippets
6. **Dismissal Paths** - 4 ways popup closes
7. **Potential Issues & Fixes** - 5 problems + solutions
8. **Testing Commands** - How to run tests
9. **Logging** - How to enable debug logs
10. **Key Data Structures** - State definitions

---

## 🔗 Cross-References

### To understand "Why doesn't the popup stay visible?"
1. Read: POPUP_FLOW_DIAGRAMS.md § 6 "Early Close Scenarios"
2. Then: EYE_GUARD_POPUP_ANALYSIS.md § Part 5 "Potential Issues"
3. Check: QUICK_REFERENCE.md § "Issue 1-5"

### To modify break intervals
1. Edit: Constants.swift (microBreakInterval, etc.)
2. Or: UserPreferencesManager.swift (user-facing settings)
3. Test: BreakSchedulerTests.swift

### To change popup appearance
1. Edit: BreakOverlayView.swift (Tier 2 UI)
2. Or: FullScreenOverlayView.swift (Tier 3 UI)
3. Configure: OverlayWindow.swift (NSWindow properties)

---

## ✅ Verification Checklist

- [ ] Understand how BreakScheduler timer works
- [ ] Understand 3-tier escalation system
- [ ] Know the difference between Tier 2 and Tier 3
- [ ] Can trace the path from break-due to popup shown
- [ ] Understand why popup might close early
- [ ] Know how to run tests
- [ ] Can enable debug logging
- [ ] Understand NSWindow vs SwiftUI responsibilities
- [ ] Know timer lifecycle (start → count → complete)
- [ ] Understand callback system (onTaken/onSkipped)

---

## 📞 Quick Contact Points

**Q: Break isn't triggering?**
→ Check: BreakScheduler.tick() → checkForDueBreaks() → lastNotifiedCycle

**Q: Popup appears but closes too fast?**
→ Check: NotificationManager escalationTask → handleEscalationTimeout()

**Q: Countdown timer not working?**
→ Check: BreakOverlayView.startCountdownTimer() → Timer.invalidate()

**Q: Window not appearing?**
→ Check: OverlayWindow.makeKeyAndOrderFront(nil) → NSWindow.level

**Q: Callbacks not firing?**
→ Check: NotificationManager.onTakenCallback → invokeCallbacks properly

---

**Last Updated:** 2026-04-15  
**Project:** Eye-Guard (macOS)  
**Analysis by:** Code Exploration System
