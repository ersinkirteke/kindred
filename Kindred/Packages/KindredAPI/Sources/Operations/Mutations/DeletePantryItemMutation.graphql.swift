// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct DeletePantryItemMutation: GraphQLMutation {
  public static let operationName: String = "DeletePantryItem"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation DeletePantryItem($id: String!, $userId: String!) { deletePantryItem(id: $id, userId: $userId) { __typename id isDeleted updatedAt } }"#
    ))

  public var id: String
  public var userId: String

  public init(
    id: String,
    userId: String
  ) {
    self.id = id
    self.userId = userId
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "id": id,
    "userId": userId
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("deletePantryItem", DeletePantryItem.self, arguments: [
        "id": .variable("id"),
        "userId": .variable("userId")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      DeletePantryItemMutation.Data.self
    ] }

    /// Soft delete a pantry item
    public var deletePantryItem: DeletePantryItem { __data["deletePantryItem"] }

    /// DeletePantryItem
    ///
    /// Parent Type: `PantryItemModel`
    public struct DeletePantryItem: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.PantryItemModel }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("isDeleted", Bool.self),
        .field("updatedAt", KindredAPI.DateTime.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeletePantryItemMutation.Data.DeletePantryItem.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var isDeleted: Bool { __data["isDeleted"] }
      public var updatedAt: KindredAPI.DateTime { __data["updatedAt"] }
    }
  }
}
