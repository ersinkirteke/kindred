import CoreLocation
import Foundation
import ComposableArchitecture
import Dependencies
import AuthClient
import FeedFeature

@Reducer
public struct OnboardingReducer {
    @ObservableState
    public struct State: Equatable {
        public var firstName: String?
        public var currentStep: Int
        public var totalSteps: Int = 3

        // Dietary preferences step state
        public var selectedDietaryPrefs: Set<String> = []

        // Location step state
        public var locationAuthStatus: LocationAuthStatus = .notDetermined
        public var selectedCity: String?
        public var showCityPicker = false
        public var isRequestingLocation = false
        // Voice teaser step state (no additional state needed)

        public init(firstName: String? = nil) {
            self.firstName = firstName

            // Resume from last step if onboarding was dismissed
            self.currentStep = UserDefaults.standard.integer(forKey: "onboardingCurrentStep")

            // Pre-fill from guest data
            if let encoded = UserDefaults.standard.data(forKey: "dietaryPreferences"),
               let prefs = try? JSONDecoder().decode(Set<String>.self, from: encoded) {
                self.selectedDietaryPrefs = prefs
            }

            if let city = UserDefaults.standard.string(forKey: "selectedCity") {
                self.selectedCity = city
            }
        }
    }

    public enum LocationAuthStatus: Equatable {
        case notDetermined
        case authorized
        case denied
    }

    public enum Action: Equatable, Sendable {
        // Navigation
        case nextStep
        case skipStep
        case completeOnboarding

        // Dietary preferences step
        case toggleDietaryPref(String)

        // Location step
        case requestLocationPermission
        case locationAuthChanged(LocationAuthStatus)
        case showManualCityPicker
        case dismissCityPicker
        case citySelected(String)

        // Voice teaser step
        case tryVoiceNowTapped
        case setupVoiceLaterTapped

        // Delegate
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case completed(dietaryPrefs: Set<String>, city: String?, wantsVoiceUpload: Bool)
    }

    @Dependency(\.locationClient) var locationClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nextStep:
                state.currentStep += 1

                // Save progress
                UserDefaults.standard.set(state.currentStep, forKey: "onboardingCurrentStep")

                if state.currentStep >= state.totalSteps {
                    return .send(.completeOnboarding)
                }
                return .none

            case .skipStep:
                return .send(.nextStep)

            case .completeOnboarding:
                return .send(.delegate(.completed(
                    dietaryPrefs: state.selectedDietaryPrefs,
                    city: state.selectedCity,
                    wantsVoiceUpload: false
                )))

            case .toggleDietaryPref(let pref):
                if state.selectedDietaryPrefs.contains(pref) {
                    state.selectedDietaryPrefs.remove(pref)
                } else {
                    state.selectedDietaryPrefs.insert(pref)
                }

                // Save to UserDefaults using SAME key as Phase 6 dietary chip bar
                return .run { [prefs = state.selectedDietaryPrefs] _ in
                    let encoder = JSONEncoder()
                    if let encoded = try? encoder.encode(prefs) {
                        UserDefaults.standard.set(encoded, forKey: "dietaryPreferences")
                    }
                }

            case .requestLocationPermission:
                state.isRequestingLocation = true
                return .run { send in
                    let status = await LocationManager.shared.requestPermissionAndWait()

                    guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                        await send(.locationAuthChanged(.denied))
                        return
                    }

                    do {
                        let location = try await LocationManager.shared.requestCurrentLocation()
                        let geocoder = CLGeocoder()
                        let placemarks = try await geocoder.reverseGeocodeLocation(location)
                        if let city = placemarks.first?.locality {
                            await send(.citySelected(city))
                        } else if let area = placemarks.first?.administrativeArea {
                            await send(.citySelected(area))
                        } else {
                            await send(.showManualCityPicker)
                        }
                    } catch {
                        await send(.showManualCityPicker)
                    }
                }

            case let .locationAuthChanged(status):
                state.locationAuthStatus = status
                state.isRequestingLocation = false
                if status == .denied {
                    state.showCityPicker = true
                }
                return .none

            case .showManualCityPicker:
                state.isRequestingLocation = false
                state.showCityPicker = true
                return .none

            case .dismissCityPicker:
                state.showCityPicker = false
                return .none

            case .citySelected(let city):
                state.selectedCity = city
                state.showCityPicker = false
                state.isRequestingLocation = false

                // Save to @AppStorage key
                UserDefaults.standard.set(city, forKey: "selectedCity")

                // Auto-advance to next step
                return .send(.nextStep)

            case .tryVoiceNowTapped:
                return .send(.delegate(.completed(
                    dietaryPrefs: state.selectedDietaryPrefs,
                    city: state.selectedCity,
                    wantsVoiceUpload: true
                )))

            case .setupVoiceLaterTapped:
                return .send(.delegate(.completed(
                    dietaryPrefs: state.selectedDietaryPrefs,
                    city: state.selectedCity,
                    wantsVoiceUpload: false
                )))

            case .delegate:
                return .none
            }
        }
    }
}

