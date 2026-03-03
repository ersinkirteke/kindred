// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AuthFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AuthFeature",
            targets: ["AuthFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(url: "https://github.com/clerk/clerk-ios", from: "1.0.0"),
        .package(name: "AuthClient", path: "../AuthClient"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "FeedFeature", path: "../FeedFeature"),
    ],
    targets: [
        .target(
            name: "AuthFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ClerkKit", package: "clerk-ios"),
                "AuthClient",
                "DesignSystem",
                "FeedFeature",
            ]
        ),
    ]
)
