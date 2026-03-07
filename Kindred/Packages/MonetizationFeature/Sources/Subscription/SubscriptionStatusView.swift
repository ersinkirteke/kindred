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
            Text("Loading subscription status...")
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
            Text("Unlock Kindred Pro")
                .kindredHeading2()
                .foregroundColor(.kindredTextPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                BenefitItem(text: "Ad-free cooking experience")
                BenefitItem(text: "Unlimited voice profiles")
            }

            KindredButton("Subscribe for \(displayPrice)/month", style: .primary) {
                onSubscribe()
            }
            .accessibilityLabel("Subscribe for \(displayPrice) per month")
            .accessibilityHint("Opens subscription purchase screen")
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
                Text("Kindred Pro")
                    .kindredHeading2()
                    .foregroundColor(.kindredTextPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // PRO badge
                Text("PRO")
                    .kindredCaption()
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, KindredSpacing.sm)
                    .padding(.vertical, KindredSpacing.xs)
                    .background(Color.kindredAccent)
                    .clipShape(Capsule())
                    .accessibilityLabel("Pro subscriber")
            }

            // Grace period warning
            if isInGracePeriod {
                HStack(spacing: KindredSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Text("Payment issue - updating billing info")
                        .kindredCaption()
                        .foregroundColor(.orange)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Warning: Payment issue, please update billing information")
            }

            // Renewal date
            VStack(alignment: .leading, spacing: KindredSpacing.xs) {
                Text("Renews on")
                    .kindredCaption()
                    .foregroundColor(.kindredTextSecondary)

                Text(expiresDate, style: .date)
                    .kindredBody()
                    .foregroundColor(.kindredTextPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Renews on \(expiresDate.formatted(date: .long, time: .omitted))")

            // Manage subscription button
            Button {
                onManage()
            } label: {
                Text("Manage Subscription")
                    .kindredBody()
                    .foregroundColor(.kindredAccent)
            }
            .accessibilityLabel("Manage subscription")
            .accessibilityHint("Opens App Store subscription management")
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
