//
//  TypewriterText.swift
//  EyeGuard — Notch Module (Phase 4)
//
//  Lightweight typewriter animation for Notch pop banners.
//  Renders characters one-by-one with ~40 ms cadence, then freezes.
//

import SwiftUI

struct TypewriterText: View {
    let text: String
    var charactersPerSecond: Double = 25  // ≈ 40 ms/char

    @State private var visibleCount: Int = 0

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .task(id: text) {
                // Reset on new text, then animate.
                visibleCount = 0
                let perChar = 1.0 / max(1.0, charactersPerSecond)
                for _ in text.indices {
                    try? await Task.sleep(for: .seconds(perChar))
                    if Task.isCancelled { return }
                    visibleCount += 1
                }
            }
            .accessibilityLabel(text)
    }
}
