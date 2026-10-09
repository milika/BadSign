#!/bin/bash
# testflight_upload.sh - archive Bad Sign and upload it to App Store Connect for
# TestFlight. Only on the owner's request for that upload.
#
#   scripts/testflight_upload.sh <build>   # higher than any build uploaded for this version
#
# Sets CURRENT_PROJECT_VERSION for every target, archives Release for generic iOS, then exports with
# method app-store-connect / destination upload and automatic signing, through
# the Apple account signed in to Xcode (Settings > Accounts). Same flow as
# FlashQuiz's scripts/testflight_upload.sh. Output under ~/DevTemp/bad sign.
# Commit the project file after.
set -uo pipefail
BUILD="${1:?usage: scripts/testflight_upload.sh <build number>}"
[[ "$BUILD" =~ ^[0-9]+$ ]] || { echo "build must be a number: $BUILD" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
D="$HOME/DevTemp/bad sign"
OUT="$D/scratch/testflight"
PBX="$ROOT/Bad Sign.xcodeproj/project.pbxproj"
XB=/usr/bin/xcodebuild   # not the TestMonitor wrapper in /opt/homebrew/bin
mkdir -p "$OUT" "$D/logs"

sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $BUILD;/" "$PBX"
VERSION=$(grep -oE 'MARKETING_VERSION = [0-9.]+' "$PBX" | awk '{print $3}' | sort -V | tail -1)

ARCHIVE="$OUT/BadSign-$VERSION-$BUILD.xcarchive"
rm -rf "$ARCHIVE" "$OUT/export-$BUILD"
echo "archiving $VERSION ($BUILD)..."
$XB -project "$ROOT/Bad Sign.xcodeproj" -scheme "Bad Sign" -configuration Release \
    -destination 'generic/platform=iOS' -derivedDataPath "$D/derived-data/archive" \
    -archivePath "$ARCHIVE" -allowProvisioningUpdates archive >"$D/logs/archive-$BUILD.log" 2>&1 \
    || { grep -E 'error:' "$D/logs/archive-$BUILD.log" | head -8; echo "archive failed: $D/logs/archive-$BUILD.log" >&2; exit 1; }
got=$(/usr/libexec/PlistBuddy -c 'Print ApplicationProperties:CFBundleVersion' "$ARCHIVE/Info.plist")
[ "$got" = "$BUILD" ] || { echo "the archive is build $got, not $BUILD" >&2; exit 1; }
gotv=$(/usr/libexec/PlistBuddy -c 'Print ApplicationProperties:CFBundleShortVersionString' "$ARCHIVE/Info.plist")
echo "archived $gotv ($got)"

cat >"$OUT/export_options.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store-connect</string>
    <key>destination</key><string>upload</string>
    <key>teamID</key><string>5A4JA438MW</string>
    <key>signingStyle</key><string>automatic</string>
    <key>uploadSymbols</key><true/>
    <key>manageAppVersionAndBuildNumber</key><false/>
</dict>
</plist>
PLIST

echo "uploading $gotv ($BUILD) to App Store Connect..."
$XB -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OUT/export_options.plist" \
    -exportPath "$OUT/export-$BUILD" -allowProvisioningUpdates >"$D/logs/upload-$BUILD.log" 2>&1
rc=$?
grep -E 'Upload succeeded|error|Error' "$D/logs/upload-$BUILD.log" | head -8
[ $rc -eq 0 ] && grep -q 'Upload succeeded' "$D/logs/upload-$BUILD.log" || { echo "upload failed: $D/logs/upload-$BUILD.log" >&2; exit 1; }
echo "$gotv ($BUILD) uploaded; commit $PBX"
