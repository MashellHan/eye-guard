# Eye-Guard Popup/Overlay Flow Diagrams

## 1. Break Trigger Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BreakScheduler.startTimerLoop()                   │
│                   (Async Task running forever)                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ↓
                     Task.sleep(1.0 second)
                              │
                              ↓
                      BreakScheduler.tick()
                              │
        ┌───────────────────────────────────┬──────────────────────┐
        │                                   │                      │
        ↓                                   ↓                      ↓
  Update session          Update per-type elapsed time      Poll ActivityMonitor
  duration                (micro, macro, mandatory)         (every 5 seconds)
        │                                   │                      │
        └───────────────────────────────────┼──────────────────────┘
                              │
                              ↓
                  BreakScheduler.updateNextBreak()
                  (Calculate next break in queue)
                              │
                              ↓
              BreakScheduler.checkForDueBreaks()
                              │
                    ┌─────────────────────────┐
                    │                         │
                    ↓                         ↓
            For each break type:        Is break due?
            - micro (20 min)              │
            - macro (60 min)    ┌─────────┴──────┐
            - mandatory (120 min)│ No             │ Yes
                                 │                ↓
                                 ↓     Has this cycle been
                            (continue)  notified already?
                                        │
                        ┌───────────────┴──────┐
                        │                      │
                        ↓ Yes                  ↓ No
                     (skip)         triggerBreakNotification()
                                             │
                                             ↓
                          NotificationManager.notify()
                          (Stores onTaken/onSkipped callbacks)
```

## 2. 3-Tier Notification Escalation

```
TIER 1: System Notification (Immediate)
┌─────────────────────────────────────────┐
│ UNUserNotificationCenter.add(request)    │
│ - Title: "Time for a Micro Break"       │
│ - Body: "20-20-20 Rule: Every 20 min..." │
│ - Sound: .default                        │
└─────────────────────────────────────────┘
         │
         │ User ignores or doesn't interact
         │
         ↓ Wait 2 minutes (tier1EscalationDelay = 120s)
         │
TIER 2: Floating Overlay Window
┌─────────────────────────────────────────┐
│ OverlayWindowController.showBreakOverlay│
│ - Position: top-right (20pt margin)     │
│ - Size: 340×300 pt                      │
│ - Level: .floating (above other windows)│
│ - UI: BreakOverlayView (SwiftUI)        │
│   • Eye icon with pulse animation       │
│   • "Time for an eye break!" title      │
│   • Health score badge                  │
│   • [Take Break] [Skip] [Exercises]     │
│   • When user clicks "Take Break":      │
│     → Starts countdown timer            │
│     → Shows progress bar                │
│     → Counts down from 20s/5m/15m       │
└─────────────────────────────────────────┘
         │
    ┌────┴─────────────────────────────────┐
    │                                       │
    ↓ User clicks "Take Break"     ↓ User clicks "Skip"
    │ (Countdown starts)           │ (No countdown)
    │                              │
    ├─ Countdown reaches 0         ├─ Immediately invokes
    │ │ → onTaken callback         │  onSkipped callback
    │ │ → onDismiss callback       │  → onDismiss callback
    │ ↓                            ↓
    │ Popup fades out (300ms)    Popup fades out (300ms)
    │ │                          │
    │ └──────────────────────────┘
    │        ↓
    │ OverlayWindowController.dismiss()
    │ - Fade-out animation (300ms, easeIn)
    │ - window.close()
    │ - self.window = nil
    │
    ↓ 5 minutes elapsed, user still ignoring
    │ (ONLY FOR MANDATORY BREAKS)
    │
