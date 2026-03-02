// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct ViralRecipesQuery: GraphQLQuery {
  public static let operationName: String = "ViralRecipes"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ViralRecipes($location: String!) { viralRecipes(location: $location) { __typename id name description prepTime cookTime calories imageUrl imageStatus location isViral engagementLoves engagementBookmarks dietaryTags difficulty cuisineType ingredients { __typename name quantity unit orderIndex } } }"#
    ))

  public var location: String

  public init(location: String) {
    self.location = location
  }

  @_spi(Unsafe) public var __variables: Variables? { ["location": location] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("viralRecipes", [ViralRecipe].self, arguments: ["location": .variable("location")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ViralRecipesQuery.Data.self
    ] }

    /// Get viral recipes for a specific location
    public var viralRecipes: [ViralRecipe] { __data["viralRecipes"] }

    /// ViralRecipe
    ///
    /// Parent Type: `Recipe`
    public struct ViralRecipe: KindredAPI.SelectionSet {
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
        .field("cuisineType", GraphQLEnum<KindredAPI.CuisineType>.self),
        .field("ingredients", [Ingredient].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ViralRecipesQuery.Data.ViralRecipe.self
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
      public var cuisineType: GraphQLEnum<KindredAPI.CuisineType> { __data["cuisineType"] }
      public var ingredients: [Ingredient] { __data["ingredients"] }

      /// ViralRecipe.Ingredient
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
          ViralRecipesQuery.Data.ViralRecipe.Ingredient.self
        ] }

        public var name: String { __data["name"] }
        public var quantity: String { __data["quantity"] }
        public var unit: String { __data["unit"] }
        public var orderIndex: Int { __data["orderIndex"] }
      }
    }
  }
}
