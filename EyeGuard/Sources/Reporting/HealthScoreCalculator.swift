import Foundation
import os

/// Trend direction for the health score over recent recalculations.
enum ScoreTrend: String, Codable, Sendable {
    case improving
    case stable
    case declining

    /// Arrow symbol for display.
    var symbol: String {
        switch self {
        case .improving: return "↑"
        case .stable:    return "→"
        case .declining: return "↓"
        }
    }

    /// Display label.
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable:    return "Stable"
        case .declining: return "Declining"
        }
    }
}

/// Detailed breakdown of a single score component with explanation text.
struct ScoreComponent: Codable, Sendable {
    let name: String
    let score: Int
    let maxScore: Int
    let explanation: String
}

/// Extended health score with component breakdowns and explanation text.
struct HealthScoreBreakdown: Codable, Sendable {
    let score: HealthScore
    let components: [ScoreComponent]
    let trend: ScoreTrend
    let summaryText: String
}

/// Calculates a daily health score (0-100) based on user break behavior.
///
/// Score breakdown:
/// - Break compliance: 40 pts — percentage of scheduled breaks taken
/// - Continuous use discipline: 30 pts — how well user avoids long stretches
/// - Total screen time: 20 pts — total hours vs recommended max
/// - Break quality: 10 pts — actual break duration vs recommended
struct HealthScoreCalculator: Sendable {

    /// Calculates the health score from today's activity data.
    ///
    /// - Parameters:
    ///   - breakEvents: All break events recorded today.
    ///   - totalScreenTime: Total active screen time in seconds.
    ///   - longestContinuousSession: Longest unbroken usage stretch in seconds.
    /// - Returns: A `HealthScore` with component breakdown.
    func calculate(
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval,
        exerciseSessionsToday: Int = 0
    ) -> HealthScore {
        let compliance = calculateBreakCompliance(breakEvents)
        let discipline = calculateContinuousUseDiscipline(longestContinuousSession)
        let screenTime = calculateScreenTimeScore(totalScreenTime)
        let quality = calculateBreakQuality(breakEvents, exerciseSessions: exerciseSessionsToday)

        return HealthScore(
            breakCompliance: compliance,
            continuousUseDiscipline: discipline,
            screenTimeScore: screenTime,
            breakQuality: quality
        )
    }

    /// Calculates a full breakdown with per-component explanations and trend.
    ///
    /// - Parameters:
    ///   - breakEvents: All break events recorded today.
    ///   - totalScreenTime: Total active screen time in seconds.
    ///   - longestContinuousSession: Longest unbroken usage stretch in seconds.
    ///   - previousScores: Recent score history for trend calculation.
    /// - Returns: A `HealthScoreBreakdown` with component details and trend.
    func calculateBreakdown(
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval,
        previousScores: [Int],
        exerciseSessionsToday: Int = 0
    ) -> HealthScoreBreakdown {
        let score = calculate(
            breakEvents: breakEvents,
            totalScreenTime: totalScreenTime,
            longestContinuousSession: longestContinuousSession,
            exerciseSessionsToday: exerciseSessionsToday
        )

        let complianceExplanation = complianceExplanation(breakEvents)
        let disciplineExplanation = disciplineExplanation(longestContinuousSession)
        let screenTimeExplanation = screenTimeExplanation(totalScreenTime)
        let qualityExplanation = qualityExplanation(breakEvents)

        let components = [
            ScoreComponent(
                name: "Breaks",
                score: score.breakCompliance,
                maxScore: EyeGuardConstants.breakComplianceMaxPoints,
                explanation: complianceExplanation
            ),
            ScoreComponent(
                name: "Discipline",
                score: score.continuousUseDiscipline,
                maxScore: EyeGuardConstants.continuousUseDisciplineMaxPoints,
                explanation: disciplineExplanation
            ),
            ScoreComponent(
                name: "Time",
                score: score.screenTimeScore,
                maxScore: EyeGuardConstants.screenTimeMaxPoints,
                explanation: screenTimeExplanation
            ),
            ScoreComponent(
                name: "Quality",
                score: score.breakQuality,
                maxScore: EyeGuardConstants.breakQualityMaxPoints,
                explanation: qualityExplanation
            ),
        ]

        let trend = calculateTrend(currentScore: score.totalScore, previousScores: previousScores)
        let summaryText = generateSummaryText(score: score.totalScore, trend: trend)

        return HealthScoreBreakdown(
            score: score,
            components: components,
            trend: trend,
            summaryText: summaryText
        )
    }

