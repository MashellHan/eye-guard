import Foundation

/// Emotional states for the Eye Guard mascot (阿普).
///
/// Each state drives a distinct visual expression and animation set
/// on the floating mascot character.
///
/// Redesigned in v3.0: simplified from 7 states to 5.
/// - `happy` merged into `idle` (expressed via `isHighScore` flag)
/// - `sleeping` + `exercising` merged into `resting` with `RestingMode`
enum MascotState: String, Sendable, CaseIterable {
    /// Normal resting state — gentle breathing, occasional blink.
    /// When health score is high, blush intensifies and iris warms up.
    case idle

    /// User has been working too long — iris turns amber, pupil contracts.
    case concerned

    /// Break time! — bouncing, alert glow pulse, iris turns warm red.
    case alerting

    /// Eyes partially/fully closed — sleeping at night or doing exercises.
    /// Use `RestingMode` to distinguish sub-behaviors.
    case resting

    /// Just completed a break — sparkle particles, bouncy spring.
    case celebrating
}

/// Sub-modes for the `.resting` mascot state.
enum RestingMode: String, Sendable {
    /// Late night (after 10 PM) — fully closed eyes, floating zzz.
    case sleeping

    /// During an active break — pupil moves in exercise patterns.
    case exercising
}

/// Periodic eye-care gestures the mascot performs.
/// These play as short animations to reinforce the eye-care theme.
enum HandGesture: String, Sendable {
    /// No gesture — hands at sides.
    case none

    /// Rubbing eyes with both hands.
    case rubEyes

    /// Hand on forehead, looking far away.
    case lookFar

    /// Hands pointing at own eyes (eye exercise).
    case eyeExercise
}
