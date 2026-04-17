//
//  NotchModule.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Module entry point. Creates and tears down NotchWindowController
//  for each eligible screen (Phase 1: built-in display only).
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
    private let log = Logger(subsystem: "com.eyeguard.app", category: "Notch")

    private init() {}

    /// Spawn notch panels on all eligible screens.
    /// Phase 1: prefer built-in displays, but fall back to the main
    /// screen so the shell is visible during development on setups
    /// without a MacBook built-in display (external monitors only).
    func activate() {
        guard !isActive else { return }
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
        controllers = eligible.map { NotchWindowController(screen: $0) }
        isActive = true
        log.info("NotchModule activated on \(eligible.count) screen(s)")
    }

    /// Tear down all panels and clear state.
    func deactivate() {
        guard isActive else { return }
        for controller in controllers {
            controller.window?.orderOut(nil)
            controller.window?.close()
        }
        controllers.removeAll()
        isActive = false
        log.info("NotchModule deactivated")
    }
}