    // MARK: - Trend Calculation

    /// Determines trend direction from recent score history.
    /// Uses the last 5 scores (or fewer if not enough history).
    func calculateTrend(currentScore: Int, previousScores: [Int]) -> ScoreTrend {
        guard !previousScores.isEmpty else { return .stable }

        let recentScores = Array(previousScores.suffix(5))
        let averagePrevious = Double(recentScores.reduce(0, +)) / Double(recentScores.count)
        let difference = Double(currentScore) - averagePrevious

        if difference > 3.0 {
            return .improving
        } else if difference < -3.0 {
            return .declining
        } else {
            return .stable
        }
    }

    // MARK: - Component Calculations

    /// Break compliance: what percentage of scheduled breaks were taken?
    /// Full score = 100% compliance.
    private func calculateBreakCompliance(_ events: [BreakEvent]) -> Int {
        guard !events.isEmpty else {
            return EyeGuardConstants.breakComplianceMaxPoints
        }

        let taken = events.filter(\.wasTaken).count
        let total = events.count
        let ratio = Double(taken) / Double(total)

        return Int(ratio * Double(EyeGuardConstants.breakComplianceMaxPoints))
    }

    /// Continuous use discipline: penalizes long unbroken stretches.
    /// Full score = never exceeding the mandatory break interval.
    private func calculateContinuousUseDiscipline(_ longestSession: TimeInterval) -> Int {
        let maxAllowed = EyeGuardConstants.mandatoryBreakInterval
        let maxPoints = Double(EyeGuardConstants.continuousUseDisciplineMaxPoints)

        if longestSession <= EyeGuardConstants.microBreakInterval {
            // Perfect: never exceeded 20 minutes
            return EyeGuardConstants.continuousUseDisciplineMaxPoints
        } else if longestSession <= maxAllowed {
            // Proportional deduction
            let ratio = 1.0 - (longestSession - EyeGuardConstants.microBreakInterval)
                / (maxAllowed - EyeGuardConstants.microBreakInterval)
            return Int(max(0, ratio) * maxPoints)
        } else {
            // Exceeded mandatory interval
            return 0
        }
    }

    /// Screen time score: penalizes exceeding recommended daily max (BUG-004 fix).
    /// Full score = under recommended max (8 hours).
    ///
    /// Fixed boundary arithmetic: at exactly the recommended max, score is correctly
    /// calculated without discontinuity.
    private func calculateScreenTimeScore(_ totalTime: TimeInterval) -> Int {
        let recommended = EyeGuardConstants.recommendedMaxScreenTime
        let maxPoints = Double(EyeGuardConstants.screenTimeMaxPoints)

        if totalTime <= 0 {
            return EyeGuardConstants.screenTimeMaxPoints
        } else if totalTime <= recommended * 0.5 {
            // Under half the recommended max — full score
            return EyeGuardConstants.screenTimeMaxPoints
        } else if totalTime < recommended {
            // Between 50% and 100%: linear interpolation from maxPoints down to maxPoints * 0.5
            let fraction = (totalTime - recommended * 0.5) / (recommended * 0.5)
            let score = maxPoints * (1.0 - fraction * 0.5)
            return Int(score)
        } else {
            // At or over recommended max — steep penalty, min 0
            // At exactly recommended: score = maxPoints * 0.5 = 10
            // At 2x recommended: score = 0
            let overFraction = min((totalTime - recommended) / recommended, 1.0)
            let score = maxPoints * 0.5 * (1.0 - overFraction)
            return Int(max(0, score))
        }
    }

