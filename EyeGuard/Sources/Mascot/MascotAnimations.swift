import SwiftUI

/// Centralized animation parameters for each mascot state.
///
/// Provides timing, easing, and value ranges for breathing,
/// bouncing, blinking, pupil movement, and expression overlays.
/// Redesigned in v3.0: removed arm waving, added spring configs,
/// particle effects, and dynamic pupil sizing.
enum MascotAnimations {

    // MARK: - Breathing

    /// Scale range for the idle breathing animation.
    static let breathingScaleMin: CGFloat = 0.96
    static let breathingScaleMax: CGFloat = 1.0

    /// Duration for one full breath cycle (in -> out -> in).
    static let breathingDuration: Double = 3.0

    // MARK: - Blinking

    /// Average interval between blinks (seconds).
    static let blinkInterval: Double = 3.5

    /// Random variance around the blink interval (+-seconds).
    static let blinkVariance: Double = 1.5

    /// Duration the eyes stay closed during a blink (faster = more natural).
    static let blinkDuration: Double = 0.08

    // MARK: - Bouncing (alerting/celebrating)

    /// Vertical bounce amplitude in points.
    static let bounceAmplitude: CGFloat = 5.0

    /// Duration for one full bounce cycle.
    static let bounceDuration: Double = 0.4

    // MARK: - Pupil Exercise Pattern

    /// Points the pupil visits during eye exercises (normalized -1...1).
    static let exercisePattern: [CGSize] = [
        CGSize(width: 0, height: -1),     // Up
        CGSize(width: 1, height: 0),      // Right
        CGSize(width: 0, height: 1),      // Down
        CGSize(width: -1, height: 0),     // Left
        CGSize(width: 0.7, height: -0.7), // Top-right
        CGSize(width: -0.7, height: 0.7), // Bottom-left
        CGSize(width: -0.7, height: -0.7), // Top-left
        CGSize(width: 0.7, height: 0.7),  // Bottom-right
        CGSize(width: 0, height: 0),      // Center
    ]

    /// Maximum pupil offset in points (constrained for natural look).
    static let pupilRange: CGFloat = 3.0

    /// Duration to move between exercise pattern points.
    static let exerciseStepDuration: Double = 0.8

    // MARK: - Idle Pupil Look-Around

    /// Subtle random pupil offset range for idle look-around.
    static let idlePupilRange: CGFloat = 2.5

    /// Interval between random idle pupil movements.
    static let idleLookInterval: Double = 4.0

    // MARK: - Sleeping Sway

    /// Horizontal sway amplitude for sleeping state (points).
    static let sleepSwayAmplitude: CGFloat = 4.0

    /// Duration for one full sway cycle (left -> right -> left).
    static let sleepSwayDuration: Double = 3.0

    // MARK: - Celebrating

    /// Scale pulse range for celebrating state.
    static let celebrateScaleMin: CGFloat = 0.95
    static let celebrateScaleMax: CGFloat = 1.08

    /// Duration for one celebrating pulse cycle.
    static let celebratePulseDuration: Double = 0.5

    /// Rotation angle (degrees) for celebrating wiggle.
    static let celebrateRotation: Double = 8.0

    // MARK: - Alerting

    /// Vertical bounce amplitude for alerting (points, larger than default).
    static let alertBounceAmplitude: CGFloat = 8.0

    /// Duration for one alerting bounce cycle.
    static let alertBounceDuration: Double = 0.35

    /// Alert glow pulse duration.
    static let alertGlowDuration: Double = 0.8

    // MARK: - Speech Bubble

    /// How long the speech bubble stays visible.
    static let bubbleDisplayDuration: Double = 5.0

    /// Fade-in/out duration for the speech bubble.
    static let bubbleFadeDuration: Double = 0.3

    // MARK: - Break Celebration

    /// Duration to show celebrating state after break completion.
    static let celebrationDisplayDuration: Double = 5.0

    // MARK: - Pupil Size (dynamic per state)

    /// Default pupil diameter.
    static let pupilSizeDefault: CGFloat = 16.0

    /// Concerned: slightly contracted.
    static let pupilSizeConcerned: CGFloat = 14.0

    /// Alerting: dilated (surprise/urgency).
    static let pupilSizeAlerting: CGFloat = 20.0

    /// Resting: relaxed, slightly small.
    static let pupilSizeResting: CGFloat = 14.0

    /// Celebrating: slightly large, excited.
    static let pupilSizeCelebrating: CGFloat = 18.0

    // MARK: - Spring Animation Configs

    /// Default spring for state transitions.
    static let defaultSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Bouncy spring for celebrating/alerting.
    static let bouncySpring = Animation.spring(response: 0.35, dampingFraction: 0.5)

    /// Gentle spring for idle movements.
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)

    // MARK: - Particle Effects (celebrating)

    /// Number of particles in celebration burst.
    static let particleCount: Int = 8

    /// Particle spread radius.
    static let particleRadius: CGFloat = 35.0

    /// Particle animation duration.
    static let particleDuration: Double = 1.2
}