TIER 3: Full-Screen Overlay (All Monitors)
┌─────────────────────────────────────────┐
│ OverlayWindowController.showFullScreenOv│
│ - Created per monitor (NSScreen.screens)│
│ - Level: .screenSaver (above everything)│
│ - Size: Covers entire screen            │
│ - UI: FullScreenOverlayView (SwiftUI)   │
│   • Black semi-transparent overlay      │
│   • Blur effect (VisualEffectBlur)      │
│   • Center content:                     │
│     • Warning icon (pulsing yellow)     │
│     • "You've been using screen 2 hrs!" │
│     • Circular countdown (15 minutes)   │
│     • Progress ring (angular gradient)  │
│     • Health score display              │
│     • Medical tip                       │
│     • [Take 15-min Break] button        │
│     • Extension buttons (max 2×5min)    │
│   • When user clicks "Take 15-min Break"│
│     → Starts 15-minute countdown        │
│     → Progress ring animates            │
│   • User can request 2 extensions       │
│     → Each adds 5 minutes               │
│     → Max total: 15 + 2×5 = 25 minutes │
└─────────────────────────────────────────┘
         │
    ┌────┴────────────────────┐
    │                         │
    ↓ Countdown reaches 0  ↓ 5 min timeout,
    │                    │ no user action
    │ onBreakTaken()    │
    │ dismissFullScreen()
    │                    │
    └────────────┬───────┘
                 │
          Fade-out animation (300ms)
                 │
                 ↓
          window.close() for each monitor
                 │
                 ↓
          OverlayWindowController.dismissFullScreen()
```

## 3. Popup Countdown Timer Lifecycle

### Tier 2 (BreakOverlayView)

```
User clicks "Take Break" Button
         │
         ↓
  startBreak() called
         │
         ├─ isBreaking = true
         ├─ countdown = breakDurationSeconds (20, 300, or 900)
         │
         ↓
  startCountdownTimer() called
         │
         ↓
  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
         │
    ┌────┴─────────────────────┐
    │                          │
    ↓ Tick (every 1 second)   ↓ 
    │                          
    ├─ if countdown > 0:
    │  └─ countdown -= 1
    │
    ├─ if countdown <= 0:
    │  │  completeBreak()
    │  │  │
    │  │  ├─ stopTimer() (timer?.invalidate())
    │  │  ├─ onTaken() (callback to NotificationManager)
    │  │  └─ onDismiss() (callback to OverlayWindowController)
    │  │
    │  └─ BreakOverlayView fades out
    │     └─ OverlayWindowController.dismiss()
    │
    └─ UI displays countdown with animation:
       - Text display updated (contentTransition.numericText)
       - Progress bar updated (animation .linear(duration: 0.5))

TIMELINE:
─────────────────────────────────────────────
0s         Take Break clicked
           countdown = 20
           Timer starts
           
1s         countdown = 19
           
2s         countdown = 18
           
...
           
19s        countdown = 1
           
20s        countdown = 0
           completeBreak() invoked
           Timer invalidated
           onTaken() called
           onDismiss() called
           → Popup starts fading out
           
20.3s      Fade-out complete (300ms)
           window.close()
```

### Tier 3 (FullScreenOverlayView)

```
User clicks "Take 15-min Break" Button
         │
         ↓
  startBreak() called
         │
         ├─ isCountingDown = true
         ├─ remainingSeconds = 15 * 60 = 900
         ├─ totalDuration = 900
         │
         ↓
  startCountdownTimer() called
         │
         ↓
  Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
         │
    ┌────┴──────────────────────────────────┐
    │                                       │
    ↓ Tick (every 1 second)                ↓
    │                                       
    ├─ if remainingSeconds > 0:
    │  └─ remainingSeconds -= 1
    │     └─ progress = (totalDuration - remainingSeconds) / totalDuration
    │        └─ Progress ring animates (animation .linear(duration: 1.0))
    │        └─ Countdown text updates (contentTransition.numericText)
    │
    ├─ if remainingSeconds <= 0:
    │  │  completeBreak()
    │  │  │
    │  │  ├─ stopTimer()
    │  │  └─ onBreakTaken()
    │  │     └─ OverlayWindowController.dismissFullScreen()
    │  │
    │  └─ All full-screen windows fade out (300ms each)
    │     └─ window.close() for each monitor
    │
    └─ EXTENSION HANDLING:
       User clicks "I Need 5 More Minutes"
       │
       ├─ extensionsUsed += 1
       ├─ remainingSeconds += extensionSeconds (300s)
       ├─ totalDuration += extensionSeconds
       │
       └─ Countdown resets and continues
          (Max 2 extensions = 15 + 10 = 25 total minutes)

