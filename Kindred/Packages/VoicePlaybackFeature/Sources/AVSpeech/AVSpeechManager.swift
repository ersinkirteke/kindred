@preconcurrency import AVFoundation
import Foundation
import NaturalLanguage

// MARK: - AVSpeechManager

@MainActor
final class AVSpeechManager: NSObject {

    // MARK: - Singleton

    static let shared = AVSpeechManager()

    // MARK: - State

    private var synthesizer: AVSpeechSynthesizer?
    private var steps: [String] = []
    private var currentStepIndex: Int = 0
    private var speed: Float = 1.0
    private var retryCount: Int = 0
    private var timeoutTask: Task<Void, Never>?
    private var detectedLanguage: String = "en-US"

    // MARK: - Streams

    private var statusContinuation: AsyncStream<PlaybackStatus>.Continuation?
    private var stepContinuation: AsyncStream<Int>.Continuation?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Public Interface

    func speak(steps: [String], speed: PlaybackSpeed) throws {
        self.steps = steps
        self.speed = speed.rawValue
        self.currentStepIndex = 0
        self.retryCount = 0

        // Detect language from step text
        detectedLanguage = detectLanguage(from: steps)

        // Check for available voices before starting
        let langPrefix = String(detectedLanguage.prefix(2))
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(langPrefix) }

        if availableVoices.isEmpty {
            statusContinuation?.yield(
                .error("No voice installed — Go to Settings > Accessibility > Spoken Content > Voices to download a voice")
            )
            return
        }

        enqueueUtterances(from: 0)
    }

    func pause() {
        synthesizer?.pauseSpeaking(at: .immediate)
    }

    func resume() {
        synthesizer?.continueSpeaking()
    }

    func stopSpeaking() {
        synthesizer?.stopSpeaking(at: .immediate)
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    func jumpToStep(index: Int) {
        stopSpeaking()
        currentStepIndex = index
        enqueueUtterances(from: index)
    }

    func setRate(rate: Float) {
        speed = rate
        // AVSpeechSynthesizer doesn't support changing rate mid-utterance.
        // Stop and re-enqueue from current step with new rate.
        let currentIndex = currentStepIndex
        stopSpeaking()
        enqueueUtterances(from: currentIndex)
    }

    func statusStream() -> AsyncStream<PlaybackStatus> {
        AsyncStream { [weak self] continuation in
            self?.statusContinuation = continuation
        }
    }

    func stepIndexStream() -> AsyncStream<Int> {
        AsyncStream { [weak self] continuation in
            self?.stepContinuation = continuation
        }
    }

    func cleanup() {
        stopSpeaking()
        synthesizer?.delegate = nil
        synthesizer = nil
        timeoutTask?.cancel()
        timeoutTask = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Non-fatal — session deactivation best-effort
        }

        statusContinuation?.finish()
        stepContinuation?.finish()
        statusContinuation = nil
        stepContinuation = nil
    }

    // MARK: - Private

    private func enqueueUtterances(from startIndex: Int) {
        // Deallocate old synthesizer and create a fresh one
        synthesizer?.delegate = nil
        synthesizer = nil

        let newSynthesizer = AVSpeechSynthesizer()
        newSynthesizer.usesApplicationAudioSession = true
        newSynthesizer.delegate = self
        synthesizer = newSynthesizer

        let voice = preferredVoice()

        for (offset, stepText) in steps[startIndex...].enumerated() {
            let utterance = AVSpeechUtterance(string: stepText)
            utterance.voice = voice
            utterance.rate = Self.mappedRate(speed)
            utterance.postUtteranceDelay = 1.2
            newSynthesizer.speak(utterance)
        }

        startSilentFailureTimeout()
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let langPrefix = String(detectedLanguage.prefix(2))
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(langPrefix) }
        return voices.first(where: { $0.quality == .enhanced })
            ?? voices.first(where: { $0.quality == .default })
            ?? AVSpeechSynthesisVoice(language: detectedLanguage)
    }

    private func detectLanguage(from steps: [String]) -> String {
        let sampleText = steps.prefix(3).joined(separator: " ")
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(sampleText)
        if let language = recognizer.dominantLanguage {
            // Map NLLanguage to BCP 47 language tag
            // NLLanguage.english → "en", we need a full locale like "en-US"
            let langCode = language.rawValue
            // Find best matching voice language code
            let voices = AVSpeechSynthesisVoice.speechVoices()
            if let exactMatch = voices.first(where: { $0.language.hasPrefix(langCode) }) {
                return exactMatch.language
            }
            return langCode
        }
        // Fallback to device language
        return AVSpeechSynthesisVoice.currentLanguageCode()
    }

    private static func mappedRate(_ appSpeed: Float) -> Float {
        // App 1.0x → AVSpeech 0.5 (default), App 2.0x → 0.65, App 0.5x → 0.35
        let normalized = (appSpeed - 0.5) / 1.5  // 0..1
        return 0.35 + normalized * 0.30
    }

    private func startSilentFailureTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            guard !Task.isCancelled else { return }
            await self?.handleSilentFailure()
        }
    }

    private func handleSilentFailure() {
        guard retryCount < 1 else {
            statusContinuation?.yield(.error("Voice unavailable — Retry"))
            return
        }
        retryCount += 1
        enqueueUtterances(from: currentStepIndex)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AVSpeechManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            timeoutTask?.cancel()
            timeoutTask = nil
            statusContinuation?.yield(.playing)
            stepContinuation?.yield(currentStepIndex)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            currentStepIndex += 1
            if currentStepIndex < steps.count {
                stepContinuation?.yield(currentStepIndex)
            } else {
                statusContinuation?.yield(.stopped)
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            statusContinuation?.yield(.paused)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            statusContinuation?.yield(.playing)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // No-op: cancel is handled explicitly via stopSpeaking() / jumpToStep() etc.
    }
}
