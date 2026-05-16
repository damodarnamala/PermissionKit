// MARK: - AccessibilityHandler (macOS)

#if os(macOS)
import Foundation
import AppKit
import ApplicationServices

/// Handles accessibility permission on macOS using AXIsProcessTrustedWithOptions.
final class AccessibilityHandler: PermissionHandler, @unchecked Sendable {

    let permission: Permission = .accessibility
    private let lock = NSLock()
    private var streamContinuations: [UUID: AsyncStream<PermissionStatus>.Continuation] = [:]

    var status: PermissionStatus {
        let trusted = AXIsProcessTrusted()
        return trusted ? .granted : .denied
    }

    func request() async -> PermissionStatus {
        // Prompt the system dialog by passing prompt=true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        let newStatus: PermissionStatus = trusted ? .granted : .denied
        notifyStreams(newStatus)
        return newStatus
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
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func notifyStreams(_ status: PermissionStatus) {
        lock.lock()
        let streams = Array(streamContinuations.values)
        lock.unlock()
        for s in streams { s.yield(status) }
    }
}
#endif
