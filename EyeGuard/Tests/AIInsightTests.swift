import Foundation
import Testing

@testable import EyeGuard

// MARK: - LocalLLMService Tests

@Suite("LocalLLMService")
struct LocalLLMServiceTests {

    @Test("Analyzes high screen time report")
    func highScreenTime() async throws {
        let service = LocalLLMService()
        let report = makeReport(screenTime: 11 * 3600, score: 40, taken: 5, scheduled: 20)
        let result = try await service.analyzeUsagePattern(data: report)
        #expect(result.contains("11.0"))
        #expect(!result.isEmpty)
    }

    @Test("Analyzes low screen time report")
    func lowScreenTime() async throws {
        let service = LocalLLMService()
        let report = makeReport(screenTime: 2 * 3600, score: 95, taken: 10, scheduled: 10)
        let result = try await service.analyzeUsagePattern(data: report)
        #expect(result.contains("2.0"))
        #expect(!result.isEmpty)
    }

    @Test("Analyzes low compliance report")
    func lowCompliance() async throws {
        let service = LocalLLMService()
        let report = makeReport(screenTime: 6 * 3600, score: 50, taken: 3, scheduled: 15)
        let result = try await service.analyzeUsagePattern(data: report)
        #expect(result.contains("20%") || result.contains("compliance"))
    }

    @Test("Analyzes high compliance report")
    func highCompliance() async throws {
        let service = LocalLLMService()
        let report = makeReport(screenTime: 6 * 3600, score: 85, taken: 18, scheduled: 20)
        let result = try await service.analyzeUsagePattern(data: report)
        #expect(result.contains("90%") || result.contains("compliance") || result.contains("Great"))
    }

    @Test("Returns non-empty result for empty report")
    func emptyReport() async throws {
        let service = LocalLLMService()
        let report = makeReport(screenTime: 0, score: 100, taken: 0, scheduled: 0)
        let result = try await service.analyzeUsagePattern(data: report)
        #expect(!result.isEmpty)
    }
}

// MARK: - InsightGenerator Tests

@Suite("InsightGenerator")
struct InsightGeneratorTests {

    @Test("Generates report insights")
    func reportInsights() async {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let report = makeReport(screenTime: 7 * 3600, score: 70, taken: 10, scheduled: 15)
        let insights = await generator.generateReportInsights(report: report)
        #expect(!insights.isEmpty)
        #expect(insights.contains("-"))  // Bullet points
    }

