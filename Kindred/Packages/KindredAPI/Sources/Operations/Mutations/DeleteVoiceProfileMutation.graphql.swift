// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct DeleteVoiceProfileMutation: GraphQLMutation {
  public static let operationName: String = "DeleteVoiceProfile"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation DeleteVoiceProfile($id: String!) { deleteVoiceProfile(id: $id) { __typename id status } }"#
    ))

  public var id: String

  public init(id: String) {
    self.id = id
  }

  public var __variables: Variables? { ["id": id] }

  public struct Data: KindredAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.VoiceProfile }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("deleteVoiceProfile", DeleteVoiceProfile.self, arguments: ["id": .variable("id")]),
    ] }

    public var deleteVoiceProfile: DeleteVoiceProfile { __data["deleteVoiceProfile"] }

    public struct DeleteVoiceProfile: KindredAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.VoiceProfile }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("status", GraphQLEnum<KindredAPI.VoiceStatus>.self),
      ] }

      public var id: String { __data["id"] }
      public var status: GraphQLEnum<KindredAPI.VoiceStatus> { __data["status"] }
    }
  }
}
