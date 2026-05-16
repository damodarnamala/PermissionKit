// MARK: - UnsupportedHandler

import Foundation

/// A handler for permissions not available on the current platform.
/// Always returns `.unknown` and never crashes.
final class UnsupportedHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission

    init(permission: Permission) {
        self.permission = permission
    }

    var status: PermissionStatus { .unknown }

    func request() async -> PermissionStatus { .unknown }

    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            continuation.yield(.unknown)
            continuation.finish()
        }
    }

    func openSettings() async {}
}
