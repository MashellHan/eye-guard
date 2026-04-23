import AppKit
import Foundation
import SwiftUI

/// Forces EyeGuard into a specific UI state at launch for screenshot tests.
///
/// Activated only when the `DEBUG_UI_STATE` environment variable is set to one
/// of the supported state names below. When inactive (the env var is unset or
/// empty) this type is a no-op and the app behaves normally.
///
/// ### Why no `#if DEBUG` gate
/// `scripts/build-app.sh` ships a release-configured `.app` to the tester and
/// `#if DEBUG` would strip this code from that bundle. We rely on the env-var
/// check alone — production users will never set this variable, and even if
/// they did the visible behavior is "scheduler paused, view forced", which is
/// harmless (they would need to relaunch to recover normal scheduling).
///
/// ### Supported `DEBUG_UI_STATE` values
/// **Tier A — baseline + bug-repro**
/// - `menubar-popover`
/// - `mascot-idle`
/// - `overlay-tier2-micro`
/// - `overlay-tier2-macro`
/// - `overlay-tier3-mandatory`
///
/// **Tier B — broad coverage**
/// - `menubar-popover-mascot-mode`, `menubar-popover-notch-mode`
/// - `mascot-concerned`, `mascot-alerting`, `mascot-resting`, `mascot-celebrating`
/// - `notch-collapsed`, `notch-expanded`, `notch-pop-banner`
/// - `dashboard-today`
/// - `report-window`
/// - `prefs-general`
///
/// **Tier B (partial) — entry only, sub-tab routing TODO (backlog/I1-tier-C)**
/// - `dashboard-history`, `dashboard-breakdown`
/// - `prefs-reminder-modes`, `prefs-sounds`
///
/// These return an explicit `not yet supported` error so the tester can mark
/// them `skipped, reason=debug_trigger_unsupported` (per plan §未支持的 state).
///
/// **Tier C — entry only (sub-frames TODO, see backlog I1-tier-C)**
/// - `exercise-focus-shifting`, `exercise-figure-8`, `exercise-circle`,
///   `exercise-distance`, `exercise-palming`
///
/// Unknown values log an error listing the supported states and leave the app
/// in its normal state.
@MainActor
enum DebugTrigger {

    /// Environment variable name read on launch.
    static let envVar = "DEBUG_UI_STATE"

    /// Owned overlay controller used to host debug-rendered tier 2/3 overlays
    /// without going through the live notification pipeline.
    private static var overlayController: OverlayWindowController?

    /// Owned panel hosting `MenuBarView` for the `menubar-popover*` debug
    /// states. SwiftUI's `MenuBarExtra` does not expose its `NSStatusItem`,
    /// so we cannot programmatically `performClick(nil)` on the real menu
    /// bar item. Instead we render the same `MenuBarView` content in a
    /// floating panel positioned where the popover would appear, which is
    /// what the tester actually needs to screenshot. (I2 fix, iter3.)
    private static var menuBarDebugPanel: NSPanel?

    /// Reads the env var and dispatches to the matching renderer.
    /// Safe to call multiple times — second call is a no-op if env var unset.
    /// Caller is expected to early-return before invoking when env var is unset
    /// to avoid spawning an idle Task on the production launch path (see W1).
    static func activateIfRequested(scheduler: BreakScheduler) {
        guard let raw = ProcessInfo.processInfo.environment[envVar],
              !raw.isEmpty else {
            return
        }
        guard let state = State(rawValue: raw) else {
            Log.app.error(
                "DebugTrigger: unknown \(envVar)='\(raw, privacy: .public)'. Supported: \(State.allRawValues, privacy: .public)"
            )
            return
        }

        // Pause real scheduling so timers don't yank the view away mid-screenshot.
        // Done before dispatch so any view that reads `isPaused` sees the new value.
        if !scheduler.isPaused {
            scheduler.togglePause()
        }

        // Single high-visibility breadcrumb so tester logs make it obvious why
        // the app isn't behaving normally.
        Log.app.warning(
            "⚠️ DEBUG_UI_STATE active — scheduler paused, view forced (state=\(state.rawValue, privacy: .public))"
        )

        dispatch(state, scheduler: scheduler)
    }

