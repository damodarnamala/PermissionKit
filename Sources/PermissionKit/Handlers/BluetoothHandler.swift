// MARK: - BluetoothHandler

#if canImport(CoreBluetooth) && !os(tvOS)
import CoreBluetooth
import Foundation

/// Handles Bluetooth permission using CBCentralManager.
final class BluetoothHandler: NSObject, PermissionHandler, CBCentralManagerDelegate, @unchecked Sendable {

    let permission: Permission = .bluetooth
    private let lock = NSLock()
    private var manager: CBCentralManager?
    private var requestContinuation: CheckedContinuation<PermissionStatus, Never>?
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        switch CBCentralManager.authorization {
        case .notDetermined: return .notDetermined
        case .allowedAlways: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .unknown
        }
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            lock.lock()
            self.requestContinuation = continuation
            lock.unlock()

            DispatchQueue.main.async {
                // Creating the CBCentralManager triggers the authorization prompt
                self.manager = CBCentralManager(delegate: self, queue: nil)
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

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let newStatus = status

        lock.lock()
        let continuation = requestContinuation
        requestContinuation = nil
        let streams = Array(streamContinuations.values)
        lock.unlock()

        continuation?.resume(returning: newStatus)
        for s in streams { s.yield(newStatus) }
    }
}
#else
import Foundation

final class BluetoothHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .bluetooth
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
