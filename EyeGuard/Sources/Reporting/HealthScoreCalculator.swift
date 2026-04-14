import Foundation

/// Calculates a daily health score (0-100) based on user break behavior.
///
/// Score breakdown:
/// - Break compliance: 40 pts — percentage of scheduled breaks taken
/// - Continuous use discipline: 30 pts — how well user avoids long stretches
/// - Total screen time: 20 pts — total hours vs recommended max
/// - Break quality: 10 pts — actual break duration vs recommended
struct HealthScoreCalculator {

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
        longestContinuousSession: TimeInterval
    ) -> HealthScore {
        let compliance = calculateBreakCompliance(breakEvents)
        let discipline = calculateContinuousUseDiscipline(longestContinuousSession)
        let screenTime = calculateScreenTimeScore(totalScreenTime)
        let quality = calculateBreakQuality(breakEvents)

        return HealthScore(
            breakCompliance: compliance,
            continuousUseDiscipline: discipline,
            screenTimeScore: screenTime,
            breakQuality: quality
        )
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

    /// Screen time score: penalizes exceeding recommended daily max.
    /// Full score = under recommended max (8 hours).
    private func calculateScreenTimeScore(_ totalTime: TimeInterval) -> Int {
        let recommended = EyeGuardConstants.recommendedMaxScreenTime
        let maxPoints = Double(EyeGuardConstants.screenTimeMaxPoints)

        if totalTime <= recommended * 0.5 {
            // Under half the recommended max
            return EyeGuardConstants.screenTimeMaxPoints
        } else if totalTime <= recommended {
            // Proportional between 50% and 100%
            let ratio = 1.0 - (totalTime - recommended * 0.5) / (recommended * 0.5)
            return Int(ratio * maxPoints * 0.5) + Int(maxPoints * 0.5)
        } else {
            // Over recommended max — steep penalty
            let overRatio = min(totalTime / recommended, 2.0)
            let score = maxPoints * max(0, 1.0 - (overRatio - 1.0) * 2.0)
            return Int(max(0, score))
        }
    }

    /// Break quality: did the user actually take the full break duration?
    /// Full score = all taken breaks met recommended duration.
    private func calculateBreakQuality(_ events: [BreakEvent]) -> Int {
        let takenBreaks = events.filter(\.wasTaken)
        guard !takenBreaks.isEmpty else {
            return EyeGuardConstants.breakQualityMaxPoints
        }

        var totalQuality = 0.0
        for event in takenBreaks {
            let recommended = event.type.duration
            let actual = event.actualDuration
            let quality = min(actual / recommended, 1.0)
            totalQuality += quality
        }

        let averageQuality = totalQuality / Double(takenBreaks.count)
        return Int(averageQuality * Double(EyeGuardConstants.breakQualityMaxPoints))
    }
}
