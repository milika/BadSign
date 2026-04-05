# Bad Sign

An iOS app built in Objective-C by **Void Software** that calculates a user's astrological signs across 12 different cultural and esoteric traditions based on a single birthdate input.

---

## Overview

The user selects a birthday using a `UIDatePicker`. The app then computes the user's sign in every supported astrology system and displays the results in a scrollable, expandable table. Each row shows the sign name and a color-coded band; tapping a row expands it to show a detailed HTML description loaded from a bundled 7z archive.

A proprietary **"Bad Sign"** is derived by summing the index values of all other calculated signs and taking the result modulo 12 — presented as the final, tongue-in-cheek entry on the list.

---

## Supported Astrology Systems

| # | System | Signs |
|---|--------|-------|
| 1 | Western Astrology | Aries, Taurus, Gemini, Cancer, Leo, Virgo, Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces |
| 2 | Chinese Astrology | Rat, Oxen, Tiger, Rabbit, Dragon, Snake, Horse, Sheep, Monkey, Rooster, Dog, Pig |
| 3 | Aztec Astrology | 20 day-signs (Crocodile → Flower) |
| 4 | Mayan Astrology | 20 day-signs (Crocodile → Sun) |
| 5 | Egyptian Astrology | Thoth, Horus, Wadjet, Sekhmet, Sphinx, Shu, Isis, Osiris, Amun, Hathor, Phoenix, Anubis |
| 6 | Zoroastrian Astrology | 32 animal signs (Deer → Falcon) |
| 7 | Celtic Astrology | 13 tree signs (Birch → Elder) |
| 8 | Norse Astrology | 12 Norse deities (Ullr → Vidar) |
| 9 | Slavic / Svarog Astrology | 15 Slavic deities (Yarilo → Vesna) |
| 10 | Numerology | Life path number (1–9, with master numbers 11 and 22) |
| 11 | Geek Astrology | Robot, Wizard, Alien, Superhero, Slayer, Pirate, Daikaiju, Time Traveler, Spy, Astronaut, Samurai, Explorer |
| 12 | Bad Sign | Proprietary sign — sum of all sign indices mod 12 (Nash / Slavic mythology: Zmay, Alla, Bauk…) |

Additionally, the stats bar at the top displays:

- Current **moon phase** (8 phases, computed astronomically)
- **Moon sign** (zodiac position of the moon)
- Age in days/months/years since birthday

---

## Architecture

```
Bad Sign/
├── AppDelegate.h / .m      — App bootstrap, date picker UI, stats bar, share sheet
├── ViewController.h / .m   — Main UITableView, expandable rows, WKWebView sign details
├── Signs.h / .m            — Pure calculation class for all 12 astrology algorithms
├── LZMASDK/                — 7z decompression library (C + ObjC wrapper)
│   └── LZMAExtractor.h/m   — Extracts HTML + PNG assets from arch.7z at runtime
├── Images.xcassets/        — App icon, launch image, share button icons
├── Moon.xcassets/          — 8 moon phase images (moon0–moon7)
├── Bad Sign/               — Runtime asset images (N-M-0.png naming scheme)
├── arch.7z                 — Bundled archive: HTML descriptions + sign images
├── Helvetica.ttf           — Custom font (Helvetica Neue LT Com)
├── Launch Screen.storyboard
└── ViewController.xib      — Main view layout
```

### Key Classes

**`Signs`** (`Signs.m`)
- Initialized with an `NSDate`
- Exposes one method per astrology system (e.g. `-westernSign`, `-chineseSign`, `-mayanSign`)
- Contains full astronomical moon phase calculation (Meeus algorithm)
- All calculations are pure date math — no network calls

**`ViewController`** (`ViewController.m`)
- `UITableView` with expandable rows pattern: each sign row inserts a `WKWebView` row below it when tapped
- 12-color rainbow palette applied to each row `(UIColor` bands in spectral order)
- Calls `calculateSigns:` on birthday change, which calls all `Signs` methods and loads HTML/PNG from the decompressed archive
- PNG images are named using the pattern `{systemIndex}-{signIndex}-{variant}.png`

**`AppDelegate`** (`AppDelegate.m`)
- Builds the navigation controller and custom nav bar with date label + share icon
- Owns the `UIDatePicker` overlay and the stats panel (age, moon, next birthday countdown)
- Persists the birthday in `NSUserDefaults` under the key `"birtday"`
- Implements share via `UIActivityViewController` — renders the full screen to a JPEG and shares with a textual invite and App Store URL

---

## Data / Asset Pipeline

Sign descriptions and sign images are stored in a single **`arch.7z`** archive bundled inside the app. At runtime:

1. `LZMAExtractor` (wrapping the 7z LZMA SDK in C) extracts the requested file to the temporary directory.
2. HTML files are read into memory and injected into `WKWebView` via `-loadHTMLString:baseURL:`.
3. PNG images are loaded with `+[UIImage imageWithContentsOfFile:]`.

This keeps the app binary small while still shipping all content offline.

---

## Tech Stack

| Area | Detail |
|------|--------|
| Language | Objective-C |
| UI Framework | UIKit, WebKit (`WKWebView`) |
| Platform | iOS (armv7, portrait only) |
| Build System | Xcode (`.xcodeproj`) |
| Compression | LZMA SDK (7-Zip, C) via `LZMAExtractor` ObjC wrapper |
| Persistence | `NSUserDefaults` (birthday, usage count) |
| Sharing | `UIActivityViewController` with JPEG screenshot + App Store URL |

