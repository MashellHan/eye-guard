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
        VStack(alignment: .leading, spacing: 14) {
            // B7: gate every child on `.opened` so SwiftUI sees each row as
            // an insert and runs its `.transition`. Without the `if`, the
            // whole VStack is constructed before the parent's spring kicks
            // in and the rows pop in instantly. We deliberately do NOT add
            // `.delay()` per row — staggered animations would force the
            // height-throttle (W2) to settle multiple times and burn the
            // 10-writes / 500ms budget.
            if viewModel?.status == .opened {
                ContinuousTimeSection(bridge: bridge)
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))

                Divider()
                    .background(Color.white.opacity(0.12))
                    .transition(.opacity)

                HealthScoreSection(bridge: bridge)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                NextBreakSection(bridge: bridge)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                CompactStatsStrip(bridge: bridge)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                BreakNowButton(bridge: bridge)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Fallback when this view is rendered outside an .opened
                // context (e.g. the placeholder bridge path in
                // NotchContainerView during contentType juggling). Mirrors
                // the original VStack so we don't regress non-hover paths.
                ContinuousTimeSection(bridge: bridge)
                Divider()
                    .background(Color.white.opacity(0.12))
                HealthScoreSection(bridge: bridge)
                NextBreakSection(bridge: bridge)
                CompactStatsStrip(bridge: bridge)
                BreakNowButton(bridge: bridge)
                    .padding(.top, 4)
            }
        }
        .padding(16)
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
