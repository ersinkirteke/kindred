// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct RecipeDetailQuery: GraphQLQuery {
  public static let operationName: String = "RecipeDetail"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query RecipeDetail($id: ID!) { recipe(id: $id) { __typename id name description prepTime cookTime servings calories protein carbs fat imageUrl imageStatus location isViral engagementLoves engagementBookmarks engagementViews dietaryTags difficulty ingredients { __typename name quantity unit orderIndex } steps { __typename orderIndex text duration techniqueTag } } }"#
    ))

  public var id: ID

  public init(id: ID) {
    self.id = id
  }

  @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("recipe", Recipe?.self, arguments: ["id": .variable("id")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      RecipeDetailQuery.Data.self
    ] }

    /// Get a single recipe by ID
    public var recipe: Recipe? { __data["recipe"] }

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
        .field("servings", Int?.self),
        .field("calories", Int?.self),
        .field("protein", Double?.self),
        .field("carbs", Double?.self),
        .field("fat", Double?.self),
        .field("imageUrl", String?.self),
        .field("imageStatus", GraphQLEnum<KindredAPI.ImageStatus>.self),
        .field("location", String.self),
        .field("isViral", Bool.self),
        .field("engagementLoves", Int.self),
        .field("engagementBookmarks", Int.self),
        .field("engagementViews", Int.self),
        .field("dietaryTags", [String].self),
        .field("difficulty", GraphQLEnum<KindredAPI.DifficultyLevel>.self),
        .field("ingredients", [Ingredient].self),
        .field("steps", [Step].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RecipeDetailQuery.Data.Recipe.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var name: String { __data["name"] }
      public var description: String? { __data["description"] }
      public var prepTime: Int { __data["prepTime"] }
      public var cookTime: Int? { __data["cookTime"] }
      public var servings: Int? { __data["servings"] }
      public var calories: Int? { __data["calories"] }
      public var protein: Double? { __data["protein"] }
      public var carbs: Double? { __data["carbs"] }
      public var fat: Double? { __data["fat"] }
      public var imageUrl: String? { __data["imageUrl"] }
      public var imageStatus: GraphQLEnum<KindredAPI.ImageStatus> { __data["imageStatus"] }
      public var location: String { __data["location"] }
      public var isViral: Bool { __data["isViral"] }
      public var engagementLoves: Int { __data["engagementLoves"] }
      public var engagementBookmarks: Int { __data["engagementBookmarks"] }
      public var engagementViews: Int { __data["engagementViews"] }
      public var dietaryTags: [String] { __data["dietaryTags"] }
      public var difficulty: GraphQLEnum<KindredAPI.DifficultyLevel> { __data["difficulty"] }
      public var ingredients: [Ingredient] { __data["ingredients"] }
      public var steps: [Step] { __data["steps"] }

      /// Recipe.Ingredient
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
          RecipeDetailQuery.Data.Recipe.Ingredient.self
        ] }

        public var name: String { __data["name"] }
        public var quantity: String { __data["quantity"] }
        public var unit: String { __data["unit"] }
        public var orderIndex: Int { __data["orderIndex"] }
      }

      /// Recipe.Step
      ///
      /// Parent Type: `RecipeStep`
      public struct Step: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeStep }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("orderIndex", Int.self),
          .field("text", String.self),
          .field("duration", Int?.self),
          .field("techniqueTag", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RecipeDetailQuery.Data.Recipe.Step.self
        ] }

        public var orderIndex: Int { __data["orderIndex"] }
        public var text: String { __data["text"] }
        public var duration: Int? { __data["duration"] }
        public var techniqueTag: String? { __data["techniqueTag"] }
      }
    }
  }
}
