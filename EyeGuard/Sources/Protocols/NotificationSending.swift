import Foundation

/// Protocol for notification delivery, enabling testability via dependency injection.
///
/// Production: `NotificationManager` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol NotificationSending {
    /// Whether a notification is currently being displayed.
    var isNotificationActive: Bool { get }

    /// Sends a break notification using mode-aware behavior (v2.4).
    ///
    /// - Parameters:
    ///   - breakType: The type of break to notify about.
    ///   - behavior: Behavioral configuration for this break type (entry tier, dismiss policy).
    ///   - escalation: Escalation strategy (direct or tiered).
    ///   - healthScore: Current eye health score (0-100) to display in overlays.
    ///   - onTaken: Callback when user acknowledges the break.
    ///   - onSkipped: Callback when user dismisses/skips the break.
    ///   - onPostponed: Callback when user postpones the break (receives delay in seconds).
    ///   - exerciseSessionsToday: Number of exercise sessions completed today (v2.5).
    ///   - recommendedExerciseSessions: Recommended exercise sessions based on screen time (v2.5).
    ///   - onStartExercises: Optional callback when user starts exercises from break overlay (v2.5).
    func notify(
        breakType: BreakType,
        behavior: BreakBehavior,
        escalation: EscalationStrategy,
        healthScore: Int,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void,
        onPostponed: @escaping @Sendable (TimeInterval) -> Void,
        exerciseSessionsToday: Int,
        recommendedExerciseSessions: Int,
        onStartExercises: (@Sendable () -> Void)?
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

// MARK: - Default Exercise Parameters

extension NotificationSending {
    /// Convenience overload without exercise parameters (backward compatibility).
    func notify(
        breakType: BreakType,
        behavior: BreakBehavior,
        escalation: EscalationStrategy,
        healthScore: Int,
        onTaken: @escaping @Sendable () -> Void,
        onSkipped: @escaping @Sendable () -> Void,
        onPostponed: @escaping @Sendable (TimeInterval) -> Void
    ) {
        notify(
            breakType: breakType,
            behavior: behavior,
            escalation: escalation,
            healthScore: healthScore,
            onTaken: onTaken,
            onSkipped: onSkipped,
            onPostponed: onPostponed,
            exerciseSessionsToday: 0,
            recommendedExerciseSessions: 1,
            onStartExercises: nil
        )
    }
}
