import SwiftUI

/// The adorable eyeball mascot drawn entirely with SwiftUI shapes.
///
/// A round, Q-style character with a large iris, expressive pupil,
/// eyebrows, mouth, tiny stick-figure arms/legs, and state-driven expressions.
/// Enhanced with pink blush cheeks, radial gradients, and polished highlights
/// ported from the eyes-health project (v2.2).
/// Size: 64×64 pt body, ~80×90 pt total with limbs.
struct MascotView: View {
    let state: MascotState

    /// Whether the eyelids are currently closed (blink animation).
    var isBlinking: Bool = false

    /// Pupil tracking offset for eye exercise or idle look-around.
    var pupilOffset: CGSize = .zero

    /// Bounce offset for alerting/celebrating states.
    var bounceOffset: CGFloat = 0

    /// Wave angle for arm animation (radians).
    var waveAngle: Double = 0

    /// Body size constant for proportional sizing.
    private let bodySize: CGFloat = 64

    var body: some View {
        ZStack {
            // Legs — two small lines below body
            legs

            // Body — eyeball with radial gradient and subtle blue tint
            eyeballBody

            // Iris — colored circle with radial gradient
            irisView

            // Pupil — black circle with animated highlight
            pupilView

            // Sparkle highlight — follows pupil subtly
            sparkleHighlight

            // Eyelids (blink / sleeping) with skin-tone color
            eyelids

            // Pink blush cheeks — expression-dependent opacity
            cheeksView

            // Eyebrows
            eyebrows

            // Mouth
            mouth

            // Expression extras (exclamation marks, etc.)
            expressionExtras

            // Arms
            arms

            // Sleeping zzz
            if state == .sleeping {
                sleepingZzz
            }

            // Celebrating sparkles
            if state == .celebrating {
                sparkles
            }
        }
        .offset(y: bounceOffset)
    }

    // MARK: - Eyeball Body

