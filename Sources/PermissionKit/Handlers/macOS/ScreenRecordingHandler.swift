// MARK: - ScreenRecordingHandler (macOS)

#if os(macOS)
import Foundation
import AppKit
import CoreGraphics

/// Handles screen recording permission on macOS.
/// Uses CGWindowListCopyWindowInfo to detect permission status.
final class ScreenRecordingHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .screenRecording
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // On macOS, screen recording permission can be checked by attempting
        // to capture a window list with names. If names are nil, permission is denied.
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        let hasNames = windowList.contains { ($0[kCGWindowName as String] as? String) != nil }
        return hasNames ? .granted : .denied
    }

    func request() async -> PermissionStatus {
        // macOS doesn't have a direct API to request screen recording.
        // We open System Settings to the relevant pane.
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
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
#endif
