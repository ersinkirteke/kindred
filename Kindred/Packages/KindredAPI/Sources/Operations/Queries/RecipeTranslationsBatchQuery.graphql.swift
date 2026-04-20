// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct RecipeTranslationsBatchQuery: GraphQLQuery {
  public static let operationName: String = "RecipeTranslationsBatch"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query RecipeTranslationsBatch($recipeIds: [String!]!, $locale: String!) { recipeTranslations(recipeIds: $recipeIds, locale: $locale) { __typename recipeId name description } }"#
    ))

  public var recipeIds: [String]
  public var locale: String

  public init(
    recipeIds: [String],
    locale: String
  ) {
    self.recipeIds = recipeIds
    self.locale = locale
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "recipeIds": recipeIds,
    "locale": locale
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("recipeTranslations", [RecipeTranslation].self, arguments: [
        "recipeIds": .variable("recipeIds"),
        "locale": .variable("locale")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      RecipeTranslationsBatchQuery.Data.self
    ] }

    /// Batch: cached translations only for a list of recipes. Triggers background generation for uncached ones so subsequent calls return them. Returns only the subset currently cached — callers should fall back to the original (English) name/description for missing ids.
    public var recipeTranslations: [RecipeTranslation] { __data["recipeTranslations"] }

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
        .field("name", String.self),
        .field("description", String?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RecipeTranslationsBatchQuery.Data.RecipeTranslation.self
      ] }

      public var recipeId: String { __data["recipeId"] }
      public var name: String { __data["name"] }
      public var description: String? { __data["description"] }
    }
  }
}
