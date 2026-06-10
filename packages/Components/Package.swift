// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Components",
            targets: ["Components"]
        ),
    ],
    dependencies: [
        .package(name: "ASKit", path: "../ASKit"),
    ],
    targets: [
        .target(
            name: "Components",
            dependencies: [
                "ASKit",
            ]
        ),
    ]
)
