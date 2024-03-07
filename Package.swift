// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppDependency",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v11),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AppDependency",
            targets: ["AppDependency"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/0xLeif/Cache", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AppDependency",
            dependencies: [
                "Cache"
            ]
        ),
        .testTarget(
            name: "AppDependencyTests",
            dependencies: ["AppDependency"]
        )
    ]
)
