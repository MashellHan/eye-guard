# Eye-Guard Reminder/Break Popup Implementation Analysis

## Project Overview

**Eye-Guard** is a medical-grade eye health guardian for macOS that implements evidence-based break reminders using the 20-20-20 rule and other medical guidelines. The project follows a clean, protocol-oriented architecture with strict Swift 6 concurrency.

### Core Architecture
```
EyeGuard/Sources/
├── Scheduling/       # BreakScheduler.swift - Main timer engine
├── Notifications/    # Tier 1/2/3 notification system
│   ├── NotificationManager.swift
│   ├── OverlayWindow.swift
│   ├── BreakOverlayView.swift (Tier 2)
│   └── FullScreenOverlayView.swift (Tier 3)
├── App/              # AppDelegate, MenuBar
├── Mascot/           # Floating character UI
├── Monitoring/       # ActivityMonitor for idle detection
├── Persistence/      # Data persistence
└── Utils/            # Constants, logging
```

---

## Part 1: How the Break/Rest Reminder Popup is Triggered

### 1.1 Break Scheduling Engine (BreakScheduler.swift)

The **BreakScheduler** is the core timing engine that orchestrates all break notifications:

**Break Types and Intervals:**
- **Micro-break**: every 20 minutes (20-20-20 rule)
- **Macro-break**: every 60 minutes (OSHA guidelines)
- **Mandatory break**: every 120 minutes (EU directive)

**Durations:**
- Micro: 20 seconds
- Macro: 5 minutes  
- Mandatory: 15 minutes

### 1.2 Timer Loop

From **BreakScheduler.swift** (lines 242-313):

```swift
// Main timer loop — ticks every second for UI responsiveness
private func startTimerLoop() {
    timerTask = Task {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            tick()  // Called every second
        }
    }
}

// Called every second
private func tick() {
    guard !isPaused else { return }
    
    // 1. Update session duration
    currentSessionDuration = Date.now.timeIntervalSince(sessionStartTime)
    
    // 2. Update per-break-type elapsed time
    for type in BreakType.allCases {
        elapsedPerType[type, default: 0] += delta
    }
    
    // 3. Check if any break is due
    updateNextBreak()
    checkForDueBreaks()  // THIS TRIGGERS NOTIFICATIONS
    
    // Heavy operations on slower cadence (every 5 seconds)
    checkContinuousUse()
    checkDailyRollover()
}
```

### 1.3 Break Due Detection (lines 339-358)

```swift
private func checkForDueBreaks() {
    for type in BreakType.allCases {
        let elapsed = elapsedPerType[type, default: 0]
        let interval = intervalForType(type)
        let currentCycle = Int(elapsed / interval)
        
        // Only fire if we crossed into a new cycle (prevent double-fire)
        if currentCycle > 0 && currentCycle != lastNotifiedCycle[type] {
            lastNotifiedCycle[type] = currentCycle
            triggerBreakNotification(type)  // TRIGGERS NOTIFICATION
        }
    }
}

private func triggerBreakNotification(_ breakType: BreakType) {
    Log.scheduler.info("Break due: \(breakType.displayName)")
    
    notificationSender.notify(
        breakType: breakType,
        healthScore: currentHealthScore
    ) { [weak self] in
        // onTaken callback
        self?.takeBreakNow(breakType)
    } onSkipped: { [weak self] in
        // onSkipped callback  
        self?.skipBreak(breakType)
    }
}
```

### 1.4 Continuous Use Check (lines 375-390)

For mandatory breaks, there's an additional continuous use check:

```swift
private func checkContinuousUse() {
    let threshold = preferences.mandatoryBreakInterval  // 120 minutes
    guard currentSessionDuration >= threshold else { return }
    
    // Only warn once per session crossing threshold
    let warningCycle = Int(currentSessionDuration / threshold)
    if warningCycle > continuousUseWarnings {
        continuousUseWarnings = warningCycle
        triggerBreakNotification(.mandatory)  // Tier 3 escalation
    }
}
```

### 1.5 Constants Configuration (Constants.swift)

