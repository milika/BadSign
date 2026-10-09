# Build and release

## Requirements

- Xcode (built successfully with the Xcode installed on 2026-10-09)
- No package managers, no external dependencies
- To run on a device or upload: membership of Apple team `5A4JA438MW`

## Project layout

| | |
|---|---|
| Project | `Bad Sign.xcodeproj` |
| Scheme | `Bad Sign`, shared (`Bad Sign.xcodeproj/xcshareddata/xcschemes/`), builds the app and runs `Bad SignTests` |
| Targets | `Bad Sign` (app), `Bad SignTests` (XCTest bundle) |
| Configurations | Debug, Release |

## Key build settings (app target)

| Setting | Value |
|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `voidsoftware.com.Bad-Sign.nl` |
| `MARKETING_VERSION` | 2.0 |
| `CURRENT_PROJECT_VERSION` | 18 (bumped by hand for each upload) |
| `IPHONEOS_DEPLOYMENT_TARGET` | 15.0 (project default and both targets) |
| `TARGETED_DEVICE_FAMILY` | 1 (iPhone) |
| `DEVELOPMENT_TEAM` | `5A4JA438MW` |
| `CODE_SIGN_ENTITLEMENTS` | `Bad Sign/Bad Sign.entitlements` (iCloud key-value store, unused) |
| `CLANG_ENABLE_OBJC_ARC` | YES |
| `VALID_ARCHS` | `armv7 armv7s arm64` (legacy, see known issues) |

`Bad Sign-Info.plist` highlights: portrait only, status bar hidden, launch
storyboard `Launch Screen.storyboard`, font `Helvetica.ttf`,
`ITSAppUsesNonExemptEncryption = NO`, and photo-library usage strings (the
share sheet's "Save Image" needs them).

## Building

In Xcode: open `Bad Sign.xcodeproj`, pick the `Bad Sign` scheme and a
simulator or device, Run.

From the command line (build output goes to `~/DevTemp/bad sign/`, per the
owner's global rules; `~/DevTemp/bin/devtemp dir derived-data` prints and
creates the folder):

```bash
xcodebuild -project "Bad Sign.xcodeproj" -scheme "Bad Sign" -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath "$HOME/DevTemp/bad sign/derived-data" CODE_SIGNING_ALLOWED=NO build
```

This succeeded on 2026-10-09 with no compiler warnings (only the libpng
notices described in [assets-and-content.md](assets-and-content.md#build-note)).

## Tests

`Bad SignTests` is a logic-test bundle: it compiles `Signs.m` in directly
and has no host app, so it runs without launching the app. It pins
the expected sign for each system on reference dates (14 tests).

```bash
xcodebuild -project "Bad Sign.xcodeproj" -scheme "Bad Sign" -destination 'platform=iOS Simulator,name=Bad Sign Verify' -derivedDataPath "$HOME/DevTemp/bad sign/derived-data" test
```

`Bad Sign Verify` is a simulator made for this project; create it once with
`xcrun simctl create "Bad Sign Verify" com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-27-0`
(or use any simulator from `xcrun simctl list devices available`).

On 2026-10-09 `xcodebuild` printed the results within seconds but did not
exit afterwards; watch for `Test Suite 'All tests' passed` and stop it.

## Releasing to TestFlight / App Store

1. Bump `CURRENT_PROJECT_VERSION` (and `MARKETING_VERSION` for a new public
   version) in the app target. Past commits do this as "Update project version
   to N".
2. Archive and upload, either from Xcode (Product → Archive → Distribute) or
   with the `testflight-upload` skill on this Mac.
3. The App Store id `912176242` (in `AppDelegate.h`) builds the share link and
   the rating link; it does not change between versions.

## Repository

- Remote: `https://github.com/milika/BadSign.git`, branch `main`.
- `.gitignore` excludes Xcode user state (`xcuserdata/`), `.DS_Store`, macOS
  `._*` resource-fork files and build output.
