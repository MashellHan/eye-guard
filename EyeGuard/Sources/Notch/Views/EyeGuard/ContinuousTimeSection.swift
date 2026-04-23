//
//  ContinuousTimeSection.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Large-font "continuous use" display with progress bar.
//

import SwiftUI

struct ContinuousTimeSection: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: bridge.tier.symbolName)
                    .foregroundStyle(bridge.tier.color)
                    .font(.system(size: 12))
                Text("Continuous Use")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.notchSecondaryText)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                // B5: TimelineView isolates per-second invalidation to the
                // numeric Text only, instead of cascading a relayout to the
                // surrounding HStack/progress section every second.
                TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                    Text(bridge.continuousTimeFormatted)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                Text("/ 20:00")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.notchTertiaryText)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 4)
                    Capsule()
                        .fill(bridge.tier.color)
                        .frame(
                            width: proxy.size.width * bridge.continuousProgress,
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
    }
}