```swift
enum EyeGuardConstants {
    // Break Intervals (seconds)
    static let microBreakInterval: TimeInterval = 20 * 60      // 1200s
    static let macroBreakInterval: TimeInterval = 60 * 60      // 3600s
    static let mandatoryBreakInterval: TimeInterval = 120 * 60 // 7200s
    
    // Break Durations (seconds)
    static let microBreakDuration: TimeInterval = 20
    static let macroBreakDuration: TimeInterval = 5 * 60       // 300s
    static let mandatoryBreakDuration: TimeInterval = 15 * 60  // 900s
    
    // Notification Escalation Delays
    static let tier1EscalationDelay: TimeInterval = 2 * 60    // 120s
    static let tier2EscalationDelay: TimeInterval = 5 * 60    // 300s
}
```

---

## Part 2: 3-Tier Notification System

### 2.1 Notification Architecture (NotificationManager.swift)

The **NotificationManager** implements a 3-tier escalation system:

```
Tier 1: User ignores
   ↓ (after 2 minutes)
Tier 2: User ignores
   ↓ (after 5 minutes, mandatory breaks only)
Tier 3: Mandatory acknowledgment
```

**Tier 1 - System Notification (lines 206-230):**
```swift
private func sendTier1Notification(breakType: BreakType) {
    let content = UNMutableNotificationContent()
    content.title = "Time for a \(breakType.displayName)"
    content.body = breakType.ruleDescription
    content.sound = .default
    
    let request = UNNotificationRequest(
        identifier: "eyeguard.break.\(breakType.rawValue)",
        content: content,
        trigger: nil  // Deliver immediately
    )
    
    UNUserNotificationCenter.current().add(request) { error in ... }
}
```

**Tier 2 - Floating Overlay Window (lines 234-261):**
- Shown after 2 minutes of ignoring Tier 1
- Appears in top-right corner
- Semi-transparent blur background
- Requires user interaction (Take Break / Skip buttons)

**Tier 3 - Full-Screen Overlay (lines 265-289):**
- Shown after 5 minutes (only for mandatory breaks)
- Covers entire screen on all monitors
- 15-minute countdown timer
- Cannot be easily dismissed
- Allows up to 2 × 5-minute extensions

### 2.2 Escalation Chain (NotificationManager.notify, lines 65-123)

```swift
func notify(
    breakType: BreakType,
    healthScore: Int,
    onTaken: @escaping @Sendable () -> Void,
    onSkipped: @escaping @Sendable () -> Void
) {
    guard !isNotificationActive else { return }
    
    isNotificationActive = true
    currentTier = .gentle
    currentHealthScore = healthScore
    
    // Store callbacks for later (H4 pattern)
    self.onTakenCallback = onTaken
    self.onSkippedCallback = onSkipped
    
    // Send Tier 1
    sendTier1Notification(breakType: breakType)
    
    // Start escalation chain
    escalationTask = Task {
        // Wait Tier 1 → Tier 2 (2 minutes)
        try? await Task.sleep(for: .seconds(EyeGuardConstants.tier1EscalationDelay))
        guard !Task.isCancelled else { return }
        
        await MainActor.run {
            self.currentTier = .firm
            self.showTier2Overlay(breakType: breakType)
        }
        
        // If mandatory, wait Tier 2 → Tier 3 (5 minutes)
        if breakType == .mandatory {
            try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.currentTier = .mandatory
                self.showTier3Fullscreen(breakType: breakType)
            }
            
            // After Tier 3 timeout (5 minutes), invoke onSkipped if still not acknowledged
            try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.handleEscalationTimeout()  // Invokes onSkipped
            }
        } else {
            // Non-mandatory: after Tier 2 timeout (5 minutes), invoke onSkipped
            try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.handleEscalationTimeout()
            }
        }
    }
}
```

---

## Part 3: Popup Window Implementation (View Layer)

### 3.1 OverlayWindow - Window Controller (OverlayWindow.swift)

This is the **NSWindow** management layer for Tier 2 and Tier 3 overlays.

