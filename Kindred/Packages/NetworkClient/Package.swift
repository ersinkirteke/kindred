// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NetworkClient",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios", from: "2.0.6"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(path: "../KindredAPI"),
    ],
    targets: [
        .target(
            name: "NetworkClient",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloSQLite", package: "apollo-ios"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "KindredAPI", package: "KindredAPI"),
            ],
            exclude: ["Schema/Package.swift"]
        ),
    ]
)
