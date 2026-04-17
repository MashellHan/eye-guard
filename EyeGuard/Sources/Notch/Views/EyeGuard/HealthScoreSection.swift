//
//  HealthScoreSection.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Today's eye-health score (0–100).
//

import SwiftUI

struct HealthScoreSection: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .foregroundStyle(scoreColor)
                .font(.system(size: 16))
            Text("Health Score")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(bridge.healthScore)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text("/ 100")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
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
