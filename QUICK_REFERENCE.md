# Eye-Guard Popup System - Quick Reference Guide

## File Locations & Purposes

### Core Notification System
| File | Location | Purpose |
|------|----------|---------|
| **NotificationManager.swift** | `Sources/Notifications/` | Orchestrates 3-tier escalation, manages callbacks |
| **OverlayWindow.swift** | `Sources/Notifications/` | Creates/manages NSWindow instances for overlays |
| **BreakOverlayView.swift** | `Sources/Notifications/` | SwiftUI UI for Tier 2 floating popup |
| **FullScreenOverlayView.swift** | `Sources/Notifications/` | SwiftUI UI for Tier 3 full-screen overlay |

### Timing & Scheduling
| File | Location | Purpose |
|------|----------|---------|
| **BreakScheduler.swift** | `Sources/Scheduling/` | Main 1-second timer loop, detects due breaks |
| **BreakType.swift** | `Sources/Scheduling/` | Enum: micro (20m), macro (60m), mandatory (120m) |
| **Constants.swift** | `Sources/Utils/` | Timing config (intervals, durations, delays) |

### Supporting Systems
| File | Location | Purpose |
|------|----------|---------|
| **AppDelegate.swift** | `Sources/App/` | System setup, permissions, midnight rollover |
| **ActivityMonitor.swift** | `Sources/Monitoring/` | Detects keyboard/mouse idle state |

## Key Constants & Timing

```swift
// INTERVALS (How often breaks are due)
microBreakInterval = 20 minutes    (1200 seconds)
macroBreakInterval = 60 minutes    (3600 seconds)
mandatoryBreakInterval = 120 minutes (7200 seconds)

// DURATIONS (How long user must rest)
microBreakDuration = 20 seconds
macroBreakDuration = 5 minutes (300 seconds)
mandatoryBreakDuration = 15 minutes (900 seconds)

// ESCALATION DELAYS
tier1EscalationDelay = 2 minutes (120 seconds)   // Tier 1 → Tier 2
tier2EscalationDelay = 5 minutes (300 seconds)   // Tier 2 → Tier 3

// UI ANIMATION
fadeInDuration = 0.3 seconds (easeOut)
fadeOutDuration = 0.3 seconds (easeIn)
```

## Trigger Chain (Step by Step)

```
1. BreakScheduler starts at app launch
   └─ startTimerLoop() → Task running forever

2. Every 1 second: tick()
   ├─ currentSessionDuration += 1
   ├─ elapsedPerType[.micro] += 1
   ├─ elapsedPerType[.macro] += 1
   ├─ elapsedPerType[.mandatory] += 1
   └─ checkForDueBreaks()

3. Check if break is due
   ├─ elapsed = elapsedPerType[breakType]
   ├─ interval = intervalForType(breakType)
   ├─ currentCycle = Int(elapsed / interval)
   ├─ if currentCycle > lastNotifiedCycle[breakType]:
   │  └─ triggerBreakNotification(breakType)
   │
   └─ SPECIAL: Mandatory breaks also checked via checkContinuousUse()

4. Trigger notification
   └─ NotificationManager.notify(breakType, healthScore, onTaken, onSkipped)

5. Show Tier 1 (immediate)
   └─ UNUserNotificationCenter.add(request)

6. Wait 2 minutes (tier1EscalationDelay)
   └─ Task.sleep(for: .seconds(120))

7. Show Tier 2 (after 2 minutes)
   └─ OverlayWindowController.showBreakOverlay()

8. Wait 5 minutes (tier2EscalationDelay)
   └─ Task.sleep(for: .seconds(300))

9a. For MANDATORY: Show Tier 3 (after 7 minutes total)
   └─ OverlayWindowController.showFullScreenOverlay()

9b. For NON-MANDATORY: Timeout after 7 minutes total
   └─ handleEscalationTimeout() → dismissAllOverlays()
```

## NSWindow Configuration

### Tier 2 (Floating Overlay)
```swift
level = .floating              // Above normal windows
size = 340×300 pt
position = top-right with 20pt margin
isOpaque = false              // Supports transparency
backgroundColor = .clear
hasShadow = true
isMovableByWindowBackground = true
collectionBehavior = [.canJoinAllSpaces, .stationary]
alphaValue: 0 → 1 over 0.3s (fade in)
alphaValue: 1 → 0 over 0.3s (fade out)
```

### Tier 3 (Full-Screen Overlay)
```swift
level = .screenSaver           // Above everything
size = screen.frame           // Each monitor
isOpaque = false
backgroundColor = .clear
hasShadow = false
collectionBehavior = [.canJoinAllSpaces, .stationary]
alphaValue: 0 → 1 over 0.5s (fade in)
alphaValue: 1 → 0 over 0.3s (fade out)
```

## SwiftUI View Timer Implementations

### BreakOverlayView (Tier 2)
```swift
// User clicks "Take Break"
startBreak()
├─ isBreaking = true
├─ countdown = Int(breakType.duration)  // 20, 300, or 900
└─ startCountdownTimer()

// Timer fires every 1 second
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
├─ if countdown > 0: countdown -= 1
└─ if countdown <= 0: completeBreak()

// When countdown reaches 0
completeBreak()
├─ stopTimer()
├─ onTaken()     // Callback to NotificationManager
└─ onDismiss()   // Callback to OverlayWindowController → dismiss()
```

