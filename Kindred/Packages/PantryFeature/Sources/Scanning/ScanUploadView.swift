import ComposableArchitecture
import SwiftUI

public struct ScanUploadView: View {
    @Bindable var store: StoreOf<ScanUploadReducer>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(store: StoreOf<ScanUploadReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            // Background photo (dimmed during upload)
            Image(uiImage: store.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: uploadInProgress ? 8 : 0)
                .brightness(uploadInProgress ? -0.3 : 0)
                .animation(.easeInOut(duration: 0.3), value: uploadInProgress)

            // Upload overlay
            overlayContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
        }
        .onAppear {
            store.send(.startUpload)
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch store.uploadState {
        case .compressing:
            compressingView
        case .uploading:
            uploadingView
        case .processing:
            processingView
        case .completed:
            completedView
        case .failed:
            failedView
        }
    }

    // MARK: - Upload States

    private var compressingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)

            Text("scan.upload.preparing", bundle: .main, comment: "Preparing photo...")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "scan.upload.preparing", defaultValue: "Preparing photo", bundle: .main))
    }

    private var uploadingView: some View {
        VStack(spacing: 24) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: store.uploadProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: store.uploadProgress)

                Text("\(Int(store.uploadProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }

            Text("scan.upload.uploading", bundle: .main, comment: "Uploading...")
                .font(.headline)
                .foregroundStyle(.white)

            // Cancel button
            Button {
                store.send(.cancelUpload)
            } label: {
                Text("scan.upload.cancel", bundle: .main, comment: "Cancel")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .accessibilityLabel(String(localized: "scan.upload.cancel", defaultValue: "Cancel upload", bundle: .main))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "scan.upload.uploading", defaultValue: "Uploading", bundle: .main))
        .accessibilityValue("\(Int(store.uploadProgress * 100)) percent")
    }

    private var processingView: some View {
        VStack(spacing: 24) {
            // Animated scanning effect
            if reduceMotion {
                // Reduce Motion: static icon
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            } else {
                // Animated pulse effect
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                            .opacity(pulseAnimation ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.5),
                                value: pulseAnimation
                            )
                    }

                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                .onAppear {
                    pulseAnimation = true
                }
            }

            VStack(spacing: 8) {
                Text("scan.analysis.processing", bundle: .main, comment: "AI analyzing photo...")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("(this takes 5-10 seconds)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Animated dots (Reduce Motion: show spinner instead)
            if reduceMotion {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotAnimation ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: dotAnimation
                            )
                    }
                }
                .onAppear {
                    dotAnimation = true
                }
            }

            Spacer()
                .frame(height: 40)

            // Back to Pantry button
            Button {
                store.send(.backToPantryTapped)
            } label: {
                Text("scan.upload.back_to_pantry", bundle: .main, comment: "Back to Pantry")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .accessibilityLabel(String(localized: "scan.upload.back_to_pantry", defaultValue: "Back to Pantry", bundle: .main))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "scan.upload.analyzing", defaultValue: "Analyzing your photo", bundle: .main))
    }

    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("scan.upload.complete", bundle: .main, comment: "Upload complete")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "scan.upload.complete", defaultValue: "Upload complete", bundle: .main))
    }

    private var failedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            if let error = store.error {
                Text(error)
                    .font(.headline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("scan.upload.failed", bundle: .main, comment: "Upload failed")
                    .font(.headline)
                    .foregroundStyle(.red)
            }

            VStack(spacing: 16) {
                // Retry button
                Button {
                    store.send(.retryUpload)
                } label: {
                    Text("scan.upload.retry", bundle: .main, comment: "Retry")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .accessibilityLabel(String(localized: "scan.upload.retry", defaultValue: "Retry upload", bundle: .main))

                // Add items manually link (if error message indicates analysis failure)
                if let error = store.error, error.contains("identify items") {
                    Button {
                        store.send(.cancelUpload)
                        // TODO: Navigate to manual add form
                    } label: {
                        Text("scan.failure.add_manually", bundle: .main, comment: "Add items manually")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .underline()
                    }
                    .accessibilityLabel(String(localized: "scan.failure.add_manually", defaultValue: "Add items manually", bundle: .main))
                }

                // Cancel button
                Button {
                    store.send(.cancelUpload)
                } label: {
                    Text("scan.upload.cancel", bundle: .main, comment: "Cancel")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .accessibilityLabel(String(localized: "scan.upload.cancel", defaultValue: "Cancel", bundle: .main))
            }
        }
        .accessibilityElement(children: .contain)
    }

    // Offline queued banner
    @ViewBuilder
    private var offlineQueuedBanner: some View {
        if store.isOfflineQueued {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .font(.title3)
                        .foregroundStyle(.white)

                    Text("scan.upload.offline_queued", bundle: .main, comment: "Photo saved — will upload when back online")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                Spacer()
            }
        }
    }

    // MARK: - Helper Properties

    private var uploadInProgress: Bool {
        store.uploadState == .compressing || store.uploadState == .uploading
    }

    @State private var pulseAnimation = false
    @State private var dotAnimation = false
}
