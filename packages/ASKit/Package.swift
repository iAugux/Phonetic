// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ASKit",
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
