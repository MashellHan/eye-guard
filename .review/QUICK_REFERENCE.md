# Quick Reference: Popup Flash Bug Investigation

## 📌 One-Line Summary
**Break overlay popup disappears after ~1 second because `handleIdleDetected()` doesn't check `isNotificationActive` before resetting scheduler state.**

---

## 🔴 PRIMARY BUG (95% Certain)

```
File: EyeGuard/Sources/Scheduling/BreakScheduler.swift
Lines: 248-257 + 261-270

Problem: Two methods DON'T check NotificationManager.isNotificationActive

  ❌ handleIdleDetected() [Line 248]
     → Calls resetTimersAfterBreak() even during active popup
  
  ❌ handleActivityResumed() [Line 261]
     → Calls session reset even during active popup

Result: State desynchronization
  • Scheduler thinks: "break already taken"
  • UI thinks: "countdown still running"
  • Popup disappears (dismissed or hidden)
```

## 🟠 SECONDARY BUG (70% Certain)

```
File: EyeGuard/Sources/Notifications/OverlayWindow.swift
Line: 179

Problem: Window uses CGShieldingWindowLevel
  → No protection against being obscured by system windows
  → Popup gets hidden behind notification center, security prompts, etc.
```

## 🟡 TERTIARY BUG (40% Certain)

```
File: EyeGuard/Sources/Notifications/OverlayWindow.swift [170-178]
      EyeGuard/Sources/Notifications/FullScreenOverlayView.swift [196-210]

Problem: SwiftUI state invalidation
  → If scheduler state reset propagates, view tree might be torn down
  → onDisappear called → timer stopped → window vanishes
```

---

## ⏱️ Why ~1 Second?

```
T+0.0s   Popup fade-in starts (0.5s animation)
T+0.5s   Animation complete, user stops moving mouse
T+1.0s   Idle poll fires → handleIdleDetected() → state reset
         OR system window pops up at same layer
T+1.0s   To user: popup appeared for ~1 second, then gone
```

---

## 🧬 Exact Code Locations

| # | Bug | File | Lines | Fix |
|---|-----|------|-------|-----|
| 1 | Missing guard | BreakScheduler | 248-257 | Add `isNotificationActive` check |
| 2 | Missing guard | BreakScheduler | 261-270 | Add `isNotificationActive` check |
| 3 | Window layer | OverlayWindow | 179 | Increase z-order or use `makeKeyAndOrderFront()` |
| 4 | Idle poll | BreakScheduler | 338-349 | Add `isNotificationActive` to condition |

---

## ✅ Required Fixes

**Fix #1: handleIdleDetected() (Lines 248-257)**
```swift
func handleIdleDetected() {
    guard !isPaused else { return }
    guard !isBreakInProgress else { return }
    
    // ⭐ ADD THIS:
    guard let nm = notificationSender as? NotificationManager,
          !nm.isNotificationActive else {
        Log.scheduler.info("Idle detected during notification — skipping timer reset.")
        return
    }
    
    resetTimersAfterBreak(.micro)
}
```

**Fix #2: handleActivityResumed() (Lines 261-270)**
```swift
func handleActivityResumed() {
    guard !isPaused else { return }
    guard !isBreakInProgress else { return }
    
    // ⭐ ADD THIS:
    guard let nm = notificationSender as? NotificationManager,
          !nm.isNotificationActive else {
        Log.scheduler.info("Activity resumed during notification — skipping session reset.")
        return
    }
    
    sessionStartTime = .now
    currentSessionDuration = 0
}
```

**Fix #3: Window Layer (Line 179 in OverlayWindow.swift)**
```swift
// BEFORE:
fullScreenWindow.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))

// AFTER:
fullScreenWindow.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
fullScreenWindow.makeKeyAndOrderFront(nil)
```

