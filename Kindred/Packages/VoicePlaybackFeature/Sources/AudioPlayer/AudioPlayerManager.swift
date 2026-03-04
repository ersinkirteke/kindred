import AVFoundation
import Foundation
import os.log

private let logger = Logger(subsystem: "com.ersinkirteke.kindred", category: "AudioPlayer")

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
        logger.info("▶️ play() called with URL: \(url.absoluteString)")

        // Verify audio session is active
        let session = AVAudioSession.sharedInstance()
        logger.info("Audio session category: \(session.category.rawValue), mode: \(session.mode.rawValue), isOtherAudioPlaying: \(session.isOtherAudioPlaying)")

        // Re-activate session if needed (handles silent mode, etc.)
        if session.category != .playback {
            try session.setCategory(.playback, mode: .spokenAudio)
        }
        try session.setActive(true)

        // Clean up existing player
        await cleanup()

        let playerItem = AVPlayerItem(url: url)
        playerItem.audioTimePitchAlgorithm = .spectral

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        newPlayer.volume = 1.0
        self.player = newPlayer

        // Wait for AVPlayerItem to reach .readyToPlay before calling play()
        do {
            try await waitForReadyToPlay(playerItem: playerItem)
            logger.info("✅ PlayerItem ready to play")
        } catch {
            // Enhanced error diagnostics
            let itemStatus = playerItem.status.rawValue
            let itemError = playerItem.error?.localizedDescription ?? "none"
            let sessionCategory = session.category.rawValue
            let otherAudioPlaying = session.isOtherAudioPlaying

            logger.error("❌ waitForReadyToPlay failed - URL: \(url.absoluteString), status: \(itemStatus), error: \(itemError), session: \(sessionCategory), otherAudio: \(otherAudioPlaying)")

            // Clean up failed player so streams see nil and finish immediately
            await cleanup()

            throw PlayerError.failedToLoadWithDetails(
                url: url.absoluteString,
                itemStatus: itemStatus,
                itemError: itemError,
                sessionCategory: sessionCategory,
                otherAudioPlaying: otherAudioPlaying
            )
        }

        // Start playback - AVPlayer handles buffering internally
        logger.info("🎵 Calling AVPlayer.play()")
        newPlayer.play()
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

            continuation.onTermination = { _ in
                // Observer removal is handled by cleanup() to avoid double-remove crash
            }
        }
    }

    public func statusStream() -> AsyncStream<PlaybackStatus> {
        AsyncStream { continuation in
            guard let player = self.player else {
                logger.warning("⚠️ statusStream: player is nil")
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
            logger.info("📊 statusStream initial: \(String(describing: initialStatus))")
            continuation.yield(initialStatus)

            // Observe time control status changes
            let observation = player.observe(\.timeControlStatus, options: [.new]) { [weak player] _, change in
                guard let newValue = change.newValue, let player = player else { return }

                let status: PlaybackStatus = switch newValue {
                case .playing:
                    .playing
                case .paused:
                    // Check for AVPlayerItem errors first
                    if let error = player.currentItem?.error {
                        .error("Cannot Open: \(error.localizedDescription)")
                    } else if player.currentItem?.isPlaybackLikelyToKeepUp == false {
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

            // Observe item status for error detection
            let itemObservation = player.currentItem?.observe(\.status, options: [.new]) { item, _ in
                if item.status == .failed, let error = item.error {
                    logger.error("❌ AVPlayerItem failed: \(error.localizedDescription)")
                    continuation.yield(.error("Failed: \(error.localizedDescription)"))
                }
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
                itemObservation?.invalidate()
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

    /// Waits for an AVPlayerItem to reach `.readyToPlay` status using KVO observation.
    /// Times out after 15 seconds. Throws if the item fails to load or times out.
    private func waitForReadyToPlay(playerItem: AVPlayerItem) async throws {
        let statusStream = AsyncStream<AVPlayerItem.Status> { continuation in
            let observation = playerItem.observe(\.status, options: [.initial, .new]) { item, _ in
                continuation.yield(item.status)
            }
            continuation.onTermination = { _ in
                observation.invalidate()
            }
        }

        // Race the status observation against a 15-second timeout
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await status in statusStream {
                    logger.debug("📡 PlayerItem status: \(status.rawValue)")
                    switch status {
                    case .readyToPlay:
                        return
                    case .failed:
                        throw playerItem.error ?? PlayerError.failedToLoad
                    case .unknown:
                        continue
                    @unknown default:
                        continue
                    }
                }
                throw PlayerError.failedToLoad
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds
                logger.error("⏰ waitForReadyToPlay timed out after 15s")
                throw PlayerError.timeout
            }

            // Wait for the first task to complete (either ready or timeout)
            try await group.next()
            // Cancel the other task
            group.cancelAll()
        }
    }
}

// MARK: - TestAudioGenerator

public enum TestAudioGenerator {
    /// Creates a 10-second sine wave WAV audio file in the caches directory for testing.
    /// Returns the file URL. Reuses existing file if already created.
    public static func createTestFile() -> URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = cachesDir.appendingPathComponent("kindred_test_narration.wav")

        if FileManager.default.fileExists(atPath: url.path) {
            logger.info("🎵 Test file already exists at \(url.path)")
            return url
        }

        do {
            let sampleRate: Double = 44100
            let duration: Double = 10
            let frequency: Double = 440
            let frameCount = AVAudioFrameCount(sampleRate * duration)

            // Use WAV/PCM format - simplest, no encoding needed
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
            ]

            let audioFile = try AVAudioFile(forWriting: url, settings: settings)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
                logger.error("❌ Failed to create PCM buffer")
                throw PlayerError.failedToLoad
            }

            buffer.frameLength = frameCount
            if let channelData = buffer.floatChannelData?[0] {
                let sr = Float(sampleRate)
                for i in 0..<Int(frameCount) {
                    channelData[i] = sin(2.0 * .pi * Float(frequency) * Float(i) / sr) * 0.3
                }
            }

            try audioFile.write(from: buffer)
            logger.info("🎵 Created test WAV file at \(url.path) (\(frameCount) frames)")
            return url
        } catch {
            logger.error("❌ Failed to create test audio: \(error.localizedDescription)")
            return url
        }
    }
}

// MARK: - PlayerError

enum PlayerError: Error, LocalizedError {
    case failedToLoad
    case timeout
    case failedToLoadWithDetails(url: String, itemStatus: Int, itemError: String, sessionCategory: String, otherAudioPlaying: Bool)

    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            return "Failed to load audio"
        case .timeout:
            return "Audio loading timed out"
        case let .failedToLoadWithDetails(url, itemStatus, itemError, sessionCategory, otherAudioPlaying):
            return """
            Failed to load: \(url)
            Status: \(itemStatus), Error: \(itemError)
            Session: \(sessionCategory), OtherAudio: \(otherAudioPlaying)
            """
        }
    }
}
