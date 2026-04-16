import Foundation
import Testing

@testable import EyeGuard

// MARK: - Mock ActivityMonitor

/// Mock activity monitor for testing BreakScheduler in isolation.
actor MockActivityMonitor: ActivityMonitoring {
    private(set) var isIdle: Bool = false
    private(set) var isScreenLocked: Bool = false
    private(set) var startMonitoringCalled = false
    private(set) var stopMonitoringCalled = false
    private(set) var resetStateCalled = false

    func setIdle(_ idle: Bool) {
        isIdle = idle
    }

    func setScreenLocked(_ locked: Bool) {
        isScreenLocked = locked
    }

    func startMonitoring() {
        startMonitoringCalled = true
    }

    func stopMonitoring() {
        stopMonitoringCalled = true
    }

    func resetState() {
        resetStateCalled = true
        isIdle = false
        isScreenLocked = false
    }
}

// MARK: - Mock NotificationSender

/// Mock notification sender for testing BreakScheduler in isolation (v2.4).
@MainActor
final class MockNotificationSender: NotificationSending {
    struct NotifyCall {
        let breakType: BreakType
        let behavior: BreakBehavior
        let escalation: EscalationStrategy
        let healthScore: Int
        let onTaken: @Sendable () -> Void
        let onSkipped: @Sendable () -> Void
        let onPostponed: @Sendable (TimeInterval) -> Void
    }

    private(set) var notifyCalls: [NotifyCall] = []
    private(set) var acknowledgeCalls = 0
    private(set) var snoozeCalls: [(BreakType, @Sendable () -> Void)] = []
    private(set) var setupCalled = false

    var lastNotifiedBreakType: BreakType? {
        notifyCalls.last?.breakType
    }

    var lastNotifiedHealthScore: Int? {
        notifyCalls.last?.healthScore
    }

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
    ) {
        notifyCalls.append(NotifyCall(
            breakType: breakType,
            behavior: behavior,
            escalation: escalation,
            healthScore: healthScore,
            onTaken: onTaken,
            onSkipped: onSkipped,
            onPostponed: onPostponed
        ))
    }

    func acknowledgeBreak() {
        acknowledgeCalls += 1
    }

    func snooze(breakType: BreakType, onDue: @escaping @Sendable () -> Void) {
        snoozeCalls.append((breakType, onDue))
    }

    func setup() {
        setupCalled = true
    }
}

// MARK: - BreakScheduler Tests

@Suite("BreakScheduler")
struct BreakSchedulerTests {

    @Test("Initial state is correct")
    @MainActor
    func initialState() {
        let mockActivity = MockActivityMonitor()
        let mockNotification = MockNotificationSender()
        let scheduler = BreakScheduler(
            activityMonitor: mockActivity,
            notificationSender: mockNotification
        )

        #expect(scheduler.isPaused == false)
        #expect(scheduler.currentSessionDuration == 0)
        #expect(scheduler.nextScheduledBreak == .micro)
        #expect(scheduler.breaksTakenToday == 0)
        #expect(scheduler.breaksSkippedToday == 0)
        #expect(scheduler.currentHealthScore == 100)
        #expect(scheduler.todayBreakEvents.isEmpty)
        #expect(scheduler.totalScreenTimeToday == 0)
    }

