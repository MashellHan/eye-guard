//
//  NotchHostingController.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Hosts the SwiftUI NotchContainerView inside the NSPanel.
//  Uses a custom NSHostingView subclass that passes clicks through
//  empty (transparent) regions when the notch is closed.
//

import AppKit
import SwiftUI

/// NSHostingView subclass that conditionally eats or passes clicks
/// depending on whether the notch is opened.
final class NotchPassThroughHostingView<Content: View>: NSHostingView<Content> {
    var isOpened: () -> Bool = { false }

    // Explicit deinit to work around a generic NSHostingView subclass
    // SIL optimization crash seen on Swift 6.2.x.
    deinit {}

    override func hitTest(_ point: NSPoint) -> NSView? {
        if isOpened() {
            return super.hitTest(point)
        }
        // When closed, accept clicks in the top ~notch band so the
        // NotchViewModel.handleMouseDown path can evaluate geometry.
        if point.y >= bounds.height - 44 {
            return self
        }
        return nil
    }
}

@MainActor
final class NotchHostingController: NSViewController {
    private let viewModel: NotchViewModel
    private var hosting: NotchPassThroughHostingView<NotchContainerView>!

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = NotchContainerView(viewModel: viewModel)
        let host = NotchPassThroughHostingView(rootView: rootView)
        host.isOpened = { [weak viewModel] in
            viewModel?.status == .opened
        }
        self.hosting = host
        self.view = host
    }
}
