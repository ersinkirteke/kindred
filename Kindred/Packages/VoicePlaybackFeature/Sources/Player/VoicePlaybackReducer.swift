import ComposableArchitecture
import Foundation
import MonetizationFeature
import Network
import SwiftUI
import UIKit
import OSLog
import Apollo
import KindredAPI
import NetworkClient

// MARK: - Logger Extension

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let voicePlayback = Logger(subsystem: subsystem, category: "voice-playback")
}

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
        public var pendingRecipeId: String?
        public var pendingRecipeName: String?
        public var pendingArtworkURL: String?
        public var voiceUpload: VoiceUploadReducer.State?
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var showPaywall: Bool = false
        public var hasNarration: Bool = true
        public var isAVSpeechActive: Bool = false
        public var offlineFallbackNote: String? = nil

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
            error: String? = nil,
            pendingRecipeId: String? = nil,
            pendingRecipeName: String? = nil,
            pendingArtworkURL: String? = nil,
            voiceUpload: VoiceUploadReducer.State? = nil,
            subscriptionStatus: SubscriptionStatus = .unknown,
            showPaywall: Bool = false,
            hasNarration: Bool = true,
            isAVSpeechActive: Bool = false,
            offlineFallbackNote: String? = nil
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
            self.pendingRecipeId = pendingRecipeId
            self.pendingRecipeName = pendingRecipeName
            self.pendingArtworkURL = pendingArtworkURL
            self.voiceUpload = voiceUpload
            self.subscriptionStatus = subscriptionStatus
            self.showPaywall = showPaywall
            self.hasNarration = hasNarration
            self.isAVSpeechActive = isAVSpeechActive
            self.offlineFallbackNote = offlineFallbackNote
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
        case dismissVoicePicker
        case showVoiceSwitcher
        case showVoiceUpload
        case voiceUpload(VoiceUploadReducer.Action)
        case checkSubscriptionStatus
        case subscriptionStatusUpdated(SubscriptionStatus)
        case upgradeTapped
        case showPaywall
        case dismissPaywall
        case narrationAvailabilityChecked(Bool)
        case retryNarration
        case avSpeechStepChanged(Int)
        case showVoicePickerForNewPlayback
        case offlineFallbackToKindredVoice
        case jumpToStepRequested(Int)

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
            case (.dismissVoicePicker, .dismissVoicePicker): return true
            case (.showVoiceSwitcher, .showVoiceSwitcher): return true
            case (.showVoiceUpload, .showVoiceUpload): return true
            case let (.voiceUpload(lAction), .voiceUpload(rAction)):
                return lAction == rAction
            case (.checkSubscriptionStatus, .checkSubscriptionStatus): return true
            case let (.subscriptionStatusUpdated(lStatus), .subscriptionStatusUpdated(rStatus)):
                return lStatus == rStatus
            case (.upgradeTapped, .upgradeTapped): return true
            case (.showPaywall, .showPaywall): return true
            case (.dismissPaywall, .dismissPaywall): return true
            case let (.narrationAvailabilityChecked(lVal), .narrationAvailabilityChecked(rVal)):
                return lVal == rVal
            case (.retryNarration, .retryNarration): return true
            case let (.avSpeechStepChanged(lIdx), .avSpeechStepChanged(rIdx)):
                return lIdx == rIdx
            case (.showVoicePickerForNewPlayback, .showVoicePickerForNewPlayback): return true
            case (.offlineFallbackToKindredVoice, .offlineFallbackToKindredVoice): return true
            case let (.jumpToStepRequested(lIdx), .jumpToStepRequested(rIdx)):
                return lIdx == rIdx
            default:
                return false
            }
        }
    }

    // MARK: - Dependencies

    @Dependency(\.audioPlayerClient) var audioPlayer
    @Dependency(\.voiceCacheClient) var voiceCache
    @Dependency(\.continuousClock) var clock
    @Dependency(\.subscriptionClient) var subscriptionClient
    @Dependency(\.apolloClient) var apolloClient
    @Dependency(\.avSpeechClient) var avSpeechClient
    @Dependency(\.nowPlayingManager) var nowPlayingManager

    // MARK: - CancelID

    private enum CancelID: Hashable {
        case timeObserver
        case statusObserver
        case durationObserver
        case autoCache
        case delayedDismiss
        case avSpeechStepObserver
        case avSpeechStatusObserver
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showVoiceUpload:
                state.showVoicePicker = false
                state.voiceUpload = VoiceUploadReducer.State()
                return .none

            case .voiceUpload(.dismiss):
                state.voiceUpload = nil
                return .none

            case let .voiceUpload(.uploadCompleted(profile)):
                // Add the new profile to the list
                state.voiceProfiles.append(profile)
                return .none

            case .voiceUpload:
                return .none

            case let .startPlayback(recipeId, recipeName, artworkURL, steps):
                state.recipeSteps = steps
                state.pendingRecipeId = recipeId
                state.pendingRecipeName = recipeName
                state.pendingArtworkURL = artworkURL

                // Early exit if narration not available
                if !state.hasNarration {
                    state.error = "Narration not available"
                    state.isLoadingNarration = false
                    return .none
                }

                state.error = nil

                // Check last used voice for this recipe
                if let lastVoiceId = state.lastUsedVoicePerRecipe[recipeId] {
                    // If last used voice was Kindred Voice, start immediately (no network needed)
                    if lastVoiceId == "kindred-default" {
                        return .send(.selectVoice("kindred-default"))
                    }
                    state.selectedVoiceId = lastVoiceId
                    state.showVoicePicker = false
                    state.isLoadingNarration = true
                    // Auto-start with cached voice — ensure selectVoice fires even if profiles fail
                    return .run { [lastVoiceId] send in
                        do {
                            let result = try await apolloClient.fetch(query: KindredAPI.VoiceProfilesQuery())
                            let profiles = (result.data?.myVoiceProfiles ?? [])
                                .filter { $0.status == .ready }
                                .map { dto -> VoiceProfile in
                                    let dateFormatter = ISO8601DateFormatter()
                                    let createdAt = dateFormatter.date(from: dto.createdAt) ?? Date()
                                    return VoiceProfile(
                                        id: dto.id,
                                        name: dto.speakerName,
                                        avatarURL: nil,
                                        sampleAudioURL: nil,
                                        isOwnVoice: dto.relationship == "Self",
                                        createdAt: createdAt
                                    )
                                }
                            await send(.voiceProfilesLoaded(.success(profiles)))
                        } catch {
                            await send(.voiceProfilesLoaded(.failure(error)))
                        }
                        // Always send selectVoice regardless of profile fetch success/failure
                        await send(.selectVoice(lastVoiceId))
                    }
                } else {
                    state.isLoadingNarration = true
                    // Fetch subscription + profiles, then route
                    return .merge(
                        // Start AVSpeech immediately for responsiveness — will be cancelled if Pro user picks different voice
                        .send(.selectVoice("kindred-default")),
                        // Background: fetch subscription status + voice profiles
                        .run { send in
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.subscriptionStatusUpdated(status))

                            do {
                                let result = try await apolloClient.fetch(query: KindredAPI.VoiceProfilesQuery())
                                var profiles = (result.data?.myVoiceProfiles ?? [])
                                    .filter { $0.status == .ready }
                                    .map { dto -> VoiceProfile in
                                        let dateFormatter = ISO8601DateFormatter()
                                        let createdAt = dateFormatter.date(from: dto.createdAt) ?? Date()
                                        return VoiceProfile(
                                            id: dto.id,
                                            name: dto.speakerName,
                                            avatarURL: nil,
                                            sampleAudioURL: nil,
                                            isOwnVoice: dto.relationship == "Self",
                                            createdAt: createdAt
                                        )
                                    }

                                let defaultVoice = VoiceProfile(
                                    id: "kindred-default",
                                    name: "Kindred Voice",
                                    avatarURL: nil,
                                    sampleAudioURL: nil,
                                    isOwnVoice: false,
                                    createdAt: Date()
                                )
                                profiles.insert(defaultVoice, at: 0)

                                await send(.voiceProfilesLoaded(.success(profiles)))
                            } catch {
                                await send(.voiceProfilesLoaded(.failure(error)))
                            }

                            // If Pro user, show voice picker (they can switch from the already-playing Kindred Voice)
                            if case .pro = status {
                                await send(.showVoicePickerForNewPlayback)
                            }
                        }
                    )
                }

            case let .voiceProfilesLoaded(.success(profiles)):
                state.voiceProfiles = profiles
                state.error = nil
                return .none

            case let .voiceProfilesLoaded(.failure(error)):
                Logger.voicePlayback.error("voiceProfilesLoaded FAILED: \(error.localizedDescription)")
                state.error = error.localizedDescription
                state.isLoadingNarration = false
                return .none

            case let .selectVoice(voiceId):
                let pendingId = state.pendingRecipeId ?? "nil"
                let currentId = state.currentPlayback?.recipeId ?? "nil"
                let stepCount = state.recipeSteps.count
                Logger.voicePlayback.debug("selectVoice: \(voiceId) pendingRecipeId=\(pendingId) currentPlayback=\(currentId) steps=\(stepCount)")
                guard state.currentPlayback?.recipeId != nil || state.pendingRecipeId != nil else {
                    Logger.voicePlayback.error("selectVoice: guard FAILED — no pending or current recipe")
                    return .none
                }

                state.selectedVoiceId = voiceId
                state.showVoicePicker = false

                let recipeId = state.pendingRecipeId ?? state.currentPlayback?.recipeId ?? "unknown"

                // Store in lastUsedVoicePerRecipe
                state.lastUsedVoicePerRecipe[recipeId] = voiceId

                // --- AVSpeech branch: Kindred Voice (free tier, on-device) ---
                if voiceId == "kindred-default" {
                    // Cancel any active ElevenLabs streams
                    state.isAVSpeechActive = true
                    state.isLoadingNarration = false
                    state.offlineFallbackNote = nil

                    let recipeName = state.pendingRecipeName ?? "Recipe"
                    let artworkURL = state.pendingArtworkURL
                    let preprocessedSteps = TextPreprocessor.prepareSteps(state.recipeSteps)
                    let currentSpeed = state.currentPlayback?.speed ?? .normal

                    state.currentPlayback = CurrentPlayback(
                        recipeId: recipeId,
                        recipeName: recipeName,
                        voiceId: "kindred-default",
                        speakerName: "Kindred Voice",
                        artworkURL: artworkURL,
                        duration: 0,
                        currentTime: 0,
                        speed: currentSpeed,
                        status: .loading,
                        currentStepIndex: 0
                    )

                    return .concatenate(
                        // Cancel existing AVPlayer streams
                        .cancel(id: CancelID.timeObserver),
                        .cancel(id: CancelID.statusObserver),
                        .cancel(id: CancelID.durationObserver),
                        .cancel(id: CancelID.autoCache),
                        // Cancel any existing AVSpeech streams
                        .cancel(id: CancelID.avSpeechStatusObserver),
                        .cancel(id: CancelID.avSpeechStepObserver),
                        // Cleanup existing AVPlayer
                        .run { _ in await audioPlayer.cleanup() },
                        // Start AVSpeech and observe streams
                        .merge(
                            .run { [preprocessedSteps, currentSpeed] send in
                                do {
                                    try await avSpeechClient.speak(preprocessedSteps, currentSpeed)
                                } catch {
                                    await send(.narrationFailed(error.localizedDescription))
                                }
                            },
                            .run { send in
                                for await status in await avSpeechClient.statusStream() {
                                    await send(.statusChanged(status))
                                }
                            }.cancellable(id: CancelID.avSpeechStatusObserver),
                            .run { send in
                                for await index in await avSpeechClient.stepIndexStream() {
                                    await send(.avSpeechStepChanged(index))
                                }
                            }.cancellable(id: CancelID.avSpeechStepObserver)
                        )
                    )
                }

                // --- ElevenLabs / AVPlayer branch (Pro voices) ---
                state.isLoadingNarration = true

                return .run { [voiceId, recipeId] send in
                    // Check for offline + uncached: fallback to Kindred Voice
                    let hasCachedAudio = await voiceCache.getCachedAudio(voiceId, recipeId) != nil
                    if !hasCachedAudio {
                        let monitor = NWPathMonitor()
                        let isOnline = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                            monitor.pathUpdateHandler = { path in
                                monitor.cancel()
                                continuation.resume(returning: path.status == .satisfied)
                            }
                            monitor.start(queue: DispatchQueue(label: "network.check"))
                        }
                        if !isOnline {
                            await send(.offlineFallbackToKindredVoice)
                            return
                        }
                    }

                    // Cache-first per locked decision
                    if let cachedURL = await voiceCache.getCachedAudio(voiceId, recipeId) {
                        // Load cached metadata (step timestamps stored alongside audio)
                        let cachedMetadata = await voiceCache.getCachedMetadata(voiceId, recipeId)
                        let metadata = NarrationMetadata(
                            recipeId: recipeId,
                            voiceId: voiceId,
                            audioURL: cachedURL.absoluteString,
                            duration: cachedMetadata?.duration ?? 0,
                            stepTimestamps: cachedMetadata?.stepTimestamps ?? [],
                            generatedAt: cachedMetadata?.generatedAt ?? Date()
                        )
                        await send(.narrationReady(metadata))
                    } else {
                        // Fetch from backend via GraphQL
                        do {
                            let result = try await apolloClient.fetch(
                                query: KindredAPI.NarrationUrlQuery(recipeId: recipeId, voiceProfileId: .some(voiceId))
                            )
                            guard let narrationData = result.data?.narrationUrl,
                                  let audioUrl = narrationData.url else {
                                await send(.narrationFailed("Narration not available"))
                                return
                            }

                            let metadata = NarrationMetadata(
                                recipeId: recipeId,
                                voiceId: voiceId,
                                audioURL: audioUrl,
                                duration: TimeInterval(narrationData.durationMs ?? 0) / 1000.0,
                                stepTimestamps: [],
                                generatedAt: Date()
                            )
                            await send(.narrationReady(metadata))
                        } catch {
                            await send(.narrationFailed(error.localizedDescription))
                        }
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
                    recipeName: state.pendingRecipeName ?? "Recipe",
                    voiceId: metadata.voiceId,
                    speakerName: voiceProfile.name,
                    artworkURL: state.pendingArtworkURL,
                    duration: metadata.duration,
                    currentTime: 0,
                    speed: .normal,
                    status: .loading,
                    currentStepIndex: nil
                )

                // Play first so the player is set up, then start observing streams
                return .concatenate(
                    .run { send in
                        guard let url = URL(string: metadata.audioURL) else {
                            await send(.narrationFailed("Invalid audio URL"))
                            return
                        }
                        do {
                            try await audioPlayer.play(url)
                        } catch {
                            await send(.narrationFailed("\(url.absoluteString) — \(error.localizedDescription)"))
                        }
                    },
                    .merge(
                        .run { send in
                            for await time in await audioPlayer.currentTimeStream() {
                                await send(.timeUpdated(time))
                            }
                        }
                        .cancellable(id: CancelID.timeObserver),
                        .run { send in
                            for await status in await audioPlayer.statusStream() {
                                await send(.statusChanged(status))
                            }
                        }
                        .cancellable(id: CancelID.statusObserver),
                        .run { send in
                            for await duration in await audioPlayer.durationStream() {
                                await send(.durationUpdated(duration))
                            }
                        }
                        .cancellable(id: CancelID.durationObserver)
                    )
                )

            case let .narrationFailed(errorMessage):
                state.error = errorMessage
                state.isLoadingNarration = false
                // Keep currentPlayback visible so user can see error state
                if let currentPlayback = state.currentPlayback {
                    state.currentPlayback = CurrentPlayback(
                        recipeId: currentPlayback.recipeId,
                        recipeName: currentPlayback.recipeName,
                        voiceId: currentPlayback.voiceId,
                        speakerName: currentPlayback.speakerName,
                        artworkURL: currentPlayback.artworkURL,
                        duration: currentPlayback.duration,
                        currentTime: currentPlayback.currentTime,
                        speed: currentPlayback.speed,
                        status: .error(errorMessage),
                        currentStepIndex: currentPlayback.currentStepIndex
                    )
                }
                return .none

            case .play:
                guard let currentPlayback = state.currentPlayback,
                      currentPlayback.status != .playing,
                      currentPlayback.status != .buffering else { return .none }

                // If near the end, restart from beginning
                let shouldRestart = currentPlayback.currentTime >= currentPlayback.duration - 0.5
                    && currentPlayback.duration > 0

                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: shouldRestart ? 0 : currentPlayback.currentTime,
                    speed: currentPlayback.speed,
                    status: .playing,
                    currentStepIndex: shouldRestart ? 0 : currentPlayback.currentStepIndex
                )

                // VoiceOver announcement
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Now playing: \(currentPlayback.recipeName) by \(currentPlayback.speakerName)"
                )

                if state.isAVSpeechActive {
                    return .run { _ in
                        if shouldRestart {
                            await avSpeechClient.jumpToStep(0)
                        }
                        await avSpeechClient.resume()
                    }
                } else {
                    return .run { _ in
                        if shouldRestart {
                            await audioPlayer.seek(0)
                        }
                        await audioPlayer.resume()
                    }
                }

            case .pause:
                guard let currentPlayback = state.currentPlayback,
                      currentPlayback.status == .playing || currentPlayback.status == .buffering || currentPlayback.status == .loading else { return .none }
                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: currentPlayback.currentTime,
                    speed: currentPlayback.speed,
                    status: .paused,
                    currentStepIndex: currentPlayback.currentStepIndex
                )

                // VoiceOver announcement
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Paused"
                )

                if state.isAVSpeechActive {
                    return .run { _ in
                        await avSpeechClient.pause()
                    }
                } else {
                    return .run { _ in
                        await audioPlayer.pause()
                    }
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
                guard let currentPlayback = state.currentPlayback else { return .none }
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

                if state.isAVSpeechActive {
                    return .run { _ in
                        await avSpeechClient.setRate(nextSpeed.rawValue)
                    }
                } else {
                    return .run { _ in
                        await audioPlayer.setRate(nextSpeed.rawValue)
                    }
                }

            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none

            case .dismissVoicePicker:
                state.showVoicePicker = false
                state.isLoadingNarration = false
                return .none

            case .showVoiceSwitcher:
                // Stop playback, close expanded player, show voice picker
                state.isExpanded = false
                state.showVoicePicker = true
                state.isLoadingNarration = false
                state.currentPlayback = nil
                state.narrationMetadata = nil
                let wasAVSpeechActive = state.isAVSpeechActive
                state.isAVSpeechActive = false

                if wasAVSpeechActive {
                    return .concatenate(
                        .cancel(id: CancelID.avSpeechStatusObserver),
                        .cancel(id: CancelID.avSpeechStepObserver),
                        .cancel(id: CancelID.delayedDismiss),
                        .run { _ in
                            await avSpeechClient.cleanup()
                        }
                    )
                } else {
                    return .concatenate(
                        .cancel(id: CancelID.timeObserver),
                        .cancel(id: CancelID.autoCache),
                        .cancel(id: CancelID.delayedDismiss),
                        .run { _ in
                            await audioPlayer.cleanup()
                        }
                    )
                }

            case .dismiss:
                state.isExpanded = false
                state.currentPlayback = nil
                state.narrationMetadata = nil
                state.selectedVoiceId = nil
                state.error = nil
                let wasAVSpeechActiveDismiss = state.isAVSpeechActive
                state.isAVSpeechActive = false
                state.offlineFallbackNote = nil

                if wasAVSpeechActiveDismiss {
                    // Cancel all AVSpeech observations
                    return .concatenate(
                        .cancel(id: CancelID.avSpeechStatusObserver),
                        .cancel(id: CancelID.avSpeechStepObserver),
                        .cancel(id: CancelID.delayedDismiss),
                        .run { _ in
                            await avSpeechClient.cleanup()
                        }
                    )
                } else {
                    // Cancel all AVPlayer stream observations
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
                }

            case let .timeUpdated(time):
                guard let currentPlayback = state.currentPlayback else { return .none }

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
                guard let currentPlayback = state.currentPlayback else { return .none }

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
                guard let currentPlayback = state.currentPlayback else { return .none }

                // Don't let stream status override error state, but allow Pro AVSpeech fallback
                if case .error(let message) = currentPlayback.status {
                    // Pro user AVSpeech error: auto-fallback to ElevenLabs
                    if state.isAVSpeechActive, case .pro = state.subscriptionStatus {
                        let firstProVoiceId = state.voiceProfiles.first(where: { $0.id != "kindred-default" })?.id
                        if let proVoiceId = firstProVoiceId {
                            state.isAVSpeechActive = false
                            return .concatenate(
                                .cancel(id: CancelID.avSpeechStepObserver),
                                .cancel(id: CancelID.avSpeechStatusObserver),
                                .run { _ in await avSpeechClient.cleanup() },
                                .send(.selectVoice(proVoiceId))
                            )
                        }
                    }
                    return .none
                }

                // Handle .error status from stream (before setting status)
                if case .error(let errorMessage) = status {
                    // Pro user AVSpeech error: auto-fallback to ElevenLabs silently
                    if state.isAVSpeechActive, case .pro = state.subscriptionStatus {
                        let firstProVoiceId = state.voiceProfiles.first(where: { $0.id != "kindred-default" })?.id
                        if let proVoiceId = firstProVoiceId {
                            state.isAVSpeechActive = false
                            return .concatenate(
                                .cancel(id: CancelID.avSpeechStepObserver),
                                .cancel(id: CancelID.avSpeechStatusObserver),
                                .run { _ in await avSpeechClient.cleanup() },
                                .send(.selectVoice(proVoiceId))
                            )
                        }
                    }
                    // Free user or no Pro voice: show error normally
                    state.currentPlayback = CurrentPlayback(
                        recipeId: currentPlayback.recipeId,
                        recipeName: currentPlayback.recipeName,
                        voiceId: currentPlayback.voiceId,
                        speakerName: currentPlayback.speakerName,
                        artworkURL: currentPlayback.artworkURL,
                        duration: currentPlayback.duration,
                        currentTime: currentPlayback.currentTime,
                        speed: currentPlayback.speed,
                        status: .error(errorMessage),
                        currentStepIndex: currentPlayback.currentStepIndex
                    )
                    return .none
                }

                // Don't let AVSpeech stream override a user-initiated .paused
                // Race: pauseSpeaking can race with didStart (.playing) or didFinish (.stopped)
                // of the current/next utterance, which would override the pause state
                if currentPlayback.status == .paused {
                    switch status {
                    case .playing, .stopped:
                        return .none
                    default:
                        break
                    }
                }

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
                    if state.isAVSpeechActive {
                        // Cancel AVSpeech streams and schedule delayed dismiss
                        return .concatenate(
                            .cancel(id: CancelID.avSpeechStatusObserver),
                            .cancel(id: CancelID.avSpeechStepObserver),
                            .run { [clock] send in
                                try await clock.sleep(for: .seconds(2))
                                await send(.dismiss)
                            }
                            .cancellable(id: CancelID.delayedDismiss)
                        )
                    } else {
                        // Cancel AVPlayer streams immediately to prevent further events,
                        // then schedule delayed dismiss for cleanup
                        return .concatenate(
                            .cancel(id: CancelID.timeObserver),
                            .cancel(id: CancelID.autoCache),
                            .run { [clock] send in
                                try await clock.sleep(for: .seconds(2))
                                await send(.dismiss)
                            }
                            .cancellable(id: CancelID.delayedDismiss)
                        )
                    }
                }

                // Handle auto-cache on playing (if not already cached) — only for ElevenLabs
                if case .playing = status,
                   !state.isAVSpeechActive,
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

                            // Cache metadata alongside audio
                            try await voiceCache.cacheMetadata(
                                metadata.voiceId,
                                metadata.recipeId,
                                NarrationCacheMetadata(
                                    duration: metadata.duration,
                                    stepTimestamps: metadata.stepTimestamps,
                                    generatedAt: metadata.generatedAt
                                )
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
                guard let currentPlayback = state.currentPlayback else { return .none }
                let savedStepIndex = currentPlayback.currentStepIndex ?? 0
                let savedTime = currentPlayback.currentTime

                state.isLoadingNarration = true
                state.selectedVoiceId = newVoiceId
                state.lastUsedVoicePerRecipe[currentPlayback.recipeId] = newVoiceId

                // Switching TO Kindred Voice from ElevenLabs
                if newVoiceId == "kindred-default" {
                    state.isAVSpeechActive = false // will be set to true in selectVoice
                    return .concatenate(
                        .cancel(id: CancelID.timeObserver),
                        .cancel(id: CancelID.statusObserver),
                        .cancel(id: CancelID.durationObserver),
                        .cancel(id: CancelID.autoCache),
                        .run { _ in await audioPlayer.cleanup() },
                        .send(.selectVoice("kindred-default"))
                    )
                }

                // Switching FROM Kindred Voice to ElevenLabs
                if state.isAVSpeechActive {
                    state.isAVSpeechActive = false
                    return .concatenate(
                        .cancel(id: CancelID.avSpeechStatusObserver),
                        .cancel(id: CancelID.avSpeechStepObserver),
                        .run { _ in await avSpeechClient.cleanup() },
                        .send(.selectVoice(newVoiceId))
                    )
                }

                return .run { [recipeId = currentPlayback.recipeId] send in
                    // Pause current AVPlayer playback
                    await audioPlayer.pause()

                    // Fetch new voice narration (cache-first, then GraphQL)
                    if let cachedURL = await voiceCache.getCachedAudio(newVoiceId, recipeId) {
                        let cachedMetadata = await voiceCache.getCachedMetadata(newVoiceId, recipeId)
                        let metadata = NarrationMetadata(
                            recipeId: recipeId,
                            voiceId: newVoiceId,
                            audioURL: cachedURL.absoluteString,
                            duration: cachedMetadata?.duration ?? 0,
                            stepTimestamps: cachedMetadata?.stepTimestamps ?? [],
                            generatedAt: cachedMetadata?.generatedAt ?? Date()
                        )
                        await send(.narrationReady(metadata))
                    } else {
                        do {
                            let result = try await apolloClient.fetch(
                                query: KindredAPI.NarrationUrlQuery(recipeId: recipeId, voiceProfileId: .some(newVoiceId))
                            )
                            guard let narrationData = result.data?.narrationUrl,
                                  let audioUrl = narrationData.url else {
                                await send(.narrationFailed("Narration not available"))
                                return
                            }

                            let metadata = NarrationMetadata(
                                recipeId: recipeId,
                                voiceId: newVoiceId,
                                audioURL: audioUrl,
                                duration: TimeInterval(narrationData.durationMs ?? 0) / 1000.0,
                                stepTimestamps: [],
                                generatedAt: Date()
                            )
                            await send(.narrationReady(metadata))
                        } catch {
                            await send(.narrationFailed(error.localizedDescription))
                        }
                    }

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
                Logger.voicePlayback.warning("Caching failed (non-critical): \(errorMessage, privacy: .public)")
                return .none

            case .checkSubscriptionStatus:
                return .run { send in
                    let status = await subscriptionClient.currentEntitlement()
                    await send(.subscriptionStatusUpdated(status))
                }

            case let .subscriptionStatusUpdated(status):
                state.subscriptionStatus = status
                return .none

            case .upgradeTapped:
                Logger.voicePlayback.debug("upgradeTapped: setting showPaywall=true")
                state.showPaywall = true
                state.showVoicePicker = false
                return .none

            case .showPaywall:
                state.showPaywall = true
                return .none

            case .dismissPaywall:
                state.showPaywall = false
                return .none

            case let .narrationAvailabilityChecked(hasNarration):
                state.hasNarration = hasNarration
                return .none

            case .retryNarration:
                // Re-fetch narration with current voice and recipe
                guard let voiceId = state.selectedVoiceId,
                      let recipeId = state.pendingRecipeId ?? state.currentPlayback?.recipeId else {
                    return .none
                }
                if state.isAVSpeechActive || voiceId == "kindred-default" {
                    return .send(.selectVoice("kindred-default"))
                }
                return .send(.selectVoice(voiceId))

            case let .avSpeechStepChanged(stepIndex):
                guard let currentPlayback = state.currentPlayback else { return .none }
                state.currentPlayback = CurrentPlayback(
                    recipeId: currentPlayback.recipeId,
                    recipeName: currentPlayback.recipeName,
                    voiceId: currentPlayback.voiceId,
                    speakerName: currentPlayback.speakerName,
                    artworkURL: currentPlayback.artworkURL,
                    duration: currentPlayback.duration,
                    currentTime: currentPlayback.currentTime,
                    speed: currentPlayback.speed,
                    status: currentPlayback.status,
                    currentStepIndex: stepIndex
                )
                return .none

            case .showVoicePickerForNewPlayback:
                state.showVoicePicker = true
                state.isLoadingNarration = false
                return .none

            case .offlineFallbackToKindredVoice:
                state.offlineFallbackNote = "Using Kindred Voice — no internet connection"
                return .send(.selectVoice("kindred-default"))

            case let .jumpToStepRequested(stepIndex):
                guard state.isAVSpeechActive else { return .none }
                state.currentPlayback = state.currentPlayback.map { playback in
                    CurrentPlayback(
                        recipeId: playback.recipeId,
                        recipeName: playback.recipeName,
                        voiceId: playback.voiceId,
                        speakerName: playback.speakerName,
                        artworkURL: playback.artworkURL,
                        duration: playback.duration,
                        currentTime: playback.currentTime,
                        speed: playback.speed,
                        status: playback.status,
                        currentStepIndex: stepIndex
                    )
                }
                return .run { _ in
                    await avSpeechClient.jumpToStep(stepIndex)
                }
            }
        }
        .onChange(of: \.currentPlayback) { oldValue, newValue in
            Reduce { state, _ in
                let isAVSpeechActive = state.isAVSpeechActive
                return .run { [nowPlayingManager] _ in
                    await MainActor.run {
                        PlaybackObserver.shared.currentPlayback = newValue
                    }
                    // Update Now Playing info for lock screen
                    if let playback = newValue {
                        let rate: Double
                        switch playback.status {
                        case .playing: rate = Double(playback.speed.rawValue)
                        default: rate = 0.0
                        }
                        nowPlayingManager.updateNowPlaying(
                            title: playback.recipeName,
                            artist: playback.speakerName,
                            artworkURL: isAVSpeechActive ? nil : playback.artworkURL,
                            duration: playback.duration > 0 ? playback.duration : 1,
                            elapsedTime: playback.currentTime,
                            rate: rate
                        )
                    } else {
                        nowPlayingManager.cleanup()
                    }
                }
            }
        }
        .ifLet(\.voiceUpload, action: \.voiceUpload) {
            VoiceUploadReducer()
        }
    }
}
