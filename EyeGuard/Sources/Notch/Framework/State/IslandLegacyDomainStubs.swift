//
//  IslandLegacyDomainStubs.swift
//  EyeGuard — Notch UI Migration Shim
//
//  Mio's Notch UI references chat/session/plugin domain types that
//  eye-guard does not have (and won't reintroduce). To avoid bulk file
//  deletion of mio's well-tested view code, we provide minimal stub
//  declarations for those types. The mio code paths that read these
//  stubs become no-ops at runtime — eye-guard never publishes session
//  state, so .idle / nil branches always hit.
//
//  This file is migration scaffolding. Once mio's view code is wired
//  to a real eye-guard data source (Phase 2 — `EyeGuardNotchView`),
//  these stubs can be deleted alongside the dead view paths.
//

import Foundation

// MARK: - SessionState / SessionPhase
//
// Mio uses `SessionState` to drive things like the hovering processing
// indicator. Eye-guard has no chat session, so we expose a single
// `.idle` value and leave it unobservable.

public enum SessionPhase: Equatable, Sendable {
    case idle
    case thinking
    case responding
    case waitingForUser
    case waitingForInput
    case waitingForQuestion
    case waitingForApproval
    case processing
    case compacting
    case ended
    case error
}

public struct SessionState: Equatable, Sendable {
    public let phase: SessionPhase
    public let sessionId: String?
    public let projectName: String?
    public let lastActivityAt: Date?
    public init(
        phase: SessionPhase = .idle,
        sessionId: String? = nil,
        projectName: String? = nil,
        lastActivityAt: Date? = nil
    ) {
        self.phase = phase
        self.sessionId = sessionId
        self.projectName = projectName
        self.lastActivityAt = lastActivityAt
    }
    public static let idle = SessionState()
}

// MARK: - ClaudeSessionMonitor
//
// Mio's IslandSoundManager wires up sound effects keyed off a session
// monitor's published events. Eye-guard has no equivalent, so we ship
// an empty stub that publishes nothing.

import Combine

public final class ClaudeSessionMonitor: ObservableObject, @unchecked Sendable {
    public static let shared = ClaudeSessionMonitor()
    @Published public private(set) var state: SessionState = .idle
    private init() {}
    public func start() {}
    public func stop() {}
}

// MARK: - NativePluginManager
//
// Mio's PluginSlotView and IslandNotchMenuView depend on a plugin
// manager. Eye-guard has no plugin system. The stub returns an empty
// list so the mio menu renders no plugin section.

public final class NativePluginManager: ObservableObject, @unchecked Sendable {
    public static let shared = NativePluginManager()
    @Published public private(set) var loadedPlugins: [IslandPluginDescriptor] = []
    private init() {}
}

public struct IslandPluginDescriptor: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

// MARK: - HookSocketServer / ChatMessage
//
// Referenced in dead paths only. Stubs let the file compile.

public struct ChatMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let role: String
    public let text: String
    public let createdAt: Date
    public init(
        id: UUID = UUID(),
        role: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

public final class HookSocketServer: @unchecked Sendable {
    public static let shared = HookSocketServer()
    private init() {}
    public func start() {}
    public func stop() {}
}

// MARK: - AppDelegate.shared / EyeGuardModule
//
// Mio's IslandNotchMenuView reads `AppDelegate.shared?.modeManager` and
// `AppDelegate.shared?.eyeGuardModule`. Eye-guard's AppDelegate exists
// but does not (yet) expose those as singletons in the shape mio
// expects. We provide a `.shared` accessor that returns a thin shim
// vending the real ModeManager and a stub EyeGuardModule. All the
// nullable `?.` chains in mio's menu degrade to nil → empty UI, which
// is the correct behavior until Day 2 wires real eye-guard data.

import AppKit

@MainActor
public final class IslandAppDelegateShim {
    public static let shared = IslandAppDelegateShim()
    let modeManager = ModeManager()
    let eyeGuardModule: EyeGuardModule? = nil
    private init() {}
}

extension AppDelegate {
    /// Migration shim: vends an `IslandAppDelegateShim` so mio menu code
    /// that reads `AppDelegate.shared?.modeManager` / `?.eyeGuardModule`
    /// compiles. The real wiring happens in Day 2 when EyeGuardNotchView
    /// replaces mio's menu code.
    @MainActor
    public static var shared: IslandAppDelegateShim? {
        IslandAppDelegateShim.shared
    }
}

/// Stub for mio's plugin/module concept. Eye-guard has no equivalent —
/// the menu rows that depend on this stay hidden because `nil` is
/// returned from `AppDelegate.shared?.eyeGuardModule`.
public final class EyeGuardModule: @unchecked Sendable {
    public init() {}
}

// MARK: - AppMode.dual fallback
//
// Eye-guard's `AppMode` enum does not have a `.dual` case. Mio's menu
// code references `.dual`. Provide a static accessor returning a known
// other case so the comparison compiles and is always false at runtime.

extension AppMode {
    /// Migration shim: eye-guard has no `.dual` mode. Returns `.apu`
    /// so equality checks against this property are always false vs the
    /// real current mode (when current is .dual, which it can never be).
    public static var dual: AppMode { .apu }
}
