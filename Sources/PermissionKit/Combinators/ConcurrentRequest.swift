// MARK: - ConcurrentRequest

import Foundation

/// Requests multiple permissions simultaneously using a TaskGroup.
///
/// ```swift
/// let results = await Permission.concurrent([.contacts, .calendar, .reminders]).request()
/// ```
public struct ConcurrentRequest: Sendable {
    /// The permissions to request concurrently.
    public let permissions: [Permission]

    public init(permissions: [Permission]) {
        self.permissions = permissions
    }

    /// Request all permissions concurrently and return a dictionary of results.
    public func request() async -> [Permission: PermissionResult] {
        await withTaskGroup(of: PermissionResult.self, returning: [Permission: PermissionResult].self) { group in
            for permission in permissions {
                group.addTask {
                    let status = await permission.request()
                    return PermissionResult(
                        permission: permission,
                        status: status,
                        timestamp: Date()
                    )
                }
            }

            var results: [Permission: PermissionResult] = [:]
            for await result in group {
                results[result.permission] = result
            }
            return results
        }
    }
}
