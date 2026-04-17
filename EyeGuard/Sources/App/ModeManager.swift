//
//  ModeManager.swift
//  EyeGuard — App (Phase 3)
//
//  Central switcher between "Apu mascot" and "Notch island" display modes.
//  Persists to UserDefaults; observers react via @Observable.
//

import Foundation
import Observation

/// Display mode for the Eye Guard presentation layer.
/// The underlying business logic (BreakScheduler, HealthScore, etc.)
/// is independent of this choice.
enum AppMode: String, CaseIterable, Identifiable, Sendable {
    /// Floating Apu mascot window (the original Eye Guard look).
    case apu
    /// Dynamic Notch island overlay (Mio-inspired, data-injected).
    case notch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apu:   return "Apu Mascot"
        case .notch: return "Dynamic Notch"
        }
    }

    var icon: String {
        switch self {
        case .apu:   return "face.smiling"
        case .notch: return "rectangle.roundedtop"
        }
    }
}

/// Persisted mode + observer hook. All mutations happen on the main actor.
@MainActor
@Observable
final class ModeManager {
    /// Shared instance used by the SwiftUI app and coordinator.
    static let shared = ModeManager()

    /// UserDefaults key for mode persistence.
    static let defaultsKey = "eyeguard.displayMode"

    /// Currently active mode. Writes persist to UserDefaults and
    /// invoke `onModeChanged` so the coordinator can activate /
    /// deactivate modules.
    private(set) var currentMode: AppMode {
        didSet {
            guard oldValue != currentMode else { return }
            UserDefaults.standard.set(currentMode.rawValue, forKey: Self.defaultsKey)
            onModeChanged?(currentMode)
        }
    }

    /// Optional callback invoked after a mode change commits.
    /// Coordinator wires this to activate/deactivate NotchModule / Apu.
    var onModeChanged: (@MainActor (AppMode) -> Void)?

    /// Initialize from UserDefaults (default .apu for backward compat).
    /// Allows dependency injection for tests.
    init(defaults: UserDefaults = .standard) {
        if let raw = defaults.string(forKey: Self.defaultsKey),
           let mode = AppMode(rawValue: raw) {
            self.currentMode = mode
        } else {
            self.currentMode = .apu
        }
    }

    /// Switch to a specific mode. No-op if already in that mode.
    func switchMode(to mode: AppMode) {
        currentMode = mode
    }

    /// Cycle to the next mode (useful for right-click menu).
    func cycleMode() {
        let all = AppMode.allCases
        guard let idx = all.firstIndex(of: currentMode) else {
            currentMode = all[0]
            return
        }
        let next = all[(idx + 1) % all.count]
        currentMode = next
    }
}
