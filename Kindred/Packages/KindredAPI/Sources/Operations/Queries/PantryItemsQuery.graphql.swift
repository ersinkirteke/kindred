// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct PantryItemsQuery: GraphQLQuery {
  public static let operationName: String = "PantryItems"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query PantryItems($userId: String!, $sinceTimestamp: DateTime) { pantryItems(userId: $userId, sinceTimestamp: $sinceTimestamp) { __typename id name normalizedName quantity unit storageLocation foodCategory photoUrl notes source expiryDate isDeleted createdAt updatedAt } }"#
    ))

  public var userId: String
  public var sinceTimestamp: GraphQLNullable<DateTime>

  public init(
    userId: String,
    sinceTimestamp: GraphQLNullable<DateTime>
  ) {
    self.userId = userId
    self.sinceTimestamp = sinceTimestamp
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "userId": userId,
    "sinceTimestamp": sinceTimestamp
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("pantryItems", [PantryItem].self, arguments: [
        "userId": .variable("userId"),
        "sinceTimestamp": .variable("sinceTimestamp")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      PantryItemsQuery.Data.self
    ] }

    /// Get all pantry items for user
    public var pantryItems: [PantryItem] { __data["pantryItems"] }

    /// PantryItem
    ///
    /// Parent Type: `PantryItemModel`
    public struct PantryItem: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.PantryItemModel }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("name", String.self),
        .field("normalizedName", String?.self),
        .field("quantity", String.self),
        .field("unit", String?.self),
        .field("storageLocation", String.self),
        .field("foodCategory", String?.self),
        .field("photoUrl", String?.self),
        .field("notes", String?.self),
        .field("source", String.self),
        .field("expiryDate", KindredAPI.DateTime?.self),
        .field("isDeleted", Bool.self),
        .field("createdAt", KindredAPI.DateTime.self),
        .field("updatedAt", KindredAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PantryItemsQuery.Data.PantryItem.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var name: String { __data["name"] }
      public var normalizedName: String? { __data["normalizedName"] }
      public var quantity: String { __data["quantity"] }
      public var unit: String? { __data["unit"] }
      public var storageLocation: String { __data["storageLocation"] }
      public var foodCategory: String? { __data["foodCategory"] }
      public var photoUrl: String? { __data["photoUrl"] }
      public var notes: String? { __data["notes"] }
      public var source: String { __data["source"] }
      public var expiryDate: KindredAPI.DateTime? { __data["expiryDate"] }
      public var isDeleted: Bool { __data["isDeleted"] }
      public var createdAt: KindredAPI.DateTime { __data["createdAt"] }
      public var updatedAt: KindredAPI.DateTime { __data["updatedAt"] }
    }
  }
}
