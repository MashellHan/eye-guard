import AppKit
import SwiftUI
import os

/// Controls floating overlay windows for Tier 2 and Tier 3 break notifications.
///
/// Tier 2: appears in the top-right corner with semi-transparent blur background.
/// Tier 3: covers ALL screens with a full-screen semi-transparent overlay.
///
/// v2.4: Now accepts `DismissPolicy`, `postponeCount`, and `onPostponed` to support
/// mode-aware behavior.
@MainActor
final class OverlayWindowController: NSObject {

    // MARK: - State

    private var window: NSWindow?

    /// Full-screen overlay windows (one per screen) for Tier 3.
    private var fullScreenWindows: [NSWindow] = []

    /// Whether a Tier 2 overlay is currently displayed.
    var isShowing: Bool { window != nil }

    /// Whether a Tier 3 full-screen overlay is currently displayed.
    var isFullScreenShowing: Bool { !fullScreenWindows.isEmpty }

    // MARK: - Public API

    /// Shows a break overlay window with mode-aware dismiss behavior (v2.4).
    ///
    /// - Parameters:
    ///   - breakType: The type of break being prompted.
    ///   - healthScore: Current eye health score (0-100) to display.
    ///   - dismissPolicy: How the user can dismiss this notification.
    ///   - postponeCount: Number of postpones already used.
    ///   - onTaken: Called when the user taps "Take Break" and the countdown completes.
    ///   - onSkipped: Called when the user taps "Skip".
    ///   - onPostponed: Called when the user taps "Postpone".
    func showBreakOverlay(
        breakType: BreakType,
        healthScore: Int = 100,
        dismissPolicy: DismissPolicy = .skippable,
        postponeCount: Int = 0,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void,
        onPostponed: @escaping @Sendable () -> Void = {}
    ) {
        // Dismiss any existing overlay first
        if isShowing {
            dismissImmediate()
        }

        let dismissAction: @MainActor () -> Void = { [weak self] in
            self?.dismiss()
        }

        let contentView = BreakOverlayView(
            breakType: breakType,
            healthScore: healthScore,
            dismissPolicy: dismissPolicy,
            postponeCount: postponeCount,
            onTaken: onTaken,
            onSkipped: onSkipped,
            onPostponed: onPostponed,
            onDismiss: dismissAction
        )

        let hostingView = NSHostingView(rootView: contentView)

        // Larger window for macro/mandatory breaks
        let windowWidth: CGFloat = breakType == .macro ? 400 : 340
        let windowHeight: CGFloat = breakType == .macro ? 340 : 300

        let overlayWindow = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow.contentView = hostingView
        overlayWindow.level = .floating
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.hasShadow = true
        overlayWindow.isMovableByWindowBackground = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        overlayWindow.isReleasedWhenClosed = false

        // Position top-right with 20pt margin
        positionTopRight(overlayWindow)

        // Show with fade-in animation
        overlayWindow.alphaValue = 0
        overlayWindow.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            overlayWindow.animator().alphaValue = 1
        }

        self.window = overlayWindow

        Log.notification.info("Overlay window shown for \(breakType.displayName)")
    }

    /// Shows a full-screen overlay on every connected monitor (v2.4).
    ///
    /// - Parameters:
    ///   - breakType: The type of break driving this overlay.
    ///   - healthScore: Current eye health score (0-100) to display.
    ///   - dismissPolicy: How the user can dismiss this overlay.
    ///   - postponeCount: Number of postpones already used.
    ///   - onTaken: Called when the user completes the full break countdown.
    ///   - onPostponed: Called when the user postpones.
    func showFullScreenOverlay(
        breakType: BreakType = .mandatory,
        healthScore: Int,
        dismissPolicy: DismissPolicy = .postponeOnly(maxCount: 2),
        postponeCount: Int = 0,
        exerciseSessionsToday: Int = 0,
        recommendedExerciseSessions: Int = 1,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void = {},
        onPostponed: @escaping @Sendable () -> Void = {},
        onStartExercises: (@Sendable () -> Void)? = nil
    ) {
        // Dismiss any existing overlays first
        dismissFullScreen()
        if isShowing {
            dismissImmediate()
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            Log.notification.warning("No screens available for full-screen overlay.")
            return
        }

        for (index, screen) in screens.enumerated() {
            let contentView = FullScreenOverlayView(
                breakType: breakType,
                healthScore: healthScore,
                dismissPolicy: dismissPolicy,
                postponeCount: postponeCount,
                exerciseSessionsToday: exerciseSessionsToday,
                recommendedExerciseSessions: recommendedExerciseSessions,
                onBreakTaken: { [weak self] in
                    Task { @MainActor in
                        self?.dismissFullScreen()
                        onTaken()
                    }
                },
                onSkipped: { [weak self] in
                    Task { @MainActor in
                        self?.dismissFullScreen()
                        onSkipped()
                    }
                },
                onPostponed: { [weak self] in
                    Task { @MainActor in
                        self?.dismissFullScreen()
                        onPostponed()
                    }
                },
                onStartExercises: onStartExercises.map { callback in
                    { [weak self] in
                        Task { @MainActor in
                            self?.dismissFullScreen()
                            callback()
                        }
                    }
                }
            )

            let hostingView = NSHostingView(rootView: contentView)

            let fullScreenWindow = KeyableWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            fullScreenWindow.contentView = hostingView
            fullScreenWindow.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
            fullScreenWindow.ignoresMouseEvents = false
            fullScreenWindow.isOpaque = false
            fullScreenWindow.backgroundColor = .clear
            fullScreenWindow.hasShadow = false
            fullScreenWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
            fullScreenWindow.isReleasedWhenClosed = false

            // Position to cover entire screen
            fullScreenWindow.setFrame(screen.frame, display: true)

            // Fade in
            fullScreenWindow.alphaValue = 0
            fullScreenWindow.makeKeyAndOrderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                fullScreenWindow.animator().alphaValue = 1
            }

            fullScreenWindows.append(fullScreenWindow)

            Log.notification.info(
                "Full-screen overlay shown on screen \(index + 1) of \(screens.count)"
            )
        }

        Log.notification.info(
            "Tier 3 full-screen overlay active on \(screens.count) screen(s), health: \(healthScore)"
        )
    }

    /// Dismisses the Tier 2 overlay with a fade-out animation.
    func dismiss() {
        guard let overlayWindow = window else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            overlayWindow.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor [weak self] in
                overlayWindow.close()
                self?.window = nil
                Log.notification.info("Overlay window dismissed.")
            }
        })
    }

    /// Dismisses all Tier 3 full-screen overlay windows with fade-out animation.
    func dismissFullScreen() {
        guard !fullScreenWindows.isEmpty else { return }

        let windows = fullScreenWindows
        fullScreenWindows = []

        for fsWindow in windows {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                fsWindow.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    fsWindow.close()
                }
            })
        }

        Log.notification.info("Full-screen overlay windows dismissed.")
    }

    // MARK: - Private

    /// Dismisses immediately without animation (for replacing overlays).
    private func dismissImmediate() {
        window?.close()
        window = nil
    }

    /// Positions the window in the top-right corner of the main screen with a 20pt margin.
    private func positionTopRight(_ overlayWindow: NSWindow) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let windowFrame = overlayWindow.frame
        let margin: CGFloat = 20

        let x = screenFrame.maxX - windowFrame.width - margin
        let y = screenFrame.maxY - windowFrame.height - margin

        overlayWindow.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - KeyableWindow

/// A borderless NSWindow subclass that can become key window,
/// enabling keyboard events (e.g. Escape to dismiss).
final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
