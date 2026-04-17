//
//  NextBreakSection.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Countdown to the next scheduled break.
//

import SwiftUI

struct NextBreakSection: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 14))
            Text("Next Break")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(bridge.nextBreakInFormatted)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}
