import Testing
import Foundation
@testable import PermissionKit

// MARK: - Pure Data Model Tests (no global state)

@Suite("PermissionStatus Tests")
struct PermissionStatusTests {

    @Test("isGranted returns true only for .granted")
    func isGranted() {
        #expect(PermissionStatus.granted.isGranted == true)
        #expect(PermissionStatus.denied.isGranted == false)
        #expect(PermissionStatus.notDetermined.isGranted == false)
        #expect(PermissionStatus.restricted.isGranted == false)
        #expect(PermissionStatus.limited.isGranted == false)
        #expect(PermissionStatus.provisional.isGranted == false)
        #expect(PermissionStatus.unknown.isGranted == false)
    }

    @Test("isDenied returns true only for .denied")
    func isDenied() {
        #expect(PermissionStatus.denied.isDenied == true)
        #expect(PermissionStatus.granted.isDenied == false)
    }

    @Test("isNotDetermined returns true only for .notDetermined")
    func isNotDetermined() {
        #expect(PermissionStatus.notDetermined.isNotDetermined == true)
        #expect(PermissionStatus.granted.isNotDetermined == false)
    }

    @Test("canAskAgain is true only for .notDetermined")
    func canAskAgain() {
        #expect(PermissionStatus.notDetermined.canAskAgain == true)
        #expect(PermissionStatus.denied.canAskAgain == false)
        #expect(PermissionStatus.restricted.canAskAgain == false)
        #expect(PermissionStatus.granted.canAskAgain == false)
    }

    @Test("shouldShowSettings is true only for .denied")
    func shouldShowSettings() {
        #expect(PermissionStatus.denied.shouldShowSettings == true)
        #expect(PermissionStatus.granted.shouldShowSettings == false)
        #expect(PermissionStatus.notDetermined.shouldShowSettings == false)
    }
}

@Suite("Permission Tests")
struct PermissionTests {

    @Test("Permission convenience statics resolve correctly")
    func convenienceStatics() {
        #expect(Permission.notifications == Permission.notifications(.default))
        #expect(Permission.locationWhenInUse == Permission.location(.whenInUse))
        #expect(Permission.locationAlways == Permission.location(.always))
        #expect(Permission.photos == Permission.photos(.readWrite))
        #expect(Permission.calendar == Permission.calendar(.fullAccess))
        #expect(Permission.biometrics == Permission.biometrics(.any))
    }

    @Test("Permission groups contain expected permissions")
    func groups() {
        #expect(Permission.mediaCapture.contains(.camera))
        #expect(Permission.mediaCapture.contains(.microphone))
        #expect(Permission.social.contains(.contacts))
    }

    @Test("Permission equality works with associated values")
    func equality() {
        #expect(Permission.location(.whenInUse) == Permission.location(.whenInUse))
        #expect(Permission.location(.whenInUse) != Permission.location(.always))
        #expect(Permission.camera == Permission.camera)
        #expect(Permission.camera != Permission.microphone)
    }
}

@Suite("Permission Metadata Tests")
struct PermissionMetadataTests {

    @Test("All permissions have a title")
    func titles() {
        let permissions: [Permission] = [
            .camera, .microphone, .contacts, .reminders, .bluetooth,
            .tracking, .siri, .speechRecognition, .motion, .homeKit,
            .nfc, .location(.whenInUse), .location(.always),
            .photos(.readWrite), .photos(.addOnly),
            .calendar(.read), .calendar(.fullAccess),
            .notifications, .criticalAlerts, .localNetwork, .nearbyInteraction,
            .biometrics(.faceID), .biometrics(.touchID),
            .health(.read), .health(.write), .mediaLibrary,
            .screenRecording, .fullDiskAccess, .accessibility,
            .inputMonitoring, .automation, .workoutExtension, .mindfulnessSession,
        ]
        for permission in permissions {
            #expect(!permission.title.isEmpty, "Title should not be empty for \(permission)")
        }
    }

    @Test("All permissions have a system image name")
    func systemImageNames() {
        let permissions: [Permission] = [.camera, .microphone, .contacts, .location(.whenInUse)]
        for permission in permissions {
            #expect(!permission.systemImageName.isEmpty)
        }
    }

