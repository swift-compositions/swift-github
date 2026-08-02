// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-github",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "GitHub",
            targets: ["GitHub"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-primitives/swift-async-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-either-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-standards/swift-github-standard.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "GitHub",
            dependencies: [
                .product(
                    name: "Async Lifecycle Primitives",
                    package: "swift-async-primitives"
                ),
                .product(
                    name: "Either Primitives",
                    package: "swift-either-primitives"
                ),
                .product(
                    name: "GitHub Standard",
                    package: "swift-github-standard"
                )
            ]
        ),
        .testTarget(
            name: "GitHub Core Tests",
            dependencies: ["GitHub"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
