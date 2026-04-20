// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct NarrationUrlQuery: GraphQLQuery {
  public static let operationName: String = "NarrationUrl"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query NarrationUrl($recipeId: String!, $voiceProfileId: String, $locale: String) { narrationUrl( recipeId: $recipeId voiceProfileId: $voiceProfileId locale: $locale ) { __typename url speakerName relationship recipeName durationMs } }"#
    ))

  public var recipeId: String
  public var voiceProfileId: GraphQLNullable<String>
  public var locale: GraphQLNullable<String>

  public init(
    recipeId: String,
    voiceProfileId: GraphQLNullable<String>,
    locale: GraphQLNullable<String>
  ) {
    self.recipeId = recipeId
    self.voiceProfileId = voiceProfileId
    self.locale = locale
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "recipeId": recipeId,
    "voiceProfileId": voiceProfileId,
    "locale": locale
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("narrationUrl", NarrationUrl.self, arguments: [
        "recipeId": .variable("recipeId"),
        "voiceProfileId": .variable("voiceProfileId"),
        "locale": .variable("locale")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      NarrationUrlQuery.Data.self
    ] }

    public var narrationUrl: NarrationUrl { __data["narrationUrl"] }

    /// NarrationUrl
    ///
    /// Parent Type: `NarrationUrlDto`
    public struct NarrationUrl: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.NarrationUrlDto }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("url", String?.self),
        .field("speakerName", String.self),
        .field("relationship", String.self),
        .field("recipeName", String.self),
        .field("durationMs", Int?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        NarrationUrlQuery.Data.NarrationUrl.self
      ] }

      /// R2 CDN URL for cached narration audio, null if not yet generated
      public var url: String? { __data["url"] }
      /// Speaker's name (e.g., 'Mom', 'Nonna Maria')
      public var speakerName: String { __data["speakerName"] }
      /// Relationship to user (e.g., 'Mother', 'Grandmother')
      public var relationship: String { __data["relationship"] }
      /// Recipe name
      public var recipeName: String { __data["recipeName"] }
      /// Audio duration in milliseconds, null if not yet cached
      public var durationMs: Int? { __data["durationMs"] }
    }
  }
}
