//
//  MioIslandCoexistence.swift
//  EyeGuard — Notch Module
//
//  Detects whether Mio Island (com.codeisland.app) is running and
//  publishes a horizontal-offset suggestion so EyeGuard's notch panel
//  shifts left and doesn't overlap Mio's centered island.
//

import AppKit
import Observation
import os

/// Singleton observer of Mio Island's running state.
///
/// When Mio is running, EyeGuard's notch should slide left by
/// `Self.shiftWhenMioPresent` points so both islands fit side-by-side.
/// When Mio quits, the offset returns to 0.
@MainActor
@Observable
final class MioIslandCoexistence {
    static let shared = MioIslandCoexistence()

    /// Bundle identifier of Mio Island (mio-guard).
    static let mioBundleID = "com.codeisland.app"

    /// Negative = shift EyeGuard's notch to the left. ~210pt is enough
    /// to clear Mio's collapsed wings (~240pt expansion + a 30pt gap).
    static let shiftWhenMioPresent: CGFloat = -210

    /// Current suggested horizontal offset (0 when Mio is absent).
    private(set) var horizontalOffset: CGFloat = 0

    private let log = Logger(subsystem: "com.eyeguard.app", category: "Coexistence")
    private var launchObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?

    private init() {}

    /// Begin observing NSWorkspace launch / terminate notifications.
    /// Safe to call multiple times — installs observers once.
    func start() {
        if launchObserver == nil {
            let center = NSWorkspace.shared.notificationCenter
            launchObserver = center.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] note in
                Task { @MainActor in
                    self?.handleAppChange(note: note)
                }
            }
            terminateObserver = center.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] note in
                Task { @MainActor in
                    self?.handleAppChange(note: note)
                }
            }
        }
        recompute()
    }

    func stop() {
        let center = NSWorkspace.shared.notificationCenter
        if let observer = launchObserver { center.removeObserver(observer) }
        if let observer = terminateObserver { center.removeObserver(observer) }
        launchObserver = nil
        terminateObserver = nil
    }

    /// Whether Mio Island is currently running.
    var isMioRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Self.mioBundleID
        }
    }

    private func handleAppChange(note: Notification) {
        guard
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            app.bundleIdentifier == Self.mioBundleID
        else { return }
        recompute()
    }

    private func recompute() {
        let target: CGFloat = isMioRunning ? Self.shiftWhenMioPresent : 0
        guard target != horizontalOffset else { return }
        horizontalOffset = target
        log.info("Mio Island \(self.isMioRunning ? "present" : "absent"); offset=\(target)")
    }
}
