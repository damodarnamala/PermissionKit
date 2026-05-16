// MARK: - Permission Metadata

#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

// MARK: - Human-Readable Metadata

extension Permission {
    /// Human-readable title for this permission.
    public var title: String {
        switch self {
        case .location(.whenInUse): return "Location (When In Use)"
        case .location(.always): return "Location (Always)"
        case .location(.precise): return "Precise Location"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .photos(.readWrite): return "Photos"
        case .photos(.addOnly): return "Photos (Add Only)"
        case .photos(.limited): return "Photos (Limited)"
        case .mediaLibrary: return "Media Library"
        case .contacts: return "Contacts"
        case .calendar(.read): return "Calendar (Read)"
        case .calendar(.write): return "Calendar (Write)"
        case .calendar(.fullAccess): return "Calendar"
        case .reminders: return "Reminders"
        case .notifications: return "Notifications"
        case .criticalAlerts: return "Critical Alerts"
        case .bluetooth: return "Bluetooth"
        case .localNetwork: return "Local Network"
        case .nearbyInteraction: return "Nearby Interaction"
        case .biometrics(.faceID): return "Face ID"
        case .biometrics(.touchID): return "Touch ID"
        case .biometrics(.any): return "Biometrics"
        case .tracking: return "App Tracking"
        case .siri: return "Siri"
        case .speechRecognition: return "Speech Recognition"
        case .health(.read): return "Health (Read)"
        case .health(.write): return "Health (Write)"
        case .health(.readWrite): return "Health"
        case .motion: return "Motion & Fitness"
        case .homeKit: return "HomeKit"
        case .nfc: return "NFC"
        case .screenRecording: return "Screen Recording"
        case .fullDiskAccess: return "Full Disk Access"
        case .accessibility: return "Accessibility"
        case .inputMonitoring: return "Input Monitoring"
        case .automation: return "Automation"
        case .workoutExtension: return "Workout Extension"
        case .mindfulnessSession: return "Mindfulness Session"
        }
    }

    /// Description of what this permission is used for.
    public var description: String {
        switch self {
        case .location: return "Used to access your location for navigation and nearby features."
        case .camera: return "Used to take photos and record videos."
        case .microphone: return "Used to record audio."
        case .photos: return "Used to access and save photos and videos."
        case .mediaLibrary: return "Used to access your Apple Music library."
        case .contacts: return "Used to access your contacts."
        case .calendar: return "Used to access your calendar events."
        case .reminders: return "Used to access your reminders."
        case .notifications: return "Used to send you notifications."
        case .criticalAlerts: return "Used to send critical alerts that bypass Do Not Disturb."
        case .bluetooth: return "Used to connect to Bluetooth devices."
        case .localNetwork: return "Used to discover and connect to devices on your local network."
        case .nearbyInteraction: return "Used to interact with nearby devices."
        case .biometrics: return "Used for secure authentication."
        case .tracking: return "Used to deliver personalized ads."
        case .siri: return "Used to integrate with Siri and Shortcuts."
        case .speechRecognition: return "Used to convert speech to text."
        case .health: return "Used to access your health and fitness data."
        case .motion: return "Used to access motion and fitness activity."
        case .homeKit: return "Used to control your home accessories."
        case .nfc: return "Used to read NFC tags."
        case .screenRecording: return "Used to record the contents of your screen."
        case .fullDiskAccess: return "Used to access all files on your computer."
        case .accessibility: return "Used to control your computer."
        case .inputMonitoring: return "Used to monitor keyboard and mouse input."
        case .automation: return "Used to control other applications."
        case .workoutExtension: return "Used for extended workout sessions."
        case .mindfulnessSession: return "Used for mindfulness and meditation sessions."
        }
    }

    /// Description shown when the permission has been denied.
    public var deniedDescription: String {
        "Please enable \(title) in Settings to use this feature."
    }

