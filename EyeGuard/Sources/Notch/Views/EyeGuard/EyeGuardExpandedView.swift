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

    /// Shared, gentle insert/remove transition for every row in the panel.
    /// Combines a soft fade with a small downward slide + barely-perceptible
    /// scale-up — the slide softens the otherwise-rigid `.move(edge: .top)`
    /// pop, while the 3% scale removes the "stamping in" feeling without
    /// triggering W2 height-throttle (no per-row .delay()).
    static let rowTransition: AnyTransition = .asymmetric(
        insertion: .opacity
            .combined(with: .offset(y: -6))
            .combined(with: .scale(scale: 0.985, anchor: .top)),
        removal: .opacity.combined(with: .offset(y: -4))
    )

    var body: some View {
        // B11: outer spacing 14→10 + padding 16→14 to absorb the 3 new
        // sections (QuickActionsRow ~26pt, AIInsightRow ~30pt, NotchFooterRow
        // ~32pt) without busting the ~420pt panel-height budget.
        VStack(alignment: .leading, spacing: 10) {
            // B7: gate every child on `.opened` so SwiftUI sees each row as
            // an insert and runs its `.transition`. Without the `if`, the
            // whole VStack is constructed before the parent's spring kicks
            // in and the rows pop in instantly. We deliberately do NOT add
            // `.delay()` per row — staggered animations would force the
            // height-throttle (W2) to settle multiple times and burn the
            // 10-writes / 500ms budget.
            if viewModel?.status == .opened {
                ContinuousTimeSection(bridge: bridge)
                    .transition(Self.rowTransition)

                Divider()
                    .background(Color.white.opacity(0.12))
                    .transition(.opacity)

                HealthScoreSection(bridge: bridge)
                    .transition(Self.rowTransition)
                NextBreakSection(bridge: bridge)
                    .transition(Self.rowTransition)
                CompactStatsStrip(bridge: bridge)
                    .transition(Self.rowTransition)

                BreakNowButton(bridge: bridge)
                    .padding(.top, 4)
                    .transition(Self.rowTransition)

                // B11: Exercise + Tip secondary actions sit directly under
                // the primary CTA — same insert/transition pattern, no
                // `.delay()` (would burn W2 height-throttle budget).
                QuickActionsRow(bridge: bridge)
                    .transition(Self.rowTransition)

                Divider()
                    .background(Color.white.opacity(0.12))
                    .transition(.opacity)

                AIInsightRow(bridge: bridge)
                    .transition(Self.rowTransition)

                Divider()
                    .background(Color.white.opacity(0.08))
                    .transition(.opacity)

                NotchFooterRow(bridge: bridge)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Fallback when this view is rendered outside an .opened
                // context (e.g. the placeholder bridge path in
                // NotchContainerView during contentType juggling). Mirrors
                // the .opened branch (without transitions) so non-hover
                // paths don't regress to a stale layout.
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
    }
}