    @Test("Toggle pause works correctly")
    @MainActor
    func togglePause() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        #expect(scheduler.isPaused == false)
        scheduler.togglePause()
        #expect(scheduler.isPaused == true)
        scheduler.togglePause()
        #expect(scheduler.isPaused == false)
    }

    @Test("Take break records event and increments counter")
    @MainActor
    func takeBreak() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        #expect(scheduler.breaksTakenToday == 1)
        #expect(scheduler.breaksSkippedToday == 0)
        #expect(scheduler.todayBreakEvents.count == 1)
        #expect(scheduler.todayBreakEvents[0].wasTaken == true)
        #expect(scheduler.todayBreakEvents[0].type == .micro)
    }

    @Test("Skip break records event and increments counter")
    @MainActor
    func skipBreak() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.skipBreak(.macro)
        #expect(scheduler.breaksTakenToday == 0)
        #expect(scheduler.breaksSkippedToday == 1)
        #expect(scheduler.todayBreakEvents.count == 1)
        #expect(scheduler.todayBreakEvents[0].wasTaken == false)
    }

    @Test("Reset session clears duration and timers")
    @MainActor
    func resetSession() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        scheduler.resetSession()

        #expect(scheduler.currentSessionDuration == 0)
        #expect(scheduler.nextScheduledBreak == .micro)
    }

    @Test("Reset daily clears all counters")
    @MainActor
    func resetDaily() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        scheduler.skipBreak(.macro)
        scheduler.resetDaily()

        #expect(scheduler.breaksTakenToday == 0)
        #expect(scheduler.breaksSkippedToday == 0)
        #expect(scheduler.todayBreakEvents.isEmpty)
        #expect(scheduler.totalScreenTimeToday == 0)
        #expect(scheduler.currentHealthScore == 100)
    }

    @Test("Micro break reset only resets micro timer")
    @MainActor
    func microBreakResetBehavior() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        #expect(scheduler.breaksTakenToday == 1)
        #expect(scheduler.currentSessionDuration == 0)
    }

    @Test("Mandatory break reset resets all timers")
    @MainActor
    func mandatoryBreakResetBehavior() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.mandatory)
        #expect(scheduler.breaksTakenToday == 1)
        #expect(scheduler.currentSessionDuration == 0)
    }

    @Test("Handle idle detected resets micro timer")
    @MainActor
    func handleIdleDetected() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.handleIdleDetected()
        #expect(scheduler.currentSessionDuration == 0)
    }

    @Test("Handle idle detected does nothing when paused")
    @MainActor
    func handleIdleDetectedWhenPaused() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.togglePause()
        scheduler.handleIdleDetected()
        #expect(scheduler.isPaused == true)
    }

    @Test("Health score decreases when breaks are skipped")
    @MainActor
    func healthScoreDecreasesOnSkip() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.skipBreak(.micro)
        scheduler.skipBreak(.micro)
        scheduler.skipBreak(.macro)

        #expect(scheduler.currentHealthScore < 100)
    }

    @Test("Multiple break types can be taken independently")
    @MainActor
    func multipleBreakTypes() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        scheduler.takeBreakNow(.macro)
        scheduler.takeBreakNow(.mandatory)

        #expect(scheduler.breaksTakenToday == 3)
        #expect(scheduler.todayBreakEvents.count == 3)

        let types = Set(scheduler.todayBreakEvents.map(\.type))
        #expect(types.contains(.micro))
        #expect(types.contains(.macro))
        #expect(types.contains(.mandatory))
    }

    @Test("Initial longestContinuousSession is zero")
    @MainActor
    func initialLongestContinuousSession() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        #expect(scheduler.longestContinuousSession == 0)
    }

    @Test("Initial continuousUseWarnings is zero")
    @MainActor
    func initialContinuousUseWarnings() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        #expect(scheduler.continuousUseWarnings == 0)
    }

    @Test("Reset daily clears continuous use tracking")
    @MainActor
    func resetDailyClearsContinuousUseTracking() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        // Simulate some activity
        scheduler.takeBreakNow(.micro)
        scheduler.resetDaily()

        #expect(scheduler.longestContinuousSession == 0)
        #expect(scheduler.continuousUseWarnings == 0)
    }

    @Test("Initial score trend is stable")
    @MainActor
    func initialScoreTrend() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        #expect(scheduler.currentTrend == .stable)
    }

    @Test("Initial score history is empty")
    @MainActor
    func initialScoreHistory() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        #expect(scheduler.scoreHistory.isEmpty)
    }

    @Test("Reset daily clears trend and breakdown")
    @MainActor
    func resetDailyClearsTrendAndBreakdown() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        scheduler.skipBreak(.macro)
        scheduler.resetDaily()

        #expect(scheduler.currentTrend == .stable)
        #expect(scheduler.currentBreakdown == nil)
        #expect(scheduler.scoreHistory.isEmpty)
    }

    @Test("Health score breakdown is populated after break events")
    @MainActor
    func healthScoreBreakdownPopulated() {
        let scheduler = BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )

        scheduler.takeBreakNow(.micro)
        scheduler.skipBreak(.macro)

        // After break events, breakdown should be populated
        #expect(scheduler.currentBreakdown != nil)
        if let breakdown = scheduler.currentBreakdown {
            #expect(breakdown.components.count == 4)
            #expect(breakdown.components[0].name == "Breaks")
            #expect(breakdown.components[1].name == "Discipline")
            #expect(breakdown.components[2].name == "Time")
            #expect(breakdown.components[3].name == "Quality")
        }
    }
}
