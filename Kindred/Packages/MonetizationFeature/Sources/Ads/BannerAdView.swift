import ComposableArchitecture
import DesignSystem
import GoogleMobileAds
import SwiftUI

/// Adaptive banner ad for recipe detail view
/// Uses UIViewRepresentable to wrap GADBannerView
public struct BannerAdView: View {
    @State private var bannerHeight: CGFloat = 0
    @Dependency(\.adClient) var adClient

    public init() {}

    public var body: some View {
        Group {
            if adClient.shouldShowAds() && bannerHeight > 0 {
                BannerViewRepresentable(bannerHeight: $bannerHeight)
                    .frame(height: bannerHeight)
                    .background(Color.kindredCardSurface)
                    .accessibilityLabel("Advertisement")
            } else {
                // Collapsed when no ad loaded or ads suppressed
                EmptyView()
            }
        }
    }
}

// MARK: - BannerViewRepresentable

/// UIViewRepresentable wrapper for GADBannerView
private struct BannerViewRepresentable: UIViewRepresentable {
    @Binding var bannerHeight: CGFloat

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()

        // Set ad unit ID
        bannerView.adUnitID = AdUnitIDs.detailBanner

        // Get root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        // Set delegate
        bannerView.delegate = context.coordinator

        // Use adaptive banner size
        let viewWidth = UIScreen.main.bounds.width
        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView.adSize = adaptiveSize

        // Load ad request
        bannerView.load(GADRequest())

        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // No updates needed after initial setup
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerHeight: $bannerHeight)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, GADBannerViewDelegate {
        @Binding var bannerHeight: CGFloat

        init(bannerHeight: Binding<CGFloat>) {
            _bannerHeight = bannerHeight
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            // Update height when ad loads successfully
            DispatchQueue.main.async {
                self.bannerHeight = bannerView.adSize.size.height
            }
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            // Collapse on failure
            DispatchQueue.main.async {
                self.bannerHeight = 0
            }
        }
    }
}
