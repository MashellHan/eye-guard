import AppKit
import SwiftUI
import os

/// Controls the floating borderless window that hosts the mascot character.
///
/// The mascot window is:
/// - Always floating above other windows
/// - Transparent background (only the mascot is visible)
/// - Draggable by the user
/// - Visible on all desktops/spaces
/// - Positioned at the bottom-right corner by default
/// - Wired to break events via the scheduler (v1.0)
/// - Tracks mouse position for pupil follow (v1.1)
@MainActor
final class MascotWindowController {

    private var window: NSWindow?

    /// The mascot view model, accessible for external state updates.
    private(set) var viewModel: MascotViewModel?

    /// Reference to the scheduler for state sync.
    private var scheduler: BreakScheduler?

    /// Task for monitoring scheduler state changes.
    private var stateMonitorTask: Task<Void, Never>?

    /// Mouse event monitor for hover tracking (v1.1).
    private var mouseMonitor: Any?

    /// Task for polling mouse position updates.
    private var mouseTrackTask: Task<Void, Never>?

    // MARK: - Peek Mode (v3.1)

    /// Whether the mascot is currently in peek (hidden) mode, showing only eyes/ears.
    private var isPeeking: Bool = true

    /// How many points of the mascot are visible in peek mode (ears + eyes ≈ 50pt).
    private let peekVisibleHeight: CGFloat = 50

    /// Auto-hide timer that returns mascot to peek after inactivity.
    private var autoHideTask: Task<Void, Never>?

    /// Whether the user is hovering over the mascot in peek mode.
    private var isHoveringPeek: Bool = false

    /// Task for monitoring speech bubble state to auto-reveal.
    private var bubbleMonitorTask: Task<Void, Never>?

    /// Observer for exercise-from-break notification.
    private var exerciseFromBreakObserver: Any?

    /// Observer for menu-bar "Show Tip" notification.
    private var showTipObserver: Any?

    /// Observer for pre-alert started notification.
    private var preAlertStartedObserver: Any?

    /// Observer for pre-alert countdown notification.
    private var preAlertCountdownObserver: Any?

    /// Observer for pre-alert cancelled notification.
    private var preAlertCancelledObserver: Any?

    /// The popover panel that mirrors the menu bar popover.
    private var popoverWindow: NSPanel?

    /// Event monitor for click-outside-to-dismiss.
    private var clickOutsideMonitor: Any?

    /// Global event monitor for click-outside-to-dismiss.
    private var clickOutsideGlobalMonitor: Any?

    /// Event monitor for Escape key to dismiss popover.
    private var escapeKeyMonitor: Any?

    /// Shows the mascot window on screen.
    ///
    /// - Parameter scheduler: The BreakScheduler to wire mascot state to.
    func show(scheduler: BreakScheduler) {
        guard window == nil else { return }
        self.scheduler = scheduler

        let vm = MascotViewModel()
        self.viewModel = vm

        let containerView = MascotContainerView(
            viewModel: vm,
            scheduler: scheduler,
            onTap: { [weak self] in
                self?.handleMascotTap()
            },
            onHoverChanged: { [weak self] isHovering in
                self?.handleMascotHover(isHovering: isHovering)
            },
            onTakeBreak: { [weak self] in
                self?.handleTakeBreak()
            },
            onSnooze: { [weak self] in
                self?.handleSnooze()
            },
            onGenerateReport: { [weak self] in
                self?.handleGenerateReport()
            },
            onStartExercises: { [weak self] in
                self?.handleStartExercises()
            },
            onShowTip: { [weak self] in
                self?.handleShowTip()
            },
            onDashboard: { [weak self] in
                self?.handleDashboard()
            }
        )
        let hostingView = NSHostingView(rootView: containerView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 120, height: 130)

        let mascotWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 130),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        mascotWindow.level = .floating
        mascotWindow.isOpaque = false
        mascotWindow.backgroundColor = .clear
        mascotWindow.hasShadow = false
        mascotWindow.ignoresMouseEvents = false
        mascotWindow.isMovableByWindowBackground = false  // Disable drag in peek mode
        mascotWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        mascotWindow.contentView = hostingView

