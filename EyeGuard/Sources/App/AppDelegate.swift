import AppKit
import Foundation

/// Application delegate handling system-level setup.
///
/// Responsibilities:
/// - Check/request accessibility permissions (needed for CGEventTap)
/// - Initialize monitoring services
/// - Ensure data directories exist
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDataDirectories()
        checkAccessibilityPermissions()
        startMonitoring()
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
            print("[EyeGuard] Accessibility permission not yet granted. Some features will be limited.")
        } else {
            print("[EyeGuard] Accessibility permission granted.")
        }
    }

    /// Starts the activity monitoring pipeline.
    private func startMonitoring() {
        Task {
            await ActivityMonitor.shared.startMonitoring()
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
