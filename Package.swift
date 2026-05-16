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
        .plugin(
            name: "GeneratePermissionPlist",
            targets: ["GeneratePermissionPlist"]
        ),
    ],
    targets: [
        .target(
            name: "PermissionKit",
            path: "Sources/PermissionKit"
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
