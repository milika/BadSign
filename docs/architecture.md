# Architecture

Three classes do all the work. There is no model layer, no storyboard
navigation and no Auto Layout: views are built in code with fixed frames
scaled from a 320 pt design (`screenWidth - (320 - x)`).

```
main.m ─► AppDelegate ──owns──► UINavigationController ─► ViewController (table)
              │                         │
              │ date picker, stats      │ calculateSigns:(NSDate*)
              │ panel, share-all        ▼
              └──────────────► Signs (pure date maths, one instance per date)
```

## AppDelegate (`AppDelegate.m`)

Builds the whole UI in `application:didFinishLaunchingWithOptions:`:

- the window and a `UINavigationController` whose root is `ViewController`
  (loaded from `ViewController.xib`);
- a custom title view added straight onto the navigation bar, holding the date
  label, the share icon and an activity indicator; one tap recogniser on it
  decides by x position whether the tap was "share" or "date";
- `statsView`, the light panel with the birthday statistics and moon phase;
- the `UIDatePicker`, added over the navigation controller's view.

Flow on a date change:

```
UIDatePicker valueChanged ─► dateChanged:  (updates label, restarts 0.5 s timer)
                                   │
                         timer ─► updateStats
                                   ├─ save NSUserDefaults "birtday"
                                   ├─ fill stats labels (NSCalendar component diffs)
                                   ├─ Signs.phase ─► moon image + label
                                   └─ [viewController calculateSigns:birthday]
```

`hidePickers` animates the picker and panel away and drives the rating prompt.
`shareTap` (run on a background queue) builds the "all signs" image by calling
`-[ViewController getBandImage:]` for each row; that method hops to the main
queue with `dispatch_sync` because it scrolls the table and renders cells.

App Store URLs are built from `kAppStoreID` in `AppDelegate.h`.

## Signs (`Signs.m`)

`-initWithDate:` stores the date; each `-xxxSign` method returns an `int`
index into that system's name list (kept in `ViewController`). All methods use
`[NSCalendar currentCalendar]` date components, so results follow the device's
calendar and time zone. `-phase` returns the moon's phase as a 0–1 fraction.
`-moonSign` exists but is not called anywhere. The algorithms are described in
[sign-systems.md](sign-systems.md).

## ViewController (`ViewController.m`)

### Static data (set up in `initWithNibName:bundle:`)

| ivar | Content |
|---|---|
| `tableSections` | `["Classic"]`: one section (more were planned and commented out) |
| `tableData` | the 12 system names |
| `tableSubData` | per system, the list of sign names, indexed by the `Signs` result |
| `tableColors`, `tableColorsUp` | 12 main-band and top-band colours |
| `cells` | 12 pre-built sign cells (not reused through the table's queue) |
| `webViews` | 12 pre-built detail cells, each with a footer ("social band") |
| `horData` | current sign index per row, `NSNull` while unknown |
| `htmlData` | current HTML per row |
| `webHeights` | measured content height per row |
| `preloadedWebViews` | 12 off-screen `WKWebView`s, `NSNull` once taken by a cell |

View tags used to find subviews: `1001` the detail web view, `1002` top band,
`1003` main band, `1004` system label, `1005` sign label, `1006` icon, `1007`
footer band, `2000+i` pre-loading web views.

### `calculateSigns:` in three phases

1. **Main thread, maths.** Skip if the date is within 30 s of the last one.
   Close any open row, blank all titles (`NSNull` → "..."), disable table
   interaction, compute the 11 indices with `Signs` and the Bad Sign as
   `sum % 12`.
2. **Background queue, file I/O.** For each row: copy
   `SignAssets/<row>-<idx>@2x.png` to `tmp/<row>@2x.png` (`getPng7z:out:`),
   read `SignAssets/<row>-<idx>.html` (`getHtml7z:`), and add a
   `width=device-width` viewport `<meta>` if the page lacks one. (The `7z`
   names and "LZMA" log lines are left over from when the content lived in a 7z
   archive.)
3. **Main thread, UI.** Store the HTML, clear cached heights, drop any web view
   still attached to a detail cell, then `preloadAllWebViews`.

`preloadAllWebViews` loads all 12 pages into `WKWebView`s that live in a
container placed off-screen to the left (`x = -3 × screenWidth`), using the app
bundle as base URL so the pages' `<img src="…png">` resolve. Each
`webView:didFinishNavigation:` injects the font, measures
`document.body.scrollHeight`, caches it, and counts down `preloadPendingCount`.
When it reaches zero, `revealSignTitles` copies the pending indices into
`horData`, reloads the table and re-enables taps. A second measurement 0.4 s
later picks up height changes once the injected font has loaded.

### Expanding a row

The table has 12 rows, or 13 while a row is open (the detail row sits at
`rowSelected + 1`). `rowSelected = -99` means none is open.

- `didSelectRowAtIndexPath:` handles open, close and switch in one
  `beginUpdates`/`endUpdates` block, then scrolls the opened row to the top.
- `cellForRowAtIndexPath:` for the detail row moves the pre-loaded web view
  for that row into the cell (fading it in after 0.3 s); if none is available,
  it creates one and loads the HTML on demand.
- `heightForRowAtIndexPath:` returns 85 pt for sign rows and
  `cached height + 55` (footer) for the detail row.
- Closing or switching calls `releaseExpandedWebView`, which removes the web
  view from its cell so its WebContent process can go away. A web view that
  has been shown is not returned to the pre-load pool; reopening the same row
  loads it again on demand.

`webView:decidePolicyForNavigationAction:` cancels `ready://` URLs, which the
pages fire from their own `onload` handler (a leftover height-reporting trick
from the `UIWebView` days).

### Font injection

Every page gets a `<style>` added by JavaScript after load, with
`Helvetica.ttf` embedded as a base64 `@font-face` named
"Helvetica Neue LT Com". This is done per load, so each page receives a copy
of the whole font file.

## Threading summary

| Work | Thread |
|---|---|
| UI build, stats, sign maths | main |
| reading HTML, copying PNGs | global default queue |
| web view creation, loading, measuring | main |
| share-all image composition | global background queue, with `dispatch_sync` to main per band |