    // MARK: - infoPlistKey

    @Test("infoPlistKey — location variants")
    func infoPlistKeyLocation() {
        #expect(Permission.location(.whenInUse).infoPlistKey == "NSLocationWhenInUseUsageDescription")
        #expect(Permission.location(.always).infoPlistKey == "NSLocationAlwaysAndWhenInUseUsageDescription")
        // precise falls back to whenInUse as primary key; full accuracy key is in infoPlistKeys
        #expect(Permission.location(.precise).infoPlistKey == "NSLocationWhenInUseUsageDescription")
    }

    @Test("infoPlistKey — media permissions")
    func infoPlistKeyMedia() {
        #expect(Permission.camera.infoPlistKey == "NSCameraUsageDescription")
        #expect(Permission.microphone.infoPlistKey == "NSMicrophoneUsageDescription")
        #expect(Permission.photos(.readWrite).infoPlistKey == "NSPhotoLibraryUsageDescription")
        #expect(Permission.photos(.limited).infoPlistKey == "NSPhotoLibraryUsageDescription")
        #expect(Permission.photos(.addOnly).infoPlistKey == "NSPhotoLibraryAddUsageDescription")
        #expect(Permission.mediaLibrary.infoPlistKey == "NSAppleMusicUsageDescription")
    }

    @Test("infoPlistKey — communication permissions")
    func infoPlistKeyComm() {
        #expect(Permission.contacts.infoPlistKey == "NSContactsUsageDescription")
        #expect(Permission.calendar(.fullAccess).infoPlistKey == "NSCalendarsUsageDescription")
        #expect(Permission.calendar(.read).infoPlistKey == "NSCalendarsUsageDescription")
        #expect(Permission.calendar(.write).infoPlistKey == "NSCalendarsUsageDescription")
        #expect(Permission.reminders.infoPlistKey == "NSRemindersUsageDescription")
    }

    @Test("infoPlistKey — connectivity permissions")
    func infoPlistKeyConnectivity() {
        #expect(Permission.bluetooth.infoPlistKey == "NSBluetoothAlwaysUsageDescription")
        #expect(Permission.localNetwork.infoPlistKey == "NSLocalNetworkUsageDescription")
        #expect(Permission.nearbyInteraction.infoPlistKey == "NSNearbyInteractionUsageDescription")
    }

    @Test("infoPlistKey — identity & tracking permissions")
    func infoPlistKeyIdentity() {
        #expect(Permission.biometrics(.faceID).infoPlistKey == "NSFaceIDUsageDescription")
        #expect(Permission.biometrics(.any).infoPlistKey == "NSFaceIDUsageDescription")
        // touchID: Face ID key included as safety net for any device
        #expect(Permission.biometrics(.touchID).infoPlistKey == "NSFaceIDUsageDescription")
        #expect(Permission.tracking.infoPlistKey == "NSUserTrackingUsageDescription")
    }

    @Test("infoPlistKey — intelligence permissions")
    func infoPlistKeyIntelligence() {
        #expect(Permission.siri.infoPlistKey == "NSSiriUsageDescription")
        #expect(Permission.speechRecognition.infoPlistKey == "NSSpeechRecognitionUsageDescription")
    }

    @Test("infoPlistKey — health & fitness permissions")
    func infoPlistKeyHealth() {
        #expect(Permission.health(.read).infoPlistKey == "NSHealthShareUsageDescription")
        #expect(Permission.health(.readWrite).infoPlistKey == "NSHealthShareUsageDescription")
        #expect(Permission.health(.write).infoPlistKey == "NSHealthUpdateUsageDescription")
        #expect(Permission.motion.infoPlistKey == "NSMotionUsageDescription")
    }

    @Test("infoPlistKey — smart home permissions")
    func infoPlistKeySmartHome() {
        #expect(Permission.homeKit.infoPlistKey == "NSHomeKitUsageDescription")
        #expect(Permission.nfc.infoPlistKey == "NFCReaderUsageDescription")
    }

