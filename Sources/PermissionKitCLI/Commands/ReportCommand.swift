// MARK: - Report Command

import ArgumentParser
import Foundation
import PermissionKit

struct ReportCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "report",
        abstract: "Print a detailed report of your configured permissions"
    )

    @Option(name: .long, help: "Path to the YAML config file (default: .permissionkit.yml)")
    var config: String = ".permissionkit.yml"

    mutating func run() throws {
        let configPath = resolvedPath(config)

        guard FileManager.default.fileExists(atPath: configPath) else {
            throw ValidationError("Config file not found: \(configPath)\nRun 'permissionkit init' to create one.")
        }

        let yamlConfig = try ConfigParser.load(from: configPath)
        let manifest = ConfigParser.manifest(from: yamlConfig)

        guard !manifest.entries.isEmpty else {
            throw ValidationError("No valid permissions found in \(configPath)")
        }

        print(manifest.report())
    }

    private func resolvedPath(_ path: String) -> String {
        if path.hasPrefix("/") { return path }
        return (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(path)
    }
}
