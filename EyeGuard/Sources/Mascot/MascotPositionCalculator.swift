import AppKit

/// Pure stateless calculator for mascot window positioning.
/// Extracted from MascotWindowController to enable unit testing.
struct MascotPositionCalculator {
    /// Returns the bottom-right origin for the mascot window.
    ///
    /// - Parameters:
    ///   - visibleFrame: The visible frame of the **target** screen (builtin preferred).
    ///   - windowSize: Current size of the mascot window.
    ///   - isPeeking: Whether the mascot is in peek (partially hidden) mode.
    ///   - peekVisibleHeight: How many points remain visible in peek mode.
    static func bottomRight(
        in visibleFrame: CGRect,
        windowSize: CGSize,
        isPeeking: Bool,
        peekVisibleHeight: CGFloat
    ) -> NSPoint {
        let x = visibleFrame.maxX - windowSize.width - 20
        let y: CGFloat = isPeeking
            ? visibleFrame.minY - (windowSize.height - peekVisibleHeight)
            : visibleFrame.minY + 20
        return NSPoint(x: x, y: y)
    }
}
