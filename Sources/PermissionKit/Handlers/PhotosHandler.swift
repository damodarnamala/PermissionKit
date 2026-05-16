// MARK: - PhotosHandler

#if canImport(Photos)
import Photos
import Foundation

/// Handles photo library permissions using PHPhotoLibrary.
final class PhotosHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    init(permission: Permission) {
        self.permission = permission
    }

    var status: PermissionStatus {
        let level: PHAccessLevel
        switch permission {
        case .photos(.addOnly): level = .addOnly
        default: level = .readWrite
        }
        return Self.mapStatus(PHPhotoLibrary.authorizationStatus(for: level))
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        let level: PHAccessLevel
        switch permission {
        case .photos(.addOnly): level = .addOnly
        default: level = .readWrite
        }

        let phStatus = await PHPhotoLibrary.requestAuthorization(for: level)
        let newStatus = Self.mapStatus(phStatus)
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

    private static func mapStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .limited: return .limited
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class PhotosHandler: PermissionHandler, @unchecked Sendable {
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
