// MARK: - PermissionStatus

import Foundation

/// Unified permission status across all Apple platform permissions.
public enum PermissionStatus: String, Equatable, Hashable, Sendable, Codable {
    /// The user has not yet been asked for this permission.
    case notDetermined
    /// The user has granted full access.
    case granted
    /// The user has explicitly denied access.
    case denied
    /// Access is restricted (e.g., parental controls, MDM).
    case restricted
    /// Limited access granted (e.g., Photos limited library).
    case limited
    /// Provisional authorization granted (e.g., quiet notifications).
    case provisional
    /// The permission status cannot be determined on this platform.
    case unknown
}

// MARK: - Convenience Properties

extension PermissionStatus {
    /// Whether the permission has been fully granted.
    public var isGranted: Bool {
        self == .granted
    }

    /// Whether the user denied the permission.
    public var isDenied: Bool {
        self == .denied
    }

    /// Whether the permission has never been requested.
    public var isNotDetermined: Bool {
        self == .notDetermined
    }

    /// Whether the system can present the permission dialog again.
    /// Returns `false` if the user has denied or the permission is restricted.
    public var canAskAgain: Bool {
        self == .notDetermined
    }

    /// Whether the user should be redirected to Settings to change this permission.
    public var shouldShowSettings: Bool {
        self == .denied
    }
}
