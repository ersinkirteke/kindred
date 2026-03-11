// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct AddPantryItemMutation: GraphQLMutation {
  public static let operationName: String = "AddPantryItem"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AddPantryItem($input: AddPantryItemInput!) { addPantryItem(input: $input) { __typename id name normalizedName quantity unit storageLocation foodCategory photoUrl notes source expiryDate isDeleted createdAt updatedAt } }"#
    ))

  public var input: AddPantryItemInput

  public init(input: AddPantryItemInput) {
    self.input = input
  }

  @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("addPantryItem", AddPantryItem.self, arguments: ["input": .variable("input")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      AddPantryItemMutation.Data.self
    ] }

    /// Add a pantry item with normalization
    public var addPantryItem: AddPantryItem { __data["addPantryItem"] }

    /// AddPantryItem
    ///
    /// Parent Type: `PantryItemModel`
    public struct AddPantryItem: KindredAPI.SelectionSet {
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
        AddPantryItemMutation.Data.AddPantryItem.self
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
