import Foundation
import os

/// Generates rule-based daily insights without requiring an external LLM.
///
/// Analyzes usage patterns by comparing today's data against historical trends
/// and generates actionable, human-readable insights for:
/// - Daily report (🤖 AI Insights section)
/// - Mascot periodic speech bubble (every 2 hours)
/// - Menu bar popover (summary insight)
///
/// v1.8: LLM-ready architecture — can be replaced with ClaudeLLMService
/// when an API key is configured.
struct InsightGenerator: Sendable {

    /// The LLM service used for deep analysis.
    private let llmService: any LLMAnalyzing

    init(llmService: any LLMAnalyzing = LLMServiceFactory.createService()) {
        self.llmService = llmService
    }

    // MARK: - Daily Report Insights

    /// Generates a full insight section for the daily Markdown report.
    ///
    /// - Parameter report: The daily report data.
    /// - Returns: Markdown-formatted insight string for the report.
    func generateReportInsights(report: DailyReport) async -> String {
        do {
            let analysis = try await llmService.analyzeUsagePattern(data: report)
            return formatReportInsights(analysis)
        } catch {
            Log.ai.error("LLM analysis failed: \(error.localizedDescription). Using fallback.")
            return formatReportInsights(generateFallbackInsights(report: report))
        }
    }

    /// Formats raw insight text into Markdown for the report section.
    private func formatReportInsights(_ rawInsights: String) -> String {
        let paragraphs = rawInsights.components(separatedBy: "\n\n")
        let bulletPoints = paragraphs.map { "- \($0.trimmingCharacters(in: .whitespacesAndNewlines))" }
        return bulletPoints.joined(separator: "\n")
    }

    // MARK: - Mascot Speech Bubble Insights

    /// Generates a short insight for the mascot speech bubble.
    ///
    /// Called periodically (every 2 hours) to show contextual tips.
    /// The result is kept short (under 50 characters) for the bubble UI.
    ///
    /// - Parameters:
    ///   - screenTime: Total screen time today in seconds.
    ///   - breaksTaken: Number of breaks taken today.
    ///   - breaksScheduled: Number of breaks scheduled today.
    ///   - healthScore: Current health score (0-100).
    ///   - hour: Current hour of day (0-23).
    /// - Returns: A short insight string for the speech bubble.
    func generateMascotInsight(
        screenTime: TimeInterval,
        breaksTaken: Int,
        breaksScheduled: Int,
        healthScore: Int,
        hour: Int
    ) -> String {
        let screenHours = screenTime / 3600.0

        // Time-based insights
        if hour >= 14 && hour <= 16 {
            return afternoonInsight(screenHours: screenHours, healthScore: healthScore)
        }

        if hour >= 17 {
            return eveningInsight(screenHours: screenHours)
        }

        // Score-based insights
        if healthScore < 50 {
            return lowScoreInsight(healthScore: healthScore)
        }

        // Compliance-based insights
        if breaksScheduled > 0 {
            let rate = Double(breaksTaken) / Double(breaksScheduled)
            if rate < 0.5 {
                return "🤖 Break compliance is low. Try taking the next one!"
            }
            if rate >= 0.9 {
                return "🤖 Amazing break discipline! Your eyes thank you 👁️"
            }
        }

        // Screen time milestones
        if screenHours > 6 {
            return "🤖 \(String(format: "%.0f", screenHours))h screen time. Consider a longer break."
        }

        if screenHours > 4 {
            return "🤖 \(String(format: "%.0f", screenHours))h so far. You're doing well!"
        }

        // Default encouraging messages
        let messages = [
            "🤖 Remember: blink more often while reading!",
            "🤖 Keep your monitor at arm's length 💪",
            "🤖 Good posture helps your eyes too!",
            "🤖 Stay hydrated — it helps your eyes!",
            "🤖 Adjust screen brightness to match room light",
        ]
        return messages[Int.random(in: 0..<messages.count)]
    }

    // MARK: - Menu Bar Summary Insight

    /// Generates a one-line summary insight for the menu bar popover.
    ///
    /// - Parameters:
    ///   - healthScore: Current health score.
    ///   - screenTime: Total screen time today in seconds.
    ///   - breakCompliance: Break compliance ratio (0.0 - 1.0).
    /// - Returns: A brief summary insight.
    func generateMenuBarInsight(
        healthScore: Int,
        screenTime: TimeInterval,
        breakCompliance: Double
    ) -> String {
        let hours = String(format: "%.1f", screenTime / 3600.0)

        if healthScore >= 80 {
            return "🤖 Score \(healthScore) · \(hours)h screen · Great job!"
        } else if healthScore >= 50 {
            if breakCompliance < 0.6 {
                return "🤖 Score \(healthScore) · Take more breaks for better health"
            }
            return "🤖 Score \(healthScore) · \(hours)h screen · Room for improvement"
        } else {
            return "🤖 Score \(healthScore) · Your eyes need rest. Take a break!"
        }
    }

    // MARK: - Comparison Insights

