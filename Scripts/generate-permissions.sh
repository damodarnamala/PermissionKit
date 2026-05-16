#!/bin/bash
# ──────────────────────────────────────────────────────────────────────
# generate-permissions.sh
# PermissionKit — Auto-generate Info.plist & Entitlements for your app
#
# USAGE (standalone):
#   ./generate-permissions.sh permissions.json --app-name MyApp --output-dir MyApp/
#
# USAGE (Xcode Build Phase):
#   Add as "Run Script" in Build Phases with:
#     ${SRCROOT}/Scripts/generate-permissions.sh \
#       ${SRCROOT}/permissions.json \
#       --app-name ${PRODUCT_NAME} \
#       --output-dir ${SRCROOT}/${PRODUCT_NAME}
# ──────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Defaults ──
APP_NAME="App"
OUTPUT_DIR="."
CONFIG_PATH=""

# ── Parse arguments ──
while [[ $# -gt 0 ]]; do
    case "$1" in
        --app-name)
            APP_NAME="$2"; shift 2 ;;
        --output-dir)
            OUTPUT_DIR="$2"; shift 2 ;;
        --help|-h)
            cat <<'EOF'
USAGE: generate-permissions.sh <permissions.json> [--app-name <name>] [--output-dir <dir>]

Reads a permissions.json and generates files for your Xcode project:
  • <AppName>-Info.plist   — privacy usage descriptions
  • <AppName>.entitlements — required capabilities
  • <AppName>.xcconfig     — build settings wiring both files

OPTIONS:
  --app-name <name>     Your app name for generated filenames (default: "App")
  --output-dir <dir>    Directory to write files (default: current dir)
  --help, -h            Show this help

XCODE BUILD PHASE SETUP:
  1. Copy this script and permissions.json into your project
  2. In Xcode → Build Phases → + → New Run Script Phase
  3. Paste:
       ${SRCROOT}/Scripts/generate-permissions.sh \
         ${SRCROOT}/permissions.json \
         --app-name ${PRODUCT_NAME} \
         --output-dir ${SRCROOT}/${PRODUCT_NAME}
  4. Move the phase ABOVE "Compile Sources"
  5. Build — files are generated automatically
EOF
            exit 0 ;;
        *)
            if [[ -z "$CONFIG_PATH" ]]; then
                CONFIG_PATH="$1"; shift
            else
                echo "Error: Unknown argument: $1" >&2; exit 1
            fi ;;
    esac
done

if [[ -z "$CONFIG_PATH" ]]; then
    echo "Error: Missing required argument: path to permissions.json" >&2
    echo "Run with --help for usage info." >&2
    exit 1
fi

if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Error: File not found: $CONFIG_PATH" >&2
    exit 1
fi

# ── Create output dir ──
mkdir -p "$OUTPUT_DIR"

# ── Read JSON with python3 (available on all macOS) ──
python3 - "$CONFIG_PATH" "$APP_NAME" "$OUTPUT_DIR" <<'PYTHON_SCRIPT'
import json
import sys
import os

config_path = sys.argv[1]
app_name = sys.argv[2]
output_dir = sys.argv[3]

with open(config_path) as f:
    config = json.load(f)

permissions = config.get("permissions", [])
if not permissions:
    print("Error: No permissions found in", config_path, file=sys.stderr)
    sys.exit(1)

# ── Permission → Info.plist key mapping ──
PLIST_KEYS = {
    "camera": "NSCameraUsageDescription",
    "microphone": "NSMicrophoneUsageDescription",
    "medialibrary": "NSAppleMusicUsageDescription",
    "contacts": "NSContactsUsageDescription",
    "reminders": "NSRemindersUsageDescription",
    "bluetooth": "NSBluetoothAlwaysUsageDescription",
    "localnetwork": "NSLocalNetworkUsageDescription",
    "nearbyinteraction": "NSNearbyInteractionUsageDescription",
    "tracking": "NSUserTrackingUsageDescription",
    "siri": "NSSiriUsageDescription",
    "speechrecognition": "NSSpeechRecognitionUsageDescription",
    "motion": "NSMotionUsageDescription",
    "homekit": "NSHomeKitUsageDescription",
    "nfc": "NFCReaderUsageDescription",
    "calendar": "NSCalendarsUsageDescription",
}

PLIST_KEYS_VARIANT = {
    ("location", "wheninuse"): "NSLocationWhenInUseUsageDescription",
    ("location", "always"): "NSLocationAlwaysAndWhenInUseUsageDescription",
    ("location", "precise"): "NSLocationWhenInUseUsageDescription",
    ("location", None): "NSLocationWhenInUseUsageDescription",
    ("photos", "readwrite"): "NSPhotoLibraryUsageDescription",
    ("photos", "limited"): "NSPhotoLibraryUsageDescription",
    ("photos", "addonly"): "NSPhotoLibraryAddUsageDescription",
    ("photos", None): "NSPhotoLibraryUsageDescription",
    ("biometrics", "faceid"): "NSFaceIDUsageDescription",
    ("biometrics", "touchid"): "NSFaceIDUsageDescription",
    ("biometrics", "any"): "NSFaceIDUsageDescription",
    ("biometrics", None): "NSFaceIDUsageDescription",
    ("health", "read"): "NSHealthShareUsageDescription",
    ("health", "readwrite"): "NSHealthShareUsageDescription",
    ("health", "write"): "NSHealthUpdateUsageDescription",
    ("health", None): "NSHealthShareUsageDescription",
}

