import SwiftUI

/// A cute round creature mascot drawn entirely with SwiftUI shapes.
///
/// v3.2: Added state-driven body color, visible arms with eye-care gestures,
/// and health-state visual feedback. The creature's appearance directly
/// reflects eye health — users see the mascot and immediately know
/// their eye fatigue level.
///
/// Size: 64×64 pt body, ~90×100 pt total with ears/legs/arms.
struct MascotView: View {
    let state: MascotState
    let restingMode: RestingMode

    /// Blink progress (0 = eyes open, 1 = eyes closed).
    var eyelidClosedness: CGFloat = 0

    /// Eye tracking offset for exercises or idle look-around.
    var pupilOffset: CGSize = .zero

    /// Bounce offset for alerting/celebrating states.
    var bounceOffset: CGFloat = 0

    /// Eye size multiplier (1.0 = normal, >1 for alerting).
    var eyeScale: CGFloat = 1.0

    /// Whether health score is high (drives stronger blush + sparkle).
    var isHighScore: Bool = false

    /// Alert glow opacity (pulsing ring).
    var alertGlowOpacity: Double = 0

    /// Current hand gesture.
    var handGesture: HandGesture = .none

    /// Wiggle angle for hand gesture animation.
    var gestureWiggle: Double = 0

    /// Body size constant.
    private let bodySize: CGFloat = 64

    var body: some View {
        ZStack {
            // Alert glow (behind everything)
            if state == .alerting {
                alertGlowRing
            }

            // Tiny legs (behind body)
            legs

            // Arms (behind body so they look attached)
            arms

            // Body
            creatureBody

            // Ears
            ears

            // Eye underglow (sparkle or tired)
            eyeUnderglow

            // Eyes
            eyes

            // Mouth
            mouth

            // Blush cheeks
            blushCheeks

            // Hand gesture overlay (in front of body)
            gestureOverlay

            // Expression overlays (zzz, particles, etc.)
            expressionOverlay
        }
        .offset(y: bounceOffset)
    }

    // MARK: - Alert Glow

    private var alertGlowRing: some View {
        RoundedRectangle(cornerRadius: 28)
            .stroke(MascotColors.alertGlow.opacity(alertGlowOpacity), lineWidth: 3)
            .frame(width: bodySize + 12, height: bodySize + 12)
            .blur(radius: 4)
    }

    // MARK: - Legs

    private var legs: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(legColor)
                .frame(width: 8, height: 10)

