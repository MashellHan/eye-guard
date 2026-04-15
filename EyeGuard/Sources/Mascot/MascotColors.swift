import SwiftUI

/// Color palette for the cute creature mascot.
///
/// Warm mint-green base with soft accents — friendly and eye-care themed.
/// Redesigned in v3.1: replaced eyeball colors with creature colors.
enum MascotColors {

    // MARK: - Body

    /// Main body color: soft mint green.
    static let body = Color(red: 0.72, green: 0.90, blue: 0.82)        // #B8E6D0

    /// Body gradient edge: slightly deeper mint.
    static let bodyEdge = Color(red: 0.56, green: 0.83, blue: 0.71)    // #8FD4B4

    /// Body outline stroke.
    static let bodyStroke = Color(red: 0.50, green: 0.75, blue: 0.64)  // #80BFA3

    // MARK: - Ears & Legs

    /// Ears and legs: slightly deeper than body for contrast.
    static let accent = Color(red: 0.62, green: 0.83, blue: 0.74)      // #9DD4BC

    /// Inner ear highlight.
    static let earInner = Color(red: 0.90, green: 0.82, blue: 0.80)    // #E6D1CC

    // MARK: - Eyes

    /// Eye color: soft near-black.
    static let eye = Color(red: 0.17, green: 0.17, blue: 0.17)         // #2C2C2C

    /// Eye highlight: white sparkle.
    static let eyeHighlight = Color.white.opacity(0.90)

    /// Closed-eye line color (for blink/sleep).
    static let eyeClosed = Color(red: 0.25, green: 0.25, blue: 0.25)

    // MARK: - Mouth

    /// Default mouth color: dark green-gray, coordinated with body.
    static let mouth = Color(red: 0.42, green: 0.61, blue: 0.50)       // #6B9B80

    // MARK: - Blush

    /// Cheek blush: soft pink.
    static let blush = Color(red: 0.96, green: 0.78, blue: 0.78)       // #F5C6C6

    /// Alert blush: slightly more red.
    static let alertBlush = Color(red: 0.96, green: 0.63, blue: 0.63)  // #F5A0A0

    // MARK: - Alert State

    /// Body tint when alerting: warm peach overlay.
    static let alertBody = Color(red: 0.96, green: 0.85, blue: 0.80)   // #F5D9CC

    /// Alert glow ring.
    static let alertGlow = Color(red: 0.95, green: 0.40, blue: 0.35)

    // MARK: - Sleep Text

    /// Warm color for Zzz text.
    static let sleepText = Color(red: 0.55, green: 0.50, blue: 0.72)

    // MARK: - Eye Expressiveness

    /// Sparkle glow around eyes when health is good.
    static let eyeSparkle = Color(red: 1.0, green: 0.97, blue: 0.80)   // warm golden glow

    /// Tired eye circle (dark under-eye).
    static let eyeTired = Color(red: 0.60, green: 0.55, blue: 0.65)    // faint purple-gray

    /// Tiny hand color (lighter than body).
    static let hand = Color(red: 0.78, green: 0.93, blue: 0.86)        // light mint

    /// Particle colors for celebration.
    static let particleColors: [Color] = [
        .yellow, .pink, .orange, .mint, .cyan, .purple,
    ]
}
