//
//  NotchHardwareDetector.swift
//  EyeGuard — Notch Module (Phase 1)
//
//  Pure helpers for deriving hardware-notch metrics and clamping
//  user-provided customization values. Based on mio-guard's
//  NotchHardwareDetector.swift, stripped of the NotchCustomizationStore
//  dependency (Phase 1 uses defaults only).
//

import AppKit
import CoreGraphics

enum NotchHardwareDetector {

    /// Minimum idle notch width — prevents the collapsed display from
    /// shrinking narrower than "icon + 3-char status + indicator".
    static let minIdleWidth: CGFloat = 140

    /// Minimum and maximum custom notch heights.
    static let minNotchHeight: CGFloat = 20
    static let maxNotchHeight: CGFloat = 80

    /// Whether `screen` has a physical notch (ignores user overrides).
    static func hasHardwareNotch(on screen: NSScreen?) -> Bool {
        guard let screen else { return false }
        return screen.safeAreaInsets.top > 0
    }

    /// Width of the hardware notch in points, derived from safe-area
    /// insets. Returns 0 when there is no physical notch.
    static func hardwareNotchWidth(on screen: NSScreen?) -> CGFloat {
        guard hasHardwareNotch(on: screen), let screen else { return 0 }
        let insets = screen.safeAreaInsets
        return screen.frame.width - insets.left - insets.right
    }

    /// Clamp a user-provided notch height to the valid range.
    static func clampedHeight(_ height: CGFloat) -> CGFloat {
        max(minNotchHeight, min(height, maxNotchHeight))
    }

    /// Clamp the measured content width against the user's `maxWidth`
    /// and the hard `minIdleWidth` floor.
    static func clampedWidth(
        measuredContentWidth: CGFloat,
        maxWidth: CGFloat
    ) -> CGFloat {
        max(minIdleWidth, min(measuredContentWidth, maxWidth))
    }

    /// Clamp the horizontal offset so the notch stays on screen.
    /// Stateless; safe to call render-side on any screen.
    static func clampedHorizontalOffset(
        storedOffset: CGFloat,
        runtimeWidth: CGFloat,
        screenWidth: CGFloat
    ) -> CGFloat {
        let baseX = (screenWidth - runtimeWidth) / 2
        let minOffset = -baseX
        let maxOffset = screenWidth - baseX - runtimeWidth
        return max(minOffset, min(storedOffset, maxOffset))
    }
}
