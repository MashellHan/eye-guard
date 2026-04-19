import Foundation
import os

/// Generates daily Markdown reports summarizing eye health metrics.
///
/// Reports are saved to `~/EyeGuard/reports/YYYY-MM-DD.md`.
/// All file I/O is performed asynchronously.
///
/// Features (v0.7):
/// - Hourly activity breakdown table
/// - Break compliance statistics
/// - Longest continuous session tracking
/// - Personalized recommendations based on score components
/// - Detailed break event log
struct DailyReportGenerator: Sendable {

    private let calculator = HealthScoreCalculator()

    /// Generates and saves a daily report for the given data.
    ///
    /// File I/O is performed on a background thread via async (v0.2).
    /// Includes AI-powered insights section (v1.8).
    ///
    /// - Parameters:
    ///   - date: The date of the report.
    ///   - sessions: Usage sessions for the day.
    ///   - breakEvents: All break events for the day.
    ///   - totalScreenTime: Total active screen time in seconds.
    ///   - longestContinuousSession: Longest unbroken session in seconds.
    /// - Returns: The generated `DailyReport` struct.
    func generate(
        date: Date = .now,
        sessions: [UsageSession],
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval
    ) async -> DailyReport {
        let healthScore = calculator.calculate(
            breakEvents: breakEvents,
            totalScreenTime: totalScreenTime,
            longestContinuousSession: longestContinuousSession
        )

        let takenCount = breakEvents.filter(\.wasTaken).count
        let report = DailyReport(
            date: date,
            sessions: sessions,
            healthScore: healthScore,
            totalScreenTime: totalScreenTime,
            totalBreaksTaken: takenCount,
            totalBreaksScheduled: breakEvents.count
        )

        // Generate AI insights for the report (v1.8)
        let insightGenerator = InsightGenerator()
        let aiInsights = await insightGenerator.generateReportInsights(report: report)

        await saveMarkdownReport(
            report,
            date: date,
            breakEvents: breakEvents,
            longestContinuousSession: longestContinuousSession,
            aiInsights: aiInsights
        )
        return report
    }

    /// Generates the Markdown content without saving (for preview / testing).
    func generateMarkdownContent(
        date: Date = .now,
        sessions: [UsageSession],
        breakEvents: [BreakEvent],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval
    ) -> String {
        let healthScore = calculator.calculate(
            breakEvents: breakEvents,
            totalScreenTime: totalScreenTime,
            longestContinuousSession: longestContinuousSession
        )

        let takenCount = breakEvents.filter(\.wasTaken).count
        let report = DailyReport(
            date: date,
            sessions: sessions,
            healthScore: healthScore,
            totalScreenTime: totalScreenTime,
            totalBreaksTaken: takenCount,
            totalBreaksScheduled: breakEvents.count
        )

        return renderMarkdown(
            report,
            date: date,
            breakEvents: breakEvents,
            longestContinuousSession: longestContinuousSession
        )
    }

    // MARK: - Markdown Generation