    /// Returns true if `DEBUG_UI_STATE` is set to a non-empty value.
    /// Used by the launch path to short-circuit before allocating any Task.
    static var isRequested: Bool {
        guard let raw = ProcessInfo.processInfo.environment[envVar] else {
            return false
        }
        return !raw.isEmpty
    }

    // MARK: - Dispatch

    private static func dispatch(_ state: State, scheduler: BreakScheduler) {
        switch state {
        // Tier A
        case .menubarPopover:
            renderMenuBar(scheduler: scheduler, mode: nil)
        case .mascotIdle:
            renderMascot(state: .idle)
        case .overlayTier2Micro:
            renderOverlayTier2(.micro)
        case .overlayTier2Macro:
            renderOverlayTier2(.macro)
        case .overlayTier3Mandatory:
            renderOverlayTier3()

        // Tier B — menubar variants
        case .menubarPopoverMascotMode:
            renderMenuBar(scheduler: scheduler, mode: .apu)
        case .menubarPopoverNotchMode:
            renderMenuBar(scheduler: scheduler, mode: .notch)

        // Tier B — mascot states
        case .mascotConcerned:
            renderMascot(state: .concerned)
        case .mascotAlerting:
            renderMascot(state: .alerting)
        case .mascotResting:
            renderMascot(state: .resting)
        case .mascotCelebrating:
            renderMascot(state: .celebrating)

        // Tier B — notch states
        case .notchCollapsed:
            renderNotch(scheduler: scheduler, action: .collapsed)
        case .notchExpanded:
            renderNotch(scheduler: scheduler, action: .expanded)
        case .notchPopBanner:
            renderNotch(scheduler: scheduler, action: .popBanner)

        // Tier B — windows (drivable today)
        case .dashboardToday:
            renderDashboard(scheduler: scheduler)
        case .reportWindow:
            renderReportWindow()
        case .prefsGeneral:
            renderPreferences()

        // Tier B (partial) — sub-tab routing not yet wired (C1 fix).
        // Surface as unsupported so the tester records `skipped` per plan
        // §未支持的 state instead of capturing a misleading screenshot of
        // the parent window's default tab.
        case .dashboardHistory,
             .dashboardBreakdown,
             .prefsReminderModes,
             .prefsSounds:
            Log.app.error(
                "DebugTrigger: '\(state.rawValue, privacy: .public)' not yet supported (sub-tab routing TBD, backlog/I1-tier-C). Reported as unsupported; tester should mark skipped."
            )
            return

        // Tier C — exercise entry points only.
        // TODO(eye-guard, backlog/I1-tier-C): drive sub-frames per exercise.
        // For now we just open the exercise overlay so the tester can capture
        // the entry frame; per-step screenshots are deferred.
        case .exerciseFocusShifting,
             .exerciseFigure8,
             .exerciseCircle,
             .exerciseDistance,
             .exercisePalming:
            renderExerciseEntry()
        }
    }

    // MARK: - Renderers

    /// Switches mode if requested, then opens a debug-only floating panel
    /// hosting `MenuBarView` so the tester can screenshot the popover
    /// content. (I2 fix, iter3 — see `menuBarDebugPanel` doc for why we
    /// don't drive the real `MenuBarExtra`.)
    private static func renderMenuBar(scheduler: BreakScheduler, mode: AppMode?) {
        if let mode {
            ModeManager.shared.switchMode(to: mode)
        }
        Log.app.info("DebugTrigger: menubar ready (mode=\(ModeManager.shared.currentMode.rawValue, privacy: .public)).")
        showMenuBarDebugPopover(scheduler: scheduler)
    }

