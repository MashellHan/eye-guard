import AppKit
import SwiftUI
import os

/// Presents the full-screen eye-exercise session window stack on every connected
/// display. Extracted from `MascotWindowController` (B4) so that **all** display
/// modes — Apu mascot, Dynamic Notch, future modes — can launch exercises by
/// posting `.startExercisesFromBreak` or by calling `present()` directly.
///
/// Why a singleton: there is exactly one exercise session at a time and only
/// one observer should listen for the cross-module notification. Putting it in
/// a view-layer module (Mascot) was an R1 violation because Notch users had
/// no observer at all and the button silently no-op'd.
///
/// Lifecycle:
/// 1. `EyeGuardApp` calls `configure(scheduler:)` once at launch.
/// 2. `EyeGuardApp` calls `observeStartFromBreak()` once at launch.
/// 3. Display modules (Mascot, Notch) may set `onSessionStart` / `onSessionEnd`
///    closures while active to update their own view state, and clear them on
///    deactivate. This keeps view-only concerns in the view module without
///    pulling business logic back in.
@MainActor
final class ExercisePresenter {

    /// Process-wide presenter — there is at most one exercise session at a time.
    static let shared = ExercisePresenter()

    private init() {}

    // MARK: - Configuration

    /// Scheduler used to record completed exercise sessions. Set once by
    /// `EyeGuardApp` so the presenter remains free of any view-module
    /// dependency.
    private weak var scheduler: BreakScheduler?

    /// Notification observer for `.startExercisesFromBreak`. Stored so we can
    /// detach if needed (currently we never do — registered for app lifetime).
    private var startFromBreakObserver: Any?

    /// View-layer hook fired when a session is about to be presented. Display
    /// modules (mascot/notch) can use this to update their own UI state.
    var onSessionStart: (@MainActor () -> Void)?

    /// View-layer hook fired when the session completes (user finished it).
    var onSessionComplete: (@MainActor () -> Void)?

    /// View-layer hook fired when the user skips the session.
    var onSessionSkipped: (@MainActor () -> Void)?

    // MARK: - Window State

    /// Active exercise overlay windows — primary screen hosts the interactive
    /// `ExerciseSessionView`; secondary screens host a dim/blur overlay only.
    private var exerciseWindows: [NSWindow] = []

    /// Returns true while an exercise overlay stack is on screen. Useful to
    /// avoid double-presenting when a button and the notification race.
    var isPresenting: Bool { !exerciseWindows.isEmpty }

    // MARK: - Public API

    /// Stores the scheduler reference so `recordExerciseSession()` can be
    /// invoked on completion. Idempotent — safe to call multiple times.
    func configure(scheduler: BreakScheduler) {
        self.scheduler = scheduler
    }

    /// Registers a single, app-lifetime observer for the notification posted by
    /// `BreakScheduler` (Tier 3 button), `MenuBarView` (quick action), and
    /// `BreakOverlayView` (Tier 2 button after B4).
    ///
    /// Idempotent: calling more than once does not register duplicates.
    func observeStartFromBreak() {
        guard startFromBreakObserver == nil else { return }
        startFromBreakObserver = NotificationCenter.default.addObserver(
            forName: .startExercisesFromBreak,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.present()
            }
        }
    }

    /// Builds the full-screen exercise window stack and shows it. If a session
    /// is already on screen this collapses to a no-op (the existing windows
    /// remain) so duplicate notifications don't tear down a live session.
    func present() {
        if isPresenting {
            Log.app.info("ExercisePresenter: present() ignored — session already active.")
            return
        }

        onSessionStart?()

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            Log.app.warning("ExercisePresenter: no screens available.")
            return
        }

        for (index, screen) in screens.enumerated() {
            let isPrimaryScreen = index == 0

            // Only the primary screen gets the interactive exercise view;
            // secondary screens show a dark overlay only (review-011 M1
            // behaviour preserved from the prior MascotWindowController impl).
            let fullscreenContent: AnyView
            if isPrimaryScreen {
                let sessionView = ExerciseSessionView(
                    onComplete: { [weak self] in
                        self?.handleComplete()
                    },
                    onSkip: { [weak self] in
                        self?.handleSkip()
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
            exWindow.ignoresMouseEvents = !isPrimaryScreen
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

            Log.app.info(
                "ExercisePresenter: overlay shown on screen \(index + 1) of \(screens.count)"
            )
        }
    }

    /// Tears down all overlay windows with a fade-out. Called from session
    /// completion/skip handlers and exposed for callers that need to abort
    /// (e.g. mode switch).
    func dismiss() {
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

    // MARK: - Private

    /// User finished the exercise sequence. Records the session against the
    /// scheduler (business effect — drives daily count + health score) and
    /// notifies the active display module.
    private func handleComplete() {
        dismiss()
        scheduler?.recordExerciseSession()
        onSessionComplete?()
    }

    /// User skipped before completion. No business effect; just dismiss + let
    /// the display module reset its UI.
    private func handleSkip() {
        dismiss()
        onSessionSkipped?()
    }
}
