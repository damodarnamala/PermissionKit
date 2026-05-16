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
Permission.camera.title           // "Camera"
Permission.camera.description     // "Access the device camera..."
Permission.camera.systemImageName // "camera.fill"
Permission.camera.infoPlistKey    // "NSCameraUsageDescription"
Permission.camera.platforms       // [.iOS, .macOS, .tvOS]
```

### Info.plist Validation

```swift
let missing = InfoPlistHelper.validateInfoPlist(for: [.camera, .microphone, .location(.whenInUse)])
// Returns array of missing Info.plist keys
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
