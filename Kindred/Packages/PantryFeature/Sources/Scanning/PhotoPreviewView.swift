import ComposableArchitecture
import DesignSystem
import SwiftUI
import UIKit

/// Full-screen photo preview with Use/Retake actions after capture
struct PhotoPreviewView: View {
    let store: StoreOf<CameraReducer>
    let image: UIImage

    var body: some View {
        ZStack {
            // Full-screen captured image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .accessibilityLabel(String(localized: "camera.preview.captured_photo", defaultValue: "Captured photo", bundle: .main))

            // Bottom gradient with action buttons
            VStack {
                Spacer()

                HStack(spacing: 16) {
                    // Retake button (secondary)
                    Button {
                        store.send(.retakeTapped)
                    } label: {
                        Text(String(localized: "camera.preview.retake", defaultValue: "Retake", bundle: .main))
                            .font(.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel(String(localized: "camera.preview.retake", defaultValue: "Retake", bundle: .main))
                    .accessibilityHint(String(localized: "camera.preview.retake.hint", defaultValue: "Return to camera to take another photo", bundle: .main))

                    // Use photo button (primary)
                    Button {
                        store.send(.usePhotoTapped)
                    } label: {
                        Text(String(localized: "camera.preview.use", defaultValue: "Use photo", bundle: .main))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(String(localized: "camera.preview.use", defaultValue: "Use photo", bundle: .main))
                    .accessibilityHint(String(localized: "camera.preview.use.hint", defaultValue: "Proceed with this photo", bundle: .main))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .ignoresSafeArea(),
                alignment: .bottom
            )
        }
        .alert(
            String(localized: "camera.blur.title", defaultValue: "Photo may be blurry", bundle: .main),
            isPresented: Binding(
                get: { store.showBlurWarning },
                set: { if !$0 { store.send(.blurWarningDismissed) } }
            )
        ) {
            Button(String(localized: "camera.blur.use_anyway", defaultValue: "Use anyway", bundle: .main)) {
                store.send(.blurWarningDismissed)
            }
            Button(String(localized: "camera.blur.retake", defaultValue: "Retake", bundle: .main), role: .cancel) {
                store.send(.blurWarningRetake)
            }
        }
    }
}