**Tier 2 Window Properties (lines 71-100):**

```swift
func showBreakOverlay(
    breakType: BreakType,
    healthScore: Int = 100,
    onTaken: @escaping @Sendable () -> Void,
    onSkipped: @escaping @Sendable () -> Void
) {
    // Dismiss any existing overlay first
    if isShowing {
        dismissImmediate()
    }
    
    let contentView = BreakOverlayView(
        breakType: breakType,
        healthScore: healthScore,
        onTaken: onTaken,
        onSkipped: onSkipped,
        onDismiss: { [weak self] in
            self?.dismiss()
        }
    )
    
    let hostingView = NSHostingView(rootView: contentView)
    
    let overlayWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 340, height: 300),
        styleMask: [.borderless],           // No title bar
        backing: .buffered,
        defer: false
    )
    
    overlayWindow.contentView = hostingView
    overlayWindow.level = .floating        // Above other windows but not fullscreen
    overlayWindow.isOpaque = false         // Transparent background
    overlayWindow.backgroundColor = .clear
    overlayWindow.hasShadow = true
    overlayWindow.isMovableByWindowBackground = true  // User can drag
    overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
    overlayWindow.isReleasedWhenClosed = false
    
    // Position top-right with 20pt margin
    positionTopRight(overlayWindow)
    
    // Show with fade-in animation (300ms)
    overlayWindow.alphaValue = 0
    overlayWindow.makeKeyAndOrderFront(nil)
    
    NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.3
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        overlayWindow.animator().alphaValue = 1
    }
    
    self.window = overlayWindow
    Log.notification.info("Overlay window shown for \(breakType.displayName)")
}
```

**Key NSWindow Properties:**
| Property | Value | Purpose |
|----------|-------|---------|
| `level` | `.floating` | Above other windows but not fullscreen (Tier 2) |
| `level` | `.screenSaver` | Above everything, covers entire screen (Tier 3) |
| `isOpaque` | `false` | Supports transparency for blur background |
| `hasShadow` | `true` | Adds drop shadow for visual hierarchy |
| `isMovableByWindowBackground` | `true` | User can drag the window |
| `collectionBehavior` | `[.canJoinAllSpaces, .stationary]` | Visible on all Spaces (desktops) |
| `isReleasedWhenClosed` | `false` | Window object retained in memory |

**Tier 3 Full-Screen Windows (lines 109-172):**

```swift
func showFullScreenOverlay(healthScore: Int, onTaken: @escaping @Sendable () -> Void) {
    // Dismiss any existing overlays first
    dismissFullScreen()
    if isShowing {
        dismissImmediate()
    }
    
    let screens = NSScreen.screens
    guard !screens.isEmpty else {
        Log.notification.warning("No screens available for full-screen overlay.")
        return
    }
    
    // Create one window per monitor
    for (index, screen) in screens.enumerated() {
        let contentView = FullScreenOverlayView(
            healthScore: healthScore,
            onBreakTaken: { [weak self] in
                Task { @MainActor in
                    self?.dismissFullScreen()
                    onTaken()
                }
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        
        let fullScreenWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        fullScreenWindow.contentView = hostingView
        fullScreenWindow.level = .screenSaver    // Covers everything
        fullScreenWindow.isOpaque = false
        fullScreenWindow.backgroundColor = .clear
        fullScreenWindow.hasShadow = false
        fullScreenWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        fullScreenWindow.isReleasedWhenClosed = false
        
        // Position to cover entire screen
        fullScreenWindow.setFrame(screen.frame, display: true)
        
        // Fade in animation
        fullScreenWindow.alphaValue = 0
        fullScreenWindow.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            fullScreenWindow.animator().alphaValue = 1
        }
        
        fullScreenWindows.append(fullScreenWindow)
    }
}
```

### 3.2 BreakOverlayView - Tier 2 UI (BreakOverlayView.swift)

The SwiftUI view shown in the Tier 2 floating window.

**State:**

