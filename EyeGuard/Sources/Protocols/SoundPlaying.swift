import Foundation

/// Protocol for sound effect and ambient audio playback.
///
/// Abstracts the sound management layer for testability via dependency injection.
/// Production: `SoundManager` conforms to this protocol.
/// Tests: Inject a mock conforming to this protocol.
@MainActor
protocol SoundPlaying {
    /// Plays a sound effect of the given type.
    func play(_ type: SoundManager.SoundType)

    /// Starts ambient nature sound generation for the current preset.
    func startAmbient()

    /// Stops any playing ambient sound.
    func stopAmbient()

    /// Convenience: plays the break-start chime and starts ambient sound.
    func onBreakStart()

    /// Convenience: stops ambient sound and plays the completion celebration.
    func onBreakComplete()

    /// Convenience: plays the tip rotation bell.
    func onTipRotation()

    /// Whether ambient sound is currently playing.
    var isAmbientPlaying: Bool { get }

    /// Whether all sounds are muted.
    var isMuted: Bool { get set }

    // MARK: - TTS Voice Guidance

    /// Speaks a text instruction using TTS.
    func speak(_ text: String)

    /// Stops any current TTS speech.
    func stopSpeaking()

    /// Whether TTS is currently speaking.
    var isSpeaking: Bool { get }

    /// Speaks an exercise intro greeting.
    func speakExerciseIntro()

    /// Speaks a random encouragement phrase.
    func speakEncouragement()

    /// Speaks an exercise name and step instruction.
    func speakExerciseStep(_ exercise: String, step: String)

    /// Speaks a step instruction only.
    func speakInstruction(_ instruction: String)

    /// Plays exercise step transition chime.
    func onExerciseStepTransition()

    /// Plays exercise completion celebration with TTS.
    func onExerciseComplete()
}

// MARK: - Default Implementations

/// Empty defaults for TTS methods so mock conformances don't need to implement all of them.
extension SoundPlaying {
    func speak(_ text: String) {}
    func stopSpeaking() {}
    var isSpeaking: Bool { false }
    func speakExerciseIntro() {}
    func speakEncouragement() {}
    func speakExerciseStep(_ exercise: String, step: String) {}
    func speakInstruction(_ instruction: String) {}
    func onExerciseStepTransition() {}
    func onExerciseComplete() {}
}
