import ComposableArchitecture
import DesignSystem
import GoogleMobileAds
import SwiftUI

/// Native ad card styled to match recipe cards
/// Wraps GADNativeAdView via UIViewRepresentable
public struct AdCardView: View {
    let onUpgradeTapped: () -> Void

    @State private var nativeAd: GADNativeAd?
    @State private var loadState: AdLoadState = .idle
    @State private var adLoader: GADAdLoader?
    @State private var adCoordinator: AdLoaderCoordinator?

    @Dependency(\.adClient) var adClient

    public init(onUpgradeTapped: @escaping () -> Void) {
        self.onUpgradeTapped = onUpgradeTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let ad = nativeAd, loadState == .loaded {
                // Ad loaded - show native ad content
                loadedAdContent(ad: ad)
            } else if isShowingProPromo {
                // No ad to show (e.g. no fill) - promote Pro instead of an empty card
                proPromoContent
            } else {
                // Loading - show placeholder
                loadingPlaceholder
            }
        }
        .background(Color.kindredCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.kindredTextSecondary.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        .frame(width: 340, height: 400)
        .padding(.horizontal, KindredSpacing.xl)
        .onAppear {
            if adClient.shouldShowAds() {
                loadAd()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isShowingProPromo
            ? String(localized: "accessibility.paywall.label", bundle: .main)
            : String(localized: "accessibility.ads.sponsored_content", bundle: .main))
    }

    private var isShowingProPromo: Bool {
        if case .failed = loadState { return true }
        return false
    }

    private var proPromoContent: some View {
        VStack(alignment: .leading, spacing: KindredSpacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28))
                .foregroundStyle(.kindredAccent)
                .frame(width: 56, height: 56)
                .background(Color.kindredAccent.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(String(localized: "paywall.title", bundle: .main))
                .font(.kindredHeading1())
                .foregroundStyle(.kindredTextPrimary)

            proBenefitRow(
                icon: "nosign",
                title: String(localized: "paywall.benefit_adfree_title", bundle: .main),
                detail: String(localized: "paywall.benefit_adfree_description", bundle: .main)
            )
            proBenefitRow(
                icon: "waveform",
                title: String(localized: "paywall.benefit_voice_title", bundle: .main),
                detail: String(localized: "paywall.benefit_voice_description", bundle: .main)
            )

            Spacer(minLength: 0)

            KindredButton(String(localized: "ads.remove_ads_pro", bundle: .main), action: onUpgradeTapped)
        }
        .padding(KindredSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func proBenefitRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: KindredSpacing.sm) {
            Image(systemName: icon)
                .font(.kindredBody())
                .foregroundStyle(.kindredAccent)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.kindredBodyBold())
                    .foregroundStyle(.kindredTextPrimary)
                Text(detail)
                    .font(.kindredCaption())
                    .foregroundStyle(.kindredTextSecondary)
            }
        }
    }

    @ViewBuilder
    private func loadedAdContent(ad: GADNativeAd) -> some View {
        // Media view (ad image) at top - 16:9 ratio
        Color.clear
            .frame(height: 280)
            .overlay {
                NativeAdMediaView(ad: ad)
            }
            .clipped()
            .overlay(alignment: .topTrailing) {
                // "Sponsored" label
                Text(String(localized: "ads.sponsored", bundle: .main))
                    .font(.kindredCaption())
                    .foregroundStyle(.kindredTextSecondary)
                    .padding(.horizontal, KindredSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.kindredCardSurface.opacity(0.9))
                    .clipShape(.rect(cornerRadius: 8))
                    .padding(KindredSpacing.md)
            }

        // Ad details with padding
        VStack(alignment: .leading, spacing: KindredSpacing.sm) {
            // Headline
            if let headline = ad.headline {
                Text(headline)
                    .font(.kindredHeading2())
                    .foregroundStyle(.kindredTextPrimary)
                    .lineLimit(2)
            }

            // Body text
            if let body = ad.body {
                Text(body)
                    .font(.kindredBody())
                    .foregroundStyle(.kindredTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // "Remove ads with Pro" upsell link
            Button(action: onUpgradeTapped) {
                Text(String(localized: "ads.remove_ads_pro", bundle: .main))
                    .font(.kindredCaption())
                    .foregroundStyle(.kindredAccent)
                    .underline()
            }
            .accessibilityLabel(String(localized: "accessibility.ads.remove_ads", bundle: .main))
        }
        .padding(KindredSpacing.md)
        .frame(height: 120, alignment: .top)
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Placeholder media area
            Rectangle()
                .fill(Color.kindredDivider.opacity(0.3))
                .frame(height: 280)
                .overlay {
                    if loadState == .loading {
                        ProgressView()
                            .tint(.kindredTextSecondary)
                    }
                }

            // Placeholder text area
            VStack(alignment: .leading, spacing: KindredSpacing.sm) {
                Rectangle()
                    .fill(Color.kindredDivider.opacity(0.3))
                    .frame(height: 20)
                    .clipShape(.rect(cornerRadius: 4))

                Rectangle()
                    .fill(Color.kindredDivider.opacity(0.2))
                    .frame(height: 16)
                    .clipShape(.rect(cornerRadius: 4))

                Spacer()
            }
            .padding(KindredSpacing.md)
            .frame(height: 120, alignment: .top)
        }
    }

    private func loadAd() {
        loadState = .loading

        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController

        let coordinator = AdLoaderCoordinator { ad in
            self.nativeAd = ad
            self.loadState = .loaded
        } onFailure: { error in
            self.loadState = .failed(error.localizedDescription)
        }

        let loader = GADAdLoader(
            adUnitID: AdUnitIDs.feedNative,
            rootViewController: rootVC,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = coordinator

        // Store in @State to keep alive until callback
        self.adCoordinator = coordinator
        self.adLoader = loader

        loader.load(GADRequest())
    }
}

// MARK: - NativeAdMediaView

/// UIViewRepresentable wrapper for GADMediaView
private struct NativeAdMediaView: UIViewRepresentable {
    let ad: GADNativeAd

    func makeUIView(context: Context) -> GADMediaView {
        let mediaView = GADMediaView()
        mediaView.mediaContent = ad.mediaContent
        return mediaView
    }

    func updateUIView(_ uiView: GADMediaView, context: Context) {
        // No updates needed
    }
}

// MARK: - AdLoaderCoordinator

/// Coordinator to handle GADAdLoaderDelegate callbacks
private class AdLoaderCoordinator: NSObject, GADNativeAdLoaderDelegate, GADNativeAdDelegate {
    let onSuccess: (GADNativeAd) -> Void
    let onFailure: (Error) -> Void

    init(onSuccess: @escaping (GADNativeAd) -> Void, onFailure: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        nativeAd.delegate = self
        onSuccess(nativeAd)
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        onFailure(error)
    }
}
