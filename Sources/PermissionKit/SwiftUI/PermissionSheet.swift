// MARK: - PermissionSheet

#if canImport(SwiftUI)
import SwiftUI

/// A modal sheet view for requesting a single permission with built-in UI.
///
/// Auto-populates icon, title, and description from Permission metadata.
///
/// ```swift
/// .sheet(isPresented: $showSheet) {
///     PermissionSheet(.camera) { status in
///         showSheet = false
///     }
/// }
/// ```
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PermissionSheet: View {

    private let permission: Permission
    private let onResult: ((PermissionStatus) -> Void)?

    @State private var status: PermissionStatus = .notDetermined
    @State private var isRequesting = false

    /// Creates a permission sheet.
    /// - Parameters:
    ///   - permission: The permission to request.
    ///   - onResult: Callback with the resulting status.
    public init(_ permission: Permission, onResult: ((PermissionStatus) -> Void)? = nil) {
        self.permission = permission
        self.onResult = onResult
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: permission.systemImageName)
                .font(.system(size: 56))
                .foregroundColor(permission.color)
                .accessibilityHidden(true)

            // Title
            Text(permission.title)
                .font(.title.bold())

            // Description
            Text(status.isDenied ? permission.deniedDescription : permission.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Action button
            Button {
                Task {
                    isRequesting = true
                    if status.shouldShowSettings {
                        await permission.openSettings()
                    } else {
                        status = await permission.request()
                    }
                    isRequesting = false
                    onResult?(status)
                }
            } label: {
                Group {
                    if isRequesting {
                        ProgressView()
                    } else {
                        Text(buttonLabel)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(status == .granted || status == .restricted)
            .padding(.horizontal, 24)

            // Not Now
            Button("Not Now") {
                onResult?(status)
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 24)
        }
        .task {
            status = permission.status
        }
    }

    private var buttonLabel: String {
        switch status {
        case .denied: return "Open Settings"
        case .granted: return "Already Enabled"
        case .restricted: return "Restricted"
        default: return "Allow \(permission.title)"
        }
    }
}
#endif
