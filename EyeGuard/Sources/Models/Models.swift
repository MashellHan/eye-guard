import Foundation

// MARK: - BreakEvent

/// Records a single break event, whether taken or skipped.
struct BreakEvent: Codable, Sendable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: BreakType
    let wasTaken: Bool
    let actualDuration: TimeInterval

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        type: BreakType,
        wasTaken: Bool,
        actualDuration: TimeInterval = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.wasTaken = wasTaken
        self.actualDuration = actualDuration
    }
}

// MARK: - UsageSession

/// Represents a continuous period of computer usage.
struct UsageSession: Codable, Sendable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let activeTime: TimeInterval
    let breaks: [BreakEvent]

    init(
        id: UUID = UUID(),
        startTime: Date = .now,
        endTime: Date? = nil,
        activeTime: TimeInterval = 0,
        breaks: [BreakEvent] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.activeTime = activeTime
        self.breaks = breaks
    }

    /// Returns a new session with the given break appended.
    func addingBreak(_ breakEvent: BreakEvent) -> UsageSession {
        UsageSession(
            id: id,
            startTime: startTime,
            endTime: endTime,
            activeTime: activeTime,
            breaks: breaks + [breakEvent]
        )
    }

    /// Returns a new session marked as ended at the given time.
    func ending(at time: Date = .now) -> UsageSession {
        UsageSession(
            id: id,
            startTime: startTime,
            endTime: time,
            activeTime: activeTime,
            breaks: breaks
        )
    }
}

// MARK: - HealthScore

/// Composite health score for a given day, scored 0-100.
struct HealthScore: Codable, Sendable {
    /// Overall score (0-100).
    let totalScore: Int
    /// Break compliance component (0-40 pts).
    let breakCompliance: Int
    /// Continuous use discipline component (0-30 pts).
    let continuousUseDiscipline: Int
    /// Total screen time component (0-20 pts).
    let screenTimeScore: Int
    /// Break quality component (0-10 pts).
    let breakQuality: Int

    init(
        breakCompliance: Int,
        continuousUseDiscipline: Int,
        screenTimeScore: Int,
        breakQuality: Int
    ) {
        self.breakCompliance = min(max(breakCompliance, 0), 40)
        self.continuousUseDiscipline = min(max(continuousUseDiscipline, 0), 30)
        self.screenTimeScore = min(max(screenTimeScore, 0), 20)
        self.breakQuality = min(max(breakQuality, 0), 10)
        self.totalScore = self.breakCompliance
            + self.continuousUseDiscipline
            + self.screenTimeScore
            + self.breakQuality
    }
}

// MARK: - UserPreferences

/// User-configurable preferences for break scheduling and notifications.
struct UserPreferences: Codable, Sendable {
    var microBreakInterval: TimeInterval
    var microBreakDuration: TimeInterval
    var macroBreakInterval: TimeInterval
    var macroBreakDuration: TimeInterval
    var mandatoryBreakInterval: TimeInterval
    var mandatoryBreakDuration: TimeInterval
    var isMicroBreakEnabled: Bool
    var isMacroBreakEnabled: Bool
    var isMandatoryBreakEnabled: Bool
    var isSoundEnabled: Bool
    var isEscalationEnabled: Bool

    /// Active reminder mode preset (v2.4).
    var reminderMode: ReminderMode

    /// Returns the behavioral profile for the active reminder mode (v2.4).
    var activeProfile: ReminderModeProfile {
        reminderMode.profile()
    }

    /// Default preferences based on medical guidelines.
    static let `default` = UserPreferences(
        microBreakInterval: EyeGuardConstants.microBreakInterval,
        microBreakDuration: EyeGuardConstants.microBreakDuration,
        macroBreakInterval: EyeGuardConstants.macroBreakInterval,
        macroBreakDuration: EyeGuardConstants.macroBreakDuration,
        mandatoryBreakInterval: EyeGuardConstants.mandatoryBreakInterval,
        mandatoryBreakDuration: EyeGuardConstants.mandatoryBreakDuration,
        isMicroBreakEnabled: true,
        isMacroBreakEnabled: true,
        isMandatoryBreakEnabled: true,
        isSoundEnabled: true,
        isEscalationEnabled: true,
        reminderMode: EyeGuardConstants.defaultReminderMode
    )
}

// MARK: - DailyReport

/// Aggregated report for a single day.
struct DailyReport: Codable, Sendable, Identifiable {
    var id: String { dateString }

    let dateString: String
    let sessions: [UsageSession]
    let healthScore: HealthScore
    let totalScreenTime: TimeInterval
    let totalBreaksTaken: Int
    let totalBreaksScheduled: Int

    init(
        date: Date,
        sessions: [UsageSession],
        healthScore: HealthScore,
        totalScreenTime: TimeInterval,
        totalBreaksTaken: Int,
        totalBreaksScheduled: Int
    ) {
        self.dateString = TimeFormatting.dateStringFormatter.string(from: date)
        self.sessions = sessions
        self.healthScore = healthScore
        self.totalScreenTime = totalScreenTime
        self.totalBreaksTaken = totalBreaksTaken
        self.totalBreaksScheduled = totalBreaksScheduled
    }
}
