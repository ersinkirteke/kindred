// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct BulkPantryItemInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    name: String,
    quantity: String,
    source: GraphQLNullable<String> = nil,
    storageLocation: GraphQLNullable<String> = nil,
    unit: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "name": name,
      "quantity": quantity,
      "source": source,
      "storageLocation": storageLocation,
      "unit": unit
    ])
  }

  public var name: String {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var quantity: String {
    get { __data["quantity"] }
    set { __data["quantity"] = newValue }
  }

  public var source: GraphQLNullable<String> {
    get { __data["source"] }
    set { __data["source"] = newValue }
  }

  public var storageLocation: GraphQLNullable<String> {
    get { __data["storageLocation"] }
    set { __data["storageLocation"] = newValue }
  }

  public var unit: GraphQLNullable<String> {
    get { __data["unit"] }
    set { __data["unit"] = newValue }
  }
}
