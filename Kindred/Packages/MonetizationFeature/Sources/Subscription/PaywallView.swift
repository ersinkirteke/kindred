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
                Text(String(localized: "paywall.title", bundle: .main))
                    .font(.kindredHeading1Scaled(size: heading1Size))
                    .foregroundStyle(.kindredTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                // Benefits
                VStack(spacing: KindredSpacing.md) {
                    BenefitRow(
                        icon: "checkmark.seal.fill",
                        title: String(localized: "paywall.benefit_adfree_title", bundle: .main),
                        description: String(localized: "paywall.benefit_adfree_description", bundle: .main),
                        bodySize: bodySize
                    )

                    BenefitRow(
                        icon: "mic.badge.plus",
                        title: String(localized: "paywall.benefit_voice_title", bundle: .main),
                        description: String(localized: "paywall.benefit_voice_description", bundle: .main),
                        bodySize: bodySize
                    )
                }

                // Subscribe button area
                VStack(spacing: KindredSpacing.md) {
                    if store.isLoadingProducts {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text(String(localized: "paywall.loading", bundle: .main))
                                .font(.kindredBodyScaled(size: bodySize))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.kindredAccent.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 16))
                    } else if store.isPurchasing {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text(String(localized: "paywall.processing", bundle: .main))
                                .font(.kindredBodyScaled(size: bodySize))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.kindredAccent)
                        .clipShape(.rect(cornerRadius: 16))
                    } else {
                        KindredButton(
                            String(localized: "paywall.subscribe_button \(store.displayPrice)", bundle: .main),
                            style: .primary
                        ) {
                            store.send(.subscribeTapped)
                        }
                        .accessibilityLabel(String(localized: "accessibility.paywall.subscribe \(store.displayPrice)", bundle: .main))
                        .accessibilityHint(String(localized: "accessibility.paywall.subscribe_hint", bundle: .main))
                    }

                    // Restore purchases link
                    Button {
                        store.send(.restoreTapped)
                    } label: {
                        if store.isRestoring {
                            HStack(spacing: KindredSpacing.xs) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(String(localized: "paywall.restoring", bundle: .main))
                                    .font(.kindredCaptionScaled(size: captionSize))
                                    .foregroundStyle(.kindredAccent)
                            }
                        } else {
                            Text(String(localized: "paywall.restore_purchases", bundle: .main))
                                .font(.kindredCaptionScaled(size: captionSize))
                                .foregroundStyle(.kindredAccent)
                        }
                    }
                    .accessibilityLabel(String(localized: "accessibility.paywall.restore", bundle: .main))
                    .accessibilityHint(String(localized: "accessibility.paywall.restore_hint", bundle: .main))
                }

                // Error message
                if let error = store.error, !error.isEmpty {
                    Text(error)
                        .font(.kindredCaptionScaled(size: captionSize))
                        .foregroundStyle(.red)
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
        .accessibilityLabel(String(localized: "accessibility.paywall.label", bundle: .main))
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
                .foregroundStyle(.kindredAccent)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text(title)
                    .font(.kindredBodyBoldScaled(size: bodySize))
                    .foregroundStyle(.kindredTextPrimary)

                Text(description)
                    .font(.kindredBodyScaled(size: bodySize))
                    .foregroundStyle(.kindredTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}
