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
        let discipline = calculateContinuousUseDiscipline(longestContinuousSession, events: breakEvents)
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
        let disciplineExplanation = disciplineExplanation(longestContinuousSession, events: breakEvents)
        let screenTimeExplanation = screenTimeExplanation(totalScreenTime)
        let qualityExplanation = qualityExplanation(breakEvents, exerciseSessions: exerciseSessionsToday)

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
    /// Uses recency weighting: last 10 breaks count 2x to make recent behavior
    /// more impactful on the score. This gives users faster feedback when they
    /// start taking breaks after skipping several.
    private func calculateBreakCompliance(_ events: [BreakEvent]) -> Int {
        guard !events.isEmpty else {
            return EyeGuardConstants.breakComplianceMaxPoints
        }

        // Recency-weighted: last 10 breaks count double
        let recentCount = min(events.count, 10)
        let recentEvents = events.suffix(recentCount)
        let olderEvents = events.dropLast(recentCount)

        let recentTaken = Double(recentEvents.filter(\.wasTaken).count)
        let recentTotal = Double(recentEvents.count)
        let olderTaken = Double(olderEvents.filter(\.wasTaken).count)
        let olderTotal = Double(olderEvents.count)

        // Recent breaks have 2x weight
        let weightedTaken = recentTaken * 2.0 + olderTaken
        let weightedTotal = recentTotal * 2.0 + olderTotal

        let ratio = weightedTotal > 0 ? weightedTaken / weightedTotal : 1.0

        return Int(ratio * Double(EyeGuardConstants.breakComplianceMaxPoints))
    }

    /// Continuous use discipline: penalizes long unbroken stretches.
    /// Full score = never exceeding the mandatory break interval.
    ///
    /// Recovery: every 3 consecutive successfully-taken breaks at the tail
    /// of the day's history awards +1 recovery point. Skipping a break
    /// resets the streak. Total is capped at the component's max.
    private func calculateContinuousUseDiscipline(_ longestSession: TimeInterval, events: [BreakEvent]) -> Int {
        let baseScore = baseDisciplineScore(longestSession)
        let recovery = disciplineRecoveryPoints(events: events)
        return min(EyeGuardConstants.continuousUseDisciplineMaxPoints, baseScore + recovery)
    }

    private func baseDisciplineScore(_ longestSession: TimeInterval) -> Int {
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

    /// Counts the trailing streak of consecutively-taken breaks and
    /// awards 1 recovery point per `disciplineRecoveryStreakThreshold`
    /// (= 3) in the streak. Returns 0 if no streak (most recent break
    /// was skipped/postponed).
    ///
    /// The streak threshold is a gamification heuristic, not a medical
    /// constant — see `EyeGuardConstants.disciplineRecoveryStreakThreshold`.
    private func disciplineRecoveryPoints(events: [BreakEvent]) -> Int {
        var streak = 0
        for event in events.reversed() {
            if event.wasTaken {
                streak += 1
            } else {
                break
            }
        }
        return streak / EyeGuardConstants.disciplineRecoveryStreakThreshold
    }

    /// Current trailing streak of consecutively-taken breaks (for UI display).
    private func currentTakenStreak(events: [BreakEvent]) -> Int {
        var streak = 0
        for event in events.reversed() {
            if event.wasTaken { streak += 1 } else { break }
        }
        return streak
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
            return "今天还没有安排休息。\n如何拿满:按计划完成休息提醒就行。"
        }
        let taken = events.filter(\.wasTaken).count
        let total = events.count
        let percent = Int(Double(taken) / Double(total) * 100)
        let missed = total - taken
        if missed == 0 {
            return "完成了 \(taken)/\(total) 次休息(100%)。\n保持下去就是满分。"
        }
        return "完成了 \(taken)/\(total) 次休息(\(percent)%),错过 \(missed) 次。\n如何改善:错过的休息无法撤销,但最近 10 次按 2 倍权重计入,所以接下来不再跳过,这一项会较快回升。明日重新计算。"
    }

    private func disciplineExplanation(_ longestSession: TimeInterval, events: [BreakEvent]) -> String {
        let minutes = Int(longestSession / 60)
        let microMin = Int(EyeGuardConstants.microBreakInterval / 60)
        let mandatoryMin = Int(EyeGuardConstants.mandatoryBreakInterval / 60)
        let base = baseDisciplineScore(longestSession)
        let streak = currentTakenStreak(events: events)
        let recovery = streak / 3
        let untilNextRecovery = streak == 0 ? 3 : (3 - streak % 3)

        let header: String
        if longestSession <= EyeGuardConstants.microBreakInterval {
            header = "今天最长一次连续用眼 \(minutes) 分钟,没超过 \(microMin) 分钟,基础分 \(base)/\(EyeGuardConstants.continuousUseDisciplineMaxPoints)。"
        } else if longestSession <= EyeGuardConstants.mandatoryBreakInterval {
            header = "今天最长一次连续用眼 \(minutes) 分钟,超过了 \(microMin) 分钟门槛,基础分 \(base)/\(EyeGuardConstants.continuousUseDisciplineMaxPoints)。"
        } else {
            header = "今天最长一次连续用眼 \(minutes) 分钟,超过了 \(mandatoryMin) 分钟硬性上限,基础分 0。"
        }

        let recoveryLine: String
        if base >= EyeGuardConstants.continuousUseDisciplineMaxPoints {
            recoveryLine = "已是满分,保持下去就好。"
        } else if streak == 0 {
            recoveryLine = "恢复机制:连续 3 次按时完成休息可 +1 分。当前连续完成 0 次(上一次被跳过/推迟,streak 已清零),从下一次开始累计。"
        } else {
            recoveryLine = "恢复机制:连续 3 次按时完成休息可 +1 分。当前已连续完成 \(streak) 次,获得 +\(recovery) 恢复分;再坚持 \(untilNextRecovery) 次可再 +1。跳过任意一次会清零 streak。"
        }

        return header + "\n" + recoveryLine
    }

    private func screenTimeExplanation(_ totalTime: TimeInterval) -> String {
        let hours = Int(totalTime / 3600)
        let minutes = Int((totalTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let recommended = Int(EyeGuardConstants.recommendedMaxScreenTime / 3600)
        if totalTime <= EyeGuardConstants.recommendedMaxScreenTime * 0.5 {
            return "今天屏幕时间 \(hours)h \(minutes)m,远低于推荐上限 \(recommended)h。\n保持下去就是满分。"
        } else if totalTime <= EyeGuardConstants.recommendedMaxScreenTime {
            return "今天屏幕时间 \(hours)h \(minutes)m,接近推荐上限 \(recommended)h,得分按比例衰减。\n这一项今天只会下降不会回升:已累计的时间不会清零。\n避免变更糟:今天减少屏幕时间,明日重新计算。"
        } else {
            return "今天屏幕时间 \(hours)h \(minutes)m,超过推荐上限 \(recommended)h。\n这一项今天已锁定,无法恢复。\n建议:今天剩下时间多远眺/休息,明日注意控制总时长。"
        }
    }

    private func qualityExplanation(_ events: [BreakEvent], exerciseSessions: Int = 0) -> String {
        let baseMax = 6
        let exerciseBonus = 4
        let takenBreaks = events.filter(\.wasTaken)
        let didExercise = exerciseSessions > 0

        // Base portion (休息时长是否做满) — 取所有已完成休息的平均,过去做短了的休息没法回退
        let baseScore: Int
        let baseLine: String
        if takenBreaks.isEmpty {
            baseScore = baseMax
            baseLine = "基础分 \(baseMax)/\(baseMax):还没完成休息,默认按满分计。"
        } else {
            var totalQuality = 0.0
            for event in takenBreaks {
                totalQuality += min(event.actualDuration / event.type.duration, 1.0)
            }
            let avg = totalQuality / Double(takenBreaks.count)
            baseScore = Int(avg * Double(baseMax))
            let avgPercent = Int(avg * 100)
            if baseScore >= baseMax {
                baseLine = "基础分 \(baseScore)/\(baseMax):休息时长平均 \(avgPercent)%,已拿满。"
            } else {
                baseLine = "基础分 \(baseScore)/\(baseMax):休息时长平均只有 \(avgPercent)%,过去提前关掉的休息无法补回。\n→ 接下来:倒计时走完再回去工作,这一项的均值会逐步上升。"
            }
        }

        // Bonus portion (是否做眼保健操) — 这部分今天就能补回来
        let bonusLine: String
        if didExercise {
            bonusLine = "眼保健操奖励 +\(exerciseBonus)/+\(exerciseBonus):今天已完成 \(exerciseSessions) 次,已拿到。"
        } else {
            bonusLine = "眼保健操奖励 +0/+\(exerciseBonus):今天还没做。\n→ 今天就能补:从托盘菜单的「眼保健操」入口完成 1 次,这 4 分立刻补回。"
        }

        return "Quality = 基础分(最多 \(baseMax)) + 眼保健操奖励(0 或 +\(exerciseBonus))\n\n" + baseLine + "\n\n" + bonusLine
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
