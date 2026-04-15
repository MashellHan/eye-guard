import AppKit
import Foundation
import Observation
import os

/// Analyzes dominant screen colors by periodically capturing a small screenshot
/// and sampling pixel colors to determine the dominant color family.
///
/// Suggests complementary colors to reduce eye strain from prolonged
/// exposure to a single color family.
///
/// Capture method: `CGWindowListCreateImage` (lightweight, no ML required).
/// Sampling frequency: Every 5 minutes.
@Observable
@MainActor
final class ColorAnalyzer {

    /// Shared singleton instance.
    static let shared = ColorAnalyzer()

    // MARK: - Published State

    /// The currently detected dominant color family.
    private(set) var dominantColorFamily: ColorFamily = .neutral

    /// The suggested complementary color family.
    private(set) var suggestedColorFamily: ColorFamily = .neutral

    /// Number of analyses performed today.
    private(set) var analysisCount: Int = 0

    /// History of detected color families (last 12 = 1 hour at 5-min intervals).
    private(set) var colorHistory: [ColorFamily] = []

    /// Whether the analyzer is currently running.
    private(set) var isRunning: Bool = false

    // MARK: - Color Families

    /// Broad color families detected from screen content.
    enum ColorFamily: String, Sendable, CaseIterable {
        case blue
        case red
        case green
        case yellow
        case purple
        case orange
        case neutral  // Gray, black, white — no strong color

        /// Display name in Chinese.
        var displayNameZH: String {
            switch self {
            case .blue: return "蓝色"
            case .red: return "红色"
            case .green: return "绿色"
            case .yellow: return "黄色"
            case .purple: return "紫色"
            case .orange: return "橙色"
            case .neutral: return "中性色"
            }
        }

        /// The complementary color family for balance.
        var complementary: ColorFamily {
            switch self {
            case .blue: return .green
            case .red: return .green
            case .green: return .blue
            case .yellow: return .purple
            case .purple: return .yellow
            case .orange: return .blue
            case .neutral: return .green  // Default suggestion
            }
        }

        /// SwiftUI-compatible color for display.
        var displayColor: (red: Double, green: Double, blue: Double) {
            switch self {
            case .blue: return (0.2, 0.5, 0.9)
            case .red: return (0.9, 0.3, 0.3)
            case .green: return (0.3, 0.8, 0.4)
            case .yellow: return (0.9, 0.8, 0.2)
            case .purple: return (0.6, 0.3, 0.8)
            case .orange: return (0.9, 0.6, 0.2)
            case .neutral: return (0.6, 0.6, 0.6)
            }
        }
    }

    // MARK: - Suggestion Messages

    /// Color-specific suggestion messages (Chinese + emoji).
    nonisolated static let suggestions: [ColorFamily: [(message: String, emoji: String)]] = [
        .blue: [
            ("看了很多蓝色屏幕，试试看看绿色植物吧", "🌿"),
            ("蓝光看多了，望望窗外的绿色放松一下", "🌲"),
            ("屏幕偏蓝，看看暖色调的东西缓解眼睛", "🌅"),
        ],
        .red: [
            ("屏幕偏红色调，看看绿色植物平衡一下", "🌿"),
            ("红色看多了，试试看看蓝天白云", "☁️"),
            ("暖色调屏幕看久了，看看清凉的颜色吧", "🏔️"),
        ],
        .green: [
            ("虽然绿色护眼，也要注意休息哦", "👀"),
            ("屏幕偏绿，看看蓝天白云放松一下", "☁️"),
            ("绿色看够了，欣赏一下其他颜色吧", "🌈"),
        ],
        .yellow: [
            ("屏幕偏暖色调，看看蓝天白云放松一下", "☁️"),
            ("黄色调看多了，试试看看紫色的花", "🌸"),
            ("暖色看久了，望望远处的冷色调景物", "🏔️"),
        ],
        .purple: [
            ("屏幕偏紫色调，看看明亮的黄绿色平衡", "🌻"),
            ("紫色看多了，试试看看阳光明媚的景色", "☀️"),
            ("深色调看久了，看看明亮温暖的颜色", "🌼"),
        ],
        .orange: [
            ("屏幕偏橙色调，看看蓝色天空放松一下", "🌊"),
            ("暖色调看多了，看看清凉的蓝绿色", "🐬"),
            ("橙色看久了，试试望望远处的蓝天", "⛅"),
        ],
        .neutral: [
            ("屏幕颜色很均衡，继续保持！", "👍"),
            ("眼睛需要看看色彩丰富的东西", "🌈"),
            ("试试看看窗外的自然风景吧", "🏞️"),
        ],
    ]

    // MARK: - Initialization

    private init() {}

    // MARK: - Analysis Task

    private var analysisTask: Task<Void, Never>?

    /// Starts periodic color analysis (every 5 minutes).
    func startAnalysis() {
        guard !isRunning else { return }
        isRunning = true

        analysisTask = Task {
            while !Task.isCancelled {
                await performAnalysis()
                try? await Task.sleep(for: .seconds(300)) // 5 minutes
            }
        }
        Log.colorAnalysis.info("Color analyzer started.")
    }

