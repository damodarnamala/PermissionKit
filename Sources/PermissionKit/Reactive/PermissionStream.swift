// MARK: - PermissionStream

import Foundation

/// AsyncStream-based reactive interface for observing permission status changes.
///
/// ```swift
/// for await status in Permission.camera.statusStream {
///     updateUI(for: status)
/// }
/// ```
public enum PermissionStream {
    /// Observe status changes for a single permission.
    public static func observe(_ permission: Permission) -> AsyncStream<PermissionStatus> {
        permission.statusStream
    }

    /// Observe status changes for multiple permissions.
    /// Yields tuples of (Permission, PermissionStatus) as any of them change.
    public static func observe(_ permissions: [Permission]) -> AsyncStream<(Permission, PermissionStatus)> {
        Permission.observe(permissions)
    }
}
