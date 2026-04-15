import Foundation
import Testing

@testable import EyeGuard

// MARK: - DataPersistenceManager Tests

@Suite("DataPersistenceManager")
struct DataPersistenceManagerTests {

    let manager = DataPersistenceManager()

    @Test("Save and load round-trip preserves data")
    func saveAndLoadRoundTrip() async throws {
        let breakEvents = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
        ]
        let screenTime: TimeInterval = 3600
        let longestSession: TimeInterval = 1200
        let scoreHistory = [100, 95, 90]

        // Use a fixed date to avoid collision with real data
        let testDate = Date(timeIntervalSince1970: 946684800) // 2000-01-01

        await manager.save(
            breakEvents: breakEvents,
            totalScreenTime: screenTime,
            longestContinuousSession: longestSession,
            scoreHistory: scoreHistory,
            date: testDate
        )

        let loaded = await manager.load(for: testDate)
        #expect(loaded != nil)

        if let data = loaded {
            #expect(data.breakEvents.count == 2)
            #expect(data.breakEvents[0].type == .micro)
            #expect(data.breakEvents[0].wasTaken == true)
            #expect(data.breakEvents[1].type == .macro)
            #expect(data.breakEvents[1].wasTaken == false)
            #expect(data.totalScreenTime == screenTime)
            #expect(data.longestContinuousSession == longestSession)
            #expect(data.scoreHistory == scoreHistory)
        }

        // Clean up test file
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: testDate)
        let fileURL = EyeGuardConstants.dataDirectory
            .appendingPathComponent("\(dateString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test("Load returns nil for nonexistent date")
    func loadNonexistentDate() async {
        // Use a date far in the past that won't have data
        let testDate = Date(timeIntervalSince1970: 0) // 1970-01-01
        let loaded = await manager.load(for: testDate)
        #expect(loaded == nil)
    }

    @Test("Exists returns false for nonexistent date")
    func existsNonexistent() {
        let testDate = Date(timeIntervalSince1970: 0)
        #expect(manager.exists(for: testDate) == false)
    }

    @Test("Save creates data directory if needed")
    func saveCreatesDirectory() async throws {
        let testDate = Date(timeIntervalSince1970: 946684800) // 2000-01-01

        await manager.save(
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0,
            scoreHistory: [],
            date: testDate
        )

        let directoryExists = FileManager.default.fileExists(
            atPath: EyeGuardConstants.dataDirectory.path
        )
        #expect(directoryExists == true)

        // Clean up
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: testDate)
        let fileURL = EyeGuardConstants.dataDirectory
            .appendingPathComponent("\(dateString).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test("DailyData is codable round-trip")
    func dailyDataCodable() throws {
        let data = DailyData(
            date: "2024-01-15",
            breakEvents: [
                BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            ],
            totalScreenTime: 7200,
            longestContinuousSession: 3600,
            scoreHistory: [100, 85, 72]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DailyData.self, from: jsonData)

        #expect(decoded.date == data.date)
        #expect(decoded.breakEvents.count == 1)
        #expect(decoded.totalScreenTime == data.totalScreenTime)
        #expect(decoded.longestContinuousSession == data.longestContinuousSession)
        #expect(decoded.scoreHistory == data.scoreHistory)
    }
}

// MARK: - HealthScoreCalculator Enhanced Tests

@Suite("HealthScoreCalculator - Trend & Breakdown")
struct HealthScoreCalculatorEnhancedTests {

    let calculator = HealthScoreCalculator()

    @Test("Trend is stable with no previous scores")
    func trendStableNoPrevious() {
        let trend = calculator.calculateTrend(currentScore: 80, previousScores: [])
        #expect(trend == .stable)
    }

    @Test("Trend is improving when score increased significantly")
    func trendImproving() {
        let trend = calculator.calculateTrend(currentScore: 90, previousScores: [70, 72, 75, 78, 80])
        #expect(trend == .improving)
    }

    @Test("Trend is declining when score decreased significantly")
    func trendDeclining() {
        let trend = calculator.calculateTrend(currentScore: 50, previousScores: [90, 85, 80, 75, 70])
        #expect(trend == .declining)
    }

    @Test("Trend is stable when score is similar")
    func trendStableSimilar() {
        let trend = calculator.calculateTrend(currentScore: 80, previousScores: [79, 80, 81, 80, 79])
        #expect(trend == .stable)
    }

    @Test("Breakdown contains four components")
    func breakdownHasFourComponents() {
        let breakdown = calculator.calculateBreakdown(
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0,
            previousScores: []
        )

        #expect(breakdown.components.count == 4)
        #expect(breakdown.components[0].name == "Breaks")
        #expect(breakdown.components[1].name == "Discipline")
        #expect(breakdown.components[2].name == "Time")
        #expect(breakdown.components[3].name == "Quality")
    }

    @Test("Breakdown components have valid max scores")
    func breakdownMaxScores() {
        let breakdown = calculator.calculateBreakdown(
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0,
            previousScores: []
        )

        #expect(breakdown.components[0].maxScore == 40)
        #expect(breakdown.components[1].maxScore == 30)
        #expect(breakdown.components[2].maxScore == 20)
        #expect(breakdown.components[3].maxScore == 10)
    }

    @Test("Breakdown includes non-empty explanations")
    func breakdownHasExplanations() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
            BreakEvent(type: .macro, wasTaken: false, actualDuration: 0),
        ]
        let breakdown = calculator.calculateBreakdown(
            breakEvents: events,
            totalScreenTime: 3600,
            longestContinuousSession: 1200,
            previousScores: [80, 75]
        )

        for component in breakdown.components {
            #expect(!component.explanation.isEmpty,
                    "\(component.name) should have a non-empty explanation")
        }
    }

    @Test("Breakdown summary text is non-empty")
    func breakdownSummaryNotEmpty() {
        let breakdown = calculator.calculateBreakdown(
            breakEvents: [],
            totalScreenTime: 0,
            longestContinuousSession: 0,
            previousScores: []
        )

        #expect(!breakdown.summaryText.isEmpty)
    }

    @Test("ScoreTrend symbols are distinct")
    func trendSymbolsDistinct() {
        let symbols = [ScoreTrend.improving.symbol, ScoreTrend.stable.symbol, ScoreTrend.declining.symbol]
        #expect(Set(symbols).count == 3)
    }

    @Test("ScoreTrend display names are distinct")
    func trendDisplayNamesDistinct() {
        let names = [ScoreTrend.improving.displayName, ScoreTrend.stable.displayName, ScoreTrend.declining.displayName]
        #expect(Set(names).count == 3)
    }

    @Test("Breakdown score matches direct calculation")
    func breakdownScoreMatchesDirect() {
        let events = [
            BreakEvent(type: .micro, wasTaken: true, actualDuration: 20),
        ]
        let directScore = calculator.calculate(
            breakEvents: events,
            totalScreenTime: 3600,
            longestContinuousSession: 1200
        )
        let breakdown = calculator.calculateBreakdown(
            breakEvents: events,
            totalScreenTime: 3600,
            longestContinuousSession: 1200,
            previousScores: []
        )

        #expect(breakdown.score.totalScore == directScore.totalScore)
        #expect(breakdown.score.breakCompliance == directScore.breakCompliance)
        #expect(breakdown.score.continuousUseDiscipline == directScore.continuousUseDiscipline)
        #expect(breakdown.score.screenTimeScore == directScore.screenTimeScore)
        #expect(breakdown.score.breakQuality == directScore.breakQuality)
    }
}