    /// Compares today's data against yesterday's for trend insights.
    ///
    /// - Parameters:
    ///   - today: Today's daily report.
    ///   - yesterday: Yesterday's daily report (optional).
    /// - Returns: A comparison insight string.
    func generateComparisonInsight(today: DailyReport, yesterday: DailyReport?) -> String {
        guard let yesterday else {
            return "First day of tracking! Building your baseline data."
        }

        var comparisons: [String] = []

        // Screen time comparison
        let todayHours = today.totalScreenTime / 3600.0
        let yesterdayHours = yesterday.totalScreenTime / 3600.0
        let timeDiff = todayHours - yesterdayHours

        if abs(timeDiff) > 0.5 {
            if timeDiff > 0 {
                comparisons.append(
                    String(format: "Screen time is up %.1fh compared to yesterday.", timeDiff)
                )
            } else {
                comparisons.append(
                    String(format: "Screen time is down %.1fh from yesterday — nice!", abs(timeDiff))
                )
            }
        }

        // Score comparison
        let scoreDiff = today.healthScore.totalScore - yesterday.healthScore.totalScore
        if abs(scoreDiff) > 5 {
            if scoreDiff > 0 {
                comparisons.append("Health score improved by \(scoreDiff) points!")
            } else {
                comparisons.append("Health score dropped \(abs(scoreDiff)) points. Let's improve tomorrow.")
            }
        }

        // Compliance comparison
        let todayCompliance = today.totalBreaksScheduled > 0
            ? Double(today.totalBreaksTaken) / Double(today.totalBreaksScheduled) * 100
            : 100
        let yesterdayCompliance = yesterday.totalBreaksScheduled > 0
            ? Double(yesterday.totalBreaksTaken) / Double(yesterday.totalBreaksScheduled) * 100
            : 100
        let complianceDiff = todayCompliance - yesterdayCompliance

        if abs(complianceDiff) > 10 {
            if complianceDiff > 0 {
                comparisons.append(
                    String(format: "Break compliance improved by %.0f%%.", complianceDiff)
                )
            } else {
                comparisons.append(
                    String(format: "Break compliance dropped %.0f%% today.", abs(complianceDiff))
                )
            }
        }

        if comparisons.isEmpty {
            return "Today's performance is similar to yesterday. Consistency is key!"
        }

        return comparisons.joined(separator: " ")
    }

    // MARK: - Hourly Pattern Analysis

    /// Identifies the worst and best hours based on break events.
    ///
    /// - Parameter breakEvents: Today's break events.
    /// - Returns: A tuple of (bestHour, worstHour) descriptions.
    func analyzeHourlyPatterns(breakEvents: [BreakEvent]) -> (best: String, worst: String) {
        guard !breakEvents.isEmpty else {
            return ("No data yet", "No data yet")
        }

        let calendar = Calendar.current
        var hourlyCompliance: [Int: (taken: Int, total: Int)] = [:]

        for event in breakEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            var entry = hourlyCompliance[hour, default: (taken: 0, total: 0)]
            entry.total += 1
            if event.wasTaken { entry.taken += 1 }
            hourlyCompliance[hour] = entry
        }

        let sorted = hourlyCompliance.sorted { lhs, rhs in
            let lhsRate = lhs.value.total > 0 ? Double(lhs.value.taken) / Double(lhs.value.total) : 0
            let rhsRate = rhs.value.total > 0 ? Double(rhs.value.taken) / Double(rhs.value.total) : 0
            return lhsRate > rhsRate
        }

        let bestHour = sorted.first.map { "\(String(format: "%02d", $0.key)):00 (\($0.value.taken)/\($0.value.total) breaks taken)" } ?? "N/A"
        let worstHour = sorted.last.map { "\(String(format: "%02d", $0.key)):00 (\($0.value.taken)/\($0.value.total) breaks taken)" } ?? "N/A"

        return (best: bestHour, worst: worstHour)
    }

    // MARK: - Private Helpers

    private func afternoonInsight(screenHours: Double, healthScore: Int) -> String {
        if healthScore < 60 {
            return "🤖 Afternoon slump alert! Take a walk to refresh your eyes."
        }
        return "🤖 Afternoon focus peak — remember your micro-breaks!"
    }

    private func eveningInsight(screenHours: Double) -> String {
        if screenHours > 8 {
            return "🤖 \(String(format: "%.0f", screenHours))h today. Time to wind down 🌙"
        }
        return "🤖 Evening mode: reduce brightness, enable Night Shift"
    }

    private func lowScoreInsight(healthScore: Int) -> String {
        if healthScore < 30 {
            return "🤖 Score \(healthScore) — please take a break now!"
        }
        return "🤖 Score \(healthScore). A few breaks will help a lot!"
    }

    /// Generates fallback insights when LLM service fails.
    private func generateFallbackInsights(report: DailyReport) -> String {
        let screenHours = String(format: "%.1f", report.totalScreenTime / 3600.0)
        let score = report.healthScore.totalScore
        let compliance = report.totalBreaksScheduled > 0
            ? Int(Double(report.totalBreaksTaken) / Double(report.totalBreaksScheduled) * 100)
            : 100

        return """
        Screen time: \(screenHours) hours. \(report.totalScreenTime > EyeGuardConstants.recommendedMaxScreenTime ? "Above recommended limit." : "Within healthy range.")

        Health score: \(score)/100. Break compliance: \(compliance)%.

        \(score >= 80 ? "Great performance today!" : "Focus on taking regular breaks to improve your score.")
        """
    }
}
