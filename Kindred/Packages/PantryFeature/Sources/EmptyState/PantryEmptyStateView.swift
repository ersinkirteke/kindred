import DesignSystem
import SwiftUI

struct PantryEmptyStateView: View {
    let isGuest: Bool
    let onAddTapped: () -> Void
    let onSignInTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "refrigerator")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text(String(localized: "pantry.empty_title", bundle: .main))
                    .font(.title2)
                    .fontWeight(.semibold)

                if isGuest {
                    Text(String(localized: "pantry.empty_subtitle_guest", bundle: .main))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(String(localized: "pantry.empty_subtitle_auth", bundle: .main))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if isGuest {
                Button(action: onSignInTapped) {
                    Text(String(localized: "pantry.sign_in", bundle: .main))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .padding(.horizontal, 40)
            } else {
                Button(action: onAddTapped) {
                    Label(String(localized: "pantry.add_first_item", bundle: .main), systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .padding(.horizontal, 40)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
