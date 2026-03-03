import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - VoicePlaybackReducer

@Reducer
public struct VoicePlaybackReducer {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var currentPlayback: CurrentPlayback?
        public var isExpanded: Bool = false
        public var voiceProfiles: [VoiceProfile] = []
        public var selectedVoiceId: String?
        public var lastUsedVoicePerRecipe: [String: String] = [:] // recipeId -> voiceId
        public var isLoadingNarration: Bool = false
        public var showVoicePicker: Bool = false
        public var narrationMetadata: NarrationMetadata?
        public var recipeSteps: [String] = []
        public var error: String?

        public init(
            currentPlayback: CurrentPlayback? = nil,
            isExpanded: Bool = false,
            voiceProfiles: [VoiceProfile] = [],
            selectedVoiceId: String? = nil,
            lastUsedVoicePerRecipe: [String: String] = [:],
            isLoadingNarration: Bool = false,
            showVoicePicker: Bool = false,
            narrationMetadata: NarrationMetadata? = nil,
            recipeSteps: [String] = [],
            error: String? = nil
        ) {
            self.currentPlayback = currentPlayback
            self.isExpanded = isExpanded
            self.voiceProfiles = voiceProfiles
            self.selectedVoiceId = selectedVoiceId
            self.lastUsedVoicePerRecipe = lastUsedVoicePerRecipe
            self.isLoadingNarration = isLoadingNarration
            self.showVoicePicker = showVoicePicker
            self.narrationMetadata = narrationMetadata
            self.recipeSteps = recipeSteps
            self.error = error
        }
    }

    // MARK: - Action

    public enum Action: Equatable {
        case startPlayback(recipeId: String, recipeName: String, artworkURL: String?, steps: [String])
        case voiceProfilesLoaded(Result<[VoiceProfile], Error>)
        case selectVoice(String)
        case narrationReady(NarrationMetadata)
        case narrationFailed(String)
        case play
        case pause
        case seekTo(TimeInterval)
        case skipForward
        case skipBackward
        case cycleSpeed
        case toggleExpanded
        case dismiss
        case timeUpdated(TimeInterval)
        case durationUpdated(TimeInterval)
        case statusChanged(PlaybackStatus)
        case switchVoiceMidPlayback(String)
        case previewVoiceSample(String)
        case stopPreview
        case cachingCompleted(URL)
        case cachingFailed(String)

        public static func == (lhs: Action, rhs: Action) -> Bool {
            switch (lhs, rhs) {
            case let (.startPlayback(lId, lName, lArt, lSteps), .startPlayback(rId, rName, rArt, rSteps)):
                return lId == rId && lName == rName && lArt == rArt && lSteps == rSteps
            case let (.voiceProfilesLoaded(.success(lProfiles)), .voiceProfilesLoaded(.success(rProfiles))):
                return lProfiles == rProfiles
            case let (.voiceProfilesLoaded(.failure(lError)), .voiceProfilesLoaded(.failure(rError))):
                return lError.localizedDescription == rError.localizedDescription
            case let (.selectVoice(lId), .selectVoice(rId)):
                return lId == rId
            case let (.narrationReady(lMeta), .narrationReady(rMeta)):
                return lMeta == rMeta
            case let (.narrationFailed(lErr), .narrationFailed(rErr)):
                return lErr == rErr
            case (.play, .play): return true
            case (.pause, .pause): return true
            case let (.seekTo(lTime), .seekTo(rTime)):
                return lTime == rTime
            case (.skipForward, .skipForward): return true
            case (.skipBackward, .skipBackward): return true
            case (.cycleSpeed, .cycleSpeed): return true
            case (.toggleExpanded, .toggleExpanded): return true
            case (.dismiss, .dismiss): return true
            case let (.timeUpdated(lTime), .timeUpdated(rTime)):
                return lTime == rTime
            case let (.durationUpdated(lDur), .durationUpdated(rDur)):
                return lDur == rDur
            case let (.statusChanged(lStatus), .statusChanged(rStatus)):
                return lStatus == rStatus
            case let (.switchVoiceMidPlayback(lId), .switchVoiceMidPlayback(rId)):
                return lId == rId
            case let (.previewVoiceSample(lId), .previewVoiceSample(rId)):
                return lId == rId
            case (.stopPreview, .stopPreview): return true
            case let (.cachingCompleted(lURL), .cachingCompleted(rURL)):
                return lURL == rURL
            case let (.cachingFailed(lErr), .cachingFailed(rErr)):
                return lErr == rErr
            default:
                return false
            }
        }
    }

    // MARK: - Dependencies

    @Dependency(\.audioPlayerClient) var audioPlayer
    @Dependency(\.voiceCacheClient) var voiceCache
    @Dependency(\.continuousClock) var clock

    // MARK: - CancelID

    private enum CancelID: Hashable {
        case timeObserver
        case statusObserver
        case durationObserver
        case autoCache
        case delayedDismiss
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .startPlayback(recipeId, recipeName, artworkURL, steps):
                state.recipeSteps = steps
                state.isLoadingNarration = true
                state.error = nil

                // Check last used voice for this recipe
                if let lastVoiceId = state.lastUsedVoicePerRecipe[recipeId] {
                    state.selectedVoiceId = lastVoiceId
                    state.showVoicePicker = false
                    // Auto-start with cached voice
                    return .run { send in
                        // Fetch voice profiles (to validate voice exists)
                        // TODO: Replace with actual GraphQL query
                        let mockProfiles = [
                            VoiceProfile(
                                id: lastVoiceId,
                                name: "My Voice",
                                avatarURL: nil,
                                sampleAudioURL: nil,
                                isOwnVoice: true,
                                createdAt: Date()
                            )
                        ]
                        await send(.voiceProfilesLoaded(.success(mockProfiles)))

                        // Auto-select the last used voice
                        await send(.selectVoice(lastVoiceId))
                    }
                } else {
                    state.showVoicePicker = true
                    // Fetch available voice profiles
                    return .run { send in
                        // TODO: Replace with actual GraphQL query to fetch voice profiles
                        // For now, return mock profiles
                        let mockProfiles = [
                            VoiceProfile(
                                id: "voice-1",
                                name: "My Voice",
                                avatarURL: nil,
                                sampleAudioURL: "https://example.com/sample.m4a",
                                isOwnVoice: true,
                                createdAt: Date()
                            ),
                            VoiceProfile(
                                id: "voice-2",
                                name: "Mom",
                                avatarURL: nil,
                                sampleAudioURL: "https://example.com/sample2.m4a",
                                isOwnVoice: false,
                                createdAt: Date()
                            )
                        ]
                        await send(.voiceProfilesLoaded(.success(mockProfiles)))
                    }
                }

            case let .voiceProfilesLoaded(.success(profiles)):
                state.voiceProfiles = profiles
                state.error = nil
                return .none

            case let .voiceProfilesLoaded(.failure(error)):
                state.error = error.localizedDescription
                state.isLoadingNarration = false
                return .none

            case let .selectVoice(voiceId):
                guard let currentRecipeId = state.currentPlayback?.recipeId ?? state.recipeSteps.isEmpty ? nil : "pending" else {
                    return .none
                }

                state.selectedVoiceId = voiceId
                state.showVoicePicker = false
                state.isLoadingNarration = true

                // Store in lastUsedVoicePerRecipe (will be persisted via @AppStorage later)
                if let recipeId = state.currentPlayback?.recipeId {
                    state.lastUsedVoicePerRecipe[recipeId] = voiceId
                }

                // Check cache first
                return .run { [voiceId] send in
                    // TODO: Extract recipeId from pending state
                    let recipeId = "recipe-1" // Placeholder

                    if let cachedURL = await voiceCache.getCachedAudio(voiceId, recipeId) {
                        // Load from cache
                        let metadata = NarrationMetadata(
                            recipeId: recipeId,
                            voiceId: voiceId,
                            audioURL: cachedURL.absoluteString,
                            duration: 300, // Placeholder
                            stepTimestamps: [0, 30, 60, 120, 180, 240], // Placeholder
                            generatedAt: Date()
                        )
                        await send(.narrationReady(metadata))
                    } else {
                        // Stream from remote
                        // TODO: Replace with actual narration API call (GraphQL mutation or R2 presigned URL)
                        let remoteURL = "https://example.com/narration/\(recipeId)_\(voiceId).m4a"
                        let metadata = NarrationMetadata(
                            recipeId: recipeId,
                            voiceId: voiceId,
                            audioURL: remoteURL,
                            duration: 300,
                            stepTimestamps: [0, 30, 60, 120, 180, 240],
                            generatedAt: Date()
                        )
                        await send(.narrationReady(metadata))
                    }
                }

            case let .narrationReady(metadata):
                state.narrationMetadata = metadata
                state.isLoadingNarration = false

                // Create CurrentPlayback with initial values
                guard let voiceProfile = state.voiceProfiles.first(where: { $0.id == metadata.voiceId }) else {
                    state.error = "Voice profile not found"
                    return .none
                }

                state.currentPlayback = CurrentPlayback(
                    recipeId: metadata.recipeId,
                    recipeName: "Recipe Name", // TODO: Get from state
                    voiceId: metadata.voiceId,
                    speakerName: voiceProfile.name,
                    artworkURL: nil, // TODO: Get from state
                    duration: metadata.duration,
                    currentTime: 0,
                    speed: .normal,
                    status: .loading,
                    currentStepIndex: nil
                )

                // Start observing streams and play audio
                return .run { send in
                    guard let url = URL(string: metadata.audioURL) else {
                        await send(.narrationFailed("Invalid audio URL"))
                        return
                    }

                    // Start audio playback
                    try await audioPlayer.play(url)

                    // Observe time updates
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await time in audioPlayer.currentTimeStream() {
                                await send(.timeUpdated(time))
                            }
                        }

                        group.addTask {
                            for await status in audioPlayer.statusStream() {
                                await send(.statusChanged(status))
                            }
                        }

                        group.addTask {
                            for await duration in audioPlayer.durationStream() {
                                await send(.durationUpdated(duration))
                            }
                        }
                    }
                }
                .cancellable(id: CancelID.timeObserver)

            case let .narrationFailed(errorMessage):
                state.error = errorMessage
                state.isLoadingNarration = false
                return .none

            case .play:
                guard state.currentPlayback?.status == .paused else { return .none }
                return .run { _ in
                    await audioPlayer.resume()
                }

            case .pause:
                guard state.currentPlayback?.status == .playing else { return .none }
                return .run { _ in
                    await audioPlayer.pause()
                }

            case let .seekTo(time):
                guard let currentPlayback = state.currentPlayback else { return .none }
                let clampedTime = max(0, min(time, currentPlayback.duration))

                // Update UI immediately for responsiveness
                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: clampedTime,
                    speed: currentPlayback.speed,
                    status: currentPlayback.status,
                    currentStepIndex: currentPlayback.currentStepIndex
                )

                return .run { _ in
                    await audioPlayer.seek(clampedTime)
                }

            case .skipForward:
                guard let currentPlayback = state.currentPlayback else { return .none }
                let targetTime = min(currentPlayback.currentTime + 30, currentPlayback.duration)
                return .send(.seekTo(targetTime))

            case .skipBackward:
                guard let currentPlayback = state.currentPlayback else { return .none }
                let targetTime = max(currentPlayback.currentTime - 15, 0)
                return .send(.seekTo(targetTime))

            case .cycleSpeed:
                guard var currentPlayback = state.currentPlayback else { return .none }
                let nextSpeed = currentPlayback.speed.next

                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: currentPlayback.currentTime,
                    speed: nextSpeed,
                    status: currentPlayback.status,
                    currentStepIndex: currentPlayback.currentStepIndex
                )

                return .run { _ in
                    await audioPlayer.setRate(nextSpeed.rawValue)
                }

            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none

            case .dismiss:
                state.isExpanded = false
                state.currentPlayback = nil
                state.narrationMetadata = nil
                state.selectedVoiceId = nil
                state.error = nil

                // Cancel all stream observations
                return .concatenate(
                    .cancel(id: CancelID.timeObserver),
                    .cancel(id: CancelID.statusObserver),
                    .cancel(id: CancelID.durationObserver),
                    .cancel(id: CancelID.autoCache),
                    .cancel(id: CancelID.delayedDismiss),
                    .run { _ in
                        await audioPlayer.cleanup()
                    }
                )

            case let .timeUpdated(time):
                guard var currentPlayback = state.currentPlayback else { return .none }

                // Update step index using StepSyncEngine
                let stepIndex: Int?
                if let metadata = state.narrationMetadata {
                    stepIndex = StepSyncEngine.currentStepIndex(
                        at: time,
                        timestamps: metadata.stepTimestamps
                    )
                } else {
                    stepIndex = nil
                }

                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: time,
                    speed: currentPlayback.speed,
                    status: currentPlayback.status,
                    currentStepIndex: stepIndex
                )

                return .none

            case let .durationUpdated(duration):
                guard var currentPlayback = state.currentPlayback else { return .none }

                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: duration,
                    currentTime: currentPlayback.currentTime,
                    speed: currentPlayback.speed,
                    status: currentPlayback.status,
                    currentStepIndex: currentPlayback.currentStepIndex
                )

                return .none

            case let .statusChanged(status):
                guard var currentPlayback = state.currentPlayback else { return .none }

                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: currentPlayback.currentTime,
                    speed: currentPlayback.speed,
                    status: status,
                    currentStepIndex: currentPlayback.currentStepIndex
                )

                // Handle auto-dismiss on stopped
                if case .stopped = status {
                    return .run { send in
                        try await clock.sleep(for: .seconds(2))
                        await send(.dismiss)
                    }
                    .cancellable(id: CancelID.delayedDismiss)
                }

                // Handle auto-cache on playing (if not already cached)
                if case .playing = status,
                   let metadata = state.narrationMetadata,
                   !voiceCache.isCached(metadata.voiceId, metadata.recipeId) {
                    return .run { send in
                        // Download audio data and cache it
                        guard let url = URL(string: metadata.audioURL) else { return }

                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            let cachedURL = try await voiceCache.cacheAudio(
                                metadata.voiceId,
                                metadata.recipeId,
                                data
                            )
                            await send(.cachingCompleted(cachedURL))
                        } catch {
                            await send(.cachingFailed(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.autoCache)
                }

                return .none

            case let .switchVoiceMidPlayback(newVoiceId):
                guard var currentPlayback = state.currentPlayback else { return .none }
                let savedTime = currentPlayback.currentTime

                state.isLoadingNarration = true
                state.selectedVoiceId = newVoiceId
                state.lastUsedVoicePerRecipe[currentPlayback.recipeId] = newVoiceId

                return .run { send in
                    // Pause current playback
                    await audioPlayer.pause()

                    // Fetch new voice narration
                    // TODO: Replace with actual narration API call
                    let newMetadata = NarrationMetadata(
                        recipeId: currentPlayback.recipeId,
                        voiceId: newVoiceId,
                        audioURL: "https://example.com/narration/\(currentPlayback.recipeId)_\(newVoiceId).m4a",
                        duration: 300,
                        stepTimestamps: [0, 30, 60, 120, 180, 240],
                        generatedAt: Date()
                    )

                    await send(.narrationReady(newMetadata))

                    // Seek to saved position
                    await send(.seekTo(savedTime))
                }

            case let .previewVoiceSample(voiceId):
                guard let profile = state.voiceProfiles.first(where: { $0.id == voiceId }),
                      let sampleURL = profile.sampleAudioURL,
                      let url = URL(string: sampleURL) else {
                    return .none
                }

                return .run { _ in
                    try await audioPlayer.play(url)
                }

            case .stopPreview:
                return .run { _ in
                    await audioPlayer.pause()
                    await audioPlayer.cleanup()
                }

            case let .cachingCompleted(url):
                // Non-critical success - no UI update needed
                return .none

            case let .cachingFailed(errorMessage):
                // Non-critical failure - log but don't block playback
                print("Caching failed (non-critical): \(errorMessage)")
                return .none
            }
        }
    }
}