    /// Builds the debug menu-bar popover panel and pins it under the
    /// top-right of the main screen, where a real `MenuBarExtra` popover
    /// would land. Idempotent: a second call replaces the old panel.
    private static func showMenuBarDebugPopover(scheduler: BreakScheduler) {
        // Replace any existing panel so a re-trigger gets a fresh view.
        menuBarDebugPanel?.close()
        menuBarDebugPanel = nil

        let menuBarView = MenuBarView(scheduler: scheduler)
        let hostingView = NSHostingView(rootView: menuBarView)
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
        panel.becomesKeyOnlyIfNeeded = false
        panel.isFloatingPanel = true

        // Round corners to mirror the real popover appearance.
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12
        panel.contentView?.layer?.masksToBounds = true

        // Pin to top-right of the main screen, just below the menu bar,
        // matching where a `MenuBarExtra` popover would appear.
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.maxX - fittingSize.width - 8
            let y = visible.maxY - fittingSize.height - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        menuBarDebugPanel = panel
    }

    /// Forces the mascot into the requested state. Switches to Apu mode first
    /// so the mascot window exists, then drives the view model directly.
    /// Polls for the mascot controller instead of sleeping a fixed delay so
    /// slower hardware doesn't race ahead with a nil controller (W2 fix).
    ///
    /// I1 fix (iter3): two changes were necessary to make the per-state
    /// screenshots actually distinct.
    /// 1. `MascotContainerView` previously created its own `@State` view
    ///    model, so `controller.viewModel` was a different instance from
    ///    the one being rendered. The controller now injects its `vm` into
    ///    the container, so `transition(to:)` here actually mutates the
    ///    rendered VM. (See `MascotContainerView.viewModel` doc.)
    /// 2. `MascotStateSync.start` early-returns when `DebugTrigger.isRequested`
    ///    is true, so its 2 s loop no longer overwrites our forced state
    ///    (which is what caused all 5 states to collapse to "concerned +
    ///    跳过休息了 bubble" driven by the 33/100 health score).
    /// Verify with: `DEBUG_UI_STATE=mascot-celebrating open EyeGuard.app`
    /// — should show happy squint eyes + bouncy mint body, not worried face.
    private static func renderMascot(state: MascotState) {
        ModeManager.shared.switchMode(to: .apu)
        Task { @MainActor in
            guard let controller = await waitForMascotController() else {
                Log.app.error("DebugTrigger: mascot controller did not appear within timeout.")
                return
            }
            guard let vm = controller.viewModel else {
                Log.app.error("DebugTrigger: mascot controller has no view model.")
                return
            }
            // Wipe any speech bubble — `MascotStateSync` is skipped under
            // debug, but other paths (pre-alert observers, exercise hooks)
            // could still set one and it would dominate the screenshot.
            vm.hideBubble()

            // Default the resting sub-mode to sleeping so the view has
            // something to render; tester can override via a future flag.
            if state == .resting {
                vm.restingMode = .sleeping
            }
            // `transition(to:)` is a no-op when `newState == mascotState`
            // (default `.idle`). Force-assign first so the per-state setup
            // (bouncing / celebrating / glow / sway tasks) always fires
            // when DebugTrigger asks for `.idle` after a previous run too.
            if vm.mascotState == state {
                vm.mascotState = (state == .idle) ? .concerned : .idle
            }
            vm.transition(to: state)
        }
    }

    /// Action selector for the notch renderer — keeps `dispatch(_:)` flat.
    private enum NotchAction { case collapsed, expanded, popBanner }

