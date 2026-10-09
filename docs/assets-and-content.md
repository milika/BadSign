# Assets and content

## `SignAssets/`: one page and one icon per sign

Added to the target as a **folder reference** (blue folder), so its files are
copied into `Bad Sign.app/SignAssets/` as they are, and anything dropped into
the folder ships without touching the Xcode project.

Naming: `<row>-<index>.html` and `<row>-<index>@2x.png`, where `row` is the
system (0–11, see [sign-systems.md](sign-systems.md)) and `index` the sign.

| Row | System | Pages |
|---|---|---|
| 0 | Western | 12 |
| 1 | Chinese | 12 |
| 2 | Aztec | 20 |
| 3 | Mayan | 20 |
| 4 | Egyptian | 12 |
| 5 | Zoroastrian | 32 |
| 6 | Celtic | 13 |
| 7 | Norse | 12 |
| 8 | Slavic | 15 |
| 9 | Numerology | 11 |
| 10 | Geek | 12 |
| 11 | Bad Sign | 12 |
| | **Total** | **183** (+ 183 icons) |

To add a sign to a system: add its name to the right list in `tableSubData`
(`ViewController.m`), make the `Signs` method able to return the new index,
and add `SignAssets/<row>-<index>.html` and `<row>-<index>@2x.png`.

### HTML page conventions

The pages are hand-written, old-style HTML (`<FONT>`, `<center>`, `</br>`).
What the app relies on:

- a `<head>` (or `<HEAD>`). Only the Western pages (`0-*.html`) contain a
  `width=device-width` viewport `<meta>`; for the other 171 `calculateSigns:`
  inserts one after `<head>`, so do not remove that code without first adding
  the tag to every page;
- background `#f0f0ed`, text `#343434`, body padding 15 px,
  `p { text-align: justify; }`, font family "Helvetica Neue LT Com" (the app
  injects the font after load, see [architecture.md](architecture.md#font-injection));
- images referenced by bare file name (`<img src="0-0-0.png">`), resolved
  against the app bundle root;
- an `onload` handler that navigates to `ready://<height>`; the app cancels
  that navigation and measures the height itself, so the handler is harmless
  but no longer needed.

## Inline images in the bundle root (`Bad Sign/[0-9]*.png`)

About 170 small PNGs added to the target individually (not via the folder
reference), used only from inside the HTML pages:

| Pattern | Used by | Content |
|---|---|---|
| `0-<sign>-0.png`, `0-<sign>-1.png` | Western pages | two header pictures per sign |
| `1-<sign>-0.png` | Chinese pages | animal picture |
| `1-earth/fire/metal/water/wood.png` | Chinese pages | element pictures (`1-wind.png` is unused) |
| `3-<sign>-0.png` | Mayan pages | glyph |
| `4-<sign>-1.png` | Egyptian pages | picture |
| `<row>-l.png`, `<row>-r.png` | rows 2–11 | left/right header pictures (row 3 has only `-r`, row 4 only `-l`) |

New images must be added to the target's *Copy Bundle Resources* phase, or
moved into `SignAssets/` and referenced as `SignAssets/…`.

## Asset catalogs

| Catalog | Item | Used for |
|---|---|---|
| `Images.xcassets` | `AppIcon` | app icon |
| | `LaunchImage` | legacy launch image (the launch storyboard is what is used) |
| | `share-white` | share icon in the navigation bar |
| | `share` | share button in each detail footer |
| | `sharebig` | background of the "all signs" share image |
| | `void` | Void Software logo in each detail footer |
| `Moon.xcassets` | `moon0` … `moon7` | moon phase images in the stats panel |

## Font

`Helvetica.ttf` registers the family **"Helvetica Neue LT Com"** (listed under
`UIAppFonts` in `Bad Sign-Info.plist`). All labels request it by name; if it
failed to load, `UIFont fontWithName:` would return `nil` and labels would
fall back to the system font. Check its licence before redistributing the
app's sources: Helvetica Neue LT is a commercial typeface.

## Build note

The build prints 16 `libpng warning: Input PNG does not have an 8 bit input
depth` lines: some PNGs are 16-bit. Harmless, but converting them to 8-bit
would shrink them.
