import SwiftUI

/// Menu bar popover view showing session status, controls, health score gauge, and quick stats.
struct MenuBarView: View {
    @Bindable var scheduler: BreakScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            displayModeSection
            Divider()
            continuousScreenTimeSection
            Divider()
            healthScoreSection
            Divider()
            controlsSection
            Divider()
            statsSection
            Divider()
            insightAndReportSection
            Divider()
            actionSection
            Divider()
            footerSection
        }
        .padding()
        .frame(width: 360)
        .onChange(of: elapsedSinceLastBreak > 3600) { _, isOver in
            if isOver {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    blinkOpacity = 0.3
                }
            } else {
                withAnimation(.default) {
                    blinkOpacity = 1.0
                }
            }
        }
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

    /// Continuous screen time display — the most prominent real-time indicator.
    private var continuousScreenTimeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "desktopcomputer")
                    .font(.caption)
                    .foregroundStyle(screenTimeColor)
                Text("距上次休息")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if elapsedSinceLastBreak < 5 {
                Text("刚刚休息过 ✨")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.green)
            } else {
                Text(TimeFormatting.formatTimerDisplay(elapsedSinceLastBreak))
                    .font(.system(.title, design: .monospaced))
                    .foregroundStyle(screenTimeColor)
                    .opacity(elapsedSinceLastBreak > 3600 ? (blinkOpacity) : 1.0)
            }

            // Progress bar toward next break
            if let nextBreak = scheduler.nextScheduledBreak {
                let progress = nextBreak.interval > 0
                    ? min(1.0, elapsedSinceLastBreak / nextBreak.interval)
                    : 0.0

                ProgressView(value: progress)
                    .tint(screenTimeColor)

                HStack {
                    Image(systemName: nextBreak.iconName)
                        .font(.caption2)
                    Text("下次休息: \(nextBreak.displayName)")
                        .font(.caption)
                    Spacer()
                    Text("还剩 \(TimeFormatting.formatTimerDisplay(scheduler.timeUntilNextBreak))")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    /// Blink animation opacity for prolonged screen time (>60min).
    @State private var blinkOpacity: Double = 1.0

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
                let breakType: BreakType = scheduler.nextScheduledBreak ?? .micro
                let behavior = BreakBehavior(
                    interval: 0,
                    duration: breakType.duration,
                    isEnabled: true,
                    entryTier: .fullScreen,
                    dismissPolicy: .skippable
                )
                NotificationManager.shared.notify(
                    breakType: breakType,
                    behavior: behavior,
                    escalation: .direct,
                    healthScore: scheduler.currentHealthScore,
                    onTaken: {
                        Task { @MainActor in
                            scheduler.takeBreakNow(breakType)
                        }
                    },
                    onSkipped: {
                        Task { @MainActor in
                            scheduler.skipBreak(breakType)
                        }
                    },
                    onPostponed: { delay in
                        Task { @MainActor in
                            scheduler.postponeBreak(breakType, by: delay)
                        }
                    }
                )
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
                    icon: "figure.cooldown",
                    label: "Exercises",
                    value: "\(scheduler.exerciseSessionsToday)/\(scheduler.recommendedExerciseSessions)"
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

    /// AI insight + Generate Report combined in one section.
    private var insightAndReportSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                    .font(.caption2)
                    .foregroundStyle(.purple)
                Text("AI Insight")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    generateReport()
                } label: {
                    Label("Report", systemImage: "doc.text")
                }
                .font(.caption2)
                .buttonStyle(.borderless)
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

    private var actionSection: some View {
        HStack(spacing: 8) {
            Button {
                DashboardWindowController.shared.showDashboard(scheduler: scheduler)
            } label: {
                Label("Dashboard", systemImage: "chart.bar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                generateReport()
            } label: {
                Label("Report", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var footerSection: some View {
        HStack {
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

    // MARK: - Display Mode

    /// Segmented picker that switches the presentation layer between
    /// Apu mascot and Notch island. Backed by `ModeManager.shared`.
    @ViewBuilder
    private var displayModeSection: some View {
        let binding = Binding<AppMode>(
            get: { ModeManager.shared.currentMode },
            set: { ModeManager.shared.switchMode(to: $0) }
        )
        VStack(alignment: .leading, spacing: 4) {
            Text("Display Mode")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("", selection: binding) {
                ForEach(AppMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
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

    /// Time elapsed since the last micro break (most frequent break type).
    private var elapsedSinceLastBreak: TimeInterval {
        scheduler.elapsedPerType[.micro, default: 0]
    }

    /// Color based on time since last break.
    private var screenTimeColor: Color {
        let minutes = elapsedSinceLastBreak / 60
        switch minutes {
        case ..<20:  return .green
        case 20..<45: return .blue
        case 45..<60: return .orange
        default:      return .red
        }
    }

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
