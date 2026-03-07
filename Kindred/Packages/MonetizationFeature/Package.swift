// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MonetizationFeature",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(
            name: "MonetizationFeature",
            targets: ["MonetizationFeature"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "MonetizationFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "DesignSystem",
            ],
            path: "Sources"
        )
    ]
)
