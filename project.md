# Bad Sign

An iOS app built in Objective-C by **Void Software** that calculates a user's astrological signs across 12 different cultural and esoteric traditions based on a single birthdate input.

Available on the App Store: https://itunes.apple.com/us/app/bad-sign/id912176242

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
| Analytics | Flurry SDK (integrated but currently disabled/commented out) |
| Fonts | Custom `Helvetica.ttf` (Helvetica Neue LT Com) |
| Persistence | `NSUserDefaults` (birthday, usage count) |
| Sharing | `UIActivityViewController` with JPEG screenshot + App Store URL |

---

## Build & Run

Open `Bad Sign.xcodeproj` in Xcode, select a device or simulator, and run. No external dependencies beyond what is in the repository.

> **Note:** The Flurry analytics session key is present in the source but the integration is commented out. Re-enable it in `AppDelegate.m` if analytics are needed.

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
