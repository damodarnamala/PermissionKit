// MARK: - NFCHandler

#if canImport(CoreNFC) && os(iOS)
import CoreNFC
import Foundation

/// Handles NFC reader session permission.
final class NFCHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .nfc
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        if NFCNDEFReaderSession.readingAvailable {
            return .granted
        }
        return .restricted
    }

    func request() async -> PermissionStatus {
        // NFC doesn't have a traditional permission prompt.
        // Availability is hardware-based.
        return status
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

final class NFCHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .nfc
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
