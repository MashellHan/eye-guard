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

    /// Current score trend direction.
    private(set) var currentTrend: ScoreTrend = .stable

    /// Full score breakdown with component details.
    private(set) var currentBreakdown: HealthScoreBreakdown?

    /// Recent score history for trend calculation.
    private(set) var scoreHistory: [Int] = []

    /// Whether a break is currently in progress (user taking a break).
    private(set) var isBreakInProgress: Bool = false

    /// The type of break currently in progress, if any.
    private(set) var activeBreakType: BreakType?

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

    /// The sound manager dependency (v2.3 — protocol-based DI).
    private let soundPlayer: any SoundPlaying

    /// Tick counter for periodic health score recalculation (every 60 ticks = 1 minute).
    private var ticksSinceLastScoreUpdate: Int = 0

    /// Tick counter for periodic data persistence (every 300 ticks = 5 minutes).
    private var ticksSinceLastPersist: Int = 0

    /// Data persistence manager for JSON file I/O.
    @ObservationIgnored
    private let persistenceManager = DataPersistenceManager()

    /// Health score calculator (reusable instance instead of creating per-call, v1.9).
    @ObservationIgnored
    private let healthScoreCalculator = HealthScoreCalculator()

    // MARK: - Initialization

    /// Creates a new BreakScheduler with injectable dependencies (H6, v2.3).
    ///
    /// - Parameters:
    ///   - activityMonitor: Activity monitoring service (defaults to shared singleton).
    ///   - notificationSender: Notification delivery service (defaults to shared singleton).
    ///   - soundPlayer: Sound playback service (defaults to shared singleton, v2.3).
    ///   - preferences: User preferences for break intervals.
    init(
        activityMonitor: any ActivityMonitoring = ActivityMonitor.shared,
        notificationSender: any NotificationSending = NotificationManager.shared,
        soundPlayer: any SoundPlaying = SoundManager.shared,
        preferences: UserPreferences = .default
    ) {
        self.activityMonitor = activityMonitor
        self.notificationSender = notificationSender
        self.soundPlayer = soundPlayer
        self.preferences = preferences
        startTimerLoop()
        loadPersistedData()
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
        currentTrend = .stable
        currentBreakdown = nil
        scoreHistory = []
        isBreakInProgress = false
        activeBreakType = nil
        resetSession()
        Log.scheduler.info("Daily counters reset for new day.")
    }

    /// Immediately triggers a break of the given type.
    /// Sets break-in-progress state for mascot exercising animation.
    func takeBreakNow(_ type: BreakType) {
        isBreakInProgress = true
        activeBreakType = type
        recordBreak(type: type, wasTaken: true)
        resetTimersAfterBreak(type)

        // Start ambient sound during break (v1.6, v2.3 — uses injected soundPlayer)
        soundPlayer.startAmbient()

        // Auto-end break after the break duration
        Task {
            try? await Task.sleep(for: .seconds(type.duration))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.endBreak()
            }
        }
    }

    /// Ends the current break-in-progress state.
    func endBreak() {
        isBreakInProgress = false
        activeBreakType = nil

        // Stop ambient sound when break ends (v1.6, v2.3 — uses injected soundPlayer)
        soundPlayer.stopAmbient()
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

    /// Main timer loop — ticks every second for UI responsiveness.
    /// Heavy work (health score, persistence, idle polling) runs on a slower cadence.
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
    /// Lightweight operations run every tick; heavy operations run on slower cadence.
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

        // Heavy operations on slower cadence (every 5 seconds)
        ticksSinceLastScoreUpdate += 1
        if ticksSinceLastScoreUpdate >= 5 {
            checkContinuousUse()
            checkDailyRollover()
        }

        // Periodic health score recalculation (every 60 seconds)
        if ticksSinceLastScoreUpdate >= 60 {
            ticksSinceLastScoreUpdate = 0
            recalculateHealthScore()
        }

        // Periodic data persistence (every 300 seconds = 5 minutes)
        ticksSinceLastPersist += 1
        if ticksSinceLastPersist >= 300 {
            ticksSinceLastPersist = 0
            persistData()
        }

        // Poll activity monitor every 5 seconds (not every tick)
        if ticksSinceLastScoreUpdate % 5 == 0 {
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
    /// v2.4: Break absorption — when multiple breaks are due simultaneously,
    /// only the highest-priority break fires; lower-priority timers reset silently.
    private func checkForDueBreaks() {
        var dueBreaks: [(BreakType, Int)] = []

        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }

            let elapsed = elapsedPerType[type, default: 0]
            let interval = intervalForType(type)

            guard interval > 0 else { continue }

            let currentCycle = Int(elapsed / interval)

            // Collect all breaks that crossed into a new cycle
            if currentCycle > 0 && currentCycle != lastNotifiedCycle[type] {
                dueBreaks.append((type, currentCycle))
            }
        }

        guard !dueBreaks.isEmpty else { return }

        // Sort by priority descending — highest wins
        let sorted = dueBreaks.sorted { $0.0.priority > $1.0.priority }
        let winner = sorted[0]

        // Fire the highest-priority break
        lastNotifiedCycle[winner.0] = winner.1
        triggerBreakNotification(winner.0)

        // Silently reset lower-priority breaks (absorption)
        for i in 1..<sorted.count {
            let (type, cycle) = sorted[i]
            lastNotifiedCycle[type] = cycle
            elapsedPerType[type] = 0
            lastNotifiedCycle[type] = -1
            Log.scheduler.info(
                "Break \(type.displayName) absorbed by \(winner.0.displayName)."
            )
        }
    }

    /// Sends a break notification using mode-aware behavior (v2.4).
    /// Internal access for "Take Break Now" from mascot menu.
    func triggerBreakNotification(_ breakType: BreakType) {
        Log.scheduler.info("Break due: \(breakType.displayName)")

        let profile = preferences.activeProfile
        let behavior = profile.behavior(for: breakType)

        notificationSender.notify(
            breakType: breakType,
            behavior: behavior,
            escalation: profile.escalationStrategy,
            healthScore: currentHealthScore,
            onTaken: { [weak self] in
                Task { @MainActor in
                    self?.takeBreakNow(breakType)
                }
            },
            onSkipped: { [weak self] in
                Task { @MainActor in
                    self?.skipBreak(breakType)
                }
            },
            onPostponed: { [weak self] delay in
                Task { @MainActor in
                    self?.postponeBreak(breakType, by: delay)
                }
            }
        )
    }

    /// Postpones a break by the given delay (v2.4).
    /// Sets elapsed time back so the break re-fires after `delay` seconds.
    func postponeBreak(_ type: BreakType, by delay: TimeInterval) {
        let interval = intervalForType(type)
        // Set elapsed so the break is `delay` seconds away from re-triggering
        elapsedPerType[type] = max(0, interval - delay)
        // Reset notified cycle so it can fire again
        lastNotifiedCycle[type] = Int(elapsedPerType[type, default: 0] / interval)
        Log.scheduler.info(
            "Break \(type.displayName) postponed by \(Int(delay))s."
        )
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
    /// Updates trend tracking and full breakdown.
    private func recalculateHealthScore() {
        let totalScheduled = breaksTakenToday + breaksSkippedToday
        guard totalScheduled > 0 else {
            currentHealthScore = 100
            currentTrend = .stable
            return
        }

        let calculator = healthScoreCalculator
        let breakdown = calculator.calculateBreakdown(
            breakEvents: todayBreakEvents,
            totalScreenTime: totalScreenTimeToday,
            longestContinuousSession: longestContinuousSession,
            previousScores: scoreHistory
        )
        currentHealthScore = breakdown.score.totalScore
        currentTrend = breakdown.trend
        currentBreakdown = breakdown

        // Record score in history (keep last 20 entries)
        scoreHistory = Array((scoreHistory + [currentHealthScore]).suffix(20))
    }

    /// Persists current data to JSON file asynchronously.
    private func persistData() {
        let events = todayBreakEvents
        let screenTime = totalScreenTimeToday
        let longestSession = longestContinuousSession
        let history = scoreHistory

        Task {
            await persistenceManager.save(
                breakEvents: events,
                totalScreenTime: screenTime,
                longestContinuousSession: longestSession,
                scoreHistory: history
            )
        }
    }

    /// Loads persisted data for today on app start.
    private func loadPersistedData() {
        Task {
            guard let data = await persistenceManager.load() else { return }
            await MainActor.run {
                self.todayBreakEvents = data.breakEvents
                self.totalScreenTimeToday = data.totalScreenTime
                self.longestContinuousSession = data.longestContinuousSession
                self.scoreHistory = data.scoreHistory

                let taken = data.breakEvents.filter(\.wasTaken).count
                let skipped = data.breakEvents.filter { !$0.wasTaken }.count
                self.breaksTakenToday = taken
                self.breaksSkippedToday = skipped

                self.recalculateHealthScore()
                Log.scheduler.info(
                    "Restored \(data.breakEvents.count) break events from persisted data."
                )
            }
        }
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
