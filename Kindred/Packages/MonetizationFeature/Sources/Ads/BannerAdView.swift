import DesignSystem
import GoogleMobileAds
import SwiftUI

/// Adaptive banner ad for recipe detail view
public struct BannerAdView: View {
    @State private var adLoaded = false
    @State private var adError: String?

    public init() {}

    public var body: some View {
        ZStack {
            Color.kindredCardSurface

            if let error = adError {
                Text("Ad error: \(error)")
                    .font(.caption2)
                    .foregroundColor(.red)
            } else if !adLoaded {
                ProgressView()
                    .controlSize(.small)
            }

            BannerViewRepresentable(adLoaded: $adLoaded, adError: $adError)
        }
        .frame(height: 60)
        .cornerRadius(8)
        .accessibilityLabel(String(localized: "accessibility.ads.advertisement"))
    }
}

// MARK: - BannerViewRepresentable

private struct BannerViewRepresentable: UIViewRepresentable {
    @Binding var adLoaded: Bool
    @Binding var adError: String?

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = AdUnitIDs.detailBanner

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        bannerView.delegate = context.coordinator

        let viewWidth = UIScreen.main.bounds.width - 32 // Account for padding
        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView.adSize = adaptiveSize

        bannerView.load(GADRequest())

        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(adLoaded: $adLoaded, adError: $adError)
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        @Binding var adLoaded: Bool
        @Binding var adError: String?

        init(adLoaded: Binding<Bool>, adError: Binding<String?>) {
            _adLoaded = adLoaded
            _adError = adError
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            DispatchQueue.main.async {
                self.adLoaded = true
                self.adError = nil
            }
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            DispatchQueue.main.async {
                self.adLoaded = false
                self.adError = error.localizedDescription
            }
        }
    }
}