    /// SF Symbol name for this permission.
    public var systemImageName: String {
        switch self {
        case .location: return "location.fill"
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .photos: return "photo.fill"
        case .mediaLibrary: return "music.note"
        case .contacts: return "person.crop.circle.fill"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .notifications: return "bell.fill"
        case .criticalAlerts: return "exclamationmark.triangle.fill"
        case .bluetooth: return "wave.3.right"
        case .localNetwork: return "network"
        case .nearbyInteraction: return "sensor.tag.radiowaves.forward.fill"
        case .biometrics(.faceID): return "faceid"
        case .biometrics(.touchID): return "touchid"
        case .biometrics(.any): return "lock.shield.fill"
        case .tracking: return "hand.raised.fill"
        case .siri: return "mic.circle.fill"
        case .speechRecognition: return "waveform"
        case .health: return "heart.fill"
        case .motion: return "figure.walk"
        case .homeKit: return "house.fill"
        case .nfc: return "wave.3.forward"
        case .screenRecording: return "record.circle"
        case .fullDiskAccess: return "externaldrive.fill"
        case .accessibility: return "accessibility"
        case .inputMonitoring: return "keyboard"
        case .automation: return "gearshape.2.fill"
        case .workoutExtension: return "figure.run"
        case .mindfulnessSession: return "brain.head.profile"
        }
    }

    #if canImport(SwiftUI)
    /// SwiftUI color associated with this permission.
    @available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
    public var color: Color {
        switch self {
        case .location: return .blue
        case .camera: return .gray
        case .microphone: return .red
        case .photos: return .green
        case .mediaLibrary: return .pink
        case .contacts: return .orange
        case .calendar: return .red
        case .reminders: return .orange
        case .notifications: return .red
        case .criticalAlerts: return .red
        case .bluetooth: return .blue
        case .localNetwork: return .purple
        case .nearbyInteraction: return .blue
        case .biometrics: return .green
        case .tracking: return .orange
        case .siri: return .purple
        case .speechRecognition: return .blue
        case .health: return .red
        case .motion: return .green
        case .homeKit: return .orange
        case .nfc: return .blue
        case .screenRecording: return .gray
        case .fullDiskAccess: return .blue
        case .accessibility: return .blue
        case .inputMonitoring: return .gray
        case .automation: return .gray
        case .workoutExtension: return .green
        case .mindfulnessSession: return .teal
        }
    }
    #endif

    /// The Xcode capability identifier required for this permission, if any.
    /// Use this to determine which capabilities to enable in your target's
    /// "Signing & Capabilities" tab or in the `.entitlements` file.
    public var requiredCapability: String? {
        switch self {
        case .location: return "com.apple.security.personal-information.location"
        case .camera: return "com.apple.security.device.camera"
        case .microphone: return "com.apple.security.device.audio-input"
        case .photos: return "com.apple.security.personal-information.photos-library"
        case .mediaLibrary: return "com.apple.security.assets.music.read-write"
        case .contacts: return "com.apple.security.personal-information.addressbook"
        case .calendar, .reminders: return "com.apple.security.personal-information.calendars"
        case .notifications, .criticalAlerts: return "com.apple.developer.aps-environment"
        case .bluetooth: return "com.apple.security.device.bluetooth"
        case .localNetwork: return "com.apple.developer.networking.multicast"
        case .nearbyInteraction: return "com.apple.developer.nearby-interaction"
        case .biometrics: return nil // No entitlement needed, uses LocalAuthentication
        case .tracking: return nil // No entitlement needed
        case .siri: return "com.apple.developer.siri"
        case .speechRecognition: return nil // No entitlement needed
        case .health: return "com.apple.developer.healthkit"
        case .motion: return nil // No entitlement needed
        case .homeKit: return "com.apple.developer.homekit"
        case .nfc: return "com.apple.developer.nfc.readersession.formats"
        case .screenRecording: return nil // macOS TCC
        case .fullDiskAccess: return "com.apple.security.files.all"
        case .accessibility: return "com.apple.security.accessibility"
        case .inputMonitoring: return "com.apple.security.device.usb"
        case .automation: return "com.apple.security.automation.apple-events"
        case .workoutExtension: return "com.apple.developer.healthkit"
        case .mindfulnessSession: return "com.apple.developer.healthkit"
        }
    }

