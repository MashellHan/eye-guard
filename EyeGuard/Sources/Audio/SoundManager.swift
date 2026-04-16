import AppKit
import AVFoundation
import Foundation
import os

/// Manages sound effects, TTS audio guidance, and ambient audio for EyeGuard.
///
/// Provides:
/// - Notification chimes when breaks start (gentle tone)
/// - Celebration sounds when breaks complete (ascending chime)
/// - Soft bell for tip rotation events
/// - TTS voice guidance for eye exercises (AVSpeechSynthesizer, zh-CN)
/// - Ambient nature sound generation during breaks (AVAudioEngine)
/// - Volume control and mute toggle via UserDefaults
@MainActor
final class SoundManager: SoundPlaying {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Sound Types

    /// Categories of sounds played by EyeGuard.
    enum SoundType: String, Sendable {
        /// Gentle chime when a break notification appears.
        case breakStart
        /// Celebration tone when a break is completed.
        case breakComplete
        /// Soft bell when a new tip is shown.
        case tipRotation
        /// Alert tone for escalated notifications.
        case alert
        /// Ambient nature sound during breaks.
        case ambient
        /// Step transition chime for exercises.
        case exerciseStep
    }

    /// Ambient sound presets available during breaks.
    enum AmbientPreset: String, CaseIterable, Sendable {
        case rain = "Rain 🌧️"
        case ocean = "Ocean Waves 🌊"
        case forest = "Forest Birds 🌲"
        case wind = "Gentle Wind 🍃"
        case silence = "Silence 🔇"

        /// Description for the preference UI.
        var description: String {
            switch self {
            case .rain:    return "Soft rainfall pattern"
            case .ocean:   return "Rolling ocean waves"
            case .forest:  return "Forest atmosphere with bird calls"
            case .wind:    return "Gentle breeze rustling leaves"
            case .silence: return "No ambient sound"
            }
        }
    }

    // MARK: - State

    /// The AVAudioEngine for procedural sound generation.
    private var audioEngine: AVAudioEngine?

    /// Tone generator nodes for ambient sounds.
    private var toneNodes: [AVAudioSourceNode] = []

    /// Whether ambient sound is currently playing.
    private(set) var isAmbientPlaying: Bool = false

    /// Task managing the ambient sound lifecycle.
    private var ambientTask: Task<Void, Never>?

    /// AVSpeechSynthesizer for TTS exercise guidance (v2.4).
    @ObservationIgnored
    private let speechSynthesizer = AVSpeechSynthesizer()

    /// Whether TTS is currently speaking.
    private(set) var isSpeaking: Bool = false

    /// Current volume level (0.0 – 1.0).
    var volume: Float {
        get {
            let stored = UserDefaults.standard.float(forKey: "soundVolume")
            return stored > 0 ? stored : 0.5
        }
        set {
            UserDefaults.standard.set(max(0, min(1, newValue)), forKey: "soundVolume")
        }
    }

