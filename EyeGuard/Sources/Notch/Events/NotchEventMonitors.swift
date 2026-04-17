//
//  NotchEventMonitors.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Global + local NSEvent monitors that stream mouse moves and
//  left-clicks into closures used by NotchViewModel.
//
//  Swift 6 Rewrite notes:
//  - No Combine (uses @MainActor async callbacks instead).
//  - Throttling is performed at the consumer (50ms debounce in VM).
//

import AppKit

/// Wraps an `NSEvent.add{Global,Local}MonitorForEvents` pair.
/// Safe lifecycle: `start()` installs, `stop()` or deinit removes.
final class NotchEventMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: @Sendable @MainActor (NSEvent) -> Void

    init(
        mask: NSEvent.EventTypeMask,
        handler: @escaping @Sendable @MainActor (NSEvent) -> Void
    ) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @MainActor
    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
            Task { @MainActor in self.handler(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            Task { @MainActor in self.handler(event) }
            return event
        }
    }

    @MainActor
    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

/// Singleton aggregator for the notch's global event streams.
/// Subscribers register closures; the monitor dispatches to each.
@MainActor
final class NotchEventMonitors {
    static let shared = NotchEventMonitors()

    /// Latest known mouse-location (global screen coords).
    private(set) var mouseLocation: CGPoint = .zero

    private var moveObservers: [UUID: @MainActor (CGPoint) -> Void] = [:]
    private var clickObservers: [UUID: @MainActor (NSEvent) -> Void] = [:]

    private var moveMonitor: NotchEventMonitor?
    private var clickMonitor: NotchEventMonitor?
    private var dragMonitor: NotchEventMonitor?

    private init() {
        install()
    }

    private func install() {
        moveMonitor = NotchEventMonitor(mask: .mouseMoved) { [weak self] _ in
            self?.broadcastMove(NSEvent.mouseLocation)
        }
        moveMonitor?.start()

        dragMonitor = NotchEventMonitor(mask: .leftMouseDragged) { [weak self] _ in
            self?.broadcastMove(NSEvent.mouseLocation)
        }
        dragMonitor?.start()

        clickMonitor = NotchEventMonitor(mask: .leftMouseDown) { [weak self] event in
            self?.broadcastClick(event)
        }
        clickMonitor?.start()
    }

    private func broadcastMove(_ location: CGPoint) {
        mouseLocation = location
        for observer in moveObservers.values {
            observer(location)
        }
    }

    private func broadcastClick(_ event: NSEvent) {
        for observer in clickObservers.values {
            observer(event)
        }
    }

    /// Subscribe to mouse-move events. Returns a cancellation token.
    @discardableResult
    func onMove(_ handler: @escaping @MainActor (CGPoint) -> Void) -> UUID {
        let id = UUID()
        moveObservers[id] = handler
        return id
    }

    /// Subscribe to left-mouse-down events. Returns a cancellation token.
    @discardableResult
    func onClick(_ handler: @escaping @MainActor (NSEvent) -> Void) -> UUID {
        let id = UUID()
        clickObservers[id] = handler
        return id
    }

    func cancel(_ id: UUID) {
        moveObservers.removeValue(forKey: id)
        clickObservers.removeValue(forKey: id)
    }
}
