import Foundation
import Testing

@testable import EyeGuard

// MARK: - NightModeManager Tests

@Suite("NightModeManager")
struct NightModeManagerTests {

    @Test("Night messages array is not empty")
    func nightMessagesNotEmpty() {
        #expect(!NightModeManager.nightMessages.isEmpty)
    }

    @Test("Night break messages array is not empty")
    func nightBreakMessagesNotEmpty() {
        #expect(!NightModeManager.nightBreakMessages.isEmpty)
    }

    @Test("All night messages have emoji, Chinese, and English text")
    func nightMessagesHaveAllFields() {
        for msg in NightModeManager.nightMessages {
            #expect(!msg.emoji.isEmpty)
            #expect(!msg.zh.isEmpty)
            #expect(!msg.en.isEmpty)
        }
    }

    @Test("All night break messages have emoji, Chinese, and English text")
    func nightBreakMessagesHaveAllFields() {
        for msg in NightModeManager.nightBreakMessages {
            #expect(!msg.emoji.isEmpty)
            #expect(!msg.zh.isEmpty)
            #expect(!msg.en.isEmpty)
        }
    }

    @Test("Night messages count is at least 8")
    func nightMessagesCount() {
        #expect(NightModeManager.nightMessages.count >= 8)
    }

    @Test("Night break messages count is at least 3")
    func nightBreakMessagesCount() {
        #expect(NightModeManager.nightBreakMessages.count >= 3)
    }

    @Test("Default night start hour is 22")
    @MainActor
    func defaultNightStartHour() {
        let manager = NightModeManager.shared
        // Default stored value is 0, but nightStartHour returns 22 when 0
        #expect(manager.nightStartHour == 22)
    }

    @Test("Default night end hour is 6")
    @MainActor
    func defaultNightEndHour() {
        let manager = NightModeManager.shared
        #expect(manager.nightEndHour == 6)
    }

    @Test("Night break multiplier is less than 1")
    @MainActor
    func nightBreakMultiplierIsAggressive() {
        let manager = NightModeManager.shared
        #expect(manager.nightBreakMultiplier < 1.0)
        #expect(manager.nightBreakMultiplier > 0.0)
    }

    @Test("Formatted night screen time returns valid string")
    @MainActor
    func formattedNightScreenTimeReturnsString() {
        let manager = NightModeManager.shared
        let formatted = manager.formattedNightScreenTime()
        #expect(!formatted.isEmpty)
    }

    @Test("Night screen time message contains emoji")
    @MainActor
    func nightScreenTimeMessageContainsEmoji() {
        let manager = NightModeManager.shared
        let msg = manager.nightScreenTimeMessage()
        #expect(msg.contains("🌙"))
    }

    @Test("Menu bar indicator is empty when not in night mode during daytime")
    @MainActor
    func menuBarIndicatorDaytime() {
        let manager = NightModeManager.shared
        let hour = Calendar.current.component(.hour, from: .now)
        if hour >= 6 && hour < 22 {
            // During daytime, should not be active
            #expect(manager.menuBarIndicator == "")
        }
        // Can't test night time deterministically
    }

    @Test("Random night message returns a non-empty string")
    @MainActor
    func randomNightMessageNotEmpty() {
        let manager = NightModeManager.shared
        let msg = manager.randomNightMessage()
        #expect(!msg.isEmpty)
    }

    @Test("Random night break message returns a non-empty string")
    @MainActor
    func randomNightBreakMessageNotEmpty() {
        let manager = NightModeManager.shared
        let msg = manager.randomNightBreakMessage()
        #expect(!msg.isEmpty)
    }
}
