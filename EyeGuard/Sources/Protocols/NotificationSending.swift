import Foundation

/// Protocol for notification delivery, enabling testability via dependency injection.
///
/// Production: `NotificationManager` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol NotificationSending {
    /// Sends a break notification with escalation.
    ///
    /// - Parameters:
    ///   - breakType: The type of break to notify about.
    ///   - onTaken: Callback when user acknowledges the break.
    ///   - onSkipped: Callback when user dismisses/skips the break.
    func notify(
        breakType: BreakType,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void
    )

    /// Dismisses the current notification (user took the break).
    func acknowledgeBreak()

    /// Snoozes the current notification for a short period.
    ///
    /// - Parameters:
    ///   - breakType: The break type being snoozed.
    ///   - onDue: Callback when snooze expires and break is due again.
    func snooze(breakType: BreakType, onDue: @escaping @Sendable () -> Void)

    /// Requests notification permission from the user.
    func setup()
}
