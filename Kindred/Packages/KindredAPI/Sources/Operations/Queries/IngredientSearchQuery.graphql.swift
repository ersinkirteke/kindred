// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct IngredientSearchQuery: GraphQLQuery {
  public static let operationName: String = "IngredientSearch"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query IngredientSearch($query: String!, $lang: String = "en") { ingredientSearch(query: $query, lang: $lang) { __typename id canonicalName canonicalNameTR aliases defaultCategory defaultShelfLifeDays } }"#
    ))

  public var query: String
  public var lang: GraphQLNullable<String>

  public init(
    query: String,
    lang: GraphQLNullable<String> = "en"
  ) {
    self.query = query
    self.lang = lang
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "query": query,
    "lang": lang
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("ingredientSearch", [IngredientSearch].self, arguments: [
        "query": .variable("query"),
        "lang": .variable("lang")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      IngredientSearchQuery.Data.self
    ] }

    /// Search ingredient catalog
    public var ingredientSearch: [IngredientSearch] { __data["ingredientSearch"] }

    /// IngredientSearch
    ///
    /// Parent Type: `IngredientCatalogEntry`
    public struct IngredientSearch: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.IngredientCatalogEntry }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("canonicalName", String.self),
        .field("canonicalNameTR", String.self),
        .field("aliases", [String].self),
        .field("defaultCategory", String.self),
        .field("defaultShelfLifeDays", Double?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        IngredientSearchQuery.Data.IngredientSearch.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var canonicalName: String { __data["canonicalName"] }
      public var canonicalNameTR: String { __data["canonicalNameTR"] }
      public var aliases: [String] { __data["aliases"] }
      public var defaultCategory: String { __data["defaultCategory"] }
      public var defaultShelfLifeDays: Double? { __data["defaultShelfLifeDays"] }
    }
  }
}
