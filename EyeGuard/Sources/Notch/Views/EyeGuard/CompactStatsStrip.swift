//
//  CompactStatsStrip.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  B7: a single-row "today at a glance" strip rendered inside the
//  expanded eyeGuard panel. Three columns — breaks done, breaks
//  skipped, total screen time — sourced from `EyeGuardDataBridge`
//  derived getters so MenuBar / Dashboard / Notch can never drift.
//
//  Visual budget: ~28pt tall. Plan caps the whole panel at ~340pt
//  and the four pre-existing rows + padding already sit ~300pt, so
//  the strip stays inside the budget without forcing a height
//  re-throttle (W2).
//

import SwiftUI

@MainActor
struct CompactStatsStrip: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 12) {
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
                icon: "clock.fill",
                color: AppColors.notchSecondaryText,
                value: bridge.screenTimeFormattedShort,
                label: "Screen"
            )
        }
        .frame(maxWidth: .infinity)
    }

    /// Single stat column — icon over value over label. `maxWidth: .infinity`
    /// on each column gives equal thirds without hard-coded widths so the
    /// strip survives small panel-width tweaks.
    @ViewBuilder
    private func stat(
        icon: String,
        color: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.notchPrimaryText)
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(AppColors.notchSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
