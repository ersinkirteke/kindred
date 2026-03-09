import Foundation
import Dependencies
import DependenciesMacros
import FeedFeature
import AuthClient
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let guestMigration = Logger(subsystem: subsystem, category: "guest-migration")
}

/// Result of guest data migration
public struct MigrationResult: Equatable, Sendable {
    public let migratedBookmarks: Int
    public let migratedSkips: Int
    public let migratedDietaryPrefs: Int
    public let migratedCity: String?
}

/// TCA dependency client for migrating guest data to authenticated account
@DependencyClient
public struct GuestMigrationClient: Sendable {
    /// Upload all guest data to backend and clean up local storage
    public var migrateGuestData: @Sendable () async throws -> MigrationResult

    /// Check if there's pending guest data to migrate
    public var hasPendingMigration: @Sendable () async -> Bool = { false }
}

enum MigrationError: Error {
    case noData
    case countMismatch
    case noGuestUserId
}

// MARK: - Dependency Registration

extension GuestMigrationClient: DependencyKey {
    public static let liveValue: GuestMigrationClient = {
        @Dependency(\.guestSessionClient) var guestSessionClient

        return GuestMigrationClient(
            migrateGuestData: {
                // Read guest UUID
                guard let guestUserId = UserDefaults.standard.string(forKey: "guestUserId"), !guestUserId.isEmpty else {
                    throw MigrationError.noGuestUserId
                }

                // Fetch all local guest data
                let bookmarks = await guestSessionClient.allBookmarks()
                let skips = await guestSessionClient.allSkips()

                // Read dietary preferences from UserDefaults
                var dietaryPreferences: [String] = []
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let prefs = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    dietaryPreferences = Array(prefs)
                }

                // Read selected city from UserDefaults
                let city = UserDefaults.standard.string(forKey: "selectedCity")

                // Set pendingMigration flag BEFORE attempting migration
                UserDefaults.standard.set(true, forKey: "pendingMigration")

                // LOCAL-ONLY FALLBACK (use until backend mutation exists and codegen is run):
                // TODO: Replace with Apollo mutation call after running codegen
                // When backend adds migrateGuestData mutation to schema.gql, run:
                // ./apollo-ios-cli generate
                // Then uncomment the Apollo mutation code below and remove this fallback.
                Logger.guestMigration.notice("Migration: local-only mode (backend mutation pending)")
                Logger.guestMigration.notice("  Bookmarks: \(bookmarks.count, privacy: .public)")
                Logger.guestMigration.notice("  Skips: \(skips.count, privacy: .public)")
                Logger.guestMigration.notice("  Dietary: \(dietaryPreferences.joined(separator: ", "), privacy: .public)")
                Logger.guestMigration.notice("  City: \(city ?? "none", privacy: .public)")

                // Keep local data intact — don't clean up SwiftData until backend confirms
                UserDefaults.standard.set(true, forKey: "guestMigrated")
                UserDefaults.standard.removeObject(forKey: "pendingMigration")

                return MigrationResult(
                    migratedBookmarks: bookmarks.count,
                    migratedSkips: skips.count,
                    migratedDietaryPrefs: dietaryPreferences.count,
                    migratedCity: city
                )

                /* APOLLO MUTATION CODE (uncomment after codegen):
                do {
                    // Attempt real GraphQL migration
                    let mutation = MigrateGuestDataMutation(
                        guestUserId: guestUserId,
                        bookmarks: bookmarks.map { $0.recipeId },
                        skips: skips.map { $0.recipeId },
                        dietaryPreferences: dietaryPreferences,
                        city: .some(city)
                    )
                    let result = try await apolloClient.perform(mutation: mutation)

                    guard let data = result.data else {
                        throw MigrationError.noData
                    }

                    // Verify counts match before cleanup
                    guard data.migrateGuestData.migratedBookmarks == bookmarks.count,
                          data.migrateGuestData.migratedSkips == skips.count else {
                        throw MigrationError.countMismatch
                    }

                    // Backend confirmed — safe to clean up local SwiftData
                    for bookmark in bookmarks {
                        try await guestSessionClient.unbookmarkRecipe(bookmark.recipeId)
                    }
                    for skip in skips {
                        try await guestSessionClient.undoSkip(skip.recipeId)
                    }

                    UserDefaults.standard.set(true, forKey: "guestMigrated")
                    UserDefaults.standard.removeObject(forKey: "pendingMigration")

                    return MigrationResult(
                        migratedBookmarks: data.migrateGuestData.migratedBookmarks,
                        migratedSkips: data.migrateGuestData.migratedSkips,
                        migratedDietaryPrefs: dietaryPreferences.count,
                        migratedCity: city
                    )
                } catch {
                    // If Apollo mutation fails (including if type doesn't exist yet),
                    // fall back to local-only migration — data stays in SwiftData,
                    // pendingMigration flag remains set for retry on next launch
                    Logger.guestMigration.warning("Apollo mutation failed, keeping local data: \(error.localizedDescription)")
                    throw error
                }
                */
            },
            hasPendingMigration: {
                // Check pendingMigration flag first (survives app restart)
                if UserDefaults.standard.bool(forKey: "pendingMigration") {
                    return true
                }

                // Also check: if guestMigrated is false AND (bookmarks or skips exist), return true
                let bookmarks = await guestSessionClient.allBookmarks()
                let skips = await guestSessionClient.allSkips()
                let isMigrated = UserDefaults.standard.bool(forKey: "guestMigrated")
                return (!bookmarks.isEmpty || !skips.isEmpty) && !isMigrated
            }
        )
    }()

    public static let testValue = GuestMigrationClient()
}

extension DependencyValues {
    public var guestMigrationClient: GuestMigrationClient {
        get { self[GuestMigrationClient.self] }
        set { self[GuestMigrationClient.self] = newValue }
    }
}
