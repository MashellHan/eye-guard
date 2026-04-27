//
//  QuickActionsRow.swift
//  EyeGuard — Notch Module (B11)
//
//  Two ghost-style secondary buttons — Exercise + Tip — sitting under
//  the primary `BreakNowButton` CTA. Visual hierarchy:
//      filled "Take a Break" (primary)
//      ────────────────────────────────
//      [ghost Exercise] [ghost Tip]    (secondary)
//
//  We deliberately do NOT repeat "Break" here (BreakNowButton already
//  owns that action) — duplicating CTAs would muddy the hierarchy and
//  burn vertical space we need for AIInsightRow + footer.
//
//  All side effects route through `EyeGuardDataBridge` so the notch
//  module never imports `NotificationCenter` / `Notification.Name`
//  (R1: presentation layer cannot reach into business logic).
//

import SwiftUI

@MainActor
struct QuickActionsRow: View {
    @Bindable var bridge: EyeGuardDataBridge

    var body: some View {
        HStack(spacing: 8) {
            quickButton(
                icon: "figure.cooldown",
                label: "Exercise"
            ) {
                bridge.triggerExercise()
            }
            quickButton(
                icon: "lightbulb",
                label: "Tip"
            ) {
                bridge.showRandomTip()
            }
        }
    }

    /// Capsule "ghost" button — translucent fill, hover tint via
    /// `AppColors.notchHoverTint`. Mirrors the visual language of the
    /// `NotchFooterRow` icon buttons but with a label since these are
    /// primary user actions, not housekeeping.
    @ViewBuilder
    private func quickButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.notchHoverTint)
            )
            .foregroundStyle(AppColors.notchPrimaryText)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
