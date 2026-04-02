import ComposableArchitecture
import FeedFeature
import Foundation
import MonetizationFeature
import StoreKit
import OSLog

#if canImport(ClerkSDK)
import ClerkSDK
#endif

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let profile = Logger(subsystem: subsystem, category: "profile")
}

// Resolve SubscriptionStatus ambiguity between FeedFeature and MonetizationFeature
public typealias SubscriptionStatus = MonetizationFeature.SubscriptionStatus

public enum AuthState: Equatable {
    case guest
    case authenticated(userId: String)
}

// Voice profile info for Privacy & Data section
public struct VoiceProfileInfo: Equatable, Identifiable {
    public let id: String
    public let speakerName: String
    public let relationship: String
    public let createdAt: Date
    public let status: VoiceProfileStatus

    public init(id: String, speakerName: String, relationship: String, createdAt: Date, status: VoiceProfileStatus) {
        self.id = id
        self.speakerName = speakerName
        self.relationship = relationship
        self.createdAt = createdAt
        self.status = status
    }
}

public enum VoiceProfileStatus: String, Equatable {
    case ready = "READY"
    case processing = "PROCESSING"
    case failed = "FAILED"
}

@Reducer
public struct ProfileReducer {
    @ObservableState
    public struct State: Equatable {
        public var authState: AuthState = .guest
        public var dietaryPreferences: Set<String> = []

        // Culinary DNA
        public var culinaryDNAAffinities: [AffinityScore] = []
        public var interactionCount: Int = 0
        public var isDNAActivated: Bool = false

        // Subscription
        public var subscriptionStatus: SubscriptionStatus = .unknown
        public var displayPrice: String = "$9.99"
        public var subscriptionProducts: [Product] = []

        // Voice profile (Privacy & Data section)
        public var voiceProfile: VoiceProfileInfo? = nil
        public var showDeleteConfirmation: Bool = false
        public var isDeletingVoice: Bool = false
        public var showDeleteSuccessToast: Bool = false
        public var showPrivacyPolicy: Bool = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case signInTapped
        case continueAsGuestTapped
        case loadDietaryPreferences
        case dietaryPreferencesChanged(Set<String>)
        case resetDietaryPreferences
        case loadCulinaryDNA
        case culinaryDNALoaded([AffinityScore], Int, Bool)
        case loadSubscriptionStatus
        case subscriptionStatusLoaded(SubscriptionStatus)
        case subscriptionProductsLoaded([Product])
        case subscribeTapped
        case purchaseCompleted(SubscriptionStatus)
        case simulatedPurchaseCompleted
        case purchaseFailed(String)
        case manageSubscriptionTapped
        case restorePurchasesTapped
        case restoreCompleted(SubscriptionStatus)
        case authStateUpdated(AuthState)
        case signOutTapped
        case loadVoiceProfile
        case voiceProfileLoaded(VoiceProfileInfo?)
        case deleteVoiceTapped
        case confirmDeleteVoice
        case cancelDeleteVoice
        case voiceDeleted
        case voiceDeletionFailed(String)
        case dismissDeleteSuccessToast
        case privacyPolicyTapped
        case dismissPrivacyPolicy
        case trackingSettingsTapped
    }

    @Dependency(\.guestSessionClient) var guestSession
    @Dependency(\.personalizationClient) var personalization
    @Dependency(\.subscriptionClient) var subscriptionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Load dietary preferences, culinary DNA, subscription status, and voice profile on appear
                return .merge(
                    .send(.loadDietaryPreferences),
                    .send(.loadCulinaryDNA),
                    .send(.loadSubscriptionStatus),
                    .send(.loadVoiceProfile)
                )

