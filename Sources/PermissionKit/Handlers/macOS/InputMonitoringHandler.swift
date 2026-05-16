// MARK: - InputMonitoringHandler (macOS)

#if os(macOS)
import Foundation
import AppKit

/// Handles input monitoring permission on macOS.
/// Input monitoring allows apps to monitor keyboard and mouse input.
final class InputMonitoringHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .inputMonitoring
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // Input monitoring can be coarsely checked via IOHIDCheckAccess
        // or by trying to install an event tap. We default to .notDetermined.
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
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
#endif
