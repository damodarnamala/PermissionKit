# Changelog

All notable changes to PermissionKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-16

### Added

- **`permissionkit` CLI tool** — SwiftLint-style command-line app managed through `.permissionkit.yml` config file; install via `make install`
- **YAML configuration** (`.permissionkit.yml`) — define `app_name`, `output_dir`, `permissions`, `bonjour_services` in YAML format
- **CLI commands**: `generate` (auto-generate files), `init` (create template config), `lint` (validate config), `report` (print permissions summary)
- **`PermissionManifest`** — declarative manifest to define all app permissions in one place and auto-generate Info.plist, entitlements, and xcconfig files
- **JSON configuration support** — define permissions in a `permissions.json` file with permission names, variants, and usage descriptions
- **Build script** (`generate-permissions.sh`) — standalone shell script that works with any Xcode project, no SPM required
- **SPM command plugin** (`GeneratePermissionPlist`) — run `swift package plugin generate-permission-plist`
- **`Permission.requiredCapability`** — Xcode capability identifier for each permission
- **`Permission.entitlements`** — full entitlements dictionary for `.entitlements` file generation
- **Bonjour services helper** — `generateBonjourServices(serviceTypes:)` for local network `NSBonjourServices` array
- **Manifest validation** — `validateBundle()` checks that all required Info.plist keys are present

## [0.0.1] - 2025-05-16

### Added

- **Core framework** with unified `Permission` enum covering 45 Apple platform permissions
- **`PermissionStatus`** — 7-state enum (notDetermined, granted, denied, restricted, limited, provisional, unknown) with convenience properties
- **`PermissionHandler` protocol** — async/await handler interface with status, request, stream, and openSettings
- **Handler implementations** for all permissions with conditional compilation per platform:
  - iOS/macOS/tvOS: Camera, Microphone, Photos, Location, Contacts, Calendar, Reminders, Notifications, Bluetooth, Speech Recognition, Biometrics, HomeKit, NFC, Siri, Media Library, Local Network, Nearby Interaction, Tracking
  - macOS: Screen Recording, Full Disk Access, Accessibility, Input Monitoring, Automation
  - watchOS: Workout Extension, Mindfulness Session
- **Combinators engine**:
  - `SequenceRequest` — sequential permission requests with optional stop-on-denied
  - `ConcurrentRequest` — parallel permission requests via TaskGroup
  - `ConditionalChain` — fluent builder with `.onGranted`, `.onDenied`, `.onRestricted`, `.onSettingsNeeded`
- **Reactive layer**:
  - `PermissionStream` — AsyncStream wrappers for single and multi-permission observation
  - `PermissionPublisher` — Combine bridge with `AnyPublisher` output
- **SwiftUI components**:
  - `PermissionGate` — generic 3-state view (granted/denied/restricted)
  - `PermissionButton` — auto-requesting button with status feedback
  - `PermissionBadge` — color-coded status dot with pulse animation
  - `PermissionFlow` — multi-step onboarding with progress tracking
  - `PermissionSheet` — modal with auto-populated permission metadata
- **Permission metadata** — title, description, systemImageName, color, infoPlistKey, settingsURL, and supported platforms for every permission case
- **`InfoPlistHelper`** — utility for required keys lookup, full key dictionary, and missing key validation
- **Testing infrastructure**:
  - `MockPermissionHandler` — configurable stub with call tracking, delay simulation, and status change support
  - `PermissionTestHelper` — convenience API for mocking single/multiple permissions and retrieving mocks
- **Handler registry** — `PermissionKit` singleton with thread-safe override storage via NSLock
- **Zero external dependencies** — pure Apple SDK with conditional imports
