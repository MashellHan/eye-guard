//
//  IslandNotchViewController.swift
//  ClaudeIsland
//
//  Hosts the SwiftUI IslandNotchView in AppKit with click-through support
//

import AppKit
import SwiftUI

/// Custom NSHostingView that passes through clicks on transparent/empty areas.
class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    var isOpened: () -> Bool = { false }

    // Explicit deinit works around a Swift 6.2.4 compiler crash (SR-xxxxx)
    // in SILPerformanceInliner when optimizing the synthesized deallocating
    // deinit of a generic NSHostingView subclass.
    deinit {}

    override func hitTest(_ point: NSPoint) -> NSView? {
        // When opened, let SwiftUI handle all hit testing naturally
        if isOpened() {
            return super.hitTest(point)
        }
        // When closed, accept clicks in the top band (notch height)
        // so the left/right wings are clickable even on transparent areas
        // IslandNotchViewModel.handleMouseDown does the precise geometry check
        if point.y >= bounds.height - 44 {
            return self
        }
        return nil
    }
}

class IslandNotchViewController: NSViewController {
    private let viewModel: IslandNotchViewModel
    private var hostingView: PassThroughHostingView<IslandNotchView>!

    init(viewModel: IslandNotchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // IslandNotchView reads IslandNotchCustomizationStore.shared directly via
        // an @ObservedObject on the singleton (see IslandNotchView.swift).
        // Because the store is a MainActor singleton, there is no need
        // to cross an @EnvironmentObject boundary here — direct
        // observation avoids the generic type mismatch that
        // `environmentObject(_:)` would introduce into the
        // strictly-typed PassThroughHostingView<IslandNotchView>.
        hostingView = PassThroughHostingView(rootView: IslandNotchView(viewModel: viewModel))

        hostingView.isOpened = { [weak self] in
            self?.viewModel.status == .opened
        }

        self.view = hostingView
    }
}