    @Test("infoPlistKey — macOS-only permissions return nil (TCC managed)")
    func infoPlistKeyMacOS() {
        #expect(Permission.screenRecording.infoPlistKey == nil)
        #expect(Permission.fullDiskAccess.infoPlistKey == nil)
        #expect(Permission.accessibility.infoPlistKey == nil)
        #expect(Permission.inputMonitoring.infoPlistKey == nil)
        #expect(Permission.automation.infoPlistKey == nil)
    }

    @Test("infoPlistKey — watchOS-only permissions return nil")
    func infoPlistKeyWatchOS() {
        #expect(Permission.workoutExtension.infoPlistKey == nil)
        #expect(Permission.mindfulnessSession.infoPlistKey == nil)
    }

    @Test("infoPlistKey — notifications")
    func infoPlistKeyNotifications() {
        // iOS/tvOS/watchOS: no plist key needed for UNUserNotificationCenter
        // macOS: sandboxed apps require NSUserNotificationsUsageDescription
        #if os(macOS)
        #expect(Permission.notifications.infoPlistKey == "NSUserNotificationsUsageDescription")
        #expect(Permission.criticalAlerts.infoPlistKey == "NSUserNotificationsUsageDescription")
        #else
        #expect(Permission.notifications.infoPlistKey == nil)
        #expect(Permission.criticalAlerts.infoPlistKey == nil)
        #endif
    }

    // MARK: - infoPlistKeys (multi-key permissions)

    @Test("infoPlistKeys — precise location returns two keys")
    func infoPlistKeysLocation() {
        let keys = Permission.location(.precise).infoPlistKeys
        #expect(keys.count == 2)
        #expect(keys.contains("NSLocationWhenInUseUsageDescription"))
        #expect(keys.contains("NSLocationTemporaryFullAccuracyUsageDescription"))
    }

    @Test("infoPlistKeys — whenInUse and always return one key each")
    func infoPlistKeysSingleLocation() {
        #expect(Permission.location(.whenInUse).infoPlistKeys.count == 1)
        #expect(Permission.location(.always).infoPlistKeys.count == 1)
    }

    @Test("infoPlistKeys — health readWrite returns two keys")
    func infoPlistKeysHealthReadWrite() {
        let keys = Permission.health(.readWrite).infoPlistKeys
        #expect(keys.count == 2)
        #expect(keys.contains("NSHealthShareUsageDescription"))
        #expect(keys.contains("NSHealthUpdateUsageDescription"))
    }

    @Test("infoPlistKeys — health read returns one key")
    func infoPlistKeysHealthRead() {
        let keys = Permission.health(.read).infoPlistKeys
        #expect(keys.count == 1)
        #expect(keys.contains("NSHealthShareUsageDescription"))
    }

    @Test("infoPlistKeys — health write returns one key")
    func infoPlistKeysHealthWrite() {
        let keys = Permission.health(.write).infoPlistKeys
        #expect(keys.count == 1)
        #expect(keys.contains("NSHealthUpdateUsageDescription"))
    }

