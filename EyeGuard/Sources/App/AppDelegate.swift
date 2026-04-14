import AppKit
import Foundation
import os

/// Application delegate handling system-level setup.
///
/// Responsibilities:
/// - Check/request accessibility permissions (needed for CGEventTap)
/// - Initialize monitoring services
/// - Ensure data directories exist
/// - Set up notification permissions
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDataDirectories()
        checkAccessibilityPermissions()
        startMonitoring()
        setupNotifications()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // TODO: Generate daily report on quit if data exists
        // TODO: Persist current session state
    }

    // MARK: - Private

    /// Verifies accessibility permissions required for CGEventTap.
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            // Prompt the user to grant accessibility permissions.
            // Use string literal to avoid Swift 6 concurrency warning on the C global.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            Log.app.warning("Accessibility permission not yet granted. Some features will be limited.")
        } else {
            Log.app.info("Accessibility permission granted.")
        }
    }

    /// Starts the activity monitoring pipeline.
    private func startMonitoring() {
        Task {
            await ActivityMonitor.shared.startMonitoring()
        }
    }

    /// Requests notification permissions via explicit setup() call
    /// (moved out of NotificationManager.init).
    /// Guarded: only runs inside a proper .app bundle with a bundle identifier.
    private func setupNotifications() {
        guard Bundle.main.bundleIdentifier != nil else {
            Log.app.warning("Not running in an app bundle. Notifications disabled.")
            return
        }
        Task { @MainActor in
            NotificationManager.shared.setup()
        }
    }

    /// Creates required data directories if they don't exist.
    private func ensureDataDirectories() {
        let directories = [
            EyeGuardConstants.reportsDirectory,
            EyeGuardConstants.dataDirectory,
        ]
        let fileManager = FileManager.default
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }
}
