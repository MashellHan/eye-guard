//
//  NotchPanel.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Transparent, non-activating NSPanel subclass for the Notch overlay.
//  Rewrite of mio-guard's NotchWindow.swift. Simplified — no plugin
//  click-through logic (Phase 1 only has placeholder content).
//

import AppKit

/// A borderless, floating panel that hovers over the menu bar in the
/// notch area. Clicks pass through when `ignoresMouseEvents = true`
/// (toggled by the controller based on open/closed state).
final class NotchPanel: NSPanel {

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Floating-panel behavior — don't steal key on hover.
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true

        // Fully transparent so only the SwiftUI content paints.
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        hasShadow = false

        // Keep panel pinned across Space changes.
        isMovable = false
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]

        // Initially above menu bar; controller elevates to .popUpMenu on open.
        level = .mainMenu + 3

        allowsToolTipsWhenApplicationIsInactive = true
        ignoresMouseEvents = true
        isReleasedWhenClosed = true
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
