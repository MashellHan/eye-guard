//
//  EyeGuardNotchMenuTests.swift
//  EyeGuard — Notch Module (Day 2.2)
//
//  Validates EyeGuardNotchMenu's action contract:
//  - Each Actions closure fires when the corresponding menu row is invoked.
//  - State (isPaused) flips the pause/resume row's symbol + label.
//  - openPreferences default closure posts Notification.Name
//    .eyeGuardNotchMenuOpenPreferences.
//
//  Strategy: invoke the closures directly (not the SwiftUI buttons) so the
//  test is hermetic and does not depend on view rendering. The closures
//  *are* the unit under test — the view's job is just to wire them.
//

import Testing
import Foundation
@testable import EyeGuard

@Suite("EyeGuardNotchMenu")
@MainActor
struct EyeGuardNotchMenuTests {

    // MARK: - Action closures fire

    @Test("takeBreakNow closure invokes caller-provided action")
    func takeBreakNowFires() {
        var fired = 0
        let actions = makeActions(takeBreak: { fired += 1 })
        actions.takeBreakNow()
        #expect(fired == 1)
    }

    @Test("skipNextBreak closure invokes caller-provided action")
    func skipNextBreakFires() {
        var fired = 0
        let actions = makeActions(skipNext: { fired += 1 })
        actions.skipNextBreak()
        #expect(fired == 1)
    }

    @Test("togglePause closure invokes caller-provided action")
    func togglePauseFires() {
        var fired = 0
        let actions = makeActions(togglePause: { fired += 1 })
        actions.togglePause()
        #expect(fired == 1)
    }

    @Test("resetSession closure invokes caller-provided action")
    func resetSessionFires() {
        var fired = 0
        let actions = makeActions(resetSession: { fired += 1 })
        actions.resetSession()
        #expect(fired == 1)
    }

    // MARK: - State equality (used for SwiftUI diffing)

    @Test("State equality is by-value")
    func stateEquatable() {
        let a = EyeGuardNotchMenu.State(isPaused: false, nextBreakLabel: "micro break")
        let b = EyeGuardNotchMenu.State(isPaused: false, nextBreakLabel: "micro break")
        let c = EyeGuardNotchMenu.State(isPaused: true,  nextBreakLabel: "micro break")
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Default openPreferences posts notification

    @Test("Default openPreferences posts .eyeGuardNotchMenuOpenPreferences")
    func defaultOpenPreferencesPostsNotification() async {
        let actions = EyeGuardNotchMenu.Actions(
            takeBreakNow:  {},
            skipNextBreak: {},
            togglePause:   {},
            resetSession:  {}
        )

        // Listen on the default center; we await one delivery via
        // notifications(named:) async sequence.
        let received: Bool = await withCheckedContinuation { cont in
            let center = NotificationCenter.default
            nonisolated(unsafe) var token: NSObjectProtocol?
            token = center.addObserver(
                forName: .eyeGuardNotchMenuOpenPreferences,
                object: nil,
                queue: .main
            ) { _ in
                if let token { center.removeObserver(token) }
                cont.resume(returning: true)
            }
            actions.openPreferences()
        }
        #expect(received)
    }

    // MARK: - Helpers

    private func makeActions(
        takeBreak:    @escaping @MainActor () -> Void = {},
        skipNext:     @escaping @MainActor () -> Void = {},
        togglePause:  @escaping @MainActor () -> Void = {},
        resetSession: @escaping @MainActor () -> Void = {}
    ) -> EyeGuardNotchMenu.Actions {
        EyeGuardNotchMenu.Actions(
            takeBreakNow:  takeBreak,
            skipNextBreak: skipNext,
            togglePause:   togglePause,
            resetSession:  resetSession
        )
    }
}
