import Foundation
import Testing

@testable import EyeGuard

// MARK: - ColorAnalyzer Tests

@Suite("ColorAnalyzer")
struct ColorAnalyzerTests {

    @Test("All color families have display names")
    func colorFamiliesHaveDisplayNames() {
        for family in ColorAnalyzer.ColorFamily.allCases {
            #expect(!family.displayNameZH.isEmpty)
        }
    }

    @Test("All color families have complementary colors")
    func colorFamiliesHaveComplementary() {
        for family in ColorAnalyzer.ColorFamily.allCases {
            let comp = family.complementary
            // Complementary should not be the same (except neutral which maps to green)
            if family != .neutral && family != .green {
                #expect(comp != family)
            }
        }
    }

    @Test("All color families have display colors with valid ranges")
    func colorFamiliesHaveValidDisplayColors() {
        for family in ColorAnalyzer.ColorFamily.allCases {
            let color = family.displayColor
            #expect(color.red >= 0 && color.red <= 1)
            #expect(color.green >= 0 && color.green <= 1)
            #expect(color.blue >= 0 && color.blue <= 1)
        }
    }

    @Test("Blue complementary is green")
    func blueComplementary() {
        #expect(ColorAnalyzer.ColorFamily.blue.complementary == .green)
    }

    @Test("Red complementary is green")
    func redComplementary() {
        #expect(ColorAnalyzer.ColorFamily.red.complementary == .green)
    }

    @Test("Green complementary is blue")
    func greenComplementary() {
        #expect(ColorAnalyzer.ColorFamily.green.complementary == .blue)
    }

    @Test("Yellow complementary is purple")
    func yellowComplementary() {
        #expect(ColorAnalyzer.ColorFamily.yellow.complementary == .purple)
    }

    @Test("Suggestions dictionary has entries for all color families")
    func suggestionsHaveAllFamilies() {
        for family in ColorAnalyzer.ColorFamily.allCases {
            let suggestions = ColorAnalyzer.suggestions[family]
            #expect(suggestions != nil, "Missing suggestions for \(family.rawValue)")
            #expect(suggestions!.count >= 2, "Too few suggestions for \(family.rawValue)")
        }
    }

    @Test("All suggestion messages have non-empty content")
    func allSuggestionMessagesValid() {
        for (_, suggestions) in ColorAnalyzer.suggestions {
            for suggestion in suggestions {
                #expect(!suggestion.message.isEmpty)
                #expect(!suggestion.emoji.isEmpty)
            }
        }
    }

    @Test("Initial dominant color is neutral")
    @MainActor
    func initialDominantIsNeutral() {
        let analyzer = ColorAnalyzer.shared
        // On fresh start or after reset, should be neutral
        analyzer.resetDaily()
        #expect(analyzer.dominantColorFamily == .neutral)
    }

    @Test("Reset clears analysis count")
    @MainActor
    func resetClearsCount() {
        let analyzer = ColorAnalyzer.shared
        analyzer.resetDaily()
        #expect(analyzer.analysisCount == 0)
        #expect(analyzer.colorHistory.isEmpty)
    }

    @Test("Suggestion bubble text returns non-empty string")
    @MainActor
    func suggestionBubbleTextNotEmpty() {
        let analyzer = ColorAnalyzer.shared
        let text = analyzer.suggestionBubbleText()
        #expect(!text.isEmpty)
    }

    @Test("Current suggestion returns valid tuple")
    @MainActor
    func currentSuggestionValid() {
        let analyzer = ColorAnalyzer.shared
        let suggestion = analyzer.currentSuggestion()
        #expect(!suggestion.message.isEmpty)
        #expect(!suggestion.emoji.isEmpty)
    }

    @Test("Most frequent recent color returns neutral when history is empty")
    @MainActor
    func mostFrequentEmptyHistory() {
        let analyzer = ColorAnalyzer.shared
        analyzer.resetDaily()
        #expect(analyzer.mostFrequentRecentColor() == .neutral)
    }

    @Test("Color family raw values are all unique")
    func colorFamilyRawValuesUnique() {
        let rawValues = ColorAnalyzer.ColorFamily.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    @Test("ColorFamily allCases has expected count")
    func colorFamilyCount() {
        #expect(ColorAnalyzer.ColorFamily.allCases.count == 7)
    }
}
