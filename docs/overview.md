# Overview

## What the user sees

The app has one screen with two states, switched by tapping the date in the
navigation bar.

### 1. Date entry (picker + stats panel)

Shown on first launch (no saved birthday) and whenever the user taps the date
label.

- A wheel-style `UIDatePicker` (date only) sits under the navigation bar.
- The nav-bar label shows the selected date with a ✓ while the picker is open.
- Below the picker, a light panel shows statistics for the chosen birthday:
  - the full date (e.g. "Monday, 1 January 1990")
  - "Since your birthday:" followed by
    - years / months / days ago
    - weeks / days ago
    - total days ago
    - decimal years ago (`years + days/365`)
  - the **moon phase on the birthday**: one of 8 images (`moon0`…`moon7`) with
    a label (New Moon, Young Crescent, First Quarter, Waxing Gibbous, Full Moon,
    Waning Gibbous, Last Quarter, Old Crescent)
  - "Tap anywhere to close"
- Each wheel change is debounced by 0.5 s, then the birthday is saved and the
  stats and signs are recalculated.
- Tapping the panel (or any table row) closes the picker.

### 2. Sign list

A table of 12 coloured rows, one per system, in rainbow order (red → magenta).
Each row has a small upper band with the system name, a large band with the
sign name, and the sign's icon on the right.

| Row | System | Possible values |
|---|---|---|
| 0 | Western Astrology | 12 zodiac signs |
| 1 | Chinese Astrology | 12 animals |
| 2 | Aztec Astrology | 20 day signs |
| 3 | Mayan Astrology | 20 day signs |
| 4 | Egyptian Astrology | 12 gods |
| 5 | Zoroastrian Astrology | 32 animals |
| 6 | Celtic Astrology | 13 trees |
| 7 | Norse Astrology | 12 gods |
| 8 | Slavic Astrology | 15 gods |
| 9 | Numerology | Life path 1–9, 11, 22 |
| 10 | Geek Astrology | 12 archetypes |
| 11 | Bad Sign | 12 creatures from Serbian folklore |

Details of each are in [sign-systems.md](sign-systems.md).

While signs are being calculated and their pages pre-loaded, the rows show
"..." and the table ignores taps. When all 12 pages are ready, the names
appear.

Tapping a row expands it: a detail row opens under it with the sign's HTML
page (dates, symbols, description) and a footer band with two buttons:

- **share** (left): renders the row and its page to a JPEG and opens the share
  sheet with "I am reading about the X in Y using Bad Sing app..." and the
  App Store link.
- **Void Software logo** (right): opens the Void Software Facebook page (the
  Facebook app if installed, otherwise the mobile site).

Tapping the row again (or its detail) collapses it; tapping another row
switches to it. Only one row is open at a time.

### Share all signs

The share icon at the right of the navigation bar closes any open row, renders
all 12 sign bands on top of the `sharebig` background, scales it to 540 px
high, saves it as `Documents/badsign.jpg`, and opens the share sheet with
"Check out all Your signs using Bad Sing app..." and the App Store link.

### Rating prompt

Each time the picker is closed a use counter goes up. On the fifth time a
"Rate Bad Sign" alert offers to open the App Store review page; after that the
counter is set to -99 so the alert does not return for another ~100 uses.

## Stored data

| `NSUserDefaults` key | Type | Meaning |
|---|---|---|
| `birtday` (sic) | `NSDate` | The selected birthday. The misspelling is load-bearing: renaming it would lose every existing user's date. |
| `uses_count` | `NSInteger` | Rating-prompt counter, saved when the app resigns active. |

Files written: `Documents/badsign.jpg` (last share image) and
`tmp/<row>@2x.png` (copies of the current sign icons, see
[architecture.md](architecture.md)).
