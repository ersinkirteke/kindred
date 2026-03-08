import SwiftUI
import StoreKit
import ComposableArchitecture
import DesignSystem

public struct PaywallView: View {
    let store: StoreOf<SubscriptionReducer>

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .largeTitle) private var heading1Size: CGFloat = 34
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14

    public init(store: StoreOf<SubscriptionReducer>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: KindredSpacing.lg) {
            // Drag indicator
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, KindredSpacing.sm)

            VStack(spacing: KindredSpacing.xl) {
                // Heading
                Text("Upgrade to Pro")
                    .font(.kindredHeading1Scaled(size: heading1Size))
                    .foregroundColor(.kindredTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                // Benefits
                VStack(spacing: KindredSpacing.md) {
                    BenefitRow(
                        icon: "checkmark.seal.fill",
                        title: "Ad-Free Experience",
                        description: "No interruptions while cooking",
                        bodySize: bodySize
                    )

                    BenefitRow(
                        icon: "mic.badge.plus",
                        title: "Unlimited Voice Profiles",
                        description: "Clone any voice you love",
                        bodySize: bodySize
                    )
                }

                // Subscribe button area
                VStack(spacing: KindredSpacing.md) {
                    if store.isLoadingProducts {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Loading...")
                                .font(.kindredBodyScaled(size: bodySize))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.kindredAccent.opacity(0.5))
                        .cornerRadius(16)
                    } else if store.isPurchasing {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Processing...")
                                .font(.kindredBodyScaled(size: bodySize))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.kindredAccent)
                        .cornerRadius(16)
                    } else {
                        KindredButton(
                            "Subscribe for \(store.displayPrice)/month",
                            style: .primary
                        ) {
                            store.send(.subscribeTapped)
                        }
                        .accessibilityLabel("Subscribe for \(store.displayPrice) per month")
                        .accessibilityHint("Starts monthly subscription")
                    }

                    // Restore purchases link
                    Button {
                        store.send(.restoreTapped)
                    } label: {
                        if store.isRestoring {
                            HStack(spacing: KindredSpacing.xs) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Restoring...")
                                    .font(.kindredCaptionScaled(size: captionSize))
                                    .foregroundColor(.kindredAccent)
                            }
                        } else {
                            Text("Restore Purchases")
                                .font(.kindredCaptionScaled(size: captionSize))
                                .foregroundColor(.kindredAccent)
                        }
                    }
                    .accessibilityLabel("Restore purchases")
                    .accessibilityHint("Restore previous subscription purchases")
                }

                // Error message
                if let error = store.error, !error.isEmpty {
                    Text(error)
                        .font(.kindredCaptionScaled(size: captionSize))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KindredSpacing.md)
                        .accessibilityLabel("Error: \(error)")
                }
            }
            .padding(KindredSpacing.lg)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pro subscription upgrade")
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let bodySize: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: KindredSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.kindredAccent)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text(title)
                    .font(.kindredBodyBoldScaled(size: bodySize))
                    .foregroundColor(.kindredTextPrimary)

                Text(description)
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundColor(.kindredTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}
