import DesignSystem
import SwiftUI

/// Scan-specific Pro paywall with animated mockup
public struct ScanPaywallView: View {
    let subscribeButtonTitle: String
    let isLoadingPrice: Bool
    let isPurchasing: Bool
    let isRestoring: Bool
    let purchaseError: String?
    let restoreMessage: String?
    let onSubscribe: () -> Void
    let onRestore: () -> Void
    let onDismiss: () -> Void
    let onDismissError: () -> Void
    let onDismissRestoreMessage: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStep: AnimationStep = .photo

    public init(
        subscribeButtonTitle: String,
        isLoadingPrice: Bool,
        isPurchasing: Bool,
        isRestoring: Bool,
        purchaseError: String?,
        restoreMessage: String?,
        onSubscribe: @escaping () -> Void,
        onRestore: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onDismissError: @escaping () -> Void,
        onDismissRestoreMessage: @escaping () -> Void
    ) {
        self.subscribeButtonTitle = subscribeButtonTitle
        self.isLoadingPrice = isLoadingPrice
        self.isPurchasing = isPurchasing
        self.isRestoring = isRestoring
        self.purchaseError = purchaseError
        self.restoreMessage = restoreMessage
        self.onSubscribe = onSubscribe
        self.onRestore = onRestore
        self.onDismiss = onDismiss
        self.onDismissError = onDismissError
        self.onDismissRestoreMessage = onDismissRestoreMessage
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text(String(localized: "scan.paywall.title", bundle: .main))
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)

                        Text(String(localized: "scan.paywall.subtitle", bundle: .main))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Animated mockup or static preview
                    if reduceMotion {
                        staticMockup
                    } else {
                        animatedMockup
                    }

                    // Feature bullets
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureBullet(
                            icon: "camera.fill",
                            title: String(localized: "scan.paywall.unlimited_scans", bundle: .main)
                        )

                        FeatureBullet(
                            icon: "doc.text.viewfinder",
                            title: String(localized: "scan.paywall.receipt_scanning", bundle: .main)
                        )

                        FeatureBullet(
                            icon: "sparkles",
                            title: String(localized: "scan.paywall.recipe_suggestions", bundle: .main)
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtons
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(String(localized: "common.close", defaultValue: "Close", bundle: .main))
                }
            }
            .overlay {
                if isRestoring {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Restoring purchases...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Restoring purchases")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var animatedMockup: some View {
        VStack(spacing: 16) {
            ZStack {
                switch animationStep {
                case .photo:
                    mockupPhotoPlaceholder
                        .transition(.opacity)
                case .analyzing:
                    mockupAnalyzing
                        .transition(.opacity)
                case .results:
                    mockupResults
                        .transition(.opacity)
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal)
        }
        .onAppear {
            startAnimation()
        }
    }

    @ViewBuilder
    private var staticMockup: some View {
        VStack(spacing: 12) {
            // Show all three states at once for Reduce Motion
            HStack(spacing: 12) {
                mockupPhotoPlaceholder
                    .frame(width: 100, height: 100)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                mockupAnalyzing
                    .frame(width: 100, height: 100)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                mockupResults
                    .frame(width: 100, height: 100)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal)

            Text("Scan → Analyze → Results")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mockupPhotoPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))

            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mockupAnalyzing: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)

            Text("AI analyzing...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mockupResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Eggs")
                    .font(.body)
                Spacer()
                Text("×6")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Milk")
                    .font(.body)
                Spacer()
                Text("1L")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Butter")
                    .font(.body)
                Spacer()
                Text("200g")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 8))
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            // Error and restore message banners
            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isStaticText)
            }
            if let restoreMsg = restoreMessage {
                Text(restoreMsg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityAddTraits(.isStaticText)
            }

            Button {
                onSubscribe()
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else if isLoadingPrice {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text(subscribeButtonTitle)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubscribe ? Color.accentColor : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubscribe)
            .accessibilityLabel(isLoadingPrice ? "Loading subscription price" : subscribeButtonTitle)

            Button {
                onRestore()
            } label: {
                Text(String(localized: "scan.paywall.restore", bundle: .main))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSubscribe: Bool {
        !isLoadingPrice && !isPurchasing && subscribeButtonTitle != "Unable to load pricing"
    }

    private func startAnimation() {
        guard !reduceMotion else { return }

        // Loop through animation steps
        let sequence = [AnimationStep.photo, .analyzing, .results]
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut) {
                currentIndex = (currentIndex + 1) % sequence.count
                animationStep = sequence[currentIndex]
            }
        }
    }

    private enum AnimationStep {
        case photo
        case analyzing
        case results
    }
}

/// Feature bullet for paywall
private struct FeatureBullet: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            Text(title)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}
