import SwiftUI

/// EyeGuard — a macOS menu bar app for eye health protection.
///
/// Uses `MenuBarExtra` to live exclusively in the menu bar (no dock icon).
/// Wires up the core services and provides the menu bar UI.
/// The menu bar title shows a countdown to the next 20-20-20 break.
///
/// Phase 3: presentation layer is chosen by ModeManager — either the
/// floating Apu mascot (default) or the Dynamic Notch overlay.
@main
struct EyeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var scheduler = BreakScheduler()

    /// Whether the mode coordinator has been started.
    @State private var coordinatorStarted = false

    /// Retained reference to the mode coordinator for the app lifetime.
    @State private var coordinator: AppModeCoordinator?

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scheduler: scheduler)
                .onAppear {
                    ReportDataProvider.shared.register(scheduler: scheduler)
                    startCoordinatorIfNeeded()
                }
        } label: {
            MenuBarLabel(scheduler: scheduler)
                .task {
                    startCoordinatorIfNeeded()
                }
        }
        .menuBarExtraStyle(.window)
    }

    /// Start the AppModeCoordinator once, wiring ModeManager ↔ modules.
    @MainActor
    private func startCoordinatorIfNeeded() {
        guard !coordinatorStarted else { return }
        coordinatorStarted = true
        let c = AppModeCoordinator(
            modeManager: ModeManager.shared,
            scheduler: scheduler
        )
        c.start()
        coordinator = c
        Log.app.info("AppModeCoordinator started (mode=\(ModeManager.shared.currentMode.rawValue)).")

        // DEBUG_UI_STATE hook (no-op unless the env var is set).
        // Gate at the call site so the production launch path doesn't even
        // allocate a Task when the var is unset (W1 fix).
        if DebugTrigger.isRequested {
            Task { @MainActor in
                // Brief delay to let the mode coordinator finish its initial
                // activate so the mascot/notch window is in place before we
                // drive it. (Renderers themselves poll, so this is just a
                // courtesy head-start, not a correctness dependency.)
                try? await Task.sleep(for: .milliseconds(500))
                DebugTrigger.activateIfRequested(scheduler: scheduler)
            }
        }
    }
}

// MARK: - MenuBarLabel

/// Displays a countdown to the next break in the menu bar.
///
/// Format: 👁️ 18:32  (minutes:seconds until next break)
/// Shows ⏸ when paused.
/// Shows 🌙 prefix when night mode is active (v1.4).
private struct MenuBarLabel: View {
    let scheduler: BreakScheduler

    var body: some View {
        let countdown = formatCountdown(scheduler.timeUntilNextBreak)
        let nightIndicator = NightModeManager.shared.menuBarIndicator
        if scheduler.isPaused {
            Label("\(nightIndicator)⏸", systemImage: "eye.trianglebadge.exclamationmark")
        } else {
            Label(
                "\(nightIndicator)\(countdown)",
                systemImage: "eye.trianglebadge.exclamationmark"
            )
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
