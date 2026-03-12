// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct UploadScanPhotoMutation: GraphQLMutation {
  public static let operationName: String = "UploadScanPhoto"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation UploadScanPhoto($userId: String!, $scanType: ScanType!, $photoData: String!) { uploadScanPhoto(userId: $userId, scanType: $scanType, photoData: $photoData) { __typename id status photoUrl scanType createdAt } }"#
    ))

  public var userId: String
  public var scanType: GraphQLEnum<ScanType>
  public var photoData: String

  public init(
    userId: String,
    scanType: GraphQLEnum<ScanType>,
    photoData: String
  ) {
    self.userId = userId
    self.scanType = scanType
    self.photoData = photoData
  }

  @_spi(Unsafe) public var __variables: Variables? {
    ["userId": userId, "scanType": scanType, "photoData": photoData]
  }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("uploadScanPhoto", UploadScanPhoto.self, arguments: [
        "userId": .variable("userId"),
        "scanType": .variable("scanType"),
        "photoData": .variable("photoData")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      UploadScanPhotoMutation.Data.self
    ] }

    /// Upload a scan photo for AI processing
    public var uploadScanPhoto: UploadScanPhoto { __data["uploadScanPhoto"] }

    /// UploadScanPhoto
    ///
    /// Parent Type: `ScanJobResponse`
    public struct UploadScanPhoto: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.ScanJobResponse }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", String.self),
        .field("status", GraphQLEnum<KindredAPI.ScanJobStatus>.self),
        .field("photoUrl", String.self),
        .field("scanType", GraphQLEnum<KindredAPI.ScanType>.self),
        .field("createdAt", String.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UploadScanPhotoMutation.Data.UploadScanPhoto.self
      ] }

      public var __typename: String { __data["__typename"] }
      public var id: String { __data["id"] }
      public var status: GraphQLEnum<KindredAPI.ScanJobStatus> { __data["status"] }
      public var photoUrl: String { __data["photoUrl"] }
      public var scanType: GraphQLEnum<KindredAPI.ScanType> { __data["scanType"] }
      public var createdAt: String { __data["createdAt"] }
    }
  }
}