    /// The entitlements dictionary entries required for this permission, if any.
    /// Returns key-value pairs for generating `.entitlements` files.
    public var entitlements: [String: Any]? {
        switch self {
        case .health(.read), .health(.readWrite), .health(.write),
             .workoutExtension, .mindfulnessSession:
            return [
                "com.apple.developer.healthkit": true,
                "com.apple.developer.healthkit.access": ["health-records"]
            ]
        case .notifications, .criticalAlerts:
            return ["com.apple.developer.aps-environment": "development"]
        case .nfc:
            return [
                "com.apple.developer.nfc.readersession.formats": ["NDEF", "TAG"]
            ]
        case .siri:
            return ["com.apple.developer.siri": true]
        case .homeKit:
            return ["com.apple.developer.homekit": true]
        case .localNetwork:
            return ["com.apple.developer.networking.multicast": true]
        case .nearbyInteraction:
            return ["com.apple.developer.nearby-interaction": true]
        default:
            guard let cap = requiredCapability else { return nil }
            return [cap: true]
        }
    }

    /// All Info.plist keys required for this permission.
    /// Most permissions need only one; `.location(.precise)` and `.health(.readWrite)` require two.
    public var infoPlistKeys: [String] {
        switch self {
        case .location(.precise):
            return ["NSLocationWhenInUseUsageDescription", "NSLocationTemporaryFullAccuracyUsageDescription"]
        case .health(.readWrite):
            return ["NSHealthShareUsageDescription", "NSHealthUpdateUsageDescription"]
        default:
            return infoPlistKey.map { [$0] } ?? []
        }
    }

    /// The Info.plist key required for this permission, if any.
    public var infoPlistKey: String? {
        switch self {
        case .location(.whenInUse): return "NSLocationWhenInUseUsageDescription"
        case .location(.always): return "NSLocationAlwaysAndWhenInUseUsageDescription"
        case .location(.precise): return "NSLocationWhenInUseUsageDescription"
        case .camera: return "NSCameraUsageDescription"
        case .microphone: return "NSMicrophoneUsageDescription"
        case .photos(.readWrite), .photos(.limited): return "NSPhotoLibraryUsageDescription"
        case .photos(.addOnly): return "NSPhotoLibraryAddUsageDescription"
        case .mediaLibrary: return "NSAppleMusicUsageDescription"
        case .contacts: return "NSContactsUsageDescription"
        case .calendar: return "NSCalendarsUsageDescription"
        case .reminders: return "NSRemindersUsageDescription"
        case .notifications, .criticalAlerts:
            #if os(macOS)
            return "NSUserNotificationsUsageDescription"
            #else
            return nil
            #endif
        case .bluetooth: return "NSBluetoothAlwaysUsageDescription"
        case .localNetwork: return "NSLocalNetworkUsageDescription"
        case .nearbyInteraction: return "NSNearbyInteractionUsageDescription"
        case .biometrics(.faceID): return "NSFaceIDUsageDescription"
        case .biometrics(.touchID), .biometrics(.any): return "NSFaceIDUsageDescription"
        case .tracking: return "NSUserTrackingUsageDescription"
        case .siri: return "NSSiriUsageDescription"
        case .speechRecognition: return "NSSpeechRecognitionUsageDescription"
        case .health(.read), .health(.readWrite): return "NSHealthShareUsageDescription"
        case .health(.write): return "NSHealthUpdateUsageDescription"
        case .motion: return "NSMotionUsageDescription"
        case .homeKit: return "NSHomeKitUsageDescription"
        case .nfc: return "NFCReaderUsageDescription"
        case .screenRecording, .fullDiskAccess, .accessibility,
             .inputMonitoring, .automation: return nil // macOS manages via TCC
        case .workoutExtension, .mindfulnessSession: return nil // watchOS
        }
    }

    /// URL to open in system Settings for this permission, if available.
    public var settingsURL: URL? {
        #if os(iOS) || os(tvOS)
        return URL(string: "app-settings:")
        #elseif os(macOS)
        let pane: String?
        switch self {
        case .camera: pane = "Privacy_Camera"
        case .microphone: pane = "Privacy_Microphone"
        case .location: pane = "Privacy_LocationServices"
        case .photos: pane = "Privacy_Photos"
        case .contacts: pane = "Privacy_Contacts"
        case .calendar, .reminders: pane = "Privacy_Calendars"
        case .screenRecording: pane = "Privacy_ScreenCapture"
        case .fullDiskAccess: pane = "Privacy_AllFiles"
        case .accessibility: pane = "Privacy_Accessibility"
        case .inputMonitoring: pane = "Privacy_ListenEvent"
        case .automation: pane = "Privacy_Automation"
        default: pane = nil
        }
        if let pane {
            return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
        }
        return nil
        #else
        return nil
        #endif
    }

