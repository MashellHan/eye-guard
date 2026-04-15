import Foundation
import Observation
import os

/// Manages break scheduling based on medical guidelines.
///
/// Tracks continuous usage time, schedules breaks at appropriate intervals,
/// and provides reactive state for the menu bar UI.
///
/// Break schedule:
/// - Micro-break: every 20 min → 20 sec (20-20-20 rule)
/// - Macro-break: every 60 min → 5 min
/// - Mandatory break: every 120 min → 15 min
///
/// Accepts `ActivityMonitoring` and `NotificationSending` protocols via init
/// for testability (H6).
@Observable
@MainActor
final class BreakScheduler {

    // MARK: - Published State

    /// Whether scheduling is paused by the user.
    private(set) var isPaused: Bool = false

    /// Duration of the current continuous usage session.
    private(set) var currentSessionDuration: TimeInterval = 0

    /// The next break type that will trigger.
    private(set) var nextScheduledBreak: BreakType? = .micro

    /// Time remaining until the next break.
    private(set) var timeUntilNextBreak: TimeInterval = EyeGuardConstants.microBreakInterval

    /// Number of breaks taken today.
    private(set) var breaksTakenToday: Int = 0

    /// Number of breaks skipped today.
    private(set) var breaksSkippedToday: Int = 0

    /// Current health score (0-100).
    private(set) var currentHealthScore: Int = 100

    /// All break events recorded today.
    private(set) var todayBreakEvents: [BreakEvent] = []

    /// Total screen time accumulated across all sessions today (BUG-002).
    private(set) var totalScreenTimeToday: TimeInterval = 0

    /// Longest continuous session without a mandatory break (updated each tick).
    private(set) var longestContinuousSession: TimeInterval = 0

    /// Number of continuous use warnings (Tier 3) issued today.
    private(set) var continuousUseWarnings: Int = 0

    // MARK: - Internal State

    private var sessionStartTime: Date = .now
    private var timerTask: Task<Void, Never>?
    private let preferences: UserPreferences

    /// Tracks whether the user was idle on the previous tick (H1).
    private var wasIdle: Bool = false

    /// Per-break-type elapsed time for independent tracking (H5/BUG-001).
    private var elapsedPerType: [BreakType: TimeInterval] = [
        .micro: 0,
        .macro: 0,
        .mandatory: 0,
    ]

    /// Tracks the last notified cycle per break type to prevent double-fire (BUG-003).
    private var lastNotifiedCycle: [BreakType: Int] = [
        .micro: -1,
        .macro: -1,
        .mandatory: -1,
    ]

    /// Date of the last daily rollover check.
    private var lastRolloverDate: Date = .now

    /// The activity monitor dependency (H6).
    private let activityMonitor: any ActivityMonitoring

    /// The notification manager dependency (H6).
    private let notificationSender: any NotificationSending

    // MARK: - Initialization

    /// Creates a new BreakScheduler with injectable dependencies (H6).
    ///
    /// - Parameters:
    ///   - activityMonitor: Activity monitoring service (defaults to shared singleton).
    ///   - notificationSender: Notification delivery service (defaults to shared singleton).
    ///   - preferences: User preferences for break intervals.
    init(
        activityMonitor: any ActivityMonitoring = ActivityMonitor.shared,
        notificationSender: any NotificationSending = NotificationManager.shared,
        preferences: UserPreferences = .default
    ) {
        self.activityMonitor = activityMonitor
        self.notificationSender = notificationSender
        self.preferences = preferences
        startTimerLoop()
    }

    // MARK: - Public Controls

    /// Toggles pause/resume of break scheduling.
    func togglePause() {
        isPaused.toggle()
        if !isPaused {
            // Resuming — reset session start so timers recalculate
            sessionStartTime = Date.now.addingTimeInterval(-currentSessionDuration)
        }
    }

    /// Resets the current session, clearing all timers.
    func resetSession() {
        sessionStartTime = .now
        currentSessionDuration = 0
        timeUntilNextBreak = preferences.microBreakInterval
        nextScheduledBreak = .micro

        for type in BreakType.allCases {
            elapsedPerType[type] = 0
            lastNotifiedCycle[type] = -1
        }
    }