    @Test("infoPlistKeys — single-key permissions return one-element array")
    func infoPlistKeysSingleKey() {
        #expect(Permission.camera.infoPlistKeys == ["NSCameraUsageDescription"])
        #expect(Permission.microphone.infoPlistKeys == ["NSMicrophoneUsageDescription"])
        #expect(Permission.contacts.infoPlistKeys == ["NSContactsUsageDescription"])
        #expect(Permission.tracking.infoPlistKeys == ["NSUserTrackingUsageDescription"])
        #expect(Permission.bluetooth.infoPlistKeys == ["NSBluetoothAlwaysUsageDescription"])
        #expect(Permission.localNetwork.infoPlistKeys == ["NSLocalNetworkUsageDescription"])
        #expect(Permission.nearbyInteraction.infoPlistKeys == ["NSNearbyInteractionUsageDescription"])
        #expect(Permission.motion.infoPlistKeys == ["NSMotionUsageDescription"])
        #expect(Permission.homeKit.infoPlistKeys == ["NSHomeKitUsageDescription"])
        #expect(Permission.nfc.infoPlistKeys == ["NFCReaderUsageDescription"])
        #expect(Permission.siri.infoPlistKeys == ["NSSiriUsageDescription"])
        #expect(Permission.speechRecognition.infoPlistKeys == ["NSSpeechRecognitionUsageDescription"])
        #expect(Permission.photos(.readWrite).infoPlistKeys == ["NSPhotoLibraryUsageDescription"])
        #expect(Permission.photos(.addOnly).infoPlistKeys == ["NSPhotoLibraryAddUsageDescription"])
        #expect(Permission.mediaLibrary.infoPlistKeys == ["NSAppleMusicUsageDescription"])
        #expect(Permission.reminders.infoPlistKeys == ["NSRemindersUsageDescription"])
        #expect(Permission.calendar(.fullAccess).infoPlistKeys == ["NSCalendarsUsageDescription"])
        #expect(Permission.biometrics(.faceID).infoPlistKeys == ["NSFaceIDUsageDescription"])
    }

    @Test("infoPlistKeys — no-key permissions return empty array")
    func infoPlistKeysEmpty() {
        #expect(Permission.screenRecording.infoPlistKeys.isEmpty)
        #expect(Permission.fullDiskAccess.infoPlistKeys.isEmpty)
        #expect(Permission.accessibility.infoPlistKeys.isEmpty)
        #expect(Permission.inputMonitoring.infoPlistKeys.isEmpty)
        #expect(Permission.automation.infoPlistKeys.isEmpty)
        #expect(Permission.workoutExtension.infoPlistKeys.isEmpty)
        #expect(Permission.mindfulnessSession.infoPlistKeys.isEmpty)
        #if !os(macOS)
        #expect(Permission.notifications.infoPlistKeys.isEmpty)
        #expect(Permission.criticalAlerts.infoPlistKeys.isEmpty)
        #endif
    }
}

@Suite("PermissionResult Tests")
struct PermissionResultTests {

    @Test("PermissionResult computed properties")
    func computedProperties() {
        let granted = PermissionResult(permission: .camera, status: .granted, timestamp: Date())
        #expect(granted.isGranted == true)
        #expect(granted.shouldOpenSettings == false)

        let denied = PermissionResult(permission: .camera, status: .denied, timestamp: Date())
        #expect(denied.isGranted == false)
        #expect(denied.shouldOpenSettings == true)
    }
}

@Suite("MockPermissionHandler Tests")
struct MockPermissionHandlerTests {

    @Test("Mock handler returns stubbed status")
    func stubbedStatus() async {
        let mock = MockPermissionHandler(permission: .camera, status: .denied)
        #expect(mock.status == .denied)
        let result = await mock.request()
        #expect(result == .denied)
        #expect(mock.requestCallCount == 1)
    }

    @Test("Mock handler tracks request call count")
    func requestCallCount() async {
        let mock = MockPermissionHandler(permission: .microphone, status: .granted)
        _ = await mock.request()
        _ = await mock.request()
        _ = await mock.request()
        #expect(mock.requestCallCount == 3)
    }

    @Test("Mock handler can change status")
    func statusChange() async {
        let mock = MockPermissionHandler(permission: .camera, status: .notDetermined)
        #expect(mock.status == .notDetermined)
        mock.stubbedStatus = .granted
        #expect(mock.status == .granted)
    }

    @Test("Mock handler reset clears call count")
    func reset() async {
        let mock = MockPermissionHandler(permission: .camera, status: .granted)
        _ = await mock.request()
        #expect(mock.requestCallCount == 1)
        mock.reset()
        #expect(mock.requestCallCount == 0)
    }
}

@Suite("NotificationOptions Tests")
struct NotificationOptionsTests {

    @Test("Default options have alert, badge, sound enabled")
    func defaultOptions() {
        let options = NotificationOptions.default
        #expect(options.alert == true)
        #expect(options.badge == true)
        #expect(options.sound == true)
        #expect(options.criticalAlert == false)
        #expect(options.provisional == false)
    }

