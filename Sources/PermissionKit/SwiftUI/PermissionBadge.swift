// MARK: - PermissionBadge

#if canImport(SwiftUI)
import SwiftUI

/// A small status indicator that shows the current permission state.
///
/// Color coding: green = granted, red = denied, yellow = not determined, gray = restricted.
///
/// ```swift
/// PermissionBadge(.location(.always))
/// ```
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PermissionBadge: View {

    private let permission: Permission

    @State private var status: PermissionStatus = .notDetermined
    @State private var isPulsing = false

    /// Creates a permission badge.
    /// - Parameter permission: The permission to display status for.
    public init(_ permission: Permission) {
        self.permission = permission
    }

    public var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(
                status == .notDetermined
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .accessibilityLabel("\(permission.title) permission: \(status.accessibilityDescription)")
            .task {
                status = permission.status
                isPulsing = status == .notDetermined
            }
            .task {
                for await newStatus in permission.statusStream {
                    status = newStatus
                    isPulsing = newStatus == .notDetermined
                }
            }
    }

    private var statusColor: Color {
        switch status {
        case .granted: return .green
        case .denied: return .red
        case .notDetermined: return .yellow
        case .restricted: return .gray
        case .limited: return .orange
        case .provisional: return .blue
        case .unknown: return .gray
        }
    }
}
#endif
