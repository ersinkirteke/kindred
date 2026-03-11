// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct AddPantryItemInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    expiryDate: GraphQLNullable<DateTime> = nil,
    foodCategory: GraphQLNullable<String> = nil,
    name: String,
    notes: GraphQLNullable<String> = nil,
    quantity: String,
    source: GraphQLNullable<String> = nil,
    storageLocation: String,
    unit: GraphQLNullable<String> = nil,
    userId: String
  ) {
    __data = InputDict([
      "expiryDate": expiryDate,
      "foodCategory": foodCategory,
      "name": name,
      "notes": notes,
      "quantity": quantity,
      "source": source,
      "storageLocation": storageLocation,
      "unit": unit,
      "userId": userId
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

  public var name: String {
    get { __data["name"] }
    set { __data["name"] = newValue }
  }

  public var notes: GraphQLNullable<String> {
    get { __data["notes"] }
    set { __data["notes"] = newValue }
  }

  public var quantity: String {
    get { __data["quantity"] }
    set { __data["quantity"] = newValue }
  }

  public var source: GraphQLNullable<String> {
    get { __data["source"] }
    set { __data["source"] = newValue }
  }

  public var storageLocation: String {
    get { __data["storageLocation"] }
    set { __data["storageLocation"] = newValue }
  }

  public var unit: GraphQLNullable<String> {
    get { __data["unit"] }
    set { __data["unit"] = newValue }
  }

  public var userId: String {
    get { __data["userId"] }
    set { __data["userId"] = newValue }
  }
}
