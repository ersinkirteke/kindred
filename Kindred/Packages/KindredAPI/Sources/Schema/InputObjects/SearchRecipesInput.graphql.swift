// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct SearchRecipesInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    after: GraphQLNullable<String> = nil,
    cuisines: GraphQLNullable<[String]> = nil,
    diets: GraphQLNullable<[String]> = nil,
    first: GraphQLNullable<Int32> = nil,
    intolerances: GraphQLNullable<[String]> = nil,
    query: GraphQLNullable<String> = nil
  ) {
    __data = InputDict([
      "after": after,
      "cuisines": cuisines,
      "diets": diets,
      "first": first,
      "intolerances": intolerances,
      "query": query
    ])
  }

  /// Cursor for pagination (base64 encoded offset)
  public var after: GraphQLNullable<String> {
    get { __data["after"] }
    set { __data["after"] = newValue }
  }

  /// Cuisine types to filter by
  public var cuisines: GraphQLNullable<[String]> {
    get { __data["cuisines"] }
    set { __data["cuisines"] = newValue }
  }

  /// Diet types to filter by (e.g., vegetarian, vegan, keto)
  public var diets: GraphQLNullable<[String]> {
    get { __data["diets"] }
    set { __data["diets"] = newValue }
  }

  /// Number of results to return
  public var first: GraphQLNullable<Int32> {
    get { __data["first"] }
    set { __data["first"] = newValue }
  }

  /// Intolerances to exclude (e.g., gluten, dairy, nuts)
  public var intolerances: GraphQLNullable<[String]> {
    get { __data["intolerances"] }
    set { __data["intolerances"] = newValue }
  }

  /// Search query for recipe name or ingredients
  public var query: GraphQLNullable<String> {
    get { __data["query"] }
    set { __data["query"] = newValue }
  }
}
