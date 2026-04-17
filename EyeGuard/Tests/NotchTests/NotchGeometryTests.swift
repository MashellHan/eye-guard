//
//  NotchGeometryTests.swift
//  EyeGuard — Phase 1
//
//  Tests for pure geometry calculations.
//

import Testing
import CoreGraphics
@testable import EyeGuard

@Suite("NotchGeometry")
struct NotchGeometryTests {

    /// A representative geometry: 14-inch MacBook Pro notch on a 3024x1964 display.
    private var fixture: NotchGeometry {
        NotchGeometry(
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

    @Test("isPointInNotch — 10px padding forgives slightly-outside clicks")
    func hitForgiveness() {
        let g = fixture
        // 5px below the strict notch area — should still hit thanks to the
        // -10/-5 inset applied inside isPointInNotch.
        let forgiving = CGPoint(x: 1512, y: 1921)
        #expect(g.isPointInNotch(forgiving) == true)
    }

    @Test("isPointOutsidePanel is the inverse of isPointInOpenedPanel")
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

    // MARK: E) Hardware detector

    @Test("NotchHardwareDetector clamps notch height to valid range")
    func heightClamp() {
        #expect(NotchHardwareDetector.clampedHeight(10) == NotchHardwareDetector.minNotchHeight)
        #expect(NotchHardwareDetector.clampedHeight(200) == NotchHardwareDetector.maxNotchHeight)
        #expect(NotchHardwareDetector.clampedHeight(40) == 40)
    }

    @Test("NotchHardwareDetector clamps width above minIdleWidth")
    func widthClamp() {
        let clamped = NotchHardwareDetector.clampedWidth(
            measuredContentWidth: 50,
            maxWidth: 500
        )
        #expect(clamped == NotchHardwareDetector.minIdleWidth)
    }

    @Test("NotchHardwareDetector clamps horizontal offset against screen bounds")
    func offsetClamp() {
        // If the user pushes an offset that would drive the panel off-screen,
        // the clamp should pull it back.
        let offset = NotchHardwareDetector.clampedHorizontalOffset(
            storedOffset: 100_000,
            runtimeWidth: 400,
            screenWidth: 3024
        )
        // offset must be within [−(screenWidth − runtimeWidth)/2, +(screenWidth − runtimeWidth)/2]
        let halfSlack = (3024 - 400) / 2
        #expect(offset <= CGFloat(halfSlack))
        #expect(offset >= -CGFloat(halfSlack))
    }
}
