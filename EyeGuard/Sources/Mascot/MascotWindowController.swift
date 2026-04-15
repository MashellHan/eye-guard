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
    private func handleTakeBreak() {
        guard let scheduler else { return }
        let breakType = scheduler.nextScheduledBreak ?? .micro
        scheduler.takeBreakNow(breakType)
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
