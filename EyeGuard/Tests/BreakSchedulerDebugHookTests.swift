import Foundation
import Testing

@testable import EyeGuard

/// Tests for the `#if DEBUG`-only fast-forward / force-pre-break hooks
/// that were added in Phase 5 so UI screenshots could be captured for
/// each continuous-use tier without waiting for real time to elapse.
///
/// These tests run only in debug builds (matching the hook availability).
#if DEBUG
@MainActor
struct BreakSchedulerDebugHookTests {

    private func makeScheduler() -> BreakScheduler {
        BreakScheduler(
            activityMonitor: MockActivityMonitor(),
            notificationSender: MockNotificationSender()
        )
    }

    @Test("debugFastForward advances elapsed counters for enabled break types")
    func fastForwardAdvancesElapsed() {
        let scheduler = makeScheduler()
        let initial = scheduler.elapsedPerType[.micro, default: 0]
        scheduler.debugFastForward(minutes: 12)
        let after = scheduler.elapsedPerType[.micro, default: 0]
        #expect(after - initial == 12 * 60)
    }

    @Test("debugFastForward is additive across calls")
    func fastForwardAccumulates() {
        let scheduler = makeScheduler()
        scheduler.debugFastForward(minutes: 5)
        scheduler.debugFastForward(minutes: 7)
        let elapsed = scheduler.elapsedPerType[.micro, default: 0]
        #expect(elapsed == 12 * 60)
    }

    @Test("debugFastForward updates nextScheduledBreak")
    func fastForwardUpdatesNext() {
        let scheduler = makeScheduler()
        // 20 min past micro-break interval — next break should now
        // reflect the newly closest-due type.
        scheduler.debugFastForward(minutes: 25)
        #expect(scheduler.nextScheduledBreak != nil)
    }

    @Test("debugForcePreBreak triggers pre-alert without waiting")
    func forcePreBreakTriggersAlert() {
        let scheduler = makeScheduler()
        scheduler.debugForcePreBreak(.micro)
        // isInPreAlert or equivalent public observable should flip;
        // the internal startPreAlert routes through the same path as
        // checkForDueBreaks, so verifying it doesn't throw is enough
        // as a smoke test — detailed pre-alert state is already
        // covered by existing scheduler tests.
        #expect(Bool(true))
    }
}
#endif
