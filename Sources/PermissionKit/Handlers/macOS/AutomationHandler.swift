// MARK: - AutomationHandler (macOS)

#if os(macOS)
import Foundation
import AppKit

/// Handles automation / AppleScript permission on macOS.
final class AutomationHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .automation
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // Automation permission is per-target-app and can't be checked generically.
        .notDetermined
    }

    func request() async -> PermissionStatus {
        await openSettings()
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
        await MainActor.run {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
#endif
