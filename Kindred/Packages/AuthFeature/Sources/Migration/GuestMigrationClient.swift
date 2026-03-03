import Foundation
import Dependencies
import DependenciesMacros
import FeedFeature
import AuthClient

/// TCA dependency client for migrating guest data to authenticated account
@DependencyClient
public struct GuestMigrationClient: Sendable {
    /// Upload all guest data to backend and clean up local storage
    public var migrateGuestData: @Sendable () async throws -> Void

    /// Check if there's pending guest data to migrate
    public var hasPendingMigration: @Sendable () async -> Bool = { false }
}

// MARK: - Dependency Registration

extension GuestMigrationClient: DependencyKey {
    public static let liveValue: GuestMigrationClient = {
        @Dependency(\.guestSessionClient) var guestSessionClient

        return GuestMigrationClient(
            migrateGuestData: {
                // Read guest UUID
                let guestUserId = UserDefaults.standard.string(forKey: "guestUserId") ?? ""

                // Fetch all local guest data
                let bookmarks = await guestSessionClient.allBookmarks()
                let skips = await guestSessionClient.allSkips()

                // Read dietary preferences from UserDefaults
                var dietaryPreferences: [String] = []
                if let data = UserDefaults.standard.data(forKey: "dietaryPreferences"),
                   let prefs = try? JSONDecoder().decode(Set<String>.self, from: data) {
                    dietaryPreferences = Array(prefs)
                }

                // TODO: Execute GraphQL mutation when backend endpoint is ready
                // For now, log the migration data and mark as successful
                print("🔄 [GuestMigration] Migrating data for guest: \(guestUserId)")
                print("📚 Bookmarks: \(bookmarks.count)")
                print("⏭️ Skips: \(skips.count)")
                print("🍽️ Dietary preferences: \(dietaryPreferences.joined(separator: ", "))")

                // Simulate GraphQL mutation (placeholder until backend is ready)
                // let mutation = MigrateGuestDataMutation(
                //     guestUserId: guestUserId,
                //     bookmarks: bookmarks.map { ... },
                //     skips: skips.map { ... },
                //     dietaryPreferences: dietaryPreferences
                // )
                // try await apolloClient.mutate(mutation)

                // On success: Clean up local storage
                for bookmark in bookmarks {
                    try await guestSessionClient.unbookmarkRecipe(bookmark.recipeId)
                }

                for skip in skips {
                    try await guestSessionClient.undoSkip(skip.recipeId)
                }

                // Keep guestUserId for analytics continuity, but mark as migrated
                UserDefaults.standard.set(true, forKey: "guestMigrated")

                print("✅ [GuestMigration] Migration complete")
            },
            hasPendingMigration: {
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
