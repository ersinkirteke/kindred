// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ProfileFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "ProfileFeature",
            targets: ["ProfileFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "FeedFeature", path: "../FeedFeature"),
        .package(name: "MonetizationFeature", path: "../MonetizationFeature"),
    ],
    targets: [
        .target(
            name: "ProfileFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DesignSystem",
                "FeedFeature",
                "MonetizationFeature",
            ]
        ),
    ]
)
