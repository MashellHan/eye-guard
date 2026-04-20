#if os(macOS)
import Testing
import CoreGraphics
@testable import EyeGuard

@Suite("IslandNotchFrameCalculator")
struct IslandNotchGeometryApplicationTests {

    // a) Builtin screen origin (0,0), offset 0: finalX = (screenWidth-runtimeWidth)/2
    @Test("frame centers on builtin screen with zero offset")
    func frameCenteredBuiltin() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let runtimeWidth: CGFloat = 200
        let currentFrame = CGRect(x: 0, y: 850, width: 100, height: 36)
        let result = IslandNotchFrameCalculator.frame(
            screenFrame: screenFrame,
            runtimeWidth: runtimeWidth,
            clampedOffset: 0,
            currentFrame: currentFrame
        )
        let expectedX = (screenFrame.width - runtimeWidth) / 2
        #expect(result.origin.x == expectedX)
    }

    // b) External screen at origin (2560,0): finalX includes origin.x offset
    @Test("frame includes external screen origin.x offset")
    func frameExternalScreenOrigin() {
        let screenFrame = CGRect(x: 2560, y: 0, width: 2560, height: 1440)
        let runtimeWidth: CGFloat = 300
        let currentFrame = CGRect(x: 0, y: 1404, width: 100, height: 36)
        let result = IslandNotchFrameCalculator.frame(
            screenFrame: screenFrame,
            runtimeWidth: runtimeWidth,
            clampedOffset: 0,
            currentFrame: currentFrame
        )
        let baseX = (screenFrame.width - runtimeWidth) / 2
        let expectedX = screenFrame.origin.x + baseX
        #expect(result.origin.x == expectedX)
    }

    // c) runtimeWidth is applied to returned frame.size.width
    @Test("frame applies runtimeWidth to size.width")
    func frameAppliesRuntimeWidth() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let runtimeWidth: CGFloat = 250
        let currentFrame = CGRect(x: 0, y: 864, width: 100, height: 36)
        let result = IslandNotchFrameCalculator.frame(
            screenFrame: screenFrame,
            runtimeWidth: runtimeWidth,
            clampedOffset: 0,
            currentFrame: currentFrame
        )
        #expect(result.size.width == runtimeWidth)
    }

    // d) y and height unchanged (from currentFrame)
    @Test("frame preserves currentFrame origin.y and height")
    func framePreservesYAndHeight() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let currentFrame = CGRect(x: 0, y: 864, width: 100, height: 42)
        let result = IslandNotchFrameCalculator.frame(
            screenFrame: screenFrame,
            runtimeWidth: 200,
            clampedOffset: 0,
            currentFrame: currentFrame
        )
        #expect(result.origin.y == currentFrame.origin.y)
        #expect(result.size.height == currentFrame.size.height)
    }
}
#endif