    /// Whether all sounds are muted.
    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "soundMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "soundMuted") }
    }

    /// The selected ambient preset for break periods.
    var selectedAmbientPreset: AmbientPreset {
        get {
            let raw = UserDefaults.standard.string(forKey: "ambientPreset") ?? ""
            return AmbientPreset(rawValue: raw) ?? .rain
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "ambientPreset")
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Plays a sound effect of the given type.
    ///
    /// - Parameter type: The sound effect category to play.
    func play(_ type: SoundType) {
        guard !isMuted, volume > 0 else { return }

        switch type {
        case .breakStart:
            playSystemSound(named: "Tink")
            Log.sound.info("Sound: break start chime")

        case .breakComplete:
            playSystemSound(named: "Glass")
            Log.sound.info("Sound: break complete")

        case .exerciseStep:
            playSystemSound(named: "Pop")
            Log.sound.info("Sound: exercise step transition")

        case .tipRotation:
            playSystemSound(named: "Purr")
            Log.sound.info("Sound: tip rotation")

        case .alert:
            playSystemSound(named: "Sosumi")
            Log.sound.info("Sound: alert")

        case .ambient:
            break
        }
    }

    /// Ambient sound is currently disabled.
    func startAmbient() {
        // Disabled — ambient sounds hidden until better audio assets
    }

    /// Stops any playing ambient sound.
    func stopAmbient() {
        guard isAmbientPlaying else { return }
        isAmbientPlaying = false
        stopAmbientEngine()
        Log.sound.info("Ambient sound stopped.")
    }

    /// Convenience: plays the break-start chime.
    func onBreakStart() {
        play(.breakStart)
    }

    /// Convenience: plays the break-complete celebration.
    func onBreakComplete() {
        play(.breakComplete)
    }

    /// Convenience: plays the tip rotation bell.
    func onTipRotation() {
        play(.tipRotation)
    }

    // MARK: - TTS Voice Guidance (v2.4)

    /// Speaks a Chinese text instruction using AVSpeechSynthesizer.
    ///
    /// Used for eye exercise step-by-step guidance.
    /// Respects mute and volume settings.
    /// Utterances are queued by AVSpeechSynthesizer when already speaking.
    ///
    /// - Parameter text: Chinese text to speak (zh-CN voice).
    func speak(_ text: String) {
        guard !isMuted else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.volume = volume
        utterance.pitchMultiplier = 1.05

        let wasAlreadySpeaking = speechSynthesizer.isSpeaking
        speechSynthesizer.speak(utterance)
        isSpeaking = true
        Log.sound.info("TTS: \(text)\(wasAlreadySpeaking ? " (queued)" : "")")
    }

    /// Stops any current TTS speech.
    func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    /// Speaks an exercise name and first instruction.
    /// - Parameters:
    ///   - exercise: The exercise to announce.
    ///   - step: The step instruction to speak.
    func speakExerciseStep(_ exercise: String, step: String) {
        speak("\(exercise)。\(step)")
    }

    /// Speaks an exercise step instruction only.
    /// - Parameter instruction: The step instruction text.
    func speakInstruction(_ instruction: String) {
        speak(instruction)
    }

    /// Plays exercise completion celebration with TTS.
    func onExerciseComplete() {
        play(.breakComplete)
        speak("做得好！眼保健操完成")
    }

    /// Speaks a countdown number (1-5) for the last seconds of a break.
    func speakCountdown(_ seconds: Int) {
        guard !isMuted, seconds > 0, seconds <= 5 else { return }
        speak("\(seconds)")
    }

    /// Speaks break completion message.
    func speakBreakComplete() {
        speak("休息结束，继续加油")
    }

    // MARK: - Encouragement (v3.2)

    /// Encouragement phrases spoken during exercises.
    private static let encouragements = [
        "很好，继续保持",
        "做得不错",
        "放松，慢慢来",
        "你的眼睛会感谢你的",
        "保持节奏，很棒",
    ]

    /// Speaks a random encouragement phrase.
    func speakEncouragement() {
        let phrase = Self.encouragements.randomElement() ?? "很好"
        speak(phrase)
    }

    /// Speaks the exercise intro greeting.
    func speakExerciseIntro() {
        speak("来，闭上眼睛，我们一起做眼保健操")
    }

    /// Plays exercise step transition chime.
    func onExerciseStepTransition() {
        play(.exerciseStep)
    }

    // MARK: - System Sound Playback

    /// Plays a named macOS system sound.
    ///
    /// Falls back to NSSound.beep() if the named sound is unavailable.
    ///
    /// - Parameter name: The system sound file name (without extension).
    private func playSystemSound(named name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.volume = volume
            sound.play()
        } else {
            // Fallback to system beep
            NSSound.beep()
            Log.sound.warning("System sound '\(name)' not found, using beep fallback.")
        }
    }

    // MARK: - Ambient Sound Engine

    /// Starts the AVAudioEngine with a procedurally generated ambient tone.
    private func startAmbientEngine() {
        let engine = AVAudioEngine()
        self.audioEngine = engine

        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate

        guard sampleRate > 0 else {
            Log.sound.error("Invalid sample rate, cannot start ambient engine.")
            isAmbientPlaying = false
            return
        }

        let preset = selectedAmbientPreset
        let currentVolume = volume

        nonisolated(unsafe) var phase: Double = 0.0
        nonisolated(unsafe) var modPhase: Double = 0.0

        let sourceNode = AVAudioSourceNode(format: outputFormat) {
            @Sendable _, _, frameCount, bufferList -> OSStatus in

            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)

            for frame in 0..<Int(frameCount) {
                let sample: Float

                switch preset {
                case .rain:
                    let noise = Float.random(in: -1.0...1.0)
                    let lpf = noise * 0.15 * currentVolume * 0.3
                    sample = lpf

                case .ocean:
                    let modFreq = 0.08
                    modPhase += modFreq / sampleRate
                    let modulation = Float(sin(modPhase * 2.0 * .pi))
                    let envelope = (modulation + 1.0) / 2.0
                    let noise = Float.random(in: -1.0...1.0)
                    sample = noise * envelope * 0.12 * currentVolume * 0.3

                case .forest:
                    let baseFreq = 1200.0 + sin(modPhase * 0.5) * 400.0
                    phase += baseFreq / sampleRate
                    modPhase += 0.3 / sampleRate
                    let chirp = Float(sin(phase * 2.0 * .pi))
                    let chirpEnvelope = Float(max(0, sin(modPhase * 2.0 * .pi)))
                    let thresholdedEnvelope = chirpEnvelope > 0.95 ? chirpEnvelope : 0.0
                    sample = chirp * thresholdedEnvelope * 0.08 * currentVolume * 0.3

                case .wind:
                    modPhase += 0.15 / sampleRate
                    let modulation = Float(sin(modPhase * 2.0 * .pi))
                    let envelope = (modulation + 1.0) / 2.0 * 0.7 + 0.3
                    let noise = Float.random(in: -1.0...1.0)
                    sample = noise * envelope * 0.1 * currentVolume * 0.3

                case .silence:
                    sample = 0
                }

                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
            }

            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mainMixer, format: outputFormat)
        toneNodes = [sourceNode]

        do {
            try engine.start()
            Log.sound.info("Ambient audio engine started for preset: \(preset.rawValue)")
        } catch {
            Log.sound.error("Failed to start ambient engine: \(error.localizedDescription)")
            isAmbientPlaying = false
        }
    }

    /// Stops the AVAudioEngine and cleans up nodes.
    private func stopAmbientEngine() {
        ambientTask?.cancel()
        ambientTask = nil

        guard let engine = audioEngine else { return }

        engine.stop()
        for node in toneNodes {
            engine.detach(node)
        }
        toneNodes = []
        audioEngine = nil
    }
}