    /// Saves the report as a Markdown file on a background thread.
    private func saveMarkdownReport(
        _ report: DailyReport,
        date: Date,
        breakEvents: [BreakEvent],
        longestContinuousSession: TimeInterval,
        aiInsights: String = ""
    ) async {
        let markdown = renderMarkdown(
            report,
            date: date,
            breakEvents: breakEvents,
            longestContinuousSession: longestContinuousSession,
            aiInsights: aiInsights
        )
        let fileName = "\(report.dateString).md"
        let fileURL = EyeGuardConstants.reportsDirectory.appendingPathComponent(fileName)

        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            Log.report.info("Report saved: \(fileURL.path)")
        } catch {
            Log.report.error("Failed to save report: \(error.localizedDescription)")
        }
    }

    /// Renders a `DailyReport` as a comprehensive Markdown string (v0.7, v1.8).
    private func renderMarkdown(
        _ report: DailyReport,
        date: Date,
        breakEvents: [BreakEvent],
        longestContinuousSession: TimeInterval,
        aiInsights: String = ""
    ) -> String {
        let dateFormatter = TimeFormatting.longDateFormatter

        let score = report.healthScore
        let screenTimeStr = TimeFormatting.formatDuration(report.totalScreenTime)

        var sections: [String] = []

        // Title
        sections.append("# \(healthEmoji(score.totalScore)) EyeGuard Daily Report")
        sections.append("")
        sections.append("> \(dateFormatter.string(from: date))")

        // --- Executive Summary (NEW) ---
        sections.append("")
        sections.append("## \u{1F4DD} Executive Summary")
        sections.append("")
        sections.append(
            renderExecutiveSummary(
                report: report,
                breakEvents: breakEvents,
                longestContinuousSession: longestContinuousSession
            )
        )

        // --- Daily Summary ---
        sections.append("")
        sections.append("## \u{1F4CA} Daily Summary")
        sections.append("")
        sections.append("| Metric | Value |")
        sections.append("|--------|-------|")
        sections.append("| **Date** | \(dateFormatter.string(from: date)) |")
        sections.append("| **Total Screen Time** | \(screenTimeStr) |")
        sections.append("| **Health Score** | \(score.totalScore)/100 \(healthEmoji(score.totalScore)) |")
        sections.append("| **Breaks Taken** | \(report.totalBreaksTaken) / \(report.totalBreaksScheduled) |")
        sections.append("| **Sessions** | \(report.sessions.count) |")
        sections.append("| **Longest Session** | \(TimeFormatting.formatDuration(longestContinuousSession)) |")
        sections.append("")
        sections.append("### Score Breakdown")
        sections.append("")
        sections.append("| Component | Score | Max | Bar |")
        sections.append("|-----------|-------|-----|-----|")
        sections.append(
            "| Break Compliance | \(score.breakCompliance) | 40 | \(renderBar(score.breakCompliance, max: 40)) |"
        )
        sections.append(
            "| Continuous Use Discipline | \(score.continuousUseDiscipline) | 30 | \(renderBar(score.continuousUseDiscipline, max: 30)) |"
        )
        sections.append(
            "| Screen Time | \(score.screenTimeScore) | 20 | \(renderBar(score.screenTimeScore, max: 20)) |"
        )
        sections.append(
            "| Break Quality | \(score.breakQuality) | 10 | \(renderBar(score.breakQuality, max: 10)) |"
        )
        sections.append(
            "| **Total** | **\(score.totalScore)** | **100** | \(renderBar(score.totalScore, max: 100)) |"
        )

        // --- Hourly Breakdown ---
        sections.append("")
        sections.append("## \u{1F4C8} Hourly Breakdown")
        sections.append("")
        sections.append(renderHourlyBreakdown(breakEvents: breakEvents, sessions: report.sessions))

        // --- Break Compliance ---
        sections.append("")
        sections.append("## \u{1F504} Break Compliance")
        sections.append("")
        sections.append(renderBreakCompliance(breakEvents: breakEvents))

        // --- Longest Continuous Session ---
        sections.append("")
        sections.append("## \u{1F3C6} Longest Continuous Session")
        sections.append("")
        sections.append(
            renderLongestSession(longestContinuousSession: longestContinuousSession)
        )

        // --- Personalized Recommendations ---
        sections.append("")
        sections.append("## \u{1F4A1} Personalized Recommendations")
        sections.append("")
        sections.append(generateRecommendations(score))

        // --- Detailed Break Log ---
        sections.append("")
        sections.append("## \u{1F4CB} Detailed Break Log")
        sections.append("")
        sections.append(renderDetailedBreakLog(breakEvents: breakEvents))

        // --- Session Deep Dive (NEW) ---
        sections.append("")
        sections.append("## \u{1F50E} Session Deep Dive")
        sections.append("")
        sections.append(renderSessionDeepDive(sessions: report.sessions))

        // --- Behavioral Insights (NEW) ---
        sections.append("")
        sections.append("## \u{1F9E0} Behavioral Insights")
        sections.append("")
        sections.append(
            renderBehavioralInsights(
                breakEvents: breakEvents,
                sessions: report.sessions,
                totalScreenTime: report.totalScreenTime,
                longestContinuousSession: longestContinuousSession
            )
        )

        // --- Tomorrow's Action Plan (NEW) ---
        sections.append("")
        sections.append("## \u{1F3AF} Tomorrow's Action Plan")
        sections.append("")
        sections.append(
            renderActionPlan(
                score: score,
                breakEvents: breakEvents,
                longestContinuousSession: longestContinuousSession
            )
        )

        // --- AI Insights (v1.8) ---
        if !aiInsights.isEmpty {
            sections.append("")
            sections.append("## \u{1F916} AI Insights")
            sections.append("")
            sections.append(aiInsights)
        }

        // --- Hourly Pattern Analysis (v1.8) ---
        let insightGen = InsightGenerator()
        let patterns = insightGen.analyzeHourlyPatterns(breakEvents: breakEvents)
        sections.append("")
        sections.append("## \u{1F50D} Pattern Analysis")
        sections.append("")
        sections.append("| Pattern | Detail |")
        sections.append("|---------|--------|")
        sections.append("| **Best Hour** | \(patterns.best) |")
        sections.append("| **Worst Hour** | \(patterns.worst) |")

        // --- Tip of the Day (v1.3) ---
        sections.append("")
        sections.append("## \u{1F4A1} Tip of the Day")
        sections.append("")
        sections.append(renderTipOfTheDay(date: date))

        // Footer
        sections.append("")
        sections.append("---")
        sections.append("")
        sections.append("*Generated by EyeGuard on \(dateFormatter.string(from: .now))*")

        return sections.joined(separator: "\n")
    }

    // MARK: - Section Renderers

    /// Renders a visual progress bar using block characters.
    private func renderBar(_ value: Int, max: Int) -> String {
        let total = 10
        let filled = max > 0 ? (value * total) / max : 0
        let empty = total - filled
        return String(repeating: "\u{2588}", count: filled)
            + String(repeating: "\u{2591}", count: empty)
    }

    /// Renders an hourly activity breakdown table.
    private func renderHourlyBreakdown(
        breakEvents: [BreakEvent],
        sessions: [UsageSession]
    ) -> String {
        var lines: [String] = []
        lines.append("| Hour | Breaks Taken | Breaks Skipped | Activity |")
        lines.append("|------|-------------|----------------|----------|")

        let calendar = Calendar.current

        for hour in 0..<24 {
            let hourBreaks = breakEvents.filter { event in
                calendar.component(.hour, from: event.timestamp) == hour
            }

            guard !hourBreaks.isEmpty else { continue }

            let taken = hourBreaks.filter(\.wasTaken).count
            let skipped = hourBreaks.filter { !$0.wasTaken }.count
            let bar = renderActivityBar(taken: taken, skipped: skipped)
            let hourLabel = String(format: "%02d:00", hour)

            lines.append("| \(hourLabel) | \(taken) | \(skipped) | \(bar) |")
        }

        if lines.count <= 2 {
            lines.append("| — | No activity recorded | — | — |")
        }

        return lines.joined(separator: "\n")
    }

    /// Renders a small activity bar for the hourly table.
    private func renderActivityBar(taken: Int, skipped: Int) -> String {
        let takenSymbols = String(repeating: "\u{2705}", count: min(taken, 5))
        let skippedSymbols = String(repeating: "\u{274C}", count: min(skipped, 5))
        return takenSymbols + skippedSymbols
    }

    /// Renders break compliance statistics.
    private func renderBreakCompliance(breakEvents: [BreakEvent]) -> String {
        let taken = breakEvents.filter(\.wasTaken).count
        let total = breakEvents.count
        let compliancePercent = total > 0 ? Int(Double(taken) / Double(total) * 100) : 100

        var lines: [String] = []
        lines.append("| Metric | Value |")
        lines.append("|--------|-------|")
        lines.append("| Breaks Suggested | \(total) |")
        lines.append("| Breaks Taken | \(taken) |")
        lines.append("| Breaks Skipped | \(total - taken) |")
        lines.append("| Compliance Rate | \(compliancePercent)% |")

        // Per-type breakdown
        lines.append("")
        lines.append("### By Type")
        lines.append("")
        lines.append("| Type | Taken | Skipped | Rate |")
        lines.append("|------|-------|---------|------|")

        for breakType in BreakType.allCases {
            let typeEvents = breakEvents.filter { $0.type == breakType }
            guard !typeEvents.isEmpty else { continue }
            let typeTaken = typeEvents.filter(\.wasTaken).count
            let typeSkipped = typeEvents.count - typeTaken
            let typeRate = Int(Double(typeTaken) / Double(typeEvents.count) * 100)
            lines.append(
                "| \(breakType.displayName) | \(typeTaken) | \(typeSkipped) | \(typeRate)% |"
            )
        }

        return lines.joined(separator: "\n")
    }

    /// Renders the longest continuous session section.
    private func renderLongestSession(longestContinuousSession: TimeInterval) -> String {
        let duration = TimeFormatting.formatDuration(longestContinuousSession)
        let minutes = Int(longestContinuousSession / 60)
        let mandatoryMinutes = Int(EyeGuardConstants.mandatoryBreakInterval / 60)

        var lines: [String] = []
        lines.append("**Duration**: \(duration)")
        lines.append("")

        if longestContinuousSession <= EyeGuardConstants.microBreakInterval {
            lines.append(
                "> \u{1F31F} Excellent! You never exceeded the 20-minute micro-break interval."
            )
        } else if longestContinuousSession <= EyeGuardConstants.macroBreakInterval {
            lines.append(
                "> \u{1F44D} Good. Your longest stretch was \(minutes) minutes. Try to stay under 20 minutes for optimal eye health."
            )
        } else if longestContinuousSession <= EyeGuardConstants.mandatoryBreakInterval {
            lines.append(
                "> \u{26A0}\u{FE0F} Your longest session was \(minutes) minutes. Consider taking more frequent breaks."
            )
        } else {
            lines.append(
                "> \u{274C} You exceeded the \(mandatoryMinutes)-minute mandatory break threshold (\(minutes) min). Please prioritize breaks tomorrow."
            )
        }

        return lines.joined(separator: "\n")
    }

    /// Renders the detailed break log table.
    private func renderDetailedBreakLog(breakEvents: [BreakEvent]) -> String {
        if breakEvents.isEmpty {
            return "*No breaks recorded today.*"
        }

        let timeFormatter = TimeFormatting.timeFormatter

        var lines: [String] = []
        lines.append("| # | Time | Type | Status | Duration |")
        lines.append("|---|------|------|--------|----------|")

        for (index, event) in breakEvents.enumerated() {
            let time = timeFormatter.string(from: event.timestamp)
            let status = event.wasTaken ? "\u{2705} Taken" : "\u{274C} Skipped"
            let duration =
                event.wasTaken
                ? TimeFormatting.formatDuration(event.actualDuration)
                : "\u{2014}"
            lines.append(
                "| \(index + 1) | \(time) | \(event.type.displayName) | \(status) | \(duration) |"
            )
        }

        return lines.joined(separator: "\n")
    }

    /// Generates personalized recommendations based on score components.
    private func generateRecommendations(_ score: HealthScore) -> String {
        var recommendations: [String] = []

        // Break compliance recommendations
        if score.breakCompliance < 10 {
            recommendations.append(
                "- \u{1F534} **Critical**: You're skipping almost all breaks. Enable notification sounds and set break reminders to urgent mode."
            )
        } else if score.breakCompliance < 20 {
            recommendations.append(
                "- \u{1F7E0} **Important**: Your break compliance is low. Try to take at least every other break. Even a 20-second pause helps your eyes."
            )
        } else if score.breakCompliance < 30 {
            recommendations.append(
                "- \u{1F7E1} **Suggestion**: Take more breaks when notified. Aim for 80%+ compliance for healthy eyes."
            )
        }

        // Continuous use discipline recommendations
        if score.continuousUseDiscipline < 10 {
            recommendations.append(
                "- \u{1F534} **Critical**: You're working in very long unbroken stretches. Stand up and walk around at least every 2 hours."
            )
        } else if score.continuousUseDiscipline < 20 {
            recommendations.append(
                "- \u{1F7E0} **Important**: Avoid long unbroken sessions. The 20-20-20 rule works best with regular short breaks."
            )
        }

        // Screen time recommendations
        if score.screenTimeScore < 5 {
            recommendations.append(
                "- \u{1F534} **Critical**: Your screen time is far above the recommended 8 hours. Consider scheduling screen-free activities."
            )
        } else if score.screenTimeScore < 10 {
            recommendations.append(
                "- \u{1F7E0} **Important**: Your screen time is approaching unhealthy levels. Try to wrap up work and take breaks."
            )
        } else if score.screenTimeScore < 15 {
            recommendations.append(
                "- \u{1F7E1} **Suggestion**: Consider reducing total screen time. Aim for under 8 hours for optimal eye health."
            )
        }

        // Break quality recommendations (base max is 6/10 without exercises, 10/10 with)
        if score.breakQuality < 3 {
            recommendations.append(
                "- \u{1F7E0} **Important**: Your breaks are too short. When you take a break, look at something 20 feet away for the full recommended duration."
            )
        } else if score.breakQuality < 5 {
            recommendations.append(
                "- \u{1F7E1} **Suggestion**: When you take a break, make it count. Look away from the screen for the full duration."
            )
        }

        if recommendations.isEmpty {
            return "\u{2728} **Great job!** Keep maintaining your healthy screen habits. Your eye health score is excellent."
        }

        return recommendations.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func healthEmoji(_ score: Int) -> String {
        switch score {
        case 80...100: return "\u{1F7E2}"
        case 60..<80: return "\u{1F7E1}"
        case 40..<60: return "\u{1F7E0}"
        default: return "\u{1F534}"
        }
    }

    // MARK: - Rich Analysis Sections

    /// Renders an at-a-glance executive summary with grade, headline, and bullet highlights.
    private func renderExecutiveSummary(
        report: DailyReport,
        breakEvents: [BreakEvent],
        longestContinuousSession: TimeInterval
    ) -> String {
        let score = report.healthScore.totalScore
        let grade = letterGrade(score)
        let headline = headline(for: score)
        let taken = breakEvents.filter(\.wasTaken).count
        let total = breakEvents.count
        let compliancePct = total > 0 ? Int(Double(taken) / Double(total) * 100) : 100
        let screenHours = report.totalScreenTime / 3600
        let longestMin = Int(longestContinuousSession / 60)

        var lines: [String] = []
        lines.append("> **\(grade) — \(headline)**")
        lines.append("")
        lines.append("**Today at a glance:**")
        lines.append(
            "- \(scoreEmoji(score)) Health Score **\(score)/100** (Grade \(grade))"
        )
        lines.append(
            "- \u{1F5A5}\u{FE0F} Screen time: **\(String(format: "%.1f", screenHours))h** across **\(report.sessions.count)** session(s)"
        )
        lines.append(
            "- \u{1F504} Break compliance: **\(compliancePct)%** (\(taken)/\(total))"
        )
        lines.append(
            "- \u{23F1}\u{FE0F} Longest unbroken stretch: **\(longestMin) min**"
        )
        lines.append("")
        lines.append("**Bottom line:** \(bottomLine(score: score, compliance: compliancePct, longestMin: longestMin, screenHours: screenHours))")
        return lines.joined(separator: "\n")
    }

    private func letterGrade(_ score: Int) -> String {
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }

    private func headline(for score: Int) -> String {
        switch score {
        case 90...100: return "Excellent eye-care discipline today"
        case 80..<90: return "Strong day with room to fine-tune"
        case 70..<80: return "Decent — but a few habits need attention"
        case 60..<70: return "Mixed day — momentum is slipping"
        case 40..<60: return "Concerning — your eyes worked too hard"
        default: return "Critical — please prioritize recovery"
        }
    }

    private func scoreEmoji(_ score: Int) -> String {
        score >= 80 ? "\u{1F4AA}" : (score >= 60 ? "\u{1F44C}" : "\u{1F6A8}")
    }

    private func bottomLine(score: Int, compliance: Int, longestMin: Int, screenHours: Double) -> String {
        var notes: [String] = []
        if compliance >= 80 { notes.append("you honored your breaks") }
        else if compliance >= 50 { notes.append("you took some breaks but skipped many") }
        else { notes.append("you skipped most break prompts") }

        if longestMin > 90 { notes.append("with one stretch over 90 minutes") }
        else if longestMin > 45 { notes.append("with stretches up to \(longestMin) min") }

        if screenHours > 9 { notes.append("on heavy screen-time (>9h)") }
        else if screenHours > 6 { notes.append("on moderate screen-time") }

        let trailing = score >= 80
            ? " Keep this rhythm tomorrow."
            : (score >= 60 ? " Tighten the gaps and you'll see immediate gains." : " A reset day tomorrow would help your eyes recover.")
        let combined = notes.joined(separator: ", ")
        let capitalized = combined.prefix(1).uppercased() + combined.dropFirst()
        return capitalized + "." + trailing
    }

    /// Per-session breakdown with start, end, duration, and breaks contained.
    private func renderSessionDeepDive(sessions: [UsageSession]) -> String {
        guard !sessions.isEmpty else {
            return "*No sessions recorded today.*"
        }
        let timeFmt = TimeFormatting.timeFormatter
        var lines: [String] = []
        lines.append("| # | Start | End | Duration | Notes |")
        lines.append("|---|-------|-----|----------|-------|")
        for (idx, s) in sessions.enumerated() {
            let dur = sessionDuration(s)
            let start = timeFmt.string(from: s.startTime)
            let end = s.endTime.map(timeFmt.string(from:)) ?? "ongoing"
            let durStr = TimeFormatting.formatDuration(dur)
            let note: String
            switch dur {
            case ..<(20 * 60): note = "\u{2705} Short session"
            case (20 * 60)..<(60 * 60): note = "\u{1F44D} Healthy"
            case (60 * 60)..<(120 * 60): note = "\u{26A0}\u{FE0F} Long"
            default: note = "\u{274C} Marathon"
            }
            lines.append("| \(idx + 1) | \(start) | \(end) | \(durStr) | \(note) |")
        }

        // Aggregate stats
        let durations = sessions.map { sessionDuration($0) }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let medianDuration = median(of: durations)
        lines.append("")
        lines.append("**Average session**: \(TimeFormatting.formatDuration(avgDuration))  ")
        lines.append("**Median session**: \(TimeFormatting.formatDuration(medianDuration))  ")
        lines.append("**Total sessions**: \(sessions.count)")
        return lines.joined(separator: "\n")
    }

    private func median(of values: [TimeInterval]) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    /// Behavioral analysis: streaks, drop-offs, peak fatigue periods.
    private func renderBehavioralInsights(
        breakEvents: [BreakEvent],
        sessions: [UsageSession],
        totalScreenTime: TimeInterval,
        longestContinuousSession: TimeInterval
    ) -> String {
        var lines: [String] = []

        // Skip streak: longest run of consecutive skipped breaks
        var currentStreak = 0
        var longestSkipStreak = 0
        var currentTakenStreak = 0
        var longestTakenStreak = 0
        for event in breakEvents.sorted(by: { $0.timestamp < $1.timestamp }) {
            if event.wasTaken {
                currentTakenStreak += 1
                longestTakenStreak = max(longestTakenStreak, currentTakenStreak)
                currentStreak = 0
            } else {
                currentStreak += 1
                longestSkipStreak = max(longestSkipStreak, currentStreak)
                currentTakenStreak = 0
            }
        }

        // Time-of-day pattern
        let calendar = Calendar.current
        var morningSkip = 0, morningTaken = 0
        var afternoonSkip = 0, afternoonTaken = 0
        var eveningSkip = 0, eveningTaken = 0
        for event in breakEvents {
            let hour = calendar.component(.hour, from: event.timestamp)
            switch hour {
            case 0..<12:
                event.wasTaken ? (morningTaken += 1) : (morningSkip += 1)
            case 12..<18:
                event.wasTaken ? (afternoonTaken += 1) : (afternoonSkip += 1)
            default:
                event.wasTaken ? (eveningTaken += 1) : (eveningSkip += 1)
            }
        }

        lines.append("### Streaks")
        lines.append("")
        lines.append("- \u{1F525} Longest **taken-break streak**: **\(longestTakenStreak)** in a row")
        lines.append("- \u{1F4A4} Longest **skipped-break streak**: **\(longestSkipStreak)** in a row")
        lines.append("")
        lines.append("### Time-of-Day Pattern")
        lines.append("")
        lines.append("| Period | Taken | Skipped | Compliance |")
        lines.append("|--------|-------|---------|------------|")
        lines.append(periodRow(name: "Morning (00–12)", taken: morningTaken, skipped: morningSkip))
        lines.append(periodRow(name: "Afternoon (12–18)", taken: afternoonTaken, skipped: afternoonSkip))
        lines.append(periodRow(name: "Evening (18–24)", taken: eveningTaken, skipped: eveningSkip))

        lines.append("")
        lines.append("### Key Observations")
        lines.append("")
        if longestSkipStreak >= 3 {
            lines.append("- \u{26A0}\u{FE0F} You skipped **\(longestSkipStreak) breaks in a row** — that's a danger zone for eye fatigue. Consider escalating those reminders.")
        }
        if longestTakenStreak >= 5 {
            lines.append("- \u{2728} You held a streak of **\(longestTakenStreak) consecutive breaks** — that's the kind of rhythm you want to repeat.")
        }
        let weakest = weakestPeriod(
            morning: (morningTaken, morningSkip),
            afternoon: (afternoonTaken, afternoonSkip),
            evening: (eveningTaken, eveningSkip)
        )
        if let w = weakest {
            lines.append("- \u{1F50D} Your weakest period was **\(w)** — focus your attention there tomorrow.")
        }
        let avgSession = sessions.isEmpty ? 0 : totalScreenTime / Double(sessions.count)
        if avgSession > 60 * 60 {
            lines.append("- \u{1F551} Your average session was **\(Int(avgSession / 60)) min** — try splitting work into focused 45-min blocks.")
        }
        if longestContinuousSession > EyeGuardConstants.mandatoryBreakInterval {
            lines.append("- \u{1F6A8} You exceeded the mandatory break threshold — set a hard stop tomorrow.")
        }
        if lines.last == "" || lines.last == "### Key Observations" {
            lines.append("- \u{1F44D} No alarming patterns detected. Maintain the rhythm.")
        }

        return lines.joined(separator: "\n")
    }

    private func periodRow(name: String, taken: Int, skipped: Int) -> String {
        let total = taken + skipped
        let pct = total > 0 ? Int(Double(taken) / Double(total) * 100) : 0
        let display = total > 0 ? "\(pct)%" : "—"
        return "| \(name) | \(taken) | \(skipped) | \(display) |"
    }

    private func weakestPeriod(
        morning: (Int, Int),
        afternoon: (Int, Int),
        evening: (Int, Int)
    ) -> String? {
        func rate(_ p: (Int, Int)) -> Double? {
            let total = p.0 + p.1
            guard total > 0 else { return nil }
            return Double(p.0) / Double(total)
        }
        let entries: [(String, Double)] = [
            ("morning", rate(morning) ?? 1.1),
            ("afternoon", rate(afternoon) ?? 1.1),
            ("evening", rate(evening) ?? 1.1)
        ].filter { $0.1 < 1.1 }
        return entries.min(by: { $0.1 < $1.1 })?.0
    }

    /// Concrete, prioritized actions for tomorrow.
    private func renderActionPlan(
        score: HealthScore,
        breakEvents: [BreakEvent],
        longestContinuousSession: TimeInterval
    ) -> String {
        var actions: [(priority: Int, text: String)] = []

        if score.breakCompliance < 30 {
            actions.append((1, "**Top priority** — set break reminders to *escalation* mode and commit to taking the next 5 in a row."))
        }
        if longestContinuousSession > EyeGuardConstants.mandatoryBreakInterval {
            actions.append((1, "**Hard cap** — schedule a calendar block at the 90-min mark to force a stand-up break."))
        }
        if score.continuousUseDiscipline < 20 {
            actions.append((2, "**Discipline drill** — practice the 20-20-20 rule on a timer for the first 2 hours of work tomorrow."))
        }
        if score.screenTimeScore < 10 {
            actions.append((2, "**Reduce screen load** — pick one meeting or task to do off-screen (paper notes, walking call)."))
        }
        if score.breakQuality < 5 {
            actions.append((3, "**Better breaks** — when prompted, look at something **20 feet away for 20 seconds**, no phone."))
        }

        // Always-include positive habit
        actions.append((3, "**Hydration check** — 1 glass of water at every break. Helps blink rate and focus."))
        actions.append((3, "**End-of-day ritual** — a 2-minute palming exercise once you wrap up to discharge eye fatigue."))

        let sorted = actions.sorted { $0.priority < $1.priority }
        var lines: [String] = []
        lines.append("**Do these tomorrow, in order:**")
        lines.append("")
        for (i, action) in sorted.enumerated() {
            let icon = action.priority == 1 ? "\u{1F534}" : (action.priority == 2 ? "\u{1F7E0}" : "\u{1F7E2}")
            lines.append("\(i + 1). \(icon) \(action.text)")
        }
        return lines.joined(separator: "\n")
    }

    private func legacyHealthEmojiPlaceholder(_ score: Int) -> String { "" }

    /// Returns session duration: endTime - startTime, or 0 if still ongoing.
    private func sessionDuration(_ s: UsageSession) -> TimeInterval {
        guard let end = s.endTime else { return 0 }
        return end.timeIntervalSince(s.startTime)
    }

    /// Renders the Tip of the Day section using `TipDatabase` (v1.3).
    private func renderTipOfTheDay(date: Date) -> String {
        let tip = TipDatabase.tipOfTheDay(for: date)
        var lines: [String] = []
        lines.append("> **\(tip.title)**")
        lines.append("> \(tip.titleChinese)")
        lines.append(">")
        lines.append("> \(tip.description)")
        lines.append(">")
        lines.append("> *Source: \(tip.source)*")
        return lines.joined(separator: "\n")
    }
}
