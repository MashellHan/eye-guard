//
//  NotchContainerView.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Root SwiftUI view hosted inside NotchPanel. Dispatches on the
//  VM.contentType for expanded content and renders the collapsed
//  wings when closed.
//

import SwiftUI

struct NotchContainerView: View {
    @Bindable var viewModel: NotchViewModel
    let bridge: EyeGuardDataBridge?

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(
                    width: currentWidth,
                    height: currentHeight
                )
                .background(
                    NotchShape(cornerRadius: currentCornerRadius)
                        .fill(Color.black)
                )
                // B12: Two-phase Dynamic-Island morph — phase A is the
                // container shape (frame + cornerRadius) driven by an
                // interpolatingSpring (mass:1, stiffness:200, damping:22 →
                // ζ≈0.78, ~3% overshoot) so the pill "breathes" open with
                // a clean elastic settle. Content fade is handled inside
                // EyeGuardExpandedView (phase B, delayed ~130ms). Same
                // spring drives status + contentType to keep both phases
                // visually coherent. Stays inside W2 height-throttle
                // (10 writes/500ms) — overshoot adds at most 1–2 settle
                // frames over the previous spring.
                .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 22), value: viewModel.status)
                .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 22), value: viewModel.contentType)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Derived geometry

    private var currentWidth: CGFloat {
        switch viewModel.status {
        case .opened:
            return viewModel.openedSize.width
        case .popping:
            // Pop banner needs room for icon + typewriter message
            return max(
                viewModel.geometry.deviceNotchRect.width + 240,
                360
            )
        case .closed:
            return viewModel.geometry.deviceNotchRect.width
                + viewModel.currentExpansionWidth
        }
    }

    /// B12: cornerRadius participates in the container morph — opened
    /// state widens to 18pt for a softer, more "liquid" feel; closed and
    /// popping keep the 14pt radius that lines up with the screen bezel.
    /// Interpolated by `NotchShape.animatableData` under the same spring.
    private var currentCornerRadius: CGFloat {
        switch viewModel.status {
        case .opened:
            return 18
        case .popping, .closed:
            return 14
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

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch (viewModel.status, viewModel.contentType) {
        case (.opened, .eyeGuard):
            if let bridge {
                EyeGuardExpandedView(bridge: bridge, viewModel: viewModel)
            } else {
                PlaceholderExpanded { viewModel.notchClose() }
            }
        case (.opened, .placeholder):
            PlaceholderExpanded { viewModel.notchClose() }

        case (.popping, _):
            if let kind = viewModel.popKind {
                NotchPopBanner(kind: kind, message: viewModel.popMessage)
            } else if viewModel.contentType == .eyeGuard, let bridge {
                EyeGuardCollapsedContent(bridge: bridge)
            } else {
                PlaceholderCollapsed()
            }

        case (.closed, .eyeGuard):
            if let bridge {
                EyeGuardCollapsedContent(bridge: bridge)
            } else {
                PlaceholderCollapsed()
            }
        case (.closed, .placeholder):
            PlaceholderCollapsed()
        }
    }
}
