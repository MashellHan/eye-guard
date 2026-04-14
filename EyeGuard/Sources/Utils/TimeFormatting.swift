import Foundation

/// Shared time formatting utilities used across the app.
enum TimeFormatting {

    /// Formats a duration in seconds to a human-readable string (e.g. "2h 15m", "5m").
    ///
    /// - Parameter interval: Duration in seconds.
    /// - Returns: Formatted string like "2h 15m" or "5m" or "30s".
    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(seconds)s"
    }

    /// Formats a duration for the menu bar timer display (e.g. "1:05:30", "05:30").
    ///
    /// - Parameter interval: Duration in seconds.
    /// - Returns: Formatted string like "1:05:30" or "05:30".
    static func formatTimerDisplay(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
