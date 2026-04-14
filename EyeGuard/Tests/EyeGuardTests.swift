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

    @Test("All break types have icon names")
    func allBreakTypesHaveIconNames() {
        for breakType in BreakType.allCases {
            #expect(!breakType.iconName.isEmpty)
        }
    }

    @Test("All break types have rule descriptions")
    func allBreakTypesHaveRuleDescriptions() {
        for breakType in BreakType.allCases {
            #expect(!breakType.ruleDescription.isEmpty)
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
