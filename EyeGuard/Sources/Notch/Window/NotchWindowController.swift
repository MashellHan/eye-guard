//
//  NotchWindowController.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Lifecycle + event binding for one NotchPanel on one NSScreen.
//  Rewrite of mio-guard NotchWindowController.swift, slimmed down
//  (no NotchCustomizationStore, no live-edit, no Combine).
//

import AppKit
import Observation
import os

@MainActor
final class NotchWindowController: NSWindowController {

    let viewModel: NotchViewModel
    private let screen: NSScreen
    let screenID: String
    private var observationTask: Task<Void, Never>?

    init(screen: NSScreen) {
        self.screen = screen
        self.screenID = screen.persistentID

        let screenFrame = screen.frame
        let notchSize = screen.notchSize
        let windowHeight: CGFloat = 400
        let windowFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - windowHeight,
            width: screenFrame.width,
            height: windowHeight
        )

        let deviceNotchRect = CGRect(
            x: (screenFrame.width - notchSize.width) / 2,
            y: 0,
            width: notchSize.width,
            height: notchSize.height
        )

        self.viewModel = NotchViewModel(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenFrame,
            windowHeight: windowHeight,
            hasPhysicalNotch: screen.hasPhysicalNotch,
            screenID: screen.persistentID
        )

        let panel = NotchPanel(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init(window: panel)

        let hosting = NotchHostingController(viewModel: viewModel)
        panel.contentViewController = hosting
        panel.setFrame(windowFrame, display: true)
        panel.orderFrontRegardless()
        panel.ignoresMouseEvents = true

        observeStatus(panel: panel)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.viewModel.performBootAnimation()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Observation-based subscription to VM.status for panel-level side
    /// effects (mouse event passthrough + level elevation).
    private func observeStatus(panel: NotchPanel) {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self, weak panel] in
            guard let self, let panel else { return }
            while !Task.isCancelled {
                let status = withObservationTracking {
                    self.viewModel.status
                } onChange: {
                    // onChange is called once; the outer while-loop re-enters
                    // withObservationTracking to re-subscribe.
                }
                self.applyStatus(status, to: panel)
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func applyStatus(_ status: NotchStatus, to panel: NotchPanel) {
        switch status {
        case .opened:
            panel.ignoresMouseEvents = false
            panel.acceptsMouseMovedEvents = true
            panel.level = .popUpMenu
            if viewModel.shouldActivateOnOpen {
                NSApp.activate(ignoringOtherApps: false)
                panel.makeKeyAndOrderFront(nil)
            } else {
                panel.orderFrontRegardless()
            }
        case .closed, .popping:
            panel.ignoresMouseEvents = true
            panel.level = .mainMenu + 3
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
