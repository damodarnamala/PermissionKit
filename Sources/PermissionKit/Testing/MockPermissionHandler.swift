// MARK: - MockPermissionHandler

import Foundation

/// A configurable mock handler for testing permission flows.
///
/// ```swift
/// let mock = MockPermissionHandler(permission: .camera, status: .denied)
/// PermissionKit.setHandler(mock, for: .camera)
/// let status = await Permission.camera.request()
/// XCTAssertEqual(status, .denied)
/// XCTAssertEqual(mock.requestCallCount, 1)
/// ```
public final class MockPermissionHandler: MockablePermissionHandler, @unchecked Sendable {

    public let permission: Permission

    private let lock = NSLock()
    private var _stubbedStatus: PermissionStatus
    private var _requestCallCount: Int = 0
    private var _continuation: AsyncStream<PermissionStatus>.Continuation?
    private var _statusStream: AsyncStream<PermissionStatus>?

    /// Simulated delay for async request (in seconds).
    public var requestDelay: TimeInterval = 0

    /// Callback invoked each time `request()` is called.
    public var onRequest: (() -> Void)?

    public var stubbedStatus: PermissionStatus {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _stubbedStatus
        }
        set {
            lock.lock()
            _stubbedStatus = newValue
            let cont = _continuation
            lock.unlock()
            cont?.yield(newValue)
        }
    }

    public var requestCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _requestCallCount
    }

    public var status: PermissionStatus {
        stubbedStatus
    }

    public init(permission: Permission, status: PermissionStatus = .notDetermined) {
        self.permission = permission
        self._stubbedStatus = status

        var cont: AsyncStream<PermissionStatus>.Continuation!
        self._statusStream = AsyncStream { continuation in
            cont = continuation
        }
        self._continuation = cont
    }

    public func request() async -> PermissionStatus {
        if requestDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        let result = lock.withLock {
            _requestCallCount += 1
            return _stubbedStatus
        }
        onRequest?()
        return result
    }

    public var statusStream: AsyncStream<PermissionStatus> {
        lock.lock()
        defer { lock.unlock() }
        return _statusStream!
    }

    public func openSettings() async {
        // No-op in tests
    }

    /// Simulate a status change (as if the user changed it in Settings).
    public func simulateStatusChange(to newStatus: PermissionStatus) {
        stubbedStatus = newStatus
    }

    /// Reset call counts and state.
    public func reset() {
        lock.lock()
        _requestCallCount = 0
        lock.unlock()
    }
}
