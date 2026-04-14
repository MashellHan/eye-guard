import SwiftUI

/// EyeGuard — a macOS menu bar app for eye health protection.
///
/// Uses `MenuBarExtra` to live exclusively in the menu bar (no dock icon).
/// Wires up the core services and provides the menu bar UI.
@main
struct EyeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var scheduler = BreakScheduler()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scheduler: scheduler)
        } label: {
            Label("EyeGuard", systemImage: "eye.trianglebadge.exclamationmark")
        }
        .menuBarExtraStyle(.window)
    }
}
