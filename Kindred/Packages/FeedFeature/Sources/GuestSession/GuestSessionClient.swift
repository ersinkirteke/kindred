import Dependencies
import Foundation
import SwiftData

@DependencyClient
public struct GuestSessionClient {
    public var getGuestUserId: @Sendable () -> String = { "" }
    public var bookmarkRecipe: @Sendable (String, String, String?) async throws -> Void
    public var unbookmarkRecipe: @Sendable (String) async throws -> Void
    public var isBookmarked: @Sendable (String) async -> Bool = { _ in false }
    public var skipRecipe: @Sendable (String) async throws -> Void
    public var undoSkip: @Sendable (String) async throws -> Void
    public var bookmarkCount: @Sendable () async -> Int = { 0 }
    public var allBookmarks: @Sendable () async -> [GuestBookmark] = { [] }
}

extension GuestSessionClient: DependencyKey {
    public static var liveValue: GuestSessionClient {
        let store = GuestSessionStore.shared

        return GuestSessionClient(
            getGuestUserId: {
                store.getGuestUserId()
            },
            bookmarkRecipe: { recipeId, recipeName, imageUrl in
                try await store.bookmarkRecipe(recipeId: recipeId, recipeName: recipeName, imageUrl: imageUrl)
            },
            unbookmarkRecipe: { recipeId in
                try await store.unbookmarkRecipe(recipeId: recipeId)
            },
            isBookmarked: { recipeId in
                await store.isBookmarked(recipeId: recipeId)
            },
            skipRecipe: { recipeId in
                try await store.skipRecipe(recipeId: recipeId)
            },
            undoSkip: { recipeId in
                try await store.undoSkip(recipeId: recipeId)
            },
            bookmarkCount: {
                await store.bookmarkCount()
            },
            allBookmarks: {
                await store.allBookmarks()
            }
        )
    }

    public static var testValue: GuestSessionClient {
        return GuestSessionClient(
            getGuestUserId: { "test-guest-id" },
            bookmarkRecipe: { _, _, _ in },
            unbookmarkRecipe: { _ in },
            isBookmarked: { _ in false },
            skipRecipe: { _ in },
            undoSkip: { _ in },
            bookmarkCount: { 0 },
            allBookmarks: { [] }
        )
    }
}

extension DependencyValues {
    public var guestSessionClient: GuestSessionClient {
        get { self[GuestSessionClient.self] }
        set { self[GuestSessionClient.self] = newValue }
    }
}

// MARK: - Guest Session Store

@MainActor
private class GuestSessionStore {
    static let shared = GuestSessionStore()

    private let modelContainer: ModelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            modelContainer = try ModelContainer(for: GuestBookmark.self, GuestSkip.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    func getGuestUserId() -> String {
        let key = "guestUserId"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    func bookmarkRecipe(recipeId: String, recipeName: String, imageUrl: String?) async throws {
        let guestUserId = getGuestUserId()

        // Check if already bookmarked
        let descriptor = FetchDescriptor<GuestBookmark>(
            predicate: #Predicate<GuestBookmark> { bookmark in
                bookmark.recipeId == recipeId && bookmark.guestUserId == guestUserId
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            return // Already bookmarked
        }

        let bookmark = GuestBookmark(
            recipeId: recipeId,
            guestUserId: guestUserId,
            recipeName: recipeName,
            recipeImageUrl: imageUrl
        )

        modelContext.insert(bookmark)
        try modelContext.save()
    }

    func unbookmarkRecipe(recipeId: String) async throws {
        let guestUserId = getGuestUserId()

        let descriptor = FetchDescriptor<GuestBookmark>(
            predicate: #Predicate<GuestBookmark> { bookmark in
                bookmark.recipeId == recipeId && bookmark.guestUserId == guestUserId
            }
        )

        let bookmarks = try modelContext.fetch(descriptor)
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }

        try modelContext.save()
    }

    func isBookmarked(recipeId: String) async -> Bool {
        let guestUserId = getGuestUserId()

        let descriptor = FetchDescriptor<GuestBookmark>(
            predicate: #Predicate<GuestBookmark> { bookmark in
                bookmark.recipeId == recipeId && bookmark.guestUserId == guestUserId
            }
        )

        do {
            let bookmarks = try modelContext.fetch(descriptor)
            return !bookmarks.isEmpty
        } catch {
            return false
        }
    }

    func skipRecipe(recipeId: String) async throws {
        let guestUserId = getGuestUserId()

        // Check if already skipped
        let descriptor = FetchDescriptor<GuestSkip>(
            predicate: #Predicate<GuestSkip> { skip in
                skip.recipeId == recipeId && skip.guestUserId == guestUserId
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if !existing.isEmpty {
            return // Already skipped
        }

        let skip = GuestSkip(
            recipeId: recipeId,
            guestUserId: guestUserId
        )

        modelContext.insert(skip)
        try modelContext.save()
    }

    func undoSkip(recipeId: String) async throws {
        let guestUserId = getGuestUserId()

        let descriptor = FetchDescriptor<GuestSkip>(
            predicate: #Predicate<GuestSkip> { skip in
                skip.recipeId == recipeId && skip.guestUserId == guestUserId
            }
        )

        let skips = try modelContext.fetch(descriptor)
        for skip in skips {
            modelContext.delete(skip)
        }

        try modelContext.save()
    }

    func bookmarkCount() async -> Int {
        let guestUserId = getGuestUserId()

        let descriptor = FetchDescriptor<GuestBookmark>(
            predicate: #Predicate<GuestBookmark> { bookmark in
                bookmark.guestUserId == guestUserId
            }
        )

        do {
            let bookmarks = try modelContext.fetch(descriptor)
            return bookmarks.count
        } catch {
            return 0
        }
    }

    func allBookmarks() async -> [GuestBookmark] {
        let guestUserId = getGuestUserId()

        let descriptor = FetchDescriptor<GuestBookmark>(
            predicate: #Predicate<GuestBookmark> { bookmark in
                bookmark.guestUserId == guestUserId
            },
            sortBy: [SortDescriptor(\GuestBookmark.createdAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
}
