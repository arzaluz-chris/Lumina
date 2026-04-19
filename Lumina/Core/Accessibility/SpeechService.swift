import AVFoundation
import Observation
import os

/// Central text-to-speech service used by the Read Aloud buttons and the
/// quiz auto-narration. Wraps ``AVSpeechSynthesizer`` with an observable
/// state so SwiftUI views can reflect which utterance is currently
/// playing and toggle playback on tap.
///
/// Designed for young users and people who can't yet read: the app still
/// works with VoiceOver (each interactive surface carries accessibility
/// labels), but the Read Aloud buttons let anyone hear the content aloud
/// without enabling the system screen reader.
@MainActor
@Observable
final class SpeechService: NSObject {
    @MainActor static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    /// Identifier of the utterance currently being spoken; `nil` when idle.
    /// Views pass a stable UUID when calling ``speak(_:id:)`` so the
    /// matching Read Aloud button can render the "playing" state.
    private(set) var currentUtteranceID: UUID?

    /// True whenever the synthesizer is producing audio.
    private(set) var isSpeaking: Bool = false

    private static let enabledKey = "readAloudEnabled"

    /// Master switch. When false, ``speak(_:id:)`` is a no-op and
    /// Read Aloud buttons render in a dimmed/disabled state.
    @ObservationIgnored
    private var enabledBacking: Bool = UserDefaults.standard.object(forKey: SpeechService.enabledKey) as? Bool ?? true
    var isEnabled: Bool {
        get { enabledBacking }
        set {
            enabledBacking = newValue
            UserDefaults.standard.set(newValue, forKey: SpeechService.enabledKey)
            if !newValue { stop() }
        }
    }

    override private init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    /// Routes TTS through a `.playback` session in `.spokenAudio` mode so
    /// the voice plays even when the silent switch is on (the app is
    /// aimed at kids who may use it on a muted family device) and ducks
    /// — not stops — any other audio that happens to be playing.
    ///
    /// Without this, the synthesizer falls back to the process default
    /// session, which on iOS 18+ tends to log "AVAudioBuffer mDataByteSize
    /// should be non-zero" and clip utterances after the first second.
    private func configureAudioSession() {
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            Logger.accessibility.error("AVAudioSession setup failed: \(error.localizedDescription)")
        }
        #endif
    }

    /// Speaks the given text, cancelling any utterance currently in
    /// flight. Pass a stable `id` (e.g. a view's `@State` UUID) so the
    /// caller can later ask ``isSpeaking(id:)`` whether it owns the
    /// active playback.
    func speak(_ text: String, id: UUID = UUID()) {
        guard isEnabled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        stop()
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = Self.preferredVoice
        // Slightly slower than system default — the app targets kids and
        // early readers, and a relaxed cadence is much easier to follow.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.05
        utterance.postUtteranceDelay = 0.1
        currentUtteranceID = id
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Immediately stops playback and clears the active utterance.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentUtteranceID = nil
        isSpeaking = false
    }

    /// Convenience used by ``ReadAloudButton`` to know whether it owns
    /// the playback currently in flight.
    func isSpeaking(id: UUID) -> Bool {
        isSpeaking && currentUtteranceID == id
    }

    /// Picks the best available Spanish voice. Falls back through
    /// `es-MX → es-US → es-ES → any Spanish` so the app sounds local in
    /// México (the primary audience) but still speaks if only a generic
    /// Spanish voice is installed on the device.
    private static let preferredVoice: AVSpeechSynthesisVoice? = {
        if let v = AVSpeechSynthesisVoice(language: "es-MX") { return v }
        if let v = AVSpeechSynthesisVoice(language: "es-US") { return v }
        if let v = AVSpeechSynthesisVoice(language: "es-ES") { return v }
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("es") }
    }()
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    // Delegate callbacks arrive off the main actor — hop back to update
    // the observable state so SwiftUI views re-render safely.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceID = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentUtteranceID = nil
        }
    }
}
