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

    /// Tracks which breakdown row the cursor is currently over — background tint only.
    @State private var hoveredComponent: String?

    /// Tracks which breakdown row was clicked-open. Click toggles; clicking outside
    /// (or the same row again) closes. Decoupled from hover for the reasons in the
    /// file header.
    @State private var clickedComponent: String?

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

            // Component breakdown — same data as MenuBar, dark-themed.
            if let breakdown = bridge.healthScoreBreakdown {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(breakdown.components, id: \.name) { component in
                        breakdownRow(component: component)
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

    @ViewBuilder
    private func breakdownRow(component: ScoreComponent) -> some View {
        let ratio = Double(component.score) / Double(max(component.maxScore, 1))
        let isPerfect = component.score >= component.maxScore
        HStack(spacing: 6) {
            Text(component.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.notchSecondaryText)
                .frame(width: 64, alignment: .leading)
            Text("\(component.score)/\(component.maxScore)")
                .font(.system(size: 10, design: .monospaced).weight(.semibold))
                .foregroundStyle(AppColors.notchPrimaryText)
                .frame(width: 36, alignment: .trailing)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.notchBarTrack)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(ratio: ratio))
                        .frame(width: geometry.size.width * CGFloat(ratio), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(hoveredComponent == component.name ? AppColors.notchHoverTint : .clear)
        )
        .onHover { inside in
            // Background tint only — see file header for why hover does NOT open the popover.
            if inside {
                hoveredComponent = component.name
            } else if hoveredComponent == component.name {
                hoveredComponent = nil
            }
        }
        .onTapGesture {
            clickedComponent = (clickedComponent == component.name) ? nil : component.name
        }
        .popover(
            isPresented: Binding(
                get: { clickedComponent == component.name },
                set: { if !$0 { clickedComponent = nil } }
            ),
            arrowEdge: .leading
        ) {
            breakdownPopoverContent(component: component, isPerfect: isPerfect)
        }
    }

    /// Rich popover body — restored in r3 after r2 collapsed it into a one-line
    /// `.help()` tooltip. SF Symbol header (perfect vs info), score, and the full
    /// multi-line `ScoreComponent.explanation` rendered with proper line-wrapping.
    @ViewBuilder
    private func breakdownPopoverContent(component: ScoreComponent, isPerfect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: isPerfect ? "checkmark.seal.fill" : "info.circle.fill")
                    .foregroundStyle(isPerfect ? .green : .blue)
                    .font(.system(size: 13))
                Text(component.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
                Text("\(component.score) / \(component.maxScore)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text(isPerfect ? "满分 — 保持现状" : "还能拿满分")
                .font(.caption2)
                .foregroundStyle(isPerfect ? .green : .blue)
            Text(component.explanation)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 260)
    }

    private var scoreColor: Color {
        switch bridge.healthScore {
        case 80...: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func barColor(ratio: Double) -> Color {
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        if ratio >= 0.3 { return .orange }
        return .red
    }
}
