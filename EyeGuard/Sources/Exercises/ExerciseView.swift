import SwiftUI

/// Displays a single eye exercise with animated visual instruction
/// and a countdown timer for the current step.
///
/// Animation types by exercise:
/// - lookAround: Animated arrow pointing in the current direction
/// - nearFar: Circle that grows (near) and shrinks (far)
/// - circularMotion: Dot tracing a circular path
/// - palmWarming: Hands emoji with warm glow
/// - rapidBlink: Blinking eye animation
struct ExerciseView: View {

    let exercise: EyeExercise

    /// Current step index within the exercise instructions.
    @Binding var currentStep: Int

    /// Remaining seconds for the entire exercise.
    @Binding var remainingSeconds: Int

    // MARK: - Animation State

    @State private var animationPhase: Double = 0
    @State private var animationTimer: Timer?
    @State private var directionIndex: Int = 0
    @State private var circleScale: CGFloat = 0.3
    @State private var dotAngle: Double = 0
    @State private var isBlinkClosed: Bool = false
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: 16) {
            // Exercise title
            exerciseHeader

            // Animated visual
            animationArea
                .frame(width: 180, height: 180)

            // Current instruction
            instructionText

            // Countdown
            countdownDisplay
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: exercise) {
            directionIndex = 0
            circleScale = 0.3
            dotAngle = 0
            isBlinkClosed = false
            glowOpacity = 0.3
            stopAnimation()
            startAnimation()
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: exercise.iconName)
                .font(.title2)
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(exercise.chineseName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Animation Area

    @ViewBuilder
    private var animationArea: some View {
        switch exercise {
        case .lookAround:
            lookAroundAnimation

        case .nearFar:
            nearFarAnimation

        case .circularMotion:
            circularMotionAnimation

        case .palmWarming:
            palmWarmingAnimation

        case .rapidBlink:
            rapidBlinkAnimation
        }
    }

    // MARK: - Look Around Animation

    private var lookAroundAnimation: some View {
        let directions: [(String, CGSize)] = [
            ("arrow.up", CGSize(width: 0, height: -50)),
            ("arrow.down", CGSize(width: 0, height: 50)),
            ("arrow.left", CGSize(width: -50, height: 0)),
            ("arrow.right", CGSize(width: 50, height: 0)),
            ("arrow.up.right", CGSize(width: 40, height: -40)),
            ("arrow.down.left", CGSize(width: -40, height: 40)),
            ("arrow.up.left", CGSize(width: -40, height: -40)),
            ("arrow.down.right", CGSize(width: 40, height: 40)),
        ]

        let safeIndex = directionIndex % directions.count
        let direction = directions[safeIndex]

        return ZStack {
            // Background circle
            Circle()
                .stroke(Color.teal.opacity(0.2), lineWidth: 2)
                .frame(width: 140, height: 140)

            // Center dot
            Circle()
                .fill(Color.teal.opacity(0.3))
                .frame(width: 10, height: 10)

            // Direction arrow
            Image(systemName: direction.0)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.teal)
                .offset(direction.1)
                .animation(.easeInOut(duration: 0.5), value: directionIndex)

            // Direction indicator dot
            Circle()
                .fill(Color.teal)
                .frame(width: 14, height: 14)
                .offset(direction.1)
                .animation(.easeInOut(duration: 0.5), value: directionIndex)
        }
    }

    // MARK: - Near-Far Animation

    private var nearFarAnimation: some View {
        ZStack {
            // Outer reference ring
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                .frame(width: 140, height: 140)

            // Pulsing focus circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.blue.opacity(0.6), .blue.opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: 2.5), value: circleScale)

            // Center focus point
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)

            // Label
            Text(circleScale > 0.6 ? "Near 近" : "Far 远")
                .font(.caption)
                .foregroundStyle(.blue)
                .offset(y: 80)
        }
    }

    // MARK: - Circular Motion Animation

    private var circularMotionAnimation: some View {
        let radius: CGFloat = 55
        let dotX = cos(dotAngle) * Double(radius)
        let dotY = sin(dotAngle) * Double(radius)

        return ZStack {
            // Orbit path
            Circle()
                .stroke(
                    Color.purple.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                )
                .frame(width: radius * 2, height: radius * 2)

            // Center eye
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 20, height: 20)

            // Tracking dot
            Circle()
                .fill(Color.purple)
                .frame(width: 16, height: 16)
                .shadow(color: .purple.opacity(0.5), radius: 6)
                .offset(x: CGFloat(dotX), y: CGFloat(dotY))

            // Trail effect
            ForEach(1..<4, id: \.self) { i in
                let trailAngle = dotAngle - Double(i) * 0.3
                let tx = cos(trailAngle) * Double(radius)
                let ty = sin(trailAngle) * Double(radius)
                Circle()
                    .fill(Color.purple.opacity(0.3 - Double(i) * 0.08))
                    .frame(width: CGFloat(16 - i * 3), height: CGFloat(16 - i * 3))
                    .offset(x: CGFloat(tx), y: CGFloat(ty))
            }
        }
    }

    // MARK: - Palm Warming Animation

    private var palmWarmingAnimation: some View {
        ZStack {
            // Warm glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .orange.opacity(glowOpacity),
                            .orange.opacity(glowOpacity * 0.3),
                            .clear,
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .animation(.easeInOut(duration: 2.0), value: glowOpacity)

            // Hands emoji
            Text("🫲🫱")
                .font(.system(size: 56))

            // Warmth particles
            Text("✨")
                .font(.system(size: 14))
                .offset(x: -30, y: -40)
                .opacity(glowOpacity)

            Text("✨")
                .font(.system(size: 12))
                .offset(x: 35, y: -35)
                .opacity(glowOpacity * 0.8)

            Text("🔥")
                .font(.system(size: 10))
                .offset(y: -50)
                .opacity(glowOpacity * 0.6)
        }
    }

    // MARK: - Rapid Blink Animation

    private var rapidBlinkAnimation: some View {
        ZStack {
            // Eye shape
            if isBlinkClosed {
                // Closed eye
                Text("😌")
                    .font(.system(size: 64))
            } else {
                // Open eye
                Text("👁️")
                    .font(.system(size: 64))
            }

            // Blink counter
            let blinkCount = Int(animationPhase) % 21
            Text("×\(blinkCount)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.teal)
                .offset(x: 50, y: -30)
        }
    }

    // MARK: - Instruction Text

    private var instructionText: some View {
        let instructions = exercise.instructions
        let chineseInstructions = exercise.instructionsChinese
        let safeStep = min(currentStep, instructions.count - 1, chineseInstructions.count - 1)

        return VStack(spacing: 4) {
            Text(instructions[max(0, safeStep)])
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text(chineseInstructions[max(0, safeStep)])
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
    }

    // MARK: - Countdown Display

    private var countdownDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .foregroundStyle(.teal)

            Text("\(remainingSeconds)s")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { _ in
            Task { @MainActor in
                updateAnimation()
            }
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private var animationInterval: TimeInterval {
        switch exercise {
        case .lookAround:     return 3.0
        case .nearFar:        return 3.0
        case .circularMotion: return 0.05
        case .palmWarming:    return 2.0
        case .rapidBlink:     return 0.5
        }
    }

    private func updateAnimation() {
        animationPhase += 1

        switch exercise {
        case .lookAround:
            withAnimation(.easeInOut(duration: 0.5)) {
                directionIndex = (directionIndex + 1) % 8
            }
            // Advance step every 2 direction changes
            let newStep = min(Int(animationPhase) / 2, exercise.instructions.count - 1)
            if newStep != currentStep {
                currentStep = newStep
            }

        case .nearFar:
            withAnimation(.easeInOut(duration: 2.5)) {
                circleScale = circleScale > 0.6 ? 0.3 : 1.0
            }
            let newStep = min(Int(animationPhase) / 2, exercise.instructions.count - 1)
            if newStep != currentStep {
                currentStep = newStep
            }

        case .circularMotion:
            let speed = 0.08
            dotAngle += speed
            if dotAngle > Double.pi * 4 {
                dotAngle = 0
            }
            let newStep = min(
                Int(dotAngle / (Double.pi * 2) * 3),
                exercise.instructions.count - 1
            )
            if newStep != currentStep {
                currentStep = newStep
            }

        case .palmWarming:
            withAnimation(.easeInOut(duration: 2.0)) {
                glowOpacity = glowOpacity > 0.5 ? 0.2 : 0.7
            }
            let newStep = min(Int(animationPhase) / 2, exercise.instructions.count - 1)
            if newStep != currentStep {
                currentStep = newStep
            }

        case .rapidBlink:
            withAnimation(.easeInOut(duration: 0.15)) {
                isBlinkClosed.toggle()
            }
            let newStep = min(Int(animationPhase) / 8, exercise.instructions.count - 1)
            if newStep != currentStep {
                currentStep = newStep
            }
        }
    }
}
