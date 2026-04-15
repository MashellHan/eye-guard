import Foundation

/// Protocol for screen color analysis and suggestion generation.
///
/// Abstracts the color analysis layer for testability via dependency injection.
/// Production: `ColorAnalyzer` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol ColorAnalyzing {
    /// The currently detected dominant color family.
    var dominantColorFamily: ColorAnalyzer.ColorFamily { get }

    /// The suggested complementary color family.
    var suggestedColorFamily: ColorAnalyzer.ColorFamily { get }

    /// Number of analyses performed today.
    var analysisCount: Int { get }

    /// Whether the analyzer is currently running.
    var isRunning: Bool { get }

    /// Starts periodic color analysis.
    func startAnalysis()

    /// Stops periodic color analysis.
    func stopAnalysis()

    /// Returns a color suggestion message based on the dominant color.
    func currentSuggestion() -> (message: String, emoji: String)

    /// Returns the full suggestion text for the mascot speech bubble.
    func suggestionBubbleText() -> String

    /// Resets daily statistics.
    func resetDaily()

    /// Returns the most frequently detected color family from recent history.
    func mostFrequentRecentColor() -> ColorAnalyzer.ColorFamily
}
