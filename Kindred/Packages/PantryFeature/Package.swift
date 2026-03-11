// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PantryFeature",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PantryFeature", targets: ["PantryFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
        .package(name: "NetworkClient", path: "../NetworkClient"),
        .package(name: "KindredAPI", path: "../KindredAPI"),
        .package(name: "AuthClient", path: "../AuthClient"),
    ],
    targets: [
        .target(
            name: "PantryFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DesignSystem",
                "NetworkClient",
                .product(name: "KindredAPI", package: "KindredAPI"),
                "AuthClient",
            ]
        ),
    ]
)
