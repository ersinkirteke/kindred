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

  @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("deleteVoiceProfile", DeleteVoiceProfile.self, arguments: ["id": .variable("id")]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      DeleteVoiceProfileMutation.Data.self
    ] }

    public var deleteVoiceProfile: DeleteVoiceProfile { __data["deleteVoiceProfile"] }

    /// DeleteVoiceProfile
    ///
    /// Parent Type: `VoiceProfile`
    public struct DeleteVoiceProfile: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.VoiceProfile }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("status", GraphQLEnum<KindredAPI.VoiceStatus>.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteVoiceProfileMutation.Data.DeleteVoiceProfile.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var status: GraphQLEnum<KindredAPI.VoiceStatus> { __data["status"] }
    }
  }
}