    /// Resets all daily counters (daily rollover).
    func resetDaily() {
        breaksTakenToday = 0
        breaksSkippedToday = 0
        currentHealthScore = 100
        todayBreakEvents = []
        totalScreenTimeToday = 0
        longestContinuousSession = 0
        continuousUseWarnings = 0
        resetSession()
        Log.scheduler.info("Daily counters reset for new day.")
    }

    /// Immediately triggers a break of the given type.
    func takeBreakNow(_ type: BreakType) {
        recordBreak(type: type, wasTaken: true)
        resetTimersAfterBreak(type)
    }

    /// Records that the user skipped a scheduled break.
    func skipBreak(_ type: BreakType) {
        recordBreak(type: type, wasTaken: false)
    }

    /// Called when idle is detected — resets timers since user is resting (H1).
    func handleIdleDetected() {
        guard !isPaused else { return }
        // User is already resting, reset micro-break timer
        resetTimersAfterBreak(.micro)
        Log.scheduler.info("Idle detected, micro timer reset.")
    }

    /// Called when user returns from idle (H1).
    func handleActivityResumed() {
        guard !isPaused else { return }
        sessionStartTime = .now
        currentSessionDuration = 0
        Log.scheduler.info("Activity resumed, session restarted.")
    }

    // MARK: - Private: Timer Loop