    /// Platforms where this permission is available.
    public var platforms: [Platform] {
        switch self {
        case .location, .contacts, .calendar, .reminders, .notifications,
             .bluetooth, .biometrics:
            return [.iOS, .macOS, .watchOS]
        case .camera, .microphone, .photos:
            return [.iOS, .macOS, .tvOS]
        case .mediaLibrary, .tracking, .motion, .nfc, .homeKit:
            return [.iOS]
        case .speechRecognition, .siri:
            return [.iOS, .macOS]
        case .health:
            return [.iOS, .watchOS]
        case .localNetwork:
            return [.iOS, .tvOS]
        case .nearbyInteraction:
            return [.iOS]
        case .criticalAlerts:
            return [.iOS, .watchOS]
        case .screenRecording, .fullDiskAccess, .accessibility,
             .inputMonitoring, .automation:
            return [.macOS]
        case .workoutExtension, .mindfulnessSession:
            return [.watchOS]
        }
    }
}

// MARK: - Info.plist Validation

/// Provides Info.plist key validation and reference generation.
public enum InfoPlistHelper {
    /// All Info.plist keys required for the given permissions.
    public static func requiredKeys(for permissions: [Permission]) -> [String: String] {
        var keys: [String: String] = [:]
        for permission in permissions {
            for key in permission.infoPlistKeys {
                keys[key] = permission.description
            }
        }
        return keys
    }

    /// All known permission Info.plist keys.
    public static var allKeys: [String: String] {
        [
            "NSCameraUsageDescription": "Camera access",
            "NSMicrophoneUsageDescription": "Microphone access",
            "NSLocationWhenInUseUsageDescription": "Location when in use",
            "NSLocationAlwaysAndWhenInUseUsageDescription": "Location always",
            "NSLocationTemporaryFullAccuracyUsageDescription": "Precise location (temporary full accuracy)",
            "NSPhotoLibraryUsageDescription": "Photo library read/write",
            "NSPhotoLibraryAddUsageDescription": "Photo library add only",
            "NSContactsUsageDescription": "Contacts access",
            "NSCalendarsUsageDescription": "Calendar access",
            "NSRemindersUsageDescription": "Reminders access",
            "NSBluetoothAlwaysUsageDescription": "Bluetooth access",
            "NSBluetoothPeripheralUsageDescription": "Bluetooth peripheral",
            "NSSpeechRecognitionUsageDescription": "Speech recognition",
            "NSMotionUsageDescription": "Motion and fitness",
            "NSHealthShareUsageDescription": "Health data reading",
            "NSHealthUpdateUsageDescription": "Health data writing",
            "NSHomeKitUsageDescription": "HomeKit access",
            "NSSiriUsageDescription": "Siri integration",
            "NFCReaderUsageDescription": "NFC reader",
            "NSFaceIDUsageDescription": "Face ID authentication",
            "NSUserTrackingUsageDescription": "App tracking transparency",
            "NSLocalNetworkUsageDescription": "Local network discovery",
            "NSNearbyInteractionUsageDescription": "Nearby interaction (UWB)",
            "NSAppleMusicUsageDescription": "Apple Music / media library",
            "NSUserNotificationsUsageDescription": "User notifications (macOS sandboxed apps)",
        ]
    }

    /// Validate that the bundle's Info.plist contains required keys for the given permissions.
    /// Returns missing keys.
    public static func validateInfoPlist(
        for permissions: [Permission],
        in bundle: Bundle = .main
    ) -> [String] {
        var seen = Set<String>()
        var missing: [String] = []
        for permission in permissions {
            for key in permission.infoPlistKeys {
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                if bundle.object(forInfoDictionaryKey: key) == nil {
                    missing.append(key)
                }
            }
        }
        return missing
    }
}
