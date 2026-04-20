// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct RecipeTranslationQuery: GraphQLQuery {
  public static let operationName: String = "RecipeTranslation"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query RecipeTranslation($recipeId: String!, $locale: String!) { recipeTranslation(recipeId: $recipeId, locale: $locale) { __typename recipeId locale name description ingredients { __typename name quantity unit } steps { __typename orderIndex text } } }"#
    ))

  public var recipeId: String
  public var locale: String

  public init(
    recipeId: String,
    locale: String
  ) {
    self.recipeId = recipeId
    self.locale = locale
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "recipeId": recipeId,
    "locale": locale
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("recipeTranslation", RecipeTranslation?.self, arguments: [
        "recipeId": .variable("recipeId"),
        "locale": .variable("locale")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      RecipeTranslationQuery.Data.self
    ] }

    /// Gemini-translated recipe content in the given locale. Returns null for English or when translation is unavailable.
    public var recipeTranslation: RecipeTranslation? { __data["recipeTranslation"] }

    /// RecipeTranslation
    ///
    /// Parent Type: `RecipeTranslation`
    public struct RecipeTranslation: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeTranslation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("recipeId", String.self),
        .field("locale", String.self),
        .field("name", String.self),
        .field("description", String?.self),
        .field("ingredients", [Ingredient].self),
        .field("steps", [Step].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RecipeTranslationQuery.Data.RecipeTranslation.self
      ] }

      public var recipeId: String { __data["recipeId"] }
      public var locale: String { __data["locale"] }
      public var name: String { __data["name"] }
      public var description: String? { __data["description"] }
      public var ingredients: [Ingredient] { __data["ingredients"] }
      public var steps: [Step] { __data["steps"] }

      /// RecipeTranslation.Ingredient
      ///
      /// Parent Type: `TranslatedIngredient`
      public struct Ingredient: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.TranslatedIngredient }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("quantity", String.self),
          .field("unit", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RecipeTranslationQuery.Data.RecipeTranslation.Ingredient.self
        ] }

        public var name: String { __data["name"] }
        public var quantity: String { __data["quantity"] }
        public var unit: String { __data["unit"] }
      }

      /// RecipeTranslation.Step
      ///
      /// Parent Type: `TranslatedStep`
      public struct Step: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.TranslatedStep }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("orderIndex", Int.self),
          .field("text", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RecipeTranslationQuery.Data.RecipeTranslation.Step.self
        ] }

        public var orderIndex: Int { __data["orderIndex"] }
        public var text: String { __data["text"] }
      }
    }
  }
}
