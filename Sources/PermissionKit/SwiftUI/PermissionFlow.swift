// MARK: - PermissionFlow

#if canImport(SwiftUI)
import SwiftUI

/// A multi-step onboarding flow that requests permissions in sequence.
///
/// ```swift
/// PermissionFlow(permissions: [.location(.whenInUse), .notifications, .camera]) { step, permission, status in
///     OnboardingPermissionCard(
///         icon: permission.icon,
///         title: permission.title,
///         description: permission.description,
///         status: status
///     )
/// }
/// ```
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct PermissionFlow<Card: View>: View {

    private let permissions: [Permission]
    private let skippable: Set<Permission>
    private let card: (Int, Permission, PermissionStatus) -> Card
    private let onComplete: (([PermissionResult]) -> Void)?

    @State private var currentStep = 0
    @State private var statuses: [PermissionStatus] = []
    @State private var results: [PermissionResult] = []
    @State private var isRequesting = false

    /// Creates a permission flow.
    /// - Parameters:
    ///   - permissions: The permissions to request in order.
    ///   - skippable: Permissions that can be skipped. Defaults to empty.
    ///   - onComplete: Callback when all permissions have been handled.
    ///   - card: A view builder for each permission step.
    public init(
        permissions: [Permission],
        skippable: Set<Permission> = [],
        onComplete: (([PermissionResult]) -> Void)? = nil,
        @ViewBuilder card: @escaping (Int, Permission, PermissionStatus) -> Card
    ) {
        self.permissions = permissions
        self.skippable = skippable
        self.onComplete = onComplete
        self.card = card
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            progressView

            if currentStep < permissions.count {
                let permission = permissions[currentStep]
                let status = currentStep < statuses.count ? statuses[currentStep] : .notDetermined

                card(currentStep, permission, status)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                buttonsView(permission: permission, status: status)
            } else {
                completionView
            }
        }
        .animation(.default, value: currentStep)
        .onAppear {
            statuses = permissions.map { $0.status }
        }
    }

    private var progressView: some View {
        HStack(spacing: 4) {
            ForEach(0..<permissions.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .accessibilityLabel("Step \(currentStep + 1) of \(permissions.count)")
    }

    @ViewBuilder
    private func buttonsView(permission: Permission, status: PermissionStatus) -> some View {
        VStack(spacing: 12) {
            if status == .notDetermined {
                Button {
                    Task {
                        isRequesting = true
                        let newStatus = await permission.request()
                        if currentStep < statuses.count {
                            statuses[currentStep] = newStatus
                        }
                        results.append(PermissionResult(
                            permission: permission,
                            status: newStatus,
                            timestamp: Date()
                        ))
                        isRequesting = false
                        advanceStep()
                    }
                } label: {
                    if isRequesting {
                        ProgressView()
                    } else {
                        Text("Allow \(permission.title)")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
            } else {
                Button("Continue") {
                    results.append(PermissionResult(
                        permission: permission,
                        status: status,
                        timestamp: Date()
                    ))
                    advanceStep()
                }
                .buttonStyle(.borderedProminent)
            }

            if skippable.contains(permission) {
                Button("Skip") {
                    results.append(PermissionResult(
                        permission: permission,
                        status: .notDetermined,
                        timestamp: Date()
                    ))
                    advanceStep()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            Text("All Set!")
                .font(.title2.bold())
        }
        .onAppear {
            onComplete?(results)
        }
    }

    private func advanceStep() {
        withAnimation {
            currentStep += 1
        }
    }
}
#endif
