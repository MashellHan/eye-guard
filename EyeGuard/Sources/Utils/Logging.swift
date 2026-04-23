import Foundation
import os

/// Centralized loggers for the EyeGuard app using os.Logger.
///
/// Usage: `Log.scheduler.info("Timer started")`
enum Log {
    /// Logger for the break scheduler subsystem.
    static let scheduler = Logger(subsystem: "com.eyeguard", category: "BreakScheduler")

    /// Logger for activity monitoring.
    static let activity = Logger(subsystem: "com.eyeguard", category: "ActivityMonitor")

    /// Logger for notifications.
    static let notification = Logger(subsystem: "com.eyeguard", category: "NotificationManager")

    /// Logger for report generation.
    static let report = Logger(subsystem: "com.eyeguard", category: "DailyReportGenerator")

    /// Logger for app lifecycle events.
    static let app = Logger(subsystem: "com.eyeguard", category: "App")

    /// Logger for data persistence operations.
    static let persistence = Logger(subsystem: "com.eyeguard", category: "DataPersistence")

    /// Logger for the mascot subsystem.
    static let mascot = Logger(subsystem: "com.eyeguard", category: "Mascot")

    /// Logger for the eye exercise subsystem.
    static let exercise = Logger(subsystem: "com.eyeguard", category: "Exercise")

    /// Logger for the eye health tips subsystem.
    static let tips = Logger(subsystem: "com.eyeguard", category: "Tips")

    /// Logger for the night mode subsystem.
    static let nightMode = Logger(subsystem: "com.eyeguard", category: "NightMode")

    /// Logger for color analysis subsystem.
    static let colorAnalysis = Logger(subsystem: "com.eyeguard", category: "ColorAnalysis")

    /// Logger for sound/audio subsystem.
    static let sound = Logger(subsystem: "com.eyeguard", category: "Sound")

    /// Logger for dashboard subsystem.
    static let dashboard = Logger(subsystem: "com.eyeguard", category: "Dashboard")

    /// Logger for AI/LLM insight subsystem.
    static let ai = Logger(subsystem: "com.eyeguard", category: "AI")

    /// Logger for the Notch (Dynamic Notch panel) subsystem.
    static let notch = Logger(subsystem: "com.eyeguard", category: "Notch")
}