    /// Switches to Notch mode and forces the panel into the requested state.
    /// Polls for the view model AND cancels the boot animation before
    /// driving state, eliminating the C2 race where boot-anim re-opens the
    /// notch after our `notchClose()`.
    private static func renderNotch(scheduler: BreakScheduler, action: NotchAction) {
        ModeManager.shared.switchMode(to: .notch)
        Task { @MainActor in
            guard let vm = await waitForNotchViewModel() else {
                Log.app.error("DebugTrigger: notch view model did not appear within timeout.")
                return
            }
            // Boot animation auto-opens the notch for ~1 s after the window
            // installs. If we don't cancel it, our requested state can be
            // clobbered when the boot timer fires after our action — most
            // visibly, `notch-collapsed` would briefly re-open. See C2.
            vm.cancelBootAnimation()
            switch action {
            case .collapsed:
                vm.notchClose()
            case .expanded:
                vm.notchOpen(reason: .click)
            case .popBanner:
                vm.notchClose()
                vm.pop(
                    kind: .preBreak,
                    message: "👀 Eye break in 20s",
                    duration: 60
                )
            }
        }
    }

    /// Builds a tier 2 floating overlay using the live styles, but drives the
    /// callbacks to no-ops so the overlay stays on screen for screenshotting.
    private static func renderOverlayTier2(_ breakType: BreakType) {
        let controller = ensureOverlayController()
        controller.showBreakOverlay(
            breakType: breakType,
            healthScore: 72,
            dismissPolicy: .skippable,
            postponeCount: 0,
            onTaken: {},
            onSkipped: {},
            onPostponed: {}
        )
    }

    /// Builds the tier 3 full-screen overlay. Hard-wired to `.mandatory` and
    /// `dismissPolicy: .postponeOnly(maxCount: 2)` because that is the only
    /// tier-3 variant in the matrix today; making the function parameterless
    /// avoids implying flexibility we don't actually have (W4 fix).
    private static func renderOverlayTier3() {
        let controller = ensureOverlayController()
        controller.showFullScreenOverlay(
            breakType: .mandatory,
            healthScore: 35,
            dismissPolicy: .postponeOnly(maxCount: 2),
            postponeCount: 0,
            exerciseSessionsToday: 1,
            recommendedExerciseSessions: 2,
            onTaken: {},
            onSkipped: {},
            onPostponed: {},
            onStartExercises: nil
        )
    }

    private static func ensureOverlayController() -> OverlayWindowController {
        if let existing = overlayController {
            return existing
        }
        let new = OverlayWindowController()
        overlayController = new
        return new
    }

    private static func renderDashboard(scheduler: BreakScheduler) {
        DashboardWindowController.shared.showDashboard(scheduler: scheduler)
    }

    /// Renders the report window WITHOUT regenerating today's report.
    /// Calling `DailyReportGenerator.generate(...)` would persist a daily
    /// report file and may trigger AI insight generation (API credits +
    /// rate limits). The screenshot path must be read-only (W3 fix), so
    /// we reuse today's existing markdown if present and fall back to a
    /// fixture string otherwise.
    private static func renderReportWindow() {
        let url = EyeGuardConstants.reportsDirectory
            .appendingPathComponent(TimeFormatting.dateStringFormatter.string(from: .now) + ".md")
        let markdown: String
        if let onDisk = try? String(contentsOf: url, encoding: .utf8) {
            markdown = onDisk
        } else {
            // Fixture content covers the section structure the report view
            // styles (h1/h2/lists). Numbers are illustrative — tester only
            // checks layout/colors, not values.
            markdown = """
            # EyeGuard — Sample Daily Report

            ## Today
            - Screen time: 4h 12m
            - Breaks taken: 8 / 12
            - Longest continuous session: 1h 47m

            ## Health Score
            72 / 100

            ## Notes
            Sample content rendered by DebugTrigger because no report exists \
            for today yet. Use this view to verify report-window layout only.
            """
        }
        ReportWindowController.shared.showReport(
            markdown: markdown,
            fileURL: url,
            title: "EyeGuard — Daily Report"
        )
    }

    private static func renderPreferences() {
        PreferencesWindowController.shared.showPreferences()
    }

