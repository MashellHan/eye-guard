//
//  EyeGuardCollapsedContent.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Collapsed-state left+right wings: status dot + MM:SS + break icon.
//

import SwiftUI

struct EyeGuardCollapsedContent: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 8) {
            // Left wing — color tier indicator
            HStack(spacing: 4) {
                Image(systemName: bridge.tier.symbolName)
                    .foregroundStyle(bridge.tier.color)
                    .font(.system(size: 10))
                Text(bridge.continuousTimeFormatted)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.leading, 8)

            Spacer(minLength: 100) // space for the physical notch

            // Right wing — eye icon
            Image(systemName: bridge.isInBreak ? "eye.slash" : "eye")
                .foregroundStyle(.white.opacity(0.75))
                .font(.system(size: 11))
                .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Continuous use \(bridge.continuousTimeFormatted), \(a11yTierLabel)"
        )
    }

    private var a11yTierLabel: String {
        switch bridge.tier {
        case .fresh:    return "fresh"
        case .warming:  return "warming"
        case .stressed: return "stressed"
        case .overdue:  return "overdue — take a break"
        case .resting:  return "resting"
        }
    }
}
