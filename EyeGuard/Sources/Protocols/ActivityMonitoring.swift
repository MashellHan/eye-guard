import Foundation

/// Protocol for activity monitoring, enabling testability via dependency injection.
///
/// Production: `ActivityMonitor` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
protocol ActivityMonitoring: Sendable {
    /// Whether the user is currently idle.
    var isIdle: Bool { get async }

    /// Starts monitoring user input events.
    func startMonitoring() async

    /// Stops monitoring and cleans up resources.
    func stopMonitoring() async

    /// Resets internal state for testing or daily rollover.
    func resetState() async
}
