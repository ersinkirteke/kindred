import ComposableArchitecture
import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

// MARK: - VoiceUploadView

public struct VoiceUploadView: View {
    @Bindable var store: StoreOf<VoiceUploadReducer>

    public init(store: StoreOf<VoiceUploadReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            if store.uploadComplete {
                successView
            } else {
                uploadFormView
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { store.showFilePicker },
                set: { newValue in
                    if !newValue {
                        store.send(.filePickerDismissed)
                    }
                }
            ),
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let url = urls.first {
                    store.send(.fileSelected(url))
                }
            case let .failure(error):
                store.send(.uploadFailed(error.localizedDescription))
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showConsentModal },
            set: { _ in store.send(.consentDeclined) }
        )) {
            VoiceConsentView(
                onAccept: { store.send(.consentAccepted) },
                onDecline: { store.send(.consentDeclined) }
            )
        }
    }

    // MARK: - Upload Form View

    private var uploadFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Create Voice Profile", bundle: .main))
                        .font(.kindredHeading2())
                        .foregroundStyle(.kindredTextPrimary)

                    Text(String(localized: "Upload a 30-60 second voice clip", bundle: .main))
                        .font(.kindredBody())
                        .foregroundStyle(.kindredTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)

                // File selection area
                fileSelectionArea
                    .padding(.horizontal, 16)

                // Duration validation
                if store.fileDuration != nil {
                    durationValidationView
                        .padding(.horizontal, 16)
                }

                // Voice name input
                nameInputField
                    .padding(.horizontal, 16)

                // Error message
                if let error = store.error {
                    errorView(error)
                        .padding(.horizontal, 16)
                }

                // Upload button
                uploadButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - File Selection Area

    private var fileSelectionArea: some View {
        Button {
            // If no file selected yet, show consent first
            // If file already selected, allow direct file change (consent already given for this session)
            if store.fileName == nil {
                store.send(.uploadVoiceTapped)
            } else {
                store.send(.selectFile)
            }
        } label: {
            VStack(spacing: 16) {
                if let fileName = store.fileName, let duration = store.fileDuration {
                    // File selected state
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.kindredAccent)

                        Text(fileName)
                            .font(.kindredBodyBold())
                            .foregroundStyle(.kindredTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(formatDuration(duration))
                            .font(.kindredBody())
                            .foregroundStyle(.kindredTextSecondary)

                        Text(String(localized: "Tap to change file", bundle: .main))
                            .font(.kindredCaption())
                            .foregroundStyle(.kindredAccent)
                    }
                    .padding(24)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.kindredTextSecondary)

                        Text(String(localized: "Select Audio File", bundle: .main))
                            .font(.kindredBodyBold())
                            .foregroundStyle(.kindredAccent)

                        Text(String(localized: ".mp3, .m4a, .wav, .aac", bundle: .main))
                            .font(.kindredCaption())
                            .foregroundStyle(.kindredTextSecondary)
                    }
                    .padding(32)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .foregroundStyle(.kindredDivider)
            )
        }
        .accessibilityLabel(String(localized: "accessibility.voice_upload.select_file_label", bundle: .main))
        .accessibilityHint(store.fileName == nil ? String(localized: "accessibility.voice_upload.select_file_hint", bundle: .main) : String(localized: "accessibility.voice_upload.change_file_hint", bundle: .main))
    }

    // MARK: - Duration Validation View

    private var durationValidationView: some View {
        HStack(spacing: 12) {
            if let duration = store.fileDuration {
                let isValid = duration >= 30 && duration <= 60

                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isValid ? .green : .kindredError)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isValid ? String(localized: "Duration Valid", bundle: .main) : String(localized: "Invalid Duration", bundle: .main))
                        .font(.kindredBodyBold())
                        .foregroundStyle(.kindredTextPrimary)

                    Text(isValid ? String(localized: "Perfect length for voice cloning", bundle: .main) : String(localized: "Must be 30-60 seconds", bundle: .main))
                        .font(.kindredBody())
                        .foregroundStyle(.kindredTextSecondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.kindredCardSurface)
        )
        .accessibilityLabel(durationAccessibilityLabel)
    }

    private var durationAccessibilityLabel: String {
        guard let duration = store.fileDuration else { return "" }
        let isValid = duration >= 30 && duration <= 60
        return String(localized: "Duration: \(Int(duration)) seconds, \(isValid ? "valid" : "invalid - must be 30 to 60 seconds")")
    }

    // MARK: - Name Input Field

    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Voice Profile Name", bundle: .main))
                .font(.kindredBodyBold())
                .foregroundStyle(.kindredTextPrimary)

            TextField(String(localized: "e.g., My Voice, Mom, Dad", bundle: .main), text: Binding(
                get: { store.voiceName },
                set: { store.send(.voiceNameChanged($0)) }
            ))
                .font(.kindredBody())
                .foregroundStyle(.kindredTextPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.kindredCardSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.kindredDivider, lineWidth: 1)
                )
                .accessibilityLabel(String(localized: "Voice profile name", bundle: .main))
                .accessibilityHint(String(localized: "accessibility.voice_upload.name_hint", bundle: .main))
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.kindredError)

            Text(message)
                .font(.kindredBody())
                .foregroundStyle(.kindredError)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.kindredError.opacity(0.1))
        )
    }

    // MARK: - Upload Button

    private var uploadButton: some View {
        Button {
            store.send(.upload)
        } label: {
            HStack(spacing: 8) {
                if store.isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text(String(localized: "Uploading...", bundle: .main))
                        .font(.kindredBodyBold())
                        .foregroundStyle(.white)
                } else {
                    Text(String(localized: "Upload Voice Clip", bundle: .main))
                        .font(.kindredBodyBold())
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(store.isValid && !store.isUploading ? Color.kindredAccent : Color.kindredDivider)
            )
        }
        .disabled(!store.isValid || store.isUploading)
        .accessibilityLabel(String(localized: "Upload voice clip", bundle: .main))
        .accessibilityHint(String(localized: "accessibility.voice_upload.upload_hint", bundle: .main))
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.kindredAccent)

            VStack(spacing: 8) {
                Text(String(localized: "Voice Profile Created!", bundle: .main))
                    .font(.kindredHeading2())
                    .foregroundStyle(.kindredTextPrimary)

                Text(String(localized: "Your voice is ready to use", bundle: .main))
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)
            }

            Spacer()

            Button {
                store.send(.dismiss)
            } label: {
                Text(String(localized: "Done", bundle: .main))
                    .font(.kindredBodyBold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.kindredAccent)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Upload Form") {
    VoiceUploadView(
        store: Store(
            initialState: VoiceUploadReducer.State()
        ) {
            VoiceUploadReducer()
        }
    )
}

