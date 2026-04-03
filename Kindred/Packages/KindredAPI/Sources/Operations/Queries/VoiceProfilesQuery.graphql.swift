// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct VoiceProfilesQuery: GraphQLQuery {
  public static let operationName: String = "VoiceProfiles"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query VoiceProfiles { myVoiceProfiles { __typename id status speakerName relationship createdAt updatedAt } }"#
    ))

  public init() {}

  @_spi(Unsafe) public var __variables: Variables? { nil }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("myVoiceProfiles", [MyVoiceProfile].self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      VoiceProfilesQuery.Data.self
    ] }

    /// Get all voice profiles for the current user
    public var myVoiceProfiles: [MyVoiceProfile] { __data["myVoiceProfiles"] }

    /// MyVoiceProfile
    ///
    /// Parent Type: `VoiceProfile`
    public struct MyVoiceProfile: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.VoiceProfile }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", KindredAPI.ID.self),
        .field("status", KindredAPI.Enums.VoiceStatus.self),
        .field("speakerName", String.self),
        .field("relationship", String.self),
        .field("createdAt", String.self),
        .field("updatedAt", String.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VoiceProfilesQuery.Data.MyVoiceProfile.self
      ] }

      public var id: KindredAPI.ID { __data["id"] }
      public var status: KindredAPI.Enums.VoiceStatus { __data["status"] }
      public var speakerName: String { __data["speakerName"] }
      public var relationship: String { __data["relationship"] }
      public var createdAt: String { __data["createdAt"] }
      public var updatedAt: String { __data["updatedAt"] }
    }
  }
}
