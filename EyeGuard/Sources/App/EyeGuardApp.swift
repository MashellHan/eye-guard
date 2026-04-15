import SwiftUI

/// EyeGuard — a macOS menu bar app for eye health protection.
///
/// Uses `MenuBarExtra` to live exclusively in the menu bar (no dock icon).
/// Wires up the core services and provides the menu bar UI.
/// The menu bar title shows a countdown to the next 20-20-20 break.
/// Launches the floating mascot character (护眼精灵) on screen (v0.9).
@main
struct EyeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var scheduler = BreakScheduler()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scheduler: scheduler)
                .onAppear {
                    // Register scheduler with ReportDataProvider for quit-time report generation
                    ReportDataProvider.shared.register(scheduler: scheduler)

                    // Launch mascot character (v0.9)
                    launchMascot()
                }
        } label: {
            MenuBarLabel(scheduler: scheduler)
        }
        .menuBarExtraStyle(.window)
    }

    /// Creates and shows the mascot floating window, wired to the scheduler.
    @MainActor
    private func launchMascot() {
        guard AppDelegate.mascotController == nil else { return }
        let controller = MascotWindowController()
        controller.show(scheduler: scheduler)
        AppDelegate.mascotController = controller
        Log.app.info("Mascot character (护眼精灵) launched.")
    }
}

// MARK: - MenuBarLabel

/// Displays a countdown to the next break in the menu bar.
///
/// Format: 👁️ 18:32  (minutes:seconds until next break)
/// Shows ⏸ when paused.
private struct MenuBarLabel: View {
    let scheduler: BreakScheduler

    var body: some View {
        let countdown = formatCountdown(scheduler.timeUntilNextBreak)
        if scheduler.isPaused {
            Label("⏸", systemImage: "eye.trianglebadge.exclamationmark")
        } else {
            Label(countdown, systemImage: "eye.trianglebadge.exclamationmark")
        }
    }

    /// Formats the remaining time as MM:SS for the menu bar title.
    private func formatCountdown(_ interval: TimeInterval) -> String {
        let totalSeconds = max(Int(interval), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