            case .loadDietaryPreferences:
                // Load from UserDefaults
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let preferences = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    state.dietaryPreferences = preferences
                }
                return .none

            case let .dietaryPreferencesChanged(preferences):
                state.dietaryPreferences = preferences
                // Save to UserDefaults
                if let encoded = try? JSONEncoder().encode(preferences) {
                    UserDefaults.standard.set(encoded, forKey: "dietaryPreferences")
                }
                return .none

            case .resetDietaryPreferences:
                state.dietaryPreferences = []
                UserDefaults.standard.removeObject(forKey: "dietaryPreferences")
                return .none

            case .loadCulinaryDNA:
                return .run { send in
                    let bookmarks = await guestSession.allBookmarks()
                    let skips = await guestSession.allSkips()
                    let affinities = await personalization.computeAffinities(bookmarks, skips)
                    let count = await personalization.interactionCount(bookmarks, skips)
                    let activated = await personalization.isActivated(bookmarks, skips)
                    await send(.culinaryDNALoaded(affinities, count, activated))
                }

            case let .culinaryDNALoaded(affinities, count, activated):
                state.culinaryDNAAffinities = affinities
                state.interactionCount = count
                state.isDNAActivated = activated
                return .none

            case .signInTapped:
                // Handled by parent AppReducer — presents auth gate
                return .none

            case let .authStateUpdated(authState):
                state.authState = authState
                return .none

            case .continueAsGuestTapped:
                // Placeholder - guest flow in Phase 8
                return .none

            case .loadSubscriptionStatus:
                return .run { send in
                    // Load products and check entitlement in parallel
                    async let products = try subscriptionClient.loadProducts()
                    async let status = subscriptionClient.currentEntitlement()

                    let loadedProducts = try await products
                    await send(.subscriptionProductsLoaded(loadedProducts))

                    let loadedStatus = await status
                    await send(.subscriptionStatusLoaded(loadedStatus))
                } catch: { error, send in
                    // If loading fails, default to free tier
                    await send(.subscriptionStatusLoaded(.free))
                }

            case let .subscriptionStatusLoaded(status):
                state.subscriptionStatus = status
                return .none

            case let .subscriptionProductsLoaded(products):
                state.subscriptionProducts = products
                // Extract display price from first product
                if let firstProduct = products.first {
                    state.displayPrice = firstProduct.displayPrice
                }
                return .none

            case .subscribeTapped:
                if let product = state.subscriptionProducts.first {
                    // Real StoreKit purchase
                    return .run { send in
                        do {
                            _ = try await subscriptionClient.purchase(product)
                            let status = await subscriptionClient.currentEntitlement()
                            await send(.purchaseCompleted(status))
                        } catch {
                            await send(.purchaseFailed(error.localizedDescription))
                        }
                    }
                } else {
                    #if DEBUG
                    // Simulated purchase when StoreKit Testing is not available (CLI install)
                    return .run { send in
                        try await Task.sleep(for: .seconds(1))
                        await send(.simulatedPurchaseCompleted)
                    }
                    #else
                    return .send(.purchaseFailed("No subscription product available"))
                    #endif
                }

            case let .purchaseCompleted(status):
                state.subscriptionStatus = status
                return .none

            case .simulatedPurchaseCompleted:
                let expiresDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                state.subscriptionStatus = .pro(expiresDate: expiresDate, isInGracePeriod: false)
                return .none

            case let .purchaseFailed(message):
                Logger.profile.error("Purchase failed: \(message, privacy: .public)")
                return .none

            case .manageSubscriptionTapped:
                // Open iOS Settings subscription management
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
                return .none

            case .restorePurchasesTapped:
                return .run { send in
                    do {
                        try await subscriptionClient.restorePurchases()
                        // Re-check entitlement after restore
                        let status = await subscriptionClient.currentEntitlement()
                        await send(.restoreCompleted(status))
                    } catch {
                        // Restore failed, keep current status
                        Logger.profile.error("Restore failed: \(error.localizedDescription, privacy: .public)")
                    }
                }

            case let .restoreCompleted(status):
                state.subscriptionStatus = status
                return .none

            case .signOutTapped:
                // Handled by parent AppReducer
                return .none

            case .loadVoiceProfile:
                guard case .authenticated(let userId) = state.authState else {
                    return .none
                }
                return .run { send in
                    do {
                        // GraphQL query to fetch voice profiles
                        let query = """
                        query MyVoiceProfiles {
                            myVoiceProfiles {
                                id
                                speakerName
                                relationship
                                createdAt
                                status
                            }
                        }
                        """

                        var request = URLRequest(url: URL(string: "https://api.kindredcook.app/v1/graphql")!)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                        // Get Clerk token for auth
                        let clerkToken = try await getClerkToken()
                        request.setValue("Bearer \(clerkToken)", forHTTPHeaderField: "Authorization")

                        let body = ["query": query]
                        request.httpBody = try JSONSerialization.data(withJSONObject: body)

                        let (data, _) = try await URLSession.shared.data(for: request)
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                        guard let dataObj = json?["data"] as? [String: Any],
                              let profiles = dataObj["myVoiceProfiles"] as? [[String: Any]],
                              let firstProfile = profiles.first(where: { profile in
                                  let status = profile["status"] as? String
                                  return status == "READY" || status == "PROCESSING"
                              }) else {
                            await send(.voiceProfileLoaded(nil))
                            return
                        }

                        // Parse first non-DELETED profile
                        let id = firstProfile["id"] as? String ?? ""
                        let speakerName = firstProfile["speakerName"] as? String ?? ""
                        let relationship = firstProfile["relationship"] as? String ?? ""
                        let statusString = firstProfile["status"] as? String ?? "PENDING"
                        let status = VoiceProfileStatus(rawValue: statusString) ?? .processing

                        // Parse createdAt
                        var createdAt = Date()
                        if let createdAtString = firstProfile["createdAt"] as? String {
                            let formatter = ISO8601DateFormatter()
                            if let date = formatter.date(from: createdAtString) {
                                createdAt = date
                            }
                        }

                        let profileInfo = VoiceProfileInfo(
                            id: id,
                            speakerName: speakerName,
                            relationship: relationship,
                            createdAt: createdAt,
                            status: status
                        )
                        await send(.voiceProfileLoaded(profileInfo))
                    } catch {
                        Logger.profile.error("Failed to load voice profile: \(error.localizedDescription)")
                        await send(.voiceProfileLoaded(nil))
                    }
                }

            case let .voiceProfileLoaded(profile):
                state.voiceProfile = profile
                return .none

            case .deleteVoiceTapped:
                state.showDeleteConfirmation = true
                return .none

            case .confirmDeleteVoice:
                state.showDeleteConfirmation = false
                guard let voiceId = state.voiceProfile?.id else {
                    return .none
                }
                state.isDeletingVoice = true

                return .run { send in
                    do {
                        // GraphQL mutation to delete voice profile
                        let mutation = """
                        mutation DeleteVoiceProfile($id: String!) {
                            deleteVoiceProfile(id: $id) {
                                id
                                status
                            }
                        }
                        """

                        var request = URLRequest(url: URL(string: "https://api.kindredcook.app/v1/graphql")!)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                        // Get Clerk token for auth
                        let clerkToken = try await getClerkToken()
                        request.setValue("Bearer \(clerkToken)", forHTTPHeaderField: "Authorization")

                        let body: [String: Any] = [
                            "query": mutation,
                            "variables": ["id": voiceId]
                        ]
                        request.httpBody = try JSONSerialization.data(withJSONObject: body)

                        let (data, _) = try await URLSession.shared.data(for: request)
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                        // Check for GraphQL errors
                        if let errors = json?["errors"] as? [[String: Any]], !errors.isEmpty {
                            let errorMessage = errors.first?["message"] as? String ?? "Unknown error"
                            await send(.voiceDeletionFailed(errorMessage))
                            return
                        }

                        await send(.voiceDeleted)
                    } catch {
                        await send(.voiceDeletionFailed(error.localizedDescription))
                    }
                } catch: { error, send in
                    await send(.voiceDeletionFailed(error.localizedDescription))
                }

            case .cancelDeleteVoice:
                state.showDeleteConfirmation = false
                return .none

            case .voiceDeleted:
                state.isDeletingVoice = false
                state.voiceProfile = nil
                state.showDeleteSuccessToast = true
                return .none

            case let .voiceDeletionFailed(message):
                state.isDeletingVoice = false
                Logger.profile.error("Voice deletion failed: \(message)")
                return .none

            case .dismissDeleteSuccessToast:
                state.showDeleteSuccessToast = false
                return .none

            case .privacyPolicyTapped:
                state.showPrivacyPolicy = true
                return .none

            case .dismissPrivacyPolicy:
                state.showPrivacyPolicy = false
                return .none

            case .trackingSettingsTapped:
                // Open iOS Settings to manage tracking permission
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    #if canImport(UIKit)
                    UIApplication.shared.open(url)
                    #endif
                }
                return .none
            }
        }
    }
}

// Helper function to get Clerk token
@Sendable
private func getClerkToken() async throws -> String {
    #if canImport(ClerkSDK)
    // Get token from Clerk
    if let session = Clerk.shared.session {
        return try await session.getToken()
    }
    #endif
    throw NSError(domain: "ProfileReducer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Clerk session"])
}