    /// Tier C placeholder — opens the mascot's exercise overlay so the tester
    /// can capture the entry frame. Per-exercise sub-frames are backlog.
    /// Polls for the mascot controller (W2 fix) instead of fixed sleep.
    private static func renderExerciseEntry() {
        ModeManager.shared.switchMode(to: .apu)
        Task { @MainActor in
            guard let controller = await waitForMascotController() else {
                Log.app.error("DebugTrigger: mascot controller unavailable for exercise entry.")
                return
            }
            controller.showExerciseWindow()
        }
    }

    // MARK: - Polling helpers (W2)

    /// How often we re-check for the target controller while waiting.
    private static let pollInterval: Duration = .milliseconds(50)
    /// Hard cap so a missing controller eventually surfaces as an error log
    /// instead of hanging the debug session forever.
    private static let pollTimeout: Duration = .seconds(2)

    /// Wait until `AppDelegate.mascotController` is non-nil, or the timeout
    /// elapses. Polling beats a fixed sleep because the controller may be
    /// installed in well under our previous 200 ms or considerably later
    /// under load — we want to act as soon as it's ready.
    private static func waitForMascotController() async -> MascotWindowController? {
        let deadline = ContinuousClock.now.advanced(by: pollTimeout)
        while ContinuousClock.now < deadline {
            if let c = AppDelegate.mascotController { return c }
            try? await Task.sleep(for: pollInterval)
        }
        return AppDelegate.mascotController
    }

    /// Wait until `NotchModule` exposes a view model on the main screen.
    /// Same rationale as `waitForMascotController`.
    private static func waitForNotchViewModel() async -> NotchViewModel? {
        let deadline = ContinuousClock.now.advanced(by: pollTimeout)
        while ContinuousClock.now < deadline {
            if let vm = NotchModule.shared.mainScreenViewModelForDebug { return vm }
            try? await Task.sleep(for: pollInterval)
        }
        return NotchModule.shared.mainScreenViewModelForDebug
    }

    // MARK: - State Enum

    /// Supported `DEBUG_UI_STATE` values. Raw values match `test-matrix.md`
    /// exactly — keep both lists in sync.
    /// `private` so only this file can build/parse states (N3 fix).
    private enum State: String, CaseIterable {
        // Tier A
        case menubarPopover         = "menubar-popover"
        case mascotIdle             = "mascot-idle"
        case overlayTier2Micro      = "overlay-tier2-micro"
        case overlayTier2Macro      = "overlay-tier2-macro"
        case overlayTier3Mandatory  = "overlay-tier3-mandatory"

        // Tier B — menubar variants
        case menubarPopoverMascotMode = "menubar-popover-mascot-mode"
        case menubarPopoverNotchMode  = "menubar-popover-notch-mode"

        // Tier B — mascot states
        case mascotConcerned   = "mascot-concerned"
        case mascotAlerting    = "mascot-alerting"
        case mascotResting     = "mascot-resting"
        case mascotCelebrating = "mascot-celebrating"

        // Tier B — notch states
        case notchCollapsed = "notch-collapsed"
        case notchExpanded  = "notch-expanded"
        case notchPopBanner = "notch-pop-banner"

        // Tier B — windows
        case dashboardToday     = "dashboard-today"
        case dashboardHistory   = "dashboard-history"
        case dashboardBreakdown = "dashboard-breakdown"
        case reportWindow       = "report-window"
        case prefsGeneral       = "prefs-general"
        case prefsReminderModes = "prefs-reminder-modes"
        case prefsSounds        = "prefs-sounds"

        // Tier C — entry only
        case exerciseFocusShifting = "exercise-focus-shifting"
        case exerciseFigure8       = "exercise-figure-8"
        case exerciseCircle        = "exercise-circle"
        case exerciseDistance      = "exercise-distance"
        case exercisePalming       = "exercise-palming"

        /// Comma-separated list of supported raw values, for diagnostics.
        static var allRawValues: String {
            allCases.map(\.rawValue).joined(separator: ", ")
        }
    }
}
