import Foundation
import Testing

@testable import EyeGuard

// MARK: - HealthScoreCalculator Tests

@Suite("HealthScoreCalculator - Detailed")
struct HealthScoreCalculatorDetailedTests {

    let calculator = HealthScoreCalculator()

    // MARK: - Full Score Scenarios

    @Test("No breaks and low screen time yields high score")
    func noBreaksLowScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 30 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.breakCompliance == 40)
        #expect(score.continuousUseDiscipline == 30)
        #expect(score.screenTimeScore == 20)
        #expect(score.breakQuality == 10)
        #expect(score.totalScore == 100)
    }

    // MARK: - Break Compliance

    @Test("All breaks skipped yields zero compliance")
    func allBreaksSkipped() {
        let events = [
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 60 * 60,
            longestContinuousSession: 60 * 60
        )
        #expect(score.breakCompliance == 0)
    }

    @Test("Half breaks taken yields proportional compliance")
    func halfBreaksTaken() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 40 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.breakCompliance == 20)
    }

    @Test("All breaks taken yields full compliance")
    func allBreaksTaken() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 60 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.breakCompliance == 40)
    }

    // MARK: - Continuous Use Discipline

    @Test("Long continuous session penalizes discipline")
    func longContinuousSession() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 3 * 60 * 60,
            longestContinuousSession: 3 * 60 * 60
        )
        #expect(score.continuousUseDiscipline == 0)
    }

    @Test("Session at micro break interval yields full discipline")
    func shortContinuousSession() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 20 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.continuousUseDiscipline == 30)
    }

    @Test("Session between micro and mandatory intervals yields partial discipline")
    func mediumContinuousSession() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 60 * 60,
            longestContinuousSession: 60 * 60
        )
        #expect(score.continuousUseDiscipline > 0)
        #expect(score.continuousUseDiscipline < 30)
    }

    // MARK: - Screen Time Score (BUG-004 boundary fixes)

    @Test("Zero screen time yields full score")
    func zeroScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )
        #expect(score.screenTimeScore == 20)
    }

    @Test("Screen time under 50% recommended yields full score")
    func lowScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 3 * 60 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.screenTimeScore == 20)
    }

    @Test("Screen time at exactly 50% recommended yields full score")
    func halfRecommendedScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 4 * 60 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.screenTimeScore == 20)
    }

    @Test("Screen time at exactly recommended max yields non-zero score")
    func maxRecommendedScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 8 * 60 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.screenTimeScore == 10)
    }

    @Test("Screen time at 2x recommended yields zero score")
    func doubleRecommendedScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 16 * 60 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.screenTimeScore == 0)
    }

    @Test("Screen time between recommended and 2x yields partial score")
    func overRecommendedScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 10 * 60 * 60,
            longestContinuousSession: 15 * 60
        )
        #expect(score.screenTimeScore > 0)
        #expect(score.screenTimeScore < 10)
    }

    @Test("Screen time score is monotonically decreasing")
    func screenTimeMonotonicallyDecreasing() {
        var lastScore = 21
        let intervals: [TimeInterval] = [0, 2, 4, 6, 8, 10, 12, 14, 16].map { $0 * 60 * 60 }

        for screenTime in intervals {
            let score = calculator.calculate(
                breakEvents: [],
                totalScreenTime: screenTime,
                longestContinuousSession: 15 * 60
            )
            #expect(score.screenTimeScore <= lastScore,
                    "Score should decrease: at \(screenTime/3600)h got \(score.screenTimeScore) vs previous \(lastScore)")
            lastScore = score.screenTimeScore
        }
    }

    // MARK: - Break Quality

    @Test("Full duration breaks yield full quality score")
    func fullDurationBreaks() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 60 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.breakQuality == 10)
    }

    @Test("Half duration breaks yield proportional quality score")
    func halfDurationBreaks() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 10),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 150),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 60 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.breakQuality == 5)
    }

    @Test("Skipped breaks are excluded from quality calculation")
    func skippedBreaksExcludedFromQuality() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 60 * 60,
            longestContinuousSession: 20 * 60
        )
        #expect(score.breakQuality == 10)
    }

    // MARK: - Mixed Scenarios

    @Test("Mixed scenario with partial compliance and moderate screen time")
    func mixedScenario() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
            BreakEvent(type: .mandatory, wasTaken: false, actualDuration: 0),
        ]
        let score = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 6 * 60 * 60,
            longestContinuousSession: 90 * 60
        )

        #expect(score.breakCompliance == 20)
        #expect(score.continuousUseDiscipline > 0)
        #expect(score.screenTimeScore > 0)
        #expect(score.screenTimeScore < 20)
        #expect(score.breakQuality == 10)
        #expect(score.totalScore > 30)
        #expect(score.totalScore < 80)
    }
}
