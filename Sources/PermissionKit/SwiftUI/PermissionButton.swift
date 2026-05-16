// MARK: - PermissionButton

#if canImport(SwiftUI)
import SwiftUI

/// A button that requests a permission when tapped and displays the current status.
///
/// ```swift
/// PermissionButton(.camera, label: "Enable Camera")
/// ```
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PermissionButton: View {

    private let permission: Permission
    private let label: String

    @State private var status: PermissionStatus = .notDetermined
    @State private var isRequesting = false

    /// Creates a permission button.
    /// - Parameters:
    ///   - permission: The permission to request.
    ///   - label: The button label text.
    public init(_ permission: Permission, label: String) {
        self.permission = permission
        self.label = label
    }

    public var body: some View {
        Button {
            guard !isRequesting else { return }
            Task {
                isRequesting = true
                status = await permission.request()
                isRequesting = false

                if status.shouldShowSettings {
                    await permission.openSettings()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isRequesting {
                    ProgressView()
                        #if !os(watchOS) && !os(tvOS)
                        .controlSize(.small)
                        #endif
                } else {
                    Image(systemName: permission.systemImageName)
                }
                Text(buttonTitle)
            }
        }
        .disabled(status == .granted || status == .restricted)
        .accessibilityLabel("\(label), \(status.accessibilityDescription)")
        .task {
            status = permission.status
        }
    }

    private var buttonTitle: String {
        switch status {
        case .granted: return "Enabled"
        case .denied: return "Open Settings"
        case .restricted: return "Restricted"
        case .limited: return "Limited Access"
        default: return label
        }
    }
}

extension PermissionStatus {
    var accessibilityDescription: String {
        switch self {
        case .notDetermined: return "Not yet requested"
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .limited: return "Limited access"
        case .provisional: return "Provisional"
        case .unknown: return "Unknown"
        }
    }
}
#endif
