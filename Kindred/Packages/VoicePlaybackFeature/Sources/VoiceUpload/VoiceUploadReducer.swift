import AVFoundation
import AuthClient
import ComposableArchitecture
import Dependencies
import Foundation
import NetworkClient

// MARK: - VoiceUploadReducer

@Reducer
public struct VoiceUploadReducer {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var selectedFileURL: URL?
        public var fileName: String?
        public var fileDuration: TimeInterval?
        public var voiceName: String = ""
        public var isUploading: Bool = false
        public var uploadProgress: Double = 0
        public var error: String?
        public var uploadComplete: Bool = false
        public var showFilePicker: Bool = false
        public var showConsentModal: Bool = false
        public var consentGiven: Bool = false

        public var isValid: Bool {
            guard let duration = fileDuration else { return false }
            let isDurationValid = duration >= 30 && duration <= 60
            let hasName = !voiceName.trimmingCharacters(in: .whitespaces).isEmpty
            return selectedFileURL != nil && isDurationValid && hasName
        }

        public init(
            selectedFileURL: URL? = nil,
            fileName: String? = nil,
            fileDuration: TimeInterval? = nil,
            voiceName: String = "",
            isUploading: Bool = false,
            uploadProgress: Double = 0,
            error: String? = nil,
            uploadComplete: Bool = false,
            showFilePicker: Bool = false,
            showConsentModal: Bool = false,
            consentGiven: Bool = false
        ) {
            self.selectedFileURL = selectedFileURL
            self.fileName = fileName
            self.fileDuration = fileDuration
            self.voiceName = voiceName
            self.isUploading = isUploading
            self.uploadProgress = uploadProgress
            self.error = error
            self.uploadComplete = uploadComplete
            self.showFilePicker = showFilePicker
            self.showConsentModal = showConsentModal
            self.consentGiven = consentGiven
        }
    }

    // MARK: - Action

    public enum Action: Equatable {
        case uploadVoiceTapped
        case consentAccepted
        case consentDeclined
        case selectFile
        case fileSelected(URL)
        case fileDurationLoaded(TimeInterval)
        case voiceNameChanged(String)
        case upload
        case uploadProgress(Double)
        case uploadCompleted(VoiceProfile)
        case uploadFailed(String)
        case filePickerDismissed
        case dismiss
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .uploadVoiceTapped:
                state.showConsentModal = true
                return .none

            case .consentAccepted:
                state.showConsentModal = false
                state.consentGiven = true
                state.showFilePicker = true
                return .none

            case .consentDeclined:
                state.showConsentModal = false
                return .none

            case .selectFile:
                state.showFilePicker = true
                state.error = nil
                return .none

            case .filePickerDismissed:
                state.showFilePicker = false
                return .none

            case let .fileSelected(url):
                state.showFilePicker = false
                state.selectedFileURL = url
                state.fileName = url.lastPathComponent
                state.fileDuration = nil
                state.error = nil

                // Load duration asynchronously
                return .run { send in
                    let duration = await loadAudioDuration(from: url)
                    await send(.fileDurationLoaded(duration))
                }

            case let .fileDurationLoaded(duration):
                state.fileDuration = duration

                // Validate duration (30-60 seconds)
                if duration < 30 || duration > 60 {
                    state.error = "Voice clip must be 30-60 seconds (current: \(Int(duration))s)"
                }

                return .none

            case let .voiceNameChanged(name):
                state.voiceName = name
                return .none

            case .upload:
                guard state.isValid else { return .none }
                guard let fileURL = state.selectedFileURL else { return .none }

                state.isUploading = true
                state.uploadProgress = 0
                state.error = nil

                // Upload to backend
                return .run { [voiceName = state.voiceName, consentGiven = state.consentGiven] send in
                    do {
                        // Get auth token
                        let authClient = await ClerkAuthClient()
                        guard let token = await authClient.getToken() else {
                            await send(.uploadFailed("Please sign in to upload a voice clip"))
                            return
                        }

                        // Security-scoped URL from file picker — must request access
                        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                        defer {
                            if didStartAccessing {
                                fileURL.stopAccessingSecurityScopedResource()
                            }
                        }

                        // Read file data
                        let data = try Data(contentsOf: fileURL)

                        // Create multipart form data
                        let boundary = UUID().uuidString
                        var body = Data()

                        // speakerName field (backend expects "speakerName")
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"speakerName\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(voiceName)\r\n".data(using: .utf8)!)

                        // relationship field (required by backend)
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"relationship\"\r\n\r\n".data(using: .utf8)!)
                        body.append("Family\r\n".data(using: .utf8)!)

                        // consentGiven field (required by backend)
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"consentGiven\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(consentGiven)\r\n".data(using: .utf8)!)

                        // appVersion field for consent audit trail (PRIV-05)
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"appVersion\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(appVersion)\r\n".data(using: .utf8)!)

                        // Audio file field (backend expects field name "audio")
                        body.append("--\(boundary)\r\n".data(using: .utf8)!)
                        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
                        body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
                        body.append(data)
                        body.append("\r\n".data(using: .utf8)!)
                        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

                        // Create request — backend route is POST /voice/upload
                        guard let url = URL(string: "\(APIEnvironment.baseURL)/voice/upload") else {
                            await send(.uploadFailed("Invalid API URL"))
                            return
                        }

                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        request.httpBody = body

                        // Perform upload
                        let (responseData, response) = try await URLSession.shared.data(for: request)

                        guard let httpResponse = response as? HTTPURLResponse else {
                            await send(.uploadFailed("Invalid response"))
                            return
                        }

                        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                            await send(.uploadFailed("Upload failed with status \(httpResponse.statusCode)"))
                            return
                        }

                        // Parse response
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601

                        let uploadResponse = try decoder.decode(VoiceProfileUploadResponse.self, from: responseData)

                        // Create VoiceProfile from response
                        let profile = VoiceProfile(
                            id: uploadResponse.id,
                            name: uploadResponse.speakerName,
                            avatarURL: nil,
                            sampleAudioURL: uploadResponse.audioSampleUrl,
                            isOwnVoice: true,
                            createdAt: uploadResponse.createdAt
                        )

                        await send(.uploadCompleted(profile))
                    } catch {
                        await send(.uploadFailed(error.localizedDescription))
                    }
                }

            case let .uploadProgress(progress):
                state.uploadProgress = progress
                return .none

            case .uploadCompleted:
                state.isUploading = false
                state.uploadComplete = true
                state.uploadProgress = 1.0
                return .none

            case let .uploadFailed(errorMessage):
                state.isUploading = false
                state.error = errorMessage
                return .none

            case .dismiss:
                return .none
            }
        }
    }

    // MARK: - Private Helpers

    private func loadAudioDuration(from url: URL) async -> TimeInterval {
        // File picker returns security-scoped URLs — must request access before reading
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let asset = AVAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return 0
        }
    }
}

// MARK: - VoiceProfileUploadResponse

private struct VoiceProfileUploadResponse: Decodable {
    let id: String
    let speakerName: String
    let audioSampleUrl: String?
    let status: String
    let createdAt: Date
}
