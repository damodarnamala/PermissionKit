# Changelog

All notable changes to PermissionKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-01

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
