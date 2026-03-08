import SwiftUI
import DesignSystem

public struct SubscriptionStatusView: View {
    let subscriptionStatus: SubscriptionStatus
    let displayPrice: String
    let onSubscribe: () -> Void
    let onManage: () -> Void

    public init(
        subscriptionStatus: SubscriptionStatus,
        displayPrice: String,
        onSubscribe: @escaping () -> Void,
        onManage: @escaping () -> Void
    ) {
        self.subscriptionStatus = subscriptionStatus
        self.displayPrice = displayPrice
        self.onSubscribe = onSubscribe
        self.onManage = onManage
    }

    public var body: some View {
        CardSurface {
            switch subscriptionStatus {
            case .unknown:
                LoadingStateView()

            case .free:
                FreeStateView(displayPrice: displayPrice, onSubscribe: onSubscribe)

            case .pro(let expiresDate, let isInGracePeriod):
                ProStateView(
                    expiresDate: expiresDate,
                    isInGracePeriod: isInGracePeriod,
                    onManage: onManage
                )
            }
        }
    }
}

// MARK: - Loading State

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: KindredSpacing.md) {
            ProgressView()
            Text(String(localized: "subscription.loading_status"))
                .kindredBody()
                .foregroundColor(.kindredTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(KindredSpacing.lg)
    }
}

// MARK: - Free State

private struct FreeStateView: View {
    let displayPrice: String
    let onSubscribe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            Text(String(localized: "subscription.unlock_pro"))
                .kindredHeading2()
                .foregroundColor(.kindredTextPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                BenefitItem(text: String(localized: "subscription.benefit_adfree"))
                BenefitItem(text: String(localized: "subscription.benefit_voice"))
            }

            KindredButton(String(localized: "subscription.subscribe_button \(displayPrice)"), style: .primary) {
                onSubscribe()
            }
            .accessibilityLabel(String(localized: "accessibility.subscription.subscribe \(displayPrice)"))
            .accessibilityHint(String(localized: "accessibility.subscription.subscribe_hint"))
        }
        .padding(KindredSpacing.lg)
    }
}

// MARK: - Pro State

private struct ProStateView: View {
    let expiresDate: Date
    let isInGracePeriod: Bool
    let onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            // Header with badge
            HStack {
                Text(String(localized: "subscription.kindred_pro"))
                    .kindredHeading2()
                    .foregroundColor(.kindredTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // PRO badge
                Text(String(localized: "subscription.pro_badge"))
                    .kindredCaption()
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, KindredSpacing.sm)
                    .padding(.vertical, KindredSpacing.xs)
                    .background(Color.kindredAccent)
                    .clipShape(Capsule())
                    .accessibilityLabel(String(localized: "accessibility.subscription.pro_badge"))
            }

            // Grace period warning
            if isInGracePeriod {
                HStack(spacing: KindredSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text(String(localized: "subscription.payment_issue"))
                        .kindredCaption()
                        .foregroundColor(.orange)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility.subscription.payment_warning"))
            }

            // Renewal date
            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text(String(localized: "subscription.renews_on"))
                    .kindredCaption()
                    .foregroundColor(.kindredTextSecondary)

                Text(expiresDate, style: .date)
                    .kindredBody()
                    .foregroundColor(.kindredTextPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "accessibility.subscription.renews_on \(expiresDate.formatted(date: .long, time: .omitted))"))

            // Manage subscription button
            Button {
                onManage()
            } label: {
                Text(String(localized: "subscription.manage_button"))
                    .kindredBody()
                    .foregroundColor(.kindredAccent)
            }
            .accessibilityLabel(String(localized: "accessibility.subscription.manage"))
            .accessibilityHint(String(localized: "accessibility.subscription.manage_hint"))
        }
        .padding(KindredSpacing.lg)
    }
}

// MARK: - Benefit Item

private struct BenefitItem: View {
    let text: String

    var body: some View {
        HStack(spacing: KindredSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.kindredAccent)
                .font(.system(size: 16))
                .accessibilityHidden(true)

            Text(text)
                .kindredBody()
                .foregroundColor(.kindredTextSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Manage Subscription Helper

extension SubscriptionStatusView {
    /// Opens the App Store subscription management page
    public static func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
    }
}
