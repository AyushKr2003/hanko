# Hanko handoff: everything a fresh session needs

This file is the single source a new Claude session (or a person) reads to pick up Hanko exactly where it was left. It covers the brief, every branch, the design, the Omarchy plugin contract, the code, the dev environment, the conventions, what each finished phase built, and detailed instructions for every remaining phase.

Last updated: 2026-10-06, after Phase 5 (on `claude/hanko-plugin-zzm827`, one commit ahead of `dev`).

**Read order for a fresh session:** this file, then [ROADMAP.md](ROADMAP.md), then [COMPONENTS.md](COMPONENTS.md) (the full spec of every option), then the code. Keep this file current: update §9 (status) and §12 (known issues) at the end of every phase, in the same commit.

---

## Contents

1. [The brief](#1-the-brief)
2. [How the user likes to work](#2-how-the-user-likes-to-work)
3. [Repository and branches](#3-repository-and-branches)
4. [Hard rules (commits, git, privacy)](#4-hard-rules-commits-git-privacy)
5. [The design in one page](#5-the-design-in-one-page)
6. [How a bar plugin plugs into Omarchy](#6-how-a-bar-plugin-plugs-into-omarchy)
7. [Code map](#7-code-map)
8. [Dev environment from scratch](#8-dev-environment-from-scratch)
9. [Phase status and what each phase built](#9-phase-status-and-what-each-phase-built)
10. [Instructions for the remaining phases (5–10)](#10-instructions-for-the-remaining-phases-510)
11. [The per-phase routine](#11-the-per-phase-routine)
12. [Known issues and things to verify on a real machine](#12-known-issues-and-things-to-verify-on-a-real-machine)
13. [QML pitfalls already hit](#13-qml-pitfalls-already-hit)
14. [Reference material](#14-reference-material)

---

## 1. The brief

- **What:** Hanko (判子, the personal seal stamped on a document) is a premium **bar plugin for Omarchy** (the Arch + Hyprland setup by DHH, `github.com/omacom/omarchy`). Plugin id `hanko.bar`, kind `bar`: it replaces Omarchy's whole bar.
- **Style source:** the **Settings app of Ryoku** (`github.com/Ryoku-dev/ryoku`, branch `unstable-dev`) and the visual design of **ryoku.dev**. Not Ryoku's bars (QS Bar, Sumi, Kairos, Shima).
- **Must be original.** Take Ryoku's *grammar* (one paper colour, warm ink in four contrast tiers, hairlines not shadows, emphasis by inversion with a `//` lead, a serif only for titles, tracked mono labels, a kanji gloss beside Latin labels). Do not copy its palette, its fonts-as-brand, its ornaments (barcodes, registration backdrops) or any of its bars. No generic "AI look": no floating pills, glow, coloured icon soup.
- **Premium and interactive:** strong interaction (click, scroll, hover all do something meaningful), print-like motion.
- **Owner:** Ayush (GitHub `AyushKr2003`).

## 2. How the user likes to work

These come from the user's own messages and reactions:

- **Design first, with many mockup images.** Each design direction (Sheet, then Scroll, then Typeset) got a full set of rendered mockups; all three now live on the `docs` branch. The user picks a direction, then asks for the next.
- **Build step by step, not all at once.** Verbatim: *"work on this properly with roadmap and all in step by step … no need to do all at once and commit after a part is done."* One phase (or a clear part of a phase) per commit, pushed right away.
- **Work happens on `dev`.** Verbatim: *"merge this branch in main and from there create a new branch name dev and start working in that."* Do not merge `dev` into `main` again unless the user asks.
- **Read the real docs.** The user pointed at the Omarchy manual and its third-party plugin docs. Base every integration decision on the Omarchy source, not on guesses.
- **Integration references are not design references.** Shibumi-Shell, `AyushKr2003/omacale` and ruixen-shell show how plugins talk to Omarchy; never borrow their look.
- **"good" / "go on" means keep going** to the next phase without asking.
- **Show renders.** Every phase reply carries a render of what was built (the harness PNG), since there is no Omarchy machine in the cloud session.
- **Before writing a lot of new code after a long stretch, the user may ask for a write-up like this one.** Keep it updated.

## 3. Repository and branches

Repo: **`AyushKr2003/hanko`** (private). In cloud sessions it was checked out at `/tmp/claude-0/hanko`.

| Branch | What it holds |
|---|---|
| `main` | The released state. Updated only when the user asks (by merging `dev`). |
| **`dev`** | **All current work.** The active branch. |
| `docs` | Every design direction in one place: Sheet, Scroll and Typeset, each with its mockups, HTML source, README and changelog. |

The design directions, in the order they were drawn:

1. **Sheet**: the bar as a printed running head. Seal, label-over-value cells, tick meters, the 24-hour day rule along the foot, folio workspaces, flush sheets that drop from a cell. 5 mockups. Lives on as the Sheet preset.
2. **Scroll**: a calm one-line bar that unrolls into a horizontal handscroll (emakimono) holding every panel, with rollers, an index plate and dithered interludes. Workspace-numeral seal, real-layout workspace glyphs, serif byline, kanji glyph status, notification stamps, the rod. 6 mockups. Lives on as the Scroll preset.
3. **Typeset** (chosen): the two merged; every part of the bar is a setting, with a Typesetting 組版 settings page. 19 mockups in `docs/mockups/typeset/`, spec in `docs/COMPONENTS.md`, overview in `docs/DESIGN.md`. This is the spec the plugin implements.

Older commit messages call these designs beta1, alpha1 and gama1.

A future design direction (if the user asks for one) gets a plain descriptive name, a full set of mockups under `docs/mockups/<name>/`, a design doc, and lands on the `docs` branch.

## 4. Hard rules (commits, git, privacy)

- **Commit message trailer** (every commit, exactly these two lines at the end):
  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01ANerSjChq6Gi7H1fd3vhH3
  ```
  A new session gets its own attribution lines from its system prompt; use those if they differ.
- **No model names or ids** in commits, PR text, code comments or any repo file.
- **Commit messages:** `Phase N: <short title>` then a blank line and a plain-language paragraph or two on what the phase does for the user.
- **Push with** `git push -u origin dev`. The git proxy in cloud sessions **rejects tag pushes**; use branches, never tags.
- **Only this repo.** Do not use GitHub's `create_repository` or any `search_*` tool. Reference repos are cloned read-only into a scratch folder (§8).
- **The repo is private.** Never publish its content anywhere outside the project.
- **Project chat (Claude projects):** replies go through the thread's `reply` tool. A thread can hold at most 24 attached outputs; the Hanko thread is at that limit, so link files by path (`/mnt/project-files/...`) in the text instead of attaching them. Renders are copied to `/mnt/project-files/ryoku-shell/typeset/phaseN-render.png`.

## 5. The design in one page

Full spec: [COMPONENTS.md](COMPONENTS.md). This is the summary a builder needs in their head.

### The six rules every option keeps

1. **One paper, four inks, one red.** All colour comes from the Omarchy theme. Paper = `background`; ink = `foreground` stepped toward the paper to contrasts of **12, 9, 6.2 and 4.6 : 1** (`ink`, `inkDim`, `inkMuted`, `inkFaint`); seal = the theme's `red`. No option may introduce a colour.
2. **Red means "you" or "now".** The seal, the now-notch, an urgent workspace, a muted master, an unread dot, a low battery, being offline. Nothing else is red.
3. **Emphasis is inversion.** The selected thing becomes a solid ink ("bone") plate, often with a `//` lead.
4. **Three typefaces with fixed jobs.** Fraunces (serif) for time, titles, bylines; Space Grotesk for values and language; the user's Omarchy monospace for labels; Noto Sans/Serif CJK JP for kanji.
5. **Hairlines, not shadows.** Dividers, frames and edges are 1 px ink lines.
6. **One baseline.** Every zone sits on the same text baseline at every height.

### The fifteen settings (`core/Style.js` `OPTIONS`; **bold** = Hanko default)

| Zone | Key | Options |
|---|---|---|
| Left | `seal` | `stamp`, **`workspace`**, `none` (plus free-text `sealGlyph`, default 印) |
| Left | `spaces` | `folio`, **`layout`**, `kanji`, `dots` |
| Left | `title` | `cell`, **`byline`**, `none` |
| Centre | `clock` | **`stacked`**, `inline`, `mono` |
| Centre | `clockAt` | **`center`**, `right` |
| Centre | `media` | `cell`, **`underline`**, `none` |
| Right | `status` | **`cells`**, `glyphs`, `numerals` |
| Right | `meters` | **`ticks`**, `off` |
| Right | `notif` | `count`, **`stamps`** |
| Edge | `edge` | `hairline`, `dayrule`, `rod`, **`rodrule`** |
| Edge | `rules` | **`on`**, `off` |
| Frame | `height` | `32`, `36`, **`40`**, `44` |
| Frame | `surface` | **`solid`**, `glass`, `inset` |
| Frame | `position` | **`top`**, `bottom` |
| Panels | `panels` | `sheets`, **`scroll`** |

### Presets

| Setting | Sheet | Scroll | **Hanko** (default) | Quiet | Instrument | Islet |
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
| edge | dayrule | rod | rodrule | hairline | dayrule | rodrule |
| rules | on | off | on | off | on | off |
| height | 36 | 40 | 40 | 32 | 44 | 36 |
| surface | solid | solid | solid | glass | solid | inset |
| position | top | top | top | top | top | top |
| panels | sheets | scroll | scroll | sheets | sheets | scroll |

### Where options interact (COMPONENTS.md §3)

- `height: 32`: two-line cells (title, media, status, inbox count) collapse to one line, label then value; the stacked clock puts the date beside the time; the seal shrinks to 22 px. *(Done.)*
- `status: numerals` + `ticks`: a five-tick ruler after each quantity. `glyphs` + `ticks`: a four-tick ruler; network keeps its name, no bars. *(Done.)*
- `clockAt: right`: clock goes after notifications with a divider; the centre is left empty on purpose. *(Done.)*
- `edge: dayrule|rodrule` + `clockAt: right`: the now-notch stays at the real hour, no longer under the clock. *(Done: the notch always sits at the hour.)*
- `position: bottom`: `dayrule`, `rod`, `rodrule` draw along the bar's **top** side; the scroll unrolls **upward** and its index plate moves to the bottom; sheets rise instead of drop. *(Phases 5–7.)*
- `surface: inset`: the edge runs inside the frame, 10 px from each end (rod 14 px, as the kit draws it); a `hairline` edge is dropped since the frame is one. `glass`: stamps, seal and inverted plates stay opaque; only the paper is translucent. *(Done.)*
- `seal: workspace` + `spaces: kanji`: the active kanji shows twice, intentionally.
- `seal: none`: left zone starts at 14 px padding, first divider dropped.
- `title: none` + `media: none`: identity, clock and status only (Quiet).
- `panels: sheets` + `edge: rod`: dragging the rod opens the sheet for the cell under the pointer; `Super+Space` opens Time. `panels: scroll` without a rod edge: `Super+Space` or a click on any status, clock or stamp unrolls the scroll; hovering the bottom edge shows a thin pull tab. *(Phases 6–7.)*

### Config file

`~/.config/hanko/style.json` (XDG_CONFIG_HOME aware), outside the plugin folder so updates never touch it:

```jsonc
{ "preset": "Hanko", "edits": { "clock": "inline" }, "sealGlyph": "印",
  "monitors": { "DP-2": { "height": 32, "spaces": "dots" } } }
```

Resolution: preset → `edits` → `monitors[name]`. Invalid keys/values are dropped with a warning (`Typeset.warnings`).

### Mockups

`docs/mockups/typeset/*.webp` (19 sheets; index in COMPONENTS.md §8) are the visual target for every phase. Compare each phase's render against the matching sheet. The HTML kit that drew them is `docs/mockups/typeset/source/` (`cat.html`, `desk.html`, `studio.html`, `typeset.css`, `typeset.js`, `shootq.mjs`), rendered with Node + Playwright:

```sh
cd docs/mockups/typeset/source
node shootq.mjs "file://$PWD/cat.html?page=status&theme=gruvbox" out.png
node shootq.mjs "file://$PWD/desk.html?preset=Quiet&o={\"spaces\":\"kanji\"}&panel=sheet-time" out.png
```

`cat.html` pages: `identity | time | status | signals | edge | frame | presets | shuffle | themes`. `desk.html` takes `preset`, `theme`, `o` (JSON overrides), `panel` (`sheet-sound`, `sheet-time`, `scroll-0`…`scroll-5`) and `wins=1`. When a phase needs a detail the sheets don't show (sheet contents, scroll sections), read the HTML/CSS in this kit: it is the exact design.

Sheet and Scroll mockups: `docs/mockups/sheet/`, `docs/mockups/scroll/`.

## 6. How a bar plugin plugs into Omarchy

Facts from the Omarchy source (`manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/shell.qml`, `shell/services/Plugin*.qml`, `shell/plugins/`). Re-check them against the current Omarchy source before relying on them; Omarchy moves fast.

### Loading

- Omarchy's desktop is **one long-running Quickshell process**, `omarchy-shell`. A bar plugin runs inside it. **Never start a second Quickshell.**
- Plugin = folder with `manifest.json` at its root, in `~/.config/omarchy/plugins/hanko.bar/`. Our manifest: `schemaVersion: 1`, `id: "hanko.bar"`, `kinds: ["bar"]`, `entryPoints.bar: "Bar.qml"`, version `0.1.0`, author `AyushKr2003`.
- `omarchy plugin add <git-url>` installs; `omarchy bar use hanko.bar` selects it (sets `bar.id` in `shell.json`); `omarchy plugin validate .` checks the manifest like the shell does. Saving a file in the plugin folder hot-reloads it. If the bar fails to load, the shell falls back to `omarchy.bar`.

### What the host injects into `Bar.qml`

`omarchyPath`, `shell`, `manifest`, `barWidgetRegistry`, `pluginRegistry`, `barConfig`. A third-party bar gets **facades**:

- `shell` is a `PluginShellApi` (`shell/services/PluginShellApi.qml`): `firstPartyServiceFor(id)`, `pluginShellForBarEntry(owner, module)`, `summon(id, json)`, `hide(id)`, `toggle(id, json)`, `isPluginOpen(id)`, `updateEntryInline(id, settings)`, `mutateShellConfig(fn)`.
- `firstPartyServiceFor(id)` returns a narrow proxy (`shell/services/PluginFirstPartyServiceApi.qml`) **only** for `omarchy.idle`, `omarchy.media`, `omarchy.nightlight`, `omarchy.notifications`. The proxy has: `stayAwake`, `enabled`, `doNotDisturb`, `activePlayer`, `sourcePlayers`, `setIdleEnabled(v)`, `setNightlight(v)`, `setDoNotDisturb(v)`, `runAction(action, showFeedback, playerKey)` (`playPause|next|previous`), `playerKey(p)`, `selectPlayer(key)`. **There is no proxy for audio, network, battery or the notification list.** The notifications proxy gives do-not-disturb only.
- `barConfig` is a detached copy of `shell.json`'s `bar:` subtree (`position`, `layout.left|center|right` arrays of `{id, ...}`, `transparent`, …).

### What the host reads back from the bar

Properties `barHidden`, `barSize`, `position`, `fontFamily`; functions if present:

- `summonBarWidget(id)`, `hideBarWidget(id)`, `isBarWidgetOpen(id)`: **the host routes `shell toggle <id>` for any plugin whose kinds include `bar-widget` (and not panel/overlay/menu) to these.** Omarchy's `omarchy.audio`, `omarchy.network`, `omarchy.power` and `omarchy.clock` panels are all kind `["bar-widget"]`. So when Hanko is the bar, `omarchy-shell shell toggle omarchy.audio` (and the Omarchy hotkeys that do the same) **only work if Hanko implements `summonBarWidget`**. See §12, issue 1.
- `panelWidgetIdAt(section, index)`: used by `omarchy-shell shell togglePanelAt right N` (Omarchy's hotkeys in `default/hypr/bindings/utilities.lua`).
- `toggleTransparency()`: called by IPC `shell toggleBarTransparency`.
- `debugBarGeometry()`.
- Reference implementation of all of these in a third-party bar: `omacale/Bar.qml` (around line 263) and `omacale/modules/bar/BarWidgetSlot.qml` / `PluginBarFacade.qml`.

### Hiding

`omarchy toggle bar` writes `~/.local/state/omarchy/toggles/bar-off`, then calls IPC `omarchy.bar syncHidden`. Hanko registers that IPC target and also watches the toggles directory. *(Done in Phase 1.)*

### Data sources Hanko uses (and why)

| Data | Source | Action |
|---|---|---|
| Workspaces, windows, monitors | `Quickshell.Hyprland` (`Hyprland.workspaces/toplevels/monitors`, `toplevel.lastIpcObject` = `at`, `size`, `floating`, `focusHistoryID`, `workspace`; monitor `lastIpcObject` = `x,y,width,height,scale,transform,reserved[l,t,r,b]`), refreshed with `Hyprland.refreshToplevels()` / `refreshMonitors()` on `rawEvent` | `Hyprland.dispatch('hl.dsp.focus({ workspace = "3" })')` (**Lua dispatch syntax**; values escaped with `luaStr`); `"r+1"`/`"r-1"` to step |
| Media | `omarchy.media` proxy `activePlayer`, else `Quickshell.Services.Mpris` | proxy `runAction`, else MPRIS directly |
| Volume | `Quickshell.Services.Pipewire` `defaultAudioSink`, resolved through any DSP sink to the physical one with `omarchy-audio-output-sink` (same as Omarchy's audio panel); `PwObjectTracker` binds it | `omarchy-audio-output-volume +5 / -5 / mute-toggle` (shows Omarchy's OSD) |
| Battery | `Quickshell.Services.UPower` `displayDevice` (`isPresent`, `isLaptopBattery`, `percentage` 0..1), `UPower.onBattery` | — |
| Network | `omarchy-network-status` (prints `kind\tname\tsignal\tfreq`, kind = `wifi|ethernet|disconnected`), polled every 3 s | — |
| Brightness | `brightnessctl -m -c backlight` only when `/sys/class/backlight/*` exists (laptops) | `omarchy-brightness-display +5% / 5%-` |
| Notifications | Omarchy's notification service writes each live toast to `~/.local/state/omarchy/notifications/*.json` and keeps the last 10 in `…/notifications/history/*.json`, one compact JSON object per file (`{id, originalId, app, appIcon, summary, body, image, glyph, execArgv, urgency (2 = critical), expireTimeout, timestamp}`). Hanko reads both with `awk 1`. DND from the proxy, else `~/.local/state/omarchy/notifications.json` `{dnd}` | `omarchy-shell notifications showHistory` (replays recent as toasts), `toggleDnd`, `clear`, `isDnd`; proxy `setDoNotDisturb` |
| Omarchy menu | — | `omarchy-shell shell toggle omarchy.menu '{"menu":"root"}'` |
| Terminal | — | `xdg-terminal-exec` |
| 12/24 h | `barConfig.layout.*[]` entry with `id: "omarchy.clock"` and its `format` | — |
| Theme | `qs.Commons` `Color.foreground`, `Color.background`, `Color.urgent` (= theme red); live on theme switch. `Style.font.family` (mono), `Style.font.body` (base size; Hanko scales by `body/12`) | — |

Other Omarchy panels that exist (`shell/plugins/panels/`): audio, bluetooth, clock, disk-speedtest, dropbox, elsewhen, monitor, network, power, speedtest, tailscale, weather, wifiqr.

### Fonts

Omarchy installs `noto-fonts-cjk`, so kanji come from the system ("Noto Sans CJK JP", "Noto Serif CJK JP"). Hanko bundles **Fraunces** (+ Italic) and **Space Grotesk** under `assets/fonts/` (SIL OFL, licence files alongside) and loads them with `FontLoader`. The mono face is `Style.font.family` (what `omarchy font set` controls).

## 7. Code map

Everything is plain QML/JS, no build step.

```
manifest.json            plugin manifest (hanko.bar, kind bar)
Bar.qml                  entry point: injected props, host contract, per-screen windows,
                         hiding, proxy bindings, `hanko` IPC
bar/
  BarWindow.qml          one layer-shell PanelWindow per screen (namespace "hanko-bar",
                         WlrLayer.Top, exclusive, parks off-screen when hidden);
                         feeds BarSurface with live data and routes its signals to services
  BarSurface.qml         PURE QtQuick: everything drawn inside the bar, from a resolved
                         style + plain data. The test harness renders this directly.
                         Left Row (Seal, Divider, Workspaces, Divider, WindowTitle),
                         centre Clock, right Row (NowPlaying, Divider, StatusRow, Divider,
                         Inbox, Divider, right Clock), hairline edge.
                         Inline component Divider { ruled }.
  Seal.qml               stamp | workspace (kanji numeral) | none
  Workspaces.qml         folio | layout | kanji | dots, urgent dot, click + wheel
  WindowTitle.qml        cell | byline | none (+ compact one-line cell)
  Clock.qml              stacked | inline | mono, timeFormat, colon inked
  NowPlaying.qml         underline (progress underline) | cell | none
  StatusRow.qml          cells | glyphs | numerals × ticks | off; Wi-Fi bars; red rule
  Inbox.qml              count | stamps (tilted seals, fan on hover), DND state
  Edge.qml               hairline | dayrule | rod | rodrule, mirrored at the bottom,
                         inset-aware; rod grip lifts on hover, drag emits pulled()
core/
  Ink.qml   (singleton)  paper, ink, inkDim, inkMuted, inkFaint, seal, bone, boneInk,
                         line, lineSoft, lineStrong, light, alpha(), paperAt()
  Type.qml  (singleton)  FontLoaders; display (Fraunces), text (Space Grotesk), mono,
                         jp, jpSerif; scale; px()
  Typeset.qml (singleton) style.json FileView + watch; doc, warnings, current,
                         ownsPosition; styleFor(monitor), set, applyPreset, reset,
                         setSealGlyph, shuffle, serialized; debounced save (200 ms)
  Style.js               OPTIONS, KEYS, PRESETS, PRESET_NAMES, DEFAULT_PRESET, coerce,
                         normalize, resolve(doc, monitor), withSetting, withPreset,
                         shuffled(doc, rng), combinations()
  InkMath.js             hexToRgb, mix, luminance, contrast, tier, isLight, ramp (TIERS)
  Title.js               appName (NAMES map, reverse-DNS), describe(cls, title) →
                         {app, head, dir, leaf}, findPath, tildify
  Spaces.js              numeral (壱 弐 参…), folio, layoutOf(windows, area),
                         usableArea(monitor), list(workspaces, activeId, min=5)
  Edge.js                dayFraction, hourTicks, at (pixel snap), span (rod/inset
                         padding), pulled(dy, atBottom), PULL_THRESHOLD 24
  Status.js              ticks, bars, network, volume, battery (LOW_BATTERY 15),
                         brightness, stampGlyph (+ STAMP_KANJI), tilt, notifications,
                         count2
  qmldir                 singletons Ink, Type, Typeset
services/
  Hypr.qml  (singleton)  workspaces/windows per monitor, spacesFor(screen), activeWindow,
                         focusWorkspace, stepWorkspace, openMenu, openTerminal
  Media.qml (singleton)  proxy | MPRIS, `now` = {title, artist, progress, playing}, act()
  Status.qml (singleton) volume, battery, network, brightness, notifications,
                         doNotDisturb; act(name, how) for click/middle/right/up/down
  qmldir                 singletons Hypr, Media, Status
scripts/hanko            CLI: install | dev | uninstall | style get|doc|set|preset|reset|
                         shuffle | doctor (style commands go over IPC `omarchy-shell hanko …`;
                         uninstall restores the bar saved in ~/.local/state/hanko/previous-bar)
assets/fonts/            Fraunces.ttf, Fraunces-Italic.ttf, SpaceGrotesk.ttf + OFL texts
tests/
  run                    unit tests → manifest check → qmllint → renders (--quick skips renders)
  unit.mjs               Node tests for core/*.js (27 tests)
  harness/render.py      PySide6 offscreen renderer (QT_SCALE_FACTOR=2)
  harness/scenes/Strips.qml  a sheet of labelled BarSurface strips from a params JSON
  harness/params/*.json  one per phase (phase1, phase2, phase2-light, phase3, phase4, phase5, phase5-light); a strip may set `now` (its own time) and `backdrop: true` (stripes behind the bar, for glass)
  harness/stubs/         fake Quickshell, Quickshell.Io/Hyprland/Wayland/Services.*,
                         qs.Commons, just enough to lint and render
docs/                    ROADMAP, COMPONENTS (spec), DESIGN, HANDOFF (this), history/,
                         mockups/{sheet,scroll,typeset}
```

**IPC target `hanko`** (Bar.qml): `version`, `styleGet`, `styleDoc`, `styleSet(key, value)`, `stylePreset(name)`, `styleReset`, `styleShuffle`, `warnings`. All typed, all return strings.

**Data flow:** services (live Quickshell data) → `BarWindow` (per screen, picks `Typeset.styleFor(screen.name)`) → `BarSurface` props (plain JS objects) → components. Components never import services. This is what lets the harness render any state, and it is the pattern to keep for every new part.

**Params JSON shape for the harness** (`tests/harness/params/*.json`): `{ title, width, theme: {foreground, background, red}, now, spaces, window, media, volume, network, battery, brightness, notifications, dnd, strips: [ { label, doc: {preset?, edits}, …any per-strip override of the sheet-level values… } ] }`.

## 8. Dev environment from scratch

There is **no Omarchy machine** in the cloud session. Everything is verified with unit tests, `qmllint`, and offscreen renders compared by eye against the Typeset mockups.

```sh
# 1. The repo (cloud sessions used /tmp/claude-0/hanko)
git clone -b dev https://github.com/AyushKr2003/hanko.git && cd hanko

# 2. Read-only references, in a scratch folder (cloud used /tmp/claude-0/src)
mkdir -p ../src && cd ../src
git clone -q --depth 1 -b unstable-dev https://github.com/Ryoku-dev/ryoku.git
for r in omacom/omarchy AyushKr2003/omacale HANCORE-linux/Shibumi-Shell gitcoder89431/ruixen-shell; do
  git clone -q --depth 1 https://github.com/$r.git
done
cd ../hanko

# 3. Qt for lint and renders
apt-get install -y libegl1 libgl1 libxkbcommon0 libfontconfig1 libdbus-1-3   # (apt-get update first if it fails)
python3 -m pip install PySide6-Essentials

# 4. Fonts for the harness (Noto JP + a mono face); Fraunces/Space Grotesk come from assets/
mkdir -p ../hfonts && cd ../hfonts
curl -sSfL -o NotoSerifJP.ttf   "https://raw.githubusercontent.com/google/fonts/main/ofl/notoserifjp/NotoSerifJP%5Bwght%5D.ttf"
curl -sSfL -o NotoSansJP.ttf    "https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf"
curl -sSfL -o JetBrainsMono.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
cd ../hanko
export HANKO_HARNESS_FONTS=$PWD/../hfonts

# 5. Run everything
tests/run            # unit, manifest, qmllint, renders → tests/out/*.png
tests/run --quick    # unit + lint only
OMARCHY_SRC=../src/omarchy tests/run   # use Omarchy's real manifest validator
```

**Expected lint output:** only these stub-typing warnings, which are fine: `core/Type.qml` `Member "family"/"body" not found on type "QObject"`, and `Member "values" not found` in `services/Hypr.qml`, `Media.qml`, `Status.qml`. Anything else is new and must be fixed. `bar/BarWindow.qml` warnings are filtered (the stubs don't model layer-shell attached properties).

**Lint does not catch everything.** A render failing to load is the real check (it caught the `gc` id clash). Always run the full `tests/run`, then open `tests/out/phaseN.png` and compare with the Typeset mockup.

**On a real Omarchy machine** (the user's): `scripts/hanko dev` symlinks the checkout and selects it (edits hot-reload), `scripts/hanko style preset Sheet` switches look, `scripts/hanko uninstall` restores the previous bar, `scripts/hanko doctor` checks the install. Logs: `journalctl --user -f` or the omarchy-shell log for QML errors.

## 9. Phase status and what each phase built

Status lives in [ROADMAP.md](ROADMAP.md) too (✅ / 🔨 / ⬜); keep both in sync.

### Phase 0 · Roadmap and scaffolding ✅ (`5bb25e3`, roadmap `4abd0cb`)
- `docs/ROADMAP.md`, Node tests for style resolution and the ink ramp, `qmllint` with stubs, the PySide6 offscreen render harness.

### Phase 1 · A bar that loads ✅ (`101a6b6`)
- `manifest.json`, `Bar.qml`, `core/` singletons (Ink, Type, Typeset), bundled fonts.
- One `PanelWindow` per screen via `Variants` over `Quickshell.screens`; reserves its height (`ExclusionMode.Auto`), parks at a negative margin when hidden (`ExclusionMode.Ignore`).
- Host contract: `barHidden`, `barSize` (= `Type.px(height)`, 0 when hidden), `position` (Hanko's own when the style sets it, else `barConfig.position`, top/bottom only), `fontFamily` (= mono).
- Seal (`stamp`) and stacked clock on paper with a hairline edge.
- `scripts/hanko` CLI and the `hanko` IPC target.

### Phase 2 · Left zone ✅ (`49e1d5b`)
- `services/Hypr.qml`; `Seal` all three modes (click = menu, right-click = terminal, wheel = step workspace); `Workspaces` all four modes from real Hyprland data (layout mode draws each workspace's real tiling scaled into a 24×15 glyph, focused window filled; urgent red dot); `WindowTitle` cell/byline/none with `Title.js` app-name cleanup and receding path, `~` for home.
- Renders: `phase2.json`, `phase2-light.json` (Flexoki-light-like theme).

### Phase 3 · Centre ✅ (`528154b`)
- `Clock` stacked/inline/mono, at centre or right; follows Omarchy's 12/24-hour clock format.
- `services/Media.qml` + `NowPlaying` underline/cell/none; paused media dims a tier; click = play/pause, middle = next, wheel = previous/next; position ticks every second while playing.

### Phase 4 · Right zone ✅ (`bb1cc08`)
- `core/Status.js`, `services/Status.qml`, `bar/StatusRow.qml`, `bar/Inbox.qml`.
- Status cells/glyphs/numerals × ticks/off, Wi-Fi bars, brightness on laptops, charging shows 充 instead of 電, the red rule (muted, battery ≤ 15 % and draining, offline).
- Notifications count (`INBOX 03` + red dot; `QUIET 静` + hollow ring under DND) and stamps (up to 3, tilt −6…6° from a hash, newest on top, fan out on hover, urgent ones solid; grey under DND). Click = `showHistory`, right/middle = toggle DND.
- Status clicks call `omarchy-shell shell toggle omarchy.audio|omarchy.network|omarchy.power` as a stand-in until Phase 6; **these don't work yet under Hanko** (§12, issue 1).

### Phase 5 · Edge and frame ✅
- `core/Edge.js` (+5 unit tests) and `bar/Edge.qml`, replacing the plain hairline. All four edges from the kit's CSS (`scroll.css` `.rod`, `sheet-parts.css` `.dayrule`, `typeset.css` `.rodrule`): day rule = base `line`, spent part `lineStrong`, ticks 3 px (6/12/18 h 5 px, `lineStrong`), red now-notch 2×7 px with a 3 px head; rod = 2 px `lineStrong`, 6 px `inkMuted` caps, 34×4 paper grip; rodrule adds the spent part in `inkMuted`, ticks above the rod and an 8 px notch. Nothing changes the bar's height (the kit draws edges inside the bar), so `barSize` is unchanged. The rod sits 2 px up so its caps fit inside the window.
- At `position: bottom` the edge is mirrored as a whole onto the top side.
- Rod interaction: an 8 px band along the edge; hover lifts the grip 2 px, pressing inks the rod, a drag of 24 px (scaled) away from the bar emits `pulled()` → `BarSurface.edgePulled` → `Bar.edgePulled(screenName)`, which has no receiver until Phase 7.
- Inset: `BarWindow` sets 8 px margins on the anchored edge and both sides (hidden: parks at `-(height + 8)`); the paper gets a 1 px `Ink.line` frame with 7 px corners (the kit's `typeset.css`; COMPONENTS.md says 3 px, the rendered sheets show 7, the sheets won).
- Transparency: `Bar.transparent` follows `barConfig.transparent`; `toggleTransparency()` writes `bar.transparent` through `shell.mutateShellConfig` exactly like Omarchy's own bar (falls back to a session-only flip). `BarWindow.shown` turns `solid` into `glass` while it is on; glass and inset are left alone. style.json is never written.
- Blur: Omarchy requests no blur for its own bar (no layer rule in `default/hypr/apps/omarchy-shell.lua`), so Hanko doesn't either; README documents a `hl.layer_rule` for namespace `hanko-bar`.
- Harness: `phase5.json` (every edge × top/bottom, day rule at 00:30/06:00/21:44, rodrule + clock right, rules off, four heights, three surfaces over a backdrop, inset bottom and inset hairline, four presets) and `phase5-light.json`.

## 10. Instructions for the remaining phases (6–10)

Each phase: read the matching Typeset mockups and the HTML kit first, keep `BarSurface` pure (data in, signals out), add services for live data, add a `tests/harness/params/phaseN.json` covering every option and state, and follow §11.

### Phase 6 · Sheets (`panels: sheets`)

Target sheets: `21-desk-sheet-sound.webp`, `22-desk-instrument-time.webp`, Sheet's `03-sound-sheet.webp` and `04-time-sheet-kanagawa.webp`. HTML: `desk.html` panels `sheet-sound`, `sheet-time`.

1. **Host contract first (this also fixes §12 issue 1):** implement in `Bar.qml` `summonBarWidget(id)`, `hideBarWidget(id)`, `isBarWidgetOpen(id)` and `panelWidgetIdAt(section, index)`. Map Omarchy ids to Hanko sheets: `omarchy.audio` → Sound, `omarchy.clock` → Time, `omarchy.network` → Network, `omarchy.power` → Power. Notifications history → Inbox. Read `omacale/Bar.qml` (~line 263) and `omacale/modules/drawers/ScreenScope.qml` (~line 225: "opens, never toggles; the host asks isBarWidgetOpen first") for a working example. `panelWidgetIdAt("right", N)` should count Hanko's right-zone cells in order so `togglePanelAt right N` hotkeys keep meaning "the Nth thing on the right".
2. **Then switch `Status.act`** from `toggle("omarchy.audio")` etc. to opening Hanko's own sheet (`panels: sheets`) or scroll section (`panels: scroll`, Phase 7). Until Phase 7, `scroll` mode may open the sheet as a fallback.
3. **Sheet window:** a layer-shell surface (separate `PanelWindow` or `PopupWindow` anchored to the bar window) that drops **flush** from the clicked cell, joined to the bar (no gap, no bubble). The clicked cell inverts (bone plate) while its sheet is open. Reveal top-down in ~180 ms "as if printed". At `position: bottom` sheets rise. Click outside or `Esc` closes. Keyboard: arrow keys move inside, `Tab` cycles sheets. Needs keyboard focus while open (`WlrKeyboardFocus.OnDemand` on the sheet window only; the bar keeps `None`).
4. **Sheet anatomy (Sheet grammar):** eyebrow (`02 // SOUND` style mono label with kanji), serif title, one-line blurb, `//` group heads, hairline rows, inverted selection, an action strip at the foot, crop marks on the free corners. Sliders are rulers with one needle, not progress pills.
5. **Sheets and data:**
   - **Sound 音:** master output (ruler slider on the resolved volume sink; muted master in red), output device list (`Pipewire.nodes` sinks; set default via `omarchy-audio-output-set-default` like Omarchy's audio panel), input, per-app mixer (Pipewire stream nodes). Read `omarchy/shell/plugins/panels/audio/Panel.qml` for every data detail (DSP sink resolution, availability via `omarchy-audio-sink-availability`).
   - **Time 時:** calendar or day ribbon, the day rule large, **Elsewhen** time zones (read the user's Elsewhen settings; see `omarchy/shell/plugins/panels/elsewhen/` and `panels/clock/`).
   - **Network 網:** current connection, Wi-Fi list (`nmcli`), see `panels/network/Panel.qml` and `Model.js`; actions to the existing Omarchy scripts (speedtest, wifiqr, password).
   - **Power 電:** battery detail (`omarchy-battery-status --shell`), power profiles, brightness ruler; see `panels/power/Panel.qml`.
   - **Inbox 報:** notifications as stamped letters from the same files Phase 4 reads; clear (`omarchy-shell notifications clear`), DND switch.
6. Keep each sheet's contents in its own component so Phase 7 reuses them in scroll layout.
7. The harness: add a scene that renders an open sheet under a bar (a `Sheets.qml` scene), with params per sheet.

### Phase 7 · The handscroll (`panels: scroll`)

Target sheets: `20-desk-hanko-scroll.webp`, `24-desk-islet-kanagawa.webp`, `25-desk-scroll-flexoki-light.webp`, Scroll's `03`/`04` scroll views and `05` motion. HTML: `desk.html` panels `scroll-0`…`scroll-5`, and `scroll.css`/`scroll.js` in the Typeset source kit.

1. One surface that **unrolls from the rod** (drag the rod down, `Super+Space`, or click any status/clock/stamp). It hangs between two **rollers**; sections curl under the rollers at the edges so neighbours are always visible.
2. An **index plate** at the top: `時 01 TIME · 音 02 SOUND · 網 03 NETWORK · 電 04 POWER · 頁 05 SPACES · 報 06 INBOX`, current one inverted. A position bar along the foot with key hints (`H` `L` pan, `Esc` roll up). At `position: bottom` the scroll unrolls upward and the plate moves to the bottom.
3. Each section in ryoku.dev grammar: a red kanji, `02 // SOUND`, serif title, mono caption, a large faint kanji watermark. **Interludes** between sections: narrow dithered ink-wash slivers.
4. Sections reuse the Phase 6 sheet contents in scroll layout, plus Scroll's fresh controls: Sound = a **fader bank** (master in seal red, muted channels dashed); Time = a horizontal **day ribbon**; Spaces = a map of every workspace's real layout (click a window to focus it: `hl.dsp.focus({ window = "address:0x…" })`, check the exact Lua dispatcher in Omarchy's Hyprland Lua helpers); Inbox = stamped letters.
5. Motion: the rod drops and the paper follows (300 ms); ink fades in after (200 ms, delay 120 ms); panning has momentum and snaps to a section (260 ms); `Esc` rolls up. Reduced motion cuts to end frames (Phase 10 adds the global switch; respect it if present).
6. Hook into Phase 6's `summonBarWidget` mapping: under `panels: scroll`, Omarchy's panel hotkeys unroll the scroll at the matching section.
7. Global shortcut: register `Super+Space` only if Omarchy has a supported way for plugins to add binds (check `omarchy/default/omarchy/shortcuts` and `GlobalShortcut` use in `shell.qml`); otherwise expose IPC `hanko scroll` and document the bind for the user.

### Phase 8 · Settings window and CLI parity

Target sheets: `01-settings.webp`, `02-settings-light.webp`, `03-presets.webp`, `04-shuffle.webp`. HTML: `studio.html`. Spec: COMPONENTS.md §6.

1. A real window (a floating Hyprland window via a Quickshell `FloatingWindow`, or a layer surface with keyboard focus) in the **Ryoku Hub grammar**: numbered rail on the left (`01 BAR`: Typesetting 組版 · Colour 色 · Widgets 部品; `02 PANELS`: Sheets 紙 · Scroll 巻; `03 FEEL`: Motion 動 · Keys 鍵; `04 SHARE`: Presets 型), search field at the top, **Advanced** switch at the foot (shows `sealGlyph`, per-monitor overrides, raw JSON).
2. **Typesetting 組版** page: live preview (a `BarSurface` with the draft style over a sample plate), preset gallery (six cards, current inverted, `*` when edited), six cards of segmented controls grouped Left / Centre / Right / Edge / Frame / Panels (+ Seal glyph), action bar **Reset to preset · Revert · Save**. Changes preview live but only apply on Save (keep a draft doc separate from `Typeset.doc`).
3. Header shows `PRESET · HANKO + EDITS` when edited.
4. Open it with IPC `hanko settings`, `scripts/hanko settings`, and an Omarchy menu entry under Setup (find how menus are extended in `omarchy/default/omarchy/` / the menu plugin; only add an entry if there is a supported plugin hook).
5. CLI parity: `hanko style shuffle` exists already; add anything the page can do that the CLI can't (per-monitor set: `hanko style set --monitor DP-2 height 32`).
6. Other rail pages can start as honest placeholders, but Typesetting must be complete.

### Phase 9 · Hosting other widgets

1. Third-party bar widgets listed in `barConfig.layout.{left,center,right}` (ids other than Omarchy's built-ins Hanko already draws) render in Hanko's right zone, through `barWidgetRegistry`, with Hanko's spacing, dividers and ink. Port the slot pattern from `omacale/modules/bar/BarWidgetSlot.qml` and its `PluginBarFacade.qml` (the facade a widget sees as `bar`).
2. **Tray:** Quickshell `SystemTray`; draw items as small inked glyphs; menus via `QsMenuAnchor`. See Omarchy's `shell/plugins/bar/widgets/Tray.qml` and `TrayModel.js`.
3. Omarchy indicators (DND, night light, stay awake, screen recording, dictation, reminder: `shell/plugins/bar/indicators/`) should have a Hanko rendering too (small kanji marks), using the proxies Hanko is allowed (idle, nightlight, notifications) and files/IPC for the rest.
4. Keyboard layout and microphone widgets: check `shell/plugins/bar/widgets/` and decide with the user whether Hanko draws its own or hosts Omarchy's.
5. `panelWidgetIdAt` must count hosted widgets too.

### Phase 10 · Motion and release

1. The Scroll motion spec across the bar: inversion plates slide between items (one indicator, like Ryoku's rail); values crossfade; the now-notch creeps; a new stamp is pressed down oversized and tilted, then settles (140 ms, the only overshoot anywhere); sheets print top-down (~180 ms). A global **reduced motion** switch (Motion 動 page + style key, outside the 15 settings) that cuts every transition to its end frame.
2. Per-monitor override UI on the settings page (Advanced).
3. README install guide (screenshots from renders), `manifest.json` version `0.1.0` → release version, CHANGELOG entry, listing on omarchyplugins.com (ask the user before publishing anything; the repo is private).
4. Merge `dev` into `main` **only when the user asks**.

## 11. The per-phase routine

1. `update_status` checklist in the thread (project sessions), then read the target sheets and HTML.
2. Read the Omarchy source for every data source and action you'll touch (§6 lists where).
3. Pure logic → `core/*.js` with unit tests in `tests/unit.mjs` (load it with the `load()` helper at the top of that file).
4. Components → `bar/*.qml`, pure: props in, signals out. Services → `services/*.qml` singletons registered in `services/qmldir`. Wire in `BarSurface` (props/signals) and `BarWindow` (services → props, signals → service actions).
5. Add stubs under `tests/harness/stubs/` for any new Quickshell module/type you import, just enough for lint and render.
6. Add `tests/harness/params/phaseN.json` (every option × state, plus presets) and, if needed, pass new fields through `tests/harness/scenes/Strips.qml` (use its `pick(strip, key)` helper).
7. `tests/run`; fix every new lint warning; open `tests/out/phaseN.png` and compare with the Typeset mockup; iterate until it matches.
8. Update `docs/ROADMAP.md` (phase ✅), `README.md` (status "phase N of 10" and the "Right now it draws…" sentence), and this file (§9, §12, "Last updated").
9. Commit (`Phase N: …` + trailer), `git push -u origin dev`.
10. Copy the render to `/mnt/project-files/ryoku-shell/typeset/phaseN-render.png`; reply to the user with what's new, how to try it, what to check on their machine, and what's next. Update project memory.

## 12. Known issues and things to verify on a real machine

1. **Status clicks don't open Omarchy's panels under Hanko.** `omarchy.audio`, `omarchy.network`, `omarchy.power`, `omarchy.clock` are kind `bar-widget`, so `shell toggle` routes to `shell.bar.summonBarWidget(id)`, which Hanko doesn't implement yet; the shell logs "summon: no live bar widget". Omarchy's own panel hotkeys are affected the same way. **Fix in Phase 6 step 1** (or earlier, as a small fix, if the user hits it).
2. **Notification files are an internal Omarchy format**, not a plugin API. If Omarchy changes paths or fields, the inbox breaks silently (shows `00`). Verify on the user's machine; consider asking Omarchy for a proxy property later.
3. **Roadmap said network via `Quickshell.Networking`**; Phase 4 used `omarchy-network-status` instead (it matches what Omarchy shows and needs no extra module). Polls every 3 s.
4. **Not implemented yet from the spec:** `layout` workspaces "hover opens it to show window names"; glyph status "dashed when off" and "hover adds the Latin word"; `clockClicked` has no receiver (Phase 6 Time sheet).
5. **Unverified on hardware:** layer-shell behaviour at each height, `ExclusionMode` when hidden, multi-monitor per-monitor overrides, the DSP sink resolution, brightness on laptops, FileView watching a directory (`Bar.qml` hiding), Omarchy's clock format detection, Fraunces variable axes rendering in the real Qt.
6. `tests/run` does not set `HANKO_HARNESS_FONTS` itself; export it (§8) or kanji/mono may fall back to whatever the container has.
7. **Phase 5 to verify on hardware:** the inset exclusive zone (Hyprland should add the 8 px margin to it; if windows touch the frame, set `exclusiveZone` explicitly), the blur rule's field names in Hyprland's Lua config (`blur`, `ignore_alpha`), `toggleTransparency` round-tripping through `mutateShellConfig` for a third-party bar, and the rod's 8 px drag band not swallowing clicks meant for cells above it.

## 13. QML pitfalls already hit

- A property named `onSomething` is parsed as a **signal handler** (`onBone` broke; renamed `boneInk`). Never start a property name with `on` + capital.
- The id `gc` masks a JS global and fails at load (lint missed it, the render caught it). Avoid ids that shadow globals (`gc`, `print`, `console`, `Qt`).
- Use `pragma ComponentBehavior: Bound` in files with delegates / `Loader` components, give delegates `required property` and qualify outer ids (`root.x`), or qmllint reports unqualified access.
- Loader-based variants: give the component a `property var ws` and set it in `onLoaded` with `Qt.binding(...)`.
- Fraunces is variable: set `font.weight: Font.Normal` **and** `font.variableAxes: { "opsz": N, "wght": 400 }`, or it renders bold.
- `Text.StyledText` with `<font color=…>` for mixed-ink runs; escape `& < >` in any user text (titles, songs, notifications) first.
- Inline `component X: …` declarations can't see the delegate scope; pass what they need as properties.
- Ids inside a file share one scope: don't reuse a short id like `n` that a component property also uses.
- Stubs must be `QtObject`/`Item` with the exact property names the real module has; an enum-typed thing (e.g. `ExclusionMode`) must be a QML `enum`, not properties.

## 14. Reference material

- Omarchy: `github.com/omacom/omarchy` (manual `manual/32-shell-plugins.md`, `docs/omarchy-shell.md`, `shell/`, `bin/`, `default/hypr/`).
- Ryoku (style only): `github.com/Ryoku-dev/ryoku` branch `unstable-dev` (the Settings app), and `ryoku.dev` (blocked by the cloud network; use a web fetch tool).
- Plugin integration references (not design): `AyushKr2003/omacale` (closest model: a full `bar` plugin; its `CLAUDE.md` is worth reading), `HANCORE-linux/Shibumi-Shell`, `gitcoder89431/ruixen-shell`.
- In this repo: [ROADMAP.md](ROADMAP.md), [COMPONENTS.md](COMPONENTS.md), [DESIGN.md](DESIGN.md), [history/sheet-DESIGN.md](history/sheet-DESIGN.md), [history/scroll-DESIGN.md](history/scroll-DESIGN.md), `docs/mockups/`.
- Project files (Claude project): `/mnt/project-files/ryoku-shell/{scroll,typeset}/` hold mockups and phase renders; project memory notes `hanko-bar-design`.
