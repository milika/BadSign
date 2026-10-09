# Known issues and technical debt

First listed 2026-10-09. Most important first. The sign-calculation bugs
found then (numerology, Aztec table, Slavic gaps, float Julian Days, pre-1928
Chinese time zone) were fixed the same day; see
[history.md](history.md#october-2026-calculation-fixes).

## Blocking

1. **The app does not launch when built with the iOS 27 SDK.** On the iOS 27
   simulator it exits at once with "UIScene life cycle is required for apps
   built with this SDK". `AppDelegate` creates its own `UIWindow` in
   `application:didFinishLaunchingWithOptions:` and there is no
   `UIApplicationSceneManifest` in `Bad Sign-Info.plist`. Any new build made
   with the current Xcode would crash for every user, so this has to be fixed
   before the next TestFlight upload: add a scene delegate that sets up the
   window, and a scene manifest in Info.plist. (The unit tests avoid this by
   running without the app as host.)

## Sign calculations

2. **Time zone dependence.** All systems take day/month/year from the device's
   current calendar and time zone, while the date is stored as an absolute
   `NSDate`. A user who changes time zone could see their birthday shift by
   a day.
3. `moonSign` is unused and marked "Wrong?" in its own source.

## App behaviour

4. **Race on fast date changes.** `calculateSigns:` can run again while the
   previous background job or web-view pre-load is still going. The old
   off-screen web views are removed from their container, but they keep this
   controller as navigation delegate, so a late `didFinishNavigation` can
   still decrement `preloadPendingCount` and store a height for the new set
   of pages. The 0.5 s debounce makes this rare, not impossible.
5. **Each page load carries the whole font.** `injectFontIntoWebView:`
   base64-encodes `Helvetica.ttf` into a `<style>` for every page, 12 at a
   time during pre-load. Referencing it with a relative `@font-face` URL
   (the pages already load with the bundle as base URL) would be lighter.
6. **Fixed 320 pt layout.** Frames are computed from a 320 pt-wide design
    and the picker/panel position from the navigation bar frame at launch.
    Rotation is disabled, Dynamic Type and dark mode are ignored (the picker
    forces light mode).
7. **Custom rating prompt.** The "Rate Bad Sign" alert (with a "Noooo"
    button) after five uses is a home-made prompt;
    `SKStoreReviewController` / `requestReview` is Apple's supported way.
8. Typo **"Bad Sing"** in both share texts (`AppDelegate.m`,
    `ViewController.m`).
9. `NSLog` diagnostics (`[DIAG]`, `[HTML]`, `[PNG]`, `[VIEWPORT]`,
    `[PRELOAD]`, and the Chinese helpers' loop logs) run in release builds too.

## Code and project hygiene

10. Dead code: the synchronous `stringByEvaluatingJavaScriptFromString:`
    category in `ViewController.m` (spins the run loop; unused), commented-out
    time picker and `UIWebView`/iAd code, the `ready://` handler in every HTML
    page, the `LaunchImage` asset, the empty `Flurry/` folder, `1-wind.png`.
11. Misleading names: `getHtml7z:` and `getPng7z:out:` no longer touch a 7z
    archive; log lines still say "LZMA". `Signs.h` still has the header
    comment `MoonPhase.h`.
12. Sign icons are copied from the bundle to `tmp/<row>@2x.png` and then read
    back with `imageWithContentsOfFile:`. Loading them straight from
    `SignAssets/` would skip the copy (a leftover from archive extraction).
13. Legacy settings: `VALID_ARCHS = armv7 armv7s arm64` and
    `UIRequiredDeviceCapabilities = armv7` date from 32-bit iOS; with a
    deployment target of 15.0 only arm64 matters. The iCloud key-value-store
    entitlement is not used by any code.
14. Global mutable state: `rowSelected`, `secSelected`, `old_rowSelected`,
    `delegate`, `backColor` (ViewController) and `backTap` (AppDelegate) are
    file-level C globals rather than ivars.
15. Some PNGs are 16-bit (libpng warnings at build time).