    @Test("Provisional options set provisional flag")
    func provisionalOptions() {
        let options = NotificationOptions.provisional
        #expect(options.provisional == true)
    }
}

@Suite("UnsupportedHandler Tests")
struct UnsupportedHandlerTests {

    @Test("Unsupported handler returns unknown status")
    func unknownStatus() async {
        let handler = UnsupportedHandler(permission: .screenRecording)
        #expect(handler.status == .unknown)
        let result = await handler.request()
        #expect(result == .unknown)
    }
}

@Suite("InfoPlistHelper Tests")
struct InfoPlistHelperTests {

    @Test("requiredKeys returns correct keys for single-key permissions")
    func requiredKeysSingle() {
        let keys = InfoPlistHelper.requiredKeys(for: [.camera, .microphone])
        #expect(keys["NSCameraUsageDescription"] != nil)
        #expect(keys["NSMicrophoneUsageDescription"] != nil)
        #expect(keys.count == 2)
    }

    @Test("requiredKeys returns both keys for precise location")
    func requiredKeysPreciseLocation() {
        let keys = InfoPlistHelper.requiredKeys(for: [.location(.precise)])
        #expect(keys["NSLocationWhenInUseUsageDescription"] != nil)
        #expect(keys["NSLocationTemporaryFullAccuracyUsageDescription"] != nil)
        #expect(keys.count == 2)
    }

    @Test("requiredKeys returns both keys for health readWrite")
    func requiredKeysHealthReadWrite() {
        let keys = InfoPlistHelper.requiredKeys(for: [.health(.readWrite)])
        #expect(keys["NSHealthShareUsageDescription"] != nil)
        #expect(keys["NSHealthUpdateUsageDescription"] != nil)
        #expect(keys.count == 2)
    }

    @Test("requiredKeys returns empty for no-key permissions")
    func requiredKeysNoKey() {
        let keys = InfoPlistHelper.requiredKeys(for: [.screenRecording, .fullDiskAccess, .workoutExtension])
        #expect(keys.isEmpty)
    }

    @Test("All keys dictionary is populated and includes new keys")
    func allKeys() {
        let keys = InfoPlistHelper.allKeys
        #expect(keys.count > 20)
        #expect(keys["NSCameraUsageDescription"] != nil)
        #expect(keys["NSLocationTemporaryFullAccuracyUsageDescription"] != nil)
        #expect(keys["NSHealthUpdateUsageDescription"] != nil)
        #expect(keys["NSUserNotificationsUsageDescription"] != nil)
    }

    @Test("validateInfoPlist reports missing keys")
    func validateMissingKeys() {
        let missing = InfoPlistHelper.validateInfoPlist(for: [.camera, .microphone])
        #expect(missing.contains("NSCameraUsageDescription"))
        #expect(missing.contains("NSMicrophoneUsageDescription"))
    }

    @Test("validateInfoPlist reports both precise location keys as missing")
    func validatePreciseLocationKeys() {
        let missing = InfoPlistHelper.validateInfoPlist(for: [.location(.precise)])
        #expect(missing.contains("NSLocationWhenInUseUsageDescription"))
        #expect(missing.contains("NSLocationTemporaryFullAccuracyUsageDescription"))
    }

    @Test("validateInfoPlist reports both health readWrite keys as missing")
    func validateHealthReadWriteKeys() {
        let missing = InfoPlistHelper.validateInfoPlist(for: [.health(.readWrite)])
        #expect(missing.contains("NSHealthShareUsageDescription"))
        #expect(missing.contains("NSHealthUpdateUsageDescription"))
    }

    @Test("validateInfoPlist deduplicates overlapping keys")
    func validateDeduplication() {
        // whenInUse and precise share NSLocationWhenInUseUsageDescription
        let missing = InfoPlistHelper.validateInfoPlist(for: [.location(.whenInUse), .location(.precise)])
        let whenInUseCount = missing.filter { $0 == "NSLocationWhenInUseUsageDescription" }.count
        #expect(whenInUseCount == 1)
    }
}

// MARK: - Global State Tests (all serialized in one suite to avoid races)

