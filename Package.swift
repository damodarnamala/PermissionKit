// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PermissionKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "PermissionKit",
            targets: ["PermissionKit"]
        ),
    ],
    targets: [
        .target(
            name: "PermissionKit",
            path: "Sources/PermissionKit"
        ),
        .testTarget(
            name: "PermissionKitTests",
            dependencies: ["PermissionKit"],
            path: "Tests/PermissionKitTests"
        ),
    ]
)
