import Foundation
import os

/// Manages loading and aggregating historical data from daily JSON files.
///
/// Reads `~/EyeGuard/data/*.json` files produced by `DataPersistenceManager`,
/// aggregates daily stats for charting, and provides data for the last 30 days.
///
/// Each JSON file follows the `DailyData` format:
/// ```json
/// {
///   "date": "2026-04-14",
///   "breakEvents": [...],
///   "totalScreenTime": 28800,
///   "longestContinuousSession": 3600,
///   "scoreHistory": [85, 82, ...]
/// }
/// ```
struct HistoryManager: Sendable {

    // MARK: - Daily Summary

    /// Aggregated daily summary for charting.
    struct DailySummary: Identifiable, Sendable {
        let id: String  // date string YYYY-MM-DD
        let date: Date
        let healthScore: Int
        let totalScreenTime: TimeInterval
        let longestContinuousSession: TimeInterval
        let breaksTaken: Int
        let breaksSkipped: Int
        let totalBreaks: Int

        /// Screen time in hours for charting.
        var screenTimeHours: Double {
            totalScreenTime / 3600.0
        }

        /// Break compliance as a percentage (0-100).
        var breakCompliancePercent: Int {
            guard totalBreaks > 0 else { return 100 }
            return Int(Double(breaksTaken) / Double(totalBreaks) * 100)
        }
    }

    // MARK: - Public API

    /// Loads daily summaries for the specified number of past days.
    ///
    /// - Parameter days: Number of past days to load (default 30).
    /// - Returns: Array of `DailySummary` sorted by date ascending.
    func loadHistory(days: Int = 30) async -> [DailySummary] {
        let calendar = Calendar.current
        let today = Date.now
        var summaries: [DailySummary] = []

        let persistence = DataPersistenceManager()

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }

            if let data = await persistence.load(for: date) {
                let summary = aggregateSummary(from: data, date: date)
                summaries.append(summary)
            }
        }

        Log.dashboard.info("Loaded \(summaries.count) days of history (requested \(days)).")
        return summaries
    }

    /// Loads today's summary from the current scheduler data or persisted file.
    ///
    /// - Returns: Today's `DailySummary` or nil if no data is available.
    func loadToday() async -> DailySummary? {
        let persistence = DataPersistenceManager()
        guard let data = await persistence.load(for: .now) else { return nil }
        return aggregateSummary(from: data, date: .now)
    }

    /// Returns the average health score across the given summaries.
    func averageHealthScore(_ summaries: [DailySummary]) -> Int {
        guard !summaries.isEmpty else { return 0 }
        let total = summaries.reduce(0) { $0 + $1.healthScore }
        return total / summaries.count
    }

    /// Returns the total screen time across the given summaries.
    func totalScreenTime(_ summaries: [DailySummary]) -> TimeInterval {
        summaries.reduce(0) { $0 + $1.totalScreenTime }
    }

    /// Returns the total breaks taken across the given summaries.
    func totalBreaksTaken(_ summaries: [DailySummary]) -> Int {
        summaries.reduce(0) { $0 + $1.breaksTaken }
    }

    // MARK: - Private

    /// Aggregates a `DailyData` into a `DailySummary`.
    private func aggregateSummary(from data: DailyData, date: Date) -> DailySummary {
        let breaksTaken = data.breakEvents.filter(\.wasTaken).count
        let breaksSkipped = data.breakEvents.filter { !$0.wasTaken }.count
        let totalBreaks = data.breakEvents.count

        // Calculate health score from the last value in scoreHistory,
        // or compute from break events if no history
        let healthScore: Int
        if let lastScore = data.scoreHistory.last {
            healthScore = lastScore
        } else {
            let calculator = HealthScoreCalculator()
            let computed = calculator.calculate(
                breakEvents: data.breakEvents,
                totalScreenTime: data.totalScreenTime,
                longestContinuousSession: data.longestContinuousSession
            )
            healthScore = computed.totalScore
        }

        return DailySummary(
            id: data.date,
            date: date,
            healthScore: healthScore,
            totalScreenTime: data.totalScreenTime,
            longestContinuousSession: data.longestContinuousSession,
            breaksTaken: breaksTaken,
            breaksSkipped: breaksSkipped,
            totalBreaks: totalBreaks
        )
    }
}