@Suite("Integration Tests", .serialized)
struct IntegrationTests {

    // MARK: - Registry Tests

    @Test("Override handler returns mock status")
    func overrideHandler() async {
        let mock = MockPermissionHandler(permission: .camera, status: .denied)
        PermissionKit.setHandler(mock, for: .camera)
        defer { PermissionKit.resetHandler(for: .camera) }

        #expect(Permission.camera.status == .denied)
    }

    @Test("Request through Permission enum uses mock")
    func requestThroughEnum() async {
        let mock = MockPermissionHandler(permission: .camera, status: .granted)
        PermissionKit.setHandler(mock, for: .camera)
        defer { PermissionKit.resetHandler(for: .camera) }

        let result = await Permission.camera.request()
        #expect(result == .granted)
        #expect(mock.requestCallCount == 1)
    }

    @Test("Reset removes all overrides")
    func resetHandlers() async {
        let mock = MockPermissionHandler(permission: .homeKit, status: .denied)
        PermissionKit.setHandler(mock, for: .homeKit)
        PermissionKit.resetHandler(for: .homeKit)

        let handler = PermissionKit.handler(for: .homeKit)
        #expect(!(handler is MockPermissionHandler))
    }

    @Test("isGranted convenience on Permission works with mock")
    func isGrantedConvenience() async {
        let mock = MockPermissionHandler(permission: .contacts, status: .granted)
        PermissionKit.setHandler(mock, for: .contacts)
        defer { PermissionKit.resetHandler(for: .contacts) }

        #expect(Permission.contacts.isGranted == true)

        mock.stubbedStatus = .denied
        #expect(Permission.contacts.isDenied == true)
    }

    // MARK: - TestHelper Tests

    @Test("Mock single permission via TestHelper")
    func mockSingle() async {
        let mock = PermissionTestHelper.mock(.bluetooth, with: .granted)
        defer { PermissionKit.resetHandler(for: .bluetooth) }

        #expect(Permission.bluetooth.isGranted == true)
        #expect(mock.requestCallCount == 0)
    }

    @Test("Mock multiple permissions via TestHelper")
    func mockMultiple() {
        PermissionTestHelper.mock([.nfc, .siri, .motion], with: .denied)
        defer {
            PermissionKit.resetHandler(for: .nfc)
            PermissionKit.resetHandler(for: .siri)
            PermissionKit.resetHandler(for: .motion)
        }

        #expect(Permission.nfc.isDenied == true)
        #expect(Permission.siri.isDenied == true)
        #expect(Permission.motion.isDenied == true)
    }

    @Test("Retrieve mock handler via TestHelper")
    func retrieveMock() {
        PermissionTestHelper.mock(.tracking, with: .granted)
        defer { PermissionKit.resetHandler(for: .tracking) }

        let mock = PermissionTestHelper.mockHandler(for: .tracking)
        #expect(mock != nil)
        #expect(mock?.status == .granted)
    }

    // MARK: - Sequence Tests

