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
            // Left wing — countdown to next break with a label so the
            // user knows what the timer is for. Color dot keeps the
            // continuous-use tier signal (green/yellow/orange/red/blue).
            HStack(spacing: 4) {
                Image(systemName: bridge.tier.symbolName)
                    .foregroundStyle(bridge.tier.color)
                    .font(.system(size: 10))
                Text(countdownText)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.notchPrimaryText)
                    .monospacedDigit()
                Text(countdownLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppColors.notchTertiaryText)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            .padding(.leading, 8)

            Spacer(minLength: 100) // space for the physical notch

            // Right wing — eye icon
            Image(systemName: bridge.isInBreak ? "eye.slash" : "eye")
                .foregroundStyle(AppColors.notchSecondaryText)
                .font(.system(size: 11))
                .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    /// MM:SS shown in the wing — countdown to the next break (or "rest"
    /// time elapsed when a break is in progress).
    private var countdownText: String {
        bridge.isInBreak
            ? bridge.continuousTimeFormatted
            : bridge.nextBreakInFormatted
    }

    /// Tiny suffix label that explains what the countdown means.
    private var countdownLabel: String {
        bridge.isInBreak ? "rest" : "→ break"
    }

    private var a11yLabel: String {
        if bridge.isInBreak {
            return "Resting, \(bridge.continuousTimeFormatted) elapsed"
        }
        return "Next break in \(bridge.nextBreakInFormatted), \(a11yTierLabel)"
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
