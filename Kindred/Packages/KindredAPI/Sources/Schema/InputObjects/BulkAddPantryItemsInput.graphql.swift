// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct BulkAddPantryItemsInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    items: [BulkPantryItemInput],
    userId: String
  ) {
    __data = InputDict([
      "items": items,
      "userId": userId
    ])
  }

  public var items: [BulkPantryItemInput] {
    get { __data["items"] }
    set { __data["items"] = newValue }
  }

  public var userId: String {
    get { __data["userId"] }
    set { __data["userId"] = newValue }
  }
}
