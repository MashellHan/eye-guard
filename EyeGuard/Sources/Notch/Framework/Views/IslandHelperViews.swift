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

// MARK: - IslandNotchView — Day 2 wired implementation
//
// Replaces the Day 1 placeholder. Renders eye-guard's existing collapsed +
// expanded views (`EyeGuardCollapsedContent`, `EyeGuardExpandedView`)
// inside the mio framework panel, switching by `IslandNotchViewModel.status`.
//
// The data bridge (`EyeGuardDataBridge`) is owned by `NotchModule` and
// passed through to `IslandNotchViewController.init` via the view model
// (see `IslandNotchViewModel.bridge`). When no bridge is supplied (e.g.
// pre-activation or unit-test contexts) the view degrades to a static
// "EyeGuard" label so the layout still has a sensible fallback.

struct IslandNotchView: View {
    @ObservedObject var viewModel: IslandNotchViewModel

    init(viewModel: IslandNotchViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        // Top-aligned container so the notch sits flush with the menu bar
        // and the rest of the panel stays transparent (clicks pass through).
        // Content is sized to the notch's logical width/height (NOT the full
        // 750pt-tall × screen-wide panel) so the black squircle background
        // only paints under the actual notch surface. Otherwise hover / boot /
        // pop states flood the screen with 92% opaque black (bug fixed here).
        VStack(spacing: 0) {
            content
                .frame(width: currentWidth, height: currentHeight)
                .background(
                    NotchShape(cornerRadius: 14)
                        .fill(Color.black.opacity(viewModel.status == .closed ? 0.0 : 0.92))
                        .animation(.easeInOut(duration: 0.18), value: viewModel.status)
                )
                .clipShape(NotchShape(cornerRadius: 14))

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Day 3.2: apply mio palette at the root so theme changes
        // crossfade across the entire EyeGuard notch surface.
        .notchPalette()
    }

    private var currentWidth: CGFloat {
        switch viewModel.status {
        case .opened:
            return viewModel.openedSize.width
        case .popping:
            return max(viewModel.geometry.deviceNotchRect.width + 240, 360)
        case .closed:
            return viewModel.geometry.deviceNotchRect.width + viewModel.currentExpansionWidth
        }
    }

    private var currentHeight: CGFloat {
        switch viewModel.status {
        case .opened:
            return viewModel.openedSize.height
        case .popping:
            return viewModel.geometry.deviceNotchRect.height + 6
        case .closed:
            return viewModel.geometry.deviceNotchRect.height
        }
    }

    @ViewBuilder
    private var content: some View {
        if let bridge = viewModel.eyeGuardBridge {
            switch viewModel.status {
            case .closed:
                EyeGuardCollapsedContent(bridge: bridge)
                    .transition(.opacity)
            case .opened:
                EyeGuardExpandedView(bridge: bridge)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            case .popping:
                // Banner state — same collapsed layout but bridge consumers
                // can show an attention dot via `bridge.tier`.
                EyeGuardCollapsedContent(bridge: bridge)
            }
        } else {
            FallbackBranding(status: viewModel.status)
        }
    }
}

/// Minimal "EyeGuard" branded fallback used when no data bridge is wired.
/// Keeps the panel visually coherent during boot or in preview contexts.
private struct FallbackBranding: View {
    let status: IslandNotchStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye")
                .foregroundStyle(.white.opacity(0.7))
                .font(.system(size: 11))
            if status != .closed {
                Text("EyeGuard")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 10)
    }
}
