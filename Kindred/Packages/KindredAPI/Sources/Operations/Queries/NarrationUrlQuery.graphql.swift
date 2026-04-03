// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct NarrationUrlQuery: GraphQLQuery {
  public static let operationName: String = "NarrationUrl"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query NarrationUrl($recipeId: ID!, $voiceProfileId: String) { narrationUrl(recipeId: $recipeId, voiceProfileId: $voiceProfileId) { __typename url speakerName relationship recipeName durationMs } }"#
    ))

  public var recipeId: ID
  public var voiceProfileId: String?

  public init(recipeId: ID, voiceProfileId: String? = nil) {
    self.recipeId = recipeId
    self.voiceProfileId = voiceProfileId
  }

  @_spi(Unsafe) public var __variables: Variables? {
    var vars = ["recipeId": recipeId]
    if let voiceProfileId = voiceProfileId {
      vars["voiceProfileId"] = voiceProfileId
    }
    return vars
  }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("narrationUrl", NarrationUrl.self, arguments: [
        "recipeId": .variable("recipeId"),
        "voiceProfileId": .variable("voiceProfileId")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      NarrationUrlQuery.Data.self
    ] }

    /// Get cached narration URL with metadata
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

      public var url: String? { __data["url"] }
      public var speakerName: String { __data["speakerName"] }
      public var relationship: String { __data["relationship"] }
      public var recipeName: String { __data["recipeName"] }
      public var durationMs: Int? { __data["durationMs"] }
    }
  }
}