```swift
struct BreakOverlayView: View {
    let breakType: BreakType
    let healthScore: Int
    let onTaken: @Sendable () -> Void
    let onSkipped: @Sendable () -> Void
    let onDismiss: @MainActor () -> Void
    
    @State private var countdown: Int = 0
    @State private var isBreaking: Bool = false
    @State private var showExercises: Bool = false
    @State private var timer: Timer?
    @State private var appeared: Bool = false
}
```

**UI Sections (lines 49-83):**

```swift
var body: some View {
    VStack(spacing: 16) {
        iconSection              // Break type icon with pulse animation
        titleSection             // "Time for an eye break!"
        healthScoreSection       // Health score 0-100 with motivation
        
        if showExercises {
            exerciseSessionSection  // Eye exercises interface
        } else if isBreaking {
            countdownSection        // Countdown timer + progress bar
        }
        
        if !showExercises {
            buttonSection           // "Take Break", "Skip", "Start Exercises"
        }
    }
    .padding(24)
    .frame(width: 320, height: 280)
    .background(.ultraThinMaterial)     // Frosted glass effect
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    .scaleEffect(appeared ? 1.0 : 0.95)
    .onAppear {
        withAnimation(.spring(duration: 0.4)) {
            appeared = true
        }
    }
    .onDisappear {
        stopTimer()
    }
}
```

**User Interactions:**

```swift
// User taps "Take Break"
private func startBreak() {
    isBreaking = true
    countdown = breakDurationSeconds  // E.g., 20 for micro
    startCountdownTimer()
}

// Timer counts down (every 1 second)
private func startCountdownTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        Task { @MainActor in
            if countdown > 0 {
                withAnimation {
                    countdown -= 1
                }
            }
            
            if countdown <= 0 {
                completeBreak()  // When countdown reaches 0
            }
        }
    }
}

// Break countdown completes
private func completeBreak() {
    stopTimer()
    onTaken()        // Callback to BreakScheduler
    onDismiss()      // Callback to OverlayWindowController
}

// User taps "Skip"
private func skipBreak() {
    stopTimer()
    onSkipped()      // Callback to BreakScheduler
    onDismiss()      // Dismisses the window
}
```

### 3.3 FullScreenOverlayView - Tier 3 UI (FullScreenOverlayView.swift)

The SwiftUI view for mandatory break full-screen overlay.

**State:**

```swift
struct FullScreenOverlayView: View {
    let healthScore: Int
    let onBreakTaken: @Sendable () -> Void
    
    @State private var isCountingDown: Bool = false
    @State private var remainingSeconds: Int = 15 * 60  // 900 seconds
    @State private var totalDuration: Int = 15 * 60
    @State private var extensionsUsed: Int = 0
    @State private var timer: Timer?
    @State private var appeared: Bool = false
    @State private var isPulsing: Bool = false
    @State private var currentTip: String = medicalTips.randomElement() ?? medicalTips[0]
    
    private let maxExtensions = 2
    private let extensionSeconds = 5 * 60
}
```

**UI Layout:**

```swift
var body: some View {
    ZStack {
        // Semi-transparent dark background
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        // Blur effect
        VisualEffectBlur()
            .ignoresSafeArea()
        
        // Center content
        VStack(spacing: 24) {
            // Warning icon (pulsing)
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
                .symbolEffect(.pulse, options: .repeating, isActive: true)
            
            // Warning message
            Text("⚠️ You've been using the screen for over 2 hours!")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            
            Text("Your eyes need a longer break. Step away for 15 minutes.")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
            
            // Circular countdown with progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.green, .blue, .green],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)
                
                Text(countdownText)  // "MM:SS"
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            
            // Buttons
            VStack(spacing: 12) {
                if !isCountingDown {
                    Button(action: startBreak) {
                        Label("Take 15-min Break", systemImage: "leaf.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: 280)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    if extensionsUsed < maxExtensions {
                        Button(action: requestExtension) {
                            Text("I Need 5 More Minutes (\(maxExtensions - extensionsUsed) left)")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("Taking a break... your eyes thank you! 👁️")
                        .font(.system(size: 14))
                        .foregroundStyle(.green.opacity(0.9))
                }
            }
        }
        .padding(48)
        .frame(maxWidth: 520)
    }
    .opacity(appeared ? 1.0 : 0.0)
    .onAppear {
        withAnimation(.easeIn(duration: 0.5)) {
            appeared = true
        }
    }
}
```

