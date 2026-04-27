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
    private var tipObserver: NSObjectProtocol?
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

        // In notch mode the mascot isn't running, so the
        // `.showEyeTipRequested` notification (posted by the bridge's
        // Tip quick-action) had no observer — clicks looked dead.
        // Surface the tip via a `.info` pop banner on the main-screen
        // notch view-model.
        if let firstVM = controllers.first?.viewModel {
            tipObserver = NotificationCenter.default.addObserver(
                forName: .showEyeTipRequested,
                object: nil,
                queue: .main
            ) { [weak firstVM] note in
                guard let firstVM else { return }
                let tipId = note.userInfo?["tipId"] as? Int
                let tip = TipDatabase.tips.first(where: { $0.id == tipId })
                    ?? TipDatabase.randomTip()
                Task { @MainActor in
                    // If the panel is currently expanded (user clicked
                    // Tip from QuickActionsRow inside the .opened view),
                    // close it first — `pop()` early-returns while
                    // `.opened` so without this the click looks dead.
                    // A small delay lets the close animation start
                    // before the popping state takes over.
                    if firstVM.status == .opened {
                        firstVM.notchClose()
                        try? await Task.sleep(for: .milliseconds(180))
                    }
                    firstVM.pop(
                        kind: .info,
                        message: tip.titleChinese,
                        duration: 4.5
                    )
                }
            }
        }

        isActive = true
        log.info("NotchModule activated on \(eligible.count) screen(s), bridge=\(self.bridge != nil)")
    }

    /// View model for the notch on the main screen, exposed for `DebugTrigger`.
    ///
    /// Only for `DebugTrigger`; do not call from production code paths.
    /// Filters to the controller whose window lives on `NSScreen.main` so
    /// multi-monitor setups behave deterministically. Returns nil unless the
    /// module is active and a matching controller exists.
    var mainScreenViewModelForDebug: NotchViewModel? {
        // Prefer the main-screen controller; fall back to the first available
        // (e.g. if NSScreen.main hasn't latched yet during early launch).
        let mainScreen = NSScreen.main
        let match = controllers.first { $0.window?.screen == mainScreen }
        return match?.viewModel ?? controllers.first?.viewModel
    }

    func deactivate() {
        guard isActive else { return }
        flowAdapter?.stop()
        flowAdapter = nil
        if let tipObserver {
            NotificationCenter.default.removeObserver(tipObserver)
        }
        tipObserver = nil
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
