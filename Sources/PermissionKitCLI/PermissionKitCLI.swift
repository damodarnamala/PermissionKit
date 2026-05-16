// MARK: - PermissionKit CLI

import ArgumentParser

/// A command-line tool for managing iOS/macOS app permissions.
///
/// Like SwiftLint for permissions — configure via `.permissionkit.yml`
/// and auto-generate Info.plist, entitlements, and xcconfig files.
///
/// Install:
///   make install
///
/// Usage:
///   permissionkit init --app-name MyApp
///   permissionkit generate
///   permissionkit lint
///   permissionkit report
@main
struct PermissionKitTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "permissionkit",
        abstract: "Manage iOS/macOS app permissions from a YAML config",
        discussion: """
        Configure your app's permissions in a .permissionkit.yml file, \
        then use this tool to generate Info.plist entries, entitlements, \
        and xcconfig files for your Xcode project.

        Getting started:
          permissionkit init --app-name MyApp
          permissionkit generate
        """,
        version: "1.1.0",
        subcommands: [
            GenerateCommand.self,
            InitCommand.self,
            LintCommand.self,
            ReportCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self
    )
}