**Countdown Logic:**

```swift
private func startBreak() {
    isCountingDown = true
    totalDuration = remainingSeconds
    startCountdownTimer()
}

private func startCountdownTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        Task { @MainActor in
            if remainingSeconds > 0 {
                withAnimation {
                    remainingSeconds -= 1
                }
            }
            
            if remainingSeconds <= 0 {
                completeBreak()  // Invokes onBreakTaken
            }
        }
    }
}

private func requestExtension() {
    guard extensionsUsed < maxExtensions else { return }
    extensionsUsed += 1
    
    // Add 5 minutes to countdown
    remainingSeconds += extensionSeconds      // +300 seconds
    totalDuration += extensionSeconds
}
```

---

## Part 4: Timer Logic - How Long Popup Stays Visible

### 4.1 Tier 2 Popup Duration

**Controlled by:** BreakOverlayView countdown timer

**Duration:** Break type duration
- **Micro-break**: 20 seconds (countdown from 20 to 0)
- **Macro-break**: 5 minutes (countdown from 300 to 0)
- **Mandatory-break**: Normally 15 minutes, but triggers full-screen first

**Code (BreakOverlayView.swift, lines 253-267):**

```swift
private func startCountdownTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        Task { @MainActor in
            if countdown > 0 {
                withAnimation {
                    countdown -= 1
                }
            }
            
            // When countdown reaches 0, the break is complete
            if countdown <= 0 {
                completeBreak()  // Calls onTaken() and onDismiss()
            }
        }
    }
}

private var breakDurationSeconds: Int {
    Int(breakType.duration)  // E.g., 20, 300, or 900 seconds
}
```

### 4.2 Tier 3 Full-Screen Popup Duration

**Controlled by:** FullScreenOverlayView countdown timer

**Duration:** 15 minutes (900 seconds) + up to 10 additional minutes via extensions

**Code (FullScreenOverlayView.swift, lines 298-312):**

```swift
@State private var remainingSeconds: Int = 15 * 60  // 900 seconds = 15 minutes
@State private var totalDuration: Int = 15 * 60

private func startCountdownTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        Task { @MainActor in
            if remainingSeconds > 0 {
                withAnimation {
                    remainingSeconds -= 1
                }
            }
            
            if remainingSeconds <= 0 {
                completeBreak()  // Invokes onBreakTaken()
            }
        }
    }
}

private func requestExtension() {
    guard extensionsUsed < maxExtensions else { return }  // Max 2 extensions
    extensionsUsed += 1
    
    let extensionSeconds = 5 * 60  // 300 seconds
    remainingSeconds += extensionSeconds    // +5 minutes
    totalDuration += extensionSeconds
}
```

### 4.3 Escalation Timeouts (If User Does Nothing)

From **NotificationManager.swift** (lines 65-123):

**For Non-Mandatory Breaks (Micro/Macro):**

```
Tier 1 (System notification)
   ↓ 2 minutes (tier1EscalationDelay)
Tier 2 (Overlay window with user countdown)
   ↓ 5 minutes (tier2EscalationDelay)
Auto-dismiss, onSkipped callback invoked
```

**For Mandatory Breaks:**

```
Tier 1 (System notification)
   ↓ 2 minutes
Tier 2 (Overlay window)
   ↓ 5 minutes
Tier 3 (Full-screen, 15-minute countdown)
   ↓ 15 minutes (user takes break)
     OR
   → Max 2 × 5-minute extensions (30 total minutes possible)
     OR
   → After 5 more minutes without user action, onSkipped invoked
```

**Exact Code:**

