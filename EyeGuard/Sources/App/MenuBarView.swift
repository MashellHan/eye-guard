import SwiftUI

/// Menu bar popover view showing session status, controls, health score gauge, and quick stats.
struct MenuBarView: View {
    @Bindable var scheduler: BreakScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            healthScoreSection
            Divider()
            timerSection
            Divider()
            controlsSection
            Divider()
            statsSection
            Divider()
            insightSection
            Divider()
            reportSection
            Divider()
            footerSection
        }
        .padding()
        .frame(width: 300)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("EyeGuard")
                .font(.headline)
            Spacer()
            statusBadge
        }
    }

    private var healthScoreSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Eye Health Score")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                trendIndicator
            }

            HStack(spacing: 16) {
                // Circular gauge
                HealthScoreGauge(score: scheduler.currentHealthScore)

                // Component breakdown
                VStack(alignment: .leading, spacing: 3) {
                    breakdownRow(
                        label: "Breaks",
                        score: scheduler.currentBreakdown?.score.breakCompliance
                            ?? scheduler.currentHealthScore * 40 / 100,
                        maxScore: 40
                    )
                    breakdownRow(
                        label: "Discipline",
                        score: scheduler.currentBreakdown?.score.continuousUseDiscipline
                            ?? scheduler.currentHealthScore * 30 / 100,
                        maxScore: 30
                    )
                    breakdownRow(
                        label: "Time",
                        score: scheduler.currentBreakdown?.score.screenTimeScore
                            ?? scheduler.currentHealthScore * 20 / 100,
                        maxScore: 20
                    )
                    breakdownRow(
                        label: "Quality",
                        score: scheduler.currentBreakdown?.score.breakQuality
                            ?? scheduler.currentHealthScore * 10 / 100,
                        maxScore: 10
                    )
                }
            }

            if let breakdown = scheduler.currentBreakdown {
                Text(breakdown.summaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Session")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "clock")
                Text(TimeFormatting.formatTimerDisplay(scheduler.currentSessionDuration))
                    .font(.system(.title3, design: .monospaced))
                Spacer()
            }

            if let nextBreak = scheduler.nextScheduledBreak {
                HStack {
                    Image(systemName: nextBreak.iconName)
                    Text("Next: \(nextBreak.displayName)")
                        .font(.caption)
                    Spacer()
                    Text(TimeFormatting.formatTimerDisplay(scheduler.timeUntilNextBreak))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 8) {
            Button {
                scheduler.togglePause()
            } label: {
                Label(
                    scheduler.isPaused ? "Resume" : "Pause",
                    systemImage: scheduler.isPaused ? "play.fill" : "pause.fill"
                )
            }

            Button {
                scheduler.resetSession()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }

            Spacer()

            Button {
                scheduler.takeBreakNow(.micro)
            } label: {
                Label("Break Now", systemImage: "eye")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today's Stats")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                StatItem(
                    icon: "checkmark.circle",
                    label: "Breaks",
                    value: "\(scheduler.breaksTakenToday)"
                )
                Spacer()
                StatItem(
                    icon: "xmark.circle",
                    label: "Skipped",
                    value: "\(scheduler.breaksSkippedToday)"
                )
                Spacer()
                StatItem(
                    icon: "clock",
                    label: "Screen",
                    value: TimeFormatting.formatDuration(scheduler.totalScreenTimeToday)
                )
            }
        }
    }

    private var reportSection: some View {
        HStack {
            Button {
                generateReport()
            } label: {
                Label("Generate Report", systemImage: "doc.text")
            }
            .font(.caption)
            Spacer()
        }
    }

    /// AI-powered insight summary (v1.8).
    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                    .font(.caption2)
                    .foregroundStyle(.purple)
                Text("AI Insight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            let compliance = (scheduler.breaksTakenToday + scheduler.breaksSkippedToday) > 0
                ? Double(scheduler.breaksTakenToday)
                    / Double(scheduler.breaksTakenToday + scheduler.breaksSkippedToday)
                : 1.0
            let insight = InsightGenerator().generateMenuBarInsight(
                healthScore: scheduler.currentHealthScore,
                screenTime: scheduler.totalScreenTimeToday,
                breakCompliance: compliance
            )
            Text(insight)
                .font(.caption2)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
    }

    private var footerSection: some View {
        HStack {
            Button("Dashboard...") {
                DashboardWindowController.shared.showDashboard(scheduler: scheduler)
            }
            .font(.caption)

            Spacer()

            Button("Preferences...") {
                PreferencesWindowController.shared.showPreferences()
            }
            .font(.caption)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
    }

    // MARK: - Report Generation

    /// Generates a daily report with current session data and opens the reports folder.
    private func generateReport() {
        Task { @MainActor in
            let data = ReportDataProvider.shared.currentData()
            let generator = DailyReportGenerator()
            _ = await generator.generate(
                sessions: data.sessions,
                breakEvents: data.breakEvents,
                totalScreenTime: data.totalScreenTime,
                longestContinuousSession: data.longestContinuousSession
            )
            // Open the reports directory in Finder
            NSWorkspace.shared.open(EyeGuardConstants.reportsDirectory)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(scheduler.isPaused ? .orange : .green)
                .frame(width: 8, height: 8)
            Text(scheduler.isPaused ? "Paused" : "Active")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var trendIndicator: some View {
        HStack(spacing: 2) {
            Text(scheduler.currentTrend.symbol)
                .font(.caption)
                .foregroundStyle(trendColor)
            Text(scheduler.currentTrend.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var trendColor: Color {
        switch scheduler.currentTrend {
        case .improving: return .green
        case .stable:    return .blue
        case .declining: return .red
        }
    }

    private func breakdownRow(label: String, score: Int, maxScore: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .leading)
            Text("\(score)/\(maxScore)")
                .font(.system(.caption2, design: .monospaced))
                .bold()
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(score: score, maxScore: maxScore))
                        .frame(
                            width: geometry.size.width * CGFloat(score) / CGFloat(max(maxScore, 1)),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
    }

    private func barColor(score: Int, maxScore: Int) -> Color {
        let ratio = Double(score) / Double(max(maxScore, 1))
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        if ratio >= 0.3 { return .orange }
        return .red
    }
}

// MARK: - HealthScoreGauge

/// A circular gauge displaying the health score with color coding.
///
/// Colors: Green (80-100), Yellow (50-79), Orange (30-49), Red (0-29)
private struct HealthScoreGauge: View {
    let score: Int

    private var color: Color {
        switch score {
        case 80...100: return .green
        case 50..<80:  return .yellow
        case 30..<50:  return .orange
        default:       return .red
        }
    }

    private var progress: Double {
        Double(min(max(score, 0), 100)) / 100.0
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(.quaternary, lineWidth: 6)
                .frame(width: 64, height: 64)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Score text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("/100")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - StatItem

/// A small stat display with icon, label, and value.
private struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
