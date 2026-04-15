import AppKit
import SwiftUI
import os

/// Controls a floating overlay window for Tier 2 break notifications.
///
/// The overlay appears in the top-right corner of the screen with a semi-transparent
/// blur background, smooth fade-in/out animations, and is visible on all desktops.
///
/// Window properties:
/// - Level: `.floating` (above other windows but not fullscreen)
/// - Borderless style with shadow
/// - Movable by dragging background
/// - Visible on all Spaces (desktops)
@MainActor
final class OverlayWindowController: NSObject {

    // MARK: - State

    private var window: NSWindow?

    /// Whether an overlay is currently displayed.
    var isShowing: Bool { window != nil }

    // MARK: - Public API

    /// Shows a break overlay window with the given break type and callbacks.
    ///
    /// - Parameters:
    ///   - breakType: The type of break being prompted.
    ///   - onTaken: Called when the user taps "Take Break" and the countdown completes.
    ///   - onSkipped: Called when the user taps "Skip".
    func showBreakOverlay(
        breakType: BreakType,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void
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
            onTaken: onTaken,
            onSkipped: onSkipped,
            onDismiss: dismissAction
        )

        let hostingView = NSHostingView(rootView: contentView)

        let overlayWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
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

    /// Dismisses the overlay with a fade-out animation.
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
