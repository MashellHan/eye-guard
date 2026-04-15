import Foundation
import os

// MARK: - LLMAnalyzing Protocol

/// Protocol for LLM-powered usage pattern analysis.
///
/// Implementations can range from local rule-based engines to cloud LLM APIs.
/// API keys are never hardcoded; they are read from environment variables
/// or the macOS Keychain at runtime.
protocol LLMAnalyzing: Sendable {
    /// Analyzes a daily usage report and returns a natural-language insight string.
    ///
    /// - Parameter data: The daily report to analyze.
    /// - Returns: A multi-line insight string suitable for display.
    func analyzeUsagePattern(data: DailyReport) async throws -> String
}

// MARK: - LLMServiceError

/// Errors that can occur during LLM analysis.
enum LLMServiceError: Error, LocalizedError, Sendable {
    case apiKeyMissing
    case networkError(String)
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key not configured. Set CLAUDE_API_KEY environment variable."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from LLM service."
        case .rateLimited:
            return "Rate limited. Please try again later."
        }
    }
}

// MARK: - LocalLLMService

/// A rule-based insight engine that generates smart analysis without requiring
/// an external LLM API. Produces human-like insights from usage patterns.
///
/// This is the default service used when no API key is configured.
struct LocalLLMService: LLMAnalyzing {

    func analyzeUsagePattern(data: DailyReport) async throws -> String {
        var insights: [String] = []

        // Screen time analysis
        let screenHours = data.totalScreenTime / 3600.0
        let screenTimeStr = String(format: "%.1f", screenHours)

        if screenHours > 10 {
            insights.append(
                "Based on your \(screenTimeStr) hours of screen time, you're significantly above the recommended 8-hour daily limit. Consider scheduling screen-free activities in the evening."
            )
        } else if screenHours > 8 {
            insights.append(
                "Your \(screenTimeStr) hours of screen time exceeds the recommended 8-hour limit. Try wrapping up earlier or taking longer breaks."
            )
        } else if screenHours > 6 {
            insights.append(
                "With \(screenTimeStr) hours of screen time, you're approaching the recommended limit. The 20-20-20 rule becomes even more important now."
            )
        } else if screenHours > 4 {
            insights.append(
                "Your \(screenTimeStr) hours of screen time is well within healthy limits. Keep maintaining this balance!"
            )
        } else {
            insights.append(
                "Excellent! Only \(screenTimeStr) hours of screen time today. Your eyes are getting plenty of rest."
            )
        }

        // Break compliance analysis
        let totalBreaks = data.totalBreaksScheduled
        let takenBreaks = data.totalBreaksTaken
        if totalBreaks > 0 {
            let complianceRate = Double(takenBreaks) / Double(totalBreaks) * 100
            let rateStr = String(format: "%.0f", complianceRate)

            if complianceRate < 50 {
                insights.append(
                    "Your break compliance dropped to \(rateStr)% today. The most commonly skipped breaks tend to be micro-breaks during peak focus hours (2-4 PM)."
                )
            } else if complianceRate < 80 {
                insights.append(
                    "Break compliance is at \(rateStr)%. Try enabling sound notifications to catch breaks you might be missing during deep focus."
                )
            } else {
                insights.append(
                    "Great break compliance at \(rateStr)%! Consistent breaks are the single most effective way to prevent digital eye strain."
                )
            }
        }

        // Health score analysis
        let score = data.healthScore.totalScore
        if score >= 85 {
            insights.append(
                "Your health score of \(score)/100 puts you in excellent standing. Keep it up!"
            )
        } else if score >= 60 {
            let weakest = weakestComponent(data.healthScore)
            insights.append(
                "Health score: \(score)/100. Your weakest area is \(weakest). Focus on improving that for a better overall score."
            )
        } else {
            insights.append(
                "Health score of \(score)/100 needs attention. Start with the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds."
            )
        }

        // Pattern-based suggestion
        insights.append(actionableSuggestion(score: score, compliance: totalBreaks > 0 ? Double(takenBreaks) / Double(totalBreaks) : 1.0))

        return insights.joined(separator: "\n\n")
    }

    /// Identifies the weakest health score component by name.
    private func weakestComponent(_ score: HealthScore) -> String {
        let components: [(String, Double)] = [
            ("break compliance", Double(score.breakCompliance) / 40.0),
            ("continuous use discipline", Double(score.continuousUseDiscipline) / 30.0),
            ("screen time management", Double(score.screenTimeScore) / 20.0),
            ("break quality", Double(score.breakQuality) / 10.0),
        ]
        return components.min(by: { $0.1 < $1.1 })?.0 ?? "break compliance"
    }

    /// Returns a contextual actionable suggestion.
    private func actionableSuggestion(score: Int, compliance: Double) -> String {
        if compliance < 0.5 {
            return "Tip: Try the Pomodoro technique alongside EyeGuard. Work for 25 minutes, then take a 5-minute break. This aligns naturally with the macro-break schedule."
        } else if score < 60 {
            return "Tip: Position your monitor at arm's length (about 25 inches) with the top of the screen at or slightly below eye level. This reduces strain during long sessions."
        } else if score < 80 {
            return "Tip: Blink consciously! Studies show we blink 66% less when using screens. Try placing a small reminder note near your monitor."
        } else {
            return "Tip: You're doing great! Consider adding the eye exercises from the mascot menu to your routine for even better eye health."
        }
    }
}

// MARK: - ClaudeLLMService (Placeholder)

/// Placeholder for Claude API-powered analysis.
///
/// When implemented, this service will:
/// 1. Read the API key from the `CLAUDE_API_KEY` environment variable
/// 2. Send usage data to the Claude API for natural-language analysis
/// 3. Return personalized, context-aware insights
///
/// **Security**: API keys are NEVER hardcoded. They are read from:
/// - Environment variable: `CLAUDE_API_KEY`
/// - Or macOS Keychain (future implementation)
struct ClaudeLLMService: LLMAnalyzing {

    func analyzeUsagePattern(data: DailyReport) async throws -> String {
        // Check for API key in environment
        guard let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
              !apiKey.isEmpty
        else {
            throw LLMServiceError.apiKeyMissing
        }

        // TODO: Implement Claude API integration
        // For now, fall back to local analysis
        Log.ai.info("Claude API key found but integration not yet implemented. Using local analysis.")
        let localService = LocalLLMService()
        return try await localService.analyzeUsagePattern(data: data)
    }
}

// MARK: - LLMServiceFactory

/// Factory for creating the appropriate LLM service based on configuration.
enum LLMServiceFactory {

    /// Returns the best available LLM service.
    ///
    /// Priority:
    /// 1. ClaudeLLMService (if API key is set)
    /// 2. LocalLLMService (always available)
    static func createService() -> any LLMAnalyzing {
        if let apiKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"],
           !apiKey.isEmpty
        {
            Log.ai.info("Using Claude LLM service for analysis.")
            return ClaudeLLMService()
        }

        Log.ai.info("No LLM API key found. Using local rule-based analysis.")
        return LocalLLMService()
    }
}
