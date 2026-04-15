import Foundation
import Testing

@testable import EyeGuard

// MARK: - OverlayWindowController Tests

@Suite("OverlayWindowController")
struct OverlayWindowControllerTests {

    @Test("Initial state is not showing")
    @MainActor
    func initialState() {
        let controller = OverlayWindowController()
        #expect(controller.isShowing == false)
    }

    @Test("Show overlay sets isShowing to true")
    @MainActor
    func showOverlay() {
        let controller = OverlayWindowController()

        controller.showBreakOverlay(
            breakType: .micro,
            onTaken: {},
            onSkipped: {}
        )

        #expect(controller.isShowing == true)
    }

    @Test("Dismiss overlay sets isShowing to false")
    @MainActor
    func dismissOverlay() async throws {
        let controller = OverlayWindowController()

        controller.showBreakOverlay(
            breakType: .micro,
            onTaken: {},
            onSkipped: {}
        )

        #expect(controller.isShowing == true)

        controller.dismiss()

        // Wait for animation to complete
        try await Task.sleep(for: .milliseconds(500))

        #expect(controller.isShowing == false)
    }

    @Test("Showing a new overlay replaces the existing one")
    @MainActor
    func replaceOverlay() {
        let controller = OverlayWindowController()

        controller.showBreakOverlay(
            breakType: .micro,
            onTaken: {},
            onSkipped: {}
        )

        #expect(controller.isShowing == true)

        controller.showBreakOverlay(
            breakType: .macro,
            onTaken: {},
            onSkipped: {}
        )

        #expect(controller.isShowing == true)
    }

    @Test("Dismiss when no overlay is no-op")
    @MainActor
    func dismissWhenNotShowing() {
        let controller = OverlayWindowController()

        // Should not crash
        controller.dismiss()
        #expect(controller.isShowing == false)
    }

    @Test("Overlay works with all break types")
    @MainActor
    func allBreakTypes() {
        let controller = OverlayWindowController()

        for breakType in BreakType.allCases {
            controller.showBreakOverlay(
                breakType: breakType,
                onTaken: {},
                onSkipped: {}
            )
            #expect(controller.isShowing == true)
        }
    }

    @Test("Full-screen overlay initial state is not showing")
    @MainActor
    func fullScreenInitialState() {
        let controller = OverlayWindowController()
        #expect(controller.isFullScreenShowing == false)
    }

    @Test("Show full-screen overlay sets isFullScreenShowing to true")
    @MainActor
    func showFullScreenOverlay() {
        let controller = OverlayWindowController()

        controller.showFullScreenOverlay(healthScore: 65, onTaken: {})

        #expect(controller.isFullScreenShowing == true)
    }

    @Test("Dismiss full-screen overlay sets isFullScreenShowing to false")
    @MainActor
    func dismissFullScreenOverlay() async throws {
        let controller = OverlayWindowController()

        controller.showFullScreenOverlay(healthScore: 80, onTaken: {})
        #expect(controller.isFullScreenShowing == true)

        controller.dismissFullScreen()

        // Wait for animation to complete
        try await Task.sleep(for: .milliseconds(500))

        #expect(controller.isFullScreenShowing == false)
    }

    @Test("Full-screen dismiss when not showing is no-op")
    @MainActor
    func dismissFullScreenWhenNotShowing() {
        let controller = OverlayWindowController()

        // Should not crash
        controller.dismissFullScreen()
        #expect(controller.isFullScreenShowing == false)
    }

    @Test("Full-screen overlay replaces existing Tier 2 overlay")
    @MainActor
    func fullScreenReplacesExisting() {
        let controller = OverlayWindowController()

        controller.showBreakOverlay(
            breakType: .micro,
            onTaken: {},
            onSkipped: {}
        )
        #expect(controller.isShowing == true)

        controller.showFullScreenOverlay(healthScore: 50, onTaken: {})
        #expect(controller.isFullScreenShowing == true)
        // Tier 2 should be dismissed
        #expect(controller.isShowing == false)
    }
}
