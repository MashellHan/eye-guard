import Foundation

/// Emotional states for the Eye Guard mascot (护眼精灵).
///
/// Each state drives a distinct visual expression and animation set
/// on the floating mascot character.
enum MascotState: String, Sendable, CaseIterable {
    /// Normal resting state — gentle breathing, occasional blink.
    case idle

    /// Good break compliance — smiling expression, soft bounce.
    case happy

    /// User has been working too long — slight frown, slow sway.
    case concerned

    /// Break time! — bouncing, waving arms, speech bubble visible.
    case alerting

    /// Late night (after 10 PM) — closed eyes, floating zzz.
    case sleeping

    /// During an active break — pupil moves in exercise patterns.
    case exercising

    /// Just completed a break — sparkle/star effects.
    case celebrating
}
