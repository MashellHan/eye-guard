import Foundation
import SwiftUI

/// Hover-activation speed preset for the Notch.
///
/// The delay before a hover auto-expands the collapsed notch. Users can
/// pick a preset that matches their tolerance for accidental triggers
/// (slow) vs immediate responsiveness (instant).
public enum NotchHoverSpeed: String, CaseIterable, Identifiable, Sendable, Codable {
    case instant
    case fast
    case normal
    case slow

    public var id: String { rawValue }

    /// Delay in seconds before hover triggers open.
    public var delay: TimeInterval {
        switch self {
        case .instant: return 0
        case .fast:    return 0.15
        case .normal:  return 0.35
        case .slow:    return 0.6
        }
    }

    public var localizedName: String {
        switch self {
        case .instant: return "Instant"
        case .fast:    return "Fast"
        case .normal:  return "Normal"
        case .slow:    return "Slow"
        }
    }
}

/// Per-screen persisted geometry customization for the Notch window.
///
/// `horizontalOffset` shifts the rendered notch ±30pt along the top
/// edge so users with off-center displays (or visual preferences) can
/// fine-tune placement. `showOnExternalDisplays` controls whether a
/// software-drawn notch appears on non-notched external monitors.
public struct NotchCustomization: Equatable, Sendable, Codable {
    public var horizontalOffset: CGFloat
    public var hoverSpeed: NotchHoverSpeed
    public var showOnExternalDisplays: Bool

    public static let clampRange: ClosedRange<CGFloat> = -400 ... 400

    public init(
        horizontalOffset: CGFloat = 0,
        hoverSpeed: NotchHoverSpeed = .normal,
        showOnExternalDisplays: Bool = false
    ) {
        self.horizontalOffset = NotchCustomization.clamp(horizontalOffset)
        self.hoverSpeed = hoverSpeed
        self.showOnExternalDisplays = showOnExternalDisplays
    }

    /// Returns a copy with the offset clamped into `clampRange`.
    public func withOffset(_ offset: CGFloat) -> NotchCustomization {
        var copy = self
        copy.horizontalOffset = NotchCustomization.clamp(offset)
        return copy
    }

    public static let `default`: NotchCustomization = .init()

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, clampRange.lowerBound), clampRange.upperBound)
    }
}