        // Start in peek position (only eyes/ears visible)
        isPeeking = true
        positionBottomRight(mascotWindow)

        mascotWindow.makeKeyAndOrderFront(nil)
        window = mascotWindow

        // Start mouse tracking for pupil follow (v1.1)
        startMouseTracking()

        // Start bubble monitor for auto-reveal on messages (v3.1)
        startBubbleMonitor()

        // Listen for exercise-from-break notifications (v2.5)
        exerciseFromBreakObserver = NotificationCenter.default.addObserver(
            forName: .startExercisesFromBreak,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showExerciseWindow()
            }
        }

        // Listen for "Tip" requests from the menu bar.
        showTipObserver = NotificationCenter.default.addObserver(
            forName: .showEyeTipRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleShowTip()
            }
        }

        Log.mascot.info("Mascot window shown in peek mode at bottom-right corner.")

        // Listen for pre-alert notifications (v3.2)
        setupPreAlertObservers()
    }

    // MARK: - Pre-Alert Messages (v3.2)

    /// Random pre-alert messages by break type.
    private static let preAlertMessages: [BreakType: [String]] = [
        .micro: [
            "👀 还有 {N} 秒，该让眼睛休息一下了~",
            "🌿 马上进入 20 秒眼休息~",
            "💧 准备好了吗？20 秒远眺时间~",
        ],
        .macro: [
            "☕ 还有 {N} 秒，该起来活动了~",
            "🧘 5 分钟大休息马上开始~",
            "🚶 准备站起来走走吧~",
        ],
        .mandatory: [
            "⚠️ 你已经连续工作很久了！{N} 秒后强制休息",
            "🛑 15 分钟休息倒计时即将开始！",
            "🔴 眼睛需要好好休息了！马上进入休息模式",
        ],
    ]

    /// Sets up NotificationCenter observers for pre-alert events.
    private func setupPreAlertObservers() {
        preAlertStartedObserver = NotificationCenter.default.addObserver(
            forName: .preAlertStarted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let breakType = notification.userInfo?["breakType"] as? BreakType
            let seconds = notification.userInfo?["seconds"] as? Int
            Task { @MainActor in
                guard let breakType, let seconds else { return }
                self?.handlePreAlertStarted(breakType: breakType, seconds: seconds)
            }
        }

        preAlertCountdownObserver = NotificationCenter.default.addObserver(
            forName: .preAlertCountdown,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let remaining = notification.userInfo?["remaining"] as? Int
            Task { @MainActor in
                guard let remaining else { return }
                self?.handlePreAlertCountdown(remaining: remaining)
            }
        }

        preAlertCancelledObserver = NotificationCenter.default.addObserver(
            forName: .preAlertCancelled,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handlePreAlertCancelled()
            }
        }
    }

    /// Handles the start of a pre-alert countdown.
    private func handlePreAlertStarted(breakType: BreakType, seconds: Int) {
        // Transition to concerned state
        viewModel?.transition(to: .concerned)

        // Show message with break-specific text
        let messages = Self.preAlertMessages[breakType] ?? ["⏰ 休息即将开始~"]
        let message = (messages.randomElement() ?? "").replacingOccurrences(of: "{N}", with: "\(seconds)")
        viewModel?.showMessage(message, duration: Double(seconds))

        // Play alert sound
        SoundManager.shared.play(.alert)

        // Reveal from peek mode
        if isPeeking {
            revealMascot()
        }
        cancelAutoHide() // Stay visible during pre-alert

        Log.mascot.info("Pre-alert started for \(breakType.displayName): \(seconds)s")
    }

    /// Handles countdown updates during pre-alert.
    private func handlePreAlertCountdown(remaining: Int) {
        // Last 5 seconds: show countdown numbers
        if remaining <= 5 && remaining > 0 {
            viewModel?.showMessage("\(remaining)...", duration: 1.5)
        }

        // Last 3 seconds: escalate to alerting state
        if remaining == 3 {
            viewModel?.transition(to: .alerting)
        }
    }

    /// Handles pre-alert cancellation (idle detected, postponed, etc.).
    private func handlePreAlertCancelled() {
        viewModel?.transition(to: .idle)
        viewModel?.hideBubble()
        scheduleAutoHide(after: 3)
        Log.mascot.info("Pre-alert cancelled — returning to idle.")
    }

    /// Hides the mascot window.
    func hide() {
        stateMonitorTask?.cancel()
        stateMonitorTask = nil
        autoHideTask?.cancel()
        autoHideTask = nil
        bubbleMonitorTask?.cancel()
        bubbleMonitorTask = nil
        popoverWindow?.close()
        removeClickOutsideMonitor()
        popoverWindow = nil
        if let observer = exerciseFromBreakObserver {
            NotificationCenter.default.removeObserver(observer)
            exerciseFromBreakObserver = nil
        }
        if let observer = showTipObserver {
            NotificationCenter.default.removeObserver(observer)
            showTipObserver = nil
        }
        for observer in [preAlertStartedObserver, preAlertCountdownObserver, preAlertCancelledObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
        preAlertStartedObserver = nil
        preAlertCountdownObserver = nil
        preAlertCancelledObserver = nil
        stopMouseTracking()
        window?.orderOut(nil)
        window = nil
        viewModel = nil
        scheduler = nil
        Log.mascot.info("Mascot window hidden.")
    }

    /// Repositions the mascot to the bottom-right corner of the main screen.
    /// Respects current peek/full mode.
    func reposition() {
        guard let window else { return }
        positionBottomRight(window)
    }

    // MARK: - Break Actions

    /// Handles "Take Break Now" from mascot context menu.
    /// Directly shows the break overlay (skipping tiered escalation).
    private func handleTakeBreak() {
        guard let scheduler else { return }
        let breakType = scheduler.nextScheduledBreak ?? .micro

        // Manual break: use .direct escalation to show overlay immediately,
        // with .skippable dismiss policy so user can cancel if needed.
        let behavior = BreakBehavior(
            interval: 0,
            duration: breakType.duration,
            isEnabled: true,
            entryTier: .fullScreen,
            dismissPolicy: .skippable
        )

        NotificationManager.shared.notify(
            breakType: breakType,
            behavior: behavior,
            escalation: .direct,
            healthScore: scheduler.currentHealthScore,
            onTaken: {
                Task { @MainActor in
                    scheduler.takeBreakNow(breakType)
                }
            },
            onSkipped: {
                Task { @MainActor in
                    scheduler.skipBreak(breakType)
                }
            },
            onPostponed: { delay in
                Task { @MainActor in
                    scheduler.postponeBreak(breakType, by: delay)
                }
            }
        )
        Log.mascot.info("Mascot: user initiated break via mascot menu.")
    }

    /// Handles "Snooze 5 min" from mascot context menu.
    private func handleSnooze() {
        guard let scheduler else { return }
        let breakType = scheduler.nextScheduledBreak ?? .micro
        NotificationManager.shared.snooze(breakType: breakType) {
            Task { @MainActor in
                scheduler.takeBreakNow(breakType)
            }
        }
        Log.mascot.info("Mascot: user snoozed via mascot menu.")
    }

    /// Handles "Generate Report" from mascot context menu.
    private func handleGenerateReport() {
        Task { @MainActor in
            let data = ReportDataProvider.shared.currentData()
            let generator = DailyReportGenerator()
            _ = await generator.generate(
                sessions: data.sessions,
                breakEvents: data.breakEvents,
                totalScreenTime: data.totalScreenTime,
                longestContinuousSession: data.longestContinuousSession
            )
            NSWorkspace.shared.open(EyeGuardConstants.reportsDirectory)
        }
        Log.mascot.info("Mascot: user requested report via mascot menu.")
    }

    /// Handles "Start Eye Exercises" from mascot context menu.
    /// Opens a floating exercise session window.
    private func handleStartExercises() {
        showExerciseWindow()
        Log.mascot.info("Mascot: user started eye exercises via mascot menu.")
    }

    /// Handles "Show Eye Tip" from mascot context menu.
    /// Shows a random eye health tip in the mascot speech bubble.
    private func handleShowTip() {
        let tip = TipDatabase.randomTip()
        viewModel?.showMessage(tip.shortBubbleText, duration: 15)
        Log.mascot.info("Mascot: showing eye tip #\(tip.id): \(tip.title)")
    }

    /// Handles "Dashboard" from mascot context menu.
    /// Opens the dashboard window with historical charts.
    private func handleDashboard() {
        guard let scheduler else { return }
        DashboardWindowController.shared.showDashboard(scheduler: scheduler)
        Log.mascot.info("Mascot: opened dashboard via mascot menu.")
    }

    /// The exercise session fullscreen overlay windows (one per screen, feature-005).
    private var exerciseWindows: [NSWindow] = []

    /// Shows the exercise session in a fullscreen overlay covering all screens (feature-005).
    func showExerciseWindow() {
        // Dismiss any existing exercise windows
        dismissExerciseWindow()

        // Transition mascot to resting/exercising state
        viewModel?.restingMode = .exercising
        viewModel?.transition(to: .resting)
        viewModel?.showMessage("👁️ 跟着做眼保健操吧！", duration: 30)

        let screens = NSScreen.screens
        guard !screens.isEmpty else { return }

        for (index, screen) in screens.enumerated() {
            let isPrimaryScreen = index == 0

            // Only the primary screen gets the interactive exercise view;
            // secondary screens show a dark overlay only (review-011 M1)
            let fullscreenContent: AnyView
            if isPrimaryScreen {
                let sessionView = ExerciseSessionView(
                    onComplete: { [weak self] in
                        self?.dismissExerciseWindow()
                        self?.viewModel?.transition(to: .celebrating)
                        self?.viewModel?.showMessage("👏 眼保健操做完了！好棒！")
                        self?.scheduler?.recordExerciseSession()
                    },
                    onSkip: { [weak self] in
                        self?.dismissExerciseWindow()
                        self?.viewModel?.transition(to: .idle)
                    }
                )

                fullscreenContent = AnyView(
                    ZStack {
                        Color.black.opacity(0.65)
                            .ignoresSafeArea()
                        VisualEffectBlur()
                            .ignoresSafeArea()
                        sessionView
                    }
                )
            } else {
                // Secondary screens: dark overlay only, no timer/TTS
                fullscreenContent = AnyView(
                    ZStack {
                        Color.black.opacity(0.65)
                            .ignoresSafeArea()
                        VisualEffectBlur()
                            .ignoresSafeArea()
                    }
                )
            }

            let hostingView = NSHostingView(rootView: fullscreenContent)

            let exWindow = KeyableWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            exWindow.contentView = hostingView
            exWindow.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            exWindow.ignoresMouseEvents = !isPrimaryScreen  // Secondary screens are non-interactive
            exWindow.isOpaque = false
            exWindow.backgroundColor = .clear
            exWindow.hasShadow = false
            exWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
            exWindow.isReleasedWhenClosed = false
            exWindow.setFrame(screen.frame, display: true)

            exWindow.alphaValue = 0
            exWindow.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                exWindow.animator().alphaValue = 1
            }

            exerciseWindows.append(exWindow)

            Log.mascot.info(
                "Exercise fullscreen overlay shown on screen \(index + 1) of \(screens.count)"
            )
        }
    }

    /// Dismisses all exercise session fullscreen windows.
    private func dismissExerciseWindow() {
        guard !exerciseWindows.isEmpty else { return }

        let windows = exerciseWindows
        exerciseWindows = []

        for exWindow in windows {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                exWindow.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    exWindow.close()
                }
            })
        }
    }

    // MARK: - Mouse Tracking (v1.1)

    /// Starts a polling task that reads the global mouse position and updates
    /// the mascot pupil to follow the cursor.
    private func startMouseTracking() {
        mouseTrackTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.1)) // 10 fps polling
                guard !Task.isCancelled else { return }

                guard let window = self.window, let viewModel = self.viewModel else { continue }

                let mouseLocation = NSEvent.mouseLocation
                let windowFrame = window.frame
                let mascotCenter = CGPoint(
                    x: windowFrame.midX,
                    y: windowFrame.midY
                )

                viewModel.updateHoverPupil(
                    mousePosition: mouseLocation,
                    mascotCenter: mascotCenter
                )
            }
        }
    }

    /// Stops mouse tracking.
    private func stopMouseTracking() {
        mouseTrackTask?.cancel()
        mouseTrackTask = nil
        viewModel?.stopHoverTracking()
    }

    // MARK: - Private

    /// Places the window at the bottom-right of the main screen's visible frame.
    /// In peek mode, pushes the window down so only `peekVisibleHeight` pt are visible.
    private func positionBottomRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - window.frame.width - 20

        let y: CGFloat
        if isPeeking {
            // Push window below screen edge so only top portion (ears+eyes) is visible
            y = visibleFrame.minY - (window.frame.height - peekVisibleHeight)
        } else {
            // Full mode: window fully visible above screen bottom
            y = visibleFrame.minY + 20
        }

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - Peek Mode Transitions (v3.1)

    /// Reveals the mascot from peek mode to full mode with spring animation.
    private func revealMascot() {
        guard isPeeking, let window, let screen = NSScreen.main else { return }
        isPeeking = false
        cancelAutoHide()

        // Enable dragging in full mode
        window.isMovableByWindowBackground = true

        let visibleFrame = screen.visibleFrame
        let targetY = visibleFrame.minY + 20

        // Animate window position with spring-like effect
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true
            window.animator().setFrameOrigin(NSPoint(x: window.frame.origin.x, y: targetY))
        }

        // Trigger pop bounce on the mascot character
        viewModel?.triggerPopBounce()

        // Schedule auto-hide after 5 seconds
        scheduleAutoHide()

        Log.mascot.info("Mascot revealed from peek mode.")
    }

    /// Hides the mascot back to peek mode with smooth animation.
    private func retractMascot() {
        guard !isPeeking, let window, let screen = NSScreen.main else { return }

        // Don't retract if context menu is open or bubble is showing
        if viewModel?.showBubble == true { return }

        // Dismiss popover before retracting
        if let popover = popoverWindow {
            dismissPopover(popover)
        }

        isPeeking = true
        cancelAutoHide()

        // Disable dragging in peek mode
        window.isMovableByWindowBackground = false

        let visibleFrame = screen.visibleFrame
        let targetY = visibleFrame.minY - (window.frame.height - peekVisibleHeight)

        // Reset X position to bottom-right (in case user dragged it)
        let targetX = visibleFrame.maxX - window.frame.width - 20

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            window.animator().setFrameOrigin(NSPoint(x: targetX, y: targetY))
        }

        Log.mascot.info("Mascot retracted to peek mode.")
    }

    /// Schedules auto-retract to peek mode after the given delay.
    private func scheduleAutoHide(after delay: TimeInterval = 5) {
        cancelAutoHide()
        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            retractMascot()
        }
    }

    /// Cancels the auto-hide timer.
    private func cancelAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }

    /// Handles hover state changes in peek mode — micro-float 5pt up on hover.
    private func peekHover(isHovering: Bool) {
        guard isPeeking, let window else { return }
        isHoveringPeek = isHovering

        let offset: CGFloat = isHovering ? 5 : 0
        let currentOrigin = window.frame.origin

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            context.allowsImplicitAnimation = true

            if isHovering {
                window.animator().setFrameOrigin(NSPoint(
                    x: currentOrigin.x,
                    y: currentOrigin.y + offset
                ))
            } else {
                // Return to peek position
                guard let screen = NSScreen.main else { return }
                let visibleFrame = screen.visibleFrame
                let peekY = visibleFrame.minY - (window.frame.height - peekVisibleHeight)
                window.animator().setFrameOrigin(NSPoint(
                    x: currentOrigin.x,
                    y: peekY
                ))
            }
        }
    }

    /// Monitors the viewModel's showBubble state to auto-reveal when a message appears.
    private func startBubbleMonitor() {
        bubbleMonitorTask?.cancel()
        bubbleMonitorTask = Task {
            var lastBubbleState = false
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }

                guard let viewModel = self.viewModel else { continue }

                let currentBubble = viewModel.showBubble

                // Bubble just appeared while peeking → auto-reveal
                if currentBubble && !lastBubbleState && isPeeking {
                    revealMascot()
                    // Extend auto-hide while bubble is showing
                    scheduleAutoHide(after: 8)
                }

                // Bubble just disappeared → schedule retract
                if !currentBubble && lastBubbleState && !isPeeking {
                    scheduleAutoHide(after: 3)
                }

                lastBubbleState = currentBubble
            }
        }
    }

    // MARK: - Tap & Hover Handling (v3.1)

    /// Handles tap on the mascot — reveals if peeking, shows popover if full.
    private func handleMascotTap() {
        if isPeeking {
            revealMascot()
        } else {
            togglePopover()
            // Reset auto-hide timer on interaction
            cancelAutoHide()
        }
    }

    /// Shows or hides the menu-bar-style popover anchored above the mascot.
    private func togglePopover() {
        if let existing = popoverWindow {
            dismissPopover(existing)
            return
        }
        showPopover()
    }

    /// Creates and shows the popover window above the mascot.
    private func showPopover() {
        guard let mascotWindow = window, let scheduler else { return }

        let menuBarView = MenuBarView(scheduler: scheduler)
        let hostingView = NSHostingView(rootView: menuBarView)

        // Size the hosting view to fit content
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: fittingSize)

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: fittingSize),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.level = .floating + 1
        panel.isOpaque = false
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.contentView = hostingView
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isReleasedWhenClosed = false
        // Allow the panel to become key so buttons work
        panel.becomesKeyOnlyIfNeeded = false
        panel.isFloatingPanel = true

        // Round corners
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12
        panel.contentView?.layer?.masksToBounds = true

        // Position above the mascot window
        let mascotFrame = mascotWindow.frame
        let x = mascotFrame.midX - fittingSize.width / 2
        let y = mascotFrame.maxY + 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))

        // Ensure popover stays on screen
        if let screen = NSScreen.main {
            var origin = panel.frame.origin
            if origin.x + fittingSize.width > screen.visibleFrame.maxX {
                origin.x = screen.visibleFrame.maxX - fittingSize.width - 8
            }
            if origin.x < screen.visibleFrame.minX {
                origin.x = screen.visibleFrame.minX + 8
            }
            if origin.y + fittingSize.height > screen.visibleFrame.maxY {
                origin.y = mascotFrame.minY - fittingSize.height - 8
            }
            panel.setFrameOrigin(origin)
        }

        // Fade in
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }

        popoverWindow = panel

        // Auto-dismiss when clicking outside
        removeClickOutsideMonitor()

        clickOutsideGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let popover = self.popoverWindow else { return }
            self.dismissPopover(popover)
        }

        clickOutsideMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let popover = self.popoverWindow else { return event }

            let screenPoint = event.window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow

            if NSMouseInRect(screenPoint, popover.frame, false) {
                return event
            }
            if let mascot = self.window, NSMouseInRect(screenPoint, mascot.frame, false) {
                return event
            }

            self.dismissPopover(popover)
            return event
        }

        // Dismiss on Escape key
        escapeKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                guard let self, let popover = self.popoverWindow else { return event }
                self.dismissPopover(popover)
                return nil // consume the event
            }
            return event
        }

        Log.mascot.info("Mascot popover shown.")
    }

    /// Removes click-outside event monitors.
    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        if let monitor = clickOutsideGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideGlobalMonitor = nil
        }
        if let monitor = escapeKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escapeKeyMonitor = nil
        }
    }

    /// Dismisses the popover window.
    private func dismissPopover(_ panel: NSWindow) {
        removeClickOutsideMonitor()
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                panel.close()
                if self?.popoverWindow === panel {
                    self?.popoverWindow = nil
                }
            }
        })
        scheduleAutoHide()
    }

    /// Handles hover on the mascot — micro-float if peeking, show bubble if full.
    private func handleMascotHover(isHovering: Bool) {
        if isPeeking {
            peekHover(isHovering: isHovering)
        } else if isHovering {
            // Reset auto-hide timer on hover
            cancelAutoHide()
        } else {
            // Mouse left — schedule auto-hide
            scheduleAutoHide()
        }
    }
}
