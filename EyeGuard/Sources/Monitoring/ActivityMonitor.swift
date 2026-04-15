import AppKit
import Foundation
import os

/// Actor responsible for monitoring user activity via CGEventTap.
///
/// Tracks the last activity timestamp and determines idle state.
/// Uses an actor to ensure thread safety since CGEventTap callbacks
/// arrive on arbitrary threads.
///
/// Also detects screen lock/unlock via DistributedNotificationCenter
/// to auto-pause/resume monitoring (ported from eyes-health, v2.2).
///
/// Conforms to `ActivityMonitoring` for testability.
actor ActivityMonitor: ActivityMonitoring {

    // MARK: - Singleton

    static let shared = ActivityMonitor()

    // MARK: - State

    private(set) var lastActivityTimestamp: Date = .now
    private(set) var isIdle: Bool = false
    private(set) var isMonitoring: Bool = false

    /// Whether the screen is currently locked.
    /// When locked, the monitor treats the user as idle (break timers pause).
    private(set) var isScreenLocked: Bool = false

    /// Tracks the date of the last daily rollover for midnight reset.
    private var lastRolloverDate: Date = .now

    private var idleCheckTask: Task<Void, Never>?

    /// Helper to observe DistributedNotificationCenter from within the actor.
    private var screenLockObserver: ScreenLockObserver?

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
        isScreenLocked = false
        lastRolloverDate = .now

        startIdleCheckLoop()
        startEventTap()
        registerScreenLockObservers()

        Log.activity.info("Monitoring started.")
    }

    /// Stops monitoring and cleans up resources.
    func stopMonitoring() {
        isMonitoring = false
        idleCheckTask?.cancel()
        idleCheckTask = nil
        unregisterScreenLockObservers()
        Log.activity.info("Monitoring stopped.")
    }

    /// Called when a user input event is detected.
    func recordActivity() {
        lastActivityTimestamp = .now
        if isIdle {
            isIdle = false
            Log.activity.info("User returned from idle.")
        }
    }

    /// Resets internal state for testing and daily rollover (BUG-005).
    func resetState() {
        lastActivityTimestamp = .now
        isIdle = false
        isScreenLocked = false
        lastRolloverDate = .now
        Log.activity.info("State reset.")
    }

    /// Returns the duration since the last detected user activity.
    var timeSinceLastActivity: TimeInterval {
        Date.now.timeIntervalSince(lastActivityTimestamp)
    }

    // MARK: - Screen Lock Handling

    /// Called by `ScreenLockObserver` when the screen is locked.
    func handleScreenLocked() {
        isScreenLocked = true
        isIdle = true
        Log.activity.info("Screen locked — treating as idle, break timers paused.")
    }

    /// Called by `ScreenLockObserver` when the screen is unlocked.
    func handleScreenUnlocked() {
        isScreenLocked = false
        lastActivityTimestamp = .now
        isIdle = false
        Log.activity.info("Screen unlocked — resuming activity monitoring.")
    }

    // MARK: - Private

    /// Periodically checks if the user has gone idle and handles daily rollover.
    private func startIdleCheckLoop() {
        idleCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                checkIdleState()
                checkDailyRollover()
            }
        }
    }

    private func checkIdleState() {
        // If screen is locked, already marked idle — skip polling
        guard !isScreenLocked else { return }

        let elapsed = timeSinceLastActivity
        let wasIdle = isIdle
        isIdle = elapsed >= EyeGuardConstants.idleThreshold

        if isIdle && !wasIdle {
            Log.activity.info("User is now idle (inactive for \(Int(elapsed))s).")
        }
    }

    /// Resets state at midnight for a new day (daily rollover).
    private func checkDailyRollover() {
        let calendar = Calendar.current
        let now = Date.now
        if !calendar.isDate(now, inSameDayAs: lastRolloverDate) {
            lastRolloverDate = now
            lastActivityTimestamp = now
            isIdle = false
            Log.activity.info("Daily rollover: state reset for new day.")
        }
    }

    /// Registers observers for macOS screen lock/unlock notifications.
    private func registerScreenLockObservers() {
        let observer = ScreenLockObserver(monitor: self)
        observer.register()
        screenLockObserver = observer
    }

    /// Removes screen lock/unlock observers.
    private func unregisterScreenLockObservers() {
        screenLockObserver?.unregister()
        screenLockObserver = nil
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

        Log.activity.info("CGEventTap setup skipped (placeholder). Idle detection runs via polling.")
    }
}

// MARK: - Screen Lock Observer

/// NSObject wrapper that listens for macOS screen lock/unlock notifications
/// via DistributedNotificationCenter and forwards events to the ActivityMonitor actor.
///
/// Necessary because DistributedNotificationCenter requires an NSObject target
/// with @objc selectors, which actors cannot directly provide.
private final class ScreenLockObserver: NSObject, @unchecked Sendable {
    private let monitor: ActivityMonitor

    init(monitor: ActivityMonitor) {
        self.monitor = monitor
        super.init()
    }

    func register() {
        let dnc = DistributedNotificationCenter.default()

        dnc.addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )

        dnc.addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }

    func unregister() {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func screenDidLock() {
        Task {
            await monitor.handleScreenLocked()
        }
    }

    @objc private func screenDidUnlock() {
        Task {
            await monitor.handleScreenUnlocked()
        }
    }

    deinit {
        unregister()
    }
}