```swift
// Non-mandatory break escalation
} else {
    // Non-mandatory: after Tier 2 timeout (5 minutes), invoke onSkipped (H4)
    try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
    guard !Task.isCancelled else { return }
    
    await MainActor.run {
        self.handleEscalationTimeout()  // Invokes onSkipped callback
    }
}

// Mandatory break escalation with Tier 3
if breakType == .mandatory {
    try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
    guard !Task.isCancelled else { return }
    
    // Show Tier 3 full-screen
    await MainActor.run {
        self.currentTier = .mandatory
        self.showTier3Fullscreen(breakType: breakType)
    }
    
    // After Tier 3 timeout (5 minutes), invoke onSkipped if still not acknowledged
    try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))
    guard !Task.isCancelled else { return }
    
    await MainActor.run {
        self.handleEscalationTimeout()  // Invokes onSkipped
    }
}
```

---

## Part 5: Dismiss/Close Logic

### 5.1 Dismissal Workflows

There are multiple ways a popup can be dismissed:

#### **5.1.1 User Takes Break (Completes Countdown)**

```
BreakOverlayView.completeBreak()
    ↓
1. stopTimer()        - Cancel the countdown timer
2. onTaken()          - Callback to NotificationManager.acknowledgeBreak()
3. onDismiss()        - Callback to OverlayWindowController.dismiss()

OverlayWindowController.dismiss()
    ↓
NSAnimationContext.runAnimationGroup({
    context.duration = 0.3
    overlayWindow.animator().alphaValue = 0
}, completionHandler: {
    overlayWindow.close()
    self.window = nil
})
```

#### **5.1.2 User Skips Break**

```
BreakOverlayView.skipBreak()
    ↓
1. stopTimer()
2. onSkipped()        - Callback to NotificationManager's skip handler
3. onDismiss()        - Callback to OverlayWindowController.dismiss()

// Same fade-out animation as above
```

#### **5.1.3 User Acknowledges Full Break (Completes 15-min countdown)**

```
FullScreenOverlayView.completeBreak()
    ↓
1. stopTimer()
2. onBreakTaken()     - Callback triggers OverlayWindowController.dismissFullScreen()
3. dismissFullScreen() - Loops through all full-screen windows

for fsWindow in fullScreenWindows {
    NSAnimationContext.runAnimationGroup({
        context.duration = 0.3
        fsWindow.animator().alphaValue = 0
    }, completionHandler: {
        fsWindow.close()
    })
}
```

#### **5.1.4 Escalation Timeout (No User Action)**

```
NotificationManager.handleEscalationTimeout()
    ↓
1. dismissAllOverlays()
2. isNotificationActive = false
3. onSkippedCallback?()    - Callback to BreakScheduler.skipBreak()

dismissAllOverlays()
    ↓
1. UNUserNotificationCenter.removeDeliveredNotifications()
2. overlayController.dismiss()       - Fade out Tier 2
3. overlayController.dismissFullScreen() - Fade out Tier 3
```

#### **5.1.5 New Break Interrupts Old One**

```
OverlayWindowController.showBreakOverlay(...) {
    if isShowing {
        dismissImmediate()  // Close immediately without animation
    }
    // Show new overlay
}

private func dismissImmediate() {
    window?.close()
    window = nil
}
```

### 5.2 Dismiss Methods in OverlayWindowController

#### **dismiss() - Tier 2 with animation**

```swift
func dismiss() {
    guard let overlayWindow = window else { return }
    
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.3
        context.timingFunction = CAMediaTimingFunction(name: .easeIn)
        overlayWindow.animator().alphaValue = 0
    }, completionHandler: {
        Task { @MainActor [weak self] in
            overlayWindow.close()
            self?.window = nil
            Log.notification.info("Overlay window dismissed.")
        }
    })
}
```

#### **dismissFullScreen() - All Tier 3 windows with animation**

```swift
func dismissFullScreen() {
    guard !fullScreenWindows.isEmpty else { return }
    
    let windows = fullScreenWindows
    fullScreenWindows = []
    
    for fsWindow in windows {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            fsWindow.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                fsWindow.close()
            }
        })
    }
    
    Log.notification.info("Full-screen overlay windows dismissed.")
}
```

