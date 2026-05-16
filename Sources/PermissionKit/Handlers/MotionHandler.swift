// MARK: - MotionHandler

#if canImport(CoreMotion) && os(iOS)
import CoreMotion
import Foundation

/// Handles motion and fitness activity permission using CMMotionActivityManager.
final class MotionHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .motion
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unknown
        }
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            let manager = CMMotionActivityManager()
            let now = Date()
            manager.queryActivityStarting(from: now.addingTimeInterval(-86400), to: now, to: .main) { [weak self] _, error in
                manager.stopActivityUpdates()
                let newStatus: PermissionStatus
                if let error = error as? CMError, error.code == .motionActivityNotAuthorized {
                    newStatus = .denied
                } else if error != nil {
                    newStatus = .denied
                } else {
                    newStatus = .granted
                }
                self?.notifyStreams(newStatus)
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
}
#else
import Foundation

final class MotionHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .motion
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
