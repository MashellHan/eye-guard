#if os(macOS)
import Testing
import AppKit
@testable import EyeGuard

@Suite("MascotPositionCalculator")
struct MascotPositionCalculatorTests {

    // a) Built-in screen (origin 0,0), full mode
    @Test("bottomRight full mode on builtin screen")
    func bottomRightFullBuiltin() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(width: 120, height: 140)
        let point = MascotPositionCalculator.bottomRight(
            in: visibleFrame,
            windowSize: windowSize,
            isPeeking: false,
            peekVisibleHeight: 50
        )
        #expect(point.x == visibleFrame.maxX - windowSize.width - 20)
        #expect(point.y == visibleFrame.minY + 20)
    }

    // b) External screen is main; we pass internal screen's visibleFrame → coords stay in builtin range
    @Test("bottomRight with external main screen passes builtin visibleFrame")
    func bottomRightBuiltinFrameRegression() {
        // Simulate: external screen at origin (2560,0), 2560×1440 is main.
        // But we always pass builtin visibleFrame to the calculator.
        let builtinVisible = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(width: 120, height: 140)
        let point = MascotPositionCalculator.bottomRight(
            in: builtinVisible,
            windowSize: windowSize,
            isPeeking: false,
            peekVisibleHeight: 50
        )
        // Result must be within builtin screen x range
        #expect(point.x >= 0)
        #expect(point.x < 1440)
        #expect(point.y >= 0)
        #expect(point.y < 900)
    }

    // c) Peek mode
    @Test("bottomRight peek mode pushes window below screen edge")
    func bottomRightPeekMode() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let windowSize = CGSize(width: 120, height: 140)
        let peekVisibleHeight: CGFloat = 50
        let point = MascotPositionCalculator.bottomRight(
            in: visibleFrame,
            windowSize: windowSize,
            isPeeking: true,
            peekVisibleHeight: peekVisibleHeight
        )
        let expectedY = visibleFrame.minY - (windowSize.height - peekVisibleHeight)
        #expect(point.y == expectedY)
    }

    // d) Extreme: window bigger than screen — must not crash
    @Test("bottomRight does not crash when window larger than screen")
    func bottomRightOversizedWindow() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let windowSize = CGSize(width: 500, height: 500)
        let point = MascotPositionCalculator.bottomRight(
            in: visibleFrame,
            windowSize: windowSize,
            isPeeking: false,
            peekVisibleHeight: 50
        )
        // Simply must not crash; x will be negative which is fine
        #expect(point.x == visibleFrame.maxX - windowSize.width - 20)
    }
}
#endif
