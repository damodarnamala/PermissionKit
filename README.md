<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?logo=swift" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/platforms-iOS%2016+%20|%20macOS%2013+%20|%20watchOS%209+%20|%20tvOS%2016+-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/SPM-compatible-brightgreen?logo=swift" alt="SPM Compatible">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License">
</p>

# PermissionKit

A unified, expressive, and developer-friendly permissions framework covering **all Apple platform permissions** across iOS, macOS, watchOS, and tvOS — with zero external dependencies.

## Features

- **One-line permission requests** — `await Permission.camera.request()`
- **45 permissions** across all Apple platforms
- **Async/await first** with Combine and AsyncStream bridges
- **SwiftUI components** — gates, buttons, badges, flows, and sheets
- **Combinators** — sequence, concurrent, and conditional chain patterns
- **Auto-generate Info.plist & entitlements** — CLI tool and SPM plugin
- **Testable by design** — built-in mocking infrastructure
- **Zero dependencies** — pure Apple SDK, conditional imports per platform

## Installation

### Swift Package Manager

Add PermissionKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/PermissionKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and paste the repository URL.

## Quick Start

### Request a Single Permission

```swift
import PermissionKit

let status = await Permission.camera.request()

if status.isGranted {
    // Access camera
}
```

### Check Status Without Prompting

```swift
if Permission.camera.isGranted {
    // Already authorized
} else if Permission.camera.isDenied {
    // Show settings prompt
}
```

### Request Multiple Permissions in Sequence

```swift
let results = await Permission.sequence([.camera, .microphone, .notifications])
    .stoppingOnDenied()
    .request()

for result in results {
    print("\(result.permission.title): \(result.status)")
}
```

### Request Multiple Permissions Concurrently

```swift
let results = await Permission.concurrent([.camera, .microphone, .photos]).request()

if let camera = results[.camera], camera.isGranted {
    // Camera ready
}
```

### Conditional Chains

```swift
let chain = await Permission.request(.location(.whenInUse))

await chain
    .onGranted { print("Location granted") }
    .onDenied  { print("Location denied — open Settings") }
```

## SwiftUI Components

### PermissionGate

Show different content based on permission state:

```swift
PermissionGate(.camera,
    granted: { CameraView() },
    denied: { Text("Camera access denied") },
    restricted: { Text("Camera restricted") }
)
```

### PermissionButton

A button that requests permission on tap:

```swift
PermissionButton(.microphone, label: "Enable Microphone")
```

### PermissionBadge

A color-coded status indicator:

```swift
PermissionBadge(.camera)
```

### PermissionSheet

A modal with auto-populated metadata (icon, title, description):

```swift
PermissionSheet(.camera) { status in
    print("Result: \(status)")
}
```

### PermissionFlow

Multi-step onboarding flow with progress:

```swift
PermissionFlow(
    permissions: [.camera, .microphone, .notifications],
    skippable: [.notifications],
    onComplete: { results in
        print("Onboarding complete")
    }
) { index, permission, status in
    VStack {
        Image(systemName: permission.systemImageName)
        Text(permission.title)
        Text(permission.description)
    }
}
```

## Reactive Streams

### AsyncStream

```swift
for await status in Permission.camera.stream {
    print("Camera status changed: \(status)")
}
```

### Combine

```swift
import Combine

Permission.camera.publisher
    .sink { status in
        print("Camera: \(status)")
    }
    .store(in: &cancellables)
```

## Permission Metadata

Every permission includes rich metadata:

```swift
Permission.camera.title              // "Camera"
Permission.camera.description        // "Access the device camera..."
Permission.camera.systemImageName    // "camera.fill"
Permission.camera.infoPlistKey       // "NSCameraUsageDescription"
Permission.camera.requiredCapability // "com.apple.security.device.camera"
Permission.camera.entitlements       // ["com.apple.security.device.camera": true]
Permission.camera.platforms          // [.iOS, .macOS, .tvOS]
```

### Info.plist Validation

```swift
let missing = InfoPlistHelper.validateInfoPlist(for: [.camera, .microphone, .location(.whenInUse)])
// Returns array of missing Info.plist keys
```

## Auto-Generate Info.plist & Entitlements

> **Never forget a privacy key or capability again.** Define your permissions once, generate everything your host app's Xcode project needs automatically — Info.plist privacy keys, `.entitlements` capabilities, and build settings.
>
> These files are generated for **your app** (the one that depends on PermissionKit), not for the framework itself.

### 🔧 Using PermissionManifest in Code

In your host app, define all permissions in one place:

```swift
import PermissionKit

let manifest = PermissionManifest(permissions: [
    PermissionManifest.entry(.camera, usage: "Take photos for your profile"),
    PermissionManifest.entry(.microphone, usage: "Record voice messages"),
    PermissionManifest.entry(.location(.whenInUse), usage: "Show nearby places on the map"),
    PermissionManifest.entry(.notifications(.default), usage: "Send you order updates"),
    PermissionManifest.entry(.health(.readWrite), usage: "Track your workouts"),
])

// Generate Info.plist XML with all required privacy keys
let plistXML = manifest.generateInfoPlist()

// Generate .entitlements plist with all required capabilities
let entitlementsPlist = manifest.generateEntitlementsPlist()

// Validate at runtime that your bundle isn't missing any keys
let missing = manifest.validateBundle()
if !missing.isEmpty {
    print("Missing Info.plist keys: \(missing)")
}

// Print a human-readable report
print(manifest.report())
```

