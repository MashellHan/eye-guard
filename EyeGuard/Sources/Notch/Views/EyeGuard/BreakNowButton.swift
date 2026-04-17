//
//  BreakNowButton.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  "Take a break now" button — triggers an immediate micro break.
//

import SwiftUI

struct BreakNowButton: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        Button {
            bridge.triggerBreakNow()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 13))
                Text("Take a Break Now")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(bridge.isInBreak)
        .opacity(bridge.isInBreak ? 0.5 : 1.0)
    }
}