    /// Radial gradient body — white center fading to subtle blue tint at edges.
    private var eyeballBody: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(white: 1.0),
                        Color(red: 0.94, green: 0.96, blue: 1.0),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: bodySize / 2
                )
            )
            .frame(width: bodySize, height: bodySize * 0.9)
            .overlay(
                Ellipse()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    // MARK: - Iris

    private var irisColor: Color {
        switch state {
        case .idle:        Color(red: 0.3, green: 0.55, blue: 0.9)
        case .happy:       Color(red: 0.3, green: 0.8, blue: 0.4)
        case .concerned:   Color(red: 0.9, green: 0.75, blue: 0.2)
        case .alerting:    Color(red: 0.9, green: 0.3, blue: 0.25)
        case .sleeping:    Color(red: 0.5, green: 0.5, blue: 0.75)
        case .exercising:  Color(red: 0.2, green: 0.7, blue: 0.7)
        case .celebrating: Color(red: 0.7, green: 0.4, blue: 0.85)
        }
    }

    /// Radial gradient iris — rich center fading to translucent edge.
    private var irisView: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [irisColor, irisColor.opacity(0.65)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 17
                )
            )
            .frame(width: 34, height: 34)
            .offset(pupilOffset)
    }

    // MARK: - Pupil

    /// Pupil with a shine highlight that subtly follows the pupil.
    private var pupilView: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: 16, height: 16)

            // Primary shine highlight
            Circle()
                .fill(.white.opacity(0.85))
                .frame(width: 5, height: 5)
                .offset(x: -3, y: -3)

            // Secondary micro-highlight for depth
            Circle()
                .fill(.white.opacity(0.45))
                .frame(width: 2.5, height: 2.5)
                .offset(x: 2, y: -4)
        }
        .offset(pupilOffset)
    }

    // MARK: - Sparkle Highlight

    /// Subtle sparkle on the eyeball body that drifts with pupil movement.
    private var sparkleHighlight: some View {
        Circle()
            .fill(.white.opacity(0.7))
            .frame(width: bodySize * 0.08, height: bodySize * 0.08)
            .offset(
                x: -bodySize * 0.12 + pupilOffset.width * 0.15,
                y: -bodySize * 0.15 + pupilOffset.height * 0.15
            )
    }

    // MARK: - Eyelids

    /// Skin-toned eyelids that smoothly animate per expression.
    /// Shown when blinking or sleeping; uses SkinEyelidShape for smooth curves.
    @ViewBuilder
    private var eyelids: some View {
        if isBlinking || state == .sleeping {
            VStack(spacing: 0) {
                // Top eyelid — skin-toned
                Ellipse()
                    .fill(Color(red: 0.96, green: 0.92, blue: 0.88))
                    .frame(width: bodySize, height: bodySize * 0.52)
                    .offset(y: -1)
                // Bottom eyelid — skin-toned
                Ellipse()
                    .fill(Color(red: 0.96, green: 0.92, blue: 0.88))
                    .frame(width: bodySize, height: bodySize * 0.52)
                    .offset(y: 1)
            }
        }
    }

    // MARK: - Blush Cheeks

    /// Pink blush circles below the eye — opacity varies by expression.
    private var cheeksView: some View {
        HStack(spacing: bodySize * 0.48) {
            Circle()
                .fill(Color.pink.opacity(cheeksOpacity))
                .frame(width: bodySize * 0.14, height: bodySize * 0.14)
            Circle()
                .fill(Color.pink.opacity(cheeksOpacity))
                .frame(width: bodySize * 0.14, height: bodySize * 0.14)
        }
        .offset(y: bodySize * 0.18)
    }

    /// Cheek blush intensity varies by emotional state.
    private var cheeksOpacity: Double {
        switch state {
        case .happy, .celebrating: 0.5
        case .idle, .exercising:   0.2
        case .concerned:           0.25
        case .alerting:            0.1
        case .sleeping:            0.35
        }
    }

    // MARK: - Eyebrows

    @ViewBuilder
    private var eyebrows: some View {
        switch state {
        case .happy, .celebrating:
            // Happy: curved up, relaxed eyebrows
            HappyBrow()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                .frame(width: 22, height: 5)
                .offset(y: -26)

        case .concerned:
            // Concerned: angled down, worried
            ZStack {
                ConcernedBrow()
                    .stroke(Color.gray.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 10, height: 5)
                    .offset(x: -8, y: -26)

                ConcernedBrow()
                    .stroke(Color.gray.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 10, height: 5)
                    .scaleEffect(x: -1)
                    .offset(x: 8, y: -26)
            }

        case .alerting:
            // Alerting: raised high, surprised
            ZStack {
                RaisedBrow()
                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 10, height: 6)
                    .offset(x: -8, y: -30)

                RaisedBrow()
                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 10, height: 6)
                    .scaleEffect(x: -1)
                    .offset(x: 8, y: -30)
            }

        case .sleeping:
            // Sleeping: gentle relaxed brows
            HappyBrow()
                .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                .frame(width: 20, height: 4)
                .offset(y: -25)

        case .exercising:
            // Exercising: focused brows
            ZStack {
                FocusedBrow()
                    .stroke(Color.teal.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 10, height: 4)
                    .offset(x: -8, y: -27)

                FocusedBrow()
                    .stroke(Color.teal.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 10, height: 4)
                    .scaleEffect(x: -1)
                    .offset(x: 8, y: -27)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouth: some View {
        switch state {
        case .happy, .celebrating:
            // Smile — wide arc
            HappyMouth()
                .stroke(Color.pink, lineWidth: 2)
                .frame(width: 16, height: 8)
                .offset(y: 20)

        case .concerned:
            // Small "O" mouth — worry
            Circle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                .frame(width: 6, height: 6)
                .offset(y: 21)

        case .alerting:
            // Open surprise mouth — larger "O"
            Ellipse()
                .stroke(Color.red.opacity(0.5), lineWidth: 1.5)
                .frame(width: 10, height: 8)
                .offset(y: 20)

        case .sleeping:
            // Tiny sleeping mouth — gentle arc
            SleepMouth()
                .stroke(Color.indigo.opacity(0.3), lineWidth: 1)
                .frame(width: 8, height: 4)
                .offset(y: 20)

        case .exercising:
            // Determined line mouth
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.teal.opacity(0.4))
                .frame(width: 10, height: 1.5)
                .offset(y: 20)

        default:
            EmptyView()
        }
    }

    // MARK: - Expression Extras

    @ViewBuilder
    private var expressionExtras: some View {
        switch state {
        case .alerting:
            // Exclamation marks
            ZStack {
                Text("!")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.red)
                    .offset(x: 26, y: -20)

                Text("!")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.red.opacity(0.6))
                    .offset(x: -28, y: -18)
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Arms

    private var arms: some View {
        ZStack {
            // Left arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.6))
                .frame(width: 14, height: 3)
                .offset(x: -38, y: 6)
                .rotationEffect(.degrees(-20 + waveAngle * 0.5), anchor: .trailing)

            // Right arm
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.6))
                .frame(width: 14, height: 3)
                .offset(x: 38, y: 6)
                .rotationEffect(.degrees(20 - waveAngle * 0.5), anchor: .leading)

            // Hands — small circles at arm tips
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(x: -46, y: 4)

            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(x: 46, y: 4)
        }
    }

    // MARK: - Legs

    private var legs: some View {
        HStack(spacing: 14) {
            // Left leg
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 3, height: 10)

            // Right leg
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 3, height: 10)
        }
        .offset(y: 36)
    }

    // MARK: - Sleeping Zzz

    private var sleepingZzz: some View {
        ZStack {
            Text("z")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.indigo.opacity(0.6))
                .offset(x: 20, y: -22)

            Text("z")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.indigo.opacity(0.5))
                .offset(x: 26, y: -30)

            Text("Z")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.indigo.opacity(0.4))
                .offset(x: 30, y: -40)
        }
    }

    // MARK: - Sparkles

    private var sparkles: some View {
        ZStack {
            Text("✨")
                .font(.system(size: 10))
                .offset(x: -22, y: -26)

            Text("⭐")
                .font(.system(size: 8))
                .offset(x: 28, y: -22)

            Text("✨")
                .font(.system(size: 8))
                .offset(x: 18, y: 24)
        }
    }
}

// MARK: - Custom Shapes

/// A small smile arc shape.
struct HappyMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 2)
        )
        return path
    }
}

/// A gentle sleeping mouth arc (slight curve).
struct SleepMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

/// Happy eyebrow — gentle upward curve.
struct HappyBrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

/// Concerned eyebrow — angled downward toward the center (inner side higher).
struct ConcernedBrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

/// Raised eyebrow for surprise/alert — high arch.
struct RaisedBrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - 2)
        )
        return path
    }
}

/// Focused eyebrow — slightly angled, determined look.
struct FocusedBrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Downward-pointing triangle for speech bubble pointer.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
