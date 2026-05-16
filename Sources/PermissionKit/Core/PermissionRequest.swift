// MARK: - PermissionHandler Protocol

import Foundation

/// Protocol that every permission handler must conform to.
///
/// Provides a unified interface for checking status, requesting access,
/// observing changes, and opening system settings for any permission type.
public protocol PermissionHandler: AnyObject, Sendable {
    /// The permission this handler manages.
    var permission: Permission { get }

    /// The current authorization status. Always synchronous.
    var status: PermissionStatus { get }

    /// Request authorization from the user. Always asynchronous.
    func request() async -> PermissionStatus

    /// A live stream of status changes.
    var statusStream: AsyncStream<PermissionStatus> { get }

    /// Open the relevant system Settings page for this permission.
    func openSettings() async
}

/// A permission handler that can be mocked for testing.
public protocol MockablePermissionHandler: PermissionHandler {
    /// The status to return when `status` or `request()` is called.
    var stubbedStatus: PermissionStatus { get set }

    /// How many times `request()` has been called.
    var requestCallCount: Int { get }
}
