import Foundation

// MARK: - VoiceProfile

public struct VoiceProfile: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let avatarURL: String?
    public let sampleAudioURL: String?
    public let isOwnVoice: Bool
    public let createdAt: Date

    public init(
        id: String,
        name: String,
        avatarURL: String? = nil,
        sampleAudioURL: String? = nil,
        isOwnVoice: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        self.sampleAudioURL = sampleAudioURL
        self.isOwnVoice = isOwnVoice
        self.createdAt = createdAt
    }
}
