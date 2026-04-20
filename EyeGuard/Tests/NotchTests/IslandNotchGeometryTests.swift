//
//  IslandNotchGeometryTests.swift
//  EyeGuard — Day 4.1b carry-over coverage
//
//  Mirrors NotchGeometryTests against the mio-framework `IslandNotchGeometry`
//  + `IslandNotchHardwareDetector` so the geometry contract is verified on
//  the new code path before the legacy `Notch/Geometry/` directory is
//  deleted in step 4.1.
//

import Testing
import CoreGraphics
@testable import EyeGuard

@Suite("IslandNotchGeometry")
struct IslandNotchGeometryTests {

    /// A representative geometry: 14-inch MacBook Pro notch on a 3024x1964 display.
    private var fixture: IslandNotchGeometry {
        IslandNotchGeometry(
            deviceNotchRect: CGRect(x: 1400, y: 0, width: 224, height: 38),
            screenRect: CGRect(x: 0, y: 0, width: 3024, height: 1964),
            windowHeight: 400
        )
    }

    // MARK: A) Notch rect

    @Test("notchScreenRect is centered along the top edge")
    func notchRectCentered() {
        let g = fixture
        let rect = g.notchScreenRect()
        #expect(rect.width == CGFloat(224))
        #expect(rect.height == CGFloat(38))
        #expect(rect.midX == CGFloat(3024) / 2)
        #expect(rect.maxY == CGFloat(1964))
    }

    @Test("notchScreenRect honors horizontalOffset")
    func notchRectOffset() {
        let rect = fixture.notchScreenRect(horizontalOffset: 100)
        let baseline = fixture.notchScreenRect()
        #expect(rect.minX == baseline.minX + 100)
    }

    // MARK: B) Opened rect

    @Test("openedScreenRect adds 10px padding on each dimension")
    func openedRectPadding() {
        let size = CGSize(width: 400, height: 200)
        let rect = fixture.openedScreenRect(for: size)
        #expect(rect.width == 410)
        #expect(rect.height == 210)
        #expect(rect.maxY == 1964)
    }

    // MARK: C) Hit testing

    @Test("isPointInNotch — interior point returns true")
    func hitInterior() {
        let g = fixture
        let center = CGPoint(x: 1512, y: 1945)
        #expect(g.isPointInNotch(center) == true)
    }

    @Test("isPointInNotch — far-away point returns false")
    func hitMiss() {
        let g = fixture
        let corner = CGPoint(x: 10, y: 10)
        #expect(g.isPointInNotch(corner) == false)
    }

    @Test("isPointInOpenedPanel / isPointOutsidePanel are inverse")
    func insideOutsidePanelInvert() {
        let g = fixture
        let size = CGSize(width: 400, height: 200)
        let inside = CGPoint(x: 1512, y: 1850)
        let outside = CGPoint(x: 10, y: 10)
        #expect(g.isPointInOpenedPanel(inside, size: size) == true)
        #expect(g.isPointOutsidePanel(inside, size: size) == false)
        #expect(g.isPointOutsidePanel(outside, size: size) == true)
    }

    // MARK: D) Collapsed rect (wings)

    @Test("collapsedScreenRect includes expansion wings")
    func collapsedIncludesWings() {
        let g = fixture
        let rect = g.collapsedScreenRect(expansionWidth: 240)
        #expect(rect.width == CGFloat(224 + 240))
        #expect(rect.height == CGFloat(38))
    }

    // MARK: E) Hardware detector — parity with legacy NotchHardwareDetector clamps

    @Test("IslandNotchHardwareDetector clamps notch height to valid range")
    func heightClamp() {
        #expect(IslandNotchHardwareDetector.clampedHeight(10) == IslandNotchHardwareDetector.minNotchHeight)
        #expect(IslandNotchHardwareDetector.clampedHeight(200) == IslandNotchHardwareDetector.maxNotchHeight)
        #expect(IslandNotchHardwareDetector.clampedHeight(40) == 40)
    }

    @Test("IslandNotchHardwareDetector clamps width above minIdleWidth")
    func widthClamp() {
        let clamped = IslandNotchHardwareDetector.clampedWidth(
            measuredContentWidth: 50,
            maxWidth: 500
        )
        #expect(clamped == IslandNotchHardwareDetector.minIdleWidth)
    }

    @Test("IslandNotchHardwareDetector clamps horizontal offset against screen bounds")
    func offsetClamp() {
        let offset = IslandNotchHardwareDetector.clampedHorizontalOffset(
            storedOffset: 100_000,
            runtimeWidth: 400,
            screenWidth: 3024
        )
        let halfSlack = (3024 - 400) / 2
        #expect(offset <= CGFloat(halfSlack))
        #expect(offset >= -CGFloat(halfSlack))
    }
}
