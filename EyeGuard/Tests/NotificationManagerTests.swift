import Foundation
import Testing

@testable import EyeGuard

// MARK: - NotificationManager Tests

@Suite("NotificationManager")
struct NotificationManagerMockTests {

    @Test("Mock notification sender tracks notify calls")
    @MainActor
    func mockNotifySenderTracking() {
        let mock = MockNotificationSender()
        #expect(mock.notifyCalls.isEmpty)

        mock.notify(breakType: .micro, onTaken: {}, onSkipped: {})
        #expect(mock.notifyCalls.count == 1)
        #expect(mock.lastNotifiedBreakType == .micro)
    }

    @Test("Mock notification sender tracks acknowledge calls")
    @MainActor
    func mockAcknowledgeTracking() {
        let mock = MockNotificationSender()
        mock.acknowledgeBreak()
        #expect(mock.acknowledgeCalls == 1)
    }

    @Test("Mock notification sender tracks snooze calls")
    @MainActor
    func mockSnoozeTracking() {
        let mock = MockNotificationSender()
        mock.snooze(breakType: .macro, onDue: {})
        #expect(mock.snoozeCalls.count == 1)
    }

    @Test("Mock notification sender setup is tracked")
    @MainActor
    func mockSetupTracking() {
        let mock = MockNotificationSender()
        #expect(mock.setupCalled == false)
        mock.setup()
        #expect(mock.setupCalled == true)
    }

    @Test("Multiple notifications tracked in order")
    @MainActor
    func multipleNotifications() {
        let mock = MockNotificationSender()

        mock.notify(breakType: .micro, onTaken: {}, onSkipped: {})
        mock.notify(breakType: .macro, onTaken: {}, onSkipped: {})
        mock.notify(breakType: .mandatory, onTaken: {}, onSkipped: {})

        #expect(mock.notifyCalls.count == 3)
        #expect(mock.notifyCalls[0].0 == .micro)
        #expect(mock.notifyCalls[1].0 == .macro)
        #expect(mock.notifyCalls[2].0 == .mandatory)
    }
}

// MARK: - TimeFormatting Tests

@Suite("TimeFormatting")
struct TimeFormattingTests {

    @Test("Format zero seconds")
    func zeroSeconds() {
        #expect(TimeFormatting.formatDuration(0) == "0s")
    }

    @Test("Format seconds only")
    func secondsOnly() {
        #expect(TimeFormatting.formatDuration(30) == "30s")
    }

    @Test("Format minutes only")
    func minutesOnly() {
        #expect(TimeFormatting.formatDuration(5 * 60) == "5m")
    }

    @Test("Format hours and minutes")
    func hoursAndMinutes() {
        #expect(TimeFormatting.formatDuration(2 * 3600 + 15 * 60) == "2h 15m")
    }

    @Test("Timer display format with hours")
    func timerDisplayWithHours() {
        #expect(TimeFormatting.formatTimerDisplay(3661) == "1:01:01")
    }

    @Test("Timer display format without hours")
    func timerDisplayWithoutHours() {
        #expect(TimeFormatting.formatTimerDisplay(90) == "01:30")
    }

    @Test("Timer display format zero")
    func timerDisplayZero() {
        #expect(TimeFormatting.formatTimerDisplay(0) == "00:00")
    }
}

// MARK: - ActivityMonitor Tests

@Suite("ActivityMonitor")
struct ActivityMonitorMockTests {

    @Test("Mock activity monitor starts in non-idle state")
    func initialState() async {
        let monitor = MockActivityMonitor()
        let idle = await monitor.isIdle
        #expect(idle == false)
    }

    @Test("Mock activity monitor can be set to idle")
    func setIdle() async {
        let monitor = MockActivityMonitor()
        await monitor.setIdle(true)
        let idle = await monitor.isIdle
        #expect(idle == true)
    }

    @Test("Mock activity monitor reset clears idle state")
    func resetState() async {
        let monitor = MockActivityMonitor()
        await monitor.setIdle(true)
        await monitor.resetState()
        let idle = await monitor.isIdle
        #expect(idle == false)

        let wasReset = await monitor.resetStateCalled
        #expect(wasReset == true)
    }

    @Test("Mock activity monitor tracks startMonitoring call")
    func startMonitoringTracked() async {
        let monitor = MockActivityMonitor()
        await monitor.startMonitoring()
        let called = await monitor.startMonitoringCalled
        #expect(called == true)
    }

    @Test("Mock activity monitor tracks stopMonitoring call")
    func stopMonitoringTracked() async {
        let monitor = MockActivityMonitor()
        await monitor.stopMonitoring()
        let called = await monitor.stopMonitoringCalled
        #expect(called == true)
    }
}
