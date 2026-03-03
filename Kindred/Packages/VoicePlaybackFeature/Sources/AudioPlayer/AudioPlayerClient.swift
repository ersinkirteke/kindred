import Dependencies
import Foundation

// MARK: - AudioPlayerClient

public struct AudioPlayerClient {
    public var play: @Sendable (URL) async throws -> Void
    public var pause: @Sendable () async -> Void
    public var resume: @Sendable () async -> Void
    public var seek: @Sendable (TimeInterval) async -> Void
    public var setRate: @Sendable (Float) async -> Void
    public var currentTimeStream: @Sendable () -> AsyncStream<TimeInterval>
    public var statusStream: @Sendable () -> AsyncStream<PlaybackStatus>
    public var durationStream: @Sendable () -> AsyncStream<TimeInterval>
    public var cleanup: @Sendable () async -> Void
}

// MARK: - DependencyKey

extension AudioPlayerClient: DependencyKey {
    public static var liveValue: AudioPlayerClient {
        let manager = AudioPlayerManager.shared

        return AudioPlayerClient(
            play: { url in
                try await manager.play(url: url)
            },
            pause: {
                await manager.pause()
            },
            resume: {
                await manager.resume()
            },
            seek: { seconds in
                await manager.seek(to: seconds)
            },
            setRate: { rate in
                await manager.setRate(rate)
            },
            currentTimeStream: {
                await manager.currentTimeStream()
            },
            statusStream: {
                await manager.statusStream()
            },
            durationStream: {
                await manager.durationStream()
            },
            cleanup: {
                await manager.cleanup()
            }
        )
    }

    public static var testValue: AudioPlayerClient {
        AudioPlayerClient(
            play: { _ in },
            pause: { },
            resume: { },
            seek: { _ in },
            setRate: { _ in },
            currentTimeStream: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            statusStream: {
                AsyncStream { continuation in
                    continuation.finish()
                }
            },
            durationStream: {
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
    public var audioPlayerClient: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
