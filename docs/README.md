# Bad Sign: documentation

Bad Sign is a small iOS app (Objective-C, UIKit + WebKit) by Void Software. The
user picks a birthday and sees their sign in 11 astrology/numerology systems,
plus a twelfth, made-up "Bad Sign" derived from the other eleven. App Store id
`912176242`.

| Document | What it covers |
|---|---|
| [overview.md](overview.md) | What the app does, screen by screen |
| [architecture.md](architecture.md) | Classes, data flow, threading, the table/web-view mechanics |
| [sign-systems.md](sign-systems.md) | Every sign system: how it is calculated, its index table, its quirks |
| [assets-and-content.md](assets-and-content.md) | `SignAssets/` HTML+PNG content, inline images, asset catalogs, font |
| [build-and-release.md](build-and-release.md) | Build settings, versions, building from the command line, TestFlight |
| [known-issues.md](known-issues.md) | Bugs and technical debt found while writing these docs |
| [history.md](history.md) | The 2026 modernisation work and the bugs it fixed |

## At a glance

| | |
|---|---|
| Language | Objective-C (ARC) |
| UI | UIKit, programmatic layout with fixed frames; `WKWebView` for sign details |
| Minimum iOS | 15.0 (app target) |
| Devices | iPhone only, portrait only |
| Bundle id | `voidsoftware.com.Bad-Sign.nl` |
| Version | 2.0 (build 18) |
| Dependencies | None (no CocoaPods/SPM; Flurry and LZMA SDK were removed in April 2026) |
| Persistence | `NSUserDefaults` only |
| Network | None, apart from opening the App Store / Facebook URLs |
| Tests | 14 XCTest logic tests covering every sign system (`Bad SignTests`) |

## Source map

```
Bad Sign/                       repository root
├── Bad Sign.xcodeproj          one app target, one test target, scheme "Bad Sign"
├── Bad Sign/                   app sources and resources
│   ├── main.m
│   ├── AppDelegate.h/.m        window, nav bar, date picker, stats panel, share, rating prompt
│   ├── ViewController.h/.m     the sign table, expandable rows, WKWebView details
│   ├── Signs.h/.m              all date → sign calculations, moon phase
│   ├── ViewController.xib      root view holding the UITableView
│   ├── Launch Screen.storyboard
│   ├── SignAssets/             183 sign pages (`<system>-<sign>.html`) + 183 icons (`@2x.png`)
│   ├── [0-9]*-*.png            images embedded inside the HTML pages
│   ├── Images.xcassets         app icon, launch image, share/void icons
│   ├── Moon.xcassets           moon0…moon7 phase images
│   ├── Helvetica.ttf           "Helvetica Neue LT Com", used by labels and HTML
│   ├── Bad Sign-Info.plist, Bad Sign.entitlements, Bad Sign-Prefix.pch
│   └── Flurry/                 empty leftover folder
├── Bad SignTests/              placeholder XCTest target
└── docs/                       this folder
```
