import Foundation
import SwiftData

@Model
public class GuestBookmark {
    @Attribute(.unique) public var id: UUID
    public var recipeId: String
    public var guestUserId: String
    public var recipeName: String
    public var recipeImageUrl: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        recipeId: String,
        guestUserId: String,
        recipeName: String,
        recipeImageUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.recipeId = recipeId
        self.guestUserId = guestUserId
        self.recipeName = recipeName
        self.recipeImageUrl = recipeImageUrl
        self.createdAt = createdAt
    }
}
