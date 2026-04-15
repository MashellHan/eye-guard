import SwiftUI

/// Read-only table showing behavior per break type for the selected mode.
/// Displayed in PreferencesView when mode != Custom.
struct ReminderModeSummaryView: View {

    let mode: ReminderMode

    private var profile: ReminderModeProfile {
        mode.profile()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mode description
            HStack(spacing: 8) {
                Image(systemName: mode.iconName)
                    .foregroundStyle(modeColor)
                    .font(.title3)
                Text(mode.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Behavior table
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                // Header row
                GridRow {
                    Text("Break Type")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Notification")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Dismiss")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                Divider()

                behaviorRow("Micro (20 min)", behavior: profile.microBreak)
                behaviorRow("Macro (60 min)", behavior: profile.macroBreak)
                behaviorRow("Mandatory (2 hr)", behavior: profile.mandatoryBreak)
            }

            // Escalation strategy
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Escalation: \(escalationLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func behaviorRow(_ label: String, behavior: BreakBehavior) -> some View {
        GridRow {
            Text(label)
                .font(.caption)

            HStack(spacing: 4) {
                Image(systemName: tierIcon(behavior.entryTier))
                    .font(.caption2)
                    .foregroundStyle(tierColor(behavior.entryTier))
                Text(behavior.entryTier.displayName)
                    .font(.caption)
            }

            Text(behavior.dismissPolicy.displayName)
                .font(.caption)
                .foregroundStyle(dismissColor(behavior.dismissPolicy))
        }
    }

    private var escalationLabel: String {
        switch profile.escalationStrategy {
        case .direct:
            return "Direct (no waiting)"
        case .tiered(let t1, let t2):
            return "Tiered (\(Int(t1 / 60))m → \(Int(t2 / 60))m)"
        }
    }

    private var modeColor: Color {
        switch mode {
        case .gentle:     return .green
        case .aggressive: return .orange
        case .strict:     return .red
        case .custom:     return .blue
        }
    }

    private func tierIcon(_ tier: NotificationTier) -> String {
        switch tier {
        case .system:     return "bell"
        case .floating:   return "macwindow"
        case .fullScreen: return "rectangle.fill"
        }
    }

    private func tierColor(_ tier: NotificationTier) -> Color {
        switch tier {
        case .system:     return .green
        case .floating:   return .orange
        case .fullScreen: return .red
        }
    }

    private func dismissColor(_ policy: DismissPolicy) -> Color {
        switch policy {
        case .skippable:    return .green
        case .postponeOnly: return .orange
        case .mandatory:    return .red
        }
    }
}
