# Hanko: every component, every combination

Typeset merges the two earlier directions into one bar. Sheet (the printed running head) and Scroll (the calm bar that unrolls into a handscroll) are no longer rival designs. Each of their parts is now an option on one setting, chosen on Hanko's own settings page.

- **Sheet** is the Sheet design as drawn.
- **Scroll** is the Scroll design as drawn.
- **Hanko** is the merge, and the default.

Twenty settings give **7,739,670,528** distinct bars before you even change the seal glyph or the theme. Every one of them still reads as Hanko, because every option is drawn from the same three things: paper, four inks and one seal red.

![The settings page](mockups/typeset/01-settings.webp)

## Contents

1. [The rules every option keeps](#1-the-rules-every-option-keeps)
2. [The twenty settings](#2-the-twenty-settings)
3. [How options interact](#3-how-options-interact)
4. [Presets](#4-presets)
5. [Counting the combinations](#5-counting-the-combinations)
6. [The settings page](#6-the-settings-page)
7. [Config file](#7-config-file)
8. [Sheets](#8-sheets)

---

## 1. The rules every option keeps

These rules are what let any combination look designed rather than assembled.

| Rule | Why it matters |
|---|---|
| **One paper, four inks, one red.** All colour comes from Omarchy's `colors.toml`. Paper is `background`; ink is `foreground` stepped to 12, 9, 6.2 and 4.6 : 1; seal is `red`. | No option can introduce a colour, so no combination can clash. |
| **Red means "you" or "now".** The seal, the now-notch, an urgent workspace, a muted master fader, an unread dot. Nothing else is red. | Red stays a signal whatever you turn on. |
| **Emphasis is inversion.** The selected thing becomes a solid ink plate (folio page, kanji page, index tab, settings segment). | Every option highlights in the same way. |
| **Three typefaces with fixed jobs.** Fraunces for time, titles and bylines; Space Grotesk for values; your Omarchy mono for labels; Noto JP for kanji. | Swapping a clock style changes the face, never the system. |
| **One type scale, read at 1x.** Every size comes from `core/Type.qml`: mono tag 9 / label 10 / eyebrow 11 / figure 12, text note 12 / value 13 / row 14, Fraunces byline 15 / clock 22 / title 40 / hero 46, kanji gloss 9 / 11 / 13 (at a 12 px Omarchy font). Nothing anyone reads is under 10 px, text at 11 px or less is never in `inkFaint`, labels and bar values are Medium, and kanji glosses stay as small as their label's capitals. | The mockups were drawn at 2x; on a 1x laptop panel anything smaller turns to smudge. |
| **Hairlines, not shadows.** Dividers, frames and the edge are 1 px ink lines. | Glass and inset surfaces still look printed. |
| **One baseline.** Every zone sits on the same text baseline at every height. | Mixing cells, glyphs and numerals never wobbles. |

---

## 2. The twenty settings

Each setting has a key (used in the config file), its options, the default (from the Hanko preset), and where it came from. **Sheet** and **Scroll** are the two earlier designs; **New** is new in Typeset.

### Left: where you are

![Seal and workspaces](mockups/typeset/10-seal-workspaces.webp)

#### Seal `seal` 印

| Option | What it does | From |
|---|---|---|
| `stamp` | A fixed glyph (印 by default; any character). Click for the Omarchy menu, right-click for a terminal. | Sheet |
| **`workspace`** (default) | The seal shows the active workspace as a kanji numeral (壱 弐 参 …). Scroll on it to walk workspaces. | Scroll |
| `none` | No seal. The bar opens with the workspaces. | New |

The glyph used by `stamp` is a separate free-text setting, `sealGlyph` (印 力 侍 A …). It is not counted in the combinations below.

#### Workspaces `spaces` 頁

| Option | What it does | From |
|---|---|---|
| `folio` | Page numbers `01 02 // 03 04`. The live page inverts with a `//` lead; dots under a number count its windows; a red dot marks urgent. | Sheet |
| **`layout`** (default) | Each workspace drawn as its real tiling in hairlines. The live one is outlined and its focused window filled. Hover opens it to show window names. | Scroll |
| `kanji` | Kanji numerals 壱 弐 参 with window dots; the live one inverts. | New |
| `dots` | The quietest: one dot per workspace, the live one a short bar, urgent a red dot, empty an open ring. | New |

#### Window title `title` 窓

![Title and clock](mockups/typeset/11-title-clock.webp)

| Option | What it does | From |
|---|---|---|
| `cell` | The app as a tracked mono label (`ALACRITTY 窓`) over the title. | Sheet |
| **`byline`** (default) | The app in serif italic like an author's byline; title in grotesk; path parts recede. | Scroll |
| `none` | No title. | New |

### Centre: when

#### Clock `clock` 時

| Option | What it does | From |
|---|---|---|
| **`stacked`** (default) | Serif time, with the day and date stacked in small mono beside it. | Sheet |
| `inline` | Serif time with a red colon and a small-caps date on the same line. | Scroll |
| `mono` | All mono, for an instrument look. | New |

#### Clock position `clockAt` 中

| Option | What it does | From |
|---|---|---|
| **`center`** (default) | Anchored to the exact screen centre. | Sheet, Scroll |
| `right` | Joins the end of the right cluster, after a divider; the centre stays empty. | New |

#### Now playing `media` 再生

| Option | What it does | From |
|---|---|---|
| `cell` | `NOW 再生` label over artist and song. | Sheet |
| **`underline`** (default) | Song in serif italic; its underline is the progress bar. | Scroll |
| `none` | Hidden. | New |

### Right: how things are

#### Status `status` 音

![Status and meters](mockups/typeset/12-status-meters.webp)

| Option | What it does | From |
|---|---|---|
| **`cells`** (default) | `NET 接続 / VOL 音 / BAT 電` label-over-value cells ruled off by hairlines. | Sheet |
| `glyphs` | A boxed kanji is the icon and the number is the state. Solid red when it needs you; dashed when off. | Scroll |
| `numerals` | Mono labels and numbers on one line (`VOL 62 · NET Kumo · BAT 91%`). | New |

#### Meters `meters` 目盛

| Option | What it does | From |
|---|---|---|
| **`ticks`** (default) | Volume, battery and brightness get a ten-tick ruler beside the number; Wi-Fi gets four signal bars. | Sheet |
| `off` | Numbers only. | Scroll |

All six status × meters pairs are drawn on sheet 12.

#### Notifications `notif` 報

![Media and notifications](mockups/typeset/13-media-notifications.webp)

| Option | What it does | From |
|---|---|---|
| `count` | `INBOX 03` with one red dot. | Sheet |
| **`stamps`** (default) | Each notification is a small stamped seal of its app's initial, slightly askew, newest on top. Hover fans them out. | Scroll |

#### Bluetooth `bluetooth` 藍

| Option | What it does | From |
|---|---|---|
| **`device`** (default) | A `BT 藍` cell after the network cell: the connected device's name (`+1` for each more) with its battery as the meter, or `On` / `Off`. | New |
| `marks` | One kanji mark per connected device, by its kind: 耳 headphones, 響 speaker, 鍵 keyboard, 鼠 mouse, 話 phone, 遊 controller, 機 computer, 器 anything else. In cells each mark is a small box its charge fills from the bottom; in glyphs the charge is a rule under the mark; four at most, then `+N`. | New |
| `count` | How many devices are connected, as a two-digit count, and a dot for each (six at most). | New |
| `off` | No Bluetooth cell. The panel is still in the scroll and on Omarchy's hotkey. | New |

In every style a click opens the Bluetooth panel and a middle- or right-click turns Bluetooth on or off; machines without an adapter never show the cell. A device at 15 % or less turns its mark, its dot or the count red (it needs you). The old `on` still reads as `device`. Added after the Typeset mockups were drawn, in the same grammar as the other status cells.

#### Indicators `indicators` and indicator marks `indicatorStyle` 印

Omarchy's six indicators (screen recording, dictation, reminder, stay awake, night light, do not disturb) as small square stamps in the right zone, before the inbox. One that is on is pressed down slightly askew (the stamp press, like a new notification); hovering the stamps straightens them, and hovering one opens its name in small caps to its left, pushing the zone over (the stamps never move). A click does what Omarchy's indicator does: stops a recording or opens the capture menu, opens dictation's settings, lists reminders (right-click adds one), or switches stay awake, night light or do not disturb.

| `indicators` | What it does |
|---|---|
| **`all`** (default) | All six, the ones that are off as faint outlines to click on. |
| `active` | Only the ones that are on. |

| `indicatorStyle` | What it does |
|---|---|
| **`icon`** (default) | Omarchy's own icon in the stamp (the Nerd Font glyph its bar uses), readable without the kanji. Red only for "now": a recording and live dictation are solid red; transcribing shows an hourglass. |
| `kanji` | The kanji: 録 recording, 書 dictation, 鈴 reminder, 醒 stay awake, 夜 night light, 静 do not disturb. One that is on is a small seal like the one at the far left (solid red, an inner rule, paper serif kanji); off, a faint outline like an off icon stamp. |
| `iconname` | `icon`, with the name in small caps beside each one that is on. |
| `kanjiname` | `kanji`, with the name beside each one that is on. |

The name is in the same ink as the icon styles (red only for a recording or live dictation). The old `full` reads as `iconname`. Each indicator can be hidden on the Widgets page. Added after the Typeset mockups were drawn.

### Edge

#### Bottom edge `edge` 軸

![Edge and dividers](mockups/typeset/14-edge-dividers.webp)

| Option | What it does | From |
|---|---|---|
| `hairline` | A single hairline. | Sheet |
| `dayrule` | A 24-hour ruler: hour ticks, longer every six hours, the spent part of the day brighter, a red now-notch. | Sheet |
| `rod` | The scroll's roller with end caps and a centre grip. Hover raises the grip; drag down to unroll. | Scroll |
| **`rodrule`** (default) | The roller carries the day: rod, ticks, spent part and now-notch together. | New |

#### Dividers `rules` 罫

| Option | What it does | From |
|---|---|---|
| **`on`** (default) | Hairline dividers between groups. | Sheet |
| `off` | Groups separated by space alone. | Scroll |

### Frame

![Height, surface, position](mockups/typeset/15-height-surface-position.webp)

#### Height `height` 高

| Option | What it does |
|---|---|
| `32` | Compact. Two-line cells collapse to one line (see §3). |
| `36` | Regular (Sheet's height). |
| **`40`** (default) | Roomy (Scroll's height). |
| `44` | Tall, for large or high-DPI screens. |

#### Surface `surface` 面

| Option | What it does |
|---|---|
| **`solid`** (default) | Opaque paper. |
| `glass` | Paper at 74 % over a background blur. The ink ramp does not change, so contrast holds. |
| `inset` | Floats 8 px off the screen edges with a hairline frame and 3 px corners. |

#### Position `position` 位

| Option | What it does |
|---|---|
| **`top`** (default) | Top edge. |
| `bottom` | Bottom edge. Edge details move to the bar's top side (see §3). |

Position follows Omarchy's own `bar.position` when you have not set it in Hanko.

### Panels

#### Panels open as `panels` 紙/巻

| Option | What it does | From |
|---|---|---|
| `sheets` | Clicking a cell inverts it and a flush sheet drops from it, joined to the bar: a mini settings page with eyebrow, serif title, `//` groups and an action strip. | Sheet |
| **`scroll`** (default) | Every panel lives on one handscroll that unrolls from the bar, between two rollers, with an index plate and an interlude between each two sections. Pan with `H` `L`. | Scroll |

Sheets 20–25 show both on full desktops.

#### Scroll dividers `interlude` 間

What sits between two sections of the scroll. Pick it on the Scroll 巻 page (a gallery that draws each one) or by kanji in the Panels card; from a terminal, `hanko style set interlude kotoba`. Every divider is quieter than the sections, and red appears at most once in a gap. They replace the dithered ink slivers the Scroll design drew; the research and the full set of studies are in `docs/revision1/` on the `docs` branch.

| Option | What it does | Presets |
|---|---|---|
| `ma` 間 | Nothing: the gap's space alone separates the sections. | Quiet |
| `hairline` 罫 | One rule that fades at both ends, with a small ring at its middle. | |
| `folio` 柱 | A ruler with ticks like the day rule, and both section numbers (`01 — 02`) set sideways. | Sheet, Instrument |
| `kotoba` 詞 | The next section's red kanji and its number and name set vertically, between two hairlines (a text column, as handscrolls put text between pictures). | Scroll |
| `tsugime` 継 | A paper join: the next sheet laps over the last, with a soft shadow on the earlier one. | |
| **`seal`** 印 (default) | The paper join, with a seal of the next section's kanji pressed across it, half on each sheet. | Hanko |
| `jiku` 軸 | A slim inner roller with caps, echoing the scroll's own rollers. | |
| `fuda` 札 | A bone index tab with the next section's red kanji and number, on a faint line. | Islet |
| `su` 数 | The next section's number, large in the display face and set sideways, with a red point. | |

Added after the Typeset mockups were drawn.

#### Scroll end leaf `endleaf` 跋

What sits on the bare paper right of 08 Inbox, the twin of the weather leaf on the left: `09 // …`, 400 px wide, shown while Inbox is in the middle (the index plate and the number keys skip it, as they skip the weather). Pick it on the Scroll 巻 page (a gallery that draws each one with a sample reading) or by kanji in the Panels card; from a terminal, `hanko style set endleaf shimai`. `hanko hide endleaf` (or the Widgets page, Centre card) leaves the paper bare. The designs and the research behind them are in `docs/revision2/` on the `docs` branch.

| Option | What it shows, and what it does | Presets |
|---|---|---|
| `okugaki` 奥 | A colophon, the way a handscroll ends: host and model, kernel, Hyprland, packages and the last upgrade, theme, font and Hanko's version, with three seals (your initial, your theme's, 判). | Scroll |
| **`koyomi`** 暦 (default) | The almanac: the month (Monday first) with today sealed and a dot on the day the next solar term starts; the solar term (sekki) and microseason (kō) we are in; the moon's phase and the next new or full moon; the year as a rule. Pure date maths, no network. | Hanko |
| `kiki` 機 | The machine: CPU over the last hour as one ink curve (a sample a minute, kept while this leaf is chosen), CPU, memory, disk and heat as tick meters, and the two busiest processes. | Instrument |
| `shimai` 終 | The session: Lock, Suspend, Log out, Restart and Shut down as seals, each pressed by holding it (700 ms, the seal fills with ink); the same commands as Omarchy's system menu. | Sheet |
| `iro` 色 | Omarchy's themes as paper, ink and seal swatches around the current one; a click runs `omarchy-theme-set`, and the foot opens Omarchy's theme picker. | |
| `dougu` 具 | Omarchy's utilities as tiles: screenshot, record, colour picker, stay awake, night light, silence (do not disturb), emoji, clipboard, lock. The switches show when they are on. | Islet |
| `shuchu` 集 | A focus timer: 25 minutes on a ruler with the red now-notch, today's sessions stamped, pause, +5 min and stop; a five-minute break follows each one. It keeps time with the scroll rolled up (state in `~/.local/state/hanko/focus.json`) and sends a notification when a part ends. | |
| `hikae` 控 | Today's list from `~/.config/hanko/notes.md` (`- [ ]` lines tick on a click and are written back), with the last three entries of Omarchy's clipboard history (a click copies one). | |
| `batsu` 跋 | An afterword: a large 終, "the end of the scroll", the date, and your seal glyph. Nothing to read or do. | Quiet |

Each leaf reads only what it shows and only while the scroll is open (services/Leaf.qml), apart from the machine's hourly curve and the focus timer.

The panels are Time 時, Sound 音, Network 網, Bluetooth 藍, Power 電, Display 明 and Inbox 報 (as sheets), and the scroll adds Spaces 窓 between Display and Inbox: eight sections. Display is the LUM cell's panel (and Omarchy's `omarchy.monitor`, `Super+Ctrl+D`): the chosen monitor's brightness on a ruler, every monitor with its mode and scale, and night light. It was added after the Typeset mockups were drawn, in the same grammar. So was Bluetooth (the BT cell's panel and Omarchy's `omarchy.bluetooth`): what is connected as the title, then connected, known and nearby devices (the adapter scans only while the panel is open); a click disconnects, connects or pairs through `omarchy-bluetooth-device`, and the foot turns it on or off through `omarchy-bluetooth-power`.

**The weather leaf 天.** With `panels: scroll`, Time sits in the middle of the paper when the scroll opens, which left bare paper to its left. A weather leaf (`00 // WEATHER`, not a section: the index plate and the number keys skip it) now fills it and slides away with Time:

- the title is the temperature and the sky (`18°, rain`), the caption the place, how it feels and the wind;
- today's temperature by the hour as one curve, the hours already spent fainter, daylight as a faint wash, rain chances as bars along the foot, the red now-notch where it meets the curve, the day's high and low;
- sunrise, sunset and humidity, and the first hour with a 50 % chance of rain;
- the next three days, each with its kanji (晴 月 曇 霧 雨 雪 雷) and its low to high on the span the four days share.

It uses the same data as Omarchy's own weather panel, so it needs no setting: the place from `~/.local/state/omarchy/settings/weather.json` (or found from your IP address through wttr.in when that has no coordinates), the forecast from Open-Meteo, °C or °F from the `unit` on the `omarchy.weather` entry, else your country, else your locale. It refreshes every 15 minutes (the entry's `refreshMinutes`, 5 at least) and only while the scroll is open. The leaf is 400 px wide and is left out when the screen is too narrow to fit at least 240 px of it beside Time (about 1600 px of scroll). `hanko hide weather` (or the Widgets page, Centre card) takes it off.

---

## 3. How options interact

Most settings are independent. These are the places where one setting changes how another is drawn. None of them forbid a combination; they adapt it.

| When | Then |
|---|---|
| `height: 32` | `cells` status and `cell` title/media collapse from label-over-value to one line (label then value). `stacked` clock puts the date beside the time instead of stacking. Seal shrinks to 22 px. |
| `status: numerals` + `meters: ticks` | A short five-tick ruler follows each quantity inline. |
| `status: glyphs` + `meters: ticks` | Four-tick ruler after the number; network keeps its name, no bars. |
| `clockAt: right` | The clock moves after notifications with a divider (if `rules: on`). The centre zone is left empty on purpose, so `media` stays in the right cluster. |
| `edge: dayrule` or `rodrule` + `clockAt: right` | The now-notch still sits on the ruler at the real hour; it no longer lines up under the clock, and that is fine. |
| `position: bottom` | `dayrule`, `rod` and `rodrule` draw along the bar's **top** side. A `scroll` unrolls **upward** and the index plate moves to the bottom; `sheets` rise instead of drop. |
| `surface: inset` | The edge (rod, rule) runs inside the frame, 10 px from each end, so the end caps don't touch the frame. |
| `surface: glass` | Stamps, the seal and inverted plates stay fully opaque; only the paper goes translucent. |
| `seal: workspace` + `spaces: kanji` | The active kanji appears twice (seal and inverted page). This is intended: the seal is a mark, the page is a control. |
| `seal: none` | The left zone starts at 14 px padding; the first divider is dropped. |
| `title: none` + `media: none` | The bar collapses to identity, clock and status: the Quiet preset. |
| `panels: sheets` + `edge: rod` | The rod no longer unrolls anything; dragging it opens the sheet for whatever cell is under the pointer, and `Super+Space` opens Time. |
| `panels: scroll` + no rod edge | `Super+Space` or a click on any status, clock or stamp unrolls the scroll; hovering the bottom edge shows a thin pull tab. |

---

## 4. Presets

![Six presets](mockups/typeset/03-presets.webp)

A preset sets all twenty settings at once. Change any setting afterwards and the settings page shows `PRESET · HANKO + EDITS`; **Reset to preset** puts it back.

| Setting | Sheet | Scroll | **Hanko** | Quiet | Instrument | Islet |
|---|---|---|---|---|---|---|
| seal | stamp | workspace | workspace | stamp | stamp | workspace |
| spaces | folio | layout | layout | dots | kanji | kanji |
| title | cell | byline | byline | none | cell | byline |
| clock | stacked | inline | stacked | inline | mono | inline |
| clockAt | center | center | center | center | right | center |
| media | cell | underline | underline | none | cell | underline |
| status | cells | glyphs | cells | numerals | cells | glyphs |
| meters | ticks | off | ticks | off | ticks | ticks |
| notif | count | stamps | stamps | count | count | stamps |
| bluetooth | device | marks | device | off | device | marks |
| indicators | all | active | all | active | all | active |
| indicatorStyle | kanji | kanji | icon | icon | iconname | icon |
| edge | dayrule | rod | rodrule | hairline | dayrule | rodrule |
| rules | on | off | on | off | on | off |
| height | 36 | 40 | 40 | 32 | 44 | 36 |
| surface | solid | solid | solid | glass | solid | inset |
| position | top | top | top | top | top | top |
| panels | sheets | scroll | scroll | sheets | sheets | scroll |
| interlude | folio | kotoba | seal | ma | folio | fuda |
| endleaf | shimai | okugaki | koyomi | batsu | kiki | dougu |

- **Sheet**: the Sheet design, exactly. A spec table across the top of the page.
- **Scroll**: the Scroll design, exactly. Calm type and a handscroll underneath.
- **Hanko**: the merge. Scroll's left end and panels, Sheet's cells and meters, and the roller that carries the day.
- **Quiet**: the least on screen. Dots, an inline clock, numerals, a hairline, on glass.
- **Instrument**: the most on screen. Kanji pages, a mono clock on the right, every meter, 44 px.
- **Islet**: a floating inset strip with kanji status and stamps.

![Presets on four themes](mockups/typeset/05-presets-x-themes.webp)

---

## 5. Counting the combinations

| Setting | Options |
|---|---|
| seal | 3 |
| spaces | 4 |
| title | 3 |
| clock | 3 |
| clockAt | 2 |
| media | 3 |
| status | 3 |
| meters | 2 |
| notif | 2 |
| bluetooth | 4 |
| indicators | 2 |
| indicatorStyle | 4 |
| edge | 4 |
| rules | 2 |
| height | 4 |
| surface | 3 |
| position | 2 |
| panels | 2 |
| interlude | 9 |
| endleaf | 9 |

3 × 4 × 3 × 3 × 2 × 3 × 3 × 2 × 2 × 4 × 2 × 4 × 4 × 2 × 4 × 3 × 2 × 2 × 9 × 9 = **7,739,670,528** bars.

That figure is before the seal glyph (any character) and the theme (every Omarchy theme, light or dark). The bar on screen alone, ignoring position, panels, the scroll's dividers and its end leaf, is 23,887,872 combinations.

![Twelve random combinations](mockups/typeset/04-shuffle.webp)

Sheet 04 draws twelve of them at random with a fixed seed. None is a preset. The settings page will have a **Shuffle** button that does the same, for discovering combinations you would not have picked.

---

## 6. The settings page

![Settings, dark](mockups/typeset/01-settings.webp)
![Settings, light](mockups/typeset/02-settings-light.webp)

Hanko's settings open as their own window in the Ryoku Hub grammar: a numbered rail on the left, a page on the right, an action bar at the foot.

**Rail**

| Group | Pages |
|---|---|
| `01 BAR` | Typesetting 組版 · Colour 色 · Widgets 部品 |
| `02 PANELS` | Sheets 紙 · Scroll 巻 (the scroll dividers, as a gallery) |
| `03 FEEL` | Motion 動 · Keys 鍵 |
| `04 SHARE` | Presets 型 |

There is a search field at the top and an **Advanced** switch at the foot (which shows `sealGlyph`, per-monitor overrides and raw JSON). Per-monitor overrides are set there too: pick a monitor, and every setting is listed with the value that monitor gets; a red tick marks one it sets for itself, and picking what the other screens get drops the override.

**Widgets 部品** shows or hides anything the bar can show, each row `shown | hidden`, in cards: *Left* (seal, workspaces, window title), *Centre* (clock, now playing), *Right · readings* (network, Bluetooth, volume, brightness, battery, notifications), *Marks · Hanko's own* (each indicator, the keyboard layout, the microphone, the tray, as your Omarchy layout has them), *Tray apps* (each app in the tray now), *Widgets · from your Omarchy bar* (every hosted widget, marked Omarchy or third-party) and *Edge*. A part its own setting leaves out (`seal: none`, `title: none`, `media: none`, `bluetooth: off`) reads hidden, and showing it sets it back to the preset's way. Show all puts every hidden part back. Hiding is for this bar only: the widget stays in Omarchy's layout. From a terminal: `hanko hide <part>`, `hanko show <part>`, or `hanko style set show:<part> hidden`.

**Motion 動** holds one switch outside the twenty settings, `motion`: `paper` (default) moves like Scroll's motion sheet, `still` cuts every transition to its end frame. Omarchy's own animation switch, off, makes Hanko still too. The page lists every timing.

**Typesetting 組版**, the page drawn on sheets 01 and 02, holds every setting in this document:

1. **Live preview**: your bar, on your theme, over a sample plate, updated as you click.
2. **Preset gallery**: six cards; the current one inverted, with `*` when edited.
3. **Six cards of segmented controls**, grouped the way the bar reads:
   - *Left · where you are*: Seal, Workspaces, Window title
   - *Centre · when*: Clock, Clock position, Now playing
   - *Right · how things are*: Status, Meters, Notifications, Bluetooth, Indicators, Indicator marks
   - *Edge*: Bottom edge, Dividers
   - *Frame*: Height, Surface, Position
   - *Panels*: Panels open as, Seal glyph
4. **Action bar**: Reset to preset · Revert · Save. Every change prints live on your bar at once (as the sheet says); only Save writes `style.json`, and Revert, or closing the window unsaved, puts the saved style back.

The same settings can be changed from a terminal:

```sh
hanko style get                 # print the current style
hanko style set clock mono      # change one setting
hanko style preset Instrument   # apply a preset
hanko style shuffle             # random combination
```

---

## 7. Config file

Hanko stores its style alongside the rest of Omarchy's bar settings, so `omarchy bar use hanko.bar` keeps working and a theme switch does not touch it.

```jsonc
// ~/.config/hanko/style.json (outside the plugin folder, so updates never touch it)
{
  "preset": "Hanko",          // starting point
  "edits": {                  // only what differs from the preset
    "clock": "inline",
    "status": "glyphs"
  },
  "sealGlyph": "印",
  "motion": "paper",          // or "still": every move cuts to its end frame
  "hidden": ["tray", "hosted:omarchy.weather"],  // parts taken off the bar (Widgets 部品)
  "monitors": {               // optional per-monitor overrides
    "DP-2": { "height": 32, "spaces": "dots" }
  }
}
```

Resolution order: preset → `edits` → `monitors[name]`. Unknown keys and invalid values are ignored with a warning, so a config from a newer Hanko never breaks an older one.

In QML, the bar reads one resolved object:

```qml
property var style: Typeset.current   // 20 settings
Seal   { mode: style.seal }
Spaces { mode: style.spaces }
Clock  { mode: style.clock; anchor: style.clockAt }
Status { mode: style.status; meters: style.meters }
Edge   { mode: style.edge }
Panels { mode: style.panels }
```

---

## 8. Sheets

All images are in `docs/mockups/typeset/`, rendered from the HTML in `docs/mockups/typeset/source/` and saved as lossless WebP (`Image.open('out.png').save('out.webp', lossless=True, method=6)` with Pillow).

| File | Shows |
|---|---|
| `01-settings.webp` | The Typesetting settings page, Hanko theme |
| `02-settings-light.webp` | The same page on Flexoki Light |
| `03-presets.webp` | The six presets |
| `04-shuffle.webp` | Twelve random combinations |
| `05-presets-x-themes.webp` | Sheet, Hanko and Islet on Hanko, Tokyo Night, Gruvbox and Rosé Pine Dawn |
| `10-seal-workspaces.webp` | Seal × 3, workspaces × 4 |
| `11-title-clock.webp` | Title × 3, clock × 3, clock position × 2 |
| `12-status-meters.webp` | Status × meters, all 6 pairs |
| `13-media-notifications.webp` | Now playing × 3, notifications × 2 |
| `14-edge-dividers.webp` | Edge × 4, dividers × 2 |
| `15-height-surface-position.webp` | Height × 4, surface × 3, position × 2 |
| `16-seal-workspaces-flexoki-light.webp` | Sheet 10 on Flexoki Light |
| `17-status-meters-rose-pine.webp` | Sheet 12 on Rosé Pine Dawn |
| `20-desk-hanko-scroll.webp` | Hanko preset, scroll open on Sound |
| `21-desk-sheet-sound.webp` | Sheet preset, Sound sheet open, with windows |
| `22-desk-instrument-time.webp` | Instrument preset, Time sheet open from the right-hand clock |
| `23-desk-quiet-bottom.webp` | Quiet preset at the bottom of the screen |
| `24-desk-islet-kanagawa.webp` | Islet preset on Kanagawa, scroll open on Spaces |
| `25-desk-scroll-flexoki-light.webp` | Scroll preset on Flexoki Light, scroll open on Time |

To render any combination yourself (Node with Playwright):

```sh
cd docs/mockups/typeset/source
node shootq.mjs "file://$PWD/cat.html?page=status&theme=gruvbox" out.png
node shootq.mjs "file://$PWD/desk.html?preset=Quiet&o={\"spaces\":\"kanji\"}&panel=sheet-time" out.png
```

`cat.html` takes `page` = `identity | time | status | signals | edge | frame | presets | shuffle | themes` and `theme`. `desk.html` takes `preset`, `theme`, `o` (JSON overrides), `panel` (`sheet-sound`, `sheet-time`, `scroll-0`…`scroll-5`) and `wins=1`.

The wallpaper plates are procedural and made for these mockups; they are not part of the plugin.
