// MARK: - Permission Associated Types

import Foundation

/// Location accuracy level.
public enum LocationAccuracy: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case whenInUse
    case always
    case precise
}

/// Photos access level.
public enum PhotosAccess: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case readWrite
    case addOnly
    case limited
}

/// Calendar access level.
public enum CalendarAccess: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case read
    case write
    case fullAccess
}

/// Biometric authentication type.
public enum BiometricType: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case faceID
    case touchID
    case any
}

/// Health data access type.
public enum HealthAccessType: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case read
    case write
    case readWrite
}

/// Notification options for requesting notification permissions.
public struct NotificationOptions: Equatable, Hashable, Sendable {
    public let alert: Bool
    public let badge: Bool
    public let sound: Bool
    public let criticalAlert: Bool
    public let provisional: Bool

    public init(
        alert: Bool = true,
        badge: Bool = true,
        sound: Bool = true,
        criticalAlert: Bool = false,
        provisional: Bool = false
    ) {
        self.alert = alert
        self.badge = badge
        self.sound = sound
        self.criticalAlert = criticalAlert
        self.provisional = provisional
    }

    /// Default notification options: alert, badge, and sound.
    public static let `default` = NotificationOptions()

    /// Provisional (quiet) notification options.
    public static let provisional = NotificationOptions(provisional: true)
}

/// Platform availability.
public enum Platform: String, Equatable, Hashable, Sendable, Codable, CaseIterable {
    case iOS
    case macOS
    case watchOS
    case tvOS
}
