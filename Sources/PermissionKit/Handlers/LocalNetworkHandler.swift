// MARK: - LocalNetworkHandler

import Foundation

/// Handles local network permission.
///
/// Local network permission on iOS/tvOS is triggered implicitly by network activity.
/// There is no direct API to request or check the status.
final class LocalNetworkHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .localNetwork
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // Local network permission has no direct status API
        .notDetermined
    }

    func request() async -> PermissionStatus {
        // Triggering a local network connection will prompt the user.
        // We attempt a dummy multicast connection to trigger the prompt.
        #if os(iOS) || os(tvOS)
        return await withCheckedContinuation { continuation in
            let connection = NWBrowserStub()
            connection.trigger { [weak self] granted in
                let newStatus: PermissionStatus = granted ? .granted : .denied
                self?.notifyStreams(newStatus)
                continuation.resume(returning: newStatus)
            }
        }
        #else
        return .unknown
        #endif
    }

    var statusStream: AsyncStream<PermissionStatus> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else { continuation.finish(); return }
            self.lock.lock()
            self.streamContinuations[id] = continuation
            self.lock.unlock()
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.lock.lock()
                self?.streamContinuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
            continuation.yield(self.status)
        }
    }

    func openSettings() async {
        await MainActor.run { SettingsOpener.openAppSettings() }
    }

    private func notifyStreams(_ status: PermissionStatus) {
        lock.lock()
        let streams = Array(streamContinuations.values)
        lock.unlock()
        for s in streams { s.yield(status) }
    }
}

// MARK: - NWBrowser Stub

/// A lightweight stub for triggering local network permission dialog.
private final class NWBrowserStub: @unchecked Sendable {
    func trigger(completion: @escaping (Bool) -> Void) {
        // In a real implementation, this would use NWBrowser from Network.framework
        // to browse for services, triggering the local network permission prompt.
        // The result would indicate whether the user granted access.
        completion(false)
    }
}
