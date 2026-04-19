//
//  IslandHelperViews.swift
//  EyeGuard — Notch UI Migration Shim
//
//  Small reusable subviews extracted/stubbed from mio's NotchView and
//  SystemSettingsView. These compile alongside the migrated mio framework
//  files until Day 2's EyeGuardNotchView replaces the menu/notch surfaces
//  with eye-guard-native UI.
//

import SwiftUI

/// Triangular tip used by IslandSpeechBubble.
/// Mio's call site uses `TipTriangle().fill(color).frame(...)`, so this
/// must be a `Shape`, not a `View`.
struct TipTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Stub for mio's "System Settings" menu row. Eye-guard surfaces its own
/// preferences via the existing SettingsScene, so this row is intentionally
/// empty — it stays as a no-op placeholder so existing call sites compile
/// until Day 2 swaps the menu for `EyeGuardNotchView`.
struct SystemSettingsRow: View {
    var body: some View {
        EmptyView()
    }
}

// MARK: - IslandNotchView placeholder
//
// Mio's UI/Views/NotchView.swift is 1313 LOC and tightly couples chat,
// plugin, and session concerns we are NOT porting. Day 2's task is to
// replace it with `EyeGuardNotchView`. For Day 1 build-green, expose a
// minimal `IslandNotchView` so `IslandNotchViewController` /
// `NotchPaletteModifier` references resolve. The body deliberately renders
// an empty notch panel — the real visuals land in Day 2.

struct IslandNotchView: View {
    @ObservedObject var viewModel: IslandNotchViewModel

    init(viewModel: IslandNotchViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        // Day 1 placeholder: matches the panel's expected hosting surface
        // but ships no content. Day 2 will replace this with
        // EyeGuardNotchView (collapsed/expanded eye-guard data).
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