TIMELINE:
─────────────────────────────────────────────
0s         "Take 15-min Break" clicked
           remainingSeconds = 900
           totalDuration = 900
           Timer starts
           
1s         remainingSeconds = 899 (14:59)
           progress = 1/900
           
...
           
300s       remainingSeconds = 600 (10:00)
           progress = 300/900 = 0.33
           [User clicks "I Need 5 More Minutes"]
           remainingSeconds = 900 (15:00)
           totalDuration = 1200
           progress resets
           
1200s      remainingSeconds = 0 (00:00)
           completeBreak() invoked
           Timer invalidated
           onBreakTaken() called
           → Full-screen popups start fading out
           
1200.3s    Fade-out complete (300ms)
           window.close() for each screen
```

## 4. Escalation Timeout (No User Action)

```
NotificationManager.notify() called
│
├─ isNotificationActive = true
├─ currentTier = .gentle
├─ Store onTaken & onSkipped callbacks
│
├─ sendTier1Notification() [IMMEDIATE]
│
└─ Start escalationTask (async chain):
   │
   ├─ await Task.sleep(for: .seconds(120))  ← 2 minutes
   │  │
   │  ├─ [User interaction here? → cancel escalation]
   │  │
   │  └─ showTier2Overlay() [AFTER 2 MIN]
   │
   ├─ await Task.sleep(for: .seconds(300))  ← 5 minutes
   │  │
   │  ├─ [User interaction here? → cancel escalation]
   │  │
   │  └─ For MANDATORY breaks:
   │     │
   │     └─ showTier3Fullscreen() [AFTER 5 MORE MIN = 7 TOTAL]
   │
   ├─ await Task.sleep(for: .seconds(300))  ← 5 more minutes
   │  │
   │  ├─ [User interaction here? → cancel escalation]
   │  │
   │  └─ handleEscalationTimeout() [AFTER 5 MORE MIN]
   │
   └─ handleEscalationTimeout():
      │
      ├─ dismissAllOverlays()
      │  ├─ UNUserNotificationCenter.removeDeliveredNotifications()
      │  ├─ overlayController.dismiss()
      │  └─ overlayController.dismissFullScreen()
      │
      ├─ isNotificationActive = false
      ├─ clearCallbacks()
      │
      └─ onSkippedCallback?()
         └─ Called → BreakScheduler.skipBreak(type)

TIMELINES:

NON-MANDATORY BREAKS (Micro/Macro):
─────────────────────────────────────────────
0s         Tier 1 shown (system notification)
           
120s       Tier 2 shown (overlay window)
           
420s       Escalation timeout, onSkipped invoked
(7 min)    Overlay dismissed
           


MANDATORY BREAKS:
─────────────────────────────────────────────
0s         Tier 1 shown (system notification)
           
120s       Tier 2 shown (overlay window)
(2 min)    
           
420s       Tier 3 shown (full-screen overlay)
(7 min)    15-minute countdown starts
           
900s       Countdown reaches 0 OR
(15 min    user takes break → onBreakTaken invoked
from T3)   
           
