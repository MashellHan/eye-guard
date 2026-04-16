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

    /// Number of eye exercise sessions completed today (v2.5).
    private(set) var exerciseSessionsToday: Int = 0

    /// Whether a pre-break alert countdown is active (v3.2).
    private(set) var isPreAlertActive: Bool = false

    /// The break type for the current pre-alert, if any.
    private(set) var preAlertBreakType: BreakType?

    /// Remaining seconds in the pre-alert countdown.
    private(set) var preAlertRemainingSeconds: Int = 0

    /// Task managing the pre-alert countdown.
    private var preAlertTask: Task<Void, Never>?

    /// Recommended exercise sessions based on screen time (v2.5).
    /// - Screen time < 2h → 1 session
    /// - Screen time 2–4h → 2 sessions
    /// - Screen time > 4h → 3 sessions
    var recommendedExerciseSessions: Int {
        let hours = totalScreenTimeToday / 3600
        if hours < 2 { return 1 }
        if hours < 4 { return 2 }
        return 3
    }

    // MARK: - Internal State

    private var sessionStartTime: Date = .now
    private var timerTask: Task<Void, Never>?
    private let preferences: UserPreferences

    /// Tracks whether the user was idle on the previous tick (H1).
    /// Also set immediately on screen lock/unlock to avoid 5-second poll gap (BUG-008).
    private var wasIdle: Bool = false

    /// Whether the screen is currently locked. Updated directly via
    /// DistributedNotificationCenter for immediate response (BUG-007/BUG-008).
    /// Used to gate elapsed accumulation — more reliable than idle polling
    /// since it doesn't depend on CGEventTap accessibility permissions.
    private var isScreenLocked: Bool = false

    /// Per-break-type elapsed time for independent tracking (H5/BUG-001).
    /// Treat as read-only externally; mutated only by `@testable import` tests.
    var elapsedPerType: [BreakType: TimeInterval] = [
        .micro: 0,
        .macro: 0,
        .mandatory: 0,
    ]

    /// Tracks the last notified cycle per break type to prevent double-fire (BUG-003).
    /// Internal access for `@testable import` verification.
    var lastNotifiedCycle: [BreakType: Int] = [
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
        preferences: UserPreferences = UserPreferencesManager.load()
    ) {
        self.activityMonitor = activityMonitor
        self.notificationSender = notificationSender
        self.soundPlayer = soundPlayer
        self.preferences = preferences
        startTimerLoop()
        loadPersistedData()
        registerScreenLockObserver()
    }

    // MARK: - Screen Lock Observer (BUG-007/BUG-008)

    private var screenLockObserverToken: NSObjectProtocol?
    private var screenUnlockObserverToken: NSObjectProtocol?

    /// Register for screen lock/unlock notifications directly in BreakScheduler
    /// so `isScreenLocked` updates immediately without depending on idle polling.
    private func registerScreenLockObserver() {
        let dnc = DistributedNotificationCenter.default()

        screenLockObserverToken = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isScreenLocked = true
                if !self.wasIdle {
                    self.wasIdle = true
                    self.handleIdleDetected()
                }
                Log.scheduler.notice("Screen locked — elapsed accumulation paused (BUG-008).")
            }
        }

        screenUnlockObserverToken = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isScreenLocked = false
                if self.wasIdle {
                    self.wasIdle = false
                    self.handleActivityResumed()
                }
                Log.scheduler.notice("Screen unlocked — elapsed accumulation resumed (BUG-008).")
            }
        }
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
        exerciseSessionsToday = 0
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

        // Recalculate score immediately so menu bar updates right away
        recalculateHealthScore()
    }

    /// Records that the user skipped a scheduled break.
    func skipBreak(_ type: BreakType) {
        recordBreak(type: type, wasTaken: false)
        resetTimersAfterBreak(type)
    }

    /// Records an exercise session completion (v2.5).
    /// Called from MascotWindowController when an exercise session finishes.
    func recordExerciseSession() {
        exerciseSessionsToday += 1
        Log.scheduler.info(
            "Exercise session recorded: \(self.exerciseSessionsToday)/\(self.recommendedExerciseSessions) today."
        )
    }

    /// Called when idle is detected — resets timers since user is resting (H1).
    /// Skips reset when a break notification is active to avoid dismissing the overlay (BUG-POPUP-001).
    func handleIdleDetected() {
        guard !isPaused else { return }
        guard !isBreakInProgress else {
            Log.scheduler.info("Idle detected during active break — skipping timer reset.")
            return
        }
        guard !notificationSender.isNotificationActive else {
            Log.scheduler.info("Idle detected during active notification — skipping timer reset.")
            return
        }
        cancelPreAlert()
        // User is resting — reset all break timers (BUG-007: was only micro)
        for type in BreakType.allCases {
            resetTimersAfterBreak(type)
        }
        Log.scheduler.info("Idle detected, all break timers reset.")
    }

    /// Called when user returns from idle (H1).
    /// Skips reset when a break notification is active (BUG-POPUP-001).
    func handleActivityResumed() {
        guard !isPaused else { return }
        guard !isBreakInProgress else {
            Log.scheduler.info("Activity resumed during active break — skipping session reset.")
            return
        }
        guard !notificationSender.isNotificationActive else {
            Log.scheduler.info("Activity resumed during active notification — skipping session reset.")
            return
        }
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
        // Don't accumulate during active notifications/breaks (BUG-POPUP-001 v4)
        // Don't accumulate while screen locked — user is away (BUG-007/BUG-008)
        // Note: idle detection (wasIdle) still resets timers via handleIdleDetected(),
        // but does NOT block elapsed accumulation — only screen lock does, because
        // idle detection requires CGEventTap accessibility permission which may not
        // be granted, and blocking elapsed on idle would freeze the countdown.
        if !isBreakInProgress && !notificationSender.isNotificationActive && !isScreenLocked {
            for type in BreakType.allCases {
                guard isBreakTypeEnabled(type) else { continue }
                elapsedPerType[type, default: 0] += max(delta, 0)
            }
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
        // Skip polling during active breaks to avoid idle/resume race (BUG-POPUP-001)
        // Note: idle polling only updates wasIdle for informational purposes.
        // Timer resets are now driven by screen lock/unlock notifications (BUG-008),
        // NOT by idle detection, because idle detection depends on CGEventTap which
        // requires accessibility permission and may not be available.
        if ticksSinceLastScoreUpdate % 5 == 0, !isBreakInProgress, !notificationSender.isNotificationActive {
            Task {
                let idle = await activityMonitor.isIdle
                let locked = await activityMonitor.isScreenLocked
                if locked && !wasIdle {
                    // Screen lock detected via polling (backup for notification observer)
                    handleIdleDetected()
                    wasIdle = true
                } else if !locked && wasIdle {
                    handleActivityResumed()
                    wasIdle = false
                }
                // Update wasIdle for display purposes, but don't reset timers on mere idle
                // (idle without screen lock just means CGEventTap didn't detect input)
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
    /// Internal access for `@testable import` verification.
    func checkForDueBreaks() {
        guard !isBreakInProgress else { return }
        guard !notificationSender.isNotificationActive else { return }

        var dueBreaks: [(BreakType, Int)] = []

        for type in BreakType.allCases {
            guard isBreakTypeEnabled(type) else { continue }

            let elapsed = elapsedPerType[type, default: 0]
            let interval = intervalForType(type)

            guard interval > 0 else { continue }

            // Pre-alert detection: trigger countdown before break is due
            let preAlertDuration = self.preAlertDuration(for: type)
            let preAlertThreshold = interval - preAlertDuration
            if elapsed >= preAlertThreshold && elapsed < interval && !isPreAlertActive && !isBreakInProgress {
                startPreAlert(for: type)
            }

            let currentCycle = Int(elapsed / interval)

            // Collect all breaks that crossed into a new cycle
            if currentCycle > 0 && currentCycle != lastNotifiedCycle[type] {
                dueBreaks.append((type, currentCycle))
            }
        }

        guard !dueBreaks.isEmpty else { return }

        // Cancel pre-alert since we're firing the actual break
        cancelPreAlert()

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
            Log.scheduler.info(
                "Break \(type.displayName) absorbed by \(winner.0.displayName)."
            )
        }
    }

    // MARK: - Pre-Alert (v3.2)

    /// Returns the pre-alert countdown duration for a break type.
    private func preAlertDuration(for type: BreakType) -> TimeInterval {
        switch type {
        case .micro:     return EyeGuardConstants.microPreAlertDuration
        case .macro:     return EyeGuardConstants.macroPreAlertDuration
        case .mandatory: return EyeGuardConstants.mandatoryPreAlertDuration
        }
    }

    /// Starts the pre-alert countdown for the given break type.
    private func startPreAlert(for type: BreakType) {
        isPreAlertActive = true
        preAlertBreakType = type
        let duration = Int(preAlertDuration(for: type))
        preAlertRemainingSeconds = duration

        NotificationCenter.default.post(
            name: .preAlertStarted,
            object: nil,
            userInfo: ["breakType": type, "seconds": duration]
        )

        Log.scheduler.info("Pre-alert started for \(type.displayName): \(duration)s countdown.")

        preAlertTask = Task { [weak self] in
            for i in stride(from: duration - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.preAlertRemainingSeconds = i
                    NotificationCenter.default.post(
                        name: .preAlertCountdown,
                        object: nil,
                        userInfo: ["breakType": type, "remaining": i]
                    )
                }
            }
            await MainActor.run {
                self?.isPreAlertActive = false
                self?.preAlertBreakType = nil
            }
        }
    }

    /// Cancels any active pre-alert countdown.
    func cancelPreAlert() {
        guard isPreAlertActive else { return }
        preAlertTask?.cancel()
        preAlertTask = nil
        isPreAlertActive = false
        preAlertBreakType = nil
        preAlertRemainingSeconds = 0
        NotificationCenter.default.post(name: .preAlertCancelled, object: nil)
        Log.scheduler.info("Pre-alert cancelled.")
    }

    /// Sends a break notification using mode-aware behavior (v2.4).
    /// Internal access for "Take Break Now" from mascot menu.
    func triggerBreakNotification(_ breakType: BreakType) {
        Log.scheduler.info("Break due: \(breakType.displayName)")

        let profile = preferences.activeProfile
        let behavior = profile.behavior(for: breakType)

        // Only offer exercises during macro/mandatory breaks
        let exerciseCallback: (@Sendable () -> Void)? =
            (breakType == .macro || breakType == .mandatory)
                ? { @Sendable [weak self] in
                    Task { @MainActor in
                        self?.takeBreakNow(breakType)
                        NotificationCenter.default.post(
                            name: .startExercisesFromBreak,
                            object: nil
                        )
                    }
                }
                : nil

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
            },
            exerciseSessionsToday: exerciseSessionsToday,
            recommendedExerciseSessions: recommendedExerciseSessions,
            onStartExercises: exerciseCallback
        )
    }

    /// Postpones a break by the given delay (v2.4).
    /// Sets elapsed time back so the break re-fires after `delay` seconds.
    func postponeBreak(_ type: BreakType, by delay: TimeInterval) {
        cancelPreAlert()
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
    /// Logs a warning for tracking purposes; the actual break notification is handled
    /// by `checkForDueBreaks()` via `elapsedPerType` to avoid duplicate alerts.
    /// Internal access for `@testable import` verification.
    func checkContinuousUse() {
        let threshold = preferences.mandatoryBreakInterval
        guard currentSessionDuration >= threshold else { return }

        // Only warn once per session crossing the threshold
        let warningCycle = Int(currentSessionDuration / threshold)
        if warningCycle > continuousUseWarnings {
            continuousUseWarnings = warningCycle
            Log.scheduler.warning(
                "Continuous use reached \(Int(self.currentSessionDuration / 60)) minutes — Tier 3 handled by checkForDueBreaks."
            )
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
            previousScores: scoreHistory,
            exerciseSessionsToday: exerciseSessionsToday
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
        let exercises = exerciseSessionsToday

        Task {
            await persistenceManager.save(
                breakEvents: events,
                totalScreenTime: screenTime,
                longestContinuousSession: longestSession,
                scoreHistory: history,
                exerciseSessionsToday: exercises
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
                self.exerciseSessionsToday = data.exerciseSessionsToday

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
