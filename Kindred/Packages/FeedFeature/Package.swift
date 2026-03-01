// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeedFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "FeedFeature",
            targets: ["FeedFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.0.0"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "NetworkClient", path: "../NetworkClient"),
        .package(name: "KindredAPI", path: "../KindredAPI"),
    ],
    targets: [
        .target(
            name: "FeedFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                "DesignSystem",
                "NetworkClient",
                .product(name: "KindredAPI", package: "KindredAPI"),
            ]
        ),
    ]
)
