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
        #expect(report.healthScore.totalScore == 96) // Base quality 6/10 without exercises
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
        #expect(components[0].count == 4)  // year
        #expect(components[1].count == 2)  // month
        #expect(components[2].count == 2)  // day
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

    // MARK: - v0.7 Markdown Content Tests

    @Test("Markdown contains Daily Summary section")
    func markdownHasDailySummary() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Daily Summary"))
        #expect(markdown.contains("Total Screen Time"))
        #expect(markdown.contains("Health Score"))
    }

    @Test("Markdown contains Hourly Breakdown section")
    func markdownHasHourlyBreakdown() {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Hourly Breakdown"))
        #expect(markdown.contains("Breaks Taken"))
        #expect(markdown.contains("Breaks Skipped"))
    }

    @Test("Markdown contains Break Compliance section")
    func markdownHasBreakCompliance() {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Break Compliance"))
        #expect(markdown.contains("Compliance Rate"))
        #expect(markdown.contains("50%"))
    }

    @Test("Markdown contains Longest Continuous Session section")
    func markdownHasLongestSession() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 3600,
            longestContinuousSession: 90 * 60
        )

        #expect(markdown.contains("Longest Continuous Session"))
        #expect(markdown.contains("1h 30m"))
    }

    @Test("Markdown contains Personalized Recommendations section")
    func markdownHasRecommendations() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )

        #expect(markdown.contains("Personalized Recommendations"))
    }

    @Test("Markdown contains Detailed Break Log section")
    func markdownHasDetailedBreakLog() {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Detailed Break Log"))
        #expect(markdown.contains("Micro Break"))
        #expect(markdown.contains("Macro Break"))
        #expect(markdown.contains("Taken"))
    }

    @Test("Markdown generates excellent recommendations for perfect score")
    func excellentRecommendations() {
        // Perfect score = all breaks taken, short sessions, low screen time
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: true, actualDuration: 300),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Great job"))
    }

    @Test("Markdown generates warnings for poor compliance")
    func poorComplianceRecommendations() {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .micro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
            BreakEvent(type: .mandatory, wasTaken: false, actualDuration: 0),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 12 * 60 * 60,
            longestContinuousSession: 3 * 60 * 60
        )

        #expect(markdown.contains("Critical") || markdown.contains("Important"))
    }

    @Test("Markdown empty break log shows appropriate message")
    func emptyBreakLogMessage() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )

        #expect(markdown.contains("No breaks recorded today"))
    }

    @Test("Markdown score breakdown contains bar visualization")
    func scoreBreakdownHasBar() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("Bar"))
        #expect(markdown.contains("Score Breakdown"))
    }

    @Test("Markdown contains per-type break compliance breakdown")
    func perTypeBreakCompliance() {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
        ]

        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: breakEvents,
            totalScreenTime: 3600,
            longestContinuousSession: 600
        )

        #expect(markdown.contains("By Type"))
        #expect(markdown.contains("Micro Break"))
        #expect(markdown.contains("Macro Break"))
    }

    @Test("Markdown footer contains EyeGuard attribution")
    func markdownFooter() {
        let markdown = generator.generateMarkdownContent(
            sessions: [],
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0
        )

        #expect(markdown.contains("Generated by EyeGuard"))
    }
}
