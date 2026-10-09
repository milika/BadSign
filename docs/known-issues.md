# Known issues and technical debt

Found while writing these docs (2026-10-09). None of these have been fixed.
Most important first.

## Sign calculations

Changing any of these also changes users' **Bad Sign**, which is the sum of
all the others.

1. **Numerology is wrong for most dates.** The reduction loop in
   `numerologySign` (`Signs.m`) does

   ```objc
   nT = num;
   num = nT % 10;
   num += lround(floor(num / 10));   // should be nT / 10
   ```

   so it keeps only the last digit instead of adding the digits. Example:
   1 Jan 1990 → 1+1+1+9+9+0 = 21 → should be 3, the app shows 1. A
   re-implementation over every day 1–28 of 1920–2029 disagrees with the
   standard life-path number on about 95% of dates. Day 11 and month 11 are
   also kept as 11 rather than reduced, which is a matter of school rather
   than a bug.
2. **Aztec year table is suspect.** `aztecSign` uses an 85-entry table for
   1900–1984. Each year should advance the day sign by 5 (6 after a leap
   year), but the table breaks that at 1957 (11 → 7), 1958 (7 → 2), 1983
   (8 → 8) and 1984 (8 → 18). Years after 1984 wrap back by 85 years, and
   85 years is not a whole number of 20-day cycles (31,046 days ≡ 6 mod 20),
   so every birthday after 1984 is probably off. Worth checking against a
   reference tonalpohualli and replacing with a Julian-Day calculation like
   `mayanSign` uses.
3. **Slavic gaps and odd mappings.** 21 February matches no rule and falls
   through to index 0 (Yarilo). 11–23 Dec is commented "Kitovas = Perun" but
   returns 1 (Lada). Check the intended table.
4. **Float precision in Julian Days.** `chineseSign`, `mayanSign` and their
   helpers hold Julian Day numbers (~2.4 million) in `float`, which resolves
   only to about 0.25 day. Births right at a Chinese New Year boundary may get
   the wrong animal. Using `double` would remove the doubt.
5. **Pre-1928 Chinese time zone** is computed as `-(465+40/60)/60`, which is
   integer arithmetic and gives -7 h instead of the intended -7 h 45 min 40 s.
6. **Time zone dependence.** All systems take day/month/year from the device's
   current calendar and time zone, while the date is stored as an absolute
   `NSDate`. A user who changes time zone could see their birthday shift by
   a day.
7. `moonSign` is unused and marked "Wrong?" in its own source.

## App behaviour

8. **Race on fast date changes.** `calculateSigns:` can run again while the
   previous background job or web-view pre-load is still going. The old
   off-screen web views are removed from their container, but they keep this
   controller as navigation delegate, so a late `didFinishNavigation` can
   still decrement `preloadPendingCount` and store a height for the new set
   of pages. The 0.5 s debounce makes this rare, not impossible.
9. **Each page load carries the whole font.** `injectFontIntoWebView:`
   base64-encodes `Helvetica.ttf` into a `<style>` for every page, 12 at a
   time during pre-load. Referencing it with a relative `@font-face` URL
   (the pages already load with the bundle as base URL) would be lighter.
10. **Fixed 320 pt layout.** Frames are computed from a 320 pt-wide design
    and the picker/panel position from the navigation bar frame at launch.
    Rotation is disabled, Dynamic Type and dark mode are ignored (the picker
    forces light mode).
11. **Custom rating prompt.** The "Rate Bad Sign" alert (with a "Noooo"
    button) after five uses is a home-made prompt;
    `SKStoreReviewController` / `requestReview` is Apple's supported way.
12. Typo **"Bad Sing"** in both share texts (`AppDelegate.m`,
    `ViewController.m`).
13. `NSLog` diagnostics (`[DIAG]`, `[HTML]`, `[PNG]`, `[VIEWPORT]`,
    `[PRELOAD]`, `num %i` in `aztecSign`) run in release builds too.

## Code and project hygiene

14. **The only unit test always fails** (template `XCTFail`). `Signs` is pure
    and easy to test: a table of dates → expected indices per system would
    have caught items 1–3.
15. Dead code: the synchronous `stringByEvaluatingJavaScriptFromString:`
    category in `ViewController.m` (spins the run loop; unused), commented-out
    time picker and `UIWebView`/iAd code, the `ready://` handler in every HTML
    page, the `LaunchImage` asset, the empty `Flurry/` folder, `1-wind.png`.
16. Misleading names: `getHtml7z:` and `getPng7z:out:` no longer touch a 7z
    archive; log lines still say "LZMA". `Signs.h` still has the header
    comment `MoonPhase.h`.
17. Sign icons are copied from the bundle to `tmp/<row>@2x.png` and then read
    back with `imageWithContentsOfFile:`. Loading them straight from
    `SignAssets/` would skip the copy (a leftover from archive extraction).
18. Legacy settings: `VALID_ARCHS = armv7 armv7s arm64` and
    `UIRequiredDeviceCapabilities = armv7` date from 32-bit iOS; with a
    deployment target of 15.0 only arm64 matters. The iCloud key-value-store
    entitlement is not used by any code.
19. Global mutable state: `rowSelected`, `secSelected`, `old_rowSelected`,
    `delegate`, `backColor` (ViewController) and `backTap` (AppDelegate) are
    file-level C globals rather than ivars.
20. Some PNGs are 16-bit (libpng warnings at build time).
