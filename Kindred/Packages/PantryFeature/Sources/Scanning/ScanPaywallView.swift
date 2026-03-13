import DesignSystem
import SwiftUI

/// Scan-specific Pro paywall with animated mockup
public struct ScanPaywallView: View {
    let onSubscribe: () -> Void
    let onRestore: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStep: AnimationStep = .photo

    public init(
        onSubscribe: @escaping () -> Void,
        onRestore: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onSubscribe = onSubscribe
        self.onRestore = onRestore
        self.onDismiss = onDismiss
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
            .cornerRadius(16)
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
            .cornerRadius(16)
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
        .cornerRadius(8)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 16) {
            Button {
                onSubscribe()
            } label: {
                Text(String(localized: "scan.paywall.subscribe", bundle: .main))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

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
