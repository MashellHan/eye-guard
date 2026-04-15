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
}