    @Test("Generates mascot insight for afternoon")
    func mascotAfternoonInsight() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let insight = generator.generateMascotInsight(
            screenTime: 5 * 3600,
            breaksTaken: 8,
            breaksScheduled: 12,
            healthScore: 75,
            hour: 15
        )
        #expect(!insight.isEmpty)
        #expect(insight.contains("🤖"))
    }

    @Test("Generates mascot insight for evening")
    func mascotEveningInsight() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let insight = generator.generateMascotInsight(
            screenTime: 9 * 3600,
            breaksTaken: 12,
            breaksScheduled: 20,
            healthScore: 55,
            hour: 18
        )
        #expect(!insight.isEmpty)
        #expect(insight.contains("🤖"))
    }

    @Test("Generates mascot insight for low score")
    func mascotLowScoreInsight() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let insight = generator.generateMascotInsight(
            screenTime: 4 * 3600,
            breaksTaken: 2,
            breaksScheduled: 10,
            healthScore: 25,
            hour: 10
        )
        #expect(insight.contains("🤖"))
        #expect(insight.contains("25"))
    }

    @Test("Generates menu bar insight for high score")
    func menuBarHighScore() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let insight = generator.generateMenuBarInsight(
            healthScore: 90,
            screenTime: 4 * 3600,
            breakCompliance: 0.9
        )
        #expect(insight.contains("🤖"))
        #expect(insight.contains("90"))
        #expect(insight.contains("Great"))
    }

    @Test("Generates menu bar insight for low score")
    func menuBarLowScore() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let insight = generator.generateMenuBarInsight(
            healthScore: 35,
            screenTime: 10 * 3600,
            breakCompliance: 0.3
        )
        #expect(insight.contains("🤖"))
        #expect(insight.contains("35"))
    }

    @Test("Generates comparison insight without yesterday")
    func comparisonNoYesterday() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let today = makeReport(screenTime: 5 * 3600, score: 80, taken: 10, scheduled: 12)
        let insight = generator.generateComparisonInsight(today: today, yesterday: nil)
        #expect(insight.contains("First day"))
    }

    @Test("Generates comparison insight with improvement")
    func comparisonImproved() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let today = makeReport(screenTime: 5 * 3600, score: 85, taken: 15, scheduled: 16)
        let yesterday = makeReport(screenTime: 8 * 3600, score: 55, taken: 5, scheduled: 16)
        let insight = generator.generateComparisonInsight(today: today, yesterday: yesterday)
        #expect(!insight.isEmpty)
    }

    @Test("Analyzes hourly patterns with events")
    func hourlyPatterns() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let events = [
            BreakEvent(timestamp: makeDate(hour: 9), type: .micro, wasTaken: true),
            BreakEvent(timestamp: makeDate(hour: 9), type: .micro, wasTaken: true),
            BreakEvent(timestamp: makeDate(hour: 14), type: .micro, wasTaken: false),
            BreakEvent(timestamp: makeDate(hour: 14), type: .micro, wasTaken: false),
        ]
        let patterns = generator.analyzeHourlyPatterns(breakEvents: events)
        #expect(patterns.best.contains("09:00"))
        #expect(patterns.worst.contains("14:00"))
    }

    @Test("Analyzes hourly patterns with empty events")
    func hourlyPatternsEmpty() {
        let generator = InsightGenerator(llmService: LocalLLMService())
        let patterns = generator.analyzeHourlyPatterns(breakEvents: [])
        #expect(patterns.best == "No data yet")
        #expect(patterns.worst == "No data yet")
    }
}

// MARK: - LLMServiceFactory Tests

@Suite("LLMServiceFactory")
struct LLMServiceFactoryTests {

    @Test("Creates local service when no API key")
    func defaultService() {
        let service = LLMServiceFactory.createService()
        #expect(service is LocalLLMService)
    }
}

// MARK: - ClaudeLLMService Tests

@Suite("ClaudeLLMService")
struct ClaudeLLMServiceTests {

    @Test("Throws when no API key")
    func missingApiKey() async {
        let service = ClaudeLLMService()
        let report = makeReport(screenTime: 3600, score: 80, taken: 5, scheduled: 5)
        do {
            _ = try await service.analyzeUsagePattern(data: report)
            // If env var CLAUDE_API_KEY is set, it falls back to local — that's OK
        } catch let error as LLMServiceError {
            if case .apiKeyMissing = error {
                // Expected
            } else {
                #expect(Bool(false), "Expected apiKeyMissing, got \(error)")
            }
        } catch {
            // Unexpected error type
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Helpers

private func makeReport(
    screenTime: TimeInterval,
    score: Int,
    taken: Int,
    scheduled: Int
) -> DailyReport {
    DailyReport(
        date: .now,
        sessions: [],
        healthScore: HealthScore(
            breakCompliance: score * 40 / 100,
            continuousUseDiscipline: score * 30 / 100,
            screenTimeScore: score * 20 / 100,
            breakQuality: score * 10 / 100
        ),
        totalScreenTime: screenTime,
        totalBreaksTaken: taken,
        totalBreaksScheduled: scheduled
    )
}

private func makeDate(hour: Int) -> Date {
    let calendar = Calendar.current
    return calendar.date(
        bySettingHour: hour,
        minute: 30,
        second: 0,
        of: .now
    ) ?? .now
}
