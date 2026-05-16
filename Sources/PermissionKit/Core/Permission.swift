// MARK: - Permission

import Foundation

/// A unified enum representing all 45 Apple platform permissions.
///
/// Use `Permission` as the single entry point for checking, requesting,
/// and observing any system permission across iOS, macOS, watchOS, and tvOS.
///
/// ```swift
/// let status = await Permission.camera.request()
/// if Permission.camera.isGranted { startCamera() }
/// ```
public enum Permission: Equatable, Hashable, Sendable {

    // MARK: - Location

    /// Location permission with the specified accuracy level.
    case location(LocationAccuracy)

    // MARK: - Media

    /// Camera access for photo/video capture.
    case camera

    /// Microphone access for audio recording.
    case microphone

    /// Photo library access with the specified level.
    case photos(PhotosAccess)

    /// Apple Music / media library access.
    case mediaLibrary

    // MARK: - Communication

    /// Contacts access.
    case contacts

    /// Calendar access with the specified level.
    case calendar(CalendarAccess)

    /// Reminders access.
    case reminders

    // MARK: - Notifications

    /// Push notification permission with specified options.
    case notifications(NotificationOptions)

    /// Critical alerts permission (requires Apple entitlement).
    case criticalAlerts

    // MARK: - Connectivity

    /// Bluetooth access.
    case bluetooth

    /// Local network discovery access.
    case localNetwork

    /// Nearby interaction (UWB) access.
    case nearbyInteraction

    // MARK: - Identity & Auth

    /// Biometric authentication (Face ID / Touch ID).
    case biometrics(BiometricType)

    /// App Tracking Transparency.
    case tracking

    // MARK: - Intelligence

    /// Siri and Shortcuts access.
    case siri

    /// Speech recognition access.
    case speechRecognition

    // MARK: - Health & Fitness

    /// HealthKit data access with specified type.
    case health(HealthAccessType)

    /// Motion and fitness data access.
    case motion

    // MARK: - Smart Home

    /// HomeKit access.
    case homeKit

    /// NFC reader access.
    case nfc

    // MARK: - macOS Only

    /// Screen recording permission (macOS).
    case screenRecording

    /// Full disk access (macOS).
    case fullDiskAccess

    /// Accessibility access (macOS).
    case accessibility

    /// Input monitoring / key logging (macOS).
    case inputMonitoring

    /// Automation / AppleScript (macOS).
    case automation

    // MARK: - watchOS Only

    /// Workout session extension (watchOS).
    case workoutExtension

    /// Mindfulness session (watchOS).
    case mindfulnessSession
}

// MARK: - Convenience Initializers

extension Permission {
    /// Notifications with default options (alert, badge, sound).
    public static var notifications: Permission {
        .notifications(.default)
    }

    /// Location when-in-use (most common).
    public static var locationWhenInUse: Permission {
        .location(.whenInUse)
    }

    /// Location always.
    public static var locationAlways: Permission {
        .location(.always)
    }

    /// Photos read-write (most common).
    public static var photos: Permission {
        .photos(.readWrite)
    }

    /// Calendar full access.
    public static var calendar: Permission {
        .calendar(.fullAccess)
    }

    /// Biometrics with any type.
    public static var biometrics: Permission {
        .biometrics(.any)
    }

    /// Health read access.
    public static var healthRead: Permission {
        .health(.read)
    }

    /// Health write access.
    public static var healthWrite: Permission {
        .health(.write)
    }
}

// MARK: - Predefined Permission Groups

extension Permission {
    /// Camera and microphone for media capture.
    public static let mediaCapture: [Permission] = [.camera, .microphone]

    /// Location permission variants.
    public static let locationGroup: [Permission] = [
        .location(.whenInUse),
        .location(.always)
    ]

    /// Social-related permissions.
    public static let social: [Permission] = [
        .contacts,
        .calendar(.read)
    ]

    /// Health and fitness permissions.
    public static let healthGroup: [Permission] = [
        .health(.read),
        .motion
    ]
}

// MARK: - Request & Status API

extension Permission {
    /// The current status of this permission.
    public var status: PermissionStatus {
        PermissionKit.handler(for: self).status
    }

    /// Whether this permission is currently granted.
    public var isGranted: Bool {
        status.isGranted
    }

    /// Whether this permission has been denied.
    public var isDenied: Bool {
        status.isDenied
    }

    /// Whether this permission has never been requested.
    public var isNotDetermined: Bool {
        status.isNotDetermined
    }

    /// Request this permission and return the resulting status.
    @discardableResult
    public func request() async -> PermissionStatus {
        await PermissionKit.handler(for: self).request()
    }

    /// A live stream of status changes for this permission.
    public var statusStream: AsyncStream<PermissionStatus> {
        PermissionKit.handler(for: self).statusStream
    }

    /// Open the system Settings page relevant to this permission.
    public func openSettings() async {
        await PermissionKit.handler(for: self).openSettings()
    }

    /// Request this permission and return a full result.
    public func requestWithResult() async -> PermissionResult {
        let resultStatus = await request()
        return PermissionResult(
            permission: self,
            status: resultStatus,
            timestamp: Date()
        )
    }
}

// MARK: - Combinator Entry Points

extension Permission {
    /// Request multiple permissions in sequence (one at a time, in order).
    public static func sequence(_ permissions: [Permission]) -> SequenceRequest {
        SequenceRequest(permissions: permissions)
    }

    /// Request multiple permissions concurrently (all at once).
    public static func concurrent(_ permissions: [Permission]) -> ConcurrentRequest {
        ConcurrentRequest(permissions: permissions)
    }

    /// Begin a conditional permission chain starting with the given permission.
    public static func request(_ permission: Permission) async -> ConditionalChain {
        let status = await permission.request()
        let result = PermissionResult(permission: permission, status: status, timestamp: Date())
        return ConditionalChain(results: [result])
    }

    /// Observe status changes for multiple permissions.
    public static func observe(_ permissions: [Permission]) -> AsyncStream<(Permission, PermissionStatus)> {
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    for permission in permissions {
                        group.addTask {
                            for await status in permission.statusStream {
                                continuation.yield((permission, status))
                            }
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}
