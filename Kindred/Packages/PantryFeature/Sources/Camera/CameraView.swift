import AVFoundation
import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIKit

/// Full-screen camera UI with viewfinder, controls, and capture flow
public struct CameraView: View {
    let store: StoreOf<CameraReducer>
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(store: StoreOf<CameraReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            if store.showPhotoPreview, let image = store.capturedImage {
                // Photo preview after capture
                PhotoPreviewView(store: store, image: image)
            } else {
                // Camera viewfinder
                cameraViewfinder
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: Binding(
            get: { store.showClassification },
            set: { if !$0 { store.send(.classificationDismissed) } }
        )) {
            ScanClassificationView(store: store)
        }
        .onAppear {
            store.send(.onAppear)
            setupCamera()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }

    @ViewBuilder
    private var cameraViewfinder: some View {
        ZStack {
            // Edge-to-edge camera preview
            CameraViewfinderView(session: cameraManager.session)
                .ignoresSafeArea()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value.magnitude
                            let newZoom = store.zoomFactor * delta
                            cameraManager.setZoom(newZoom)
                            store.send(.zoomChanged(newZoom))
                        }
                )

            // Top gradient overlay with controls
            VStack {
                topControls
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .frame(height: 120)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.black.opacity(0.3), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Spacer()

                // Bottom gradient with capture button
                bottomControls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .frame(height: 160)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }

    @ViewBuilder
    private var topControls: some View {
        HStack {
            // Close button
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.3), in: Circle())
                    .shadow(radius: 4)
            }
            .accessibilityLabel(String(localized: "camera.close", defaultValue: "Close camera", bundle: .main))

            Spacer()

            // Hint text (center)
            if store.showHint {
                Text(String(localized: "camera.hint", defaultValue: "Take a clear photo", bundle: .main))
                    .font(.caption)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .transition(.opacity)
            }

            Spacer()

            // Flash toggle button
            Button {
                store.send(.toggleFlash)
                cameraManager.toggleFlash()
            } label: {
                Image(systemName: store.flashMode.iconName)
                    .font(.body)
                    .foregroundStyle(store.flashMode == .on ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.3), in: Circle())
                    .shadow(radius: 4)
            }
            .accessibilityLabel(store.flashMode.accessibilityLabel)
        }
    }

    @ViewBuilder
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Low light banner
            if store.isLowLight {
                Text(String(localized: "camera.low_light", defaultValue: "Low light detected — try turning on flash", bundle: .main))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.5), in: Capsule())
                    .shadow(radius: 4)
            }

            // Capture button
            Button {
                handleCaptureButtonTapped()
            } label: {
                ZStack {
                    // Outer circle
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 72, height: 72)

                    // Inner circle
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .scaleEffect(store.isCapturing ? 0.9 : 1.0)
                }
            }
            .disabled(store.isCapturing)
            .accessibilityLabel(String(localized: "camera.capture", defaultValue: "Take photo", bundle: .main))
            .accessibilityHint(String(localized: "camera.capture.hint", defaultValue: "Double tap to capture photo", bundle: .main))

            // Error message
            if let error = store.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.7), in: Capsule())
                    .shadow(radius: 4)
            }
        }
    }

    private func setupCamera() {
        Task {
            do {
                try await cameraManager.setup()
                cameraManager.start()
            } catch {
                store.send(.captureFailed(error.localizedDescription))
            }
        }
    }

    private func handleCaptureButtonTapped() {
        store.send(.captureButtonTapped)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Capture photo
        Task {
            do {
                let image = try await cameraManager.capturePhoto()
                await MainActor.run {
                    store.send(.photoCaptured(image))
                    // VoiceOver announcement
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: String(localized: "camera.captured", defaultValue: "Photo captured", bundle: .main)
                    )
                }
            } catch {
                await MainActor.run {
                    store.send(.captureFailed(error.localizedDescription))
                }
            }
        }
    }
}
