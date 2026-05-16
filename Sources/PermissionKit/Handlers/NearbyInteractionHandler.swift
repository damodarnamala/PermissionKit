// MARK: - NearbyInteractionHandler

import Foundation

/// Handles nearby interaction (UWB) permission.
///
/// Nearby Interaction permission is granted per-session and doesn't have
/// a persistent API like other permissions.
final class NearbyInteractionHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .nearbyInteraction

    var status: PermissionStatus {
        #if canImport(NearbyInteraction) && os(iOS)
        return .notDetermined
        #else
        return .unknown
        #endif
    }

    func request() async -> PermissionStatus {
        #if canImport(NearbyInteraction) && os(iOS)
        // NISession permission is granted per-session when configured.
        // No direct API to pre-request.
        return .notDetermined
        #else
        return .unknown
        #endif
    }

    var statusStream: AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            continuation.yield(self.status)
            continuation.finish()
        }
    }

    func openSettings() async {
        await MainActor.run { SettingsOpener.openAppSettings() }
    }
}