#### **dismissImmediate() - Instant close (no animation)**

```swift
private func dismissImmediate() {
    window?.close()
    window = nil
}
```

### 5.3 Potential Issues - Why Popup Might Close Too Quickly

**Issue 1: Early Dismissal from Escalation Timeout**

If a user ignores Tier 2 for exactly 5 minutes without clicking "Take Break", the escalation timeout triggers:

```swift
// Tier 2 timeout
try? await Task.sleep(for: .seconds(EyeGuardConstants.tier2EscalationDelay))  // 5 minutes
guard !Task.isCancelled else { return }

await MainActor.run {
    self.handleEscalationTimeout()  // Dismisses overlay
}
```

This closes the overlay automatically after 5 minutes if user hasn't interacted.

**Issue 2: Immediate Dismissal on New Break**

If user doesn't interact but a new break becomes due (e.g., 20 minutes for micro-break), the new overlay replaces the old one:

```swift
// In showBreakOverlay
if isShowing {
    dismissImmediate()  // No animation!
}
```

This causes the popup to vanish instantly without fade-out.

**Issue 3: Timer Stops Early**

If the timer callback is interrupted or the view goes out of scope before countdown completes:

```swift
@State private var timer: Timer?

.onDisappear {
    stopTimer()  // Stops countdown immediately when view disappears
}

private func stopTimer() {
    timer?.invalidate()
    timer = nil
}
```

**Issue 4: Callback Invoked Prematurely**

If `onTaken` callback is invoked before countdown reaches 0, it immediately dismisses:

```swift
private func completeBreak() {
    stopTimer()
    onTaken()    // ← If this is called early, window dismisses
    onDismiss()
}
```

**Issue 5: Focus Loss or Window Ordering**

NSWindow with `.floating` level might lose key window status, causing it to hide:

```swift
overlayWindow.level = .floating  // Above other windows but not fullscreen
overlayWindow.makeKeyAndOrderFront(nil)  // Make it the key window
```

If another app steals focus or system action occurs, the overlay could be hidden.

---

## Part 6: Project Structure Summary

### 6.1 Key Files Organization

```
EyeGuard/Sources/
├── Scheduling/
│   ├── BreakScheduler.swift     ← Main timer engine, break due detection
│   └── BreakType.swift          ← Enum: micro, macro, mandatory
│
├── Notifications/
│   ├── NotificationManager.swift  ← 3-tier escalation orchestrator
│   ├── OverlayWindow.swift       ← NSWindow management
│   ├── BreakOverlayView.swift    ← SwiftUI Tier 2 UI
│   └── FullScreenOverlayView.swift ← SwiftUI Tier 3 UI
│
├── Monitoring/
│   └── ActivityMonitor.swift    ← Keyboard/mouse idle detection
│
├── Persistence/
│   └── DataPersistenceManager.swift
│
├── Reporting/
│   └── HealthScoreCalculator.swift
│
├── App/
│   ├── AppDelegate.swift        ← System setup
│   ├── EyeGuardApp.swift
│   └── MenuBarView.swift
│
├── Utils/
│   ├── Constants.swift          ← Timing configuration
│   └── Logging.swift
│
└── ... (other modules: Mascot, Dashboard, AI, etc.)
```

### 6.2 Data Flow

```
BreakScheduler.tick() (every 1 second)
    ↓
checkForDueBreaks()
    ↓
Is a break cycle complete?
    ↓ Yes
triggerBreakNotification(breakType)
    ↓
NotificationManager.notify()
    ↓
1. Send Tier 1 notification
2. Schedule Tier 1→2 escalation (2 min)
3. On escalation: Show Tier 2 overlay
4. For mandatory: Schedule Tier 2→3 escalation (5 min)
5. On escalation: Show Tier 3 full-screen
6. Auto-dismiss if no user action (5 min)
    ↓
User interacts or timeout occurs
    ↓
NotificationManager.acknowledgeBreak() or handleEscalationTimeout()
    ↓
OverlayWindowController.dismiss() or dismissFullScreen()
    ↓
SwiftUI onTaken/onSkipped callbacks
    ↓
BreakScheduler.takeBreakNow() or skipBreak()
    ↓
recordBreak() & resetTimersAfterBreak()
    ↓
Next break timer resets, cycle repeats
```

