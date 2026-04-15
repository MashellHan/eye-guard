import Foundation
import Testing

@testable import EyeGuard

// MARK: - HistoryManager Tests

@Suite("HistoryManager")
struct HistoryManagerTests {

    @Test("Average health score of empty array is zero")
    func averageScoreEmpty() {
        let manager = HistoryManager()
        let result = manager.averageHealthScore([])
        #expect(result == 0)
    }

    @Test("Average health score computes correctly")
    func averageScoreComputation() {
        let manager = HistoryManager()
        let summaries = [
            makeSummary(score: 80),
            makeSummary(score: 60),
            makeSummary(score: 100),
        ]
        let avg = manager.averageHealthScore(summaries)
        #expect(avg == 80)
    }

    @Test("Total screen time sums across days")
    func totalScreenTime() {
        let manager = HistoryManager()
        let summaries = [
            makeSummary(screenTime: 3600),
            makeSummary(screenTime: 7200),
        ]
        let total = manager.totalScreenTime(summaries)
        #expect(total == 10800)
    }

    @Test("Total breaks taken sums across days")
    func totalBreaksTaken() {
        let manager = HistoryManager()
        let summaries = [
            makeSummary(breaksTaken: 5),
            makeSummary(breaksTaken: 3),
        ]
        let total = manager.totalBreaksTaken(summaries)
        #expect(total == 8)
    }

    @Test("Daily summary screen time hours conversion")
    func screenTimeHoursConversion() {
        let summary = makeSummary(screenTime: 7200) // 2 hours
        #expect(summary.screenTimeHours == 2.0)
    }

    @Test("Break compliance with no breaks is 100%")
    func breakComplianceEmpty() {
        let summary = makeSummary(breaksTaken: 0, breaksSkipped: 0, totalBreaks: 0)
        #expect(summary.breakCompliancePercent == 100)
    }

    @Test("Break compliance calculation")
    func breakComplianceCalc() {
        let summary = makeSummary(breaksTaken: 8, breaksSkipped: 2, totalBreaks: 10)
        #expect(summary.breakCompliancePercent == 80)
    }

    // MARK: - Helpers

    private func makeSummary(
        score: Int = 75,
        screenTime: TimeInterval = 3600,
        breaksTaken: Int = 5,
        breaksSkipped: Int = 1,
        totalBreaks: Int = 6
    ) -> HistoryManager.DailySummary {
        HistoryManager.DailySummary(
            id: "2026-04-14",
            date: .now,
            healthScore: score,
            totalScreenTime: screenTime,
            longestContinuousSession: 1800,
            breaksTaken: breaksTaken,
            breaksSkipped: breaksSkipped,
            totalBreaks: totalBreaks
        )
    }
}