#Preview("File Selected - Valid Duration") {
    VoiceUploadView(
        store: Store(
            initialState: VoiceUploadReducer.State(
                fileName: "my-voice-sample.m4a",
                fileDuration: 45.5,
                voiceName: "My Voice"
            )
        ) {
            VoiceUploadReducer()
        }
    )
}

#Preview("File Selected - Invalid Duration") {
    VoiceUploadView(
        store: Store(
            initialState: VoiceUploadReducer.State(
                fileName: "short-clip.m4a",
                fileDuration: 15.0,
                voiceName: "My Voice",
                error: "Voice clip must be 30-60 seconds (current: 15s)"
            )
        ) {
            VoiceUploadReducer()
        }
    )
}

#Preview("Uploading") {
    VoiceUploadView(
        store: Store(
            initialState: VoiceUploadReducer.State(
                fileName: "my-voice-sample.m4a",
                fileDuration: 45.5,
                voiceName: "My Voice",
                isUploading: true,
                uploadProgress: 0.6
            )
        ) {
            VoiceUploadReducer()
        }
    )
}

#Preview("Success") {
    VoiceUploadView(
        store: Store(
            initialState: VoiceUploadReducer.State(
                uploadComplete: true
            )
        ) {
            VoiceUploadReducer()
        }
    )
}
