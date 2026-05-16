// MARK: - BiometricHandler

#if canImport(LocalAuthentication)
import LocalAuthentication
import Foundation

/// Handles biometric authentication (Face ID / Touch ID) using LAContext.
final class BiometricHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    init(permission: Permission) {
        self.permission = permission
    }

    var status: PermissionStatus {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .granted
        }
        if let error = error {
            switch error.code {
            case LAError.biometryNotAvailable.rawValue: return .restricted
            case LAError.biometryNotEnrolled.rawValue: return .denied
            case LAError.biometryLockout.rawValue: return .denied
            default: return .notDetermined
            }
        }
        return .notDetermined
    }

    func request() async -> PermissionStatus {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to continue"
            )
            let newStatus: PermissionStatus = success ? .granted : .denied
            notifyStreams(newStatus)
            return newStatus
        } catch {
            let newStatus: PermissionStatus = .denied
            notifyStreams(newStatus)
            return newStatus
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

final class BiometricHandler: PermissionHandler, @unchecked Sendable {
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