    /// Break quality: did the user actually take the full break duration?
    /// Base score caps at 6/10 without exercises. Exercises add up to +4 bonus.
    private func calculateBreakQuality(_ events: [BreakEvent], exerciseSessions: Int = 0) -> Int {
        let maxPoints = EyeGuardConstants.breakQualityMaxPoints
        let baseMax = 6 // Base quality without exercises
        let exerciseBonus = 4 // Bonus for doing exercises

        let takenBreaks = events.filter(\.wasTaken)
        guard !takenBreaks.isEmpty else {
            // No breaks yet — full base score + exercise bonus if applicable
            let bonus = exerciseSessions > 0 ? exerciseBonus : 0
            return min(baseMax + bonus, maxPoints)
        }

        var totalQuality = 0.0
        for event in takenBreaks {
            let recommended = event.type.duration
            let actual = event.actualDuration
            let quality = min(actual / recommended, 1.0)
            totalQuality += quality
        }

        let averageQuality = totalQuality / Double(takenBreaks.count)
        let baseScore = Int(averageQuality * Double(baseMax))
        let bonus = exerciseSessions > 0 ? exerciseBonus : 0
        return min(baseScore + bonus, maxPoints)
    }

    // MARK: - Explanation Text

    private func complianceExplanation(_ events: [BreakEvent]) -> String {
        guard !events.isEmpty else {
            return "No breaks scheduled yet — keep it up!"
        }
        let taken = events.filter(\.wasTaken).count
        let total = events.count
        let percent = Int(Double(taken) / Double(total) * 100)
        return "\(taken)/\(total) breaks taken (\(percent)%)"
    }

    private func disciplineExplanation(_ longestSession: TimeInterval) -> String {
        let minutes = Int(longestSession / 60)
        if longestSession <= EyeGuardConstants.microBreakInterval {
            return "Great! Longest session: \(minutes)min (under 20min)"
        } else if longestSession <= EyeGuardConstants.mandatoryBreakInterval {
            return "Longest session: \(minutes)min — try shorter stretches"
        } else {
            return "Longest session: \(minutes)min — exceeded 2hr limit!"
        }
    }

    private func screenTimeExplanation(_ totalTime: TimeInterval) -> String {
        let hours = Int(totalTime / 3600)
        let minutes = Int((totalTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let recommended = Int(EyeGuardConstants.recommendedMaxScreenTime / 3600)
        if totalTime <= EyeGuardConstants.recommendedMaxScreenTime * 0.5 {
            return "Screen time: \(hours)h \(minutes)m — well under \(recommended)h limit"
        } else if totalTime <= EyeGuardConstants.recommendedMaxScreenTime {
            return "Screen time: \(hours)h \(minutes)m — approaching \(recommended)h limit"
        } else {
            return "Screen time: \(hours)h \(minutes)m — over \(recommended)h limit!"
        }
    }

    private func qualityExplanation(_ events: [BreakEvent]) -> String {
        let takenBreaks = events.filter(\.wasTaken)
        guard !takenBreaks.isEmpty else {
            return "No breaks taken yet to measure quality"
        }
        var totalQuality = 0.0
        for event in takenBreaks {
            let quality = min(event.actualDuration / event.type.duration, 1.0)
            totalQuality += quality
        }
        let avgPercent = Int(totalQuality / Double(takenBreaks.count) * 100)
        return "Average break quality: \(avgPercent)%"
    }

    // MARK: - Summary Text

    private func generateSummaryText(score: Int, trend: ScoreTrend) -> String {
        let trendText: String
        switch trend {
        case .improving: trendText = "and improving"
        case .stable:    trendText = "and stable"
        case .declining: trendText = "but declining"
        }

        switch score {
        case 80...100:
            return "Your eye health is excellent \(trendText)!"
        case 50..<80:
            return "Your eye health is fair \(trendText). Take more breaks."
        case 30..<50:
            return "Your eye health needs attention \(trendText)."
        default:
            return "Your eye health is poor \(trendText). Please take a break!"
        }
    }
}
