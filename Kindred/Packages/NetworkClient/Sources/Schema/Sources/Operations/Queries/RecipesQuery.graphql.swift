// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct RecipesQuery: GraphQLQuery {
  public static let operationName: String = "Recipes"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query Recipes($location: String, $limit: Int, $offset: Int) { recipes(location: $location, limit: $limit, offset: $offset) { __typename id name description prepTime cookTime calories imageUrl imageStatus location isViral engagementLoves engagementBookmarks dietaryTags difficulty } }"#
    ))

  public var location: GraphQLNullable<String>
  public var limit: GraphQLNullable<Int32>
  public var offset: GraphQLNullable<Int32>

  public init(
    location: GraphQLNullable<String>,
    limit: GraphQLNullable<Int32>,
    offset: GraphQLNullable<Int32>
  ) {
    self.location = location
    self.limit = limit
    self.offset = offset
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "location": location,
    "limit": limit,
    "offset": offset
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("recipes", [Recipe].self, arguments: [
        "location": .variable("location"),
        "limit": .variable("limit"),
        "offset": .variable("offset")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      RecipesQuery.Data.self
    ] }

    /// Get all recipes with optional location filter and pagination
    public var recipes: [Recipe] { __data["recipes"] }

    /// Recipe
    ///
    /// Parent Type: `Recipe`
    public struct Recipe: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Recipe }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("name", String.self),
        .field("description", String?.self),
        .field("prepTime", Int.self),
        .field("cookTime", Int?.self),
        .field("calories", Int?.self),
        .field("imageUrl", String?.self),
        .field("imageStatus", GraphQLEnum<KindredAPI.ImageStatus>.self),
        .field("location", String.self),
        .field("isViral", Bool.self),
        .field("engagementLoves", Int.self),
        .field("engagementBookmarks", Int.self),
        .field("dietaryTags", [String].self),
        .field("difficulty", GraphQLEnum<KindredAPI.DifficultyLevel>.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RecipesQuery.Data.Recipe.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String? { __data["description"] }
      public var prepTime: Int { __data["prepTime"] }
      public var cookTime: Int? { __data["cookTime"] }
      public var calories: Int? { __data["calories"] }
      public var imageUrl: String? { __data["imageUrl"] }
      public var imageStatus: GraphQLEnum<KindredAPI.ImageStatus> { __data["imageStatus"] }
      public var location: String { __data["location"] }
      public var isViral: Bool { __data["isViral"] }
      public var engagementLoves: Int { __data["engagementLoves"] }
      public var engagementBookmarks: Int { __data["engagementBookmarks"] }
      public var dietaryTags: [String] { __data["dietaryTags"] }
      public var difficulty: GraphQLEnum<KindredAPI.DifficultyLevel> { __data["difficulty"] }
    }
  }
}
