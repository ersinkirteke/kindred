import Foundation
import SwiftData

@Model
public class GuestSkip {
    @Attribute(.unique) public var id: UUID
    public var recipeId: String
    public var guestUserId: String
    public var cuisineType: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        recipeId: String,
        guestUserId: String,
        cuisineType: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.recipeId = recipeId
        self.guestUserId = guestUserId
        self.cuisineType = cuisineType
        self.createdAt = createdAt
    }
}
