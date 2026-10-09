# History

## 2013–2014: original app

Written by Void Software from December 2013 (file headers), released on the
App Store as id 912176242. Sign pages and icons were packed in a 7z archive
and decompressed at runtime with the LZMA SDK; `UIWebView` showed the pages;
Flurry did analytics. The git history does not cover this period: the
repository starts with an import on 2026-04-05.

## April 2026: modernisation (builds 6 → 18)

All in git, 2026-04-05 to 2026-04-22.

### Platform updates

- `UIAlertView` replaced with `UIAlertController` for the rating prompt.
- `UIWebView` replaced with `WKWebView`.
- Flurry SDK removed.
- LZMA SDK and the 7z archive removed; content now lives as plain files in
  the `SignAssets/` folder reference.
- Photo-library usage descriptions added (needed by "Save Image" in the share
  sheet).

### UI freeze while turning the date wheel

**Symptom:** the picker stuttered and the app froze while scrolling the date.

**Cause:** every wheel tick ran `updateStats`, which recalculated all signs
and decompressed 12 pages and 12 icons on the main thread.

**Fix:** `dateChanged:` restarts a 0.5 s `NSTimer` (`datePickerTimer`) and
only the timer calls `updateStats`; `calculateSigns:` moved file work to a
background queue and returns to the main queue for UI updates.

### Memory kills from 12 web views

**Symptom:** the app was killed by the system (exit 9) after a few date
changes.

**Cause:** each `calculateSigns:` created 12 `WKWebView`s and kept them,
each with its own WebContent process.

**Fix:** HTML is kept as strings; a web view is attached only to the open
row and removed (`releaseExpandedWebView`) when the row closes, and content
heights are cached in `webHeights`. Later (build 7–10) a pre-load step was
added that loads all 12 pages off-screen once per date so the first tap is
instant; the titles stay "..." and the table ignores taps until that
finishes. See [architecture.md](architecture.md#calculatesigns-in-three-phases).

### Small text in most sign pages

**Symptom:** every system except Western showed tiny text.

**Cause:** pages 1–10 had no viewport `<meta>` and page 11 had one without
`width=device-width`, so `WKWebView` laid them out at 980 px and scaled down.

**Fix:** `calculateSigns:` adds the viewport tag when a page lacks it. Only
the 12 Western pages (`0-*.html`) carry the tag themselves, so this
injection is still required for the other 171.

### Content and look

- Paragraphs justified, padding unified, invalid closing `</p>` tags removed
  across the HTML pages.
- The HTML font is injected from the bundled `Helvetica.ttf`, and pages are
  measured again 0.4 s after load so the row grows if the font makes the text
  longer.
- The table background became a gradient from the first row's colour to the
  last, so over-scrolling at either end matches the rows.

## October 2026: calculation fixes

Unit tests were added for every sign system, and they exposed these bugs,
which were then fixed. Comparing old and new results for every day from 1920
to 2025:

| System | Change | Dates whose result changed |
|---|---|---|
| Numerology | The reduction step kept only the last digit (21 → 1 instead of 3); it now adds the digits | 95% |
| Aztec | The 1900–1984 lookup table (one sign ahead of the historical count, and wrong after 1984) was replaced by the Maya day count, which is the same cycle (owner's choice: historical count) | 87% |
| Slavic | 21 Feb now Stribog (was Yarilo by fall-through); 11–23 Dec now Perun as the comment intended (was Lada) | 4% |
| Chinese | Julian Days moved from `float` to `double`; pre-1928 time zone fixed. Each of the 12 changed dates is the eve of a Chinese New Year that the old code switched a day early (e.g. 14 Feb 1991) | 12 days |
| Bad Sign | Follows from the above (sum of all, mod 12) | 95% |

Other systems are unchanged. The Bad Sign rule moved from `ViewController`
into `-[Signs badSign]`. The test target became an unhosted logic-test
bundle, and the project-wide deployment target was raised from 12.0 to 15.0
(the app already required 15.0; current Xcode refuses 12.0).
