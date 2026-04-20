//
//  AppModeCoordinator.swift
//  EyeGuard — App (Phase 3)
//
//  Observes ModeManager and activates/deactivates the correct display
//  module (Apu mascot window OR Notch panel). Exactly one is active.
//

import AppKit
import Observation
import os

@MainActor
final class AppModeCoordinator {
    private let modeManager: ModeManager
    private let scheduler: BreakScheduler
    private let log = Logger(subsystem: "com.eyeguard.app", category: "Mode")

    init(modeManager: ModeManager, scheduler: BreakScheduler) {
        self.modeManager = modeManager
        self.scheduler = scheduler
    }

    /// Apply the current mode on launch and install a mode-change hook
    /// so future changes activate/deactivate the right modules.
    func start() {
        modeManager.onModeChanged = { [weak self] mode in
            self?.apply(mode: mode)
        }
        apply(mode: modeManager.currentMode)
        log.info("AppModeCoordinator started; initial mode = \(self.modeManager.currentMode.rawValue)")
    }

    /// Activate the matching module + deactivate the other.
    private func apply(mode: AppMode) {
        switch mode {
        case .apu:
            // Day 2.5c: route to mio-framework module instead of legacy.
            // Legacy NotchModule is kept compiled but no longer activated; it
            // can be removed in Day 4.1 once burn-in confirms parity.
            IslandNotchModule.shared.deactivate()
            activateMascot()
        case .notch:
            deactivateMascot()
            IslandNotchModule.shared.activate(scheduler: scheduler)
        }
        log.info("Mode applied: \(mode.rawValue)")
    }

    // MARK: - Mascot

    private func activateMascot() {
        if AppDelegate.mascotController == nil {
            let controller = MascotWindowController()
            controller.show(scheduler: scheduler)
            AppDelegate.mascotController = controller
        }
    }

    private func deactivateMascot() {
        AppDelegate.mascotController?.hide()
        AppDelegate.mascotController = nil
    }
}
