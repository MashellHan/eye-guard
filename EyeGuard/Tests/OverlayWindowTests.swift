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
}
