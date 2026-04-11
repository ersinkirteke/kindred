// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct UpdatePantryItemMutation: GraphQLMutation {
  public static let operationName: String = "UpdatePantryItem"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UpdatePantryItem($id: String!, $userId: String!, $input: UpdatePantryItemInput!) { updatePantryItem(id: $id, userId: $userId, input: $input) { __typename id name normalizedName quantity unit storageLocation foodCategory photoUrl notes expiryDate updatedAt } }"#
    ))

  public var id: String
  public var userId: String
  public var input: UpdatePantryItemInput

  public init(
    id: String,
    userId: String,
    input: UpdatePantryItemInput
  ) {
    self.id = id
    self.userId = userId
    self.input = input
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "id": id,
    "userId": userId,
    "input": input
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    #warning("Argument 'userId' of field 'updatePantryItem' is deprecated. Reason: 'Derived from auth token'")
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("updatePantryItem", UpdatePantryItem.self, arguments: [
        "id": .variable("id"),
        "userId": .variable("userId"),
        "input": .variable("input")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      UpdatePantryItemMutation.Data.self
    ] }

    /// Update a pantry item
    public var updatePantryItem: UpdatePantryItem { __data["updatePantryItem"] }

    /// UpdatePantryItem
    ///
    /// Parent Type: `PantryItemModel`
    public struct UpdatePantryItem: KindredAPI.SelectionSet {
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
        .field("expiryDate", KindredAPI.DateTime?.self),
        .field("updatedAt", KindredAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdatePantryItemMutation.Data.UpdatePantryItem.self
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
      public var expiryDate: KindredAPI.DateTime? { __data["expiryDate"] }
      public var updatedAt: KindredAPI.DateTime { __data["updatedAt"] }
    }
  }
}
