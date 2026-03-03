import Foundation
import ComposableArchitecture
import Dependencies
import AuthClient
import CoreLocation
import FeedFeature

@Reducer
public struct OnboardingReducer {
    @ObservableState
    public struct State: Equatable {
        public var currentStep: Int = 0
        public var totalSteps: Int = 4

        // Sign-in step state
        public var isSigningIn = false
        public var signInError: String?
        public var isAuthenticated = false

        // Dietary preferences step state
        public var selectedDietaryPrefs: Set<String> = []

        // Location step state
        public var locationAuthStatus: LocationAuthStatus = .notDetermined
        public var selectedCity: String?
        public var showCityPicker = false

        // Voice teaser step state (no additional state needed)

        public init() {}
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

        // Sign-in step
        case appleSignInTapped
        case googleSignInTapped
        case signInSucceeded
        case signInFailed(String)
        case continueAsGuestTapped

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
    }

    @Dependency(\.signInClient) var signInClient
    @Dependency(\.locationClient) var locationClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nextStep:
                state.currentStep += 1
                if state.currentStep >= state.totalSteps {
                    return .send(.completeOnboarding)
                }
                return .none

            case .skipStep:
                return .send(.nextStep)

            case .completeOnboarding:
                state.currentStep = state.totalSteps
                return .none

            case .appleSignInTapped:
                state.isSigningIn = true
                state.signInError = nil
                return .run { send in
                    do {
                        _ = try await signInClient.signInWithApple()
                        await send(.signInSucceeded)
                    } catch SignInError.cancelled {
                        // User cancelled - just reset loading state, no error
                        await send(.signInFailed(""))
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .googleSignInTapped:
                state.isSigningIn = true
                state.signInError = nil
                return .run { send in
                    do {
                        _ = try await signInClient.signInWithGoogle()
                        await send(.signInSucceeded)
                    } catch SignInError.cancelled {
                        // User cancelled - just reset loading state, no error
                        await send(.signInFailed(""))
                    } catch {
                        await send(.signInFailed(error.localizedDescription))
                    }
                }

            case .signInSucceeded:
                state.isSigningIn = false
                state.isAuthenticated = true
                // Instantly advance to next step (no delay, no animation per locked decision)
                return .send(.nextStep)

            case .signInFailed(let errorMessage):
                state.isSigningIn = false
                // Empty error message means cancellation - don't show error
                if !errorMessage.isEmpty {
                    state.signInError = errorMessage
                }
                return .none

            case .continueAsGuestTapped:
                return .send(.nextStep)

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
                return .run { send in
                    let status = await locationClient.requestAuthorization()
                    let mappedStatus: LocationAuthStatus = switch status {
                    case .authorizedWhenInUse, .authorizedAlways:
                            .authorized
                    case .denied, .restricted:
                            .denied
                    default:
                            .notDetermined
                    }
                    await send(.locationAuthChanged(mappedStatus))
                }

            case .locationAuthChanged(let status):
                state.locationAuthStatus = status

                if status == .authorized {
                    // Get city name and auto-advance
                    return .run { send in
                        do {
                            let location = try await locationClient.currentLocation()
                            let cityName = try await locationClient.reverseGeocode(location)
                            await send(.citySelected(cityName))
                        } catch {
                            // If getting location fails after permission granted, show manual picker
                            await send(.showManualCityPicker)
                        }
                    }
                } else if status == .denied {
                    // Show manual fallback
                    state.showCityPicker = true
                }

                return .none

            case .showManualCityPicker:
                state.showCityPicker = true
                return .none

            case .dismissCityPicker:
                state.showCityPicker = false
                return .none

            case .citySelected(let city):
                state.selectedCity = city
                state.showCityPicker = false

                // Save to @AppStorage key
                UserDefaults.standard.set(city, forKey: "selectedCity")

                // Auto-advance to next step
                return .send(.nextStep)

            case .tryVoiceNowTapped:
                // Complete onboarding first, then parent will trigger voice upload
                return .send(.completeOnboarding)

            case .setupVoiceLaterTapped:
                return .send(.completeOnboarding)
            }
        }
    }
}
