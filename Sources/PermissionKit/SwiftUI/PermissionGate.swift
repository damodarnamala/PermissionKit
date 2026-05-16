// MARK: - PermissionGate

#if canImport(SwiftUI)
import SwiftUI

/// A view that displays different content based on the current permission status.
///
/// ```swift
/// PermissionGate(.camera) {
///     LiveCameraFeed()
/// } denied: {
///     PermissionDeniedView()
/// } restricted: {
///     RestrictedView()
/// }
/// ```
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PermissionGate<Granted: View, Denied: View, Restricted: View>: View {

    private let permission: Permission
    private let autoRequest: Bool
    private let granted: () -> Granted
    private let denied: () -> Denied
    private let restricted: () -> Restricted

    @State private var status: PermissionStatus = .notDetermined
    @State private var isLoading = false

    /// Creates a permission gate with views for each authorization state.
    /// - Parameters:
    ///   - permission: The permission to observe.
    ///   - autoRequest: Whether to automatically request the permission on appear. Defaults to `true`.
    ///   - granted: View to show when permission is granted.
    ///   - denied: View to show when permission is denied.
    ///   - restricted: View to show when permission is restricted.
    public init(
        _ permission: Permission,
        autoRequest: Bool = true,
        @ViewBuilder granted: @escaping () -> Granted,
        @ViewBuilder denied: @escaping () -> Denied,
        @ViewBuilder restricted: @escaping () -> Restricted
    ) {
        self.permission = permission
        self.autoRequest = autoRequest
        self.granted = granted
        self.denied = denied
        self.restricted = restricted
    }

    public var body: some View {
        Group {
            switch status {
            case .granted, .limited, .provisional:
                granted()
            case .denied:
                denied()
            case .restricted:
                restricted()
            case .notDetermined, .unknown:
                if isLoading {
                    ProgressView()
                        .accessibilityLabel("Requesting permission")
                } else {
                    denied()
                }
            }
        }
        .animation(.default, value: status)
        .task {
            status = permission.status
            if autoRequest && status == .notDetermined {
                isLoading = true
                status = await permission.request()
                isLoading = false
            }
        }
        .task {
            for await newStatus in permission.statusStream {
                status = newStatus
            }
        }
    }
}

// MARK: - Convenience Initializer (without restricted)

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension PermissionGate where Restricted == Denied {
    /// Creates a permission gate with a shared view for denied and restricted states.
    public init(
        _ permission: Permission,
        autoRequest: Bool = true,
        @ViewBuilder granted: @escaping () -> Granted,
        @ViewBuilder denied: @escaping () -> Denied
    ) {
        self.init(
            permission,
            autoRequest: autoRequest,
            granted: granted,
            denied: denied,
            restricted: denied
        )
    }
}
#endif
