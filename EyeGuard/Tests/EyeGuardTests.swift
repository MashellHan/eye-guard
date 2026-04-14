import Foundation
import Testing

@testable import EyeGuard

// MARK: - BreakType Tests

@Suite("BreakType")
struct BreakTypeTests {

    @Test("Micro break has correct interval and duration")
    func microBreakValues() {
        let micro = BreakType.micro
        #expect(micro.interval == 20 * 60)
        #expect(micro.duration == 20)
        #expect(micro.displayName == "Micro Break")
    }

    @Test("Macro break has correct interval and duration")
    func macroBreakValues() {
        let macro = BreakType.macro
        #expect(macro.interval == 60 * 60)
        #expect(macro.duration == 5 * 60)
        #expect(macro.displayName == "Macro Break")
    }

    @Test("Mandatory break has correct interval and duration")
    func mandatoryBreakValues() {
        let mandatory = BreakType.mandatory
        #expect(mandatory.interval == 120 * 60)
        #expect(mandatory.duration == 15 * 60)
        #expect(mandatory.displayName == "Mandatory Break")
    }

    @Test("All break types are codable round-trip")
    func codableRoundTrip() throws {
        for breakType in BreakType.allCases {
            let data = try JSONEncoder().encode(breakType)
            let decoded = try JSONDecoder().decode(BreakType.self, from: data)
            #expect(decoded == breakType)
        }
    }
}

// MARK: - HealthScore Tests

@Suite("HealthScore")
struct HealthScoreTests {

    @Test("Perfect score totals 100")
    func perfectScore() {
        let score = HealthScore(
            breakCompliance: 40,
            continuousUseDiscipline: 30,
            screenTimeScore: 20,
            breakQuality: 10
        )
        #expect(score.totalScore == 100)
    }

    @Test("Zero score totals 0")
    func zeroScore() {
        let score = HealthScore(
            breakCompliance: 0,
            continuousUseDiscipline: 0,
            screenTimeScore: 0,
            breakQuality: 0
        )
        #expect(score.totalScore == 0)
    }

    @Test("Components are clamped to valid ranges")
    func clampedValues() {
        let score = HealthScore(
            breakCompliance: 999,
            continuousUseDiscipline: -5,
            screenTimeScore: 50,
            breakQuality: 10
        )
        #expect(score.breakCompliance == 40)
        #expect(score.continuousUseDiscipline == 0)
        #expect(score.screenTimeScore == 20)
        #expect(score.breakQuality == 10)
        #expect(score.totalScore == 70)
    }
}

// MARK: - HealthScoreCalculator Tests

@Suite("HealthScoreCalculator")
struct HealthScoreCalculatorTests {

    let calculator = HealthScoreCalculator()

    @Test("No breaks and low screen time yields high score")
    func noBreaksLowScreenTime() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 30 * 60, // 30 minutes
            longestContinuousSession: 15 * 60 // 15 minutes
        )
        // No break events = full compliance (no breaks were due)
        #expect(score.breakCompliance == 40)
        // Short session = full discipline
        #expect(score.continuousUseDiscipline == 30)
        // Low screen time = full points
        #expect(score.screenTimeScore == 20)
        // No breaks to evaluate quality = full points
        #expect(score.breakQuality == 10)
        #expect(score.totalScore == 100)
    }

    @Test("All breaks skipped yields low compliance")
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
        #expect(score.breakCompliance == 20) // 50% of 40
    }

    @Test("Long continuous session penalizes discipline")
    func longContinuousSession() {
        let score = calculator.calculate(
            breakEvents: [],
            totalScreenTime: 3 * 60 * 60,
            longestContinuousSession: 3 * 60 * 60 // 3 hours straight
        )
        // Exceeded mandatory break interval → 0 discipline
        #expect(score.continuousUseDiscipline == 0)
    }
}

// MARK: - BreakEvent Tests

@Suite("BreakEvent")
struct BreakEventTests {

    @Test("BreakEvent is codable round-trip")
    func codableRoundTrip() throws {
        let event = BreakEvent(
            type: .micro,
            wasTaken: true,
            actualDuration: 20
        )
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(BreakEvent.self, from: data)
        #expect(decoded.id == event.id)
        #expect(decoded.type == event.type)
        #expect(decoded.wasTaken == event.wasTaken)
        #expect(decoded.actualDuration == event.actualDuration)
    }
}

// MARK: - UsageSession Tests

@Suite("UsageSession")
struct UsageSessionTests {

    @Test("Adding a break returns new session with break appended")
    func addingBreak() {
        let session = UsageSession()
        let breakEvent = BreakEvent(type: .micro, wasTaken: true, actualDuration: 20)
        let updated = session.addingBreak(breakEvent)

        #expect(session.breaks.isEmpty)
        #expect(updated.breaks.count == 1)
        #expect(updated.id == session.id) // same session
    }

    @Test("Ending a session returns new session with end time")
    func endingSession() {
        let session = UsageSession()
        let ended = session.ending()

        #expect(session.endTime == nil)
        #expect(ended.endTime != nil)
        #expect(ended.id == session.id)
    }
}

// MARK: - UserPreferences Tests

@Suite("UserPreferences")
struct UserPreferencesTests {

    @Test("Default preferences match medical guidelines")
    func defaultValues() {
        let prefs = UserPreferences.default
        #expect(prefs.microBreakInterval == 20 * 60)
        #expect(prefs.microBreakDuration == 20)
        #expect(prefs.macroBreakInterval == 60 * 60)
        #expect(prefs.mandatoryBreakInterval == 120 * 60)
        #expect(prefs.isMicroBreakEnabled == true)
        #expect(prefs.isMacroBreakEnabled == true)
        #expect(prefs.isMandatoryBreakEnabled == true)
    }
}
