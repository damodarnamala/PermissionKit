// MARK: - PermissionResult

import Foundation

/// The result of a permission request, including the permission, status, and timestamp.
public struct PermissionResult: Equatable, Sendable {
    /// The permission that was requested.
    public let permission: Permission

    /// The resulting status after the request.
    public let status: PermissionStatus

    /// When the permission was requested.
    public let timestamp: Date

    /// Whether the permission was granted.
    public var isGranted: Bool {
        status.isGranted
    }

    /// Whether the user should be directed to Settings.
    public var shouldOpenSettings: Bool {
        status.shouldShowSettings
    }

    public init(permission: Permission, status: PermissionStatus, timestamp: Date) {
        self.permission = permission
        self.status = status
        self.timestamp = timestamp
    }
}
