//
//  InlineTipBanner.swift
//  EyeGuard — Notch Module
//
//  Compact in-panel tip card pinned above "Continuous Use" when the
//  user taps the Tip quick-action while the notch is expanded. Avoids
//  collapsing the panel just to show a notification — the user can read
//  the tip without losing context, and dismiss it with the × button or
//  let it auto-clear after 8s.
//

import SwiftUI

struct InlineTipBanner: View {
    let tip: EyeHealthTip
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: tip.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.yellow)
                .frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.titleChinese)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.notchPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(tip.descriptionChinese)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.notchSecondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.notchTertiaryText)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.25), lineWidth: 0.5)
                )
        )
    }
}
