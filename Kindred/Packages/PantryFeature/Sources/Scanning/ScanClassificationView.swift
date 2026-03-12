import ComposableArchitecture
import DesignSystem
import SwiftUI

/// Bottom sheet for selecting scan type (fridge or receipt)
struct ScanClassificationView: View {
    let store: StoreOf<CameraReducer>

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text(String(localized: "camera.classification.title", defaultValue: "What did you scan?", bundle: .main))
                    .font(.title2.weight(.semibold))
                    .padding(.top, 8)

                // Scan type cards
                VStack(spacing: 16) {
                    // Fridge scan card
                    Button {
                        store.send(.scanTypeSelected(.fridge))
                    } label: {
                        ScanTypeCard(
                            iconName: ScanType.fridge.iconName,
                            title: String(localized: "camera.scan.fridge", defaultValue: "Fridge Scan", bundle: .main),
                            description: String(localized: "camera.scan.fridge.description", defaultValue: "Scan ingredients from your fridge", bundle: .main)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "camera.scan.fridge", defaultValue: "Fridge Scan", bundle: .main))

                    // Receipt scan card
                    Button {
                        store.send(.scanTypeSelected(.receipt))
                    } label: {
                        ScanTypeCard(
                            iconName: ScanType.receipt.iconName,
                            title: String(localized: "camera.scan.receipt", defaultValue: "Receipt Scan", bundle: .main),
                            description: String(localized: "camera.scan.receipt.description", defaultValue: "Scan items from a receipt", bundle: .main)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "camera.scan.receipt", defaultValue: "Receipt Scan", bundle: .main))
                }
                .padding(.horizontal, 20)

                // Retake link
                Button {
                    store.send(.retakeTapped)
                } label: {
                    Text(String(localized: "camera.scan.retake", defaultValue: "Retake", bundle: .main))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.vertical, 20)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

/// Card for a single scan type option
private struct ScanTypeCard: View {
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
