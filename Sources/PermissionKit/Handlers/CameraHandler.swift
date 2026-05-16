// MARK: - CameraHandler

#if canImport(AVFoundation) && !os(watchOS)
import AVFoundation
import Foundation

/// Handles camera permission using AVCaptureDevice.
final class CameraHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .camera
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        Self.mapStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        let newStatus: PermissionStatus = granted ? .granted : .denied
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

    private static func mapStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
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

final class CameraHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .camera
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
