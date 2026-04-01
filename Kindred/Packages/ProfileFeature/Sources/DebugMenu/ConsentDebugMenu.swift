#if DEBUG
import SwiftUI
import DesignSystem

struct ConsentDebugMenu: View {
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: KindredSpacing.md) {
            Text("Debug: Consent")
                .font(.kindredHeading2Scaled(size: 20))
                .foregroundColor(.kindredTextPrimary)
                .padding(.top, KindredSpacing.lg)

            Divider()

            VStack(alignment: .leading, spacing: KindredSpacing.lg) {
                // Reset button
                Button {
                    UserDefaults.standard.removeObject(forKey: "hasSeenATTPrePrompt")
                    showConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Consent Pre-Prompt")
                            .font(.kindredBodyScaled(size: 16))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KindredSpacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Instructions
                Text("Resets the pre-prompt flag so the ATT consent flow shows again on next launch.\n\nATT permission itself must be reset via:\nSettings > General > Transfer or Reset iPhone > Reset Location & Privacy")
                    .font(.kindredCaptionScaled(size: 12))
                    .foregroundColor(.kindredTextSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.horizontal, KindredSpacing.lg)
        }
        .padding(.vertical, KindredSpacing.lg)
        .alert("Consent Reset", isPresented: $showConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Pre-prompt flag cleared. Restart app to see consent flow.")
        }
    }
}

#Preview {
    ConsentDebugMenu()
}
#endif
