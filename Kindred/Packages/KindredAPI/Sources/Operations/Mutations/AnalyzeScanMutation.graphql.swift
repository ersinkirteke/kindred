// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct AnalyzeScanMutation: GraphQLMutation {
  public static let operationName: String = "AnalyzeScan"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation AnalyzeScan($jobId: String!, $userId: String!) { analyzeScan(jobId: $jobId, userId: $userId) { __typename jobId scanType items { __typename name quantity category storageLocation estimatedExpiryDays confidence } } }"#
    ))

  public var jobId: String
  public var userId: String

  public init(
    jobId: String,
    userId: String
  ) {
    self.jobId = jobId
    self.userId = userId
  }

  @_spi(Unsafe) public var __variables: Variables? {
    ["jobId": jobId, "userId": userId]
  }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Mutation }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("analyzeScan", AnalyzeScan.self, arguments: [
        "jobId": .variable("jobId"),
        "userId": .variable("userId")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      AnalyzeScanMutation.Data.self
    ] }

    public var analyzeScan: AnalyzeScan { __data["analyzeScan"] }

    /// AnalyzeScan
    ///
    /// Parent Type: `ScanResultResponse`
    public struct AnalyzeScan: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.ScanResultResponse }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("jobId", String.self),
        .field("scanType", String.self),
        .field("items", [Item].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AnalyzeScanMutation.Data.AnalyzeScan.self
      ] }

      public var __typename: String { __data["__typename"] }
      public var jobId: String { __data["jobId"] }
      public var scanType: String { __data["scanType"] }
      public var items: [Item] { __data["items"] }

      /// AnalyzeScan.Item
      ///
      /// Parent Type: `DetectedItemDto`
      public struct Item: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.DetectedItemDto }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("name", String.self),
          .field("quantity", String.self),
          .field("category", String.self),
          .field("storageLocation", String.self),
          .field("estimatedExpiryDays", Int.self),
          .field("confidence", Int.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AnalyzeScanMutation.Data.AnalyzeScan.Item.self
        ] }

        public var __typename: String { __data["__typename"] }
        public var name: String { __data["name"] }
        public var quantity: String { __data["quantity"] }
        public var category: String { __data["category"] }
        public var storageLocation: String { __data["storageLocation"] }
        public var estimatedExpiryDays: Int { __data["estimatedExpiryDays"] }
        public var confidence: Int { __data["confidence"] }
      }
    }
  }
}
