// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct PrewarmNarrationMutation: GraphQLMutation {
  public static let operationName: String = "PrewarmNarration"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation PrewarmNarration($recipeId: String!, $voiceProfileId: String!, $locale: String) { prewarmNarration( recipeId: $recipeId voiceProfileId: $voiceProfileId locale: $locale ) }"#
    ))

  public var recipeId: String
  public var voiceProfileId: String
  public var locale: GraphQLNullable<String>

  public init(
    recipeId: String,
    voiceProfileId: String,
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

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("prewarmNarration", Bool.self, arguments: [
        "recipeId": .variable("recipeId"),
        "voiceProfileId": .variable("voiceProfileId"),
        "locale": .variable("locale")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      PrewarmNarrationMutation.Data.self
    ] }

    public var prewarmNarration: Bool { __data["prewarmNarration"] }
  }
}
