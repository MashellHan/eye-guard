//
//  EyeGuardExpandedView.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Expanded-state panel composed from Phase 2 sections.
//

import SwiftUI

struct EyeGuardExpandedView: View {
    @Bindable var bridge: EyeGuardDataBridge

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
