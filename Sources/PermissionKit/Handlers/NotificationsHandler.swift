// MARK: - NotificationsHandler

#if canImport(UserNotifications)
import UserNotifications
import Foundation

/// Handles push notification permissions using UNUserNotificationCenter.
final class NotificationsHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    init(permission: Permission) {
        self.permission = permission
    }

    var status: PermissionStatus {
        // Reading notification status requires async; return cached or poll.
        // For synchronous access we use a semaphore-based check (acceptable for notification status).
        var result: PermissionStatus = .unknown
        let semaphore = DispatchSemaphore(value: 0)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            result = Self.mapStatus(settings.authorizationStatus)
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }

    func request() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let current = Self.mapStatus(settings.authorizationStatus)
        guard current == .notDetermined else { return current }

        var options: UNAuthorizationOptions = []

        switch permission {
        case .notifications(let opts):
            if opts.alert { options.insert(.alert) }
            if opts.badge { options.insert(.badge) }
            if opts.sound { options.insert(.sound) }
            if opts.criticalAlert { options.insert(.criticalAlert) }
            if opts.provisional { options.insert(.provisional) }
        case .criticalAlerts:
            options = [.alert, .badge, .sound, .criticalAlert]
        default:
            options = [.alert, .badge, .sound]
        }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            let newStatus: PermissionStatus
            if case .notifications(let opts) = permission, opts.provisional {
                newStatus = .provisional
            } else {
                newStatus = granted ? .granted : .denied
            }
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

    private static func mapStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .granted
        case .denied: return .denied
        case .provisional: return .provisional
        case .ephemeral: return .granted
        @unknown default: return .unknown
        }
    }
}
#else
import Foundation

final class NotificationsHandler: PermissionHandler, @unchecked Sendable {
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
