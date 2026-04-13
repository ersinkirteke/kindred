import Dependencies
import Foundation

// MARK: - AVSpeechClient

public struct AVSpeechClient {
    public var speak: @Sendable ([String], PlaybackSpeed) async throws -> Void
    public var pause: @Sendable () async -> Void
    public var resume: @Sendable () async -> Void
    public var stopSpeaking: @Sendable () async -> Void
    public var jumpToStep: @Sendable (Int) async -> Void
    public var setRate: @Sendable (Float) async -> Void
    public var statusStream: @Sendable () async -> AsyncStream<PlaybackStatus>
    public var stepIndexStream: @Sendable () async -> AsyncStream<Int>
    public var cleanup: @Sendable () async -> Void
}

// MARK: - DependencyKey

extension AVSpeechClient: DependencyKey {
    public static var liveValue: AVSpeechClient {
        let manager = AVSpeechManager.shared

        return AVSpeechClient(
            speak: { steps, speed in
                try await manager.speak(steps: steps, speed: speed)
            },
            pause: {
                await manager.pause()
            },
            resume: {
                await manager.resume()
            },
            stopSpeaking: {
                await manager.stopSpeaking()
            },
            jumpToStep: { index in
                await manager.jumpToStep(index: index)
            },
            setRate: { rate in
                await manager.setRate(rate: rate)
            },
            statusStream: {
                await manager.statusStream()
            },
            stepIndexStream: {
                await manager.stepIndexStream()
            },
            cleanup: {
                await manager.cleanup()
            }
        )
    }

    public static var testValue: AVSpeechClient {
        AVSpeechClient(
            speak: { _, _ in },
            pause: { },
            resume: { },
            stopSpeaking: { },
            jumpToStep: { _ in },
            setRate: { _ in },
            statusStream: { @Sendable in
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            stepIndexStream: { @Sendable in
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            cleanup: { }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    public var avSpeechClient: AVSpeechClient {
        get { self[AVSpeechClient.self] }
        set { self[AVSpeechClient.self] = newValue }
    }
}
