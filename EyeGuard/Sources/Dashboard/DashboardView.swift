import Charts
import SwiftUI

/// Dashboard view with tabs for Today, History, and Breakdown.
///
/// Uses SwiftUI Charts framework (macOS 14+) for data visualization:
/// - **Today**: Current health score gauge, break stats, active session info
/// - **History**: BarMark for daily screen time + LineMark for health score trend
/// - **Breakdown**: Pie-style breakdown of score components
struct DashboardView: View {

    /// The connected scheduler for live data.
    let scheduler: BreakScheduler

    /// Historical data loaded asynchronously.
    @State private var history: [HistoryManager.DailySummary] = []

    /// Selected time range for history.
    @State private var selectedRange: HistoryRange = .week

    /// Whether data is loading.
    @State private var isLoading: Bool = true

    /// History range options.
    enum HistoryRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .week:  return 7
            case .month: return 30
            }
        }
    }

    var body: some View {
        TabView {
            todayTab
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            historyTab
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }

            breakdownTab
                .tabItem {
                    Label("Breakdown", systemImage: "chart.pie")
                }
        }
        .frame(width: 600, height: 500)
        .task {
            await loadHistory()
        }
    }

    // MARK: - Today Tab

    private var todayTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Health Score Gauge
                VStack(spacing: 8) {
                    Text("Current Eye Health Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    DashboardGauge(score: scheduler.currentHealthScore)
                        .frame(height: 160)

                    if let breakdown = scheduler.currentBreakdown {
                        Text(breakdown.summaryText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Divider()

                // Today's Stats Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Activity")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        DashboardStatCard(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            title: "Breaks Taken",
                            value: "\(scheduler.breaksTakenToday)"
                        )

                        DashboardStatCard(
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            title: "Breaks Skipped",
                            value: "\(scheduler.breaksSkippedToday)"
                        )

                        DashboardStatCard(
                            icon: "clock.fill",
                            iconColor: .blue,
                            title: "Screen Time",
                            value: formatHoursMinutes(scheduler.totalScreenTimeToday)
                        )
                    }

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 16) {
                        DashboardStatCard(
                            icon: "arrow.up.right",
                            iconColor: trendColor,
                            title: "Trend",
                            value: scheduler.currentTrend.displayName
                        )

                        DashboardStatCard(
                            icon: "timer",
                            iconColor: .orange,
                            title: "Longest Session",
                            value: formatHoursMinutes(scheduler.longestContinuousSession)
                        )

                        DashboardStatCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .yellow,
                            title: "Warnings",
                            value: "\(scheduler.continuousUseWarnings)"
                        )
                    }
                }

                // Active Session
                if !scheduler.isPaused {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Session")
                            .font(.headline)

                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.blue)
                            Text("Current session: \(formatHoursMinutes(scheduler.currentSessionDuration))")
                                .font(.subheadline)

                            Spacer()

                            if let next = scheduler.nextScheduledBreak {
                                Text("Next: \(next.displayName) in \(formatHoursMinutes(scheduler.timeUntilNextBreak))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.opacity(0.1))
                        )
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - History Tab

    private var historyTab: some View {
        VStack(spacing: 16) {
            // Range picker
            Picker("Time Range", selection: $selectedRange) {
                ForEach(HistoryRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedRange) { _, _ in
                Task { await loadHistory() }
            }

            if isLoading {
                ProgressView("Loading history...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if history.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Historical data will appear after your first day of use.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Screen Time Bar Chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Screen Time")
                                .font(.headline)

                            Chart(history) { day in
                                BarMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Hours", day.screenTimeHours)
                                )
                                .foregroundStyle(
                                    day.screenTimeHours > 8 ? .red :
                                    day.screenTimeHours > 6 ? .orange : .blue
                                )
                                .cornerRadius(4)
                            }
                            .chartYAxisLabel("Hours")
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                }
                            }
                            .frame(height: 160)
                        }

                        // Health Score Trend Line
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Health Score Trend")
                                .font(.headline)

                            Chart(history) { day in
                                LineMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Score", day.healthScore)
                                )
                                .foregroundStyle(.green)
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Score", day.healthScore)
                                )
                                .foregroundStyle(scoreColor(day.healthScore))
                                .symbolSize(30)
                            }
                            .chartYAxisLabel("Score")
                            .chartYScale(domain: 0...100)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { value in
                                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                }
                            }
                            .frame(height: 160)
                        }

                        // Summary Stats
                        HStack(spacing: 20) {
                            SummaryStatView(
                                title: "Avg Score",
                                value: "\(HistoryManager().averageHealthScore(history))",
                                icon: "heart.fill",
                                color: .green
                            )

                            SummaryStatView(
                                title: "Total Breaks",
                                value: "\(HistoryManager().totalBreaksTaken(history))",
                                icon: "checkmark.circle.fill",
                                color: .blue
                            )

                            SummaryStatView(
                                title: "Total Screen",
                                value: formatHoursShort(HistoryManager().totalScreenTime(history)),
                                icon: "desktopcomputer",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Breakdown Tab

    private var breakdownTab: some View {
        VStack(spacing: 20) {
            Text("Score Breakdown")
                .font(.headline)

            if let breakdown = scheduler.currentBreakdown {
                // Component bars
                VStack(spacing: 16) {
                    ForEach(breakdown.components, id: \.name) { component in
                        BreakdownComponentRow(component: component)
                    }
                }
                .padding()

                Divider()

                // Pie chart visualization using SectorMark
                Chart(breakdown.components, id: \.name) { component in
                    SectorMark(
                        angle: .value("Score", component.score),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(componentColor(component.name))
                    .annotation(position: .overlay) {
                        Text("\(component.score)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .chartLegend(position: .bottom)
                .frame(height: 200)
                .padding()

                // Total score
                HStack {
                    Spacer()
                    VStack {
                        Text("\(breakdown.score.totalScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor(breakdown.score.totalScore))
                        Text("Total Score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                ContentUnavailableView(
                    "No Data Yet",
                    systemImage: "chart.pie",
                    description: Text("Score breakdown will appear after your first break.")
                )
            }
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadHistory() async {
        isLoading = true
        let manager = HistoryManager()
        history = await manager.loadHistory(days: selectedRange.days)
        isLoading = false
    }

    // MARK: - Helpers

    private var trendColor: Color {
        switch scheduler.currentTrend {
        case .improving: return .green
        case .stable:    return .blue
        case .declining: return .red
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 50..<80:  return .yellow
        case 30..<50:  return .orange
        default:       return .red
        }
    }

    private func componentColor(_ name: String) -> Color {
        switch name {
        case "Breaks":     return .blue
        case "Discipline": return .green
        case "Time":       return .orange
        case "Quality":    return .purple
        default:           return .gray
        }
    }

    private func formatHoursMinutes(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatHoursShort(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        return "\(hours)h"
    }
}

// MARK: - Dashboard Gauge

/// A large circular gauge for the dashboard showing health score.
struct DashboardGauge: View {
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
                .stroke(.quaternary, lineWidth: 12)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            // Score text
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text("/ 100")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - Dashboard Stat Card

/// A card displaying a single statistic.
struct DashboardStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(.title3, design: .rounded))
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.5))
        )
    }
}

// MARK: - Summary Stat View

/// A compact stat view for the history summary row.
struct SummaryStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.3))
        )
    }
}

// MARK: - Breakdown Component Row

/// A row showing a single score component with bar and explanation.
struct BreakdownComponentRow: View {
    let component: ScoreComponent

    private var ratio: Double {
        guard component.maxScore > 0 else { return 0 }
        return Double(component.score) / Double(component.maxScore)
    }

    private var color: Color {
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        if ratio >= 0.3 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(component.name)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text("\(component.score) / \(component.maxScore)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * ratio)
                        .animation(.easeInOut(duration: 0.5), value: ratio)
                }
            }
            .frame(height: 8)

            Text(component.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
