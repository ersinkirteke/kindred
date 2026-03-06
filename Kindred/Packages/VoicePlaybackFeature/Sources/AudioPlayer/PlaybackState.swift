import Foundation
import SwiftUI

// MARK: - PlaybackStatus

public enum PlaybackStatus: Equatable, Sendable {
    case idle
    case loading
    case buffering
    case playing
    case paused
    case stopped
    case error(String)
}

// MARK: - PlaybackSpeed

public enum PlaybackSpeed: Float, Equatable, Sendable {
    case half = 0.5
    case threeQuarter = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5
    case double = 2.0

    public var next: PlaybackSpeed {
        switch self {
        case .half: return .threeQuarter
        case .threeQuarter: return .normal
        case .normal: return .oneAndQuarter
        case .oneAndQuarter: return .oneAndHalf
        case .oneAndHalf: return .double
        case .double: return .half
        }
    }
}

// MARK: - CurrentPlayback

public struct CurrentPlayback: Equatable, Sendable {
    public let recipeId: String
    public let recipeName: String
    public let voiceId: String
    public let speakerName: String
    public let artworkURL: String?
    public let duration: TimeInterval
    public let currentTime: TimeInterval
    public let speed: PlaybackSpeed
    public let status: PlaybackStatus
    public let currentStepIndex: Int?

    public init(
        recipeId: String,
        recipeName: String,
        voiceId: String,
        speakerName: String,
        artworkURL: String? = nil,
        duration: TimeInterval,
        currentTime: TimeInterval,
        speed: PlaybackSpeed,
        status: PlaybackStatus,
        currentStepIndex: Int? = nil
    ) {
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.voiceId = voiceId
        self.speakerName = speakerName
        self.artworkURL = artworkURL
        self.duration = duration
        self.currentTime = currentTime
        self.speed = speed
        self.status = status
        self.currentStepIndex = currentStepIndex
    }
}

// MARK: - Observable Playback State (propagates through navigation)

public class PlaybackObserver: ObservableObject {
    public static let shared = PlaybackObserver()
    @Published public var currentPlayback: CurrentPlayback?
    public init() {}
}

// MARK: - Environment Key

private struct CurrentPlaybackKey: EnvironmentKey {
    static let defaultValue: CurrentPlayback? = nil
}

public extension EnvironmentValues {
    var currentPlayback: CurrentPlayback? {
        get { self[CurrentPlaybackKey.self] }
        set { self[CurrentPlaybackKey.self] = newValue }
    }
}
