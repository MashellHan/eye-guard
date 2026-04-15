import Foundation

/// Protocol for providing session data for report generation.
///
/// Abstracts the report data source for testability via dependency injection.
/// Production: `ReportDataProvider` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol ReportDataProviding {
    /// Registers the active BreakScheduler for data access.
    func register(scheduler: BreakScheduler)

    /// Returns current data snapshot for report generation.
    func currentData() -> ReportDataProvider.ReportData
}
