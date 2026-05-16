// MARK: - watchOS Handlers

import Foundation

#if os(watchOS)
import HealthKit

/// Handles workout extension permission on watchOS.
final class WorkoutExtensionHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .workoutExtension

    var status: PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        return .notDetermined
    }

    func request() async -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        let store = HKHealthStore()
        let workoutType = HKQuantityType(.activeEnergyBurned)
        do {
            try await store.requestAuthorization(toShare: [workoutType], read: [workoutType])
            return .granted
        } catch {
            return .denied
        }
    }

    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            continuation.yield(self.status)
            continuation.finish()
        }
    }

    func openSettings() async {}
}

/// Handles mindfulness session permission on watchOS.
final class MindfulnessSessionHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .mindfulnessSession

    var status: PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        return .notDetermined
    }

    func request() async -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .restricted }
        let store = HKHealthStore()
        let mindfulType = HKCategoryType(.mindfulSession)
        do {
            try await store.requestAuthorization(toShare: [mindfulType], read: [mindfulType])
            return .granted
        } catch {
            return .denied
        }
    }

    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            continuation.yield(self.status)
            continuation.finish()
        }
    }

    func openSettings() async {}
}
#else

final class WorkoutExtensionHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .workoutExtension
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}

final class MindfulnessSessionHandler: PermissionHandler, @unchecked Sendable {
    let permission: Permission = .mindfulnessSession
    var status: PermissionStatus { .unknown }
    func request() async -> PermissionStatus { .unknown }
    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { $0.yield(.unknown); $0.finish() }
    }
    func openSettings() async {}
}
#endif
