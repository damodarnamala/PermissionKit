// MARK: - PermissionManifest

import Foundation

/// A declarative manifest of permissions your app uses.
///
/// Define a manifest of all permissions your app needs, then use
/// `PermissionPlistGenerator` to automatically produce the required
/// Info.plist entries and `.entitlements` file contents.
///
/// ```swift
/// let manifest = PermissionManifest(permissions: [
///     .entry(.camera, usage: "Take photos for your profile"),
///     .entry(.microphone, usage: "Record voice messages"),
///     .entry(.location(.whenInUse), usage: "Show nearby places"),
///     .entry(.notifications(.default), usage: "Send order updates"),
///     .entry(.health(.readWrite), usage: "Track your workouts"),
/// ])
///
/// // Generate Info.plist XML
/// let plistXML = manifest.generateInfoPlistEntries()
///
/// // Generate entitlements dictionary
/// let entitlements = manifest.generateEntitlements()
/// ```
public struct PermissionManifest: Sendable {

    /// A single permission entry with its usage description.
    public struct Entry: Sendable {
        public let permission: Permission
        public let usageDescription: String

        public init(permission: Permission, usageDescription: String) {
            self.permission = permission
            self.usageDescription = usageDescription
        }
    }

    /// Convenience factory for creating entries.
    public static func entry(_ permission: Permission, usage: String) -> Entry {
        Entry(permission: permission, usageDescription: usage)
    }

    public let entries: [Entry]

    public init(permissions: [Entry]) {
        self.entries = permissions
    }

    // MARK: - Info.plist Generation

