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
                Text("Your pantry is empty")
                    .font(.title2)
                    .fontWeight(.semibold)

                if isGuest {
                    Text("Sign in to start tracking your ingredients")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Add your first item or scan your fridge to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if isGuest {
                Button(action: onSignInTapped) {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .padding(.horizontal, 40)
            } else {
                Button(action: onAddTapped) {
                    Label("Add Your First Item", systemImage: "plus.circle.fill")
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
