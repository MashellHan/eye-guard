//
//  PlaceholderExpanded.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Placeholder opened content: "Hello Notch" + close button.
//  Phase 2 replaces this with the EyeGuard expanded panel.
//

import SwiftUI

struct PlaceholderExpanded: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Hello Notch")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            Text("Phase 1 — shell only")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Button {
                onClose()
            } label: {
                Text("Close")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.15))
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