    /// Main timer loop — ticks every second to update UI state.
    /// Fixed concurrency: no [weak self] or MainActor.run needed since
    /// BreakScheduler is @MainActor (C1).
    private func startTimerLoop() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                tick()
            }
        }
    }

    /// Called every second to update session duration and check for due breaks.
    /// Also polls ActivityMonitor for idle state (H1) and tracks continuous use.
    private func tick() {
        guard !isPaused else { return }

        let previousDuration = currentSessionDuration
        currentSessionDuration = Date.now.timeIntervalSince(sessionStartTime)

        // Accumulate daily screen time (BUG-002)
        let delta = currentSessionDuration - previousDuration
        if delta > 0 {
            totalScreenTimeToday += delta
        }

        // Track longest continuous session
        if currentSessionDuration > longestContinuousSession {
            longestContinuousSession = currentSessionDuration
        }

        // Update per-type elapsed times (H5)
        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }
            elapsedPerType[type, default: 0] += max(delta, 0)
        }

        updateNextBreak()
        checkForDueBreaks()
        checkContinuousUse()
        checkDailyRollover()

        // Poll activity monitor for idle state (H1)
        Task {
            let idle = await activityMonitor.isIdle
            if idle && !wasIdle {
                handleIdleDetected()
                wasIdle = true
            } else if !idle && wasIdle {
                handleActivityResumed()
                wasIdle = false
            }
        }
    }

    /// Determines which break is next and how long until it triggers.
    private func updateNextBreak() {
        var soonest: (BreakType, TimeInterval)? = nil

        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }

            let elapsed = elapsedPerType[type, default: 0]
            let interval = intervalForType(type)
            let remaining = interval - elapsed

            if remaining > 0 {
                if soonest == nil || remaining < soonest!.1 {
                    soonest = (type, remaining)
                }
            }
        }

        if let (type, remaining) = soonest {
            nextScheduledBreak = type
            timeUntilNextBreak = remaining
        }
    }

    /// Checks if any break is due and triggers notification.
    /// Uses `lastNotifiedCycle` per break type to prevent double-fire (BUG-003).
    private func checkForDueBreaks() {
        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }

            let elapsed = elapsedPerType[type, default: 0]
            let interval = intervalForType(type)

            guard interval > 0 else { continue }

            let currentCycle = Int(elapsed / interval)

            // Only fire if we crossed into a new cycle and haven't notified for it (BUG-003)
            if currentCycle > 0 && currentCycle != lastNotifiedCycle[type] {
                lastNotifiedCycle[type] = currentCycle
                triggerBreakNotification(type)
            }
        }
    }

    /// Sends a break notification wired to NotificationManager (H2).
    private func triggerBreakNotification(_ breakType: BreakType) {
        Log.scheduler.info("Break due: \(breakType.displayName)")

        notificationSender.notify(breakType: breakType) { [weak self] in
            Task { @MainActor in
                self?.takeBreakNow(breakType)
            }
        } onSkipped: { [weak self] in
            Task { @MainActor in
                self?.skipBreak(breakType)
            }
        }
    }

    /// Checks if continuous use has reached the mandatory break threshold (120 min).
    /// Triggers Tier 3 full-screen overlay via NotificationManager when exceeded.
    private func checkContinuousUse() {
        let threshold = preferences.mandatoryBreakInterval
        guard currentSessionDuration >= threshold else { return }

        // Only warn once per session crossing the threshold
        let warningCycle = Int(currentSessionDuration / threshold)
        if warningCycle > continuousUseWarnings {
            continuousUseWarnings = warningCycle
            Log.scheduler.warning(
                "Continuous use reached \(Int(self.currentSessionDuration / 60)) minutes — triggering Tier 3."
            )
            triggerBreakNotification(.mandatory)
        }
    }

    /// Records a break event in today's history.
    private func recordBreak(type: BreakType, wasTaken: Bool) {
        let event = BreakEvent(
            type: type,
            wasTaken: wasTaken,
            actualDuration: wasTaken ? type.duration : 0
        )
        todayBreakEvents = todayBreakEvents + [event]

        if wasTaken {
            breaksTakenToday += 1
        } else {
            breaksSkippedToday += 1
        }

        recalculateHealthScore()
    }

    /// Resets timers after a break is taken (H5/BUG-001).
    /// Per-type reset logic:
    /// - Micro break: only reset micro timer
    /// - Macro break: reset macro + micro timers
    /// - Mandatory break: reset all three timers
    private func resetTimersAfterBreak(_ type: BreakType) {
        switch type {
        case .micro:
            elapsedPerType[.micro] = 0
            lastNotifiedCycle[.micro] = -1

        case .macro:
            elapsedPerType[.macro] = 0
            elapsedPerType[.micro] = 0
            lastNotifiedCycle[.macro] = -1
            lastNotifiedCycle[.micro] = -1

        case .mandatory:
            for t in BreakType.allCases {
                elapsedPerType[t] = 0
                lastNotifiedCycle[t] = -1
            }
        }

        // Reset session tracking
        sessionStartTime = .now
        currentSessionDuration = 0
    }

    /// Checks if a break type is enabled in user preferences.
    private func isBreakTypeEnabled(_ type: BreakType) -> Bool {
        switch type {
        case .micro:     return preferences.isMicroBreakEnabled
        case .macro:     return preferences.isMacroBreakEnabled
        case .mandatory: return preferences.isMandatoryBreakEnabled
        }
    }

    /// Returns the configured interval for a break type.
    private func intervalForType(_ type: BreakType) -> TimeInterval {
        switch type {
        case .micro:     return preferences.microBreakInterval
        case .macro:     return preferences.macroBreakInterval
        case .mandatory: return preferences.mandatoryBreakInterval
        }
    }

    /// Recalculates the current health score based on today's breaks.
    /// Uses `totalScreenTimeToday` for daily accumulation (BUG-002).
    /// Uses `longestContinuousSession` for continuous use discipline scoring.
    private func recalculateHealthScore() {
        let totalScheduled = breaksTakenToday + breaksSkippedToday
        guard totalScheduled > 0 else {
            currentHealthScore = 100
            return
        }

        let calculator = HealthScoreCalculator()
        let score = calculator.calculate(
            breakEvents: todayBreakEvents,
            totalScreenTime: totalScreenTimeToday,
            longestContinuousSession: longestContinuousSession
        )
        currentHealthScore = score.totalScore
    }

    /// Checks for daily rollover at midnight and resets counters.
    private func checkDailyRollover() {
        let calendar = Calendar.current
        let now = Date.now
        if !calendar.isDate(now, inSameDayAs: lastRolloverDate) {
            lastRolloverDate = now
            resetDaily()
        }
    }
}