### 6.3 State Management

- **BreakScheduler** (observable): Manages break timing, health score, session state
- **NotificationManager** (singleton): Manages notification lifecycle, escalation
- **OverlayWindowController** (@MainActor): Manages NSWindow instances
- **BreakOverlayView** (@State): Local countdown timer, user interaction
- **FullScreenOverlayView** (@State): Local countdown timer, extensions

---

## Part 7: Testing Infrastructure

From **OverlayWindowTests.swift**:

```swift
@Suite("OverlayWindowController")
struct OverlayWindowControllerTests {
    
    @Test("Show overlay sets isShowing to true")
    @MainActor
    func showOverlay() {
        let controller = OverlayWindowController()
        
        controller.showBreakOverlay(
            breakType: .micro,
            onTaken: {},
            onSkipped: {}
        )
        
        #expect(controller.isShowing == true)
    }
    
    @Test("Dismiss overlay sets isShowing to false")
    @MainActor
    func dismissOverlay() async throws {
        let controller = OverlayWindowController()
        
        controller.showBreakOverlay(breakType: .micro, onTaken: {}, onSkipped: {})
        #expect(controller.isShowing == true)
        
        controller.dismiss()
        
        // Wait for animation to complete
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(controller.isShowing == false)
    }
    
    @Test("Dismiss when no overlay is no-op")
    @MainActor
    func dismissWhenNotShowing() {
        let controller = OverlayWindowController()
        
        // Should not crash
        controller.dismiss()
        #expect(controller.isShowing == false)
    }
}
```

---

## Summary Table

| Aspect | Details |
|--------|---------|
| **Trigger** | BreakScheduler.tick() every 1 second checks if break is due |
| **Detection** | checkForDueBreaks() compares elapsed time vs configured interval |
| **Notification** | NotificationManager.notify() with 3-tier escalation |
| **Tier 1 Delay** | 2 minutes (tier1EscalationDelay = 120 seconds) |
| **Tier 2 Window** | NSWindow at `.floating` level, top-right corner, 340×300 |
| **Tier 2 Display** | BreakOverlayView with "Take Break" / "Skip" buttons |
| **Tier 2 Duration** | Break type duration (20s, 5m, or 15m) + 5m timeout |
| **Tier 3 Delay** | 5 minutes after Tier 2 (mandatory breaks only) |
| **Tier 3 Window** | NSWindow at `.screenSaver` level, full-screen per monitor |
| **Tier 3 Display** | FullScreenOverlayView with 15-minute countdown |
| **Tier 3 Duration** | 15 minutes + up to 2×5-minute extensions |
| **Dismissal** | Fade-out animation (300ms) then window.close() |
| **Early Close Trigger** | User clicks "Take Break", 5-minute timeout, or new break replaces |

---

## Keywords Found

✅ **reminder** - break notification system
✅ **break** - core concept (micro, macro, mandatory)
✅ **rest** - handled as idle detection
✅ **popup** - BreakOverlayView (Tier 2), FullScreenOverlayView (Tier 3)
✅ **overlay** - OverlayWindow, BreakOverlayView, FullScreenOverlayView
✅ **alert** - system notifications (Tier 1)
✅ **notification** - 3-tier system in NotificationManager
✅ **timer** - Timer.scheduledTimer() for countdown
✅ **countdown** - countdown state in views
✅ **dismiss** - multiple dismiss methods
✅ **close** - window?.close() in NSWindow
✅ **window** - NSWindow for Tier 2/3
✅ **NSWindow** - OverlayWindow.swift creates windows
✅ **sheet** - N/A (not used in this project)
✅ **fullscreen** - FullScreenOverlayView for Tier 3
✅ **screen cover** - Tier 3 covers entire screen(s)