    /// Stops periodic color analysis.
    func stopAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isRunning = false
        Log.colorAnalysis.info("Color analyzer stopped.")
    }

    /// Performs a single color analysis of the current screen.
    func performAnalysis() async {
        guard let image = captureScreenSample() else {
            Log.colorAnalysis.warning("Failed to capture screen sample.")
            return
        }

        let family = analyzeImage(image)
        dominantColorFamily = family
        suggestedColorFamily = family.complementary
        analysisCount += 1

        // Maintain history (last 12 entries = 1 hour)
        colorHistory = Array((colorHistory + [family]).suffix(12))

        Log.colorAnalysis.info(
            "Analysis #\(self.analysisCount): dominant=\(family.rawValue), suggested=\(family.complementary.rawValue)"
        )
    }

    /// Returns a color suggestion message based on the dominant color.
    func currentSuggestion() -> (message: String, emoji: String) {
        let family = dominantColorFamily
        let suggestions = Self.suggestions[family] ?? Self.suggestions[.neutral]!
        return suggestions.randomElement()!
    }

    /// Returns the full suggestion text for the mascot speech bubble.
    func suggestionBubbleText() -> String {
        let suggestion = currentSuggestion()
        return "\(suggestion.emoji) \(suggestion.message)"
    }

    /// Resets daily statistics.
    func resetDaily() {
        analysisCount = 0
        colorHistory = []
        dominantColorFamily = .neutral
        suggestedColorFamily = .neutral
    }

    /// Returns the most frequently detected color family from recent history.
    func mostFrequentRecentColor() -> ColorFamily {
        guard !colorHistory.isEmpty else { return .neutral }

        var counts: [ColorFamily: Int] = [:]
        for family in colorHistory {
            counts[family, default: 0] += 1
        }

        return counts.max(by: { $0.value < $1.value })?.key ?? .neutral
    }

    // MARK: - Screen Capture

    /// Captures a small screenshot of the main display using CGWindowListCreateImage.
    /// Returns nil if capture fails or permissions are not granted.
    private func captureScreenSample() -> CGImage? {
        // Capture the entire main display at reduced quality
        let displayID = CGMainDisplayID()
        let displayBounds = CGDisplayBounds(displayID)

        // We only need a small sample — scale down for performance
        guard let image = CGWindowListCreateImage(
            displayBounds,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        ) else {
            return nil
        }

        return image
    }

    // MARK: - Color Analysis

    /// Analyzes a CGImage by sampling pixels to determine the dominant color family.
    /// Uses grid-based sampling (every 50th pixel) for efficiency.
    private func analyzeImage(_ image: CGImage) -> ColorFamily {
        let width = image.width
        let height = image.height

        guard width > 0, height > 0 else { return .neutral }

        // Create bitmap context to read pixel data
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .neutral
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample every 50th pixel in a grid pattern
        let step = 50
        var colorCounts: [ColorFamily: Int] = [:]

        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = (y * width + x) * bytesPerPixel
                let r = Double(pixelData[offset]) / 255.0
                let g = Double(pixelData[offset + 1]) / 255.0
                let b = Double(pixelData[offset + 2]) / 255.0

                let family = classifyColor(r: r, g: g, b: b)
                colorCounts[family, default: 0] += 1

                x += step
            }
            y += step
        }

        // Return the most frequent non-neutral family, or neutral if dominant
        let sorted = colorCounts.sorted { $0.value > $1.value }

        // If neutral is dominant but there's a strong secondary, prefer the secondary
        if let first = sorted.first, first.key == .neutral, sorted.count > 1 {
            let total = sorted.reduce(0) { $0 + $1.value }
            let neutralRatio = Double(first.value) / Double(max(total, 1))

            // If neutral is less than 70%, use the top non-neutral color
            if neutralRatio < 0.7, let second = sorted.dropFirst().first {
                return second.key
            }
        }

        return sorted.first?.key ?? .neutral
    }

    /// Classifies an RGB color into a broad color family.
    private func classifyColor(r: Double, g: Double, b: Double) -> ColorFamily {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let saturation = maxC > 0 ? (maxC - minC) / maxC : 0

        // Low saturation = neutral (gray/black/white)
        guard saturation > 0.15 else { return .neutral }

        // Calculate hue (0-360)
        let hue: Double
        if maxC == minC {
            return .neutral
        } else if maxC == r {
            hue = 60.0 * ((g - b) / (maxC - minC)).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            hue = 60.0 * ((b - r) / (maxC - minC) + 2)
        } else {
            hue = 60.0 * ((r - g) / (maxC - minC) + 4)
        }

        let normalizedHue = hue < 0 ? hue + 360 : hue

        // Classify by hue ranges
        switch normalizedHue {
        case 0..<15: return .red
        case 15..<45: return .orange
        case 45..<75: return .yellow
        case 75..<165: return .green
        case 165..<260: return .blue
        case 260..<330: return .purple
        case 330..<360: return .red
        default: return .neutral
        }
    }
}