### 📄 Using JSON Configuration

Create a `permissions.json` file in **your app's** project root:

```json
{
  "permissions": [
    { "permission": "camera", "usage": "Take photos for your profile" },
    { "permission": "microphone", "usage": "Record voice messages" },
    { "permission": "location", "variant": "whenInUse", "usage": "Show nearby places" },
    { "permission": "photos", "variant": "readWrite", "usage": "Save edited images" },
    { "permission": "notifications", "usage": "Send you order updates" },
    { "permission": "health", "variant": "readWrite", "usage": "Track your workouts" },
    { "permission": "biometrics", "variant": "faceID", "usage": "Secure app login" }
  ]
}
```

**Supported variants:**

| Permission | Variants |
|---|---|
| `location` | `whenInUse` (default), `always`, `precise` |
| `photos` | `readWrite` (default), `addOnly`, `limited` |
| `calendar` | `fullAccess` (default), `read`, `write` |
| `health` | `readWrite` (default), `read`, `write` |
| `biometrics` | `any` (default), `faceID`, `touchID` |

### ⚡ CLI Generator Tool

Run the generator from your app's directory to produce all required files:

```bash
swift run permission-plist-generator permissions.json --app-name MyApp --output-dir MyApp/
```

This generates three files **for your host app**:

| File | Contents |
|---|---|
| `MyApp-Info.plist` | Complete Info.plist with all `NS*UsageDescription` privacy keys |
| `MyApp.entitlements` | Entitlements file with all required capabilities |
| `MyApp.xcconfig` | Build settings pointing to the generated files |

Then add these files to your Xcode project:
1. Drag the generated files into your app target in Xcode
2. Set `MyApp-Info.plist` as the target's Info.plist in **Build Settings → Info.plist File**
3. Set `MyApp.entitlements` in **Build Settings → Code Signing Entitlements**
4. Or simply include `MyApp.xcconfig` in your build configuration — it sets both automatically

### 🔌 SPM Command Plugin

Run directly from your app's package directory:

```bash
swift package plugin generate-permission-plist
swift package plugin generate-permission-plist --output-dir Sources/MyApp
```

Or in Xcode: **right-click your app target → GeneratePermissionPlist**.

The plugin reads `permissions.json` from your app's project root and generates files into the specified directory.

### 🌐 Bonjour Services (Local Network)

If your manifest includes `.localNetwork`, generate the `NSBonjourServices` array:

```swift
if let bonjour = manifest.generateBonjourServices(serviceTypes: ["_myapp._tcp", "_myapp._udp"]) {
    print(bonjour) // XML fragment for Info.plist
}
```

## Testing

PermissionKit includes a first-class testing infrastructure:

```swift
import Testing
@testable import PermissionKit

@Suite(.serialized)
struct MyFeatureTests {
    @Test func cameraFlow() async {
        // Mock a permission
        let mock = PermissionTestHelper.mock(.camera, with: .granted)
        defer { PermissionKit.resetHandler(for: .camera) }

        // Your code under test
        let status = await Permission.camera.request()
        #expect(status == .granted)
        #expect(mock.requestCallCount == 1)
    }

    @Test func multiplePermissions() {
        PermissionTestHelper.mock([.camera, .microphone], with: .denied)
        defer { PermissionKit.resetAllHandlers() }

        #expect(Permission.camera.isDenied)
        #expect(Permission.microphone.isDenied)
    }
}
```

## Supported Permissions

| Permission | iOS | macOS | watchOS | tvOS |
|---|:---:|:---:|:---:|:---:|
| Camera | ✅ | ✅ | — | ✅ |
| Microphone | ✅ | ✅ | — | — |
| Photos | ✅ | ✅ | — | — |
| Location | ✅ | ✅ | ✅ | — |
| Contacts | ✅ | ✅ | — | — |
| Calendar | ✅ | ✅ | — | — |
| Reminders | ✅ | ✅ | — | — |
| Notifications | ✅ | ✅ | ✅ | ✅ |
| Critical Alerts | ✅ | ✅ | ✅ | — |
| Bluetooth | ✅ | ✅ | ✅ | — |
| Health | ✅ | — | ✅ | — |
| Motion | ✅ | — | ✅ | — |
| Speech Recognition | ✅ | ✅ | — | — |
| Tracking (ATT) | ✅ | — | — | — |
| Biometrics | ✅ | ✅ | ✅ | — |
| HomeKit | ✅ | ✅ | ✅ | ✅ |
| NFC | ✅ | — | — | — |
| Siri | ✅ | — | — | — |
| Media Library | ✅ | — | — | — |
| Local Network | ✅ | ✅ | — | — |
| Nearby Interaction | ✅ | — | ✅ | — |
| Screen Recording | — | ✅ | — | — |
| Full Disk Access | — | ✅ | — | — |
| Accessibility | — | ✅ | — | — |
| Input Monitoring | — | ✅ | — | — |
| Automation | — | ✅ | — | — |
| Workout Extension | — | — | ✅ | — |
| Mindfulness Session | — | — | ✅ | — |

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+ / watchOS 9+ / tvOS 16+
- Xcode 15+

## License

PermissionKit is available under the MIT License. See [LICENSE](LICENSE) for details.
