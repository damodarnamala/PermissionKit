// MARK: - YAML Configuration Parser

import Foundation
import Yams
import PermissionKit

/// Represents the `.permissionkit.yml` configuration file.
struct PermissionKitConfig: Decodable {
    let appName: String?
    let outputDir: String?
    let bundleIdentifier: String?
    let permissions: [PermissionEntry]
    let bonjourServices: [String]?

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case outputDir = "output_dir"
        case bundleIdentifier = "bundle_identifier"
        case permissions
        case bonjourServices = "bonjour_services"
    }
}

/// A single permission entry in the YAML config.
struct PermissionEntry: Decodable {
    let permission: String
    let variant: String?
    let usage: String
}

// MARK: - Parsing

enum ConfigParser {
    /// Load config from a YAML file at the given path.
    static func load(from path: String) throws -> PermissionKitConfig {
        let url = URL(fileURLWithPath: path)
        let yamlString = try String(contentsOf: url, encoding: .utf8)
        return try parse(yaml: yamlString)
    }

    /// Parse a YAML string into config.
    static func parse(yaml: String) throws -> PermissionKitConfig {
        let decoder = YAMLDecoder()
        return try decoder.decode(PermissionKitConfig.self, from: yaml)
    }

    /// Convert config to a PermissionManifest.
    static func manifest(from config: PermissionKitConfig) -> PermissionManifest {
        let entries = config.permissions.compactMap { entry -> PermissionManifest.Entry? in
            guard let permission = parsePermission(entry.permission, variant: entry.variant) else {
                return nil
            }
            return PermissionManifest.Entry(permission: permission, usageDescription: entry.usage)
        }
        return PermissionManifest(permissions: entries)
    }

    /// Validate config and return any issues found.
    static func lint(config: PermissionKitConfig) -> [LintIssue] {
        var issues: [LintIssue] = []

        if config.permissions.isEmpty {
            issues.append(.error("No permissions defined"))
        }

        var seen = Set<String>()
        for (index, entry) in config.permissions.enumerated() {
            let key = "\(entry.permission):\(entry.variant ?? "")"
            if seen.contains(key) {
                issues.append(.warning("Duplicate permission '\(entry.permission)' at index \(index)"))
            }
            seen.insert(key)

            if parsePermission(entry.permission, variant: entry.variant) == nil {
                issues.append(.error("Unknown permission '\(entry.permission)' at index \(index)"))
            }

            if entry.usage.trimmingCharacters(in: .whitespaces).isEmpty {
                issues.append(.error("Empty usage description for '\(entry.permission)' at index \(index)"))
            }

            if let variant = entry.variant {
                let validVariants = validVariants(for: entry.permission)
                if !validVariants.isEmpty && !validVariants.contains(variant.lowercased()) {
                    issues.append(.warning("Unknown variant '\(variant)' for '\(entry.permission)'. Valid: \(validVariants.joined(separator: ", "))"))
                }
            }
        }

        return issues
    }

    private static func validVariants(for permission: String) -> [String] {
        switch permission.lowercased() {
        case "location": return ["wheninuse", "always", "precise"]
        case "photos": return ["readwrite", "addonly", "limited"]
        case "calendar": return ["fullaccess", "read", "write"]
        case "health": return ["readwrite", "read", "write"]
        case "biometrics": return ["any", "faceid", "touchid"]
        default: return []
        }
    }
}

// MARK: - Lint Issues

enum LintIssue: CustomStringConvertible {
    case warning(String)
    case error(String)

    var description: String {
        switch self {
        case .warning(let msg): return "⚠️  warning: \(msg)"
        case .error(let msg): return "❌ error: \(msg)"
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

// MARK: - Permission Parsing (reuse same logic as PermissionManifest)

private func parsePermission(_ name: String, variant: String?) -> Permission? {
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
