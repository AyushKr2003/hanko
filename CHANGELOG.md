# Changelog

## Unreleased

- Display 明: the LUM cell's panel, as a sheet and a scroll section (brightness per monitor, monitors, night light).
- Motion 動: Scroll's motion across the bar (sliding plates, fading values, a creeping now-notch, the stamp press, sheets that print) and a paper/still switch on a new Motion page.
- Per-monitor overrides can be set in the settings window under Advanced.
- Widgets 部品: show or hide anything on the bar (Hanko's own parts, each reading, indicator and mark, each tray app, every hosted Omarchy or third-party widget), saved as `hidden` in style.json; `hanko hide|show <part>` from a terminal.
- The settings window reflows to any size, tiled or floating, down to 420 px wide.
- Sheets drop under the cell they belong to (they all opened at the left edge).
- Bluetooth 藍: a BT cell, a sheet, a scroll section and a sixteenth setting (`bluetooth: on|off`, 5,971,968 combinations).
- Bluetooth cell styles: `device` (was `on`), `marks` (a kanji per device, its charge filling it) and `count` (a count and a dot per device); Scroll and Islet use marks (11,943,936 combinations).
- Weather 天: a leaf left of Time on the scroll, with today's curve, rain, sun and the next three days, from the same place, units and forecast as Omarchy's weather panel; `hanko hide weather` removes it.
- Scroll dividers 間: the dither between the scroll's sections is replaced by a seventeenth setting, `interlude`, with nine styles (ma, hairline, folio, kotoba, tsugime, seal, jiku, fuda, su), a gallery on the Scroll settings page and a kanji row in Typesetting (107,495,424 combinations).

## Typeset design · 2026-10-06

- Sheet and Scroll merged into one bar. Every part is now a setting: seal, workspaces, title, clock, clock position, now playing, status, meters, notifications, edge, dividers, height, surface, position and panels (2,985,984 combinations).
- Six presets: Sheet, Scroll, Hanko (the merge, default), Quiet, Instrument and Islet.
- New options: kanji and dot workspaces, mono clock, clock on the right, numeral status, the roller that carries the day (`rodrule`), glass and inset surfaces, bottom position, 32 and 44 px heights.
- The Typesetting settings page, in the Ryoku Hub grammar, with live preview and preset gallery.
- `docs/COMPONENTS.md`: every option, how options interact, presets, the config file and the settings page.
- 19 sheets: settings (dark and light), presets, shuffle, presets × themes, six component catalogues, two light catalogues, six full desktops.
- Sheet and Scroll docs and mockups moved under `docs/history/` and `docs/mockups/{sheet,scroll}/`.

## Scroll design · 2026-10-06

- New direction from scratch: a calm, single-line bar that unrolls into a horizontal handscroll (emaki) holding every panel.
- New bar components: workspace-numeral seal, real-layout workspace glyphs, serif byline, kanji glyph status, notification stamps, and the rod.
- New scroll controls: fader bank, day ribbon, spaces map, stamped inbox.
- Six mockups (desktop, bar, two scroll views, motion, themes) and their HTML sources.

## Sheet design · 2026-10-06

- Design direction: the bar as a printed running head (seal, label/value cells, tick meters, day rule, folio workspaces, flush sheets).
- Five mockups and the HTML they are rendered from.
- Design rationale in `docs/DESIGN.md`.
