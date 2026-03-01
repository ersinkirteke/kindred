// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct HealthCheckQuery: GraphQLQuery {
  public static let operationName: String = "HealthCheck"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query HealthCheck { health dbHealth }"#
    ))

  public init() {}

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("health", String.self),
      .field("dbHealth", Bool.self),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      HealthCheckQuery.Data.self
    ] }

    /// Basic health check - returns "ok" if service is running
    public var health: String { __data["health"] }
    /// Database health check - returns true if database is accessible
    public var dbHealth: Bool { __data["dbHealth"] }
  }
}
