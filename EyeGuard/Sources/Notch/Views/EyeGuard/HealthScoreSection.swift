//
//  HealthScoreSection.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Today's eye-health score (0–100) with per-component breakdown.
//  Clicking a row opens a rich popover explaining why the row isn't full and how to
//  recover the points. Hover only drives the background tint — using hover as the
//  popover trigger races with the Notch panel's auto-close logic (see r1 C1) and
//  was the regression r3 fixes after r2 over-corrected by collapsing the rich
//  content into a single-line `.help()` tooltip.
//

import SwiftUI

struct HealthScoreSection: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header — total score
            HStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(scoreColor)
                    .font(.system(size: 16))
                Text("Health Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.notchSecondaryText)
                Spacer()
                Text("\(bridge.healthScore)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.notchPrimaryText)
                    .monospacedDigit()
                Text("/ 100")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.notchTertiaryText)
            }

            // Component breakdown — uses shared `BreakdownRowView` (DRY W1).
            // Same data shape as MenuBar, with the `.notch` theme picking the
            // dark-mode font / color / width tokens.
            if let breakdown = bridge.healthScoreBreakdown {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(breakdown.components, id: \.name) { component in
                        BreakdownRowView(component: component, theme: .notch)
                    }
                }

                let hasGap = breakdown.components.contains { $0.score < $0.maxScore }
                if hasGap {
                    HStack(spacing: 3) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 9))
                        Text("点击某行查看为什么没拿满")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(AppColors.notchHintText)
                }
            }
        }
    }

    private var scoreColor: Color {
        switch bridge.healthScore {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}
