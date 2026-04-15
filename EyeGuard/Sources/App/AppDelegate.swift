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
/// - Auto-generate daily report on app quit (v0.7)
/// - Schedule midnight report generation (v0.7)
/// - Show the mascot floating character (v0.9)
/// - Track app launch time (v1.9)
final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {

    /// Timer for midnight report generation (daily rollover).
    private var midnightTimer: Timer?

    /// The mascot floating window controller (v0.9).
    @MainActor
    static var mascotController: MascotWindowController?

    /// App launch start time for performance tracking (v1.9).
    private let launchStartTime = Date.now

    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureDataDirectories()
        checkAccessibilityPermissions()
        startMonitoring()
        setupNotifications()
        scheduleMidnightReport()

        // Log launch time (v1.9)
        let launchDuration = Date.now.timeIntervalSince(launchStartTime)
        Log.app.info("App launch completed in \(String(format: "%.3f", launchDuration))s (target < 1s)")
        if launchDuration > 1.0 {
            Log.app.warning("Launch time exceeded 1s target: \(String(format: "%.3f", launchDuration))s")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        midnightTimer?.invalidate()
        midnightTimer = nil

        // Generate daily report on app quit (v0.7)
        generateDailyReportSync()

        // Stop any ambient sound (v1.6) — synchronous on main thread
        if Thread.isMainThread {
            SoundManager.shared.stopAmbient()
            AppDelegate.mascotController?.hide()
            AppDelegate.mascotController = nil
        } else {
            DispatchQueue.main.sync {
                SoundManager.shared.stopAmbient()
                AppDelegate.mascotController?.hide()
                AppDelegate.mascotController = nil
            }
        }

        Log.app.info("EyeGuard terminating. Daily report generated.")
    }

    // MARK: - Private

    /// Verifies accessibility permissions required for CGEventTap.
    /// Only logs a warning if not trusted — does NOT prompt the user.
    /// The system will prompt automatically when CGEventTap is first used.
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
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

    // MARK: - Daily Report Generation (v0.7)

    /// Generates the daily report synchronously at app termination.
    /// Uses a semaphore to block until the async generation completes,
    /// because applicationWillTerminate does not support async.
    private func generateDailyReportSync() {
        let semaphore = DispatchSemaphore(value: 0)

        Task { @MainActor in
            let data = ReportDataProvider.shared.currentData()
            let generator = DailyReportGenerator()
            _ = await generator.generate(
                sessions: data.sessions,
                breakEvents: data.breakEvents,
                totalScreenTime: data.totalScreenTime,
                longestContinuousSession: data.longestContinuousSession
            )
            semaphore.signal()
        }

        // Wait up to 5 seconds for report generation
        _ = semaphore.wait(timeout: .now() + 5)
    }

    /// Schedules a timer to fire at the next midnight for daily report rollover.
    private func scheduleMidnightReport() {
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else {
            Log.app.error("Failed to calculate next midnight for report scheduling.")
            return
        }

        let interval = nextMidnight.timeIntervalSince(.now)
        Log.app.info("Midnight report scheduled in \(Int(interval / 60)) minutes.")

        midnightTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: false
        ) { [weak self] _ in
            self?.handleMidnightRollover()
        }
    }

    /// Called at midnight — generates the previous day's report and reschedules.
    private func handleMidnightRollover() {
        Log.app.info("Midnight rollover: generating daily report.")

        // Generate report for the day that just ended (yesterday)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now

        Task { @MainActor in
            let data = ReportDataProvider.shared.currentData()
            let generator = DailyReportGenerator()
            _ = await generator.generate(
                date: yesterday,
                sessions: data.sessions,
                breakEvents: data.breakEvents,
                totalScreenTime: data.totalScreenTime,
                longestContinuousSession: data.longestContinuousSession
            )
            Log.app.info("Midnight report generated for \(yesterday).")
        }

        // Reschedule for next midnight
        scheduleMidnightReport()
    }
}
