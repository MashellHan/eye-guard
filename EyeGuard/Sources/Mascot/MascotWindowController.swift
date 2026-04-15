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
@MainActor
final class MascotWindowController {

    private var window: NSWindow?

    /// The mascot view model, accessible for external state updates.
    private(set) var viewModel: MascotViewModel?

    /// Reference to the scheduler for state sync.
    private var scheduler: BreakScheduler?

    /// Task for monitoring scheduler state changes.
    private var stateMonitorTask: Task<Void, Never>?

    /// Shows the mascot window on screen.
    ///
    /// - Parameter scheduler: The BreakScheduler to wire mascot state to.
    func show(scheduler: BreakScheduler) {
        guard window == nil else { return }
        self.scheduler = scheduler

        let containerView = MascotContainerView(scheduler: scheduler)
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

        Log.mascot.info("Mascot window shown at bottom-right corner.")
    }

    /// Hides the mascot window.
    func hide() {
        stateMonitorTask?.cancel()
        stateMonitorTask = nil
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
