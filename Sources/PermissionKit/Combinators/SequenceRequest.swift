// MARK: - SequenceRequest

import Foundation

/// Requests permissions one at a time, in order.
///
/// ```swift
/// let results = await Permission.sequence([.camera, .microphone, .notifications]).request()
/// ```
public struct SequenceRequest: Sendable {
    /// The permissions to request in sequence.
    public let permissions: [Permission]

    /// Whether to stop requesting if a critical permission is denied.
    public var stopOnDenied: Bool = false

    public init(permissions: [Permission]) {
        self.permissions = permissions
    }

    /// Request all permissions in sequence and return the results in order.
    public func request() async -> [PermissionResult] {
        var results: [PermissionResult] = []
        for permission in permissions {
            let status = await permission.request()
            let result = PermissionResult(
                permission: permission,
                status: status,
                timestamp: Date()
            )
            results.append(result)

            if stopOnDenied && (status == .denied || status == .restricted) {
                break
            }
        }
        return results
    }

    /// Configure whether to stop when a permission is denied.
    public func stoppingOnDenied(_ stop: Bool = true) -> SequenceRequest {
        var copy = self
        copy.stopOnDenied = stop
        return copy
    }
}
