# PermissionKit v1.1.0 — SwiftLint-Style CLI for Permissions

Stop manually adding `NS*UsageDescription` keys to Info.plist and toggling capabilities in Xcode. **v1.1.0** introduces a **SwiftLint-style CLI tool** — configure permissions in a `.permissionkit.yml` file and auto-generate everything your host app needs.

---

## What's New

### `permissionkit` CLI Tool

Install once, use from any Xcode project:

```bash
# Install
cd PermissionKit && make install

# In your app project
cd ~/Projects/MyApp
permissionkit init --app-name MyApp    # Create .permissionkit.yml
permissionkit generate                  # Generate Info.plist, entitlements, xcconfig
permissionkit lint                      # Validate your config
permissionkit report                    # Print permissions summary
```

### YAML Configuration (`.permissionkit.yml`)

Like `.swiftlint.yml` — place it in your project root:

```yaml
app_name: MyApp
output_dir: MyApp/

permissions:
  - permission: camera
    usage: "Take photos for your profile"

  - permission: location
    variant: whenInUse
    usage: "Show nearby places on the map"

  - permission: health
    variant: readWrite
    usage: "Track your workouts"

  - permission: notifications
    usage: "Send you order updates"

  - permission: biometrics
    variant: faceID
    usage: "Secure app login"
```

### Xcode Build Phase Integration

Add to your build phases for automatic regeneration on every build:

```bash
if command -v permissionkit &> /dev/null; then
    permissionkit generate
fi
```

### Generated Output

| File | Purpose |
|---|---|
| `MyApp-Info.plist` | Privacy usage descriptions (`NSCameraUsageDescription`, etc.) |
| `MyApp.entitlements` | Capabilities (`com.apple.developer.healthkit`, etc.) |
| `MyApp.xcconfig` | Build settings that wire up both files automatically |

---

## All Changes

- **`permissionkit` CLI** — installable via `make install`, managed via `.permissionkit.yml`
- **YAML configuration** — `app_name`, `output_dir`, `permissions`, `bonjour_services`
- **CLI commands** — `generate`, `init`, `lint`, `report`
- **`PermissionManifest`** — declarative Swift API for code-level permission management
- **Build script** — `generate-permissions.sh` for projects that prefer a shell-based approach
- **SPM command plugin** — `GeneratePermissionPlist` for SPM-based projects
- **`Permission.requiredCapability`** — Xcode capability identifier per permission
- **`Permission.entitlements`** — entitlements dictionary per permission
- **Bonjour services helper** — `generateBonjourServices(serviceTypes:)` for local network
- **Runtime validation** — `manifest.validateBundle()` checks for missing Info.plist keys

## Installation

```swift
.package(url: "https://github.com/nicklasedvardsen/PermissionKit.git", from: "1.1.0")
```

**Full Changelog**: `1.0.0...1.1.0`
