// MARK: - ConditionalChain

import Foundation

/// A fluent builder for chaining permission requests with conditional logic.
///
/// ```swift
/// await Permission
///     .request(.location(.whenInUse))
///     .then(if: .granted) { await Permission.notifications.request() }
///     .onDenied { showLocationDeniedUI() }
///     .onRestricted { showParentalControlUI() }
/// ```
public struct ConditionalChain: Sendable {
    /// All results accumulated during the chain.
    public let results: [PermissionResult]

    /// The most recent result in the chain.
    public var lastResult: PermissionResult? {
        results.last
    }

    /// The status of the most recent result.
    public var lastStatus: PermissionStatus {
        lastResult?.status ?? .unknown
    }

    public init(results: [PermissionResult]) {
        self.results = results
    }

    // MARK: - Conditional Chaining

    /// Request the next permission only if the previous result matches the given status.
    @discardableResult
    public func then(
        if condition: PermissionStatus,
        _ action: @Sendable () async -> PermissionStatus
    ) async -> ConditionalChain {
        guard lastStatus == condition else { return self }
        let status = await action()
        let result = PermissionResult(
            permission: lastResult?.permission ?? .camera,
            status: status,
            timestamp: Date()
        )
        return ConditionalChain(results: results + [result])
    }

    /// Execute a callback if the last permission was denied.
    @discardableResult
    public func onDenied(_ action: @Sendable () async -> Void) async -> ConditionalChain {
        if lastStatus == .denied {
            await action()
        }
        return self
    }

    /// Execute a callback if the last permission was restricted.
    @discardableResult
    public func onRestricted(_ action: @Sendable () async -> Void) async -> ConditionalChain {
        if lastStatus == .restricted {
            await action()
        }
        return self
    }

    /// Execute a callback if the last permission was granted.
    @discardableResult
    public func onGranted(_ action: @Sendable () async -> Void) async -> ConditionalChain {
        if lastStatus == .granted {
            await action()
        }
        return self
    }

    /// Execute a callback if the user needs to go to Settings.
    @discardableResult
    public func onSettingsNeeded(_ action: @Sendable () async -> Void) async -> ConditionalChain {
        if lastStatus.shouldShowSettings {
            await action()
        }
        return self
    }
}
