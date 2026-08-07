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
        ),
        .library(
            name: "GitHub App",
            targets: ["GitHub App"]
        ),
        .library(
            name: "GitHub OAuth",
            targets: ["GitHub OAuth"]
        ),
        .library(
            name: "GitHub Organizations",
            targets: ["GitHub Organizations"]
        ),
        .library(
            name: "GitHub Repositories",
            targets: ["GitHub Repositories"]
        ),
        .library(
            name: "GitHub Stargazers",
            targets: ["GitHub Stargazers"]
        ),
        .library(
            name: "GitHub Traffic",
            targets: ["GitHub Traffic"]
        ),
        .library(
            name: "GitHub Users",
            targets: ["GitHub Users"]
        ),
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
            url: "https://github.com/swift-ietf/swift-rfc-3986.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-standards/swift-github-standard.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-byte-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-environment.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-file-system.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-json.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-process.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-signature.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-4648.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "GitHub",
            dependencies: [
                .target(name: "GitHub App"),
                .target(name: "GitHub OAuth"),
                .target(name: "GitHub Organizations"),
                .target(name: "GitHub Repositories"),
                .target(name: "GitHub Stargazers"),
                .target(name: "GitHub Traffic"),
                .target(name: "GitHub Users"),
            ]
        ),
        .target(
            name: "GitHub App",
            dependencies: [
                .product(
                    name: "Byte Primitives",
                    package: "swift-byte-primitives"
                ),
                .product(
                    name: "Byte Primitives Standard Library Integration",
                    package: "swift-byte-primitives"
                ),
                .product(
                    name: "Either Primitives",
                    package: "swift-either-primitives"
                ),
                .product(
                    name: "Environment",
                    package: "swift-environment"
                ),
                .product(
                    name: "File System",
                    package: "swift-file-system"
                ),
                .product(
                    name: "GitHub Standard",
                    package: "swift-github-standard"
                ),
                .product(
                    name: "JSON",
                    package: "swift-json"
                ),
                .product(
                    name: "Process",
                    package: "swift-process"
                ),
                .product(
                    name: "RFC 4648",
                    package: "swift-rfc-4648"
                ),
                .product(
                    name: "Signature",
                    package: "swift-signature"
                ),
            ]
        ),
        .testTarget(
            name: "GitHub App Core Tests",
            dependencies: [.target(name: "GitHub App")]
        ),
        .target(
            name: "GitHub OAuth",
            dependencies: [
                .product(
                    name: "GitHub Standard",
                    package: "swift-github-standard"
                )
            ]
        ),
        .testTarget(
            name: "GitHub OAuth Core Tests",
            dependencies: [
                .target(name: "GitHub OAuth"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
            ]
        ),
        .target(
            name: "GitHub Organizations",
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
                ),
            ]
        ),
        .testTarget(
            name: "GitHub Organizations Core Tests",
            dependencies: [.target(name: "GitHub Organizations")]
        ),
        .target(
            name: "GitHub Repositories",
            dependencies: [
                .product(
                    name: "GitHub Standard",
                    package: "swift-github-standard"
                )
            ]
        ),
        .testTarget(
            name: "GitHub Repositories Core Tests",
            dependencies: [.target(name: "GitHub Repositories")]
        ),
        .target(
            name: "GitHub Stargazers",
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
                ),
            ]
        ),
        .testTarget(
            name: "GitHub Stargazers Core Tests",
            dependencies: [.target(name: "GitHub Stargazers")]
        ),
        .target(
            name: "GitHub Traffic",
            dependencies: [
                .product(
                    name: "GitHub Standard",
                    package: "swift-github-standard"
                )
            ]
        ),
        .testTarget(
            name: "GitHub Traffic Core Tests",
            dependencies: [.target(name: "GitHub Traffic")]
        ),
        .target(
            name: "GitHub Users",
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
                ),
            ]
        ),
        .testTarget(
            name: "GitHub Users Core Tests",
            dependencies: [.target(name: "GitHub Users")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
