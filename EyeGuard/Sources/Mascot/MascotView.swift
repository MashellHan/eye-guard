import SwiftUI

/// The adorable eyeball mascot drawn entirely with SwiftUI shapes.
///
/// A round, Q-style character with a large iris, expressive pupil,
/// tiny stick-figure arms/legs, and state-driven expressions.
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

    var body: some View {
        ZStack {
            // Legs — two small lines below body
            legs

            // Body — white circle (the eyeball)
            Circle()
                .fill(.white)
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            // Iris — colored circle
            Circle()
                .fill(irisGradient)
                .frame(width: 34, height: 34)
                .offset(pupilOffset)

            // Pupil — black circle with highlight
            ZStack {
                Circle()
                    .fill(.black)
                    .frame(width: 16, height: 16)

                // Shine highlight
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 5, height: 5)
                    .offset(x: -3, y: -3)
            }
            .offset(pupilOffset)

            // Eyelids (blink / sleeping)
            if isBlinking || state == .sleeping {
                eyelids
            }

            // Expression overlay
            expressionOverlay

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

    // MARK: - Iris Color

    private var irisGradient: LinearGradient {
        let color: Color = switch state {
        case .idle:        .blue
        case .happy:       .green
        case .concerned:   .orange
        case .alerting:    .red
        case .sleeping:    .indigo
        case .exercising:  .teal
        case .celebrating: .purple
        }

        return LinearGradient(
            colors: [color.opacity(0.7), color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Eyelids

    private var eyelids: some View {
        VStack(spacing: 0) {
            // Top eyelid
            Ellipse()
                .fill(.white)
                .frame(width: 64, height: 34)
                .offset(y: -1)
            // Bottom eyelid
            Ellipse()
                .fill(.white)
                .frame(width: 64, height: 34)
                .offset(y: 1)
        }
    }

    // MARK: - Expression Overlay

    @ViewBuilder
    private var expressionOverlay: some View {
        switch state {
        case .happy, .celebrating:
            // Smile — small arc below the pupil
            HappyMouth()
                .stroke(Color.pink, lineWidth: 2)
                .frame(width: 16, height: 8)
                .offset(y: 20)

        case .concerned:
            // Worried eyebrow squiggle
            ConcernedBrow()
                .stroke(Color.gray.opacity(0.7), lineWidth: 1.5)
                .frame(width: 20, height: 6)
                .offset(y: -26)

        case .alerting:
            // Exclamation marks
            Text("!")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.red)
                .offset(x: 26, y: -20)

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

/// A worried brow squiggle shape.
struct ConcernedBrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.3, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.7, y: rect.maxY)
        )
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
