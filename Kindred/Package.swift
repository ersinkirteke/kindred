// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Kindred",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Kindred",
            targets: ["Kindred"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.0.0"),
        .package(path: "Packages/DesignSystem"),
        .package(path: "Packages/NetworkClient"),
        .package(path: "Packages/AuthClient"),
        .package(path: "Packages/FeedFeature"),
        .package(path: "Packages/ProfileFeature"),
    ],
    targets: [
        .target(
            name: "Kindred",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                "DesignSystem",
                "NetworkClient",
                "AuthClient",
                "FeedFeature",
                "ProfileFeature",
            ],
            path: "Sources"
        ),
    ]
)
