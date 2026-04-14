import Foundation
import Observation

/// Manages break scheduling based on medical guidelines.
///
/// Tracks continuous usage time, schedules breaks at appropriate intervals,
/// and provides reactive state for the menu bar UI.
///
/// Break schedule:
/// - Micro-break: every 20 min → 20 sec (20-20-20 rule)
/// - Macro-break: every 60 min → 5 min
/// - Mandatory break: every 120 min → 15 min
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

    // MARK: - Internal State

    private var sessionStartTime: Date = .now
    private var timerTask: Task<Void, Never>?
    private var preferences: UserPreferences = .default

    // MARK: - Initialization

    init() {
        startTimerLoop()
    }

    // Note: timerTask is cancelled when the scheduler is no longer referenced.
    // In a @MainActor class, deinit cannot access actor-isolated properties,
    // so cleanup is handled by the Task's weak self reference going nil.

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

    /// Called when idle is detected — resets timers since user is resting.
    func handleIdleDetected() {
        guard !isPaused else { return }
        // User is already resting, reset micro-break timer
        resetTimersAfterBreak(.micro)
    }

    /// Called when user returns from idle.
    func handleActivityResumed() {
        guard !isPaused else { return }
        sessionStartTime = .now
        currentSessionDuration = 0
    }

    // MARK: - Private

    /// Main timer loop — ticks every second to update UI state.
    private func startTimerLoop() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                await MainActor.run {
                    self.tick()
                }
            }
        }
    }

    /// Called every second to update session duration and check for due breaks.
    private func tick() {
        guard !isPaused else { return }

        currentSessionDuration = Date.now.timeIntervalSince(sessionStartTime)
        updateNextBreak()
        checkForDueBreaks()
    }

    /// Determines which break is next and how long until it triggers.
    private func updateNextBreak() {
        let elapsed = currentSessionDuration

        // Check breaks in order of urgency (shortest interval first)
        let candidates: [(BreakType, TimeInterval)] = [
            (.micro, preferences.microBreakInterval),
            (.macro, preferences.macroBreakInterval),
            (.mandatory, preferences.mandatoryBreakInterval),
        ]

        var soonest: (BreakType, TimeInterval)? = nil

        for (type, interval) in candidates {
            guard isBreakTypeEnabled(type) else { continue }

            let timeInCurrentCycle = elapsed.truncatingRemainder(dividingBy: interval)
            let remaining = interval - timeInCurrentCycle

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
    private func checkForDueBreaks() {
        let elapsed = currentSessionDuration

        // Check each break type
        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }

            let interval = type.interval
            let timeInCycle = elapsed.truncatingRemainder(dividingBy: interval)

            // Break is due when we cross the interval boundary (within 1-sec tolerance)
            if timeInCycle < 1.0 && elapsed >= interval {
                triggerBreakNotification(type)
            }
        }
    }

    /// Sends a break notification to the user.
    private func triggerBreakNotification(_ type: BreakType) {
        // TODO: Integrate with NotificationManager for escalation tiers
        print("[BreakScheduler] Break due: \(type.displayName)")
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

    /// Resets timers after a break is taken.
    private func resetTimersAfterBreak(_ type: BreakType) {
        // For micro-breaks, just reset the micro timer
        // For macro/mandatory, reset all shorter timers too
        switch type {
        case .micro:
            break
        case .macro:
            break
        case .mandatory:
            break
        }

        // Simplified: reset session start to now
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

    /// Recalculates the current health score based on today's breaks.
    private func recalculateHealthScore() {
        let totalScheduled = breaksTakenToday + breaksSkippedToday
        guard totalScheduled > 0 else {
            currentHealthScore = 100
            return
        }

        let calculator = HealthScoreCalculator()
        let score = calculator.calculate(
            breakEvents: todayBreakEvents,
            totalScreenTime: currentSessionDuration,
            longestContinuousSession: currentSessionDuration
        )
        currentHealthScore = score.totalScore
    }
}
