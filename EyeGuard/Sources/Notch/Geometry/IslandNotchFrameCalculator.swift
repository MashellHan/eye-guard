import CoreGraphics

/// Pure stateless calculator for IslandNotch window frame positioning.
/// Extracted from IslandNotchWindowController to enable unit testing.
struct IslandNotchFrameCalculator {
    /// Computes the new window frame for the notch panel.
    ///
    /// - Parameters:
    ///   - screenFrame: Full frame of the active screen (including origin for multi-screen).
    ///   - runtimeWidth: Clamped runtime width to apply.
    ///   - clampedOffset: Clamped horizontal offset from store.
    ///   - currentFrame: Current window frame (y and height are preserved).
    static func frame(
        screenFrame: CGRect,
        runtimeWidth: CGFloat,
        clampedOffset: CGFloat,
        currentFrame: CGRect
    ) -> CGRect {
        let baseX = (screenFrame.width - runtimeWidth) / 2
        let finalX = screenFrame.origin.x + baseX + clampedOffset
        return CGRect(
            x: finalX,
            y: currentFrame.origin.y,
            width: runtimeWidth,
            height: currentFrame.size.height
        )
    }
}
