import SwiftUI
import ComposableArchitecture
import DesignSystem

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingReducer>

    public init(store: StoreOf<OnboardingReducer>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.kindredBackground
                .ignoresSafeArea()

            TabView(selection: Binding(
                get: { store.currentStep },
                set: { _ in }
            )) {
                SignInStepView(store: store)
                    .tag(0)

                DietaryPrefsStepView(store: store)
                    .tag(1)

                LocationStepView(store: store)
                    .tag(2)

                VoiceTeaserStepView(store: store)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}
