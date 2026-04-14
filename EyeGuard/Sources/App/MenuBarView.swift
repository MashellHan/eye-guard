import SwiftUI

/// Menu bar popover view showing session status, controls, and quick stats.
struct MenuBarView: View {
    @Bindable var scheduler: BreakScheduler

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()
            timerSection
            Divider()
            controlsSection
            Divider()
            statsSection
            Divider()
            footerSection
        }
        .padding()
        .frame(width: 280)
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

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Session")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: "clock")
                Text(formatDuration(scheduler.currentSessionDuration))
                    .font(.system(.title3, design: .monospaced))
                Spacer()
            }

            if let nextBreak = scheduler.nextScheduledBreak {
                HStack {
                    Image(systemName: nextBreak.iconName)
                    Text("Next: \(nextBreak.displayName)")
                        .font(.caption)
                    Spacer()
                    Text(formatDuration(scheduler.timeUntilNextBreak))
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
                    icon: "heart.fill",
                    label: "Score",
                    value: "\(scheduler.currentHealthScore)"
                )
            }
        }
    }

    private var footerSection: some View {
        HStack {
            Button("Preferences...") {
                // TODO: Open preferences window
            }
            .font(.caption)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
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

    // MARK: - Formatting

    private func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
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