**Fix #4: Idle Poll Condition (Line 338 in BreakScheduler.swift)**
```swift
// BEFORE:
if ticksSinceLastScoreUpdate % 5 == 0, !isBreakInProgress {

// AFTER:
if ticksSinceLastScoreUpdate % 5 == 0,
   !isBreakInProgress,
   !(notificationSender as? NotificationManager)?.isNotificationActive ?? false {
```

---

## 📊 Impact Assessment

| Aspect | Details |
|--------|---------|
| **Severity** | P0 (User-facing, breaks core feature) |
| **Reproducibility** | High (occurs ~1s after popup appears) |
| **Frequency** | Happens every time micro-break triggers in quick succession |
| **User Impact** | Confusing: popup appears then vanishes with no explanation |
| **Fix Complexity** | Low (add guard conditions, ~3 minutes to implement) |
| **Testing Needed** | Unit tests + manual verification |

---

## 🔍 How to Verify Fix

1. **Before Fix:**
   - Trigger micro-break → popup appears
   - Stop moving mouse immediately
   - Observe: popup disappears after ~1 second
   - Console: Check for "Idle detected, micro timer reset" log

2. **After Fix:**
   - Trigger micro-break → popup appears
   - Stop moving mouse immediately
   - Observe: popup stays visible for full countdown (20s)
   - Console: Check for "Idle detected during notification — skipping timer reset" log

---

## 📋 Files to Review

- **Detailed Report:** `.review/2026-04-16-bug-001-thorough-investigation.md` (537 lines)
- **Summary:** `.review/FINDINGS_SUMMARY.txt` (380 lines)
- **Initial Analysis:** `.review/2026-04-16-bug-001-popup-flash.md` (484 lines)

---

## 🧪 Test Cases Needed

```swift
@Test("Idle detection during active notification does not reset timer")
func idleDuringNotificationSkipsReset() async throws {
    let scheduler = BreakScheduler(/* mocks */)
    
    // Trigger notification
    scheduler.triggerBreakNotification(.micro)
    await Task.yield() // Let notification fire
    
    // Simulate idle
    scheduler.handleIdleDetected()
    
    // Verify timer was NOT reset
    #expect(scheduler.elapsedPerType[.micro]! > 0)
    #expect(scheduler.lastNotifiedCycle[.micro] != -1)
}

@Test("Activity resumed during active notification does not reset session")
func activityResumedDuringNotificationSkipsReset() async throws {
    let scheduler = BreakScheduler(/* mocks */)
    
    // Trigger notification
    scheduler.triggerBreakNotification(.micro)
    await Task.yield()
    
    // Simulate activity resumed
    scheduler.handleActivityResumed()
    
    // Verify session was NOT reset
    #expect(scheduler.currentSessionDuration > 0)
}
```

---

## 🚀 Deployment Checklist

- [ ] Implement Fix #1 (handleIdleDetected)
- [ ] Implement Fix #2 (handleActivityResumed)
- [ ] Implement Fix #3 (window layer)
- [ ] Implement Fix #4 (idle poll condition)
- [ ] Add unit tests
- [ ] Test manual reproduction scenario
- [ ] Test on multi-screen setup
- [ ] Verify console logs show "notification — skipping" messages
- [ ] Regression test: popup stays visible for full countdown
- [ ] Regression test: timer expires properly after fix
- [ ] Regression test: user can still manually close popup

---

## 💡 Root Cause Summary

The bug exists because:

1. **Architectural Gap:** Scheduler and NotificationManager are loosely coupled
2. **Missing Guard:** Idle detection doesn't know about active notifications
3. **State Desync:** Two independent state machines get out of sync
4. **Window Layers:** Additional complexity from macOS window management

**Solution:** Add guard checks to prevent idle/activity handlers from firing during active notifications. This ensures the scheduler respects the NotificationManager's lifecycle.

---

**Generated:** April 16, 2026  
**Investigation Status:** ✅ COMPLETE - Ready for Implementation  
**Confidence Level:** 95% (Primary cause identified with certainty)
