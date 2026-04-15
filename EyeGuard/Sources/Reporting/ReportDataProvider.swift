import Foundation
import os

/// Provides current session data for report generation.
///
/// Acts as a bridge between BreakScheduler (MainActor-isolated) and
/// the DailyReportGenerator. Collects snapshot data that can be used
/// by the AppDelegate at quit time or midnight rollover.
@MainActor
final class ReportDataProvider {

    /// Shared singleton instance.
    static let shared = ReportDataProvider()

    private init() {}

    /// Snapshot of data needed for report generation.
    struct ReportData: Sendable {
        let sessions: [UsageSession]
        let breakEvents: [BreakEvent]
        let totalScreenTime: TimeInterval
        let longestContinuousSession: TimeInterval
    }

    /// Reference to the active scheduler, set during app initialization.
    private var scheduler: BreakScheduler?

    /// Registers the active BreakScheduler for data access.
    func register(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        Log.report.info("ReportDataProvider registered with BreakScheduler.")
    }

    /// Returns current data snapshot for report generation.
    func currentData() -> ReportData {
        guard let scheduler else {
            Log.report.warning("No scheduler registered. Returning empty data.")
            return ReportData(
                sessions: [],
                breakEvents: [],
                totalScreenTime: 0,
                longestContinuousSession: 0
            )
        }

        return ReportData(
            sessions: [],  // Sessions are transient; breaks carry the key data
            breakEvents: scheduler.todayBreakEvents,
            totalScreenTime: scheduler.totalScreenTimeToday,
            longestContinuousSession: scheduler.longestContinuousSession
        )
    }
}