# ── Permission → Entitlements mapping ──
ENTITLEMENTS = {
    "camera": {"com.apple.security.device.camera": True},
    "microphone": {"com.apple.security.device.audio-input": True},
    "medialibrary": {"com.apple.security.assets.music.read-write": True},
    "contacts": {"com.apple.security.personal-information.addressbook": True},
    "bluetooth": {"com.apple.security.device.bluetooth": True},
    "localnetwork": {"com.apple.developer.networking.multicast": True},
    "nearbyinteraction": {"com.apple.developer.nearby-interaction": True},
    "siri": {"com.apple.developer.siri": True},
    "homekit": {"com.apple.developer.homekit": True},
    "nfc": {"com.apple.developer.nfc.readersession.formats": ["NDEF", "TAG"]},
    "notifications": {"com.apple.developer.aps-environment": "development"},
    "criticalalerts": {"com.apple.developer.aps-environment": "development"},
    "calendar": {"com.apple.security.personal-information.calendars": True},
    "reminders": {"com.apple.security.personal-information.calendars": True},
}

ENTITLEMENTS_VARIANT = {
    ("location", None): {"com.apple.security.personal-information.location": True},
    ("photos", None): {"com.apple.security.personal-information.photos-library": True},
    ("health", None): {"com.apple.developer.healthkit": True, "com.apple.developer.healthkit.access": ["health-records"]},
}

def escape_xml(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;").replace("'", "&apos;")

# ── Collect plist entries and entitlements ──
plist_entries = {}  # key → usage
all_entitlements = {}

for entry in permissions:
    perm = entry["permission"].lower()
    variant = entry.get("variant", "").lower() or None
    usage = entry["usage"]

    # Info.plist key
    plist_key = PLIST_KEYS_VARIANT.get((perm, variant)) or PLIST_KEYS_VARIANT.get((perm, None)) or PLIST_KEYS.get(perm)
    if plist_key and plist_key not in plist_entries:
        plist_entries[plist_key] = usage

    # Entitlements
    ent = ENTITLEMENTS.get(perm) or ENTITLEMENTS_VARIANT.get((perm, None))
    if ent:
        for k, v in ent.items():
            if k in all_entitlements and isinstance(v, list) and isinstance(all_entitlements[k], list):
                all_entitlements[k] = list(set(all_entitlements[k] + v))
            else:
                all_entitlements[k] = v

# ── Generate Info.plist ──
if plist_entries:
    plist_path = os.path.join(output_dir, f"{app_name}-Info.plist")
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
        '<plist version="1.0">',
        '<dict>',
        '\t<key>CFBundleIdentifier</key>',
        '\t<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>',
        '\t<key>CFBundleName</key>',
        '\t<string>$(PRODUCT_NAME)</string>',
        '\t<key>CFBundleVersion</key>',
        '\t<string>$(CURRENT_PROJECT_VERSION)</string>',
        '\t<key>CFBundleShortVersionString</key>',
        '\t<string>$(MARKETING_VERSION)</string>',
    ]
    for key, usage in plist_entries.items():
        lines.append(f'\t<key>{escape_xml(key)}</key>')
        lines.append(f'\t<string>{escape_xml(usage)}</string>')
    lines += ['</dict>', '</plist>', '']

    with open(plist_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"✅ Generated Info.plist → {plist_path}")

# ── Generate Entitlements ──
if all_entitlements:
    ent_path = os.path.join(output_dir, f"{app_name}.entitlements")
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
        '<plist version="1.0">',
        '<dict>',
    ]
    for key in sorted(all_entitlements.keys()):
        val = all_entitlements[key]
        lines.append(f'\t<key>{escape_xml(key)}</key>')
        if isinstance(val, bool):
            lines.append('\t<true/>' if val else '\t<false/>')
        elif isinstance(val, str):
            lines.append(f'\t<string>{escape_xml(val)}</string>')
        elif isinstance(val, list):
            lines.append('\t<array>')
            for item in sorted(val):
                lines.append(f'\t\t<string>{escape_xml(item)}</string>')
            lines.append('\t</array>')
    lines += ['</dict>', '</plist>', '']

    with open(ent_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"✅ Generated entitlements → {ent_path}")

# ── Generate xcconfig ──
xcconfig_path = os.path.join(output_dir, f"{app_name}.xcconfig")
xc_lines = [
    f"// Auto-generated by PermissionKit for {app_name}",
    "// Include this in your build configuration",
    "",
]
if all_entitlements:
    xc_lines.append(f"CODE_SIGN_ENTITLEMENTS = {app_name}.entitlements")
if plist_entries:
    xc_lines.append(f"INFOPLIST_FILE = {app_name}-Info.plist")
xc_lines.append("")

with open(xcconfig_path, 'w') as f:
    f.write('\n'.join(xc_lines))
print(f"✅ Generated xcconfig → {xcconfig_path}")

# ── Report ──
print(f"\nDone! Add these files to your {app_name} Xcode project.")
print(f"  📋 {len(plist_entries)} Info.plist privacy keys")
print(f"  🔑 {len(all_entitlements)} entitlement entries")
PYTHON_SCRIPT
