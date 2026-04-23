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
                    NotchShape(cornerRadius: 14)
                        .fill(Color.black)
                )
                .animation(.easeOut(duration: 0.25), value: viewModel.status)
                .animation(.easeOut(duration: 0.25), value: viewModel.contentType)

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
