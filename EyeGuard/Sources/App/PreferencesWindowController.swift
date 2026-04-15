import AppKit
import SwiftUI

/// Manages the preferences window lifecycle.
///
/// Opens a native NSWindow hosting the SwiftUI `PreferencesView`.
/// Ensures only one preferences window is open at a time.
@MainActor
final class PreferencesWindowController {

    /// Shared singleton instance.
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    private init() {}

    /// Shows the preferences window, creating it if needed.
    func showPreferences() {
        if let existingWindow = window, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "EyeGuard Preferences"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.setContentSize(NSSize(width: 520, height: 480))
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = newWindow
    }
}
