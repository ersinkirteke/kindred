// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct UpdatePantryItemInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    expiryDate: GraphQLNullable<DateTime> = nil,
    foodCategory: GraphQLNullable<String> = nil,
    name: GraphQLNullable<String> = nil,
    notes: GraphQLNullable<String> = nil,
    quantity: GraphQLNullable<String> = nil,
    storageLocation: GraphQLNullable<String> = nil,
    unit: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "expiryDate": expiryDate,
      "foodCategory": foodCategory,
      "name": name,
      "notes": notes,
      "quantity": quantity,
      "storageLocation": storageLocation,
      "unit": unit
    ])
  }

  public var expiryDate: GraphQLNullable<DateTime> {
    get { __data["expiryDate"] }
    set { __data["expiryDate"] = newValue }
  }

  public var foodCategory: GraphQLNullable<String> {
    get { __data["foodCategory"] }
    set { __data["foodCategory"] = newValue }
  }

  public var name: GraphQLNullable<String> {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var notes: GraphQLNullable<String> {
    get { __data["notes"] }
    set { __data["notes"] = newValue }
  }

  public var quantity: GraphQLNullable<String> {
    get { __data["quantity"] }
    set { __data["quantity"] = newValue }
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