    @Test("Sequence requests permissions in order")
    func sequenceOrder() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .camera, status: .granted), for: .camera)
        PermissionKit.setHandler(MockPermissionHandler(permission: .microphone, status: .granted), for: .microphone)
        PermissionKit.setHandler(MockPermissionHandler(permission: .notifications(.default), status: .denied), for: .notifications)
        defer {
            PermissionKit.resetHandler(for: .camera)
            PermissionKit.resetHandler(for: .microphone)
            PermissionKit.resetHandler(for: .notifications)
        }

        let results = await Permission.sequence([.camera, .microphone, .notifications]).request()

        #expect(results.count == 3)
        #expect(results[0].permission == .camera)
        #expect(results[0].status == .granted)
        #expect(results[1].permission == .microphone)
        #expect(results[1].status == .granted)
        #expect(results[2].permission == .notifications)
        #expect(results[2].status == .denied)
    }

    @Test("Sequence stops on denied when configured")
    func sequenceStopsOnDenied() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .camera, status: .denied), for: .camera)
        PermissionKit.setHandler(MockPermissionHandler(permission: .microphone, status: .granted), for: .microphone)
        defer {
            PermissionKit.resetHandler(for: .camera)
            PermissionKit.resetHandler(for: .microphone)
        }

        let results = await Permission.sequence([.camera, .microphone])
            .stoppingOnDenied()
            .request()

        #expect(results.count == 1)
        #expect(results[0].status == .denied)
    }

    // MARK: - Concurrent Tests

    @Test("Concurrent requests all permissions")
    func concurrentAll() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .nfc, status: .granted), for: .nfc)
        PermissionKit.setHandler(MockPermissionHandler(permission: .siri, status: .denied), for: .siri)
        PermissionKit.setHandler(MockPermissionHandler(permission: .motion, status: .granted), for: .motion)
        defer {
            PermissionKit.resetHandler(for: .nfc)
            PermissionKit.resetHandler(for: .siri)
            PermissionKit.resetHandler(for: .motion)
        }

        let results = await Permission.concurrent([.nfc, .siri, .motion]).request()

        #expect(results.count == 3)
        #expect(results[.nfc]?.status == .granted)
        #expect(results[.siri]?.status == .denied)
        #expect(results[.motion]?.status == .granted)
    }

    // MARK: - Chain Tests

    @Test("Chain executes then block on match")
    func thenOnMatch() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .location(.whenInUse), status: .granted), for: .location(.whenInUse))
        defer { PermissionKit.resetHandler(for: .location(.whenInUse)) }

        let chain = await Permission.request(.location(.whenInUse))
        #expect(chain.lastStatus == .granted)
    }

    @Test("Chain calls onDenied when denied")
    func onDeniedCallback() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .camera, status: .denied), for: .camera)
        defer { PermissionKit.resetHandler(for: .camera) }

        var deniedCalled = false
        let chain = await Permission.request(.camera)
        _ = await chain.onDenied {
            deniedCalled = true
        }

        #expect(deniedCalled == true)
    }

    @Test("Chain calls onGranted when granted")
    func onGrantedCallback() async {
        PermissionKit.setHandler(MockPermissionHandler(permission: .camera, status: .granted), for: .camera)
        defer { PermissionKit.resetHandler(for: .camera) }

        var grantedCalled = false
        let chain = await Permission.request(.camera)
        _ = await chain.onGranted {
            grantedCalled = true
        }

        #expect(grantedCalled == true)
    }
}

// MARK: - Entitlements & Capabilities Tests

@Suite("Entitlements Metadata Tests")
struct EntitlementsMetadataTests {

    @Test("Camera has correct capability")
    func cameraCapability() {
        #expect(Permission.camera.requiredCapability == "com.apple.security.device.camera")
    }

    @Test("HealthKit permissions have entitlements")
    func healthEntitlements() {
        let entitlements = Permission.health(.readWrite).entitlements
        #expect(entitlements != nil)
        #expect(entitlements?["com.apple.developer.healthkit"] as? Bool == true)
    }

    @Test("Notifications have aps-environment entitlement")
    func notificationsEntitlements() {
        let entitlements = Permission.notifications(.default).entitlements
        #expect(entitlements?["com.apple.developer.aps-environment"] as? String == "development")
    }

    @Test("NFC has reader session format entitlement")
    func nfcEntitlements() {
        let entitlements = Permission.nfc.entitlements
        #expect(entitlements != nil)
        let formats = entitlements?["com.apple.developer.nfc.readersession.formats"] as? [String]
        #expect(formats?.contains("NDEF") == true)
    }

    @Test("Biometrics has no capability requirement")
    func biometricsNoCapability() {
        #expect(Permission.biometrics(.faceID).requiredCapability == nil)
    }

    @Test("Siri has correct entitlement")
    func siriEntitlement() {
        let entitlements = Permission.siri.entitlements
        #expect(entitlements?["com.apple.developer.siri"] as? Bool == true)
    }
}

// MARK: - PermissionManifest Tests

@Suite("PermissionManifest Tests")
struct PermissionManifestTests {

