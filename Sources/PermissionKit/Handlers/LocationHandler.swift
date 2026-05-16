// MARK: - LocationHandler

#if canImport(CoreLocation)
import CoreLocation
import Foundation

/// Handles location permission requests using CLLocationManager.
final class LocationHandler: NSObject, PermissionHandler, CLLocationManagerDelegate, @unchecked Sendable {

    let permission: Permission
    private let manager = CLLocationManager()
    private let lock = NSLock()
    private var requestContinuation: CheckedContinuation<PermissionStatus, Never>?
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    init(permission: Permission) {
        self.permission = permission
        super.init()
        manager.delegate = self
    }

    var status: PermissionStatus {
        Self.mapStatus(manager.authorizationStatus)
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            lock.lock()
            self.requestContinuation = continuation
            lock.unlock()

            DispatchQueue.main.async {
                switch self.permission {
                case .location(.always):
                    self.manager.requestAlwaysAuthorization()
                default:
                    self.manager.requestWhenInUseAuthorization()
                }
            }
        }
    }

    var statusStream: AsyncStream<PermissionStatus> {
        let id = UUID()
        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
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

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = Self.mapStatus(manager.authorizationStatus)

        lock.lock()
        let continuation = requestContinuation
        requestContinuation = nil
        let streams = Array(streamContinuations.values)
        lock.unlock()

        continuation?.resume(returning: newStatus)
        for stream in streams {
            stream.yield(newStatus)
        }
    }

    // MARK: - Status Mapping

    private static func mapStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse: return .granted
        case .authorizedAlways: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class LocationHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission
    init(permission: Permission) { self.permission = permission }
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
