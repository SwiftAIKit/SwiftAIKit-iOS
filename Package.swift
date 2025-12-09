// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "SwiftAIKit",
            targets: ["SwiftAIKit"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftAIKit",
            dependencies: [],
            path: "Sources/SwiftAIKit"
        ),
        .testTarget(
            name: "SwiftAIKitTests",
            dependencies: ["SwiftAIKit"],
            path: "Tests/SwiftAIKitTests"
        ),
    ]
)
