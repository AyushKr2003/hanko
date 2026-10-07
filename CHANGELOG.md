# Changelog

## Unreleased

- Profile 印影, About 由来, Credits 謝辞: three poster plates in the settings window. Profile presses your seal beside your name, the bar's live readings and your machine's small print, and can be edited and saved as an image (`~/.config/hanko/profile.json`).
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
- Fix: the inbox read empty whenever no toast was on screen (the history was never reached); it now lists Omarchy's notification history.
- Fix: the Network sheet and scroll section showed only the network you were on; they now ask NetworkManager to scan when they open and every 30 s while open.
- Indicator stamps 印: Omarchy's six indicators (recording, dictation, reminder, stay awake, night light and, new, do not disturb) as small stamps before the inbox, pressed and askew when on, faint when off; a click switches them as on Omarchy's bar, hovering names one. Two new settings, `indicators` (all, active) and `indicatorStyle` (icon, kanji, iconname, kanjiname; kanji stamps that are on are small red seals), twenty in all (7,739,670,528 combinations).
- Type scale: every size, weight and letter spacing comes from one scale in `core/Type.qml` (tag 9, label 10, eyebrow 11, figure and note 12, value 13, row 14, byline 15, clock 22, title 40, hero 46 at Omarchy's 12 px font). Labels that were 8 px on a 1x screen are 10 px, nothing anyone reads is under 10 px, kanji glosses stay as small as the labels' capitals, small text is never in the faintest ink, and bar values are Medium. A new `typeSize` (small, regular, large) beside motion scales Hanko's text and the bar with it; it is the Type size row in the Frame card.
- Fix: the window title's app name rendered bold.
- Fix: the Network sheet could open with only the network you were on (NetworkManager prunes its cache while connected, and the scan landed seconds after the sheet closed). Opening it, or Rescan, now runs a full scan and shows it as soon as it lands, and networks seen in the last five minutes stay listed, so the sheet and the scroll agree.
- End leaf 跋: the bare paper after Inbox on the scroll holds one of nine leaves, an eighteenth setting `endleaf`: a colophon of your machine, an almanac (month, solar term, microseason, moon), the machine's load over the last hour, the session (hold a seal to lock, suspend, log out, restart or shut down), Omarchy's themes, Omarchy's tools, a focus timer, today's notes with the clipboard, or an afterword. A gallery on the Scroll settings page, a kanji row in Typesetting, `hanko hide endleaf` (967,458,816 combinations).
- Scroll sides: the rollers at the scroll's two edges are gone. A twenty-first setting, `sides`, picks `bare` (the paper meets the screen) or `curl` (the default, a soft fold as if the paper rolls under). 15,479,341,056 combinations.
- Scroll guides: a twenty-second setting, `guides`, shows the scroll's index plate of tabs on top and the position bar along the foot together (`both`, the default), either one (`tabs`, `foot`) or neither (`none`). A Panels row in Typesetting, `hanko style set guides tabs`. 61,917,364,224 combinations.

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
