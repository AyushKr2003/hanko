# Hanko: a printed bar for Omarchy

Working name. 判子 *hanko* is the personal seal stamped on a document; it is the one mark of colour on the bar.

## What I took from Ryoku Settings (and what I didn't)

Ryoku's settings app reads as a **printed instrument**: one paper colour, a warm ink in four contrast-tiers, hairlines instead of shadows, emphasis by **inversion** (the selected thing flips to a bone plate with a `//` lead), a serif only for titles, tracked mono for labels, and a kanji gloss beside every Latin label. Hanko keeps that grammar. It does not copy Ryoku's bars (QS Bar, Sumi, Kairos, Shima) or its exact palette, fonts-as-brand, or ornaments (barcodes, registration backdrops).

## The idea: the screen is a page, the bar is its running head

Most "premium" bars are floating pills, glass, glow and coloured icons. Hanko is the opposite: a flush, printed header strip. Three signatures, nothing else:

1. **The seal.** A small stamped square in the theme's red, with a slightly rough edge. It opens the Omarchy menu (right click: terminal). The glyph is a setting (印 by default).
2. **Labels over values.** Every status is a two-tier *cell*: a tracked mono label with its kanji gloss over a plain value, ruled off by hairlines like a spec table. No icon soup. Quantities (volume, battery, brightness) are **tick meters**, ten ruler ticks, never progress pills.
3. **The day rule.** The bar's bottom hairline is a 24-hour ruler: hour ticks, longer every six hours, the spent part of the day a shade brighter, and a red notch at *now*. A glanceable sense of the day without another widget.

Workspaces are **folio numbers** (`01 02 // 03 04`); the live one inverts, dots under a number count its windows, and a red dot marks urgent. The window title is a **running head** (app over title, path parts receding). The clock is the only serif on the bar.

## Sheets, not popups

Clicking a cell inverts it and a **sheet** drops flush from it, joined to the bar, with no gap or bubble. Each sheet is a mini settings page in Ryoku's layout: eyebrow, serif title, one-line blurb, `//` group heads, hairline rows, inverted selection, an action strip at the foot, and crop marks on the free corners. Sliders are rulers with a single needle.

## Colour: native to every Omarchy theme

Hanko reads Omarchy's `colors.toml`. Paper = `background`; ink = `foreground` walked toward the paper until it hits fixed contrasts (12, 9, 6.2, 4.6 : 1); the seal and alerts = the theme's `red`. Light themes work with no special case. A signature `hanko` theme ships for the hero look. The mono face is **your Omarchy font** (`omarchy font set`), so the bar feels native; Fraunces and Space Grotesk are bundled for the serif and the language.

## Motion (for the build)

No bounce, no blur-in. Inversion plates slide between items (one indicator, like Ryoku's rail); sheets reveal top-down in about 180 ms as if printed; values change with a quick crossfade; the now-notch creeps by the minute.

## How it plugs into Omarchy

A single `bar`-kind plugin (`hanko.bar`, same model as Omacale): `manifest.json` + `Bar.qml`, installed to `~/.config/omarchy/plugins/hanko.bar`, enabled with `omarchy bar use hanko.bar`. It reads the host's `barConfig` and `qs.Commons` theme singletons, drives Omarchy's own services (audio, network, battery, media, notifications, Hyprland workspaces, Elsewhen), honours `bar.position`, and still hosts third-party bar widgets. No second Quickshell process, no Hyprland edits.

## Mockups

- `docs/mockups/01-desktop.png`: the bar in situ on the signature theme
- `docs/mockups/02-bar-anatomy.png`: anatomy, states, type and ink
- `docs/mockups/03-sound-sheet.png`: the Sound sheet open
- `docs/mockups/04-time-sheet-kanagawa.png`: the Time sheet (calendar, day rule, Elsewhen) on Kanagawa
- `docs/mockups/05-themes.png`: six Omarchy themes, light and dark
- `docs/mockups/source/`: the HTML these were rendered from (`node shoot.mjs <file.html> <out.png>`)

Wallpapers in the mockups are procedural dither prints made for this, not part of the plugin.
