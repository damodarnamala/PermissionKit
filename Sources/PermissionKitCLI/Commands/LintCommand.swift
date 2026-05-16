// MARK: - Lint Command

import ArgumentParser
import Foundation

struct LintCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Validate your .permissionkit.yml configuration"
    )

    @Option(name: .long, help: "Path to the YAML config file (default: .permissionkit.yml)")
    var config: String = ".permissionkit.yml"

    mutating func run() throws {
        let configPath = resolvedPath(config)

        guard FileManager.default.fileExists(atPath: configPath) else {
            throw ValidationError("Config file not found: \(configPath)\nRun 'permissionkit init' to create one.")
        }

        let yamlConfig: PermissionKitConfig
        do {
            yamlConfig = try ConfigParser.load(from: configPath)
        } catch {
            print("❌ Failed to parse \(configPath):")
            print("   \(error.localizedDescription)")
            throw ExitCode.failure
        }

        let issues = ConfigParser.lint(config: yamlConfig)

        if issues.isEmpty {
            print("✅ \(configPath) is valid (\(yamlConfig.permissions.count) permissions)")
        } else {
            for issue in issues {
                print(issue)
            }
            print()
            let errors = issues.filter(\.isError).count
            let warnings = issues.filter { !$0.isError }.count
            print("Found \(errors) error(s), \(warnings) warning(s)")

            if errors > 0 {
                throw ExitCode.failure
            }
        }
    }

    private func resolvedPath(_ path: String) -> String {
        if path.hasPrefix("/") { return path }
        return (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(path)
    }
}