### FullScreenOverlayView (Tier 3)
```swift
// User clicks "Take 15-min Break"
startBreak()
├─ isCountingDown = true
├─ remainingSeconds = 900
├─ totalDuration = 900
└─ startCountdownTimer()

// Timer fires every 1 second
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
├─ if remainingSeconds > 0: remainingSeconds -= 1
├─ progress = (totalDuration - remainingSeconds) / totalDuration
└─ if remainingSeconds <= 0: completeBreak()

// User requests extension
requestExtension()
├─ extensionsUsed += 1
├─ remainingSeconds += 300
└─ totalDuration += 300
   (Max 2 extensions: 15 + 2×5 = 25 minutes)

// When countdown reaches 0
completeBreak()
├─ stopTimer()
└─ onBreakTaken()  // Callback triggers dismissFullScreen()
```

## Dismissal Paths

### Path 1: User Completes Countdown
```
BreakOverlayView.completeBreak()
├─ onTaken() → NotificationManager.acknowledgeBreak()
└─ onDismiss() → OverlayWindowController.dismiss()
   └─ Fade-out animation (300ms)
```

### Path 2: User Skips
```
BreakOverlayView.skipBreak()
├─ onSkipped() → NotificationManager skip handler
└─ onDismiss() → OverlayWindowController.dismiss()
   └─ Fade-out animation (300ms)
```

### Path 3: Escalation Timeout (5 min, no action)
```
NotificationManager.handleEscalationTimeout()
├─ dismissAllOverlays()
│  ├─ UNUserNotificationCenter.removeDeliveredNotifications()
│  ├─ overlayController.dismiss()
│  └─ overlayController.dismissFullScreen()
└─ onSkippedCallback?()
```

### Path 4: New Break Interrupts Old
```
OverlayWindowController.showBreakOverlay(newType)
├─ if isShowing:
│  └─ dismissImmediate()  // NO ANIMATION!
│     └─ window?.close()
└─ Show new overlay
```

## Potential Issues & Fixes

### Issue 1: Popup closes too quickly after showing
**Cause:** Escalation timeout fires after 5 min of inactivity at Tier 2
**Fix:** User needs to interact (click button) before 5 minutes

### Issue 2: Popup disappears when new break becomes due
**Cause:** `dismissImmediate()` closes old overlay instantly
**Fix:** If micro break due at 20 min and macro also due, only show macro

### Issue 3: Timer stops but popup stays visible
**Cause:** `onDisappear` triggered (view goes out of scope)
**Fix:** `stopTimer()` invalidates timer. Popup is frozen.

### Issue 4: Full-screen doesn't appear on all monitors
**Cause:** `NSScreen.screens` might return empty array
**Fix:** Guard against empty screen list in `showFullScreenOverlay()`

### Issue 5: Focus stolen by other app
**Cause:** Overlay window loses key status
**Fix:** `makeKeyAndOrderFront(nil)` brings to front, but system can override

## Testing the System

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter OverlayWindowControllerTests

# Run specific test
swift test --filter "testShowOverlay"

# Run with verbose output
swift test --verbose
```

### Key Test Files
- `OverlayWindowTests.swift` - Window creation/dismissal
- `BreakSchedulerTests.swift` - Timing and break detection
- `NotificationManagerTests.swift` - 3-tier escalation

## Logging

Enable detailed logging to understand flow:

```swift
// In any file, use:
Log.notification.info("Message")
Log.notification.warning("Warning")
Log.notification.error("Error")
Log.scheduler.info("Message")
```

View logs in Console.app or via terminal:
```bash
log stream --predicate 'process == "EyeGuard"' --level debug
```

## Key Data Structures

### NotificationManager State
```swift
enum Tier: Int, Sendable {
    case gentle = 1    // Tier 1
    case firm = 2      // Tier 2
    case mandatory = 3 // Tier 3
}

currentTier: Tier
isNotificationActive: Bool
onTakenCallback: @Sendable () -> Void  // Called when break taken
onSkippedCallback: @Sendable () -> Void // Called when break skipped
escalationTask: Task<Void, Never>  // Manages time delays
```

### BreakScheduler State
```swift
currentSessionDuration: TimeInterval        // Seconds of continuous use
elapsedPerType: [BreakType: TimeInterval]   // Per-break-type elapsed time
nextScheduledBreak: BreakType?              // Which break comes next
timeUntilNextBreak: TimeInterval           // Seconds until next break
lastNotifiedCycle: [BreakType: Int]        // Track notified cycles
isBreakInProgress: Bool                     // Currently taking break
activeBreakType: BreakType?                // Which break active
```

### OverlayWindowController State
```swift
window: NSWindow?               // Tier 2 overlay window
fullScreenWindows: [NSWindow]  // Tier 3 windows (one per monitor)
isShowing: Bool                // window != nil
isFullScreenShowing: Bool      // !fullScreenWindows.isEmpty
```

## Architecture Notes

- **@MainActor**: NotificationManager, OverlayWindowController (must run on main thread)
- **Swift 6 Concurrency**: Uses Task, @Sendable, @escaping for callbacks
- **Protocol-Oriented**: NotificationSending protocol allows testing with mocks
- **Dependency Injection**: BreakScheduler accepts injected monitors/notifiers
- **Reactive State**: BreakScheduler is @Observable for menu bar UI updates

