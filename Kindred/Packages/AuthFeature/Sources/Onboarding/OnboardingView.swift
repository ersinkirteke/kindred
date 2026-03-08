import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingReducer>

    // @ScaledMetric for Dynamic Type support
    @ScaledMetric(relativeTo: .title2) private var heading2Size: CGFloat = 22
    @ScaledMetric(relativeTo: .headline) private var bodySize: CGFloat = 18
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 14

    public init(store: StoreOf<OnboardingReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            Group {
                switch store.currentStep {
                case 0:
                    SignInStepView(store: store)
                case 1:
                    DietaryPrefsStepView(store: store)
                case 2:
                    LocationStepView(store: store)
                default:
                    VoiceTeaserStepView(store: store)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.currentStep)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<store.totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == store.currentStep ? Color.kindredAccent : Color.kindredAccent.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}
