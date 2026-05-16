// MARK: - MediaLibraryHandler

#if canImport(MediaPlayer) && os(iOS)
import MediaPlayer
import Foundation

/// Handles Apple Music / media library permission.
final class MediaLibraryHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .mediaLibrary
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        Self.mapStatus(MPMediaLibrary.authorizationStatus())
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { authStatus in
                let newStatus = Self.mapStatus(authStatus)
                self.notifyStreams(newStatus)
                continuation.resume(returning: newStatus)
            }
        }
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

    private static func mapStatus(_ status: MPMediaLibraryAuthorizationStatus) -> PermissionStatus {
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

final class MediaLibraryHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .mediaLibrary
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
