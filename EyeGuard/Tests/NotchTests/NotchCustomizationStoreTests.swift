import Foundation
import Testing

@testable import EyeGuard

@MainActor
struct NotchCustomizationStoreTests {

    private func makeIsolatedDefaults() -> UserDefaults {
        let suite = "test.notch.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    @Test("Fresh store returns default customization")
    func freshStoreDefault() {
        let store = NotchCustomizationStore(defaults: makeIsolatedDefaults())
        #expect(store.customization == .default)
        #expect(store.customization.hoverSpeed == .normal)
        #expect(store.customization.horizontalOffset == 0)
        #expect(store.customization.showOnExternalDisplays == false)
    }

    @Test("Horizontal offset clamps to ±30pt")
    func offsetClamps() {
        let store = NotchCustomizationStore(defaults: makeIsolatedDefaults())
        store.setHorizontalOffset(9999)
        #expect(store.customization.horizontalOffset == 30)
        store.setHorizontalOffset(-9999)
        #expect(store.customization.horizontalOffset == -30)
    }

    @Test("Hover speed mutator persists")
    func hoverSpeedMutator() {
        let defaults = makeIsolatedDefaults()
        let store = NotchCustomizationStore(defaults: defaults)
        store.setHoverSpeed(.instant)
        let reloaded = NotchCustomizationStore(defaults: defaults)
        #expect(reloaded.customization.hoverSpeed == .instant)
    }

    @Test("External-display toggle persists across instances")
    func externalDisplayToggle() {
        let defaults = makeIsolatedDefaults()
        let a = NotchCustomizationStore(defaults: defaults)
        a.setShowOnExternalDisplays(true)
        let b = NotchCustomizationStore(defaults: defaults)
        #expect(b.customization.showOnExternalDisplays == true)
    }

    @Test("Reset returns to default and persists")
    func resetToDefault() {
        let defaults = makeIsolatedDefaults()
        let a = NotchCustomizationStore(defaults: defaults)
        a.setHoverSpeed(.fast)
        a.setHorizontalOffset(20)
        a.resetToDefault()
        #expect(a.customization == .default)
        let b = NotchCustomizationStore(defaults: defaults)
        #expect(b.customization == .default)
    }

    @Test("Hover speed delay values are monotonically increasing")
    func hoverSpeedDelays() {
        #expect(NotchHoverSpeed.instant.delay < NotchHoverSpeed.fast.delay)
        #expect(NotchHoverSpeed.fast.delay < NotchHoverSpeed.normal.delay)
        #expect(NotchHoverSpeed.normal.delay < NotchHoverSpeed.slow.delay)
    }
}
