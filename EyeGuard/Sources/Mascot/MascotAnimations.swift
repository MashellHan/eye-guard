import SwiftUI

/// Centralized animation parameters for each mascot state.
///
/// Provides timing, easing, and value ranges for breathing,
/// bouncing, blinking, pupil movement, and arm waving.
enum MascotAnimations {

    // MARK: - Breathing

    /// Scale range for the idle breathing animation.
    static let breathingScaleMin: CGFloat = 0.96
    static let breathingScaleMax: CGFloat = 1.0

    /// Duration for one full breath cycle (in → out → in).
    static let breathingDuration: Double = 2.5

    // MARK: - Blinking

    /// Average interval between blinks (seconds).
    static let blinkInterval: Double = 3.5

    /// Random variance around the blink interval (±seconds).
    static let blinkVariance: Double = 1.5

    /// Duration the eyes stay closed during a blink.
    static let blinkDuration: Double = 0.15

    // MARK: - Bouncing (alerting/celebrating)

    /// Vertical bounce amplitude in points.
    static let bounceAmplitude: CGFloat = 6.0

    /// Duration for one full bounce cycle.
    static let bounceDuration: Double = 0.4

    // MARK: - Arm Waving (alerting)

    /// Maximum wave angle in degrees.
    static let waveAmplitude: Double = 30.0

    /// Duration for one full wave cycle.
    static let waveDuration: Double = 0.5

    // MARK: - Pupil Exercise Pattern

    /// Points the pupil visits during eye exercises (normalized -1…1).
    static let exercisePattern: [CGSize] = [
        CGSize(width: 0, height: -1),    // Up
        CGSize(width: 1, height: 0),     // Right
        CGSize(width: 0, height: 1),     // Down
        CGSize(width: -1, height: 0),    // Left
        CGSize(width: 0.7, height: -0.7), // Top-right
        CGSize(width: -0.7, height: 0.7), // Bottom-left
        CGSize(width: -0.7, height: -0.7), // Top-left
        CGSize(width: 0.7, height: 0.7),  // Bottom-right
        CGSize(width: 0, height: 0),     // Center
    ]

    /// Maximum pupil offset in points.
    static let pupilRange: CGFloat = 8.0

    /// Duration to move between exercise pattern points.
    static let exerciseStepDuration: Double = 0.8

    // MARK: - Idle Pupil Look-Around

    /// Subtle random pupil offset range for idle look-around.
    static let idlePupilRange: CGFloat = 4.0

    /// Interval between random idle pupil movements.
    static let idleLookInterval: Double = 4.0

    // MARK: - Speech Bubble

    /// How long the speech bubble stays visible.
    static let bubbleDisplayDuration: Double = 5.0

    /// Fade-in/out duration for the speech bubble.
    static let bubbleFadeDuration: Double = 0.3
}