1200s      If no user action → Escalation timeout
(20 min    onSkipped invoked
total)     Full-screen dismissed
```

## 5. Window Dismissal Animation

```
User interaction triggers dismissal (Take Break, Skip, or Timeout)
│
├─ dismissAction called (for Tier 2):
│  │
│  ├─ OverlayWindowController.dismiss() called
│  │  │
│  │  ├─ NSAnimationContext.runAnimationGroup:
│  │  │  ├─ duration: 0.3 seconds
│  │  │  ├─ timingFunction: CAMediaTimingFunction(name: .easeIn)
│  │  │  ├─ overlayWindow.animator().alphaValue = 0
│  │  │  │  (Fade out from 1.0 → 0.0 over 300ms)
│  │  │  │
│  │  │  └─ completionHandler (after animation):
│  │  │     ├─ overlayWindow.close()
│  │  │     ├─ self.window = nil
│  │  │     └─ Log.notification.info("Overlay window dismissed.")
│
├─ dismissFullScreen (for Tier 3, called if multiple monitors):
│  │
│  ├─ for each window in fullScreenWindows:
│  │  │
│  │  ├─ NSAnimationContext.runAnimationGroup:
│  │  │  ├─ duration: 0.3 seconds
│  │  │  ├─ timingFunction: CAMediaTimingFunction(name: .easeIn)
│  │  │  ├─ fsWindow.animator().alphaValue = 0
│  │  │  │
│  │  │  └─ completionHandler:
│  │  │     └─ fsWindow.close()
│  │  │
│  │  └─ fullScreenWindows = []

ANIMATION TIMELINE:
─────────────────────────────────────────────
0ms        Alpha = 1.0 (fully opaque)
           Animation begins

100ms      Alpha ≈ 0.67 (easeIn curve)

200ms      Alpha ≈ 0.33 (easeIn curve)

300ms      Alpha = 0.0 (fully transparent)
           completionHandler invoked
           window.close()
           Memory released
```

## 6. Early Close Scenarios

```
SCENARIO 1: User ignores Tier 2 for exactly 5 minutes
─────────────────────────────────────────────
showTier2Overlay() called at T=0
         │
         ├─ User does NOT interact
         │
         ├─ 5 minutes pass
         │
         └─ Escalation timeout fires
            └─ handleEscalationTimeout()
               └─ dismissAllOverlays()
                  └─ Popup fades out and closes


