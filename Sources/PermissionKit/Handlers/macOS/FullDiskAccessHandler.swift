// MARK: - FullDiskAccessHandler (macOS)

#if os(macOS)
import Foundation
import AppKit

/// Handles full disk access permission on macOS.
/// Checks by attempting to read a protected directory.
final class FullDiskAccessHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .fullDiskAccess
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        // Check if we can access a protected path
        let protectedPaths = [
            NSHomeDirectory() + "/Library/Mail",
            NSHomeDirectory() + "/Library/Safari/Bookmarks.plist",
            "/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        for path in protectedPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return .granted
            }
        }
        return .denied
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
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
#endif
