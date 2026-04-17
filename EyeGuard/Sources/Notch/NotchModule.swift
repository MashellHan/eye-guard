//
//  NotchModule.swift
//  EyeGuard — Notch Module (Phase 2)
//
//  Module entry point. Now accepts a BreakScheduler so a data bridge
//  can power the collapsed + expanded EyeGuard views.
//

import AppKit
import Observation
import os

@MainActor
@Observable
final class NotchModule {
    static let shared = NotchModule()

    private(set) var isActive: Bool = false
    private var controllers: [NotchWindowController] = []
    private var bridge: EyeGuardDataBridge?
    private var flowAdapter: NotchBreakFlowAdapter?
    private let log = Logger(subsystem: "com.eyeguard.app", category: "Notch")

    private init() {}

    /// Spawn notch panels on all eligible screens.
    /// If a scheduler is supplied, a data bridge and break-flow adapter
    /// are attached so the Notch reflects live state and pops banners
    /// on pre-break / break-start / break-end transitions.
    func activate(scheduler: BreakScheduler? = nil) {
        guard !isActive else { return }

        if let scheduler {
            bridge = EyeGuardDataBridge(scheduler: scheduler)
        }

        let builtin = NSScreen.screens.filter { $0.isBuiltinDisplay }
        let eligible: [NSScreen]
        if !builtin.isEmpty {
            eligible = builtin
        } else if let main = NSScreen.main {
            log.info("NotchModule.activate: no built-in display; using NSScreen.main as fallback")
            eligible = [main]
        } else {
            log.warning("NotchModule.activate: no usable screen; skipping")
            isActive = true
            return
        }
        controllers = eligible.map {
            NotchWindowController(screen: $0, bridge: bridge)
        }

        if let scheduler, let firstVM = controllers.first?.viewModel {
            let adapter = NotchBreakFlowAdapter(
                scheduler: scheduler,
                viewModel: firstVM
            )
            adapter.start()
            flowAdapter = adapter
        }

        isActive = true
        log.info("NotchModule activated on \(eligible.count) screen(s), bridge=\(self.bridge != nil)")
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
        log.info("NotchModule deactivated")
    }
}
