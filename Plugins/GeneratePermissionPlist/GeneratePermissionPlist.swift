// MARK: - GeneratePermissionPlist Command Plugin

import PackagePlugin
import Foundation

/// SPM Command Plugin that generates Info.plist and entitlements from a
/// `permissions.json` configuration file in the project root.
///
/// Run via:
///   swift package plugin generate-permission-plist
///   swift package plugin generate-permission-plist --output-dir Sources/MyApp
@main
struct GeneratePermissionPlistPlugin: CommandPlugin {

    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) async throws {

        // Locate the generator tool
        let generatorTool = try context.tool(named: "permission-plist-generator")

        // Find permissions.json in the package directory
        let configPath = context.package.directory.appending("permissions.json").string

        // Determine output directory
        var outputDir = context.package.directory.string
        if let idx = arguments.firstIndex(of: "--output-dir"),
           idx + 1 < arguments.count {
            outputDir = arguments[idx + 1]
        }

        // Create output directory if needed
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )

        // Run the generator
        let process = Process()
        process.executableURL = URL(fileURLWithPath: generatorTool.path.string)
        process.arguments = [configPath, "--output-dir", outputDir]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        // Print output
        if let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
            print(output)
        }

        if process.terminationStatus != 0 {
            if let errorOutput = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
                Diagnostics.error(errorOutput)
            }
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GeneratePermissionPlistPlugin: XcodeCommandPlugin {
    func performCommand(
        context: XcodePluginContext,
        arguments: [String]
    ) throws {
        // For Xcode projects, look for permissions.json in the project directory
        let configPath = context.xcodeProject.directory.appending("permissions.json").string

        var outputDir = context.xcodeProject.directory.string
        if let idx = arguments.firstIndex(of: "--output-dir"),
           idx + 1 < arguments.count {
            outputDir = arguments[idx + 1]
        }

        let generatorTool = try context.tool(named: "permission-plist-generator")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: generatorTool.path.string)
        process.arguments = [configPath, "--output-dir", outputDir]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        if let output = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
            print(output)
        }

        if process.terminationStatus != 0 {
            if let errorOutput = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
                Diagnostics.error(errorOutput)
            }
        }
    }
}
#endif
