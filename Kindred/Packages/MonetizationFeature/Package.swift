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
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads", from: "11.0.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform", from: "2.0.0"),
        .package(name: "DesignSystem", path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "MonetizationFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform"),
                "DesignSystem",
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppTrackingTransparency")
            ]
        ),
        .testTarget(
            name: "MonetizationFeatureTests",
            dependencies: [
                "MonetizationFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Tests"
        )
    ]
)
