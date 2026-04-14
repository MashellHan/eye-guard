import Foundation
import Testing

@testable import EyeGuard

// MARK: - DailyReportGenerator Tests

@Suite("DailyReportGenerator")
struct DailyReportGeneratorDetailedTests {

    let generator = DailyReportGenerator()

    @Test("Generate report with no sessions produces valid report")
    func emptyReport() async {
        let report = await generator.generate(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )

        #expect(report.totalBreaksTaken == 0)
        #expect(report.totalBreaksScheduled == 0)
        #expect(report.totalScreenTime == 0)
        #expect(report.sessions.isEmpty)
        #expect(report.healthScore.totalScore == 100)
    }

    @Test("Generate report with sessions produces correct counts")
    func reportWithSessions() async {
        let session = UsageSession(activeTime: 3600)
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
        ]

        let report = await generator.generate(
            sessions: [session],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 1200
        )

        #expect(report.totalBreaksTaken == 2)
        #expect(report.totalBreaksScheduled == 3)
        #expect(report.sessions.count == 1)
    }

    @Test("Report date string uses correct format")
    func dateStringFormat() async {
        let fixedDate = Date(timeIntervalSince1970: 0)
        let report = await generator.generate(
            date: fixedDate,
            sessions: [],
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )

        let components = report.dateString.split(separator: "-")
        #expect(components.count == 3)
        #expect(components[0].count == 4) // year
        #expect(components[1].count == 2) // month
        #expect(components[2].count == 2) // day
    }

    @Test("Report health score reflects break events")
    func reportHealthScore() async {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
        ]

        let report = await generator.generate(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 1200
        )

        #expect(report.healthScore.breakCompliance == 0)
    }

    @Test("Report with high screen time has lower screen time score")
    func highScreenTimeReport() async {
        let report = await generator.generate(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 12 * 60 * 60,
            longestContinuousSession: 20 * 60
        )

        #expect(report.healthScore.screenTimeScore < 20)
    }
}
