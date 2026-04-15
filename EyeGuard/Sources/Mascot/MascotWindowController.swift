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

    /// Shows the mascot window on screen.
    ///
    /// - Parameter scheduler: The BreakScheduler to wire mascot state to.
    func show(scheduler: BreakScheduler) {
        guard window == nil else { return }
        self.scheduler = scheduler

        let vm = MascotViewModel()
        self.viewModel = vm

        let containerView = MascotContainerView(
            scheduler: scheduler,
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
        mascotWindow.isMovableByWindowBackground = true
        mascotWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        mascotWindow.contentView = hostingView

        // Position at bottom-right corner
        positionBottomRight(mascotWindow)

        mascotWindow.makeKeyAndOrderFront(nil)
        window = mascotWindow

        // Start mouse tracking for pupil follow (v1.1)
        startMouseTracking()

        Log.mascot.info("Mascot window shown at bottom-right corner.")
    }

    /// Hides the mascot window.
    func hide() {
        stateMonitorTask?.cancel()
        stateMonitorTask = nil
        stopMouseTracking()
        window?.orderOut(nil)
        window = nil
        viewModel = nil
        scheduler = nil
        Log.mascot.info("Mascot window hidden.")
    }

    /// Repositions the mascot to the bottom-right corner of the main screen.
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

    /// The exercise session floating window.
    private var exerciseWindow: NSWindow?

    /// Shows the exercise session in a floating window.
    func showExerciseWindow() {
        // Dismiss any existing exercise window
        exerciseWindow?.close()
        exerciseWindow = nil

        // Transition mascot to resting/exercising state
        viewModel?.restingMode = .exercising
        viewModel?.transition(to: .resting)
        viewModel?.showMessage("👁️ 跟着做眼保健操吧！", duration: 30)

        let sessionView = ExerciseSessionView(
            onComplete: { [weak self] in
                self?.dismissExerciseWindow()
                self?.viewModel?.transition(to: .celebrating)
                self?.viewModel?.showMessage("👏 眼保健操做完了！好棒！")
            },
            onSkip: { [weak self] in
                self?.dismissExerciseWindow()
                self?.viewModel?.transition(to: .idle)
            }
        )

        let hostingView = NSHostingView(rootView: sessionView)

        let exWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 640),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        exWindow.contentView = hostingView
        exWindow.level = .floating
        exWindow.isOpaque = false
        exWindow.backgroundColor = .clear
        exWindow.hasShadow = true
        exWindow.isMovableByWindowBackground = true
        exWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        exWindow.isReleasedWhenClosed = false

        // Position at center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 210
            let y = screenFrame.midY - 320
            exWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }

        exWindow.alphaValue = 0
        exWindow.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            exWindow.animator().alphaValue = 1
        }

        exerciseWindow = exWindow
    }

    /// Dismisses the exercise session window.
    private func dismissExerciseWindow() {
        guard let exWindow = exerciseWindow else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            exWindow.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor [weak self] in
                exWindow.close()
                self?.exerciseWindow = nil
            }
        })
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
    private func positionBottomRight(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.maxX - window.frame.width - 20
        let y = visibleFrame.minY + 20
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
