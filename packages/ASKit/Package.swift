// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ASKit",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "ASKit",
            targets: ["ASKit"]
        ),
    ],
    targets: [
        .target(
            name: "ASKit",
            dependencies: []
        ),
    ]
)
