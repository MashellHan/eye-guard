//
//  IslandNotchModule.swift
//  EyeGuard — Notch Module (Day 2.5b)
//
//  Mio-framework-backed parallel of `NotchModule`. Spawns
//  `IslandNotchWindowController` on every built-in display, plumbs the
//  shared `EyeGuardDataBridge` into each `IslandNotchViewModel.eyeGuardBridge`
//  field, and adapts the `BreakScheduler` to the new view model's pop()
//  parity surface added in Day 2.5a.
//
//  Lives alongside the legacy `NotchModule` rather than replacing it so
//  the app keeps working while the swap is staged. Day 2.5c (or a later
//  cron tick) will update `AppModeCoordinator` to call this module
//  instead of the legacy one — that's a one-line change once we're
//  confident the visual + lifecycle behavior matches.
//

import AppKit
import Combine
import Observation
import os

@MainActor
@Observable
final class IslandNotchModule {
    static let shared = IslandNotchModule()

    private(set) var isActive: Bool = false
    private var controllers: [IslandNotchWindowController] = []
    private var bridge: EyeGuardDataBridge?
    private var flowAdapter: IslandNotchBreakFlowAdapter?
    private let log = Logger(subsystem: "com.eyeguard.app", category: "IslandNotch")

    private init() {}

    /// Spawn mio-framework notch panels on all eligible (built-in) screens
    /// and wire up the data bridge + break-flow adapter.
    func activate(scheduler: BreakScheduler? = nil) {
        guard !isActive else { return }

        // Same coexistence guard as the legacy module — Mio Island sharing
        // the menu bar should still nudge our notch out of the way.
        MioIslandCoexistence.shared.start()

        if let scheduler {
            bridge = EyeGuardDataBridge(scheduler: scheduler)
        }

        let builtin = NSScreen.screens.filter { $0.isBuiltinDisplay }
        let eligible: [NSScreen]
        if !builtin.isEmpty {
            eligible = builtin
        } else if let main = NSScreen.main {
            log.info("IslandNotchModule.activate: no built-in display; using NSScreen.main as fallback")
            eligible = [main]
        } else {
            log.warning("IslandNotchModule.activate: no usable screen; skipping")
            isActive = true
            return
        }

        controllers = eligible.map { screen in
            let c = IslandNotchWindowController(screen: screen)
            // Plumb the bridge into the view model so EyeGuardCollapsedContent /
            // EyeGuardExpandedView (wired in Day 2.1) have live data.
            c.viewModel.eyeGuardBridge = bridge
            return c
        }

        // Order each window front so the boot animation in init becomes visible.
        for c in controllers {
            c.window?.orderFrontRegardless()
        }

        if let scheduler, let firstVM = controllers.first?.viewModel {
            let adapter = IslandNotchBreakFlowAdapter(
                scheduler: scheduler,
                viewModel: firstVM
            )
            adapter.start()
            flowAdapter = adapter
        }

        isActive = true
        log.info("IslandNotchModule activated on \(eligible.count) screen(s), bridge=\(self.bridge != nil)")
    }

    func deactivate() {
        guard isActive else { return }
        flowAdapter?.stop()
        flowAdapter = nil
        for controller in controllers {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controllers.removeAll()
        bridge = nil
        isActive = false
        log.info("IslandNotchModule deactivated")
    }
}
