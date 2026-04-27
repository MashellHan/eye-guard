//
//  EyeGuardExpandedView.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Expanded-state panel composed from Phase 2 sections.
//

import SwiftUI

/// Pushes the SwiftUI-measured intrinsic height of the eyeGuard panel
/// up to `NotchViewModel`, so `openedSize` adapts as sections grow.
struct MeasuredHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct EyeGuardExpandedView: View {
    @Bindable var bridge: EyeGuardDataBridge
    var viewModel: NotchViewModel?

    var body: some View {
        // B11: outer spacing 14→10 + padding 16→14 to absorb the 3 new
        // sections (QuickActionsRow ~26pt, AIInsightRow ~30pt, NotchFooterRow
        // ~32pt) without busting the ~420pt panel-height budget.
        //
        // B12: per-row transitions removed. The whole `.opened` block is now
        // a single `.transition(.opacity)` so SwiftUI runs ONE fade instead
        // of N staggered ones — that means exactly one height-write burst
        // (W2 budget safe) and a clean "phase B" content fade after the
        // container's spring morph (phase A). Insertion delay 0.13s lets
        // the container spring run out its overshoot first; removal has no
        // delay so content disappears before the container collapses.
        Group {
            if viewModel?.status == .opened {
                VStack(alignment: .leading, spacing: 10) {
                    ContinuousTimeSection(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.12))
                    HealthScoreSection(bridge: bridge)
                    NextBreakSection(bridge: bridge)
                    CompactStatsStrip(bridge: bridge)
                    BreakNowButton(bridge: bridge)
                        .padding(.top, 4)
                    QuickActionsRow(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.12))
                    AIInsightRow(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.08))
                    NotchFooterRow(bridge: bridge)
                }
                .transition(.opacity)
            } else {
                // Fallback when this view is rendered outside an .opened
                // context (e.g. the placeholder bridge path in
                // NotchContainerView during contentType juggling). Mirrors
                // the .opened branch (without transitions) so non-hover
                // paths don't regress to a stale layout.
                VStack(alignment: .leading, spacing: 10) {
                    ContinuousTimeSection(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.12))
                    HealthScoreSection(bridge: bridge)
                    NextBreakSection(bridge: bridge)
                    CompactStatsStrip(bridge: bridge)
                    BreakNowButton(bridge: bridge)
                        .padding(.top, 4)
                    QuickActionsRow(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.12))
                    AIInsightRow(bridge: bridge)
                    Divider()
                        .background(Color.white.opacity(0.08))
                    NotchFooterRow(bridge: bridge)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: MeasuredHeightPreferenceKey.self,
                    value: geo.size.height
                )
            }
        )
        .onPreferenceChange(MeasuredHeightPreferenceKey.self) { newHeight in
            // Round up to avoid sub-pixel jitter triggering re-layout.
            // Threshold + rate-limit live in the view-model setter.
            viewModel?.updateMeasuredEyeGuardHeight(ceil(newHeight))
        }
        // B12: phase-B content fade. 0.22s easeOut feels crisper than a
        // spring for opacity. Insertion delay (~130ms) waits for the
        // container's interpolatingSpring to run past its peak overshoot
        // before the content materialises — matches Apple's Dynamic Island
        // cadence. Removal has 0 delay so content disappears first, letting
        // the container collapse onto an already-empty panel.
        .animation(
            .easeOut(duration: 0.22).delay(viewModel?.status == .opened ? 0.13 : 0),
            value: viewModel?.status
        )
    }
}
