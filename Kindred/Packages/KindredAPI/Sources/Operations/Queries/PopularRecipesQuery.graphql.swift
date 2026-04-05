// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct PopularRecipesQuery: GraphQLQuery {
  public static let operationName: String = "PopularRecipes"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query PopularRecipes($first: Int, $after: String) { popularRecipes(first: $first, after: $after) { __typename edges { __typename node { __typename id name description prepTime cookTime calories imageUrl imageStatus popularityScore engagementLoves dietaryTags difficulty cuisineType ingredients { __typename name quantity unit orderIndex } } cursor } pageInfo { __typename hasNextPage endCursor } totalCount } }"#
    ))

  public var first: GraphQLNullable<Int32>
  public var after: GraphQLNullable<String>

  public init(
    first: GraphQLNullable<Int32>,
    after: GraphQLNullable<String>
  ) {
    self.first = first
    self.after = after
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "first": first,
    "after": after
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("popularRecipes", PopularRecipes.self, arguments: [
        "first": .variable("first"),
        "after": .variable("after")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      PopularRecipesQuery.Data.self
    ] }

    /// Get popular recipes sorted by popularity score (pre-warmed cache)
    public var popularRecipes: PopularRecipes { __data["popularRecipes"] }

    /// PopularRecipes
    ///
    /// Parent Type: `RecipeConnection`
    public struct PopularRecipes: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeConnection }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("edges", [Edge].self),
        .field("pageInfo", PageInfo.self),
        .field("totalCount", Int.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PopularRecipesQuery.Data.PopularRecipes.self
      ] }

      public var edges: [Edge] { __data["edges"] }
      public var pageInfo: PageInfo { __data["pageInfo"] }
      public var totalCount: Int { __data["totalCount"] }

      /// PopularRecipes.Edge
      ///
      /// Parent Type: `RecipeCardEdge`
      public struct Edge: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeCardEdge }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("node", Node.self),
          .field("cursor", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PopularRecipesQuery.Data.PopularRecipes.Edge.self
        ] }

        public var node: Node { __data["node"] }
        public var cursor: String { __data["cursor"] }

        /// PopularRecipes.Edge.Node
        ///
        /// Parent Type: `RecipeCard`
        public struct Node: KindredAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeCard }
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
            .field("popularityScore", Int?.self),
            .field("engagementLoves", Int.self),
            .field("dietaryTags", [String]?.self),
            .field("difficulty", GraphQLEnum<KindredAPI.DifficultyLevel>?.self),
            .field("cuisineType", GraphQLEnum<KindredAPI.CuisineType>.self),
            .field("ingredients", [Ingredient]?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PopularRecipesQuery.Data.PopularRecipes.Edge.Node.self
          ] }

          public var id: KindredAPI.ID { __data["id"] }
          public var name: String { __data["name"] }
          public var description: String? { __data["description"] }
          public var prepTime: Int { __data["prepTime"] }
          public var cookTime: Int? { __data["cookTime"] }
          public var calories: Int? { __data["calories"] }
          public var imageUrl: String? { __data["imageUrl"] }
          public var imageStatus: GraphQLEnum<KindredAPI.ImageStatus> { __data["imageStatus"] }
          public var popularityScore: Int? { __data["popularityScore"] }
          public var engagementLoves: Int { __data["engagementLoves"] }
          public var dietaryTags: [String]? { __data["dietaryTags"] }
          public var difficulty: GraphQLEnum<KindredAPI.DifficultyLevel>? { __data["difficulty"] }
          public var cuisineType: GraphQLEnum<KindredAPI.CuisineType> { __data["cuisineType"] }
          public var ingredients: [Ingredient]? { __data["ingredients"] }

          /// PopularRecipes.Edge.Node.Ingredient
          ///
          /// Parent Type: `Ingredient`
          public struct Ingredient: KindredAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Ingredient }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("name", String.self),
              .field("quantity", String.self),
              .field("unit", String.self),
              .field("orderIndex", Int.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              PopularRecipesQuery.Data.PopularRecipes.Edge.Node.Ingredient.self
            ] }

            public var name: String { __data["name"] }
            public var quantity: String { __data["quantity"] }
            public var unit: String { __data["unit"] }
            public var orderIndex: Int { __data["orderIndex"] }
          }
        }
      }

      /// PopularRecipes.PageInfo
      ///
      /// Parent Type: `PageInfo`
      public struct PageInfo: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.PageInfo }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("hasNextPage", Bool.self),
          .field("endCursor", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PopularRecipesQuery.Data.PopularRecipes.PageInfo.self
        ] }

        public var hasNextPage: Bool { __data["hasNextPage"] }
        public var endCursor: String? { __data["endCursor"] }
      }
    }
  }
}
