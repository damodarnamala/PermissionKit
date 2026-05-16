// MARK: - PermissionTestHelper

import Foundation

/// Utility helpers for testing permission-related code.
///
/// ```swift
/// // In setUp:
/// PermissionTestHelper.mockAll(with: .granted)
///
/// // In tearDown:
/// PermissionTestHelper.resetAll()
/// ```
public enum PermissionTestHelper {

    /// Override all given permissions with the specified status.
    public static func mock(_ permissions: [Permission], with status: PermissionStatus) {
        for permission in permissions {
            let mock = MockPermissionHandler(permission: permission, status: status)
            PermissionKit.setHandler(mock, for: permission)
        }
    }

    /// Override a single permission with a mock returning the given status.
    @discardableResult
    public static func mock(_ permission: Permission, with status: PermissionStatus) -> MockPermissionHandler {
        let mock = MockPermissionHandler(permission: permission, status: status)
        PermissionKit.setHandler(mock, for: permission)
        return mock
    }

    /// Reset all handler overrides.
    public static func resetAll() {
        PermissionKit.resetAllHandlers()
    }

    /// Get the mock handler for a permission (if one was set).
    public static func mockHandler(for permission: Permission) -> MockPermissionHandler? {
        PermissionKit.handler(for: permission) as? MockPermissionHandler
    }
}
