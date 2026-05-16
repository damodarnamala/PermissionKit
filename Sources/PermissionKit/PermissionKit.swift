// MARK: - PermissionKit — Handler Registry

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Central registry for permission handlers, enabling dependency injection and testing.
public final class PermissionKit: @unchecked Sendable {

    /// Shared singleton instance.
    public static let shared = PermissionKit()

    private let lock = NSLock()
    private var overrides: [PermissionKey: PermissionHandler] = [:]

    private init() {}

    // MARK: - Handler Resolution

    /// Returns the handler for a given permission, using overrides (mocks) if set.
    public static func handler(for permission: Permission) -> PermissionHandler {
        if let override = shared.getOverride(for: permission) {
            return override
        }
        return DefaultHandlerFactory.makeHandler(for: permission)
    }

    /// Override the handler for a specific permission (for testing).
    public static func setHandler(_ handler: PermissionHandler, for permission: Permission) {
        shared.setOverride(handler, for: permission)
    }

    /// Remove all handler overrides (call in test teardown).
    public static func resetAllHandlers() {
        shared.resetOverrides()
    }

    /// Remove a specific handler override.
    public static func resetHandler(for permission: Permission) {
        shared.removeOverride(for: permission)
    }

    // MARK: - Thread-Safe Override Storage

    private func getOverride(for permission: Permission) -> PermissionHandler? {
        lock.lock()
        defer { lock.unlock() }
        return overrides[PermissionKey(permission)]
    }

    private func setOverride(_ handler: PermissionHandler, for permission: Permission) {
        lock.lock()
        defer { lock.unlock() }
        overrides[PermissionKey(permission)] = handler
    }

    private func removeOverride(for permission: Permission) {
        lock.lock()
        defer { lock.unlock() }
        overrides.removeValue(forKey: PermissionKey(permission))
    }

    private func resetOverrides() {
        lock.lock()
        defer { lock.unlock() }
        overrides.removeAll()
    }
}

// MARK: - PermissionKey (Hashable wrapper)

/// A hashable wrapper for Permission to use as dictionary keys.
private struct PermissionKey: Hashable {
    let permission: Permission
    init(_ permission: Permission) { self.permission = permission }
}

// MARK: - Default Handler Factory

/// Creates the appropriate native handler for each permission.
internal enum DefaultHandlerFactory {
    static func makeHandler(for permission: Permission) -> PermissionHandler {
        switch permission {
        case .location:
            return LocationHandler(permission: permission)
        case .camera:
            return CameraHandler()
        case .microphone:
            return MicrophoneHandler()
        case .photos:
            return PhotosHandler(permission: permission)
        case .notifications, .criticalAlerts:
            return NotificationsHandler(permission: permission)
        case .contacts:
            return ContactsHandler()
        case .calendar:
            return CalendarHandler(permission: permission)
        case .reminders:
            return RemindersHandler()
        case .bluetooth:
            return BluetoothHandler()
        case .health:
            return HealthHandler(permission: permission)
        case .motion:
            return MotionHandler()
        case .speechRecognition:
            return SpeechHandler()
        case .tracking:
            return TrackingHandler()
        case .biometrics:
            return BiometricHandler(permission: permission)
        case .homeKit:
            return HomeKitHandler()
        case .nfc:
            return NFCHandler()
        case .siri:
            return SiriHandler()
        case .mediaLibrary:
            return MediaLibraryHandler()
        case .localNetwork:
            return LocalNetworkHandler()
        case .nearbyInteraction:
            return NearbyInteractionHandler()
        #if os(macOS)
        case .screenRecording:
            return ScreenRecordingHandler()
        case .fullDiskAccess:
            return FullDiskAccessHandler()
        case .accessibility:
            return AccessibilityHandler()
        case .inputMonitoring:
            return InputMonitoringHandler()
        case .automation:
            return AutomationHandler()
        #else
        case .screenRecording, .fullDiskAccess, .accessibility,
             .inputMonitoring, .automation:
            return UnsupportedHandler(permission: permission)
        #endif
        #if os(watchOS)
        case .workoutExtension:
            return WorkoutExtensionHandler()
        case .mindfulnessSession:
            return MindfulnessSessionHandler()
        #else
        case .workoutExtension, .mindfulnessSession:
            return UnsupportedHandler(permission: permission)
        #endif
        }
    }
}

// MARK: - Settings Opener Utility

internal enum SettingsOpener {
    @MainActor
    static func openAppSettings() {
        #if os(iOS) || os(tvOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}
