//
//  NotchContainerView.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  The SwiftUI root view hosted inside NotchPanel. Renders either
//  the collapsed dot or the opened placeholder based on VM.status.
//

import SwiftUI

struct NotchContainerView: View {
    @Bindable var viewModel: NotchViewModel

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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Derived geometry

    private var currentWidth: CGFloat {
        switch viewModel.status {
        case .opened:
            return viewModel.openedSize.width
        case .closed, .popping:
            return viewModel.geometry.deviceNotchRect.width
                + viewModel.currentExpansionWidth
        }
    }

    private var currentHeight: CGFloat {
        switch viewModel.status {
        case .opened:
            return viewModel.openedSize.height
        case .closed, .popping:
            return viewModel.geometry.deviceNotchRect.height
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.status {
        case .opened:
            PlaceholderExpanded { viewModel.notchClose() }
        case .closed, .popping:
            PlaceholderCollapsed()
        }
    }
}