---

## Build & Run

Open `Bad Sign.xcodeproj` in Xcode, select a device or simulator, and run. No external dependencies beyond what is in the repository.

---

## Bug Fixes & Investigations

### UI freeze when choosing birthdate (`dateChanged:` firing continuously)

**Symptom:** Scrolling the date picker wheel caused the app to freeze and eventually be killed by the OS watchdog (exit code 9 / SIGKILL). Debug log showed multiple rapid `** calculateSigns` calls and a dozen WebContent processes launching in parallel (~1s each).

**Root cause:** `UIDatePicker` fires `UIControlEventValueChanged` on every wheel tick. Each event immediately called `updateStats` → `calculateSigns`, which performed 24 synchronous LZMA extractions and created 12 new `WKWebView` instances on the main thread. With rapid scrolling, calls piled up before the previous one finished, saturating the main thread and triggering the watchdog.

**Fix (`AppDelegate.m`):** Debounced `dateChanged:` with an `NSTimer`. The date label is updated immediately on every tick (keeps UI responsive), but `updateStats` / `calculateSigns` is only invoked 0.5 s after the *last* tick — i.e. once the user stops spinning the wheel.

```objc
// AppDelegate.h — added ivar:
NSTimer * datePickerTimer;

// AppDelegate.m — dateChanged: now debounces the heavy work:
[datePickerTimer invalidate];
datePickerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(updateStats)
                                                userInfo:nil
                                                 repeats:NO];
```

---

### UI freeze at app startup (`calculateSigns:` blocking main thread)

**Symptom:** App appeared to hang for several seconds immediately after launch before the table became interactive. The same symptom occurred after each date change once the picker debounce was in place.

**Root cause:** `calculateSigns:` ran 24 synchronous LZMA decompressions (12 PNG + 12 HTML extracted from `arch.7z`) sequentially on the **main thread**, then constructed 12 `WKWebView` instances — all before returning. The entire operation took several seconds, during which the run loop was blocked.

**Fix (`ViewController.m`):** Refactored `calculateSigns:` into three phases:

1. **Phase 1 — main thread, instant:** Calculate all 12 sign indices using the pure-math `Signs` methods. Store results in `signIndices` array.
2. **Phase 2 — background thread (`DISPATCH_QUEUE_PRIORITY_DEFAULT`):** Run all 24 LZMA extractions (`getPng7z:` / `getHtml7z:`) off-thread. Main thread is freed immediately.
3. **Phase 3 — main thread (inner `dispatch_async`):** Create `WKWebView` instances, load HTML strings, update `horData`, call `reloadData`. All UIKit work safely back on the main thread.

```objc
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // extract all 12 HTML + PNG files ...
    dispatch_async(dispatch_get_main_queue(), ^{
        // update cells and reload table ...
    });
});
```

---

### WKWebView memory bloat (12 simultaneous WebContent processes)

**Symptom:** Each time `calculateSigns:` ran, up to 12 `WKWebView` instances were created and retained indefinitely. Each spawns its own `WebContent` process, pushing total memory well above the watchdog limit. OS killed the app with exit code 9.

**Fix (`ViewController.m`):**
- Switched to **lazy loading**: `WKWebView` instances are created only when a row is expanded (tapped), not upfront.
- HTML strings are stored in `htmlData` array on background thread; the web view is built and loaded only in `tableView:heightForRowAtIndexPath:` / `tableView:cellForRowAtIndexPath:` when that cell first becomes visible.
- When a different row is expanded, the old `WKWebView` is removed from its parent cell with `[wv removeFromSuperview]`, terminating its `WebContent` process. At most 1 web process is alive at a time.
- Content heights are cached in `webHeights` (per sign) so `tableView:heightForRowAtIndexPath:` does not re-load HTML on every layout pass.

---

### Signs 1–11 rendering with small fonts (viewport scaling issue)

**Symptom:** After tapping any sign other than Western Astrology (sign 0), the expanded HTML detail panel showed very small text compared to the first sign.

**Root cause investigation:** Added `[VIEWPORT]` diagnostic logs that print each sign's `<meta>` tag on extraction. Logs revealed:
- Sign 0: already had a correct `width=device-width` viewport tag in the HTML file.
- Signs 1–10: had **no `<meta>` tag at all** — `WKWebView` fell back to the default 980 px desktop viewport and scaled the content down to fit the screen.
- Sign 11: had an incomplete `<meta name="viewport" content="user-scalable=no">` with no width declaration.

**Fix (`ViewController.m`):** After extracting each HTML string, inject the viewport meta tag if `width=device-width` is not already present:
- If the HTML contains `<head>` (or `<HEAD>`), insert the tag immediately after it.
- Otherwise prepend the tag to the whole string.

```objc
NSString *viewportMeta = @"<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' />";
if (![html containsString:@"width=device-width"]) {
    if ([html containsString:@"<head>"])
        html = [html stringByReplacingOccurrencesOfString:@"<head>"
                     withString:[NSString stringWithFormat:@"<head>%@", viewportMeta]];
    else
        html = [viewportMeta stringByAppendingString:html];
}
```
```
