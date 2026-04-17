//
//  NotchHostingController.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Hosts the SwiftUI NotchContainerView inside the NSPanel.
//  Now accepts an optional EyeGuardDataBridge for data-driven content.
//

import AppKit
import SwiftUI

final class NotchPassThroughHostingView<Content: View>: NSHostingView<Content> {
    var isOpened: () -> Bool = { false }

    deinit {}

    override func hitTest(_ point: NSPoint) -> NSView? {
        if isOpened() {
            return super.hitTest(point)
        }
        if point.y >= bounds.height - 44 {
            return self
        }
        return nil
    }
}

@MainActor
final class NotchHostingController: NSViewController {
    private let viewModel: NotchViewModel
    private let bridge: EyeGuardDataBridge?
    private var hosting: NotchPassThroughHostingView<NotchContainerView>!

    init(viewModel: NotchViewModel, bridge: EyeGuardDataBridge?) {
        self.viewModel = viewModel
        self.bridge = bridge
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = NotchContainerView(viewModel: viewModel, bridge: bridge)
        let host = NotchPassThroughHostingView(rootView: rootView)
        host.isOpened = { [weak viewModel] in
            viewModel?.status == .opened
        }
        self.hosting = host
        self.view = host
    }
}
