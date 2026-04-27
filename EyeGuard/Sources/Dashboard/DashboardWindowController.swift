import AppKit
import SwiftUI
import os

/// Controls the dashboard window displaying historical charts and stats.
///
/// The dashboard window is:
/// - A standard resizable NSWindow with title bar
/// - Accessible from menu bar "Dashboard..." button
/// - Shows DashboardView with the connected scheduler
/// - Brought to front if already open
@MainActor
final class DashboardWindowController {

    // MARK: - Singleton

    static let shared = DashboardWindowController()

    // MARK: - State

    private var window: NSWindow?

    /// The scheduler reference, set when the dashboard is first shown.
    private var scheduler: BreakScheduler?

    private init() {}

    // MARK: - Public API

    /// Shows the dashboard window, creating it if needed.
    ///
    /// - Parameter scheduler: The BreakScheduler to display data from.
    func showDashboard(scheduler: BreakScheduler) {
        self.scheduler = scheduler

        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboardView = DashboardView(scheduler: scheduler)
        let hostingView = NSHostingView(rootView: dashboardView)

        let dashboardWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 880),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        dashboardWindow.title = "EyeGuard Dashboard"
        dashboardWindow.contentView = hostingView
        dashboardWindow.contentMinSize = NSSize(width: 720, height: 540)
        dashboardWindow.center()
        dashboardWindow.isReleasedWhenClosed = false

        // Set the window level to normal (not floating) so it behaves like a standard window
        dashboardWindow.level = .normal

        dashboardWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = dashboardWindow
        Log.dashboard.info("Dashboard window opened.")
    }

    /// Closes the dashboard window.
    func closeDashboard() {
        window?.close()
        window = nil
        Log.dashboard.info("Dashboard window closed.")
    }
}
