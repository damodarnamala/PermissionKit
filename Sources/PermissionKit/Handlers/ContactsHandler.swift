// MARK: - ContactsHandler

#if canImport(Contacts)
import Contacts
import Foundation

/// Handles contacts permission using CNContactStore.
final class ContactsHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .contacts
    private let store = CNContactStore()
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        Self.mapStatus(CNContactStore.authorizationStatus(for: .contacts))
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        do {
            let granted = try await store.requestAccess(for: .contacts)
            let newStatus: PermissionStatus = granted ? .granted : .denied
            notifyStreams(newStatus)
            return newStatus
        } catch {
            return .denied
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

    private static func mapStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        #if compiler(>=5.9)
        case .limited: return .limited
        #endif
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class ContactsHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .contacts
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
