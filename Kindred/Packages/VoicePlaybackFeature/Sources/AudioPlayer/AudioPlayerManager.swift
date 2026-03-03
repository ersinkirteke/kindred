import AVFoundation
import Foundation

// MARK: - AudioPlayerManager

public actor AudioPlayerManager {
    public static let shared = AudioPlayerManager()

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObservation: NSKeyValueObservation?
    private var itemEndedTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public Methods

    public func play(url: URL) async throws {
        // Clean up existing player
        await cleanup()

        let playerItem = AVPlayerItem(url: url)
        playerItem.audioTimePitchAlgorithm = .spectral

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = newPlayer

        // Start playback
        newPlayer.play()

        // Wait for player item to become ready (or fail)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Use a flag to prevent double-resume
            let resumed = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            resumed.initialize(to: false)

            var observation: NSKeyValueObservation?
            observation = playerItem.observe(\.status, options: [.initial, .new]) { item, _ in
                guard !resumed.pointee else { return }
                switch item.status {
                case .readyToPlay:
                    resumed.pointee = true
                    observation?.invalidate()
                    observation = nil
                    resumed.deallocate()
                    continuation.resume()
                case .failed:
                    resumed.pointee = true
                    observation?.invalidate()
                    observation = nil
                    let error = item.error ?? NSError(
                        domain: "AudioPlayerManager",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to load audio"]
                    )
                    resumed.deallocate()
                    continuation.resume(throwing: error)
                case .unknown:
                    break // Still loading, wait
                @unknown default:
                    break
                }
            }
        }
    }

    public func pause() async {
        player?.pause()
    }

    public func resume() async {
        guard let player = player else { return }
        player.play()
    }

    public func seek(to seconds: TimeInterval) async {
        guard let player = player else { return }
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        let tolerance = CMTime(seconds: 0.5, preferredTimescale: 600)
        await player.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }

    public func setRate(_ rate: Float) async {
        guard let player = player else { return }
        player.play()
        player.rate = rate
    }

    public func cleanup() async {
        // Remove time observer token if it exists
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }

        // Cancel item ended task
        itemEndedTask?.cancel()
        itemEndedTask = nil

        // Remove KVO observation
        statusObservation?.invalidate()
        statusObservation = nil

        // Pause and release player
        player?.pause()
        player = nil
    }

    // MARK: - Streams

    public func currentTimeStream() -> AsyncStream<TimeInterval> {
        AsyncStream { continuation in
            guard let player = self.player else {
                continuation.finish()
                return
            }

            let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
            let token = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
                guard let player = player else {
                    continuation.finish()
                    return
                }
                let seconds = CMTimeGetSeconds(time)
                if seconds.isFinite {
                    continuation.yield(seconds)
                }
            }

            Task { [weak self] in
                await self?.storeTimeObserverToken(token)
            }

            continuation.onTermination = { [weak player] _ in
                player?.removeTimeObserver(token)
            }
        }
    }

    public func statusStream() -> AsyncStream<PlaybackStatus> {
        AsyncStream { continuation in
            guard let player = self.player else {
                continuation.yield(.idle)
                continuation.finish()
                return
            }

            // Emit initial status immediately
            let initialStatus: PlaybackStatus = switch player.timeControlStatus {
            case .playing: .playing
            case .paused: .paused
            case .waitingToPlayAtSpecifiedRate: .buffering
            @unknown default: .idle
            }
            continuation.yield(initialStatus)

            // Observe time control status changes
            let observation = player.observe(\.timeControlStatus, options: [.new]) { [weak player] _, change in
                guard let newValue = change.newValue, let player = player else { return }

                let status: PlaybackStatus = switch newValue {
                case .playing:
                    .playing
                case .paused:
                    if player.currentItem?.isPlaybackLikelyToKeepUp == false {
                        .buffering
                    } else {
                        .paused
                    }
                case .waitingToPlayAtSpecifiedRate:
                    .buffering
                @unknown default:
                    .idle
                }

                continuation.yield(status)
            }

            Task { [weak self] in
                await self?.storeStatusObservation(observation)
            }

            // Observe item end notification
            let task = Task {
                let center = NotificationCenter.default
                for await _ in center.notifications(named: .AVPlayerItemDidPlayToEndTime, object: player.currentItem) {
                    continuation.yield(.stopped)
                }
            }

            Task { [weak self] in
                await self?.storeItemEndedTask(task)
            }

            continuation.onTermination = { _ in
                observation.invalidate()
                task.cancel()
            }
        }
    }

    public func durationStream() -> AsyncStream<TimeInterval> {
        AsyncStream { continuation in
            guard let player = self.player, let currentItem = player.currentItem else {
                continuation.finish()
                return
            }

            let observation = currentItem.observe(\.duration, options: [.new]) { _, change in
                guard let newDuration = change.newValue else { return }
                let seconds = CMTimeGetSeconds(newDuration)
                if seconds.isFinite && seconds > 0 {
                    continuation.yield(seconds)
                }
            }

            continuation.onTermination = { _ in
                observation.invalidate()
            }
        }
    }

    // MARK: - Private Helpers

    private func storeTimeObserverToken(_ token: Any) {
        self.timeObserverToken = token
    }

    private func storeStatusObservation(_ observation: NSKeyValueObservation) {
        self.statusObservation = observation
    }

    private func storeItemEndedTask(_ task: Task<Void, Never>) {
        self.itemEndedTask = task
    }
}
