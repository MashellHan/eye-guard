import Foundation

/// Central repository for medical guideline constants and app configuration defaults.
enum EyeGuardConstants {

    // MARK: - Break Intervals (seconds)

    /// Micro-break interval: 20 minutes (20-20-20 rule).
    /// Source: American Academy of Ophthalmology.
    static let microBreakInterval: TimeInterval = 20 * 60

    /// Macro-break interval: 60 minutes.
    /// Source: OSHA recommendations.
    static let macroBreakInterval: TimeInterval = 60 * 60

    /// Mandatory break interval: 120 minutes.
    /// Source: EU Screen Equipment Directive.
    static let mandatoryBreakInterval: TimeInterval = 120 * 60

    // MARK: - Break Durations (seconds)

    /// Micro-break duration: 20 seconds.
    static let microBreakDuration: TimeInterval = 20

    /// Macro-break duration: 5 minutes.
    static let macroBreakDuration: TimeInterval = 5 * 60

    /// Mandatory break duration: 15 minutes.
    static let mandatoryBreakDuration: TimeInterval = 15 * 60

    // MARK: - Idle Detection

    /// Idle threshold: 30 seconds of no input = idle.
    static let idleThreshold: TimeInterval = 30

    // MARK: - Notification Escalation

    /// Delay before escalating from Tier 1 to Tier 2.
    static let tier1EscalationDelay: TimeInterval = 2 * 60

    /// Delay before escalating from Tier 2 to Tier 3.
    static let tier2EscalationDelay: TimeInterval = 5 * 60

    /// Maximum snooze duration.
    static let maxSnoozeDuration: TimeInterval = 5 * 60

    // MARK: - Health Score Weights

    /// Maximum points for break compliance.
    static let breakComplianceMaxPoints = 40

    /// Maximum points for continuous use discipline.
    static let continuousUseDisciplineMaxPoints = 30

    /// Maximum points for total screen time.
    static let screenTimeMaxPoints = 20

    /// Maximum points for break quality.
    static let breakQualityMaxPoints = 10

    /// Recommended maximum daily screen time: 8 hours.
    static let recommendedMaxScreenTime: TimeInterval = 8 * 60 * 60

    // MARK: - Reminder Mode

    /// Default reminder mode for new users.
    static let defaultReminderMode: ReminderMode = .aggressive

    /// Postpone delay: 5 minutes per postpone.
    static let postponeDelay: TimeInterval = 5 * 60

    /// Maximum number of postpones per break notification.
    static let maxPostponeCount: Int = 2

    // MARK: - File Paths

    /// Base directory for EyeGuard data.
    static var baseDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("EyeGuard", isDirectory: true)
    }

    /// Directory for daily Markdown reports.
    static var reportsDirectory: URL {
        baseDirectory.appendingPathComponent("reports", isDirectory: true)
    }

    /// Directory for JSON data files.
    static var dataDirectory: URL {
        baseDirectory.appendingPathComponent("data", isDirectory: true)
    }
    // MARK: - Pre-Alert Durations (seconds)

    /// Pre-alert duration before micro break.
    static let microPreAlertDuration: TimeInterval = 10

    /// Pre-alert duration before macro break.
    static let macroPreAlertDuration: TimeInterval = 15

    /// Pre-alert duration before mandatory break.
    static let mandatoryPreAlertDuration: TimeInterval = 20
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps "Start Eye Exercises" from the break overlay.
    static let startExercisesFromBreak = Notification.Name("EyeGuard.startExercisesFromBreak")

    /// Posted when the user requests a random eye-care tip from the menu bar.
    /// userInfo: ["tipId": Int]
    static let showEyeTipRequested = Notification.Name("EyeGuard.showEyeTipRequested")

    /// Posted when a pre-break alert countdown starts.
    /// userInfo: ["breakType": BreakType, "seconds": Int]
    static let preAlertStarted = Notification.Name("EyeGuard.preAlertStarted")

    /// Posted each second during pre-alert countdown.
    /// userInfo: ["breakType": BreakType, "remaining": Int]
    static let preAlertCountdown = Notification.Name("EyeGuard.preAlertCountdown")

    /// Posted when pre-alert is cancelled (idle, postpone, etc.).
    static let preAlertCancelled = Notification.Name("EyeGuard.preAlertCancelled")
}
