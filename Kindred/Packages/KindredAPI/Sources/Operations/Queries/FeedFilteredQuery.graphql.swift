// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public struct FeedFilteredQuery: GraphQLQuery {
  public static let operationName: String = "FeedFiltered"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query FeedFiltered($latitude: Float!, $longitude: Float!, $first: Int, $after: String, $filters: FeedFiltersInput, $lastFetchedAt: String) { feed( latitude: $latitude longitude: $longitude first: $first after: $after filters: $filters lastFetchedAt: $lastFetchedAt ) { __typename edges { __typename node { __typename id name imageUrl imageStatus prepTime calories engagementLoves engagementHumanized isViral cuisineType mealType velocityScore distanceMiles } cursor } pageInfo { __typename hasNextPage endCursor } totalCount newSinceLastFetch } }"#
    ))

  public var latitude: Double
  public var longitude: Double
  public var first: GraphQLNullable<Int32>
  public var after: GraphQLNullable<String>
  public var filters: GraphQLNullable<FeedFiltersInput>
  public var lastFetchedAt: GraphQLNullable<String>

  public init(
    latitude: Double,
    longitude: Double,
    first: GraphQLNullable<Int32>,
    after: GraphQLNullable<String>,
    filters: GraphQLNullable<FeedFiltersInput>,
    lastFetchedAt: GraphQLNullable<String>
  ) {
    self.latitude = latitude
    self.longitude = longitude
    self.first = first
    self.after = after
    self.filters = filters
    self.lastFetchedAt = lastFetchedAt
  }

  @_spi(Unsafe) public var __variables: Variables? { [
    "latitude": latitude,
    "longitude": longitude,
    "first": first,
    "after": after,
    "filters": filters,
    "lastFetchedAt": lastFetchedAt
  ] }

  public struct Data: KindredAPI.SelectionSet {
    @_spi(Unsafe) public let __data: DataDict
    @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

    @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.Query }
    @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
      .field("feed", Feed.self, arguments: [
        "latitude": .variable("latitude"),
        "longitude": .variable("longitude"),
        "first": .variable("first"),
        "after": .variable("after"),
        "filters": .variable("filters"),
        "lastFetchedAt": .variable("lastFetchedAt")
      ]),
    ] }
    @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      FeedFilteredQuery.Data.self
    ] }

    /// Get location-based recipe feed with velocity ranking and filters
    public var feed: Feed { __data["feed"] }

    /// Feed
    ///
    /// Parent Type: `RecipeConnection`
    public struct Feed: KindredAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeConnection }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("edges", [Edge].self),
        .field("pageInfo", PageInfo.self),
        .field("totalCount", Int.self),
        .field("newSinceLastFetch", Int?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FeedFilteredQuery.Data.Feed.self
      ] }

      public var edges: [Edge] { __data["edges"] }
      public var pageInfo: PageInfo { __data["pageInfo"] }
      public var totalCount: Int { __data["totalCount"] }
      public var newSinceLastFetch: Int? { __data["newSinceLastFetch"] }

      /// Feed.Edge
      ///
      /// Parent Type: `RecipeCardEdge`
      public struct Edge: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeCardEdge }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("node", Node.self),
          .field("cursor", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FeedFilteredQuery.Data.Feed.Edge.self
        ] }

        public var node: Node { __data["node"] }
        public var cursor: String { __data["cursor"] }

        /// Feed.Edge.Node
        ///
        /// Parent Type: `RecipeCard`
        public struct Node: KindredAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.RecipeCard }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", KindredAPI.ID.self),
            .field("name", String.self),
            .field("imageUrl", String?.self),
            .field("imageStatus", GraphQLEnum<KindredAPI.ImageStatus>.self),
            .field("prepTime", Int.self),
            .field("calories", Int?.self),
            .field("engagementLoves", Int.self),
            .field("engagementHumanized", String.self),
            .field("isViral", Bool.self),
            .field("cuisineType", GraphQLEnum<KindredAPI.CuisineType>.self),
            .field("mealType", GraphQLEnum<KindredAPI.MealType>.self),
            .field("velocityScore", Double.self),
            .field("distanceMiles", Double?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            FeedFilteredQuery.Data.Feed.Edge.Node.self
          ] }

          public var id: KindredAPI.ID { __data["id"] }
          public var name: String { __data["name"] }
          public var imageUrl: String? { __data["imageUrl"] }
          public var imageStatus: GraphQLEnum<KindredAPI.ImageStatus> { __data["imageStatus"] }
          public var prepTime: Int { __data["prepTime"] }
          public var calories: Int? { __data["calories"] }
          public var engagementLoves: Int { __data["engagementLoves"] }
          public var engagementHumanized: String { __data["engagementHumanized"] }
          public var isViral: Bool { __data["isViral"] }
          public var cuisineType: GraphQLEnum<KindredAPI.CuisineType> { __data["cuisineType"] }
          public var mealType: GraphQLEnum<KindredAPI.MealType> { __data["mealType"] }
          public var velocityScore: Double { __data["velocityScore"] }
          public var distanceMiles: Double? { __data["distanceMiles"] }
        }
      }

      /// Feed.PageInfo
      ///
      /// Parent Type: `PageInfo`
      public struct PageInfo: KindredAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { KindredAPI.Objects.PageInfo }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("hasNextPage", Bool.self),
          .field("endCursor", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          FeedFilteredQuery.Data.Feed.PageInfo.self
        ] }

        public var hasNextPage: Bool { __data["hasNextPage"] }
        public var endCursor: String? { __data["endCursor"] }
      }
    }
  }
}
