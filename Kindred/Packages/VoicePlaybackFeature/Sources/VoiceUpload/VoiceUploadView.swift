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
                set: { _ in }
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
    }

    // MARK: - Upload Form View

    private var uploadFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Voice Profile")
                        .font(.kindredHeading2())
                        .foregroundColor(.kindredTextPrimary)

                    Text("Upload a 30-60 second voice clip")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
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
            store.send(.selectFile)
        } label: {
            VStack(spacing: 16) {
                if let fileName = store.fileName, let duration = store.fileDuration {
                    // File selected state
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.kindredAccent)

                        Text(fileName)
                            .font(.kindredBodyBold())
                            .foregroundColor(.kindredTextPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(formatDuration(duration))
                            .font(.kindredBody())
                            .foregroundColor(.kindredTextSecondary)

                        Text("Tap to change file")
                            .font(.kindredCaption())
                            .foregroundColor(.kindredAccent)
                    }
                    .padding(24)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.kindredTextSecondary)

                        Text("Select Audio File")
                            .font(.kindredBodyBold())
                            .foregroundColor(.kindredAccent)

                        Text(".mp3, .m4a, .wav, .aac")
                            .font(.kindredCaption())
                            .foregroundColor(.kindredTextSecondary)
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
                    .foregroundColor(.kindredDivider)
            )
        }
        .accessibilityLabel("Select audio file for voice profile")
        .accessibilityHint(store.fileName == nil ? "Double tap to choose an audio file" : "Double tap to change the selected audio file")
    }

    // MARK: - Duration Validation View

    private var durationValidationView: some View {
        HStack(spacing: 12) {
            if let duration = store.fileDuration {
                let isValid = duration >= 30 && duration <= 60

                Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isValid ? .green : .kindredError)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isValid ? "Duration Valid" : "Invalid Duration")
                        .font(.kindredBodyBold())
                        .foregroundColor(.kindredTextPrimary)

                    Text(isValid ? "Perfect length for voice cloning" : "Must be 30-60 seconds")
                        .font(.kindredBody())
                        .foregroundColor(.kindredTextSecondary)
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
        return "Duration: \(Int(duration)) seconds, \(isValid ? "valid" : "invalid - must be 30 to 60 seconds")"
    }

    // MARK: - Name Input Field

    private var nameInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voice Profile Name")
                .font(.kindredBodyBold())
                .foregroundColor(.kindredTextPrimary)

            TextField("e.g., My Voice, Mom, Dad", text: Binding(
                get: { store.voiceName },
                set: { store.send(.voiceNameChanged($0)) }
            ))
                .font(.kindredBody())
                .foregroundColor(.kindredTextPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.kindredCardSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.kindredDivider, lineWidth: 1)
                )
                .accessibilityLabel("Voice profile name")
                .accessibilityHint("Enter a name to identify this voice")
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.kindredError)

            Text(message)
                .font(.kindredBody())
                .foregroundColor(.kindredError)

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

                    Text("Uploading...")
                        .font(.kindredBodyBold())
                        .foregroundColor(.white)
                } else {
                    Text("Upload Voice Clip")
                        .font(.kindredBodyBold())
                        .foregroundColor(.white)
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
        .accessibilityLabel("Upload voice clip")
        .accessibilityHint("Creates a voice profile from your audio clip")
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.kindredAccent)

            VStack(spacing: 8) {
                Text("Voice Profile Created!")
                    .font(.kindredHeading2())
                    .foregroundColor(.kindredTextPrimary)

                Text("Your voice is ready to use")
                    .font(.kindredBody())
                    .foregroundColor(.kindredTextSecondary)
            }

            Spacer()

            Button {
                store.send(.dismiss)
            } label: {
                Text("Done")
                    .font(.kindredBodyBold())
                    .foregroundColor(.white)
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
