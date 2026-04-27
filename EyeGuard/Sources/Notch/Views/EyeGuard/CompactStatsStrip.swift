//
//  CompactStatsStrip.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  B7: a single-row "today at a glance" strip rendered inside the
//  expanded eyeGuard panel. B11 extended to four columns — breaks done,
//  breaks skipped, exercise sessions, total screen time — sourced from
//  `EyeGuardDataBridge` derived getters so MenuBar / Dashboard / Notch
//  can never drift.
//
//  Visual budget: ~28pt tall. With four columns instead of three we drop
//  the column gap from 12 → 8pt and the value font from 12 → 11pt so the
//  strip still fits the panel's narrow inner width without truncating
//  "3/5"-style ratios.
//

import SwiftUI

@MainActor
struct CompactStatsStrip: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 8) {
            stat(
                icon: "checkmark.circle.fill",
                color: .green,
                value: "\(bridge.breaksTakenToday)",
                label: "Done"
            )
            stat(
                icon: "xmark.circle.fill",
                color: .orange,
                value: "\(bridge.breaksSkippedToday)",
                label: "Skip"
            )
            stat(
                icon: "figure.cooldown",
                color: .teal,
                value: "\(bridge.exerciseSessionsToday)/\(bridge.recommendedExerciseSessions)",
                label: "Exercise"
            )
            stat(
                icon: "clock.fill",
                color: AppColors.notchSecondaryText,
                value: bridge.screenTimeFormattedShort,
                label: "Screen"
            )
        }
        .frame(maxWidth: .infinity)
    }

    /// Single stat column — icon over value over label. `maxWidth: .infinity`
    /// on each column gives equal quarters without hard-coded widths so the
    /// strip survives small panel-width tweaks.
    @ViewBuilder
    private func stat(
        icon: String,
        color: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.notchPrimaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AppColors.notchSecondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
