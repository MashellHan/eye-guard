import AppKit
import Foundation

/// Actor responsible for monitoring user activity via CGEventTap.
///
/// Tracks the last activity timestamp and determines idle state.
/// Uses an actor to ensure thread safety since CGEventTap callbacks
/// arrive on arbitrary threads.
actor ActivityMonitor {

    // MARK: - Singleton

    static let shared = ActivityMonitor()

    // MARK: - State

    private(set) var lastActivityTimestamp: Date = .now
    private(set) var isIdle: Bool = false
    private(set) var isMonitoring: Bool = false

    private var idleCheckTask: Task<Void, Never>?

    // MARK: - Public API

    /// Starts monitoring user input events.
    ///
    /// Requires accessibility permissions (CGEventTap).
    /// If permissions are not granted, monitoring will not start
    /// but no error is thrown — the app degrades gracefully.
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastActivityTimestamp = .now
        isIdle = false

        startIdleCheckLoop()
        startEventTap()

        print("[ActivityMonitor] Monitoring started.")
    }

    /// Stops monitoring and cleans up resources.
    func stopMonitoring() {
        isMonitoring = false
        idleCheckTask?.cancel()
        idleCheckTask = nil
        print("[ActivityMonitor] Monitoring stopped.")
    }

    /// Called when a user input event is detected.
    func recordActivity() {
        lastActivityTimestamp = .now
        if isIdle {
            isIdle = false
            print("[ActivityMonitor] User returned from idle.")
        }
    }

    /// Returns the duration since the last detected user activity.
    var timeSinceLastActivity: TimeInterval {
        Date.now.timeIntervalSince(lastActivityTimestamp)
    }

    // MARK: - Private

    /// Periodically checks if the user has gone idle.
    private func startIdleCheckLoop() {
        idleCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self else { return }
                await self.checkIdleState()
            }
        }
    }

    private func checkIdleState() {
        let elapsed = timeSinceLastActivity
        let wasIdle = isIdle
        isIdle = elapsed >= EyeGuardConstants.idleThreshold

        if isIdle && !wasIdle {
            print("[ActivityMonitor] User is now idle (inactive for \(Int(elapsed))s).")
        }
    }

    /// Sets up a CGEventTap to listen for user input events.
    ///
    /// - Note: This requires accessibility permissions.
    ///   The actual CGEventTap implementation is a placeholder —
    ///   full implementation requires running on the main thread
    ///   with proper run loop integration.
    private func startEventTap() {
        // TODO: Implement CGEventTap for production use.
        //
        // CGEventTap requires:
        // 1. Accessibility permissions (AXIsProcessTrusted)
        // 2. Creating a tap with CGEvent.tapCreate()
        // 3. Adding the tap as a run loop source on the main run loop
        // 4. Calling recordActivity() from the callback
        //
        // Event mask should include:
        //   - .mouseMoved
        //   - .keyDown
        //   - .scrollWheel
        //   - .leftMouseDown, .rightMouseDown
        //
        // For now, the idle check loop runs independently
        // and activity is recorded only when explicitly called.

        print("[ActivityMonitor] CGEventTap setup skipped (placeholder). Idle detection runs via polling.")
    }
}
