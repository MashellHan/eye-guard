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
            ContinuousTimeSection(bridge: bridge)

            Divider()
                .background(Color.white.opacity(0.12))

            HealthScoreSection(bridge: bridge)
            NextBreakSection(bridge: bridge)

            BreakNowButton(bridge: bridge)
                .padding(.top, 4)
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
            let snapped = ceil(newHeight)
            guard let viewModel,
                  abs(viewModel.measuredEyeGuardHeight - snapped) > 0.5 else { return }
            viewModel.measuredEyeGuardHeight = snapped
        }
    }
}