SCENARIO 2: New break becomes due while Tier 2 is showing
─────────────────────────────────────────────
showBreakOverlay(breakType: .micro) at T=0
         │
         ├─ Overlay window shown
         │
         ├─ 20 minutes elapsed (macro break due)
         │
         └─ showBreakOverlay(breakType: .macro) called
            │
            ├─ if isShowing {
            │  └─ dismissImmediate()  ← NO ANIMATION!
            │     └─ window?.close()
            │     └─ window = nil
            │
            └─ Show new overlay for macro break


SCENARIO 3: Timer stops before countdown completes
─────────────────────────────────────────────
startCountdownTimer() called
         │
         ├─ Timer ticking every 1 second
         │
         ├─ .onDisappear triggered (view goes out of scope)
         │
         └─ stopTimer()
            └─ timer?.invalidate()  ← COUNTDOWN STOPS
               timer = nil
               
            Result: Popup stays visible but timer frozen


SCENARIO 4: onTaken callback invoked prematurely
─────────────────────────────────────────────
startCountdownTimer() called
         │
         ├─ Timer ticking
         │
         ├─ completeBreak() called externally
         │  (E.g., NotificationManager calls acknowledgeBreak())
         │
         ├─ onTaken()  ← Callback invoked
         │
         └─ onDismiss()
            └─ dismiss() with fade-out animation
               ← Popup starts closing immediately


SCENARIO 5: BreakScheduler.takeBreakNow() called directly
─────────────────────────────────────────────
BreakScheduler.takeBreakNow(type: .micro) called
         │
         ├─ isBreakInProgress = true
         ├─ activeBreakType = .micro
         ├─ recordBreak(type: type, wasTaken: true)
         │
         ├─ Start ambient sound
         │
         └─ Task sleep for breakDuration (20 seconds):
            │
            ├─ After 20s:
            │  │
            │  └─ MainActor.run {
            │     └─ endBreak()
            │        ├─ isBreakInProgress = false
            │        ├─ activeBreakType = nil
            │        └─ soundPlayer.stopAmbient()
            │
            └─ This DOES NOT directly dismiss the overlay
               (Overlay management is separate in NotificationManager)
```

## 7. State Management Flow

```
┌──────────────────────────────────────┐
│    BreakScheduler (Observable)       │
│    ─────────────────────────────────  │
│  • currentSessionDuration (updated   │
│    every tick)                       │
│  • elapsedPerType[breakType]         │
│  • nextScheduledBreak                │
│  • timeUntilNextBreak                │
│  • isBreakInProgress                 │
│  • activeBreakType                   │
│                                      │
│  @State private var timer: Task      │
│                                      │
│  Methods:                            │
│  - tick() — called every 1s          │
│  - checkForDueBreaks()               │
│  - triggerBreakNotification()        │
└──────────────────────────────────────┘
              │
              ├─ calls NotificationManager.notify()
              │
              └─ receives onTaken/onSkipped callbacks
                 → calls takeBreakNow() or skipBreak()

┌──────────────────────────────────────┐
│  NotificationManager (Singleton)     │
│  @MainActor                          │
│  ─────────────────────────────────── │
│  • currentTier: Tier (.gentle/.firm/ │
│    .mandatory)                       │
│  • isNotificationActive: Bool        │
│  • onTakenCallback: (() → Void)?     │
│  • onSkippedCallback: (() → Void)?   │
│  • currentHealthScore: Int           │
│  • overlayController: Overlay        │
│    WindowController                  │
│  • escalationTask: Task              │
│                                      │
│  Methods:                            │
│  - notify()                          │
│  - acknowledgeBreak()                │
│  - snooze()                          │
│  - sendTier1Notification()           │
│  - showTier2Overlay()                │
│  - showTier3Fullscreen()             │
│  - handleEscalationTimeout()         │
└──────────────────────────────────────┘
              │
              ├─ calls OverlayWindowController
              │
              └─ manages escalation via Task.sleep()

┌──────────────────────────────────────┐
│ OverlayWindowController (@MainActor) │
│ ─────────────────────────────────────  │
│  • window: NSWindow?  (Tier 2)       │
│  • fullScreenWindows: [NSWindow]     │
│    (Tier 3, one per monitor)         │
│  • isShowing: Bool                   │
│  • isFullScreenShowing: Bool         │
│                                      │
│  Methods:                            │
│  - showBreakOverlay()                │
│  - showFullScreenOverlay()           │
│  - dismiss()                         │
│  - dismissFullScreen()               │
│  - dismissImmediate()                │
│  - positionTopRight()                │
└──────────────────────────────────────┘
              │
              ├─ creates & manages NSWindow instances
              │
              └─ shows SwiftUI views in windows

┌──────────────────────────────────────┐
│  BreakOverlayView (SwiftUI)          │
│  ─────────────────────────────────── │
│  @State:                             │
│  • countdown: Int (current timer)    │
│  • isBreaking: Bool                  │
│  • showExercises: Bool               │
│  • timer: Timer?                     │
│  • appeared: Bool                    │
│                                      │
│  Callbacks:                          │
│  • onTaken()                         │
│  • onSkipped()                       │
│  • onDismiss()                       │
│                                      │
│  Methods:                            │
│  - startBreak()                      │
│  - startCountdownTimer()             │
│  - completeBreak()                   │
│  - skipBreak()                       │
│  - stopTimer()                       │
└──────────────────────────────────────┘
              │
              └─ User interacts here
                 → calls callbacks
                 → triggers dismissal

┌──────────────────────────────────────┐
│  FullScreenOverlayView (SwiftUI)     │
│  ─────────────────────────────────── │
│  @State:                             │
│  • isCountingDown: Bool              │
│  • remainingSeconds: Int             │
│  • totalDuration: Int (for progress) │
│  • extensionsUsed: Int               │
│  • timer: Timer?                     │
│  • appeared: Bool                    │
│  • isPulsing: Bool                   │
│  • currentTip: String                │
│                                      │
│  Callbacks:                          │
│  • onBreakTaken()                    │
│                                      │
│  Methods:                            │
│  - startBreak()                      │
│  - requestExtension()                │
│  - startCountdownTimer()             │
│  - completeBreak()                   │
│  - stopTimer()                       │
└──────────────────────────────────────┘
```

