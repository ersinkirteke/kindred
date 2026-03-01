// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AuthClient",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AuthClient",
            targets: ["AuthClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/clerk/clerk-ios", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "AuthClient",
            dependencies: [
                .product(name: "ClerkKit", package: "clerk-ios"),
            ]
        ),
    ]
)
