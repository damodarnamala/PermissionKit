// MARK: - HomeKitHandler

#if canImport(HomeKit) && !os(tvOS) && !os(watchOS)
import HomeKit
import Foundation

/// Handles HomeKit permission using HMHomeManager.
final class HomeKitHandler: NSObject, PermissionHandler, @unchecked Sendable {

    let permission: Permission = .homeKit
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // HomeKit doesn't provide a direct status check; assume notDetermined
        .notDetermined
    }

    func request() async -> PermissionStatus {
        // Creating an HMHomeManager triggers the authorization prompt
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let manager = HMHomeManager()
                // HMHomeManager fires its delegate when authorization resolves
                // For simplicity, we wait briefly and check
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let newStatus: PermissionStatus = manager.homes.isEmpty ? .notDetermined : .granted
                    continuation.resume(returning: newStatus)
                    _ = manager // Keep alive
                }
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
}
#else
import Foundation

final class HomeKitHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .homeKit
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