    /// Generate Info.plist XML entries for all permissions in this manifest.
    /// Returns XML string fragment to paste into your Info.plist.
    public func generateInfoPlistEntries() -> String {
        var lines: [String] = []
        var seenKeys = Set<String>()

        for entry in entries {
            for key in entry.permission.infoPlistKeys {
                guard !seenKeys.contains(key) else { continue }
                seenKeys.insert(key)

                lines.append("\t<key>\(escapeXML(key))</key>")
                lines.append("\t<string>\(escapeXML(entry.usageDescription))</string>")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Generate a complete Info.plist XML file with all required privacy keys.
    public func generateInfoPlist(
        bundleIdentifier: String = "$(PRODUCT_BUNDLE_IDENTIFIER)",
        bundleName: String = "$(PRODUCT_NAME)",
        bundleVersion: String = "1.0",
        bundleShortVersion: String = "1.0"
    ) -> String {
        let privacyEntries = generateInfoPlistEntries()

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>CFBundleIdentifier</key>
        \t<string>\(escapeXML(bundleIdentifier))</string>
        \t<key>CFBundleName</key>
        \t<string>\(escapeXML(bundleName))</string>
        \t<key>CFBundleVersion</key>
        \t<string>\(escapeXML(bundleVersion))</string>
        \t<key>CFBundleShortVersionString</key>
        \t<string>\(escapeXML(bundleShortVersion))</string>
        \(privacyEntries)
        </dict>
        </plist>
        """
    }

    // MARK: - Entitlements Generation

    /// Generate the entitlements dictionary for all permissions in this manifest.
    public func generateEntitlements() -> [String: Any] {
        var result: [String: Any] = [:]
        for entry in entries {
            guard let entitlements = entry.permission.entitlements else { continue }
            for (key, value) in entitlements {
                // Merge array values
                if let existingArray = result[key] as? [String],
                   let newArray = value as? [String] {
                    let merged = Array(Set(existingArray + newArray))
                    result[key] = merged
                } else {
                    result[key] = value
                }
            }
        }
        return result
    }

    /// Generate entitlements as XML plist string for `.entitlements` file.
    public func generateEntitlementsPlist() -> String {
        let entitlements = generateEntitlements()

        var lines: [String] = []
        for key in entitlements.keys.sorted() {
            let value = entitlements[key]!
            lines.append(plistValue(key: key, value: value))
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \(lines.joined(separator: "\n"))
        </dict>
        </plist>
        """
    }

    // MARK: - Bonjour Services (for Local Network)

    /// Generate the NSBonjourServices array if local network permission is used.
    /// Pass your Bonjour service types (e.g., ["_myapp._tcp", "_myapp._udp"]).
    public func generateBonjourServices(serviceTypes: [String]) -> String? {
        guard entries.contains(where: {
            if case .localNetwork = $0.permission { return true }
            return false
        }) else { return nil }

        var lines = ["\t<key>NSBonjourServices</key>", "\t<array>"]
        for service in serviceTypes {
            lines.append("\t\t<string>\(escapeXML(service))</string>")
        }
        lines.append("\t</array>")
        return lines.joined(separator: "\n")
    }

    // MARK: - Validation

    /// Validate that all required Info.plist keys are present in the given bundle.
    /// Returns an array of missing key names.
    public func validateBundle(_ bundle: Bundle = .main) -> [String] {
        var missing: [String] = []
        var seen = Set<String>()
        for entry in entries {
            for key in entry.permission.infoPlistKeys {
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                if bundle.object(forInfoDictionaryKey: key) == nil {
                    missing.append(key)
                }
            }
        }
        return missing
    }

    /// A human-readable report of all permissions, plist keys, and capabilities.
    public func report() -> String {
        var lines: [String] = ["PermissionKit Manifest Report", String(repeating: "=", count: 40)]

        for entry in entries {
            lines.append("")
            lines.append("Permission: \(entry.permission.title)")
            lines.append("  Usage: \(entry.usageDescription)")

            let keys = entry.permission.infoPlistKeys
            if !keys.isEmpty {
                lines.append("  Info.plist Keys: \(keys.joined(separator: ", "))")
            }
            if let cap = entry.permission.requiredCapability {
                lines.append("  Capability: \(cap)")
            }
            lines.append("  Platforms: \(entry.permission.platforms.map(\.rawValue).joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func plistValue(key: String, value: Any) -> String {
        var lines: [String] = []
        lines.append("\t<key>\(escapeXML(key))</key>")

        if let boolValue = value as? Bool {
            lines.append(boolValue ? "\t<true/>" : "\t<false/>")
        } else if let stringValue = value as? String {
            lines.append("\t<string>\(escapeXML(stringValue))</string>")
        } else if let arrayValue = value as? [String] {
            lines.append("\t<array>")
            for item in arrayValue.sorted() {
                lines.append("\t\t<string>\(escapeXML(item))</string>")
            }
            lines.append("\t</array>")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - JSON Configuration Support

extension PermissionManifest {

    /// Permission entry as decoded from JSON configuration.
    private struct JSONEntry: Decodable {
        let permission: String
        let usage: String
        let variant: String?
    }

    private struct JSONManifest: Decodable {
        let permissions: [JSONEntry]
    }

    /// Initialize a manifest from a JSON configuration file.
    ///
    /// JSON format:
    /// ```json
    /// {
    ///   "permissions": [
    ///     { "permission": "camera", "usage": "Take photos" },
    ///     { "permission": "location", "variant": "whenInUse", "usage": "Show nearby" },
    ///     { "permission": "photos", "variant": "readWrite", "usage": "Save images" },
    ///     { "permission": "health", "variant": "readWrite", "usage": "Track fitness" },
    ///     { "permission": "notifications", "usage": "Send updates" }
    ///   ]
    /// }
    /// ```
    public init(jsonData: Data) throws {
        let decoded = try JSONDecoder().decode(JSONManifest.self, from: jsonData)
        let mapped = decoded.permissions.compactMap { entry -> Entry? in
            guard let permission = Self.parsePermission(entry.permission, variant: entry.variant) else {
                return nil
            }
            return Entry(permission: permission, usageDescription: entry.usage)
        }
        self.entries = mapped
    }

    /// Initialize from a JSON file at the given path.
    public init(jsonFileAt path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        try self.init(jsonData: data)
    }

    private static func parsePermission(_ name: String, variant: String?) -> Permission? {
        switch name.lowercased() {
        case "camera": return .camera
        case "microphone": return .microphone
        case "medialibrary": return .mediaLibrary
        case "contacts": return .contacts
        case "reminders": return .reminders
        case "bluetooth": return .bluetooth
        case "localnetwork": return .localNetwork
        case "nearbyinteraction": return .nearbyInteraction
        case "tracking": return .tracking
        case "siri": return .siri
        case "speechrecognition": return .speechRecognition
        case "motion": return .motion
        case "homekit": return .homeKit
        case "nfc": return .nfc
        case "screenrecording": return .screenRecording
        case "fulldiskaccess": return .fullDiskAccess
        case "accessibility": return .accessibility
        case "inputmonitoring": return .inputMonitoring
        case "automation": return .automation
        case "workoutextension": return .workoutExtension
        case "mindfulnesssession": return .mindfulnessSession
        case "criticalalerts": return .criticalAlerts

        case "location":
            switch variant?.lowercased() {
            case "always": return .location(.always)
            case "precise": return .location(.precise)
            default: return .location(.whenInUse)
            }

        case "photos":
            switch variant?.lowercased() {
            case "addonly": return .photos(.addOnly)
            case "limited": return .photos(.limited)
            default: return .photos(.readWrite)
            }

        case "calendar":
            switch variant?.lowercased() {
            case "read": return .calendar(.read)
            case "write": return .calendar(.write)
            default: return .calendar(.fullAccess)
            }

        case "notifications":
            return .notifications(.default)

        case "biometrics":
            switch variant?.lowercased() {
            case "faceid": return .biometrics(.faceID)
            case "touchid": return .biometrics(.touchID)
            default: return .biometrics(.any)
            }

        case "health":
            switch variant?.lowercased() {
            case "read": return .health(.read)
            case "write": return .health(.write)
            default: return .health(.readWrite)
            }

        default:
            return nil
        }
    }
}
