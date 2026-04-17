//
//  PlaceholderCollapsed.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Minimal collapsed-state content: a single dot centered in the notch.
//  Phase 2 replaces this with EyeGuardCollapsedContent.
//

import SwiftUI

struct PlaceholderCollapsed: View {
    var body: some View {
        HStack {
            Spacer()
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 6, height: 6)
            Spacer()
        }
        .accessibilityLabel("Notch collapsed indicator")
    }
}