            RoundedRectangle(cornerRadius: 3)
                .fill(legColor)
                .frame(width: 8, height: 10)
        }
        .offset(y: bodySize / 2 + 3)
    }

    // MARK: - Arms

    /// Small stubby arms at body sides — hidden during hand gestures.
    @ViewBuilder
    private var arms: some View {
        if handGesture == .none {
            HStack(spacing: bodySize + 2) {
                // Left arm
                RoundedRectangle(cornerRadius: 4)
                    .fill(armColor)
                    .frame(width: 10, height: 14)
                    .rotationEffect(.degrees(-8))

                // Right arm
                RoundedRectangle(cornerRadius: 4)
                    .fill(armColor)
                    .frame(width: 10, height: 14)
                    .rotationEffect(.degrees(8))
            }
            .offset(y: 2)
        }
    }

    // MARK: - Body (color changes with state!)

    private var mainBodyColor: Color {
        switch state {
        case .idle:
            isHighScore
                ? Color(red: 0.70, green: 0.92, blue: 0.78)   // brighter mint when healthy
                : MascotColors.body
        case .concerned:
            Color(red: 0.82, green: 0.85, blue: 0.80)          // desaturated gray-green (tired)
        case .alerting:
            MascotColors.alertBody                               // warm peach
        case .resting:
            Color(red: 0.78, green: 0.85, blue: 0.90)          // soft blue (calm/rest)
        case .celebrating:
            Color(red: 0.78, green: 0.93, blue: 0.82)          // vibrant mint
        }
    }

    private var mainBodyEdge: Color {
        switch state {
        case .idle:
            isHighScore
                ? Color(red: 0.55, green: 0.85, blue: 0.65)
                : MascotColors.bodyEdge
        case .concerned:
            Color(red: 0.70, green: 0.73, blue: 0.68)
        case .alerting:
            MascotColors.alertBody.opacity(0.75)
        case .resting:
            Color(red: 0.65, green: 0.75, blue: 0.82)
        case .celebrating:
            Color(red: 0.60, green: 0.85, blue: 0.68)
        }
    }

    private var armColor: Color {
        mainBodyEdge
    }

    private var legColor: Color {
        mainBodyEdge
    }

    private var earColor: Color {
        mainBodyEdge
    }

    private var creatureBody: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(
                LinearGradient(
                    colors: [mainBodyColor, mainBodyEdge],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bodySize, height: bodySize)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(MascotColors.bodyStroke.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 3)
    }

    // MARK: - Ears

    private var ears: some View {
        ZStack {
            // Left ear
            Ellipse()
                .fill(earColor)
                .frame(width: 14, height: 12)
                .overlay(
                    Ellipse()
                        .fill(MascotColors.earInner)
                        .frame(width: 8, height: 6)
                )
                .rotationEffect(.degrees(-15))
                .offset(x: -18, y: -30)

            // Right ear
            Ellipse()
                .fill(earColor)
                .frame(width: 14, height: 12)
                .overlay(
                    Ellipse()
                        .fill(MascotColors.earInner)
                        .frame(width: 8, height: 6)
                )
                .rotationEffect(.degrees(15))
                .offset(x: 18, y: -30)
        }
    }

    // MARK: - Eye Underglow

    @ViewBuilder
    private var eyeUnderglow: some View {
        let eyeY: CGFloat = -5
        let eyeSpacing: CGFloat = 14

        if isHighScore && state == .idle {
            // Healthy: golden sparkle glow behind eyes
            HStack(spacing: eyeSpacing) {
                Circle()
                    .fill(MascotColors.eyeSparkle.opacity(0.50))
                    .frame(width: 20, height: 20)
                    .blur(radius: 5)
                Circle()
                    .fill(MascotColors.eyeSparkle.opacity(0.50))
                    .frame(width: 20, height: 20)
                    .blur(radius: 5)
            }
            .offset(y: eyeY)
        } else if state == .concerned {
            // Tired: dark circles under eyes
            HStack(spacing: eyeSpacing) {
                Ellipse()
                    .fill(MascotColors.eyeTired.opacity(0.35))
                    .frame(width: 14, height: 6)
                Ellipse()
                    .fill(MascotColors.eyeTired.opacity(0.35))
                    .frame(width: 14, height: 6)
            }
            .offset(y: eyeY + 9)
        }
    }

    // MARK: - Eyes

    @ViewBuilder
    private var eyes: some View {
        let eyeY: CGFloat = -5
        let eyeSpacing: CGFloat = 14
        let baseEyeSize: CGFloat = 12 * eyeScale

        if isSleepingEyes {
            // Sleeping: curved closed eyes ᴗ ᴗ
            HStack(spacing: eyeSpacing) {
                SleepEyeShape()
                    .stroke(MascotColors.eyeClosed, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 12, height: 6)
                SleepEyeShape()
                    .stroke(MascotColors.eyeClosed, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 12, height: 6)
            }
            .offset(y: eyeY)
        } else if isCelebratingEyes {
            // Celebrating: happy squint eyes ◠ ◠
            HStack(spacing: eyeSpacing) {
                HappyEyeShape()
                    .stroke(MascotColors.eye, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 12, height: 6)
                HappyEyeShape()
                    .stroke(MascotColors.eye, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 12, height: 6)
            }
            .offset(y: eyeY)
        } else if state == .concerned {
            // Concerned: droopy half-open eyes
            HStack(spacing: eyeSpacing) {
                concernedEye(size: baseEyeSize)
                concernedEye(size: baseEyeSize)
            }
            .offset(
                x: pupilOffset.width * 0.3,
                y: eyeY + 1 + pupilOffset.height * 0.3
            )
        } else if eyelidClosedness > 0.5 {
            // Blinking: horizontal lines
            HStack(spacing: eyeSpacing) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(MascotColors.eyeClosed)
                    .frame(width: 10, height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .fill(MascotColors.eyeClosed)
                    .frame(width: 10, height: 2)
            }
            .offset(y: eyeY)
        } else {
            // Normal bean eyes with highlights
            HStack(spacing: eyeSpacing) {
                beanEye(size: baseEyeSize)
                beanEye(size: baseEyeSize)
            }
            .offset(
                x: pupilOffset.width * 0.4,
                y: eyeY + pupilOffset.height * 0.4
            )
        }
    }

    private var isSleepingEyes: Bool {
        state == .resting && restingMode == .sleeping
    }

    private var isCelebratingEyes: Bool {
        state == .celebrating
    }

    /// Normal eye: big dark circle + dual sparkle highlights.
    private func beanEye(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(MascotColors.eye)
                .frame(width: size, height: size)

            // Primary highlight — upper-left
            Circle()
                .fill(MascotColors.eyeHighlight)
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(x: -size * 0.15, y: -size * 0.18)

            // Secondary highlight — lower-right
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: size * 0.12, y: size * 0.10)
        }
    }

    /// Tired/concerned eye: half-closed with no sparkle, looks drained.
    private func concernedEye(size: CGFloat) -> some View {
        ZStack {
            // Slightly smaller, dimmer eye
            Circle()
                .fill(MascotColors.eye.opacity(0.7))
                .frame(width: size * 0.85, height: size * 0.85)

            // Only one dim highlight
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: size * 0.2, height: size * 0.2)
                .offset(x: -size * 0.1, y: -size * 0.12)

            // Droopy eyelid overlay — top half covered
            Ellipse()
                .fill(mainBodyColor)
                .frame(width: size * 1.2, height: size * 0.5)
                .offset(y: -size * 0.35)
        }
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouth: some View {
        let mouthY: CGFloat = 8

        switch state {
        case .idle:
            SmileShape()
                .stroke(MascotColors.mouth, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 10, height: 5)
                .offset(y: mouthY)

        case .concerned:
            // Wavy worried mouth ~
            WavyMouthShape()
                .stroke(MascotColors.mouth.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 10, height: 4)
                .offset(y: mouthY + 1)

        case .alerting:
            Ellipse()
                .stroke(MascotColors.mouth, lineWidth: 1.5)
                .frame(width: 8, height: 6)
                .offset(y: mouthY + 1)

        case .resting:
            if restingMode == .sleeping {
                SmileShape()
                    .stroke(MascotColors.mouth.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .frame(width: 8, height: 4)
                    .offset(y: mouthY)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(MascotColors.mouth.opacity(0.6))
                    .frame(width: 8, height: 1.5)
                    .offset(y: mouthY + 1)
            }

        case .celebrating:
            SmileShape()
                .stroke(MascotColors.mouth, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 14, height: 7)
                .offset(y: mouthY)
        }
    }

    // MARK: - Blush Cheeks

    private var blushCheeks: some View {
        let blushSize: CGFloat = 10
        let opacity = blushOpacity

        return HStack(spacing: bodySize * 0.36) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [blushColor.opacity(opacity), blushColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: blushSize / 2
                    )
                )
                .frame(width: blushSize, height: blushSize)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [blushColor.opacity(opacity), blushColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: blushSize / 2
                    )
                )
                .frame(width: blushSize, height: blushSize)
        }
        .offset(y: 6)
    }

    private var blushColor: Color {
        state == .alerting ? MascotColors.alertBlush : MascotColors.blush
    }

    private var blushOpacity: Double {
        switch state {
        case .idle:         isHighScore ? 0.55 : 0.25
        case .concerned:    0.08  // almost no blush when tired
        case .alerting:     0.35
        case .resting:      restingMode == .sleeping ? 0.40 : 0.20
        case .celebrating:  0.60
        }
    }

    // MARK: - Gesture Overlay (visible arms doing eye-care actions)

    @ViewBuilder
    private var gestureOverlay: some View {
        switch handGesture {
        case .none:
            EmptyView()

        case .rubEyes:
            // Both hands raised to eyes, rubbing back and forth
            HStack(spacing: 6) {
                gestureHand
                    .rotationEffect(.degrees(25 + gestureWiggle))
                    .offset(x: 3)
                gestureHand
                    .rotationEffect(.degrees(-25 - gestureWiggle))
                    .offset(x: -3)
            }
            .offset(y: -5)

        case .lookFar:
            // Hand above eyes like a visor, looking into distance
            ZStack {
                gestureHand
                    .frame(width: 20, height: 8)
                    .rotationEffect(.degrees(gestureWiggle * 0.3))
                    .offset(x: 0, y: -16)

                // Tiny sparkle to indicate "looking far"
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .offset(x: 30, y: -20)
                Circle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(width: 2, height: 2)
                    .offset(x: 34, y: -26)
            }

        case .eyeExercise:
            // Hands pointing outward from eyes, moving
            HStack(spacing: 42) {
                gestureHand
                    .rotationEffect(.degrees(-30 + gestureWiggle * 0.5))
                gestureHand
                    .rotationEffect(.degrees(30 - gestureWiggle * 0.5))
            }
            .offset(y: -4)
        }
    }

    private var gestureHand: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(
                LinearGradient(
                    colors: [MascotColors.hand, MascotColors.accent],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 14, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(MascotColors.bodyStroke.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }

    // MARK: - Expression Overlays

    @ViewBuilder
    private var expressionOverlay: some View {
        switch state {
        case .resting where restingMode == .sleeping:
            sleepingZzz
        case .celebrating:
            celebrationParticles
        case .alerting:
            alertExclamation
        case .concerned:
            // Sweat drop for tired state
            sweatDrop
        default:
            EmptyView()
        }
    }

    private var sleepingZzz: some View {
        ZStack {
            Text("z")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(MascotColors.sleepText.opacity(0.6))
                .offset(x: 24, y: -26)
            Text("z")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(MascotColors.sleepText.opacity(0.5))
                .offset(x: 30, y: -34)
            Text("Z")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(MascotColors.sleepText.opacity(0.4))
                .offset(x: 34, y: -44)
        }
    }

    private var celebrationParticles: some View {
        let count = MascotAnimations.particleCount
        let radius = MascotAnimations.particleRadius
        let colors = MascotColors.particleColors

        return ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * .pi * 2
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 4, height: 4)
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius)
                    .opacity(0.7)
            }
        }
    }

    private var alertExclamation: some View {
        Text("!")
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(MascotColors.alertGlow)
            .offset(x: 28, y: -24)
    }

    /// Tiny sweat drop when concerned/tired.
    private var sweatDrop: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.5), Color.blue.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 6)
            .offset(x: 24, y: -18)
    }
}

// MARK: - Custom Shapes

/// Smile mouth arc ◡
struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

/// Wavy worried mouth ~ for concerned state
struct WavyMouthShape: Shape {
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

/// Happy squint eye ◠ (upside-down arc)
struct HappyEyeShape: Shape {
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

/// Sleeping eye ᴗ (downward arc)
struct SleepEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
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

// MARK: - CGSize Scalar Multiplication

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
