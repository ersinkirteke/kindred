import AVFoundation
import MediaPlayer
import Kingfisher
import UIKit
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let nowPlaying = Logger(subsystem: subsystem, category: "now-playing")
}

/// Manages MPNowPlayingInfoCenter and MPRemoteCommandCenter for lock screen and Control Center integration
public final class NowPlayingManager {
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let infoCenter = MPNowPlayingInfoCenter.default()

    public init() {}

    // MARK: - Remote Commands Setup

    /// Sets up remote command handlers for lock screen and Control Center playback controls
    /// - Parameters:
    ///   - onPlay: Handler for play command
    ///   - onPause: Handler for pause command
    ///   - onSkipForward: Handler for skip forward command (receives interval in seconds)
    ///   - onSkipBackward: Handler for skip backward command (receives interval in seconds)
    ///   - onSeek: Handler for seek command (receives target position time in seconds)
    public func setupRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping (Double) -> Void,
        onSkipBackward: @escaping (Double) -> Void,
        onSeek: @escaping (Double) -> Void
    ) {
        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            onPlay()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            onPause()
            return .success
        }

        // Skip forward command (30 seconds per user decision)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { _ in
            onSkipForward(30)
            return .success
        }

        // Skip backward command (15 seconds per user decision)
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { _ in
            onSkipBackward(15)
            return .success
        }

        // Seek command (lock screen scrubber)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let seekEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            onSeek(seekEvent.positionTime)
            return .success
        }
    }

    // MARK: - Now Playing Info Update

    /// Updates Now Playing Info Center with current playback metadata
    /// Displays on lock screen, Control Center, CarPlay, and other system interfaces
    /// - Parameters:
    ///   - title: Recipe name (displayed as track title)
    ///   - artist: Speaker name (displayed as artist/narrator - VOICE-03)
    ///   - artworkURL: Recipe artwork URL (fetched via Kingfisher)
    ///   - duration: Total audio duration in seconds
    ///   - elapsedTime: Current playback position in seconds
    ///   - rate: Playback rate (1.0 = normal, 0.0 = paused)
    public func updateNowPlaying(
        title: String,
        artist: String,
        artworkURL: String?,
        duration: Double,
        elapsedTime: Double,
        rate: Double
    ) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]

        // Fetch artwork asynchronously via Kingfisher
        if let artworkURLString = artworkURL,
           let url = URL(string: artworkURLString) {
            // Use Kingfisher to download and cache artwork
            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
                switch result {
                case .success(let imageResult):
                    // Create NEW MPMediaItemArtwork instance (per Research Pitfall 6 - must recreate, not reuse)
                    let artwork = MPMediaItemArtwork(boundsSize: imageResult.image.size) { _ in
                        return imageResult.image
                    }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    self?.infoCenter.nowPlayingInfo = nowPlayingInfo

                case .failure(let error):
                    Logger.nowPlaying.warning("Failed to load artwork for Now Playing: \(error.localizedDescription, privacy: .public)")
                    // Set info without artwork
                    self?.infoCenter.nowPlayingInfo = nowPlayingInfo
                }
            }
        } else {
            // No artwork URL - set info without artwork
            infoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: - Cleanup

    /// Removes all command targets and clears Now Playing info
    /// Call when playback stops or app is terminating
    public func cleanup() {
        // Remove all command targets to prevent retain cycles
        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.skipForwardCommand.removeTarget(nil)
        commandCenter.skipBackwardCommand.removeTarget(nil)
        commandCenter.changePlaybackPositionCommand.removeTarget(nil)

        // Disable commands
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false

        // Clear Now Playing info from lock screen
        infoCenter.nowPlayingInfo = nil
    }
}
