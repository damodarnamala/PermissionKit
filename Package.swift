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
        .executable(
            name: "PermissionKitCLI",
            targets: ["PermissionKitCLI"]
        ),
        .plugin(
            name: "GeneratePermissionPlist",
            targets: ["GeneratePermissionPlist"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
    ],
    targets: [
        .target(
            name: "PermissionKit",
            path: "Sources/PermissionKit"
        ),
        .executableTarget(
            name: "PermissionKitCLI",
            dependencies: [
                "PermissionKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
            ],
            path: "Sources/PermissionKitCLI"
        ),
        .executableTarget(
            name: "permission-plist-generator",
            dependencies: ["PermissionKit"],
            path: "Sources/PermissionPlistGenerator"
        ),
        .plugin(
            name: "GeneratePermissionPlist",
            capability: .command(
                intent: .custom(
                    verb: "generate-permission-plist",
                    description: "Generate Info.plist entries and .entitlements from permissions.json"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Write generated Info.plist and entitlements files")
                ]
            ),
            dependencies: [
                .target(name: "permission-plist-generator")
            ],
            path: "Plugins/GeneratePermissionPlist"
        ),
        .testTarget(
            name: "PermissionKitTests",
            dependencies: ["PermissionKit"],
            path: "Tests/PermissionKitTests"
        ),
    ]
)
