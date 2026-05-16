// MARK: - HealthHandler

#if canImport(HealthKit) && !os(tvOS)
import HealthKit
import Foundation

/// Handles HealthKit permission using HKHealthStore.
final class HealthHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    init(permission: Permission) {
        self.permission = permission
    }

    var status: PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        // HealthKit doesn't provide a general authorization status check;
        // individual type checks are needed. Return a general .notDetermined.
        return .notDetermined
    }

    func request() async -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }

        let store = HKHealthStore()

        // For a generic health permission without specific types, request step count as a representative
        let readTypes: Set<HKSampleType> = [HKQuantityType(.stepCount)]
        let writeTypes: Set<HKSampleType> = [HKQuantityType(.stepCount)]

        let typesToRead: Set<HKObjectType>?
        let typesToWrite: Set<HKSampleType>?

        switch permission {
        case .health(.read):
            typesToRead = readTypes as Set<HKObjectType>
            typesToWrite = nil
        case .health(.write):
            typesToRead = nil
            typesToWrite = writeTypes
        default:
            typesToRead = readTypes as Set<HKObjectType>
            typesToWrite = writeTypes
        }

        do {
            try await store.requestAuthorization(toShare: typesToWrite ?? [], read: typesToRead ?? [])
            let newStatus: PermissionStatus = .granted
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
}
#else
import Foundation

final class HealthHandler: PermissionHandler, @unchecked Sendable {
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
