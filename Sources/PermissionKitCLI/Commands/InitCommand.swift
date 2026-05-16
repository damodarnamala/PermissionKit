// MARK: - Init Command

import ArgumentParser
import Foundation

struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a template .permissionkit.yml configuration file"
    )

    @Option(name: .long, help: "Your app's name")
    var appName: String = "MyApp"

    @Flag(name: .long, help: "Include all available permissions as examples")
    var full: Bool = false

    mutating func run() throws {
        let filename = ".permissionkit.yml"
        let path = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: path) {
            throw ValidationError("\(filename) already exists. Remove it first or edit it directly.")
        }

        let content = full ? fullTemplate(appName: appName) : minimalTemplate(appName: appName)
        try content.write(toFile: path, atomically: true, encoding: .utf8)

        print("✅ Created \(filename)")
        print()
        print("Edit the file to configure your app's permissions, then run:")
        print("  permissionkit generate")
    }

    private func minimalTemplate(appName: String) -> String {
        """
        # PermissionKit Configuration
        # Docs: https://github.com/nickthedude/PermissionKit

        app_name: \(appName)
        output_dir: .

        permissions:
          - permission: camera
            usage: "We need camera access to take photos"

          - permission: microphone
            usage: "We need microphone access to record audio"

          - permission: location
            variant: whenInUse
            usage: "We need your location to show nearby places"

          - permission: photos
            variant: readWrite
            usage: "We need photo library access to save and load images"

          - permission: notifications
            usage: "We'd like to send you important updates"
        """
    }

    private func fullTemplate(appName: String) -> String {
        """
        # PermissionKit Configuration
        # Docs: https://github.com/nickthedude/PermissionKit
        #
        # Remove any permissions your app doesn't need

        app_name: \(appName)
        output_dir: .
        # bundle_identifier: com.example.\(appName)

        permissions:
          # Camera & Media
          - permission: camera
            usage: "We need camera access to take photos"

          - permission: microphone
            usage: "We need microphone access to record audio"

          - permission: mediaLibrary
            usage: "We need access to your media library"

          - permission: photos
            variant: readWrite    # readWrite | addOnly | limited
            usage: "We need photo library access to save and load images"

          # Location
          - permission: location
            variant: whenInUse    # whenInUse | always | precise
            usage: "We need your location to show nearby places"

          # Contacts & Calendar
          - permission: contacts
            usage: "We need access to your contacts"

          - permission: calendar
            variant: fullAccess   # fullAccess | read | write
            usage: "We need calendar access to schedule events"

          - permission: reminders
            usage: "We need access to your reminders"

          # Notifications
          - permission: notifications
            usage: "We'd like to send you important updates"

          # - permission: criticalAlerts
          #   usage: "We need to send critical safety alerts"

          # Health & Motion
          - permission: health
            variant: readWrite    # readWrite | read | write
            usage: "We need access to your health data"

          - permission: motion
            usage: "We need motion data to track your activity"

          # Biometrics
          - permission: biometrics
            variant: faceID       # any | faceID | touchID
            usage: "Use Face ID to securely log in"

          # Connectivity
          - permission: bluetooth
            usage: "We need Bluetooth to connect to nearby devices"

          - permission: localNetwork
            usage: "We need local network access to discover devices"

          - permission: nearbyInteraction
            usage: "We need nearby interaction for spatial awareness"

          # Other
          - permission: tracking
            usage: "We use tracking to deliver personalized content"

          - permission: siri
            usage: "Enable Siri to use voice shortcuts"

          - permission: speechRecognition
            usage: "We need speech recognition for voice commands"

          - permission: homeKit
            usage: "We need HomeKit access to control your smart home"

          - permission: nfc
            usage: "We need NFC to read tags"

          # macOS only
          # - permission: screenRecording
          #   usage: "We need screen recording to capture your screen"
          # - permission: fullDiskAccess
          #   usage: "We need full disk access to manage files"
          # - permission: accessibility
          #   usage: "We need accessibility access for automation"
          # - permission: inputMonitoring
          #   usage: "We need input monitoring for keyboard shortcuts"
          # - permission: automation
          #   usage: "We need automation access to control other apps"

        # Bonjour services (only needed if using localNetwork permission)
        # bonjour_services:
        #   - "_myapp._tcp"
        #   - "_myapp._udp"
        """
    }
}