    @Test("Manifest generates Info.plist entries")
    func generatesPlistEntries() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Take photos"),
            PermissionManifest.entry(.microphone, usage: "Record audio"),
        ])

        let plist = manifest.generateInfoPlistEntries()
        #expect(plist.contains("NSCameraUsageDescription"))
        #expect(plist.contains("Take photos"))
        #expect(plist.contains("NSMicrophoneUsageDescription"))
        #expect(plist.contains("Record audio"))
    }

    @Test("Manifest deduplicates Info.plist keys")
    func deduplicatesPlistKeys() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Take photos"),
            PermissionManifest.entry(.camera, usage: "Also take photos"),
        ])

        let plist = manifest.generateInfoPlistEntries()
        let count = plist.components(separatedBy: "NSCameraUsageDescription").count - 1
        #expect(count == 1)
    }

    @Test("Manifest generates entitlements")
    func generatesEntitlements() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.notifications(.default), usage: "Send updates"),
            PermissionManifest.entry(.health(.readWrite), usage: "Track workouts"),
        ])

        let entitlements = manifest.generateEntitlements()
        #expect(entitlements["com.apple.developer.aps-environment"] as? String == "development")
        #expect(entitlements["com.apple.developer.healthkit"] as? Bool == true)
    }

    @Test("Manifest generates entitlements plist XML")
    func generatesEntitlementsPlistXML() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.siri, usage: "Use Siri"),
        ])

        let xml = manifest.generateEntitlementsPlist()
        #expect(xml.contains("com.apple.developer.siri"))
        #expect(xml.contains("<true/>"))
        #expect(xml.contains("<?xml version"))
    }

    @Test("Manifest generates full Info.plist XML")
    func generatesFullInfoPlist() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Take photos"),
        ])

        let xml = manifest.generateInfoPlist(bundleIdentifier: "com.test.app")
        #expect(xml.contains("com.test.app"))
        #expect(xml.contains("NSCameraUsageDescription"))
        #expect(xml.contains("Take photos"))
    }

    @Test("Manifest report includes all entries")
    func reportIncludesEntries() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Take photos"),
            PermissionManifest.entry(.location(.whenInUse), usage: "Show nearby"),
        ])

        let report = manifest.report()
        #expect(report.contains("Camera"))
        #expect(report.contains("Take photos"))
        #expect(report.contains("Location"))
        #expect(report.contains("Show nearby"))
    }

    @Test("Manifest parses from JSON")
    func parsesJSON() throws {
        let json = """
        {
          "permissions": [
            { "permission": "camera", "usage": "Take photos" },
            { "permission": "location", "variant": "always", "usage": "Background tracking" },
            { "permission": "health", "variant": "read", "usage": "Read health data" }
          ]
        }
        """.data(using: .utf8)!

        let manifest = try PermissionManifest(jsonData: json)
        #expect(manifest.entries.count == 3)
        #expect(manifest.entries[0].permission == .camera)
        #expect(manifest.entries[1].permission == .location(.always))
        #expect(manifest.entries[2].permission == .health(.read))
    }

    @Test("Manifest Bonjour services only generated when localNetwork is present")
    func bonjourServicesRequiresLocalNetwork() {
        let withoutLN = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Take photos"),
        ])
        #expect(withoutLN.generateBonjourServices(serviceTypes: ["_test._tcp"]) == nil)

        let withLN = PermissionManifest(permissions: [
            PermissionManifest.entry(.localNetwork, usage: "Find devices"),
        ])
        let xml = withLN.generateBonjourServices(serviceTypes: ["_test._tcp"])
        #expect(xml?.contains("NSBonjourServices") == true)
        #expect(xml?.contains("_test._tcp") == true)
    }

    @Test("Manifest escapes XML special characters")
    func escapesXML() {
        let manifest = PermissionManifest(permissions: [
            PermissionManifest.entry(.camera, usage: "Photos & videos <with> \"special\" chars"),
        ])

        let plist = manifest.generateInfoPlistEntries()
        #expect(plist.contains("&amp;"))
        #expect(plist.contains("&lt;with&gt;"))
        #expect(plist.contains("&quot;special&quot;"))
    }
}
