# PermissionKit v1.1.0

**Auto-Generate Info.plist & Entitlements** — Never forget a privacy key or capability again.

## What's New

### PermissionManifest

Define all your app's permissions in one place and auto-generate everything Xcode needs:

```swift
let manifest = PermissionManifest(permissions: [
    PermissionManifest.entry(.camera, usage: "Take photos for your profile"),
    PermissionManifest.entry(.location(.whenInUse), usage: "Show nearby places"),
    PermissionManifest.entry(.notifications(.default), usage: "Send order updates"),
    PermissionManifest.entry(.health(.readWrite), usage: "Track your workouts"),
])

let plistXML = manifest.generateInfoPlist()          // Complete Info.plist
let entitlements = manifest.generateEntitlementsPlist() // .entitlements file
let missing = manifest.validateBundle()                // Runtime validation
```

### JSON Configuration

Create a `permissions.json` and generate files automatically:

```json
{
  "permissions": [
    { "permission": "camera", "usage": "Take photos for your profile" },
    { "permission": "location", "variant": "whenInUse", "usage": "Show nearby places" },
    { "permission": "health", "variant": "readWrite", "usage": "Track your workouts" }
  ]
}
```

### CLI Generator Tool

```bash
swift run permission-plist-generator permissions.json --output-dir MyApp/
```

Generates `Info.plist`, `.entitlements`, and `.xcconfig` — ready to drop into your Xcode project.

### SPM Command Plugin

```bash
swift package plugin generate-permission-plist
```

Also available in Xcode via **right-click target → GeneratePermissionPlist**.

### New Permission Metadata

Every permission now exposes its Xcode capability and entitlements:

```swift
Permission.camera.requiredCapability // "com.apple.security.device.camera"
Permission.camera.entitlements       // ["com.apple.security.device.camera": true]
Permission.health(.readWrite).entitlements
// ["com.apple.developer.healthkit": true, "com.apple.developer.healthkit.access": ["health-records"]]
```

## Full Changelog

### Added
- `PermissionManifest` — declarative permission config with Info.plist, entitlements, and xcconfig generation
- JSON configuration support (`permissions.json`) with permission names, variants, and usage descriptions
- CLI tool `permission-plist-generator` for automated file generation
- SPM command plugin `GeneratePermissionPlist` for Xcode and CLI integration
- `Permission.requiredCapability` — Xcode capability identifier per permission
- `Permission.entitlements` — entitlements dictionary per permission
- Bonjour services helper for local network permission
- Runtime bundle validation via `manifest.validateBundle()`
- Human-readable manifest report via `manifest.report()`

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/your-org/PermissionKit.git", from: "1.1.0")
]
```

**Full Changelog**: 1.0.0...1.1.0
