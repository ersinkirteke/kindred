// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public struct FeedFiltersInput: InputObject {
  @_spi(Unsafe) public private(set) var __data: InputDict

  @_spi(Unsafe) public init(_ data: InputDict) {
    __data = data
  }

  public init(
    cuisineTypes: GraphQLNullable<[GraphQLEnum<CuisineType>]> = nil,
    dietaryTags: GraphQLNullable<[String]> = nil,
    mealTypes: GraphQLNullable<[GraphQLEnum<MealType>]> = nil
  ) {
    __data = InputDict([
      "cuisineTypes": cuisineTypes,
      "dietaryTags": dietaryTags,
      "mealTypes": mealTypes
    ])
  }

  public var cuisineTypes: GraphQLNullable<[GraphQLEnum<CuisineType>]> {
    get { __data["cuisineTypes"] }
    set { __data["cuisineTypes"] = newValue }
  }

  public var dietaryTags: GraphQLNullable<[String]> {
    get { __data["dietaryTags"] }
    set { __data["dietaryTags"] = newValue }
  }

  public var mealTypes: GraphQLNullable<[GraphQLEnum<MealType>]> {
    get { __data["mealTypes"] }
    set { __data["mealTypes"] = newValue }
  }
}
