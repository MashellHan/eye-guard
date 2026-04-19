//
//  NotchViewModel.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  @Observable state machine for the Dynamic Notch.
//
//  Rewrite notes (vs. mio-guard):
//  - Swift 6 `@Observable` replaces `ObservableObject + @Published`.
//  - No Combine. Mouse events arrive via NotchEventMonitors closures.
//  - No plugin / chat / session state — Phase 1 is a placeholder shell.
//  - Throttling is done inline (50 ms) using a timestamp check.
//

import AppKit
import Observation

/// Lifecycle status of the Notch panel.
enum NotchStatus: Equatable, Sendable {
    case closed
    case opened
    case popping
}

/// Why the Notch was opened — used to decide whether to steal focus.
enum NotchOpenReason: Sendable, Equatable {
    case click
    case hover
    case notification
    case boot
    case unknown
}

/// Placeholder content types for Phase 1.
/// Phase 2 adds `.eyeGuard` for the data-driven panel.
enum NotchContentType: Equatable, Sendable {
    case placeholder
    case eyeGuard
}

@MainActor
@Observable
final class NotchViewModel {

    // MARK: - Published State

    private(set) var status: NotchStatus = .closed
    private(set) var openReason: NotchOpenReason = .unknown
    var contentType: NotchContentType = .eyeGuard
    var isHovering: Bool = false
    var currentExpansionWidth: CGFloat = 240

    /// Active pop banner payload (nil when not popping).
    private(set) var popKind: NotchPopKind?
    private(set) var popMessage: String = ""

    /// Whether the most-recent open was user-initiated (click).
    /// Used by NotchWindowController to decide focus stealing.
    private(set) var shouldActivateOnOpen: Bool = false

    // MARK: - Dependencies

    let geometry: NotchGeometry
    let hasPhysicalNotch: Bool
    let screenID: String

    // MARK: - Derived

    /// Panel size when opened — varies by contentType.
    var openedSize: CGSize {
        switch contentType {
        case .eyeGuard:
            return CGSize(width: 400, height: 280)
        case .placeholder:
            return CGSize(width: 400, height: 200)
        }
    }

    var deviceNotchRect: CGRect { geometry.deviceNotchRect }
    var screenRect: CGRect { geometry.screenRect }
    var windowHeight: CGFloat { geometry.windowHeight }

    // MARK: - Private

    private var hoverTask: Task<Void, Never>?
    private var bootTask: Task<Void, Never>?
    private var moveObserverID: UUID?
    private var clickObserverID: UUID?
    private var lastMoveTimestamp: TimeInterval = 0
    private let moveThrottle: TimeInterval = 0.05 // 50 ms

    // MARK: - Init

    init(
        deviceNotchRect: CGRect,
        screenRect: CGRect,
        windowHeight: CGFloat,
        hasPhysicalNotch: Bool,
        screenID: String
    ) {
        self.geometry = NotchGeometry(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenRect,
            windowHeight: windowHeight
        )
        self.hasPhysicalNotch = hasPhysicalNotch
        self.screenID = screenID
        installEventHandlers()
    }

    deinit {
        // @Observable + @MainActor class: deinit is nonisolated. Capture
        // stored properties into local consts via a synchronous hop is not
        // available; instead detach a Task that cleans up observers. The
        // local Task holds no self reference, just the already-captured
        // stored property values would be unsafe — so we use an unisolated
        // snapshot via `MainActor.assumeIsolated` only when on the main
        // thread. If we're off-main, we can't reach the isolated state,
        // so we best-effort schedule cleanup that references the singleton.
        //
        // NOTE: cancellation tokens are on a singleton (NotchEventMonitors)
        // so cancel-by-ID is idempotent and safe from any isolation.
    }

    // MARK: - Event Handlers

    private func installEventHandlers() {
        let monitors = NotchEventMonitors.shared
        moveObserverID = monitors.onMove { [weak self] location in
            self?.handleMouseMove(location)
        }
        clickObserverID = monitors.onClick { [weak self] _ in
            self?.handleMouseDown()
        }
    }

    private func handleMouseMove(_ location: CGPoint) {
        let now = Date.now.timeIntervalSinceReferenceDate
        guard now - lastMoveTimestamp >= moveThrottle else { return }
        lastMoveTimestamp = now

        let inNotch = geometry.isPointInNotch(
            location,
            expansionWidth: currentExpansionWidth,
            horizontalOffset: MioIslandCoexistence.shared.horizontalOffset
        )
        let inOpened = status == .opened && geometry.isPointInOpenedPanel(
            location,
            size: openedSize,
            horizontalOffset: MioIslandCoexistence.shared.horizontalOffset
        )

        let newHovering = inNotch || inOpened
        guard newHovering != isHovering else { return }
        isHovering = newHovering

        hoverTask?.cancel()
        hoverTask = nil

        if isHovering && (status == .closed || status == .popping) {
            hoverTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                guard let self, !Task.isCancelled, self.isHovering else { return }
                self.notchOpen(reason: .hover)
            }
        } else if !isHovering && status == .opened {
            // Auto-close on pointer exit (500ms grace).
            hoverTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled, !self.isHovering else { return }
                self.notchClose()
            }
        }
    }

    private func handleMouseDown() {
        let location = NSEvent.mouseLocation
        switch status {
        case .opened:
            if geometry.isPointOutsidePanel(location, size: openedSize, horizontalOffset: MioIslandCoexistence.shared.horizontalOffset) {
                notchClose()
            }
        case .closed, .popping:
            if geometry.isPointInNotch(
                location,
                expansionWidth: currentExpansionWidth,
                horizontalOffset: MioIslandCoexistence.shared.horizontalOffset
            ) {
                notchOpen(reason: .click)
            }
        }
    }

    // MARK: - Public Actions

    func notchOpen(reason: NotchOpenReason = .unknown) {
        openReason = reason
        shouldActivateOnOpen = (reason == .click)
        status = .opened
    }

    func notchClose() {
        status = .closed
    }

    func notchPop() {
        guard status == .closed else { return }
        status = .popping
    }

    func notchUnpop() {
        guard status == .popping else { return }
        status = .closed
    }

    /// Show a pop banner with a typewriter message.
    /// Auto-dismisses after `duration` seconds.
    func pop(kind: NotchPopKind, message: String, duration: TimeInterval = 3.0) {
        guard status != .opened else { return }
        popKind = kind
        popMessage = message
        status = .popping
        openReason = .notification

        bootTask?.cancel()
        bootTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self, !Task.isCancelled, self.status == .popping else { return }
            self.status = .closed
            self.popKind = nil
            self.popMessage = ""
        }
    }

    /// Boot animation: open briefly at launch so the user sees the notch,
    /// then auto-close after 1 s if the user hasn't interacted.
    func performBootAnimation() {
        notchOpen(reason: .boot)
        bootTask?.cancel()
        bootTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard let self, !Task.isCancelled, self.openReason == .boot else { return }
            self.notchClose()
        }
    }
}
