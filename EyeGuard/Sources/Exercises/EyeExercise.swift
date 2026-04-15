import Foundation

/// Guided eye exercise routines based on ophthalmological guidelines.
///
/// Each exercise targets a different aspect of eye health — from tear film
/// refreshing (rapid blink) to ciliary muscle relaxation (near-far focus).
/// Used during break time alongside the mascot character.
enum EyeExercise: String, CaseIterable, Sendable {

    /// Look up, down, left, right in sequence.
    case lookAround

    /// Alternate focus between a near and far object.
    case nearFar

    /// Roll eyes smoothly in a circular motion.
    case circularMotion

    /// Close eyes and warm with palms (palming technique).
    case palmWarming

    /// Blink rapidly 20 times to refresh the tear film.
    case rapidBlink

    // MARK: - Display Names

    /// English display name.
    var name: String {
        switch self {
        case .lookAround:     return "Look Around"
        case .nearFar:        return "Near-Far Focus"
        case .circularMotion: return "Circular Motion"
        case .palmWarming:    return "Palm Warming"
        case .rapidBlink:     return "Rapid Blink"
        }
    }

    /// Chinese display name (中文名称).
    var chineseName: String {
        switch self {
        case .lookAround:     return "上下左右看"
        case .nearFar:        return "远近调焦"
        case .circularMotion: return "转圈"
        case .palmWarming:    return "掌心热敷"
        case .rapidBlink:     return "快速眨眼"
        }
    }

    /// Duration of this exercise in seconds.
    var duration: Int {
        switch self {
        case .lookAround:     return 40  // 4 directions × 3 sec hold + transitions
        case .nearFar:        return 30  // 5 cycles of near/far
        case .circularMotion: return 30  // ~5 circles each direction
        case .palmWarming:    return 30  // Relaxation period
        case .rapidBlink:     return 20  // 20 blinks
        }
    }

    /// SF Symbol icon name for this exercise.
    var iconName: String {
        switch self {
        case .lookAround:     return "arrow.up.and.down.and.arrow.left.and.right"
        case .nearFar:        return "circle.and.line.horizontal"
        case .circularMotion: return "arrow.trianglehead.2.clockwise.rotate.90"
        case .palmWarming:    return "hand.raised.fill"
        case .rapidBlink:     return "eye"
        }
    }

    /// Step-by-step instructions for this exercise.
    var instructions: [String] {
        switch self {
        case .lookAround:
            return [
                "Look up and hold for 3 seconds",
                "Look down and hold for 3 seconds",
                "Look left and hold for 3 seconds",
                "Look right and hold for 3 seconds",
                "Look up-right diagonally",
                "Look down-left diagonally",
                "Look up-left diagonally",
                "Look down-right diagonally",
                "Return to center and relax",
            ]

        case .nearFar:
            return [
                "Hold your thumb 6 inches from your nose",
                "Focus on your thumb for 3 seconds",
                "Shift focus to a distant object (20+ feet)",
                "Hold distant focus for 3 seconds",
                "Repeat near-far cycle 5 times",
                "Blink gently between each cycle",
            ]

        case .circularMotion:
            return [
                "Roll your eyes clockwise slowly",
                "Complete 5 full circles",
                "Pause and blink gently",
                "Roll your eyes counter-clockwise",
                "Complete 5 full circles",
                "Close eyes and relax",
            ]

        case .palmWarming:
            return [
                "Rub your palms together vigorously",
                "Cup warm palms over closed eyes",
                "Feel the warmth relax your eye muscles",
                "Breathe deeply and slowly",
                "Keep palms in place for 30 seconds",
                "Slowly remove palms and open eyes",
            ]

        case .rapidBlink:
            return [
                "Blink rapidly 20 times",
                "Each blink should be quick but full",
                "This refreshes your tear film",
                "Pause briefly after 10 blinks",
                "Continue with 10 more blinks",
                "Close eyes and rest for 3 seconds",
            ]
        }
    }

    /// Chinese step-by-step instructions.
    var instructionsChinese: [String] {
        switch self {
        case .lookAround:
            return [
                "向上看，保持3秒",
                "向下看，保持3秒",
                "向左看，保持3秒",
                "向右看，保持3秒",
                "看右上方对角线",
                "看左下方对角线",
                "看左上方对角线",
                "看右下方对角线",
                "回到中心，放松",
            ]

        case .nearFar:
            return [
                "将拇指放在鼻子前方15厘米处",
                "注视拇指3秒",
                "将目光转向远处物体（6米以上）",
                "保持远距离对焦3秒",
                "重复远近循环5次",
                "每次循环之间轻轻眨眼",
            ]

        case .circularMotion:
            return [
                "缓慢顺时针转动眼球",
                "完成5圈",
                "停下来轻轻眨眼",
                "缓慢逆时针转动眼球",
                "完成5圈",
                "闭眼放松",
            ]

        case .palmWarming:
            return [
                "双掌快速搓热",
                "将温暖的手掌轻轻覆盖闭合的双眼",
                "感受温暖放松眼部肌肉",
                "深呼吸，缓慢呼吸",
                "保持30秒",
                "慢慢移开手掌，睁开眼睛",
            ]

        case .rapidBlink:
            return [
                "快速眨眼20次",
                "每次眨眼要快速但完整",
                "这可以刷新泪膜",
                "眨10次后短暂停顿",
                "继续再眨10次",
                "闭眼休息3秒",
            ]
        }
    }

    /// Pupil movement pattern for the mascot (normalized -1…1 offsets).
    /// Returns an array of (CGSize, duration) pairs for animation.
    var mascotPupilPattern: [(offset: (Double, Double), holdSeconds: Double)] {
        switch self {
        case .lookAround:
            return [
                ((0, -1), 3),     // Up
                ((0, 1), 3),      // Down
                ((-1, 0), 3),     // Left
                ((1, 0), 3),      // Right
                ((0.7, -0.7), 3), // Up-right
                ((-0.7, 0.7), 3), // Down-left
                ((-0.7, -0.7), 3), // Up-left
                ((0.7, 0.7), 3),  // Down-right
                ((0, 0), 2),      // Center
            ]

        case .nearFar:
            // Simulated with scale: small pupil = far, large approach = near
            return [
                ((0, 0), 3),  // Near (pupil centered, will scale up)
                ((0, 0), 3),  // Far (pupil centered, will scale down)
                ((0, 0), 3),
                ((0, 0), 3),
                ((0, 0), 3),
                ((0, 0), 3),
            ]

        case .circularMotion:
            // Full circle in 12 steps
            let steps = 12
            let twoPi = Double.pi * 2
            var pattern: [(offset: (Double, Double), holdSeconds: Double)] = []
            for i in 0..<steps {
                let angle = twoPi * Double(i) / Double(steps)
                pattern.append(((cos(angle), -sin(angle)), 0.5))
            }
            // Reverse circle
            for i in stride(from: steps - 1, through: 0, by: -1) {
                let angle = twoPi * Double(i) / Double(steps)
                pattern.append(((cos(angle), -sin(angle)), 0.5))
            }
            pattern.append(((0, 0), 2)) // Center rest
            return pattern

        case .palmWarming:
            // Minimal movement — eyes closed
            return [
                ((0, 0), 30),
            ]

        case .rapidBlink:
            // Centered — blinking is the animation
            return [
                ((0, 0), 20),
            ]
        }
    }
}
