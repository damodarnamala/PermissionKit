// MARK: - TrackingHandler

#if canImport(AppTrackingTransparency) && !os(macOS) && !os(watchOS) && !os(tvOS)
import AppTrackingTransparency
import Foundation

/// Handles App Tracking Transparency permission.
final class TrackingHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .tracking
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        Self.mapStatus(ATTrackingManager.trackingAuthorizationStatus)
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        let attStatus = await ATTrackingManager.requestTrackingAuthorization()
        let newStatus = Self.mapStatus(attStatus)
        notifyStreams(newStatus)
        return newStatus
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

    private static func mapStatus(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class TrackingHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .tracking
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
