// MARK: - RemindersHandler

#if canImport(EventKit)
import EventKit
import Foundation

/// Handles reminders permission using EKEventStore.
final class RemindersHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .reminders
    private let store = EKEventStore()
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        Self.mapStatus(EKEventStore.authorizationStatus(for: .reminder))
    }

    func request() async -> PermissionStatus {
        let current = status
        guard current == .notDetermined else { return current }

        do {
            #if compiler(>=5.9)
            if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
                let granted = try await store.requestFullAccessToReminders()
                let newStatus: PermissionStatus = granted ? .granted : .denied
                notifyStreams(newStatus)
                return newStatus
            }
            #endif
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .reminder) { granted, _ in
                    let newStatus: PermissionStatus = granted ? .granted : .denied
                    self.notifyStreams(newStatus)
                    continuation.resume(returning: newStatus)
                }
            }
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

    private static func mapStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .fullAccess, .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .writeOnly: return .limited
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class RemindersHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .reminders
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
